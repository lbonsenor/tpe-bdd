-- Creacion de tabla futbolista
CREATE TABLE futbolista_prueba (
    nombre          VARCHAR(50) NOT NULL,
    posicion        VARCHAR(20),
    edad            int NOT NULL,
    altura          NUMERIC(10,2),
    pie             VARCHAR(15),
    fichado         DATE,
    equipo_anterior VARCHAR(50),
    valor           NUMERIC(10,2), --money not as precise, also its unlikely they will have a billion dolar value--
    equipo          VARCHAR(50) NOT NULL,
    PRIMARY KEY(nombre, equipo) --asumo que no se repiten los nombres dentro del mismo equipo?
);

CREATE TABLE dorsal_prueba (
    jugador         VARCHAR(50) NOT NULL,
    dorsal          int NOT NULL,
    PRIMARY KEY(jugador, dorsal)
);