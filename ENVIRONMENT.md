# Configuración por ambiente

Este documento define dónde vive cada variable. Los archivos `.env` y `.env.compose` reales no se versionan.

## Fuentes de configuración

| Archivo                                 | Alcance                           | Contenido                                              |
| --------------------------------------- | --------------------------------- | ------------------------------------------------------ |
| `.env` del launcher backend             | Compartido por Compose             | PostgreSQL, NATS, ambiente y puertos publicados        |
| `<servicio>/.env.compose`               | Un microservicio en Compose       | Integraciones y configuración propia del servicio      |
| `<servicio>/.env`                       | Ejecución standalone              | Equivalente local fuera de Compose                     |
| `.env` del launcher frontend            | Compartido por Compose             | Configuración común de las interfaces                  |
| `<interfaz>/.env`                       | Una interfaz                      | Gateway, origen público y clave de herramienta         |

Las plantillas correspondientes son la fuente versionada. Los secretos se suministran por el ambiente de despliegue.

## Autenticación web

### Launcher backend

| Variable                                 | Propietario  | Secreta | Finalidad                                               |
| ---------------------------------------- | ------------ | ------: | ------------------------------------------------------- |
| `WEB_AUTH_ENABLED`                       | Auth-Service |      No | Activa SID/OIDC/UMA                                     |
| `WEB_AUTH_ALLOW_INSECURE_HTTP`           | Auth y Hub   |      No | Override explícito para una intranet HTTP productiva    |
| `ENVIRONMENT`                            | Servicios    |      No | Separa claves Redis y activa validaciones de producción |
| `REDIS_PORT`                             | Compose      |      No | Puerto local expuesto en desarrollo                     |
| `KEYCLOAK_PORT`, `KEYCLOAK_BIND_ADDRESS` | Compose      |      No | Publicación controlada de Keycloak                      |

`WEB_REDIS_PASSWORD` y las variables propias de Keycloak viven en `Auth-Service/.env.compose`. Keycloak reutiliza la conexión `DB_*` del launcher y solo separa sus tablas mediante `KC_DB_SCHEMA`. `KC_BOOTSTRAP_ADMIN_USER` y `KC_BOOTSTRAP_ADMIN_PASSWORD` crean el administrador inicial cuando corresponde.

### Auth-Service

| Variable                            | Secreta | Regla                                                        |
| ----------------------------------- | ------: | ------------------------------------------------------------ |
| `AUTH_PUBLIC_ORIGIN`                |      No | Esquema y host públicos comunes, sin puerto ni ruta           |
| `AUTH_HUB_PORT`                      |      No | Override; default `3001`                                      |
| `CALLBACK_PATH`                     |      No | Override; default `/api/auth/callback`                        |
| `OIDC_INTERNAL_BASE_URL`            |      No | Origen interno de Keycloak; no cambia el issuer esperado     |
| `OIDC_HUB_TOOL_KEY`                 |      No | Override opcional; default `hub`                             |
| `OIDC_HUB_CLIENT_ID`                |      No | Override opcional; default `hub-interface`                   |
| `OIDC_HUB_CLIENT_SECRET`            |      Sí | Obligatoria; el Hub siempre es confidencial                  |
| `AUTH_TOOL_CLIENTS`                 |      No | Mapa `AUTH_TOOL_KEY` → clientId                              |
| `WEB_REDIS_HOST`, `WEB_REDIS_PORT`  |      No | Overrides opcionales; defaults `redis` y `6379`              |
| `WEB_REDIS_PASSWORD`                |      Sí | Contraseña compartida con el contenedor Redis                |
| `KC_DB_SCHEMA`, `KC_*`              | Algunas | Schema, hostname opcional y bootstrap de Keycloak            |
| `WEB_REDIS_KEY_PREFIX`              |      No | Override opcional; default `muserpol-web`                    |
| `WEB_*_TTL_SECONDS`                 |      No | Overrides opcionales de los tiempos predeterminados          |

Configuración mínima sin secretos:

