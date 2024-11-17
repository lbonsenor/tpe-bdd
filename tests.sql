
-- Para ver por equipos el dorsal asignado

CREATE OR REPLACE FUNCTION test() RETURNS VOID AS $$
DECLARE
    eq RECORD;  
    player RECORD; 
BEGIN
    FOR eq IN (SELECT DISTINCT equipo FROM futbolista) 
    LOOP
        FOR player IN 
            SELECT dp.jugador, fp.posicion, dp.dorsal
            FROM dorsal dp
            JOIN futbolista fp ON fp.nombre = dp.jugador
            WHERE fp.equipo = eq.equipo
            ORDER BY dp.dorsal
        LOOP
            RAISE NOTICE 'Equipo: %, Jugador: %, Posicion: %, Dorsal: %',
                eq.equipo, player.jugador, player.posicion, player.dorsal;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;