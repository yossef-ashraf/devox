# MySQL Commands Reference

## Connecting to MySQL

```bash
# Connect to MySQL
mysql -u root -p

# Connect with specific user
mysql -u username -p database_name
```

## Database Management

```sql
-- Show all databases
SHOW DATABASES;

-- Create new database
CREATE DATABASE db_name;

-- Delete database
DROP DATABASE db_name;

-- Use specific database
USE db_name;

-- Show tables in database
SHOW TABLES;
```

## User and Permissions Management

```sql
-- Create new user
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';

-- Grant all privileges to user on database
GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'localhost';

-- Grant specific privileges
GRANT SELECT, INSERT, UPDATE ON database_name.* TO 'username'@'localhost';

-- Update privileges
FLUSH PRIVILEGES;

-- Show user privileges
SHOW GRANTS FOR 'username'@'localhost';

-- Delete user
DROP USER 'username'@'localhost';
```

## Backup and Restore

```bash
# Create database backup
mysqldump -u username -p database_name > backup_file.sql

# Backup without username (for current user)
mysqldump database_name > backup_file.sql

# Create compressed backup
mysqldump -u username -p database_name | gzip > backup_file.sql.gz

# Restore database from backup
mysql -u username -p database_name < backup_file.sql

# Restore from compressed file
gunzip < backup_file.sql.gz | mysql -u username -p database_name

# Transfer backup to another server
scp backup_file.sql root@server-ip:/path/to/destination/
```

## Useful MySQL Commands

```sql
-- Import SQL file
SOURCE /path/to/file.sql;

-- Show current database information
SELECT DATABASE();

-- Show current user
SELECT USER();

-- Show MySQL version
SELECT VERSION();

-- Exit MySQL
EXIT;
-- or
QUIT;
```