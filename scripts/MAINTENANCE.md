# 🔄 MANTENIMIENTO DE AMBIENTES PERSISTENTES

Guía completa para mantener tus ambientes de Scratch Orgs persistentes (30 días).

---

## 📅 CALENDARIO DE MANTENIMIENTO

### **Cada 28-30 Días:**
- Renovar Scratch Orgs antes de expiración
- Re-exportar credenciales
- Actualizar Variable Groups en Azure (si usernames cambian)

### **Semanal:**
- Verificar fechas de expiración
- Monitorear pipeline executions

### **Mensual:**
- Revisar logs de deployments
- Actualizar documentación si hay cambios

---

## 🚀 SCRIPTS DISPONIBLES

### **1. setup-persistent-environments.sh**

**Propósito:** Crear/renovar los 3 ambientes persistentes (DEV, QA, UAT)

**Cuándo ejecutar:**
- Primera vez (setup inicial)
- Cada 28-30 días (renovación)
- Cuando un ambiente expire

**Uso:**
```bash
cd ~/Salesforce_CI-CD_Azure
./scripts/setup-persistent-environments.sh
```

**Duración:** 3-5 minutos

**Output:**
- Crea 3 Scratch Orgs con aliases:
  - `persistent-dev`
  - `persistent-qa`
  - `persistent-uat`
- Exporta credenciales a `credentials/` folder
- Muestra resumen con usernames y Org IDs

---

### **2. check-expiration.sh**

**Propósito:** Verificar cuándo expiran los Scratch Orgs

**Cuándo ejecutar:**
- Semanalmente (recomendado)
- Antes de cualquier deployment importante
- Cuando tengas dudas sobre el estado

**Uso:**
```bash
./scripts/check-expiration.sh
```

**Duración:** 10-15 segundos

**Output:**
- Lista de Scratch Orgs activos
- Días hasta expiración
- Alertas si alguno expira pronto (≤7 días)

---

### **3. export-azure-variables.sh**

**Propósito:** Generar archivo con variables para Azure DevOps

**Cuándo ejecutar:**
- Después de crear/renovar ambientes
- Cuando los usernames cambian
- Para documentación/backup

**Uso:**
```bash
./scripts/export-azure-variables.sh
```

**Duración:** 5 segundos

**Output:**
- Archivo: `credentials/azure-variables.txt`
- Formato listo para copiar/pegar en Azure Variable Groups

---

## 📋 PROCEDIMIENTO DE RENOVACIÓN

### **Antes de la Expiración (28 días):**

**1. Verificar estado:**
```bash
./scripts/check-expiration.sh
```

**2. Exportar datos importantes (opcional):**
```bash
# Si hay datos de prueba que quieres mantener
sf data export tree --query "SELECT Id,Name FROM Account" --target-org persistent-dev --output-dir data/backup/
```

**3. Renovar ambientes:**
```bash
./scripts/setup-persistent-environments.sh
```
- El script preguntará si quieres eliminar los Scratch Orgs existentes
- Responde: `y` (yes)
- Espera 3-5 minutos mientras se crean los nuevos

**4. Verificar credenciales:**
```bash
./scripts/export-azure-variables.sh
cat credentials/azure-variables.txt
```

**5. Actualizar Azure DevOps (si usernames cambiaron):**
- Ve a: Pipelines → Library → Variable Groups
- Edita: `Salesforce_CICD_Variables`
- Actualiza:
  - `DEV_Username`
  - `QA_Username`
  - `UAT_Username`
- (Los Instance URLs y Org IDs probablemente también cambien)

**6. Probar pipeline:**
- Dispara un run manual del CD pipeline
- Verifica que se conecta a los nuevos ambientes
- Confirma que el deployment funciona

---

## 🔑 CONFIGURACIÓN DE AZURE DEVOPS

### **Variable Group: Salesforce_CICD_Variables**

**Variables necesarias:**

```yaml
# DEV Environment
DEV_Username: test-xxxx@example.com  # Actualizar cada 30 días
DEV_Instance_URL: https://test.salesforce.com
DEV_Org_ID: 00D...  # Actualizar cada 30 días

# QA Environment
QA_Username: test-yyyy@example.com  # Actualizar cada 30 días
QA_Instance_URL: https://test.salesforce.com
QA_Org_ID: 00D...  # Actualizar cada 30 días

# UAT Environment
UAT_Username: test-zzzz@example.com  # Actualizar cada 30 días
UAT_Instance_URL: https://test.salesforce.com
UAT_Org_ID: 00D...  # Actualizar cada 30 días

# PROD Environment (Permanente)
PROD_Username: xavilopez581661@agentforce.com  # No cambia
PROD_Instance_URL: https://login.salesforce.com
PROD_Org_ID: 00DpK000000AVVWUAP

# Shared (No cambian)
Client_ID: <CONSUMER_KEY>
DevHub_Username: xavilopez581661@agentforce.com
```

