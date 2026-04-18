# bin/ — Clave JWT para Autenticación Salesforce

Esta carpeta almacena la clave privada JWT (`server.key`) **localmente** para desarrollo.
El archivo `server.key` **nunca debe commitearse** — está en `.gitignore`.

En el pipeline de Azure DevOps, la clave se gestiona como **Secure File** en Library.

## Generar el par de claves (una sola vez por proyecto)

```bash
# 1. Generar clave privada
openssl genrsa -out bin/server.key 2048

# 2. Generar certificado (autofirmado, válido 2 años)
openssl req -new -x509 -key bin/server.key \
  -out bin/server.crt \
  -days 730 \
  -subj "/C=CO/ST=Colombia/O=TuEmpresa/CN=salesforce-cicd"

# 3. Ver el contenido del certificado (lo necesitas para la Connected App)
cat bin/server.crt
```

## Configurar la Connected App en Salesforce

1. Ir a **Setup → App Manager → New Connected App**
2. Habilitar **OAuth Settings**
3. Habilitar **Use Digital Signatures** y subir `server.crt`
4. Scopes requeridos: `api`, `web`, `refresh_token`
5. Copiar el **Consumer Key** → guardar en Variable Group de Azure DevOps

## Subir server.key como Secure File en Azure DevOps

1. **Azure DevOps → Pipelines → Library → Secure Files**
2. **+ Secure File** → subir `bin/server.key`
3. Nombre del archivo: `server.key` (debe coincidir con el pipeline)

El template `templates/steps/salesforce-jwt-auth.yml` descarga automáticamente
este archivo durante la ejecución del pipeline usando `DownloadSecureFile@1`.
