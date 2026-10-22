#!/usr/bin/env bash
# Runs before the reference solution: waits until Fulcio, Rekor and the
# workstation answer, so the solution never races the stack's start.
set -eu
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
for _ in $(seq 1 120); do
  if ws curl -fsS -o /dev/null http://fulcio-server.fulcio-system.svc/api/v1/rootCert 2>/dev/null \
     && ws curl -fsS -o /dev/null http://rekor-server.rekor-system.svc/api/v1/log 2>/dev/null \
     && ws test -s /etc/sigstore/trusted-root.json 2>/dev/null; then
    exit 0
  fi
  sleep 5
done
echo "Fulcio, Rekor or the workstation did not answer in time." >&2
exit 1
