# PICOPARK_APP

Estado actual del sprint APP/INICI:

- Main Menu con nickname, seleccion de servidor y boton PLAY.
- Conexion al servidor WebSocket desde Flutter.
- Waiting Room con lista de jugadores conectados.

## Bots locales temporales

Para poder jugar en local aunque no haya suficientes clientes reales conectados:

- Se anaden bots automaticamente en modo `Local`.
- El minimo para iniciar partida se fuerza a **3 jugadores**.
- Si hay menos jugadores reales, el cliente rellena con bots hasta llegar al minimo.
- En local, al pulsar PLAY con el minimo cumplido, la partida pasa a `playing` desde cliente.

## Notas

- En `Remote`, no se inyectan bots.
- El minimo de 3 jugadores tambien se aplica sobre los datos de sala recibidos.
