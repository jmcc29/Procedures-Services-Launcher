# Pasos para levantar el proyecto
## Dev

1. Clonar el repositorio
2. Crear el `.env` basado en el .env.template \
    Este archivo posee las variables que se heredaran a los microservicios mediante el archivo docker-compose.prod
3. Ejecutar el siguiente comando para inicializar los sub-modulos
```sh
git submodule update --init --recursive
``` 
4. En cada submodulo crear su propio `.env.compose` basado en el `.env.compose.template` \
    Estos archivos tienen las variables unicas que pertenecen solamente a ese servicio
5. En la base de datos ejecutar el siguiente query
```sql
CREATE SCHEMA IF NOT EXISTS beneficiaries;
CREATE SCHEMA IF NOT EXISTS kiosk;
CREATE SCHEMA IF NOT EXISTS auth;
```
6. Ejecutar el comando para construir las imagenes
```sh
docker compose build --no-cache && docker compose up -d

```
7. Ingresar al contenedor de `beneficiary-service` y ejecutar sus migraciones y seeders
**Importante**
Primero ejecutar en pvt-be
```sh
php artisan db:seed --class=SimplificaciónRequisitos
```
```sh
docker compose exec beneficiary-service sh
yarn migration:run
yarn seed:run
```
8. Ingresar el contenedor `gateway-service` y ejecutar su migración
```sh
docker compose exec gateway-service sh
yarn migration:run
```

## Prod

### Introducción
#### Nota
>En producción las variables de entorno se estan pasando mediante el archivo `docker-compose.prod`, ahi se seleccionan los archivos `.env` que se usaran en 
cada microservicio, el `.env` del proyecto padre contiene las variables generales que se usan en dos o mas microservicios, como ser, la conexion con la base de datos, 
conexion con el servidor nats. En cada submodulo o microservicio, se encuentra un archivo `.env.compose`, en este archivo se colocan las variables unicas del servicio

### Pasos para levantar el proyecto
1. Clonar el repositorio
2. Crear el `.env` basado en el `.env.template` \
    Este archivo posee las variables que se heredaran a los microservicios mediante el archivo docker-compose.prod
3. Ejecutar el siguiente comando para inicializar los sub-modulos
```sh
git submodule update --init --recursive
``` 
4. En cada submodulo crear su propio `.env.compose` basado en el `.env.compose.template` \
    Estos archivos tienen las variables unicas que pertenecen solamente a ese servicio
5. En la base de datos ejecutar el siguiente query
```sql
CREATE SCHEMA IF NOT EXISTS beneficiaries;
CREATE SCHEMA IF NOT EXISTS kiosk;
CREATE SCHEMA IF NOT EXISTS auth;
```
6. Ejecutar el comando para construir las imagenes
```sh
docker compose -f docker-compose.prod.yml build --no-cache && docker compose -f docker-compose.prod.yml up -d

```
7. Ingresar al contenedor de `beneficiary-service` y ejecutar sus migraciones y seeders
**Importante**
Primero ejecutar en `PVT-BE`
```sh
php artisan db:seed --class=SimplificaciónRequisitos
```
```sh
docker compose -f docker-compose.prod.yml exec beneficiary-service sh
yarn migration:run
yarn seed:run
```
8. Ingresar el contenedor `gateway-service` y ejecutar su migración
```sh
docker compose -f docker-compose.prod.yml exec gateway-service sh
yarn migration:run
```

## Actualizar las variables de entorno

Si se actualiza el `.env` del proyecto `Procedures-Services-Launcher`, es necesario recontruir todos los contenedores con el siguiente comando
#### Para dev
```sh
docker compose up -d --force-recreate
```
#### Para prod
```sh
docker compose -f docker-compose.prod.yml up -d --force-recreate
```
Si se actualiza el `.env.compose` de un servicio ejecutar desde el proyecto padre
#### Para dev
```sh
docker compose up <nombre-servicio> -d --force-recreate
```
#### Para prod
```sh
docker compose -f docker-compose.prod.yml up <nombre-servicio> -d --force-recreate
```

## Pasos para añadir/crear los Git Submodules (un nuevo microservicio)

1. Crear un nuevo repositorio en GitHub
2. Copiar el Url de nuevo repositorio y añadir en el clonado del repositorio padre `Procedures-Services-Launcher` local ejecutar:
```sh
git submodule add <repository_url> <directory_name>
```
3. Añadir los cambios al repositorio `Procedures-Services-Launcher` (git add, git commit, git push) Ej:
```sh
git add .
git commit -m "Add submodule"
git push
```
## Pasos después de clonar el repositorio Procedures-Services-Launcher

1. Inicializar y actualizar Sub-módulos, cuando alguien clona el repositorio por primera vez, debe de ejecutar el siguiente comando para inicializar y actualizar los sub-módulos
```sh
git submodule update --init --recursive
```
2. Para actualizar las referencias de los sub-módulos
```sh
git submodule update --remote
```
## Importante

Si se trabaja en el repositorio que tiene los sub-módulos, primero actualizar y hacer push en el sub-módulo y después en el repositorio principal.

Si se hace al revés, se perderán las referencias de los sub-módulos en el repositorio principal y tendremos que resolver conflictos.


