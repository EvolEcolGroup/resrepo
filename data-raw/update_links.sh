#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to get the resolved repository path
path_resrepo() {
  echo "$PWD/$1"
}

# Read the current version from the file
VERSION=$(<../../data/version_meta/current_version_in_use_by_resrepo.meta)

# Check that the version directory exists
if [[ ! -d ../../versions/$VERSION ]]; then
  echo "Error: the version $VERSION does not exist!" >&2
  exit 1
fi

# Check that the data paths are NOT directories (should be a link or not exist)
if [[ -d ../../data/raw]]; then
  echo "Error: data/raw should not be a directory, but a symbolic link to a directory" >&2
  exit 1
fi
if  [[ -d ../../data/intermediate]]; then
  echo "Error: data/intermediate should not be a directory, but a symbolic link to a directory" >&2
  exit 1
fi

# create the links (overwrite them if they exist already)
ln -sf ../../versions/$VERSION/raw ../../data/raw
ln -sf ../../versions/$VERSION/intermediate ../../data/intermediate

exit 0
