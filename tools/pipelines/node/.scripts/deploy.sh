#!/bin/bash

set -e
REPO_PATH="/var/www/node-app"
BRANCH="master"
APP_NAME="node-app"

echo "--------------------------------"
echo "Trust directory..."
git config --global --add safe.directory $REPO_PATH

echo "Deployment started..."
cd $REPO_PATH

# fix PATH so npm is found
export PATH=$PATH:/usr/bin:/usr/local/bin

echo "Resetting local changes..."
git reset --hard
git clean -fd

echo "Checking out branch: $BRANCH"
git fetch origin
git checkout $BRANCH

echo "--------------------------------"
echo "Pulling the latest version of the app..."
git fetch origin
git pull origin $BRANCH
echo "--------------------------------"

if git diff --name-only HEAD@{1} HEAD | grep -E 'package(-lock)?\.json'; then
  echo "--------------------------------"
  echo "Dependencies changed, running npm install..."
  npm install
  echo "--------------------------------"
else
  echo "--------------------------------"
  echo "No dependency changes, skipping npm install."
  echo "--------------------------------"
fi

echo "--------------------------------"
echo "Building node-app App (optimized for low memory)..."

pm2 stop $APP_NAME || true
pm2 delete $APP_NAME || true

rm -rf build/ dist/ .cache/ node_modules/.cache/
rm -rf .tmp/

sync
echo 3 | sudo tee /proc/sys/vm/drop_caches || true

export NODE_OPTIONS="--max-old-space-size=1800"
export GENERATE_SOURCEMAP=false
export DISABLE_ESLINT_PLUGIN=true

killall node || true

echo "Starting build process..."
timeout 900 npm run build

echo "--------------------------------"
echo "Starting PM2 process: $APP_NAME"
pm2 start npm --name "$APP_NAME" -- run start
pm2 save
echo "--------------------------------"

echo "--------------------------------"
echo "Deployment finished successfully!"
echo "--------------------------------"