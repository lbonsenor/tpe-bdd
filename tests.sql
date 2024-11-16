
SELECT * FROM  dorsal_prueba dp
            JOIN futbolista_prueba fp ON fp.nombre = dp.jugador
            AND fp.equipo = 'Argentinos Juniors' ORDER BY dorsal;

SELECT * FROM  dorsal_prueba dp
            JOIN futbolista_prueba fp ON fp.nombre = dp.jugador
            AND fp.equipo = 'Boca' ORDER BY dorsal;