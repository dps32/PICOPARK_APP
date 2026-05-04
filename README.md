# PICOPARK_APP

Estat actual de l'sprint APP/INICI:

- Menú principal amb àlies, selecció de servidor i botó PLAY.
- Connexió al servidor WebSocket des de Flutter.
- Sala d'espera amb la llista de jugadors connectats.

## Bots locals temporals

Per poder jugar en local encara que no hi hagi prou clients reals connectats:

- S'afegeixen bots automàticament en mode `Local`.
- El mínim per iniciar la partida es força a **3 jugadors**.
- Si hi ha menys jugadors reals, el client omple amb bots fins arribar al mínim.
- En local, en prémer PLAY amb el mínim complert, la partida passa a `playing` des del client.

## Arquitectura

L'app Flutter es connecta al servidor PICOPARK_SERVER, que combina dues peces:

- Joc en temps real per WebSocket per a la sala, la partida i els missatges d'estat.
- API REST de dades d'exemple sota `/api`, amb col·leccions estil MongoDB per a nivells, jugadors, partides, moviments i rècords de temps.

Flux resumit:

```text
Flutter APP
	|
	+--> WebSocket --> servidor de joc
	|
	+--> REST /api --> col·leccions MongoDB d'exemple
```

També hi ha un endpoint de salut a `GET /health` per comprovar ràpidament que el servidor està actiu.

## Base de dades

Al servidor general s'exposen aquestes col·leccions:

- `nivells`
- `jugadors`
- `partides`
- `moviments`
- `records_temps`

Relacions principals:

- `partides.nivell_id` fa referència a `nivells._id`
- `partides.jugador_ids[]` fa referència a `jugadors._id`
- `moviments.partida_id` fa referència a `partides._id`
- `moviments.jugador_id` fa referència a `jugadors._id`
- `records_temps.nivell_id` fa referència a `nivells._id`
- `records_temps.partida_id` fa referència a `partides._id`
- `records_temps.jugador_id` fa referència a `jugadors._id`

## Connexió real a MongoDB

Per activar MongoDB real al servidor:

1. Configura a [server/config.env](../PICOPARK_SERVER/server/config.env):
	- `MONGODB_URI=mongodb://localhost:27017`
	- `MONGODB_DB=picopark`
2. Desa les col·leccions d'exemple a Mongo:
	- `npm run mongo:seed` (des de la carpeta PICOPARK_SERVER)
3. Inicia el servidor:
	- `npm run dev`

Verificació ràpida:

- `GET /health` (inclou estat Mongo)
- `GET /api/mongo/status`
- `GET /api/schema`

## Desplegament hostejat (producció)

Per a un servidor hostejat, fes servir MongoDB real persistent (Atlas o instància dedicada) i activa mode estricte:

1. Configura aquestes variables a producció:
	- `MONGODB_URI=<uri real de MongoDB>`
	- `MONGODB_DB=picopark`
	- `MONGODB_REQUIRED=1`
2. Carrega dades inicials (un cop):
	- `npm run mongo:seed`
3. Inicia servidor amb PM2:
	- `npm run pm2:prod`

Amb `MONGODB_REQUIRED=1`, si Mongo no està disponible, l'API falla explícitament i no cau a JSON local.

## Com obtenir la URI de MongoDB

Si encara no tens MongoDB aplicat, tens 3 camins:

1. MongoDB Atlas (recomanat per hosting)
	- Crea compte a Atlas i un clúster.
	- Crea usuari de base de dades (Database Access).
	- Afegeix IPs permeses (Network Access).
	- Fes "Connect -> Drivers" i copia la URI `mongodb+srv://...`.
	- Exemples:
		- `mongodb+srv://user:password@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority`
		- `MONGODB_DB=picopark`

2. MongoDB local (dev)
	- URI: `mongodb://localhost:27017`
	- DB: `picopark`

3. MongoDB en VPS/VM
	- URI típica: `mongodb://user:password@ip_o_host:27017/?authSource=admin`
	- Obre firewall només per IPs necessàries i activa autenticació.

Després, posa la URI a `PICOPARK_SERVER/server/config.env` o com variable d'entorn del host i valida amb:

- `GET /api/mongo/status`
- `GET /health`

## PM2 (preparat)

S'ha afegit `PICOPARK_SERVER/ecosystem.config.cjs` amb perfil development i production.

Comandes útils (des de PICOPARK_SERVER):

- `npm run pm2:start`
- `npm run pm2:prod`
- `npm run pm2:restart`
- `npm run pm2:logs`
- `npm run pm2:list`
- `npm run pm2:stop`
- `npm run pm2:delete`
