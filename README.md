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
    ssh nombreusuario@pampero.itba.edu.ar
```

Subir archivos a pampero:

```
    scp jugadores-2022.csv username@pampero.itba.edu.ar:/home/username/
```
> hay que subir ```tpe-bdd-functions.sql``` y ```tests.sql```

Conexión a PostgreSQL:

```
    psql -h bd1.it.itba.edu.ar -U nombreusuario PROOF
```


| Importante! |
|-------------|
> No copiar directo los comandos de la guía de importación porque no reconoce el hyphen

### Importación de datos

#### Setear la fecha en el formato correspondiente:

``` 
    SET datestyle ='DMY'
```

> Obs! Copiar a futbolista_prueba y dorsal_prueba por las dudas

### Ejecución de los scripts

Para ejecutar desde la base de datos es:

```
    \i script.sql
```

#### Importar datos a tabla futbolista:

```
    \copy futbolista_prueba(nombre,posicion,edad,altura,pie,fichado,equipo_anterior,valor,equipo) from 'jugadores-2022.csv' delimiter ';' csv header
```


> Obs! No hace falta hacer un copy a dorsal pues eso se debe ejecutar automaticamente con el trigger !


#### Ejecutar funciones

```
    SELECT test();
```

```
    SELECT analisis_jugadores('YYYY-MM-DD');
```

### Observaciones adicionales:

