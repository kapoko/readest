#!/usr/bin/env sh
set -eu

module_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir="$module_dir/data"
config_file="$config_dir/.env"

mkdir -p "$config_dir"

secret() {
  openssl rand -base64 48 | tr -d '\n'
}

token() {
  role="$1"
  node - "$JWT_SECRET" "$role" <<'NODE'
const crypto = require('crypto')
const [secret, role] = process.argv.slice(2)
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url')
const body = `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode({ role })}`
console.log(`${body}.${crypto.createHmac('sha256', secret).update(body).digest('base64url')}`)
NODE
}

if [ -f "$config_file" ]; then
  set -a
  . "$config_file"
  set +a
fi

POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(secret)}"
JWT_SECRET="${JWT_SECRET:-$(secret)}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-$(secret)}"
ANON_KEY="${ANON_KEY:-$(token anon)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(token service_role)}"
READEST_PUBLIC_URL="${READEST_PUBLIC_URL:-http://localhost:3030}"
READEST_S3_PUBLIC_URL="${READEST_S3_PUBLIC_URL:-http://localhost:9000}"
DATABASE_PASSWORD=$(node -p 'encodeURIComponent(process.argv[1])' "$POSTGRES_PASSWORD")

cat > "$config_file" <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_PORT=5432
POSTGRES_DB=postgres
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=3600
GOTRUE_DB_DATABASE_URL=postgres://supabase_auth_admin:$DATABASE_PASSWORD@db:5432/postgres
GOTRUE_DATABASE_URL=postgres://supabase_auth_admin:$DATABASE_PASSWORD@db:5432/postgres
GOTRUE_JWT_SECRET=$JWT_SECRET
GOTRUE_JWT_EXP=3600
PGRST_DB_URI=postgres://authenticator:$DATABASE_PASSWORD@db:5432/postgres
PGRST_JWT_SECRET=$JWT_SECRET
PGRST_APP_SETTINGS_JWT_SECRET=$JWT_SECRET
PGRST_APP_SETTINGS_JWT_EXP=3600
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_KEY=$SERVICE_ROLE_KEY
SUPABASE_PUBLIC_URL=$READEST_PUBLIC_URL
API_EXTERNAL_URL=$READEST_PUBLIC_URL
SITE_URL=$READEST_PUBLIC_URL
ADDITIONAL_REDIRECT_URLS=$READEST_PUBLIC_URL/**
GOTRUE_SITE_URL=$READEST_PUBLIC_URL
GOTRUE_URI_ALLOW_LIST=$READEST_PUBLIC_URL/**
DISABLE_SIGNUP=false
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=true
ENABLE_ANONYMOUS_USERS=false
PGRST_DB_SCHEMAS=public,graphql_public
MINIO_ROOT_USER=readest
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
S3_BUCKET_NAME=readest-files
S3_PUBLIC_ENDPOINT=$READEST_S3_PUBLIC_URL
S3_ACCESS_KEY_ID=readest
S3_SECRET_ACCESS_KEY=$MINIO_ROOT_PASSWORD
OBJECT_STORAGE_TYPE=s3
SELF_HOSTED=true
STORAGE_FIXED_QUOTA=1073741824
TRANSLATION_FIXED_QUOTA=50000
EOF

chmod 600 "$config_file"