---

## ⚠️ PROBLEMAS COMUNES

### **Problema 1: "LIMIT_EXCEEDED" al crear Scratch Org**

**Causa:** Límite diario de 6 Scratch Orgs alcanzado

**Solución:**
```bash
# Esperar hasta el día siguiente
# O eliminar Scratch Orgs existentes:
sf org delete scratch --all --no-prompt
```

---

### **Problema 2: Scratch Org expiró durante un deployment**

**Causa:** No renovaste a tiempo

**Solución:**
```bash
# Renovar inmediatamente
./scripts/setup-persistent-environments.sh

# Actualizar credenciales en Azure
./scripts/export-azure-variables.sh

# Re-correr el pipeline fallido
```

---

### **Problema 3: Pipeline no puede autenticar a ambiente**

**Causa:** Credenciales desactualizadas en Azure Variable Groups

**Solución:**
```bash
# 1. Obtener credenciales actuales
sf org display --target-org persistent-dev

# 2. Actualizar en Azure DevOps Variable Group
# 3. Re-correr pipeline
```

---

### **Problema 4: "Org not found" error**

**Causa:** Scratch Org fue eliminado o expiró

**Solución:**
```bash
# Ver orgs disponibles
sf org list

# Si el alias no está, recrear:
./scripts/setup-persistent-environments.sh
```

---

## 📊 COMANDOS ÚTILES

### **Ver todos los orgs:**
```bash
sf org list
```

### **Ver solo Scratch Orgs:**
```bash
sf org list --scratch-orgs
```

### **Abrir un ambiente:**
```bash
sf org open --target-org persistent-dev
sf org open --target-org persistent-qa
sf org open --target-org persistent-uat
```

### **Ver información de un org:**
```bash
sf org display --target-org persistent-dev
```

### **Eliminar un Scratch Org específico:**
```bash
sf org delete scratch --target-org persistent-dev --no-prompt
```

### **Eliminar TODOS los Scratch Orgs:**
```bash
sf org delete scratch --all --no-prompt
```

---

## 🎯 CHECKLIST DE MANTENIMIENTO

### **Setup Inicial (Una vez):**
- [ ] Ejecutar `setup-persistent-environments.sh`
- [ ] Configurar Connected Apps en cada ambiente (opcional)
- [ ] Exportar variables: `export-azure-variables.sh`
- [ ] Actualizar Variable Groups en Azure DevOps
- [ ] Configurar server.key en Secure Files
- [ ] Probar pipeline CD completo

### **Cada 28 Días:**
- [ ] Ejecutar `check-expiration.sh`
- [ ] Si expiran pronto: ejecutar `setup-persistent-environments.sh`
- [ ] Exportar nuevas credenciales
- [ ] Actualizar Azure Variable Groups
- [ ] Probar pipeline
- [ ] Agregar recordatorio para próximos 28 días

### **Semanal:**
- [ ] Ejecutar `check-expiration.sh`
- [ ] Revisar logs de pipelines
- [ ] Verificar que ambientes están healthy

---

## 📅 CALENDARIO RECOMENDADO

**Configurar recordatorios:**

```
Día 1: Setup inicial
Día 7: Primera verificación
Día 14: Segunda verificación
Día 21: Tercera verificación
Día 28: ⚠️ RENOVACIÓN (antes de día 30)
Día 29-30: Buffer por si hay problemas
```

---

## 💡 MEJORES PRÁCTICAS

1. **Nunca esperes al día 30** - Renueva en el día 28
2. **Automatiza recordatorios** - Usa calendario o cron job
3. **Documenta cambios** - Si haces modificaciones a los scripts
4. **Backup de datos** - Si cargas datos de prueba importantes
5. **Monitorea límites** - No más de 3 Scratch Orgs simultáneos
6. **Prueba después de renovar** - Siempre valida con un deployment

---

## 📞 SOPORTE

**Si tienes problemas:**

1. Verifica logs de scripts
2. Revisa `credentials/` folder
3. Verifica Variable Groups en Azure
4. Re-lee esta guía
5. Ejecuta `sf org list` para diagnosticar

**Logs útiles:**
```bash
# Ver último error de Salesforce CLI
sf whatami

# Ver versión de CLI
sf version

# Ver configuración actual
sf config list
```

---

## 🎓 RECURSOS ADICIONALES

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/)
- [Scratch Orgs Documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs.htm)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)

---

**Última actualización:** 2026-01-11
**Autor:** Oscar Javier López Gómez
**Proyecto:** Salesforce CI/CD Azure DevOps
