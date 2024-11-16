DROP TABLE futbolista_prueba CASCADE;
DROP TABLE dorsal_prueba CASCADE;

-- Preliminar pues el predeterminado es MDY
SET datestyle ='DMY';

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
    PRIMARY KEY(nombre, equipo) --asumo que no se repiten los nombres dentro del mismo equipo
);

-- Creacion de tabla dorsal 
CREATE TABLE dorsal_prueba (
    jugador         VARCHAR(50) NOT NULL,
    dorsal          int NOT NULL,
    PRIMARY KEY(jugador)
);


-- Helper para insertar en el prox lugar disponible
CREATE OR REPLACE FUNCTION assign_next_available_dorsal(team_name VARCHAR, player_name VARCHAR)
RETURNS VOID AS $$
DECLARE
    next_dorsal INT := 13;
BEGIN
    -- Next available desde 13
    LOOP
        IF NOT EXISTS (SELECT 1
            FROM dorsal_prueba dp
            JOIN futbolista_prueba fp ON fp.nombre = dp.jugador
            WHERE dp.dorsal = next_dorsal
            AND fp.equipo = team_name) THEN
            INSERT INTO dorsal_prueba (jugador, dorsal) VALUES (player_name, next_dorsal);
            RETURN;
        ELSE
            next_dorsal := next_dorsal + 1;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Funcion a ejecutar en insercion en jugador
CREATE OR REPLACE FUNCTION player_validations_and_number()
RETURNS TRIGGER AS $$
DECLARE
    available_dorsal INT;
BEGIN
    CASE
        WHEN NEW.posicion = 'Portero' THEN
            available_dorsal := 1;
        WHEN NEW.posicion IN ('Defensa', 'Defensa central') THEN
            available_dorsal := 2;
        WHEN NEW.posicion = 'Lateral izquierdo' THEN
            available_dorsal := 3;
        WHEN NEW.posicion = 'Lateral derecho' THEN
            available_dorsal := 4;
        WHEN NEW.posicion = 'Pivote' THEN
            available_dorsal := 5;
        WHEN NEW.posicion IN ('Mediocentro', 'Centrocampista', 'Interior derecho', 'Interior izquierdo') THEN
            available_dorsal := 8;
        WHEN NEW.posicion IN ('Mediocentro ofensivo', 'Mediapunta') THEN
            available_dorsal := 10;
        WHEN NEW.posicion = 'Extremo derecho' THEN
            available_dorsal := 7;
        WHEN NEW.posicion = 'Extremo izquierdo' THEN
            available_dorsal := 11;
        WHEN NEW.posicion IN ('Delantero', 'Delantero centro') THEN
            available_dorsal := 9;
        ELSE
            RAISE NOTICE 'Posicion % desconocida', NEW.posicion;
            RETURN NULL; 
    END CASE;
    
    -- Si es repetido busco otro available
    IF EXISTS (SELECT 1 FROM dorsal_prueba, futbolista_prueba WHERE dorsal = available_dorsal AND jugador != NEW.nombre AND NEW.equipo = (futbolista_prueba.equipo)) THEN
    RAISE NOTICE 'Dorsal para jugador % ya existe en % con dorsal %', NEW.nombre , NEW.equipo, available_dorsal;
        -- Alternativa según posición?
        CASE
            WHEN NEW.posicion = 'Portero' THEN
                IF NOT EXISTS (SELECT 1 FROM dorsal_prueba dp JOIN futbolista_prueba fp ON fp.nombre = dp.jugador WHERE dp.dorsal = 12 AND fp.equipo = NEW.equipo AND fp.nombre != NEW.nombre) THEN
                    available_dorsal := 12;
                ELSE
                    RAISE NOTICE 'YA HABIA UNO CON DORSAL 12';
                    PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);
                    RETURN NEW;
                END IF;
            WHEN NEW.posicion IN ('Defensa', 'Defensa central') THEN
                IF NOT EXISTS (SELECT 1 FROM dorsal_prueba dp JOIN futbolista_prueba fp ON fp.nombre = dp.jugador WHERE dp.dorsal = 6 AND fp.equipo = NEW.equipo AND fp.nombre != NEW.nombre) THEN
                    available_dorsal := 6;
                ELSE
                    RAISE NOTICE 'YA HABIA UNO CON DORSAL 6';
                    PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);
                    RETURN NEW;
                END IF;
            WHEN NEW.posicion = 'Extremo derecho' THEN
                IF NOT EXISTS (SELECT 1 FROM dorsal_prueba dp JOIN futbolista_prueba fp ON fp.nombre = dp.jugador WHERE dp.dorsal = 11 AND fp.equipo = NEW.equipo AND fp.nombre != NEW.nombre) THEN
                    available_dorsal := 11;
                ELSE
                    RAISE NOTICE 'YA HABIA UNO CON DORSAL 11';
                    PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);
                    RETURN NEW;
                END IF;
            WHEN NEW.posicion = 'Extremo izquierdo' THEN
                IF NOT EXISTS (SELECT 1 FROM dorsal_prueba dp JOIN futbolista_prueba fp ON fp.nombre = dp.jugador WHERE dp.dorsal = 7 AND fp.equipo = NEW.equipo AND fp.nombre != NEW.nombre) THEN
                    available_dorsal := 7;
                ELSE
                    RAISE NOTICE 'YA HABIA UNO CON DORSAL 7';
                    PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);
                    RETURN NEW;
                END IF;
            ELSE 
                -- Default no hay alternativas
                PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);
                RETURN NEW;
        END CASE;
      -- Default
    ELSE 
        RAISE NOTICE 'Dorsal para jugador % NO existe en % con dorsal %', NEW.nombre , NEW.equipo, available_dorsal;
    END IF;
    INSERT INTO dorsal_prueba (jugador, dorsal) VALUES (NEW.nombre, available_dorsal);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Trigger
CREATE TRIGGER on_player_insert
BEFORE INSERT ON futbolista_prueba
FOR EACH ROW
EXECUTE PROCEDURE player_validations_and_number();

