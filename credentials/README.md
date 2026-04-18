# Credentials — Guía de Configuración

Esta carpeta **nunca debe contener credenciales reales**. Los valores sensibles se gestionan como secretos en Azure DevOps Library.

## Variable Group requerido

Crea un Variable Group llamado `Salesforce_CICD_Variables` en:
**Azure DevOps → Pipelines → Library → + Variable group**

Usa `azure-variables.template.txt` como referencia de qué variables agregar.

## Variables requeridas por ambiente

| Variable | Descripción | Secreto |
|----------|-------------|---------|
| `DEV_Username` | Usuario del org DEV | No |
| `DEV_Instance_URL` | URL del org DEV | No |
| `DEV_Client_ID` | Consumer Key de la Connected App DEV | Sí |
| `QA_Username` / `QA_Instance_URL` / `QA_Client_ID` | Igual para QA | Sí |
| `UAT_Username` / `UAT_Instance_URL` / `UAT_Client_ID` | Igual para UAT | Sí |
| `PROD_Username` / `PROD_Instance_URL` | Producción | Sí |
| `Salesforce_Client_ID` | Consumer Key principal | Sí |
| `Salesforce_Username` | Usuario principal del pipeline | No |

## Autenticación JWT (recomendada)

Este sistema usa autenticación JWT (sin contraseñas). Requiere:
1. Una **Connected App** en Salesforce con certificado digital
2. La clave privada (`server.key`) subida como **Secure File** en Azure DevOps
3. El **Consumer Key** de la Connected App en el Variable Group

Ver `bin/README.md` para instrucciones de generación de la clave JWT.
