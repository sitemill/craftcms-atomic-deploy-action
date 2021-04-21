# Craft CMS - Atomic deploy action

An all-in-one action to Rsync + Atomically deploy your Craft project.

It will:

1. RSYNC you artifacts to a temporary `deploy-cache` directory
2. Create a unique release folder in a `releases` directory
3. Symlink persistent files like .env and certain `storage` folders
4. Check the `craft` script can be executed
5. Symlink the `current` folder to the new release
6. Run any post deploy scripts

## Example

```yaml
  - name: Atomic Craft Deploy
    uses: sitemill/craftcms-atomic-deploy-action@main
    with:
      host: ${{ secrets.HOST }}
      port: ${{ secrets.PORT }}
      user: ${{ secrets.USER }}
      ssh_key: ${{ secrets.SSH_KEY }}
      remote_path: ${{ secrets.REMOTE_PATH }}
      post_deploy: |
        php craft db/backup
        php craft clear-caches/all
        php craft migrate/all
        php craft project-config/apply
```

Inspired by: https://nystudio107.com/blog/executing-atomic-deployments