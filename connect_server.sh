#!/bin/bash

# Define the target server and user
TARGET_SERVER="192.168.0.102"
USERNAME="coderorbit"
PASSWORD="5499"

# Optional: Specify the SSH port (default is 22)
PORT=22

BLOWFISH_SECRET= $PASSWORD

# Software packages to install
PACKAGES="curl php libapache2-mod-php php-mysql mysql-server zip unzip wget apache2"

PMA_VERSION="5.2.1"

# Function to check if SSH connection is successful
check_ssh_connection() {
    # Connect to the server
    echo "Connecting to $TARGET_SERVER as $USERNAME..."


    sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no $USERNAME@$TARGET_SERVER << EOF
		echo "Updating package list..."
		echo "$PASSWORD" | sudo -S apt-get update -y || { echo "Failed to update package list"; exit 1; }

		echo "Installing packages: $PACKAGES"
		echo "$PASSWORD" | sudo -S apt-get install -y $PACKAGES || { echo "Failed to install packages"; exit 1; }
		wget https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.zip || { echo "Failed to download phpMyAdmin."; exit 1; }
		echo "Download done & extracting phpMyAdmin..."
		unzip phpMyAdmin-${PMA_VERSION}-all-languages.zip
		echo "$PASSWORD" | sudo -S mv phpMyAdmin-${PMA_VERSION}-all-languages /usr/share/phpmyadmin
		rm phpMyAdmin-${PMA_VERSION}-all-languages.zip

		# Set up phpMyAdmin configuration
		echo "Configuring phpMyAdmin..."
		echo "$PASSWORD" | sudo -S mkdir -p /etc/phpmyadmin
		echo "$PASSWORD" | sudo -S cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php

		echo "$PASSWORD" | sudo -S sed -i "s/\['blowfish_secret'\] = '';/['blowfish_secret'] = '$BLOWFISH_SECRET';/" /usr/share/phpmyadmin/config.inc.php
		echo "$PASSWORD" | sudo -S bash -c "cat > /etc/apache2/conf-available/phpmyadmin.conf <<EOF
		Alias /phpmyadmin /usr/share/phpmyadmin

			<Directory /usr/share/phpmyadmin>
    				Options FollowSymLinks
    				DirectoryIndex index.php

    			<IfModule mod_php.c>
        			AddType application/x-httpd-php .php
        			php_flag magic_quotes_gpc Off
        			php_flag track_vars On
        			php_flag register_globals Off
        			php_value include_path .
   			</IfModule>

			</Directory>

<Directory /usr/share/phpmyadmin/setup>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>
EOF"

	# Enable phpMyAdmin configuration in Apache
	echo "Enabling phpMyAdmin in Apache..."
	sudo a2enconf phpmyadmin
	sudo systemctl reload apache2

	# Set file permissions
	echo "Setting permissions..."
	sudo chown -R www-data:www-data /usr/share/phpmyadmin



		echo "$PASSWORD" | sudo -S ufw allow 80/tcp
		echo "$PASSWORD" | sudo -S sudo ufw allow http
		echo "$PASSWORD" | sudo -S systemctl enable apache2
		echo "$PASSWORD" | sudo -S systemctl enable mysql
		echo "$PASSWORD" | sudo -S systemctl start apache2
		echo "$PASSWORD" | sudo -S systemctl start mysql
		echo "$PASSWORD" | sudo -S systemctl reload apache2
        	echo "All packages installed successfully!"
		sudo mysql
			CREATE USER 'shell'@'%' IDENTIFIED BY '5499';
			GRANT ALL PRIVILEGES ON *.* TO 'shell'@'%';
			FLUSH PRIVILEGES;
			SHOW GRANTS FOR 'shell'@'%';
EOF

    if [ $? -eq 0 ]; then
        echo "SSH connection to $REMOTE_HOST successful."
    else
        echo "Failed to connect to $REMOTE_HOST via SSH."
        exit 1
    fi
}




# Main script execution
echo "Starting SSH connection and remote installation process..."
check_ssh_connection
# Finalize installation
echo "phpMyAdmin installation complete!"
echo "You can access phpMyAdmin at http://$TARGET_SERVER/phpmyadmin"
