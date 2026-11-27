# InnoInfrastructure

Shared Docker Compose stack for the Inno services. Each service repository keeps a `Dockerfile` only. This repository starts those images together with Keycloak, PostgreSQL, MongoDB, and SonarQube.

Check the service repositories out next to this one:

```
Inno/
  InnoInfrastructure/
  InnoAuthApi/AuthApi/Dockerfile
  InnoProfilesApi/ProfilesApi/Dockerfile
  InnoFacilityApi/FacilityApi/Dockerfile
  InnoAppointmentsApi/AppointmentsApi/Dockerfile
  InnoUI/inno-ui/Dockerfile
```

## Configuration

Copy `.env.example` to `.env`. Compose reads every service URL, database name, and password from that file. There are no fallback values in `docker-compose.yml`.

Set `KEYCLOAK_CLIENT_SECRET` to the confidential client secret for `KEYCLOAK_CLIENT_ID`. Create the realm named by `KEYCLOAK_REALM` in Keycloak (`inno-realm` in `.env.example`). On startup, Compose adds that client, the redirect `${AUTH_API_URL}/Auth/callback`, and the realm roles `Admin`, `Receptionist`, `Doctor`, and `Patient` when they are missing.

| Variable | Example | Used for |
| --- | --- | --- |
| `KEYCLOAK_BASE_URL` | `http://localhost:8080` | Keycloak hostname for the browser and the APIs |
| `AUTH_API_URL` | `http://localhost:5119` | Public Auth URL and the Keycloak redirect |
| `AUTH_API_INTERNAL_URL` | `http://auth-api:5119` | Profiles calling Auth inside the Docker network |
| `PROFILES_API_URL` | `http://localhost:5082` | UI build argument |
| `UI_URL` | `http://localhost:5173` | Page opened after login |
| `MONGO_DB`, `MONGO_USER`, `MONGO_PASSWORD` | `logs` / `logs` / `logs` | MongoDB and the log UI |

Database names and passwords for Keycloak, Profiles, Facility, and SonarQube are the matching `*_DB`, `*_DB_USER`, and `*_DB_PASSWORD` variables.

## Services

| Service | Address | Role |
| --- | --- | --- |
| keycloak | `KEYCLOAK_BASE_URL` | Identity provider. Bootstrap admin is `KEYCLOAK_ADMIN_USER` / `KEYCLOAK_ADMIN_PASSWORD` |
| keycloak-db | localhost:5435 | Keycloak PostgreSQL database |
| auth-api | `AUTH_API_URL` | Auth API. Logs to the MongoDB `auth` collection |
| profiles-db | localhost:5433 | Profiles PostgreSQL database |
| profiles-migrator | exits when migrations finish | Applies Profiles EF migrations |
| profiles-api | `PROFILES_API_URL` | Profiles API. Logs to the MongoDB `profiles` collection |
| facility-db | localhost:5434 | Facility PostgreSQL database. `001_init.sql` runs on an empty volume |
| facility-api | http://localhost:5035 | Facility API. Logs to the MongoDB `facility` collection |
| appointments-api | http://localhost:5096 | Appointments API |
| logs-db | localhost:27017 | MongoDB database `MONGO_DB` |
| logs-ui | http://localhost:8081 | Web UI for that MongoDB. No login |
| inno-ui | `UI_URL` | Web UI. Nginx serves the built app and proxies `/profiles` and `/facility` |
| sonarqube-db | localhost:5432 | SonarQube PostgreSQL database |
| sonarqube | http://localhost:9000 | SonarQube |

Long-running services have a healthcheck with 10 retries. Auth, Profiles, and Facility wait until the services they call are healthy. The UI image receives `AUTH_API_URL` and `PROFILES_API_URL` as `VITE_AUTH_API_URL` and `VITE_PROFILES_API_URL`.

Auth, Profiles, and Facility listen on their public ports and forward `127.0.0.1:8080` to the `keycloak` container, so `KEYCLOAK_BASE_URL` can stay `http://localhost:8080` in the browser and inside those containers. Profiles calls Auth at `AUTH_API_INTERNAL_URL`. Appointments listens on `http://localhost:5096` and does not forward Keycloak.

Serilog writes BSON documents to `logs-db`, database `MONGO_DB`. The URL is defined once as `x-mongo-logs-url` and Auth, Profiles, and Facility receive it as `Serilog__WriteTo__0__Args__databaseUrl`. The collection name stays in each of those APIs' `appsettings.json`: `auth`, `profiles`, or `facility`.

Host `dotnet run` does not read this `.env`. Point `ConnectionStrings:ProfilesDb` at `localhost:5433` and `ConnectionStrings:FacilityDb` at `localhost:5434`. Port 5432 is SonarQube.

## Commands

From this directory:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
docker compose ps
docker compose logs -f auth-api profiles-api facility-api appointments-api
docker compose down
```

`docker compose down -v` also deletes the database volumes.

## Logs

Open http://localhost:8081, then the `logs` database. The collections are `auth`, `profiles`, and `facility`.

From the shell:

```powershell
docker exec -it logs-db mongosh -u logs -p logs --authenticationDatabase admin logs
```

`db.auth` is a `mongosh` command, not the collection. Use `db.getCollection("auth")`.
