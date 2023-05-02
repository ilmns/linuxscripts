#!/bin/bash

# Variables
nextcloud_directory="/var/www/html/nextcloud" # Replace with your Nextcloud installation path
smtp_server=".."
smtp_port="587"
smtp_user="@."
smtp_password="PASSWORD"
smtp_encryption="tls"


# Install Postfix
sudo dnf install -y postfix

# Start and enable Postfix service
sudo systemctl enable --now postfix

# Configure Postfix to use the submission port with TLS encryption
sudo postconf -e 'submission inet n      -       n       -       -       smtpd'
sudo postconf -e 'syslog_name = postfix/submission'
sudo postconf -e 'smtpd_tls_security_level = encrypt'
sudo postconf -e 'smtpd_sasl_auth_enable = yes'
sudo postconf -e 'smtpd_client_restrictions = permit_sasl_authenticated,reject'

# Restart Postfix service
sudo systemctl restart postfix

# Change to Nextcloud directory
cd "$nextcloud_directory"

# Configure SMTP settings
sudo -u apache php occ config:app:set core mail_smtpmode --value="smtp"
sudo -u apache php occ config:app:set core mail_smtphost --value="$smtp_server"
sudo -u apache php occ config:app:set core mail_smtpport --value="$smtp_port"
sudo -u apache php occ config:app:set core mail_smtpauthtype --value="LOGIN"
sudo -u apache php occ config:app:set core mail_from_address --value="$smtp_user"
sudo -u apache php occ config:app:set core mail_domain --value="$(echo "$smtp_user" | cut -d'@' -f2)"
sudo -u apache php occ config:app:set core mail_smtpsecure --value="$smtp_encryption"
sudo -u apache php occ config:app:set core mail_smtpauth --value="1"
sudo -u apache php occ config:app:set core mail_smtpname --value="$smtp_user"
sudo -u apache php occ config:app:set core mail_smtppassword --value="$smtp_password"

echo "Nextcloud email server settings configured."
