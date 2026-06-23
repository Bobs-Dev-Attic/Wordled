#!/usr/bin/env bash
#
# Build script run by Vercel. Vercel's build image has no Flutter SDK, so we
# fetch a pinned stable release, build the web app with assets bundled locally
# (so it works offline), then generate the offline service worker.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.3}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux"

echo "==> Installing Flutter ${FLUTTER_VERSION}"
if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  curl -fsSL -o "/tmp/${ARCHIVE}" "${BASE_URL}/${ARCHIVE}"
  mkdir -p "$(dirname "${FLUTTER_HOME}")"
  tar xf "/tmp/${ARCHIVE}" -C "$(dirname "${FLUTTER_HOME}")"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"
git config --global --add safe.directory "${FLUTTER_HOME}" || true

echo "==> Flutter version"
flutter --version

echo "==> Fetching dependencies"
flutter pub get

echo "==> Building web (release, offline-capable)"
flutter build web --release --no-web-resources-cdn

echo "==> Generating offline service worker"
node tool/gen_service_worker.js build/web

echo "==> Done. Output in build/web"
