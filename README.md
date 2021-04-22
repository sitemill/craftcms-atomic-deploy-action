# Craft CMS - Atomic deploy action

An action to Atomically deploy your Craft project.

**It will:**

1. **Rsync** your source files to your server. By default it will put them in a folder called `deploy-cache`, but you can ovveride this with `remote_cache_dir`
1. **Copy** the cached files into a unique `releases` directory
2. **Symlink** persistent files `.env` and the `backups`, `logs`, `runtime` and `config-deltas` folders
3. **Set** `craft` to be executable with `chmod a+x craft`
4. **Symlink** the `current` folder to the new release
5. **Run** any post deploy scripts defined in `post_deploy`

## Usage

__Settings:__

`host` - Your remote SSH server hostname/IP

`user` - Remote SSH server user

`ssh_key` - A private [SSH key](#creating-a-ssh-key)

`port` - Your SSH server port, defaults to 22 if none set.

`local_path` - Path to your local artifacts, defaults to `GITHUB_WORKSPACE`

`remote_path` - The absolute path to the root directory of you application something like `cd /var/www/vhosts/your-app`.

`rsync` - Whether to use rsync to sync the files to the `remote_cache_dir`. Defaults to `true`. Set this to false if you are uploading files in a different job.

`remote_cache_dir` - The directory from which the files will be deployed, defaults to `deploy-cache` if none set.

`post_deploy` - Run any post deploy scripts, these will be run in the `current` directory


## Example

```yaml

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout
        uses: actions/checkout@v2
        
      # >> Your build actions here <<

      - name: Atomic Craft Deploy
        uses: sitemill/craftcms-atomic-deploy-action@v1.0.0
        with:
          
          # Required settings
          host: ${{ secrets.HOST }}
          user: ${{ secrets.USER }}
          ssh_key: ${{ secrets.SSH_KEY }}
          remote_path: ${{ secrets.REMOTE_PATH }}
          
          # Optional settings (showing defaults)
          rsync: true
          local_path: ${{ github.workspace }}
          remote_cache_dir: deploy-cache
          port: 22
          post_deploy: |
            php craft db/backup
            php craft clear-caches/all
            php craft migrate/all
            php craft project-config/apply
```

## Files ignored by rsync

This action will look for an `.rsyncignore` file in your root directory, if not it will ignore the following files and folders by default:

```text
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
```

## Creating a SSH key
You can generate a key using `ssh-keygen -t rsa -b 4096 -m pem -f /tmp/key-github`. 

Place the public key on your remote server, and paste the private key into a github secret.