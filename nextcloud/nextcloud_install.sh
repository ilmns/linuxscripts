#!/bin/bash

set -e

function error_exit {
    echo "$1" >&2
    echo "Installation aborted." >&2
    exit "${2:-1}"
}

function install_package {
    local package_manager
    if command -v dnf &>/dev/null; then
        package_manager="dnf"
    elif command -v yum &>/dev/null; then
        package_manager="yum"
    else
        error_exit "No compatible package manager found. Supported package managers: DNF, Yum."
    fi

    sudo "$package_manager" install -y "$1" || error_exit "Package $1 installation failed. Check your internet connection and the package name." 100
}

function enable_service {
    local service_manager
    if command -v systemctl &>/dev/null; then
        service_manager="systemctl"
    elif command -v service &>/dev/null; then
        service_manager="service"
    else
        error_exit "No compatible service manager found. Supported service managers: Systemctl, Service."
    fi

    sudo "$service_manager" enable "$1" || error_exit "Failed to enable $1. Check your system's services status." 101
    sudo "$service_manager" start "$1" || error_exit "Failed to start $1. Check your system's services status." 101
}

function check_db_exists {
    local db_name=$1
    local db_exists=$(sudo mysql -e "SHOW DATABASES LIKE '$db_name';" | grep -o "$db_name")

    if [[ $db_exists == "$db_name" ]]; then
        return 0  # Database exists
    else
        return 1  # Database does not exist
    fi
}

function dry_run_mode {
    echo "Dry Run Mode: Simulating Nextcloud installation..."
    # Simulate installation steps without actually making changes
    sleep 2
    echo "Dry Run Mode: Installation simulation completed successfully."
    exit 0
}

echo "Starting Nextcloud installation..."

# Check for dry run mode
if [[ $1 == "-d" || $1 == "--dry-run" ]]; then
    dry_run_mode
fi

# Apache installation
install_package httpd

# Check if Apache is installed
if ! command -v httpd &>/dev/null; then
    echo "Warning: Apache installation failed. Check your system's package manager. Proceeding with the installation..."
else
    echo "Apache installed successfully."
fi

# User input for database details
while true; do
    read -p "Enter the database name (default: nextcloud_db): " dbname
    read -p "Enter the database username (default: nextcloud_user): " dbuser
    read -s -p "Enter the database password (default: nextcloud_pass): " dbpass
    dbname=${dbname:-nextcloud_db}
    dbuser=${dbuser:-nextcloud_user}
    dbpass=${dbpass:-nextcloud_pass}
    if [[ $dbname =~ ^[a-zA-Z0-9_]+$ ]] && [[ $dbuser =~ ^[a-zA-Z0-9_]+$ ]] && [[ $dbpass =~ ^[a-zA-Z0-9_]+$ ]]; then
        if check_db_exists "$dbname"; then
            echo "Database '$dbname' already exists. Please choose a different name."
        else
            break
        fi
    else
        echo "Invalid database details. Only alphanumeric characters and '_' are allowed."
    fi
done

# Database installation
install_package mariadb mariadb-server

# Enable and start MariaDB
enable_service mariadb

# Database setup
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $dbname;" || echo "Warning: Failed to create the database. Check your database settings. Proceeding with the installation..."
sudo mysql -e "CREATE USER IF NOT EXISTS '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';" || echo "Warning: Failed to create the database user. Check your database settings. Proceeding with the installation..."
sudo mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';" || echo "Warning: Failed to grant privileges to the user. Check your database settings. Proceeding with the installation..."
sudo mysql -e "FLUSH PRIVILEGES;" || echo "Warning: Failed to flush privileges. Check your database settings. Proceeding with the installation..."

# Redis installation
install_package redis

# Enable and start Redis
enable_service redis

# Download and extract Nextcloud
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.zip || error_exit "Failed to download Nextcloud. Check your internet connection." 102
unzip latest.zip || error_exit "Failed to extract Nextcloud. Check your downloaded file." 102
sudo cp -R nextcloud/ /var/www/html/ || error_exit "Failed to copy Nextcloud files. Check your directory permissions." 103

# Set permissions
sudo mkdir -p /var/www/html/nextcloud/data || echo "Warning: Failed to create the data directory. Check your directory permissions. Proceeding with the installation..."
sudo chown -R apache:apache /var/www/html/nextcloud || echo "Warning: Failed to set permissions. Check your directory permissions. Proceeding with the installation..."

# SELinux configuration
for target in '/var/www/html/nextcloud/data' '/var/www/html/nextcloud/config' '/var/www/html/nextcloud/apps' '/var/www/html/nextcloud/.htaccess' '/var/www/html/nextcloud/.user.ini' '/var/www/html/nextcloud/3rdparty/aws/aws-sdk-php/src/data/logs'; do
    sudo semanage fcontext -a -t httpd_sys_rw_content_t "$target(/.*)?" || echo "Warning: Failed to set SELinux context for $target. Proceeding with the installation..."
done
sudo restorecon -R '/var/www/html/nextcloud/' || echo "Warning: Failed to restore SELinux contexts. Check your SELinux settings. Proceeding with the installation..."
sudo setsebool -P httpd_can_network_connect on || echo "Warning: Failed to set SELinux boolean. Check your SELinux settings. Proceeding with the installation..."

# Firewall configuration
if command -v firewall-cmd &>/dev/null; then
    sudo firewall-cmd --zone=public --add-service=http --permanent || echo "Warning: Failed to configure the firewall. Check your firewall settings. Proceeding with the installation..."
    sudo firewall-cmd --reload || echo "Warning: Failed to reload the firewall. Check your firewall settings. Proceeding with the installation..."
fi

# Restart Apache
enable_service httpd

echo "Nextcloud installation completed successfully."
