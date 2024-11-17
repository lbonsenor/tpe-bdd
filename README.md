# Trabajo Práctico Especial - Base de Datos I
## Grupo 4
### Integrantes:
* Lautaro Bonseñor
* Ana Negre
* Fernando Li
* Matías Leporini

### Acceso a Pampero e Importación

Ingreso a pampero:

```
    ssh username@pampero.itba.edu.ar
```

Subir archivos a pampero:

```
    scp jugadores-2022.csv functions.sql tests.sql username@pampero.itba.edu.ar:/home/username/
```

Conexión a PostgreSQL:

```
    psql -h bd1.it.itba.edu.ar -U username PROOF
```

| ¡Importante! |
|--------------|
> No copiar directo los comandos de la guía de importación porque no reconoce el hyphen

### Importación de datos

#### Setear la fecha en el formato correspondiente:

``` 
    SET datestyle ='DMY'
```

### Ejecución de los scripts

Para ejecutar desde la base de datos es:

```
    \i tests.sql
    \i functions.sql
```

#### Importar datos a tabla futbolista:

```
    \copy futbolista(nombre,posicion,edad,altura,pie,fichado,equipo_anterior,valor,equipo) from 'jugadores-2022.csv' delimiter ';' csv header
```

#### Ejecutar funciones

```
    SELECT test();
```

```
    SELECT analisis_jugadores('YYYY-MM-DD');
```