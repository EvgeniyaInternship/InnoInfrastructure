# InnoInfrastructure

Shared Docker Compose stack for the Inno services. The Auth and Profiles repositories keep a `Dockerfile` only. This repository starts those images together with Keycloak, PostgreSQL, and SonarQube.

Check the service repositories out next to this one:

```
Inno/
  InnoInfrastructure/
  InnoAuthApi/AuthApi/Dockerfile
  InnoProfilesApi/ProfilesApi/Dockerfile
  InnoFacilityApi/FacilityApi/Dockerfile
  InnoUI/inno-ui/Dockerfile
```

## Services

| Service | Address | Role |
| --- | --- | --- |
| keycloak | http://localhost:8080 | Identity provider. Admin user `admin` / `admin` |
| auth-api | http://localhost:5119 | Auth API, built from `InnoAuthApi/AuthApi/Dockerfile` |
| profiles-db | localhost:5433 | Profiles database (`profiles` / `profiles`) |
| profiles-migrator | exits when migrations finish | Applies Profiles EF migrations |
| profiles-api | http://localhost:5082 | Profiles API, built from `InnoProfilesApi/ProfilesApi/Dockerfile` |
| facility-db | localhost:5434 | Facility database (`facility` / `facility`). Schema comes from `001_init.sql` on first start |
| facility-api | http://localhost:5035 | Facility API, built from `InnoFacilityApi/FacilityApi/Dockerfile` |
| logs-db | localhost:27017 | MongoDB for application logs. Database `logs`, user `logs` |
| inno-ui | http://localhost:5173 | Web UI. Nginx proxies `/profiles` and `/facility` to those APIs |
| sonarqube-db | localhost:5432 | SonarQube database (`sonar` / `sonar`) |
| sonarqube | http://localhost:9000 | SonarQube |

Auth and Profiles call Keycloak at `http://localhost:8080`. Each API image listens on its public port and forwards `127.0.0.1:8080` to the `keycloak` container, so that URL is the same in the browser and inside the containers. Profiles calls Auth at `http://auth-api:5119`.

Copy `.env.example` to `.env` and set `KEYCLOAK_CLIENT_SECRET` to the confidential client secret for `dotnet-auth-service`. Create realm `inno-realm` in Keycloak. On startup, Compose adds that client, the redirect `http://localhost:5119/Auth/callback`, and the realm roles `Admin`, `Receptionist`, `Doctor`, and `Patient` when they are missing.

## Commands

From this directory:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
docker compose ps
docker compose logs -f auth-api profiles-api
docker compose down
```

`docker compose down -v` also deletes the database volumes.
