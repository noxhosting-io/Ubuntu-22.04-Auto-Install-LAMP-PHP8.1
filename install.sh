#!/bin/bash

# This script automates the setup of a web server on a Debian-based system (like Ubuntu).
# It installs Apache, PHP 8.1, MariaDB, and other necessary tools.
# It also configures PHP with high resource limits and sets up a basic firewall.

# --- Script Configuration ---
# Set to non-interactive mode to avoid prompts during installation
export DEBIAN_FRONTEND=noninteractive

# --- 1. Update System Packages ---
echo "Updating package lists..."
sudo apt update
sudo apt upgrade -y

# --- 2. Install Core Dependencies & Web Server ---
echo "Installing Apache, FFmpeg, and other utilities..."
sudo apt install -y apache2 ffmpeg software-properties-common tar unzip git redis-server curl

# --- 3. Add PHP 8.1 Repository ---
echo "Adding PPA for PHP 8.1..."
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

# --- 4. Install PHP 8.1 and Extensions ---
echo "Installing PHP 8.1 and required extensions..."
sudo apt install -y php8.1 php8.1-fpm php8.1-common php8.1-cli php8.1-gd php8.1-mysql php8.1-mbstring php8.1-bcmath php8.1-xml php8.1-curl php8.1-zip
# Enable the PHP-FPM module for Apache
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.1-fpm
sudo systemctl restart apache2

# --- 5. Configure PHP Settings (php.ini) ---
echo "Configuring PHP settings for high limits..."
# Define the path to the PHP-FPM configuration file
PHP_INI_PATH="/etc/php/8.1/fpm/php.ini"

# IMPORTANT: Setting memory to 100G is extremely high and not recommended
# for most servers. Adjust if necessary for your environment.
sudo sed -i 's/memory_limit = .*/memory_limit = 100G/' $PHP_INI_PATH
sudo sed -i 's/post_max_size = .*/post_max_size = 100G/' $PHP_INI_PATH
sudo sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100G/' $PHP_INI_PATH
sudo sed -i 's/max_execution_time = .*/max_execution_time = 3600/' $PHP_INI_PATH
sudo sed -i 's/max_input_time = .*/max_input_time = 3600/' $PHP_INI_PATH

# Enable error display for development purposes
echo "Enabling display_errors in php.ini..."
sudo sed -i 's/display_errors = .*/display_errors = On/' $PHP_INI_PATH
sudo sed -i 's/display_startup_errors = .*/display_startup_errors = On/' $PHP_INI_PATH

# Restart PHP-FPM to apply changes
echo "Restarting PHP-FPM service..."
sudo systemctl restart php8.1-fpm

# --- 6. Install and Configure Database (MariaDB) ---
echo "Installing MariaDB server..."
sudo apt install -y mariadb-server

# NOTE: The following command is INTERACTIVE.
# You will be prompted to set a root password and configure security options.
# For a fully automated script, this would need to be handled differently.
echo "Starting MariaDB secure installation (requires manual input)..."
sudo mysql_secure_installation

# --- 7. Install phpMyAdmin ---
echo "Installing phpMyAdmin..."
# This will prompt for configuration choices. We choose apache2 and configure automatically.
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo apt install -y phpmyadmin

# --- 8. Install Composer (PHP Package Manager) ---
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# --- 9. Install SSL Certificate Tool (Certbot for Let's Encrypt) ---
echo "Installing Certbot for SSL..."
sudo apt install -y certbot python3-certbot-apache

# NOTE: The following command is INTERACTIVE.
# It will guide you through obtaining an SSL certificate for your domain(s).
# You will need to provide an email and agree to the terms.
echo "To obtain an SSL certificate, run the following command and follow the prompts:"
echo "sudo certbot --apache"

# --- 10. Configure Firewall (UFW) ---
echo "Configuring firewall (UFW)..."
# We are using UFW (Uncomplicated Firewall) as it's simpler than raw iptables.
sudo apt install -y ufw
sudo ufw allow 'Apache Full' # Allows both HTTP (80) and HTTPS (443)
sudo ufw allow 'OpenSSH'     # Allows SSH (22)
sudo ufw --force enable

# --- 11. Final Steps ---
echo "Restarting Apache to ensure all changes are applied..."
sudo systemctl restart apache2

echo "Installation script finished!"
echo "--------------------------------"
echo "To verify the PHP version, run:"
php -v
echo "--------------------------------"
echo "Your firewall is active. Current status:"
sudo ufw status
echo "--------------------------------"

