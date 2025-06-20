import logging
import azure.functions as func
from azure.data.tables import TableServiceClient
import subprocess
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("🔍 Azure Function processing HTTP request")

    # Step 1 — Run Azure CLI query for subs under MG
    filtered_subs = []
    try:
        mg_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        raw_output = subprocess.check_output(
            ["az", "account", "management-group", "entities", "list", "--query", "[?type=='/subscriptions']", "-o", "json"],
            stderr=subprocess.STDOUT,
            text=True
        )
        subs = json.loads(raw_output)
        filtered_subs = [
            sub for sub in subs
            if mg_id in sub.get("parentNameChain", [])
        ]
        logging.info(f"✅ CLI result — {len(filtered_subs)} subs under MG")
        logging.info(filtered_subs)
    except subprocess.CalledProcessError as e:
        logging.error("❌ Azure CLI failed")
        logging.error(e.output)

    # Step 2 — Process payload and query Azure Table Storage
    try:
        req_body = req.get_json()
        logging.info("=======================Payload starts here================")
        logging.info(req_body)
        name = req_body.get("name")
    except ValueError:
        return func.HttpResponse("Invalid JSON.", status_code=400)

    if not name:
        return func.HttpResponse("Missing 'name' in request body.", status_code=400)

    # ⚠️ Hardcoded connection string (only for local testing)
    conn_str = (
        "DefaultEndpointsProtocol=https;"
        "EndpointSuffix=core.windows.net;"
        "AccountName=myfuncstorage28882;"
        "AccountKey=BBSw5a+l0mMhpAEFnJ5CIlxh4Yv1zRQRhPrf6Apx6p4EfrYtfZtVZDls6VhQNmGkOo7ntSaWDmXd+AStytVttA==;"
        "BlobEndpoint=https://myfuncstorage28882.blob.core.windows.net/;"
        "FileEndpoint=https://myfuncstorage28882.file.core.windows.net/;"
        "QueueEndpoint=https://myfuncstorage28882.queue.core.windows.net/;"
        "TableEndpoint=https://myfuncstorage28882.table.core.windows.net/"
    )

    table_name = "people"

    try:
        service = TableServiceClient.from_connection_string(conn_str)
        table_client = service.get_table_client(table_name=table_name)
        entities = table_client.query_entities(f"Name eq '{name}'")
        results = [dict(entity) for entity in entities]
        logging.info("=============entities:=========")
        logging.info(results)

        return func.HttpResponse(
            json.dumps(results, indent=2),
            mimetype="application/json"
        )

    except Exception as e:
        logging.exception("Error querying Table Storage")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)
