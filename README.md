# Trabajo Práctico Especial - Base de Datos I
## Grupo 4
### Integrantes:
* Lautaro Bonseñor
* Ana Negre
* Fernando Li
* Matías Leporini

### Acceso a Pampero e Importación

Ingreso a pampero:

``ssh nombreusuario@pampero.itba.edu.ar``

Conexión a PostgreSQL:

```psql -h bd1.it.itba.edu.ar -U nombreusuario PROOF```

Subir data a pampero:

```scp jugadores-2022.csv username@pampero.itba.edu.ar:/home/username/```

| Importante! |
|-------------|
> No copiar directo los comandos de la guía de importación porque no reconoce el hyphen

### Importación de datos


#### Setear la fecha en el formato correspondiente:

```SET datestyle ='DMY'```

> Obs! Copiar a futbolista_prueba y dorsal_prueba por las dudas

> Aún no importar porque faltan los triggers y etc

#### Importar datos a tabla futbolista:

```\copy futbolista_prueba(nombre,posicion,edad,altura,pie,fichado,equipo_anterior,valor_mercado,equipo) from 'jugadores-2022.csv' delimiter ';' csv header```


> Obs! No hace falta hacer un copy a dorsal pues eso se debe ejecutar automaticamente con el trigger !