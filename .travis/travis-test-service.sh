#!/bin/bash
set -o errexit

echo "--- INFO -- $0 $$ -- executed" &> /dev/stderr
make test-service
