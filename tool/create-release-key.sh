#!/usr/bin/env bash
# Creates the dedicated release keystore (outside the repo) and android/key.properties.
# Run once. Prompts for the certificate owner name and the store/key password.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE_DIR="${HOME}/.android-keys"
KEYSTORE="${KEYSTORE_DIR}/expense-tracker-release.jks"
PROPS="${REPO_ROOT}/android/key.properties"
ALIAS="release"

if [ -e "$KEYSTORE" ]; then
  echo "Refusing to overwrite existing keystore: $KEYSTORE" >&2
  exit 1
fi

read -r -p "Your name (certificate CN): " OWNER_NAME
read -r -s -p "Keystore/key password (min 6 chars): " PASSWORD
echo
read -r -s -p "Repeat password: " PASSWORD2
echo
if [ -z "$OWNER_NAME" ]; then
  echo "Name must be non-empty." >&2
  exit 1
fi
if [ "$PASSWORD" != "$PASSWORD2" ]; then
  echo "Passwords do not match." >&2
  exit 1
fi
if [ "${#PASSWORD}" -lt 6 ]; then
  echo "Password must be at least 6 characters." >&2
  exit 1
fi

# Escape characters that are special in an X.500 DN (RFC 2253) so names with commas etc. are safe.
ESCAPED_NAME="$(printf '%s' "$OWNER_NAME" | sed -e 's/[\\,+"<>;=#]/\\&/g')"

mkdir -p "$KEYSTORE_DIR"
chmod 700 "$KEYSTORE_DIR"

# Pass the password via the environment so it never appears in `ps`.
export RELEASE_KEY_PASSWORD="$PASSWORD"
keytool -genkeypair -v \
  -keystore "$KEYSTORE" -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "CN=${ESCAPED_NAME}" \
  -storepass:env RELEASE_KEY_PASSWORD -keypass:env RELEASE_KEY_PASSWORD
unset RELEASE_KEY_PASSWORD
chmod 600 "$KEYSTORE"

umask 077
cat > "$PROPS" <<EOF
storeFile=${KEYSTORE}
storePassword=${PASSWORD}
keyAlias=${ALIAS}
keyPassword=${PASSWORD}
EOF
chmod 600 "$PROPS"

echo
echo "Created: $KEYSTORE"
echo "Wrote:   $PROPS (gitignored)"
echo "IMPORTANT: back up the keystore file AND its password (e.g. in a password manager)."
echo "Losing either means you can never update the installed app."
