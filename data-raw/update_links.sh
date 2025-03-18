#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to get the resolved repository path
path_resrepo() {
  echo "$PWD/$1"
}

# Read the current version from the file
version=$(< "$(path_resrepo 'data/version_meta/current_version_in_use_by_resrepo.meta')")

# Check that the version directory exists
if [[ ! -d "$(path_resrepo "versions/$version")" ]]; then
  echo "Error: the version $version does not exist!" >&2
  exit 1
fi

# Check that the data paths are NOT directories (should be a link or not exist)
if [[ -d "$(path_resrepo 'data/raw')" && ! -L "$(path_resrepo 'data/raw')" ]]; then
  echo "Error: data/raw should not be a directory, but a symbolic link to a directory" >&2
  exit 1
fi
if [[ -d "$(path_resrepo 'data/intermediate')" && ! -L "$(path_resrepo 'data/intermediate')" ]]; then
  echo "Error: data/intermediate should not be a directory, but a symbolic link to a directory" >&2
  exit 1
fi

# Define paths for versioned data directories
version_raw_path="$(path_resrepo "versions/$version/data/raw")"
version_intermediate_path="$(path_resrepo "versions/$version/data/intermediate")"
raw_path="$(path_resrepo 'data/raw')"
intermediate_path="$(path_resrepo 'data/intermediate')"

# If the link exists but points to the wrong directory, delete it
if [[ -L "$raw_path" && "$(readlink "$raw_path")" != "$version_raw_path" ]]; then
  rm "$raw_path"
fi
if [[ -L "$intermediate_path" && "$(readlink "$intermediate_path")" != "$version_intermediate_path" ]]; then
  rm "$intermediate_path"
fi

# If the link does not exist, create it
if [[ ! -L "$raw_path" ]]; then
  ln -s "$version_raw_path" "$raw_path"
  echo "Links updated"
fi
if [[ ! -L "$intermediate_path" ]]; then
  ln -s "$version_intermediate_path" "$intermediate_path"
fi

exit 0
