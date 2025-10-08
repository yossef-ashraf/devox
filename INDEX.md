# DevOps Repository Index

## 🚀 Quick Start Scripts

### LEMP Stack Deployment
- **`scripts/server-full-init.sh`** - Complete LEMP (Linux, Nginx, MySQL, PHP) stack with customizable settings
- **`scripts/server-init.sh`** - Basic LEMP setup for quick deployment
- **`scripts/server-start.sh`** - Advanced deployment with ZIP/SQL import capabilities

### Node.js & Modern Stack
- **`scripts/node-init.sh`** - Node.js with MySQL/MongoDB support
- **`scripts/n8n-setup.sh`** - n8n workflow automation with SSL

## 📚 Documentation

### Essential References
- **`docs/quick-reference.md`** - Most commonly used commands and troubleshooting

### Git Version Control
- **`docs/git/ssh-setup-and-repository-access.md`** - SSH key setup and repository access troubleshooting
- **`docs/git/git-commands-reference.md`** - Complete Git commands reference
- **`docs/git/release-tag-troubleshooting.md`** - GitHub release and tag creation fixes

### Server Administration
- **`docs/server/installation.md`** - Complete server software installation (Nginx, Node.js, Composer, Yarn)
- **`docs/server/nginx.md`** - Nginx configuration guide with WordPress optimization
- **`docs/server/ssl-setup.md`** - Complete SSL certificate setup (Let's Encrypt & Manual)
- **`docs/server/nginx-wordpress-ssl-guide.md`** - WordPress + Nginx + SSL complete setup
- **`docs/server/csr-guide.md`** - SSL certificate signing request guide
- **`docs/server/ssl-manual.md`** - Manual SSL certificate installation process

### Performance Testing
- **`docs/performance-testing/apache-benchmark-guide.md`** - Apache Benchmark (ab) load testing guide
- **`docs/performance-testing/Apache Benchmark (ab).pdf`** - Detailed PDF documentation

## 🛠️ DevOps & Infrastructure

### Containerization
- **`devops/docker/`** - Docker configurations and compose files for various stacks
  - `laravel/` - Laravel application containers
  - `nginx/` - Custom Nginx configurations
  - `node-mongo/` - Node.js with MongoDB stack
  - `node-sql/` - Node.js with SQL database stack
  - `php-sql-apache/` - PHP with Apache and SQL
  - `php-sql-nginx/` - PHP with Nginx and SQL
  - `setup-laravel/` - Complete Laravel development environment
  - `xdebug/` - PHP debugging configuration

### CI/CD Pipelines
- **`devops/pipelines/`** - GitHub Actions and CI/CD templates
  - `node/` - Node.js deployment pipelines
  - `php/` - PHP application pipelines
  - `pipeline/` - General pipeline configurations

### Database Management
- **`database/mysql/mysql-commands.md`** - Complete MySQL commands reference

## 🔧 Development Tools

### Workflow Automation
- **`tools/n8n/installation-guide.md`** - Complete n8n setup with systemd and SSL

### Content Management
- **`tools/strapi/deployment-guide.md`** - Strapi + Vite deployment guide for Ubuntu

### System Utilities
- **`tools/shell/file-monitoring-setup.md`** - Real-time file system monitoring with inotify-tools

## 🎯 Common Use Cases

### 1. Deploy a PHP Website
```bash
cd scripts/
./server-full-init.sh
# Edit variables in the script for your project
```

### 2. Setup Node.js Application
```bash
cd scripts/
./node-init.sh
# Configure database type (MySQL/MongoDB)
```

### 3. Install n8n Automation
```bash
cd scripts/
./n8n-setup.sh
# Access via https://your-domain.com
```

### 4. Quick Command Reference
```bash
# View essential commands
cat docs/quick-reference.md
```

## 📋 Script Features

### All Scripts Include:
- ✅ **Automatic system updates** - Keep your server current
- ✅ **Service management** - Nginx, MySQL, PHP-FPM configuration
- ✅ **Database setup** - Automated database and user creation
- ✅ **SSL certificate generation** - Let's Encrypt integration
- ✅ **Error handling** - Comprehensive error checking and recovery
- ✅ **Status monitoring** - Real-time service status verification

### Advanced Features:
- 🔄 **Git integration** - Automatic repository cloning and deployment
- 📦 **ZIP deployment** - Extract and deploy from ZIP archives
- 🗄️ **Database import** - Automatic SQL file import and setup
- 🔐 **SSL/TLS security** - Production-ready SSL configuration
- 🚀 **Process management** - PM2 for Node.js applications
- 📊 **Monitoring tools** - Built-in service health checks
- 🛡️ **Security hardening** - Firewall and security header configuration

## 🔧 Customization

Each script contains configurable variables at the top:
- Project name and paths
- Database credentials
- Domain names
- PHP/Node.js versions
- Git repository URLs

## 🆘 Troubleshooting

1. **Check service status**: `sudo systemctl status nginx mysql php8.1-fpm`
2. **View logs**: `sudo tail -f /var/log/nginx/error.log`
3. **Test configuration**: `nginx -t`
4. **Network issues**: Check firewall with `sudo ufw status`

## 📞 Support & Resources

### Quick Help
- **`docs/quick-reference.md`** - Essential commands and common solutions
- **Script logs** - All scripts provide detailed output for troubleshooting
- **Prerequisites** - Each script checks and installs required dependencies

### Documentation Structure
- **`scripts/`** - Ready-to-run deployment scripts
- **`docs/`** - Comprehensive guides and references
- **`devops/`** - Docker and CI/CD configurations
- **`database/`** - Database management tools
- **`tools/`** - Development and automation tools

### Best Practices
- Always test scripts in a development environment first
- Review script variables before execution
- Keep backups of important configurations
- Monitor logs during and after deployment

## 🎯 Repository Goals

This repository aims to provide:
- **Rapid Deployment** - Get servers running quickly with minimal configuration
- **Professional Standards** - Production-ready configurations and security
- **Learning Resource** - Well-documented examples for DevOps learning
- **Flexibility** - Easily customizable for different project needs
- **Reliability** - Tested scripts with comprehensive error handling