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

if [ ! -f "${INPUT_LOCAL_PATH}/${INPUT_RSYNC_IGNORE_FILE}" ]
then
echo "No rsync ignore file, creating ${INPUT_RSYNC_IGNORE_FILE} from defaults"
cat > ${INPUT_LOCAL_PATH}/${INPUT_RSYNC_IGNORE_FILE} << EOF
.github
node_modules
.rsyncignore
.idea
.git
.gitignore
package-lock.json
package.json
README.MD
webpack.mix.js
.bashrc
.openssh
.ssh
.vimrc
.env
.idea
/_src
/storage/backups/
/storage/composer-backups/
/storage/config-backups/
/storage/config-deltas/
/storage/logs/
/storage/runtime/
/web/cpresources/
EOF
fi

if [ "${INPUT_RSYNC}" = true ]
then
  echo "Rsync'ing with: ${INPUT_RSYNC_SWITCHES}"
  rsync ${INPUT_RSYNC_SWITCHES} --exclude-from "${INPUT_RSYNC_IGNORE_FILE}" -e "ssh -i $KEYFILE -o StrictHostKeyChecking=no -p ${INPUT_PORT}" "${INPUT_LOCAL_PATH}/" ${INPUT_USER}@${INPUT_HOST}:${INPUT_REMOTE_PATH}/${INPUT_REMOTE_CACHE_DIR}
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
  mkdir storage/runtime
  mkdir storage/logs
  mkdir storage/config-deltas
  mkdir storage/backups
fi

echo "Copying: ${INPUT_REMOTE_CACHE_DIR} -> releases/${GITHUB_SHA}"
cp -RT ${INPUT_REMOTE_CACHE_DIR} releases/${GITHUB_SHA}

if [ ! -d "releases/${GITHUB_SHA}" ];
then
  echo "Error: Could not create directory releases/${GITHUB_SHA}"
  exit 1
fi

echo "Symlinking: .env"
ln -nfs ${INPUT_REMOTE_PATH}/.env ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
echo "Symlinking: storage/backups"
ln -nfs ${INPUT_REMOTE_PATH}/storage/backups ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
echo "Symlinking: storage/logs"
ln -nfs ${INPUT_REMOTE_PATH}/storage/logs ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
echo "Symlinking: storage/runtime"
ln -nfs ${INPUT_REMOTE_PATH}/storage/runtime ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage
echo "Symlinking: storage/config-deltas"
ln -nfs ${INPUT_REMOTE_PATH}/storage/config-deltas ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}/storage

if [ -d "${INPUT_REMOTE_PATH}/current" ];
then
  echo "Deleting existing ${INPUT_REMOTE_PATH}/current"
  rm -rf ${INPUT_REMOTE_PATH}/current
fi
echo "Symlinking ${INPUT_REMOTE_PATH}/current to ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}"
ln -s ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA} ${INPUT_REMOTE_PATH}/current

cd ${INPUT_REMOTE_PATH}/releases/${GITHUB_SHA}
echo "Making craft command executable"
chmod a+x craft
${INPUT_POST_DEPLOY}

echo "Removing old releases"
cd ${INPUT_REMOTE_PATH}/releases && ls -t | tail -n +11 | xargs rm -rf

EOF