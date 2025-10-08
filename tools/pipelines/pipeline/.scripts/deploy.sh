#!/bin/bash

# Stop the script if any command fails
set -e

# Configuration
REPO_PATH="/home/project/htdocs/project.project.com" # Update this path to your actual WordPress installation
BRANCH="master"                     # The branch you are deploying from


echo "Trust directory..."
# Configure Git to trust the directory
git config --global --add safe.directory $REPO_PATH

echo "Deployment started..."
# Navigate to the repository
cd $REPO_PATH

# Ensure that you're on the correct branch
echo "Checking out branch: $BRANCH"
git checkout $BRANCH

# Discard any local changes and pull the latest changes from the branch
echo "Pulling the latest version of the app..."
git fetch origin
# git reset --hard origin/$BRANCH
git pull origin $BRANCH


echo "Deployment finished successfully!"