```env
AUTH_PUBLIC_ORIGIN=https://plataforma.example.test
OIDC_INTERNAL_BASE_URL=http://keycloak:8080
AUTH_TOOL_CLIENTS={"beneficiary":{"clientId":"beneficiary-interface"},"sales":{"clientId":"sales-interface"},"collections":{"clientId":"collections-interface"}}
```

Los defaults y sus overrides están documentados en esta sección y en `Auth-Service/.env.template`, que sirve de referencia para la ejecución standalone. Para cambiar uno en Docker Compose, se agrega la variable al `.env.compose` real y se recrea `auth-service-dev`. Los cambios `KC_*` requieren recrear Keycloak; cambiar `KC_DB_SCHEMA` o la base exige preparar previamente el destino y nunca mueve datos existentes.

Agregar una herramienta exige agregar una entrada al catálogo y configurar el cliente correspondiente en Keycloak. La clave enviada por el frontend nunca puede elegir un clientId arbitrario.

### Interfaces web

Todas las interfaces SID usan:

| Variable                    | Exposición            | Finalidad                                      |
| --------------------------- | --------------------- | ---------------------------------------------- |
| `GATEWAY_INTERNAL_URL`      | Solo servidor         | Origen usado por el BFF para llamar al Gateway |
| `HUB_PUBLIC_ORIGIN`         | Solo servidor         | Origen público permitido para volver al Hub    |
| `AUTH_TOOL_KEY`             | Solo servidor         | Clave del catálogo de Auth                     |
| `AUTH_COOKIE_SECURE`        | Solo servidor del Hub | Debe ser `true` con HTTPS en producción        |
| `WEB_AUTH_ALLOW_INSECURE_HTTP` | Solo servidor del Hub | Permite HTTP productivo de forma explícita   |
| `AUTH_PENDING_TTL_SECONDS`  | Solo servidor         | Vigencia del binding OIDC del Hub              |
| `BENEFICIARY_PUBLIC_ORIGIN` | Solo servidor del Hub | Destino público de Beneficiary                 |
| `SALES_PUBLIC_ORIGIN`       | Solo servidor del Hub | Destino público de Sales                       |
| `COLLECTIONS_PUBLIC_ORIGIN` | Solo servidor del Hub | Destino público de Collections                 |

El endpoint de lanzamiento del Hub valida primero el acceso a la herramienta y luego usa el origen configurado. Los puertos y protocolos no están codificados en la aplicación.

En el Compose de desarrollo del launcher frontend, `AUTH_TOOL_KEY` se fija por servicio y las variables compartidas se inyectan desde el `.env` raíz. Los `.env` de cada submódulo se reservan para ejecución standalone.

Los valores `NEXT_PUBLIC_*` solo deben contener datos que puedan entregarse al navegador. No deben contener secretos, URLs internas ni credenciales.

## Desarrollo y producción

- Ambos launchers usan su `.env` raíz en desarrollo y producción; el archivo real permanece ignorado y se completa para el ambiente donde se despliega.
- El backend carga primero `.env` y después el `.env.compose` de cada servicio, que puede sobrescribir valores compartidos dentro de ese contenedor.
- Los `.env.compose` contienen integraciones específicas del despliegue de cada microservicio; no se copian desde desarrollo sin revisión.
- Desarrollo puede usar HTTP y nombres de servicio internos en `GATEWAY_INTERNAL_URL` y `OIDC_INTERNAL_BASE_URL`.
- HTTPS y `AUTH_COOKIE_SECURE=true` son la configuración recomendada. Una intranet que opere deliberadamente con HTTP debe usar `AUTH_COOKIE_SECURE=false` en el Hub y habilitar explícitamente `WEB_AUTH_ALLOW_INSECURE_HTTP=true` tanto en el Hub como en Auth-Service.
- El issuer público debe coincidir exactamente con el `iss` de los tokens.
- No se deben copiar direcciones particulares de desarrollo a las plantillas.
- Los Compose de producción deben revisarse de forma separada antes del despliegue; no se asume que heredan automáticamente las variables nuevas del Compose de desarrollo.
