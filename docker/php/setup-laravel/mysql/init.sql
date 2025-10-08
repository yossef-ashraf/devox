-- Use the MYSQL_USER and MYSQL_PASSWORD environment variables
SET @user = '${MYSQL_USER}';
SET @password = '${MYSQL_PASSWORD}';

-- Check if the user exists
SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = @user) AS user_exists;

-- Create the user if it doesn't exist
CREATE USER IF NOT EXISTS @user@'%' IDENTIFIED BY @password;

-- Grant privileges
GRANT ALL PRIVILEGES ON `${MYSQL_DATABASE}`.* TO @user@'%';

-- Apply the changes
FLUSH PRIVILEGES;
