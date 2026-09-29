# Configuración reproducible de Keycloak

La base de datos de Keycloak es estado operativo. No se modifica directamente, no se reemplaza con seeders SQL y no se importa un realm completo sobre un ambiente existente.

## Estrategia

La configuración debe administrarse mediante la API administrativa de Keycloak o `kcadm.sh` con tres acciones separadas:

1. **validate**: solo lectura; compara el estado esperado y reporta diferencias.
2. **plan**: muestra las operaciones que serían necesarias sin aplicarlas.
3. **apply**: crea o actualiza únicamente objetos administrados y requiere una acción explícita.

Mientras no exista esa herramienta versionada, la configuración se aplica manualmente siguiendo este documento. Nunca se ejecuta un `apply` automático al iniciar los contenedores.

Un futuro aprovisionador debe:

- identificar objetos por `clientId`, nombre de recurso, scope y permission, no por UUID exportado;
- ser idempotente;
- no borrar clientes, usuarios, grupos, sesiones ni políticas desconocidas;
- no guardar secretos o contraseñas en Git;
- detenerse ante diferencias destructivas;
- exportar un informe sanitizado antes de aplicar;
- ofrecer `validate` como acción predeterminada.

## Ejecución en producción

El launcher ejecuta Keycloak con `start`, no con `start-dev`. El puerto del contenedor se publica por defecto en `127.0.0.1` y debe quedar detrás de un proxy TLS. `KC_HOSTNAME` contiene el origen HTTPS público, mientras Auth-Service usa `OIDC_INTERNAL_BASE_URL=http://keycloak:8080` dentro de la red de Compose.

Cambiar la versión de la imagen puede migrar el schema de Keycloak. Antes de actualizarla se necesita respaldo y un plan de reversión probado.

## Realm

El realm esperado por los ejemplos es `muserpol`. Debe coincidir con `OIDC_ISSUER`.

Configurar los tiempos de sesión según [WEB-AUTHENTICATION.md](./WEB-AUTHENTICATION.md). La federación LDAP pertenece a Keycloak; sus credenciales y conexión son configuración del ambiente y no deben incorporarse a un export versionado.

## Cliente `hub-interface`

Configuración mínima:

- protocolo OpenID Connect;
- Standard Flow habilitado;
- tipo public o confidential igual a `OIDC_HUB_CLIENT_TYPE`;
- redirect URI exacta igual a `OIDC_HUB_CALLBACK_URL`;
- post logout redirect URI exacta igual a `OIDC_HUB_POST_LOGOUT_REDIRECT_URL`;
- Web Origins vacío o restringido, sin comodines; el BFF no usa llamadas OIDC desde JavaScript;
- Backchannel Logout URL: `<gateway-public-origin>/api/auth/backchannel-logout`;
- Backchannel Logout Session Required habilitado;
- Frontchannel Logout no sustituye el backchannel.

En desarrollo local, con los puertos predeterminados:

```text
Valid redirect URI:              http://localhost:3001/api/auth/callback
Valid post logout redirect URI:  http://localhost:3001/
Web origin:                      http://localhost:3001
Backchannel Logout URL:          http://localhost:3000/api/auth/backchannel-logout
```

Los valores reales deben usar el host visible por el navegador y, para backchannel, una URL del Gateway alcanzable desde Keycloak.

## Herramientas

Cada herramienta del `WEB_CLIENT_CATALOG` tiene su propio cliente y Authorization Services:

| Tool key | Client ID / audience / resource server |
| --- | --- |
| `beneficiary` | `beneficiary-interface` |
| `sales` | `sales-interface` |
| `collections` | `collections-interface` |

Auth-Service deriva audience y resource server del `clientId`; no se repiten en la variable.

El Hub usa recursos `beneficiary-interface`, `sales-interface` y `collections-interface` con scope `launch` para decidir qué tarjetas presenta y qué lanzamientos permite. La autorización de cada endpoint sigue perteneciendo al cliente de la herramienta.

