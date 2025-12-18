#!/bin/bash
HOST="samikallinen@192.168.64.1"
CMD="/opt/homebrew/bin/op whoami"

echo "=== TEST 1: Current host-op (ControlMaster + TTY) ==="
ssh -t -q -o ControlPath=~/.ssh/host-op-control $HOST "$CMD"

echo -e "\n=== TEST 2: Compound Command (Force Signin + CMD) ==="
# Attempt to auth and run in one shell
ssh -t -q $HOST "/opt/homebrew/bin/op signin --force && $CMD"

echo -e "\n=== TEST 3: Pseudo-Interactive (Expect/script) ==="
# Check if a simple 'yes' or pipe keeps it alive? Unlikely.
# Checking environment of the remote shell
ssh -t -q $HOST "env | grep -E 'SSH|TERM|OP'"
