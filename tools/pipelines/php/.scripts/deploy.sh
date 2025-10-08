#!/bin/bash

# Stop the script if any command fails
set -e

# Configuration
REPO_PATH="/home/project/htdocs/project.project.com"
BRANCH="master"
LOG_FILE="/var/log/deployment/$(date +'%Y-%m-%d_%H-%M-%S')_deploy.log"

# Colors for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO] $(date '+%Y-%m-%d %H:%M:%S')${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S')${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Ensure log directory exists
mkdir -p /var/log/deployment

log "Deployment started..."

# Validate paths
if [ ! -d "$REPO_PATH" ]; then
    error "Repository path does not exist: $REPO_PATH"
fi

log "Trusting Git directory..."
git config --global --add safe.directory "$REPO_PATH" || error "Failed to mark directory as safe."

# Navigate to repo
cd "$REPO_PATH" || error "Failed to enter directory: $REPO_PATH"

# Checkout desired branch
log "Checking out branch: $BRANCH"
git checkout "$BRANCH" || error "Failed to checkout branch $BRANCH"

# Clean and update code
log "Fetching latest changes from origin/$BRANCH..."
git fetch origin "$BRANCH" || error "Git fetch failed"
git reset --hard "origin/$BRANCH" || error "Git reset failed"  # Use reset instead of pull for clean state

log "Updating git submodules (if any)..."
git submodule update --init --recursive || true  # Optional: handle submodules

# Node.js dependencies
log "Installing NPM dependencies..."
npm ci || npm install || error "npm install failed"

log "Rebuilding esbuild and setting permissions..."
npm rebuild esbuild || true
find node_modules -name "esbuild" -type f -exec chmod +x {} \; 2>/dev/null || true
chmod -R 755 node_modules/.bin

log "Building frontend assets..."
npm run build || error "npm run build failed"

# Composer dependencies (PHP)
log "Installing Composer dependencies (production)..."
composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader || error "Composer install failed"

# Enter maintenance mode
log "Putting application into maintenance mode..."
php artisan down --render="errors::503" --secret="admin-enter" || true  # Graceful down

# Database migrations
log "Running database migrations..."
php artisan migrate --force || error "Migration failed"

# Clear and rebuild caches
log "Clearing and optimizing caches..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan event:clear
php artisan clear-compiled

log "Rebuilding cache..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan optimize || true  

log "Bringing application back online..."
php artisan up || true  

log "Deployment completed successfully!"