# Craft CMS - Atomic deploy action

This action will:

1. RSYNC you artifacts to a temporary deploy-cache directory
2. Create a unique release folder in a `releases` directory
3. Symlink to persistent files like .env and certain `storage` folders
4. Symlink the `current` folder to the new release

You can then run your post-deploy actions.
