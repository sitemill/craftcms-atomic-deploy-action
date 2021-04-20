#!/bin/bash
ssh-add <(echo "${INPUT_SSH_KEY}")

rsync -avuh --delete --progress -h -e "ssh -i ~/.ssh/gh_actions_key -o StrictHostKeyChecking=no -p ${INPUT_PORT}" --no-perms --no-owner --no-group --no-times --exclude-from "rsync-ignore.txt" --rsync-path="rsync" ${GITHUB_WORKSPACE}/ ${INPUT_USER}@${INPUT_HOST}:${INPUT_REMOTE_PATH}/deploy-cache

ssh ${INPUT_USER}@${INPUT_HOST} -p ${INPUT_PORT}

cd ${INPUT_REMOTE_PATH}

if [ ! -d "releases/${GITHUB_SHA}" ];
then
  echo "Creating: releases/${GITHUB_SHA}"
  mv deploy-cache releases/${GITHUB_SHA}
fi

echo "Creating: persistent directories"
mkdir -p storage

echo "Symlinking: persistent files & directories"
ln -nfs ${INPUT_REMOTE_PATH}/.env ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
ln -nfs ${INPUT_REMOTE_PATH}/storage/backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
ln -nfs ${INPUT_REMOTE_PATH}/storage/composer-backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
ln -nfs ${INPUT_REMOTE_PATH}/storage/config-backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
ln -nfs ${INPUT_REMOTE_PATH}/storage/logs ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
ln -nfs ${INPUT_REMOTE_PATH}/storage/runtime ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
echo "Linking current to revision: ${GITHUB_SHA}"
ln -sfn releases/${GITHUB_SHA} current
echo "Removing old releases"
cd releases && ls -t | tail -n +11 | xargs rm -rf

${INPUT_POST_DEPLOY_ACTIONS}