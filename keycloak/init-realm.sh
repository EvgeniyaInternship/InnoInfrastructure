#!/bin/bash
set -euo pipefail

kcadm=/opt/keycloak/bin/kcadm.sh

until "$kcadm" config credentials \
  --server http://keycloak:8080 \
  --realm master \
  --user "$KEYCLOAK_ADMIN_USER" \
  --password "$KEYCLOAK_ADMIN_PASSWORD"
do
  echo "Waiting for Keycloak"
  sleep 3
done

if ! "$kcadm" get "realms/$KEYCLOAK_REALM" >/dev/null 2>&1; then
  echo "Realm $KEYCLOAK_REALM was not found in Keycloak."
  exit 1
fi

for role in Admin Receptionist Doctor Patient; do
  "$kcadm" create roles -r "$KEYCLOAK_REALM" -s name="$role" >/dev/null 2>&1 || true
done

client_uuid=$("$kcadm" get clients -r "$KEYCLOAK_REALM" -q clientId="$KEYCLOAK_CLIENT_ID" --fields id --format csv --noquotes | tail -n 1)
if [ -z "$client_uuid" ] || [ "$client_uuid" = "id" ]; then
  "$kcadm" create clients -r "$KEYCLOAK_REALM" \
    -s clientId="$KEYCLOAK_CLIENT_ID" \
    -s enabled=true \
    -s protocol=openid-connect \
    -s publicClient=false \
    -s secret="$KEYCLOAK_CLIENT_SECRET" \
    -s standardFlowEnabled=true \
    -s serviceAccountsEnabled=true \
    -s directAccessGrantsEnabled=false \
    -s 'redirectUris=["http://localhost:5119/Auth/callback"]' \
    -s 'webOrigins=["http://localhost:5173","http://localhost:5082","http://localhost:5035"]'
else
  "$kcadm" update "clients/$client_uuid" -r "$KEYCLOAK_REALM" \
    -s enabled=true \
    -s publicClient=false \
    -s secret="$KEYCLOAK_CLIENT_SECRET" \
    -s standardFlowEnabled=true \
    -s serviceAccountsEnabled=true \
    -s 'redirectUris=["http://localhost:5119/Auth/callback"]' \
    -s 'webOrigins=["http://localhost:5173","http://localhost:5082","http://localhost:5035"]'
fi

"$kcadm" add-roles -r "$KEYCLOAK_REALM" \
  --uusername "service-account-$KEYCLOAK_CLIENT_ID" \
  --cclientid realm-management \
  --rolename manage-users \
  --rolename view-realm \
  --rolename view-users \
  --rolename query-users
