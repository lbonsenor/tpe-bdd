DROP TABLE futbolista CASCADE;

DROP TABLE dorsal CASCADE;

-- El predeterminado es MDY
SET
    datestyle = 'DMY';

-- Creación de tabla futbolista
CREATE TABLE futbolista (
    nombre VARCHAR(50) NOT NULL,
    posicion VARCHAR(20),
    edad int,
    altura NUMERIC(10, 2),
    pie VARCHAR(15),
    fichado DATE,
    equipo_anterior VARCHAR(50),
    valor NUMERIC(10, 2), -- Money no es tan preciso, y tampoco es muy probable que tengan un valor de un billón de dólares
    equipo VARCHAR(50) NOT NULL,
    PRIMARY KEY(nombre, equipo) -- Asumo que no se repiten los nombres dentro del mismo equipo
);

-- Creación de tabla dorsal
CREATE TABLE dorsal (
    jugador VARCHAR(50) NOT NULL,
    dorsal int NOT NULL,
    PRIMARY KEY(jugador, dorsal), -- Por las dudas de que existan despues nombres repetidos entre equipos
    FOREIGN KEY (jugador) REFERENCES futbolista(nombre) -- Clave foránea
);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Helper para insertar en el prox lugar disponible
CREATE
OR REPLACE FUNCTION assign_next_available_dorsal(team_name VARCHAR, player_name VARCHAR) RETURNS VOID AS $$ DECLARE next_dorsal INT := 13;

BEGIN -- Next available desde 13
LOOP IF NOT EXISTS (
    SELECT
        1
    FROM
        dorsal dp
        JOIN futbolista fp ON fp.nombre = dp.jugador
    WHERE
        dp.dorsal = next_dorsal
        AND fp.equipo = team_name
) THEN
INSERT INTO
    dorsal (jugador, dorsal)
VALUES
    (player_name, next_dorsal);

RETURN;

ELSE next_dorsal := next_dorsal + 1;

END IF;

END LOOP;

END;

$$ LANGUAGE plpgsql;

-- Función a ejecutar en inserción en jugador
CREATE
OR REPLACE FUNCTION player_validations_and_number() RETURNS TRIGGER AS $$ DECLARE available_dorsal INT;

BEGIN BEGIN CASE
    WHEN NEW.posicion ILIKE 'Portero' THEN available_dorsal := 1;

WHEN NEW.posicion ILIKE 'Defensa'
OR NEW.posicion ILIKE 'Defensa central' THEN available_dorsal := 2;

WHEN NEW.posicion ILIKE 'Lateral izquierdo' THEN available_dorsal := 3;

WHEN NEW.posicion ILIKE 'Lateral derecho' THEN available_dorsal := 4;

WHEN NEW.posicion ILIKE 'Pivote' THEN available_dorsal := 5;

WHEN NEW.posicion ILIKE 'Mediocentro'
OR NEW.posicion ILIKE 'Centrocampista'
OR NEW.posicion ILIKE 'Interior derecho'
OR NEW.posicion ILIKE 'Interior izquierdo' THEN available_dorsal := 8;

WHEN NEW.posicion ILIKE 'Mediocentro ofensivo'
OR NEW.posicion ILIKE 'Mediapunta' THEN available_dorsal := 10;

WHEN NEW.posicion ILIKE 'Extremo derecho' THEN available_dorsal := 7;

WHEN NEW.posicion ILIKE 'Extremo izquierdo' THEN available_dorsal := 11;

WHEN NEW.posicion ILIKE 'Delantero'
OR NEW.posicion ILIKE 'Delantero centro' THEN available_dorsal := 9;

ELSE RAISE NOTICE 'Posicion % desconocida',
NEW.posicion;

RETURN NULL;

END CASE
;

-- Si es repetido busco otro
IF EXISTS (
    SELECT
        1
    FROM
        dorsal,
        futbolista
    WHERE
        dorsal = available_dorsal
        AND dorsal.jugador = futbolista.nombre
        AND jugador != NEW.nombre
        AND NEW.equipo = (futbolista.equipo)
) THEN 

-- Alternativa según posición
CASE
    WHEN NEW.posicion ILIKE 'Portero' THEN IF NOT EXISTS (
        SELECT
            1
        FROM
            dorsal dp
            JOIN futbolista fp ON fp.nombre = dp.jugador
        WHERE
            dp.dorsal = 12
            AND fp.equipo = NEW.equipo
            AND fp.nombre != NEW.nombre
    ) THEN available_dorsal := 12;

PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);

RETURN NEW;

END IF;

WHEN NEW.posicion ILIKE 'Defensa'
OR NEW.posicion ILIKE 'Defensa central' THEN IF NOT EXISTS (
    SELECT
        1
    FROM
        dorsal dp
        JOIN futbolista fp ON fp.nombre = dp.jugador
    WHERE
        dp.dorsal = 6
        AND fp.equipo = NEW.equipo
        AND fp.nombre != NEW.nombre
) THEN available_dorsal := 6;

PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);

RETURN NEW;

END IF;

WHEN NEW.posicion ILIKE 'Extremo derecho' THEN IF NOT EXISTS (
    SELECT
        1
    FROM
        dorsal dp
        JOIN futbolista fp ON fp.nombre = dp.jugador
    WHERE
        dp.dorsal = 11
        AND fp.equipo = NEW.equipo
        AND fp.nombre != NEW.nombre
) THEN available_dorsal := 11;

PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);

RETURN NEW;

END IF;

