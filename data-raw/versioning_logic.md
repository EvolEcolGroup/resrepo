# Operations that you do to your own repository

## Set up versioning for the first time in a repository
1. Create the `version_resources` directory in the repository root.
2. Create the links from `data/raw` and `data/intermidiate` 
to `data/version_resources/initial`
3. Create meta information about the `initial` version in `data/version_meta`
4. Add git hooks to keep links up to date when changing branches, pulling
and other git operations

## Create a new version
1. Create a new directory in `version_resources` with the name 
of the new version
2. Create information about the new version in `data/version_meta`
3. Create the links from `data/raw` and `data/intermidiate`
to the new version

## Switch to a different branch with git
1. Run the `git checkout` command
2. Run the `git hooks` to update the links to the current version.


# Updating following operations by others on the repository

## Cloning someone else's repository
1. Clone the repository
2. Add the githooks to the repository
3. Ensure that `version_resources` has been created (the data have to come 
from outside the repository)
4. Ensure that the links from `data/raw` and `data/intermidiate` to
`data/version_resources` are up to date
3. Create links to 