No se deben inventar recursos o permisos para una herramienta antes de acordar su matriz. Los endpoints marcados como sesión web validan la sesión de la herramienta y los endpoints con permiso ejecutan UMA sobre el resource/scope fijo declarado por Gateway.

## Mappers

Los clientes de herramientas deben entregar al token intercambiado los claims que usa el contexto:

- subject estable;
- username preferido cuando exista;
- nombre y correo cuando correspondan;
- grupos cuando la interfaz deba mostrarlos;
- client roles de la herramienta.

Un usuario sin grupos es válido. Los permisos efectivos siempre provienen de Authorization Services; los grupos y roles mostrados por la UI son informativos.

## Verificación manual segura

Antes de probar:

1. comprobar que Keycloak, Redis, NATS, Auth-Service y Gateway estén activos;
2. confirmar que issuer, URLs públicas y URLs internas corresponden al ambiente;
3. revisar que el catálogo contenga cada tool key usada por los frontends;
4. validar redirect, post logout y backchannel del Hub;
5. confirmar que los clientes de herramientas permiten el token exchange configurado;
6. iniciar una sesión nueva después de cambios en mappers o roles;
7. validar lanzamiento, contexto, permiso UMA y logout global;
8. revocar una sesión desde Keycloak y confirmar que Redis queda invalidado por backchannel.

No se imprimen tokens, SID, secretos, cookies completas ni datos personales durante estas comprobaciones.

## Validación versionada de solo lectura

El estado estructural esperado está en:

```text
Keycloak/config/web-auth.expected.json
```

El validador consulta el realm, la presencia de una federación LDAP habilitada, los clientes, el rol base `user` de cada herramienta y los recursos `launch`. En el Hub también comprueba el tipo public/confidential, Standard Flow, Direct Access Grants deshabilitado, ausencia de comodines en Web Origins, callback y logout. No crea, actualiza ni elimina configuración. El único `POST` que realiza es el intercambio estándar de credenciales administrativas por un token temporal; todas las llamadas administrativas son `GET`.

Variables requeridas:

```env
KEYCLOAK_ADMIN_URL=https://keycloak.example.test
KEYCLOAK_ADMIN_REALM=master
KEYCLOAK_ADMIN_USERNAME=<administrador>
KEYCLOAK_ADMIN_PASSWORD=<secreto>
OIDC_HUB_CALLBACK_URL=https://hub.example.test/api/auth/callback
OIDC_HUB_POST_LOGOUT_REDIRECT_URL=https://hub.example.test/
KEYCLOAK_BACKCHANNEL_LOGOUT_URL=https://gateway.example.test/api/auth/backchannel-logout
```

También puede proporcionarse un `KEYCLOAK_ADMIN_TOKEN` temporal en lugar de usuario y contraseña.

Ejecución explícita con variables administradas por el entorno:

```sh
node Keycloak/scripts/validate-web-auth.mjs
```

Para el ambiente local del launcher existe un wrapper que lee `.env` y `Auth-Service/.env.compose` sin imprimir sus valores y deriva el backchannel usando el host del callback y `CLIENT_GATEWAY_PORT`:

```sh
node Keycloak/scripts/validate-local-web-auth.mjs
```

Este wrapper es apropiado cuando Hub y Gateway comparten host y se diferencian por puerto. En un ambiente con dominios diferentes debe usarse el validador principal y suministrar explícitamente `KEYCLOAK_BACKCHANNEL_LOGOUT_URL`.

El comando no se ejecuta durante el arranque de Compose. No imprime tokens, secretos, UUID de clientes ni respuestas administrativas completas.

## Qué no automatizar todavía

Aunque ya existe un manifiesto y validación de solo lectura, todavía no se automatiza la aplicación:

- no importar un realm JSON sobre la base actual;
- no ejecutar SQL contra el esquema de Keycloak;
- no recrear el realm;
- no rotar secretos automáticamente;
- no eliminar objetos que no aparezcan en la documentación;
- no ejecutar aprovisionamiento al arrancar Docker Compose.
