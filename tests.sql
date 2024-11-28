-- Para ver por equipos el dorsal asignado
CREATE
OR REPLACE FUNCTION test() RETURNS VOID AS $$ DECLARE eq RECORD;

player RECORD;

BEGIN FOR eq IN (
    SELECT
        DISTINCT equipo
    FROM
        futbolista
) LOOP FOR player IN
SELECT
    dp.jugador,
    fp.posicion,
    dp.dorsal
FROM
    dorsal dp
    JOIN futbolista fp ON fp.nombre = dp.jugador
WHERE
    fp.equipo = eq.equipo
ORDER BY
    dp.dorsal LOOP RAISE NOTICE 'Equipo: %, Jugador: %, Posicion: %, Dorsal: %',
    eq.equipo,
    player.jugador,
    player.posicion,
    player.dorsal;

END LOOP;

END LOOP;

END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_dorsales() RETURNS VOID AS $$
DECLARE
    team_name VARCHAR(50);
    player_name VARCHAR(50);
    dorsal_number INT;
    position VARCHAR(20);
    player_team VARCHAR(50);
BEGIN
    FOR team_name IN 
        SELECT DISTINCT equipo
        FROM futbolista
    LOOP
        FOR player_name, dorsal_number IN
            SELECT dp.jugador, dp.dorsal
            FROM dorsal dp
            JOIN futbolista fp ON fp.nombre = dp.jugador
            WHERE fp.equipo = team_name
            GROUP BY dp.dorsal, dp.jugador
            HAVING COUNT(dp.dorsal) > 1
        LOOP
            FOR player_name, dorsal_number, position, player_team IN
                SELECT fp.nombre, dp.dorsal, fp.posicion, fp.equipo
                FROM dorsal dp
                JOIN futbolista fp ON fp.nombre = dp.jugador
                WHERE dp.dorsal = dorsal_number
                  AND fp.equipo = team_name
            LOOP
                RAISE NOTICE 'Repetido Dorsal: % para jugador: %, Posicion: %, Team: %', dorsal_number, player_name, position, player_team;
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;