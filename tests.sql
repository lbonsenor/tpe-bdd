
-- Para ver por equipos el dorsal asignado

CREATE OR REPLACE FUNCTION test() RETURNS VOID AS $$
DECLARE
    eq RECORD;  -- This will hold each team (equipo) value.
    player RECORD;  -- This will hold each player's details (jugador, posicion, dorsal)
BEGIN
    -- Loop over each distinct team
    FOR eq IN (SELECT DISTINCT equipo FROM futbolista_prueba) 
    LOOP
        -- Get player details for the current team (equipo)
        FOR player IN 
            SELECT dp.jugador, fp.posicion, dp.dorsal
            FROM dorsal_prueba dp
            JOIN futbolista_prueba fp ON fp.nombre = dp.jugador
            WHERE fp.equipo = eq.equipo
            ORDER BY dp.dorsal
        LOOP
            RAISE NOTICE 'Equipo: %, Jugador: %, Posicion: %, Dorsal: %',
                eq.equipo, player.jugador, player.posicion, player.dorsal;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;