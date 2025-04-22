## Antes de ejecutar, revisar si se tiene la base de datos bien configurada con los schemas creados para cada microservicio

## Dev

1. Clonar el repositorio
2. Crear un .env basado en el .env.example
3. Ejecutar  el comando `git submodule update --init --recursive` para reconstruir los sub-modulos
4. para cada sub-modulo crear un .env basado en su propio .env. example
5. Ejecutar el comando `docker compose build --no-cache && docker compose up`

## Pasos para añadir/crear los Git Submodules (un nuevo microservicio)

1. Crear un nuevo repositorio en GitHub
2. Copiar el Url de nuevo repositorio y añadir en el clonado del repositorio padre MUSERPOL-MS local ejecutar:

git submodule add <repository_url> <directory_name>

3. Añadir los cambios al repositorio  MUSERPOL-MS (git add, git commit, git push) Ej:

git add .
git commit -m "Add submodule"
git push

## Pasos después de clonar el repositorio MUSERPOL-MS

1. Inicializar y actualizar Sub-módulos, cuando alguien clona el repositorio por primera vez, debe de ejecutar el siguiente comando para inicializar y actualizar los sub-módulos

git submodule update --init --recursive

2. Para actualizar las referencias de los sub-módulos

git submodule update --remote

## Importante

Si se trabaja en el repositorio que tiene los sub-módulos, primero actualizar y hacer push en el sub-módulo y después en el repositorio principal.

Si se hace al revés, se perderán las referencias de los sub-módulos en el repositorio principal y tendremos que resolver conflictos.

# Prod

## Introducción
### Nota
En producción las variables de entorno se estan pasando mediante el archivo docker-compose.prod, ahi se seleccionan los archivos .env que se usaran en 
cada microservicio, el .env del proyecto padre contiene las variables generales que se usan en dos o mas microservicios, como ser, la conexion con la base de datos, 
conexion con el servidor nats. En cada submodulo o microservicio, se encuentra un archivo .env.compose, en este archivo se colocan las variables unicas del servicio

### Pasos para levantar el proyecto
1. Clonar el repositorio
2. Crear el .env basado en el .env.template \
    Este archivo posee las variables que se heredaran a los microservicios mediante el archivo docker-compose.prod
3. Ejecutar el siguiente comando para inicializar los sub-modulos
```sh
git submodule update --init --recursive
``` 
4. En cada submodulo crear su propio .env.compose basado en el .env.compose.template \
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
7. Ingresar al contenedor de beneficiary-microservice y ejecutar sus migraciones y seeders
```sh
docker compose -f docker-compose.prod.yml exec beneficiary-microservice sh
yarn migration:run
yarn seed:run
```
7. Ingresar el contenedor microservice-gateway y ejecutar su migración
```sh
docker compose -f docker-compose.prod.yml exec microservice-gateway sh
yarn migration:run
```

