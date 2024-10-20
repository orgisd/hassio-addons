#!/bin/bash
set -e

# Get options
CONFIG_PATH=/data/options.json
KEY_PATH=/data/ssh_keys

HOSTNAME=$(jq --raw-output ".hostname" $CONFIG_PATH)
SSH_PORT=$(jq --raw-output ".ssh_port" $CONFIG_PATH)
USERNAME=$(jq --raw-output ".username" $CONFIG_PATH)

MONITOR_PORT=$(jq --raw-output ".monitor_port" $CONFIG_PATH)
GATETIME=$(jq --raw-output ".gatetime" $CONFIG_PATH)

REMOTE_FORWARDING=$(jq --raw-output ".remote_forwarding[]" $CONFIG_PATH)
LOCAL_FORWARDING=$(jq --raw-output ".local_forwarding[]" $CONFIG_PATH)

OTHER_SSH_OPTIONS=$(jq --raw-output ".other_ssh_options" $CONFIG_PATH)

# Generate ssh key
if [ ! -d "$KEY_PATH" ]; then
    echo "[INFO] Generating new SSH key"
    mkdir -p "$KEY_PATH"
    ssh-keygen -t rsa -b 4096 -f "${KEY_PATH}/autossh_rsa_key" -N ""
else
    echo "[INFO] Using existing SSH key"
fi

echo "[INFO] Public SSH key:"
cat "${KEY_PATH}/autossh_rsa_key.pub"

# Prepare ssh args
SSH_ARGS="-M ${MONITOR_PORT} -N -q -o ServerAliveInterval=20 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes ${USERNAME}@${HOSTNAME} -p ${SSH_PORT} -i ${KEY_PATH}/autossh_rsa_key"

# Add forwarding
if [ ! -z "$REMOTE_FORWARDING" ]; then
    while read -r line; do
        SSH_ARGS="${SSH_ARGS} -R ${line}"
    done <<< "$REMOTE_FORWARDING"
fi

if [ ! -z "$LOCAL_FORWARDING" ]; then
    while read -r line; do
        SSH_ARGS="${SSH_ARGS} -L ${line}"
    done <<< "$LOCAL_FORWARDING"
fi

# Wait for network
echo "[INFO] Waiting for successful ping to ${HOSTNAME}"
until ping -c1 $HOSTNAME >/dev/null 2>&1; do :; done
echo "[INFO] Ping to ${HOSTNAME} successful"

# Test ssh connection
echo "[INFO] Testing SSH connection"
ssh -o StirctHostKeyChecking=no -p $SSH_PORT $HOSTNAME 2>/dev/null || true

echo "[INFO] SSH Host Keys:"
ssh-keyscan -p $SSH_PORT $HOSTNAME || true

# Start autossh
SSH_ARGS="${SSH_ARGS} ${OTHER_SSH_OPTIONS}"
echo "[INFO] Command args: autossh ${SSH_ARGS}"
/usr/bin/autossh ${SSH_ARGS}
