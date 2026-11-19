#!/usr/bin/env bash

set -Eeuo pipefail

project_id="cm-app-90d65"
emulator_pid=""

cleanup() {
  if [[ -n "$emulator_pid" ]] && kill -0 "$emulator_pid" 2>/dev/null; then
    kill "$emulator_pid" 2>/dev/null || true
    wait "$emulator_pid" 2>/dev/null || true
  fi
}

wait_for_port() {
  local port="$1"
  local attempt

  for ((attempt = 0; attempt < 90; attempt++)); do
    if ! kill -0 "$emulator_pid" 2>/dev/null; then
      echo "Firebase emulator process exited before port $port became available." >&2
      return 1
    fi

    if (echo >"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Timed out waiting for Firebase emulator port $port." >&2
  return 1
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

firebase emulators:start \
  --only auth,firestore,functions,storage \
  --project "$project_id" &
emulator_pid=$!

for port in 9099 8080 5001 9199; do
  wait_for_port "$port"
done

npm --prefix functions run seed:emulator

echo
echo "Emulators are running with seeded local data."
echo "Run the Flutter app with: flutter run --dart-define=USE_FIREBASE_EMULATORS=true"
echo "Press Ctrl+C here to stop the emulators."

wait "$emulator_pid"
