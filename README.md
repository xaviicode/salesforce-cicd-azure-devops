# Salesforce CI/CD — Azure DevOps Enterprise Pipeline

> Sistema completo de CI/CD para proyectos Salesforce usando Azure DevOps. Arquitectura multi-pipeline con templates reutilizables, autenticación JWT, delta deployment y quality gates.

**Stack:** Salesforce DX · Azure DevOps YAML Pipelines · Bash · Node.js  
**Ambientes:** DEV → QA → UAT → PROD  
**Autor:** Oscar López — DevOps Engineer

---

## Arquitectura del sistema

```
Feature Branch          develop             master
      │                    │                  │
      ▼                    ▼                  ▼
┌─────────────┐    ┌──────────────┐   ┌─────────────────┐
│  CI - Fast  │    │ CI-Integrated│   │   CD - Upper    │
│ ~5-8 min    │    │ ~10-15 min   │   │ UAT ✅ → PROD ✅│
│             │    │              │   │ (approval gates)│
│ • Lint      │    │ • Tests      │   └─────────────────┘
│ • Syntax    │    │ • Coverage   │
│ • PMD scan  │    │ • Deploy DEV │   ┌─────────────────┐
└─────────────┘    │ • Deploy QA  │   │   CD - Lower    │
                   └──────────────┘   │ DEV → QA (auto) │
                                      └─────────────────┘
```

## Pipelines

| Archivo | Propósito | Trigger |
|---------|-----------|---------|
| `azure-pipelines-ci.yml` | CI rápido para feature branches | `feature/*`, `hotfix/*` |
| `azure-pipelines-ci-integrated.yml` | CI completo para develop | `develop` |
| `azure-pipelines-cd-lower.yml` | Despliegue automático DEV → QA | Completado CI-Integrated |
| `azure-pipelines-cd.yml` | Despliegue controlado UAT → PROD | Completado CI en master |

## Sistema de templates

El sistema usa **templates YAML reutilizables** organizados por responsabilidad:

```
templates/
├── jobs-setup.yml              ← Prerrequisitos: tools, validación, workspace
├── jobs-build.yml              ← Build y empaquetado
├── cd/
│   └── steps/                  ← Auth, deploy, test, cleanup
├── deployment/
│   ├── delta-deployment.yml    ← Solo despliega componentes modificados
│   ├── deployment-validation.yml
│   ├── impact-analysis.yml
│   └── rollback-planning.yml
├── quality/
│   ├── gate-evaluator.yml      ← Quality gate (falla el build si no pasa)
│   ├── metrics-calculator.yml
│   └── ...
├── steps/                      ← 18 steps atómicos reutilizables
│   ├── salesforce-jwt-auth.yml ← Autenticación segura sin contraseña
│   ├── pmd-scanner.yml         ← Análisis estático de Apex
│   ├── code-coverage-check.yml
│   ├── eslint-validation.yml
│   └── ...
└── testing/
    ├── unit-tests.yml
    ├── security-tests.yml
    └── performance-tests.yml
```

## Autenticación JWT (sin contraseñas)

El sistema usa **JWT Bearer Token Flow** — el método más seguro para CI/CD en Salesforce. No requiere usuario/contraseña en el pipeline.

```
Connected App (Salesforce)
        │  Consumer Key
        │  Certificado digital (.crt)
        ▼
Azure DevOps Library
        │  Variable Group: Salesforce_CICD_Variables
        │  Secure File: server.key
        ▼
Pipeline → sf org login jwt --client-id ... --jwt-key-file ...
```

Ver `bin/README.md` para generar el par de claves y `credentials/README.md` para configurar el Variable Group.

## Delta Deployment

El script `scripts/generate-delta-package.sh` genera automáticamente un `package.xml` con **solo los componentes que cambiaron** entre dos commits, reduciendo el tiempo de despliegue y el riesgo de errores.

```bash
# Uso directo
bash scripts/generate-delta-package.sh origin/main HEAD manifest/package.xml

# En el pipeline — automático via template
- template: templates/deployment/delta-deployment.yml
  parameters:
    targetOrg: 'persistent-qa'
    baseCommit: 'origin/develop'
    testLevel: 'RunLocalTests'
```

## Requisitos previos

### Salesforce
- Salesforce org (Developer Edition, Sandbox o scratch org)
- Connected App con OAuth y certificado digital configurado
- Salesforce CLI (`sf`) instalado localmente para desarrollo

### Azure DevOps
- Proyecto en Azure DevOps
- Variable Group `Salesforce_CICD_Variables` configurado (ver `credentials/README.md`)
- `server.key` subido como Secure File en Library
- Environments `DEV`, `QA`, `UAT`, `PROD` creados (con approval gates en UAT y PROD)

## Configuración rápida

```bash
# 1. Clonar el repo
git clone https://github.com/tu-usuario/salesforce-cicd-azure-devops.git
cd salesforce-cicd-azure-devops

# 2. Instalar dependencias
npm install

# 3. Generar claves JWT
openssl genrsa -out bin/server.key 2048
openssl req -new -x509 -key bin/server.key -out bin/server.crt -days 730

# 4. Autenticar con tu DevHub
sf org login web --alias DevHub --set-default-dev-hub

# 5. Crear scratch org de desarrollo
sf org create scratch --definition-file config/project-scratch-def.json --alias dev-local
```

## Estructura del proyecto Salesforce de ejemplo

```
force-app/main/default/
├── classes/
│   ├── AccountService.cls          ← Lógica de negocio
│   ├── AccountServiceTest.cls      ← Test unitario (>85% cobertura)
│   ├── AccountAutomationTriggerTest.cls
│   └── CICDTestClass.cls           ← Test de validación CI/CD
└── triggers/
    └── AccountAutomationTrigger.trigger
```

## Calidad de código

El pipeline aplica automáticamente:

| Check | Herramienta | Threshold |
|-------|-------------|-----------|
| Análisis estático Apex | PMD Scanner | 0 violaciones críticas |
| Linting JavaScript/LWC | ESLint + Prettier | 0 errores |
| Cobertura de tests | Salesforce Apex | ≥ 75% |
| Compilación | SF CLI | Sin errores |
| Sintaxis metadata | SF CLI | Válida |

## Licencia

MIT — libre para usar como base en tus propios proyectos.

---

*Portfolio demo por [Oscar López](https://www.linkedin.com/in/) — DevOps Engineer | Ibagué, Colombia*