WHEN NEW.posicion ILIKE 'Extremo izquierdo' THEN IF NOT EXISTS (
    SELECT
        1
    FROM
        dorsal dp
        JOIN futbolista fp ON fp.nombre = dp.jugador
    WHERE
        dp.dorsal = 7
        AND fp.equipo = NEW.equipo
        AND fp.nombre != NEW.nombre
) THEN available_dorsal := 7;

PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);

RETURN NEW;

END IF;

ELSE -- Default: no hay alternativas
PERFORM assign_next_available_dorsal(NEW.equipo, NEW.nombre);

RETURN NEW;

END CASE
;

END IF;

INSERT INTO
    dorsal (jugador, dorsal)
VALUES
    (NEW.nombre, available_dorsal);

RETURN NEW;

EXCEPTION
WHEN OTHERS THEN RAISE NOTICE 'Error procesando la fila: nombre: %, equipo: %  Error: %',
NEW.nombre,
NEW.equipo,
SQLERRM;

RETURN NULL;

-- Ignorar la fila inválida y continuar
END;

END;

$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER on_player_insert BEFORE
INSERT
    ON futbolista FOR EACH ROW EXECUTE PROCEDURE player_validations_and_number();

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Función para reporte estadístico
CREATE
OR REPLACE FUNCTION analisis_jugadores(dia DATE) RETURNS VOID AS $$ DECLARE r RECORD;

count_filas INT;

linea INT := 1;

BEGIN -- Validar que fecha no sea null
IF dia IS NULL THEN RAISE EXCEPTION 'Fecha inválida';

END IF;

-- Validar que existan fechas para realizar el análisis
SELECT
    COUNT(*) INTO count_filas
FROM
    futbolista
WHERE
    futbolista.fichado >= dia;

IF count_filas = 0 THEN RETURN;

END IF;

-- Printear headers
RAISE INFO '-------------------------------------------------------------------------------------';

RAISE INFO '------------------------------ANALISIS DE ASIGNACIONES-------------------------------';

RAISE INFO '-------------------------------------------------------------------------------------';

RAISE INFO 'Variable-----------------------Fecha------Qty-----Prom_Edad---Prom_Alt---Valor---#---';

RAISE INFO '-------------------------------------------------------------------------------------';

-- Reporte de pie preferido
FOR r IN
SELECT
    pie,
    TO_CHAR(fichado, 'YYYY-MM') AS mes_fichaje,
    COUNT(*) AS qty,
    ROUND(AVG(edad), 2) AS prom_edad,
    ROUND(AVG(altura), 2) AS prom_altura,
    ROUND(MAX(valor), 2) AS valor_maximo
FROM
    futbolista
WHERE
    fichado > dia
GROUP BY
    pie,
    TO_CHAR(fichado, 'YYYY-MM')
ORDER BY
    pie,
    mes_fichaje LOOP IF r.pie IS NOT NULL
    AND r.valor_maximo IS NOT NULL
    AND r.prom_edad IS NOT NULL
    AND r.prom_altura IS NOT NULL THEN RAISE INFO 'Pie: %                       %        %        %        %        %        %',
    r.pie,
    r.mes_fichaje,
    r.qty,
    r.prom_edad,
    r.prom_altura,
    r.valor_maximo,
    linea;

linea := linea + 1;

END IF;

END LOOP;

-- Reporte de equipos
linea := 1;

-- Reset 
FOR r IN
SELECT
    equipo,
    MIN(fichado) AS fecha_minima_fichaje,
    COUNT(*) AS qty,
    ROUND(AVG(edad), 2) AS prom_edad,
    ROUND(AVG(altura), 2) AS prom_altura,
    ROUND(MAX(valor), 2) AS valor_maximo
FROM
    futbolista
WHERE
    fichado > dia
GROUP BY
    equipo
ORDER BY
    valor_maximo DESC LOOP IF r.valor_maximo IS NOT NULL
    AND r.prom_edad IS NOT NULL
    AND r.prom_altura IS NOT NULL THEN RAISE INFO '%                                %        %        %        %        %      %',
    r.equipo,
    r.fecha_minima_fichaje,
    r.qty,
    r.prom_edad,
    r.prom_altura,
    r.valor_maximo,
    linea;

linea := linea + 1;

END IF;

END LOOP;

-- Reporte de dorsales
linea := 1;

-- Reset 
FOR r IN
SELECT
    dp.dorsal,
    MIN(fichado) AS fecha_minima_fichaje,
    COUNT(*) AS qty,
    ROUND(AVG(edad), 2) AS prom_edad,
    ROUND(AVG(altura), 2) AS prom_altura,
    ROUND(MAX(valor), 2) AS valor_maximo
FROM
    futbolista f
    JOIN dorsal dp ON f.nombre = dp.jugador
WHERE
    f.fichado > dia
GROUP BY
    dp.dorsal
ORDER BY
    valor_maximo DESC LOOP IF r.dorsal < 13
    AND r.valor_maximo IS NOT NULL
    AND r.prom_edad IS NOT NULL
    AND r.prom_altura IS NOT NULL THEN -- "Dorsales principales"
    RAISE INFO 'Dorsal: %                        %        %        %        %        %       %',
    r.dorsal,
    r.fecha_minima_fichaje,
    r.qty,
    r.prom_edad,
    r.prom_altura,
    r.valor_maximo,
    linea;

linea := linea + 1;

END IF;

END LOOP;

EXCEPTION
WHEN OTHERS THEN RAISE NOTICE 'Error al generar el reporte: %',
SQLERRM;

END;

$$ LANGUAGE plpgsql