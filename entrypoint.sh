#!/bin/bash

SSHPATH="$HOME/.ssh"

if [ ! -d "$SSHPATH" ]
then
  mkdir "$SSHPATH"
fi

if [ ! -f "$SSHPATH/known_hosts" ]
then
  touch "$SSHPATH/known_hosts"
fi

echo "$INPUT_SSH_KEY" > "$SSHPATH/deploy_key"
KEYFILE="$SSHPATH/deploy_key"

chmod 700 "$SSHPATH"
chmod 600 "$SSHPATH/known_hosts"
chmod 600 "$SSHPATH/deploy_key"

ssh -i $KEYFILE -o StrictHostKeyChecking=no -p ${INPUT_PORT} ${INPUT_USER}@${INPUT_HOST}  << EOF

  cd ${INPUT_REMOTE_PATH}

  if [ ! -d "releases" ]
  then
    echo "Creating releases directory"
    mkdir releases
  fi

  if [ ! -d "storage" ]
  then
    echo "Creating storage directory"
    mkdir storage
  fi

  echo "Creating: releases/${GITHUB_SHA}"
  cp -RT ${INPUT_SOURCE_DIR} releases/${GITHUB_SHA}

  if [ ! -d "releases/${GITHUB_SHA}" ];
  then
    echo "Error: Could not create directory releases/${GITHUB_SHA}"
    exit 1
  fi

  echo "Make craft command executable"
  chmod a+x ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/craft

  echo "Symlinking: persistent files & directories"
  ln -nfs ${INPUT_REMOTE_PATH}/.env ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
  ln -nfs ${INPUT_REMOTE_PATH}/storage/backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/logs ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/runtime ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/config-deltas ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage

  echo "Linking current to revision: ${GITHUB_SHA}"
  rm -f current
  ln -s releases/${GITHUB_SHA} current

  cd current
  ${INPUTS_POST_DEPLOY}

  echo "Removing old releases"
  cd ${INPUT_REMOTE_PATH}/releases && ls -t | tail -n +11 | xargs rm -rf

EOF