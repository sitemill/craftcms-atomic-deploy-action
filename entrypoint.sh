#!/bin/bash

# Authorize SSH Host
mkdir -p /root/.ssh && \
chmod 0700 /root/.ssh && \
ssh-keyscan github.com > /root/.ssh/known_hosts

# Add the keys and set permissions
touch /root/.ssh/id_rsa
echo "${INPUT_SSH_KEY}" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa

rsync -avuh --delete -h -e "ssh -o StrictHostKeyChecking=no -p ${INPUT_PORT}" --no-perms --no-owner --no-group --no-times --exclude-from "rsync-ignore.txt" --rsync-path="rsync" ${GITHUB_WORKSPACE}/ ${INPUT_USER}@${INPUT_HOST}:${INPUT_REMOTE_PATH}/deploy-cache

ssh ${INPUT_USER}@${INPUT_HOST} -p ${INPUT_PORT} << EOF

  cd ${INPUT_REMOTE_PATH}

  if [ ! -d "releases/${GITHUB_SHA}" ];
  then
    echo "Creating: releases/${GITHUB_SHA}"
    mkdir releases/${GITHUB_SHA}
    cp -R deploy-cache/. releases/${GITHUB_SHA}/
  fi

  echo "Checking Craft command is executable"
  chmod a+x ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/craft

  echo "Creating persistent directories"
  mkdir -p storage

  echo "Symlinking: persistent files & directories"
  ln -nfs ${INPUT_REMOTE_PATH}/.env ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
  ln -nfs ${INPUT_REMOTE_PATH}/storage/backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/logs ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/runtime ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/config-deltas ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage

  echo "Linking current to revision: ${GITHUB_SHA}"
  ln -sfn releases/${GITHUB_SHA} current

  echo "Removing old releases"
  cd releases && ls -t | tail -n +11 | xargs rm -rf

  echo "Running post-deploy scripts"
  cd ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
  ${INPUT_POST_DEPLOY}

EOF