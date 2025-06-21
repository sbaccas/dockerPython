# dockerPython

This repo contains all files needed to deploy a **containerized Python Azure Function** in an **Azure Function App running over an App Service Plan**.

Azure Functions are an excellent choice for automation runtimes, especially when coordinating communication between multiple Azure resources within the same tenant.

## 📘 Background

This project was created after attempting to follow Microsoft’s official documentation for deploying Azure Functions in **Azure Container Apps**:

> https://learn.microsoft.com/en-us/azure/azure-functions/functions-deploy-container-apps?tabs=acr%2Cbash&pivots=programming-language-python

Despite following the instructions verbatim, the deployment failed. This repo instead implements a more reliable and transparent approach using the **classic v1 Function App style** hosted via **App Service Plan**. The containerized version of the function has been tested and works as expected.

## 🚀 How to Use

### 1. Write your Azure Function

Place your Python Azure Function code in:

```
dockerPython/__init__.py
```

Use the v1-style Azure Function layout with an `HttpTrigger`.

### 2. Build and Push the Docker Image

Use the helper script to build and push to your ACR:

```bash
./bakeandpush.sh
```

This will:
- Build the image locally
- Optionally test it
- Push it to your Azure Container Registry (ACR)

### 3. Deploy the Azure Function App

Use the deployment script to launch the app using `azfunction.json`:

```bash
./create_function.sh
```

This provisions:
- The Function App
- The App Service Plan
- Storage Account
- Application Insights

### 4. Post-Deployment Configuration

Run the setup script to finalize configuration:

```bash
./post_fnapp_deployment.sh
```

This assigns:
- The correct **RBAC permissions** to the Function App's **system-assigned managed identity**
- Required **environment variables** used by the function at runtime

## 🛡️ Security Note

If you’ve committed any secrets (e.g., ACR credentials), rotate them immediately. Going forward, avoid hardcoding credentials. Use:
- **Managed Identity** for authentication
- **Environment variables** for configuration
