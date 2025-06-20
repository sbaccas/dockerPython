import logging
import os
import json
import azure.functions as func
from azure.identity import ManagedIdentityCredential
from azure.data.tables import TableServiceClient
from azure.core.exceptions import ResourceNotFoundError
import subprocess

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("🔍 Azure Function processing HTTP request")

    # Step 0 — Get config from environment
    mg_id = os.environ.get("MG_ID")
    storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
    table_name = os.environ.get("TABLE_NAME", "people")  # default fallback
    logging.info(f"🔧 MG_ID: {mg_id}")
    logging.info(f"🔧 STORAGE_ACCOUNT_NAME: {storage_account_name}")
    logging.info(f"🔧 TABLE_NAME: {table_name}")

    mg_id = os.environ.get("MG_ID", "").strip()
    logging.info(f"🧪 Cleaned MG_ID: '{mg_id}'")
    
    if not mg_id or not storage_account_name:
        return func.HttpResponse("Missing env vars: MG_ID or STORAGE_ACCOUNT_NAME", status_code=500)

    # Step 1 — Login using managed identity (for CLI-based steps only)
    try:
        subprocess.check_output(["az", "login", "--identity"], stderr=subprocess.STDOUT, text=True)
        logging.info("✅ Logged in using managed identity")
    except subprocess.CalledProcessError as e:
        logging.error("❌ Failed to login with managed identity")
        logging.error(e.output)
        return func.HttpResponse("Azure CLI login failed", status_code=500)

    # Step 2 — Query all subs under the given MG
    try:
        raw_output = subprocess.check_output(
            [
                "az", "account", "management-group", "entities", "list",
                "--query", "[?type=='/subscriptions']",
                "-o", "json"
            ],
            stderr=subprocess.STDOUT,
            text=True
        )
        subs = json.loads(raw_output)
        filtered_subs = [sub for sub in subs if mg_id in sub.get("parentNameChain", [])]
        logging.info(f"✅ CLI result — {len(filtered_subs)} subs under MG")
    except subprocess.CalledProcessError as e:
        logging.error("❌ Azure CLI query failed")
        logging.error(e.output)
        filtered_subs = []

    # Step 3 — Parse payload
    try:
        req_body = req.get_json()
        name = req_body.get("name")
        logging.info("===========================Payload===================")
        logging.info(req_body)
    except ValueError:
        return func.HttpResponse("Invalid JSON.", status_code=400)

    if not name:
        return func.HttpResponse("Missing 'name' in request body.", status_code=400)

    # Step 4 — Query Azure Table using Managed Identity
    try:
        table_endpoint = f"https://{storage_account_name}.table.core.windows.net"
        credential = ManagedIdentityCredential()
        service_client = TableServiceClient(endpoint=table_endpoint, credential=credential)
        table_client = service_client.get_table_client(table_name=table_name)

        entities = table_client.query_entities(f"Name eq '{name}'")
        results = [dict(entity) for entity in entities]

        return func.HttpResponse(
            json.dumps({
                "matched_entities": results,
                "filtered_subs": filtered_subs  # optional: include it in the return
            }, indent=2),
            mimetype="application/json"
        )

    except ResourceNotFoundError:
        return func.HttpResponse(f"Table {table_name} not found.", status_code=404)
    except Exception as e:
        logging.exception("Error querying Table Storage")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)
