#!/bin/bash

echo "Remote cache dir: ${INPUT_REMOTE_CACHE_DIR}"
echo "Rsync ignore file: ${INPUT_RSYNC_IGNORE_FILE}"

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

if [ -z "${INPUT_LOCAL_PATH}" ]
then
  LOCAL_PATH="${GITHUB_WORKSPACE}"
else
  LOCAL_PATH="${INPUT_LOCAL_PATH}"
fi
echo "Local path: $LOCAL_PATH"

if [ ! -f "${LOCAL_PATH}/${INPUT_RSYNC_IGNORE_FILE}" ]
then
  echo "Creating rsync ignore file"
  cat > ${LOCAL_PATH}/${INPUT_RSYNC_IGNORE_FILE} << EOF
    .github
    node_modules
    .idea
    .git
    .gitignore
    package-lock.json
    package.json
    README.MD
    webpack.mix.js
    .bashrc
    conf
    logs
    .openssh
    .ssh
    ssl
    tmp
    .vimrc
    gitStatusTelegramBot.sh
    .env
    .idea
    _src
    storage/backups/
    storage/composer-backups/
    storage/config-backups/
    storage/config-deltas/
    storage/logs/
    storage/runtime/
    web/cpresources/
EOF
fi

if [ "${INPUT_RSYNC}" = true ]
then
  rsync ${INPUT_RSYNC_SWITCHES} --exclude-from "${INPUT_RSYNC_IGNORE_FILE}" -e "ssh -i $KEYFILE -o StrictHostKeyChecking=no -p ${INPUT_PORT}" "${LOCAL_PATH}/" ${INPUT_USER}@${INPUT_HOST}:${INPUT_REMOTE_PATH}/${INPUT_REMOTE_CACHE_DIR}
fi

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

  echo "Copying: ${INPUT_REMOTE_CACHE_DIR} -> releases/${GITHUB_SHA}"
  cp -RT ${INPUT_REMOTE_CACHE_DIR} releases/${GITHUB_SHA}

  if [ ! -d "releases/${GITHUB_SHA}" ];
  then
    echo "Error: Could not create directory releases/${GITHUB_SHA}"
    exit 1
  fi

  echo "Symlinking: persistent files & directories"
  ln -nfs ${INPUT_REMOTE_PATH}/.env ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
  ln -nfs ${INPUT_REMOTE_PATH}/storage/backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/logs ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/runtime ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
  ln -nfs ${INPUT_REMOTE_PATH}/storage/config-deltas ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage

  echo "Linking current to revision: ${GITHUB_SHA}"
  rm -f current
  ln -s releases/${GITHUB_SHA} current

  cd ${INPUT_REMOTE_PATH}/current
  echo "Make craft command executable"
  chmod a+x craft
  ${INPUT_POST_DEPLOY}

  echo "Removing old releases"
  cd ${INPUT_REMOTE_PATH}/releases && ls -t | tail -n +11 | xargs rm -rf

EOF