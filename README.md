# Craft CMS - Atomic deploy action

An action to Atomically deploy your Craft project.

It will:

1. Copy your source files into a unique `releases` directory
2. Symlink persistent files like `.env` and the `backups`, `logs`, `runtime` and `config-deltas` folders
3. Check the `craft` script can be executed
4. Symlink the `current` folder to the new release
5. Run any post deploy scripts

## Usage

This action presumes that you are first syncing your files to a cache folder with Rsync. This folder is set to `deploy-cache` by default, but you can change this by setting the`source_dir`. 

__Settings:__

`host` - Your remote SSH server hostname/ip

`user` - Remote SSH server user

`ssh_key` - A private SSH key, you can create a key using `ssh-keygen -t rsa -b 4096 -m pem -f /tmp/key-github` then place the public key on your remote server, and paste the private key in a github secret. This can be used for rsync'ing also.

`port` - Your SSH server port, defaults to 22 if none set.

`remote_path` - The absolute path to the root directory of you application something like `cd /var/www/vhosts/your-app`.

`source_dir` - The directory from which the files will be deployed, defaults to `deploy-cache` if none set.

`post_deploy` - Optional post deploy actions, one per line.

``
## Example

```yaml

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout
        uses: actions/checkout@v2
        
      # >> Your build actions here <<

      # Let's use a pre-made rsync action (you could just use a simple ssh action)
      - name: rsync deployments
          uses: burnett01/rsync-deployments@4.1
          with:
            switches: -avuhe --delete --no-perms --no-owner --no-group --no-times --exclude-from "rsync-ignore.txt" 
            path: ${GITHUB_WORKSPACE}
            remote_path: ${{ secrets.REMOTE_PATH }}/deploy-cache
            remote_host: ${{ secrets.HOST }}
            remote_port: ${{ secrets.PORT }}
            remote_user: ${{ secrets.USER }}
            remote_key: ${{ secrets.SSH_KEY }}
            
      - name: Atomic Craft Deploy
        uses: sitemill/craftcms-atomic-deploy-action@v1.0.0
        with:
          # Required settings
          host: ${{ secrets.HOST }}
          user: ${{ secrets.USER }}
          ssh_key: ${{ secrets.SSH_KEY }}
          remote_path: ${{ secrets.REMOTE_PATH }}
          # Optional settings
          source_dir: deploy-cache
          port: ${{ secrets.PORT }}
          post_deploy: |
            php craft db/backup
            php craft clear-caches/all
            php craft migrate/all
            php craft project-config/apply

```

Borrowed from: https://nystudio107.com/blog/executing-atomic-deployments