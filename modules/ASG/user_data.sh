#!/bin/bash
set -e

# Install base packages
dnf update -y
dnf install -y nginx php php-fpm php-mysqlnd wget tar unzip aws-cli jq

# Variables passed from Terraform
RDS_HOST="${RDS_HOST}"
SECRET_ARN="${SECRET_ARN}"
AWS_REGION="${AWS_REGION}"

# Fetch DB secrets from Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region $AWS_REGION --query SecretString --output text)
RDS_DB_NAME=$(echo "$SECRET_JSON" | jq -r '.db_name')
RDS_DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
RDS_DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')

# Start services
systemctl enable nginx
systemctl start nginx
systemctl enable php-fpm
systemctl start php-fpm

# Download WordPress
cd /var/www
wget https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
rm latest.tar.gz
chown -R nginx:nginx wordpress
chmod -R 755 wordpress

rm -f /etc/nginx/conf.d/default.conf

# Configure Nginx for WordPress
cat > /etc/nginx/conf.d/wordpress.conf <<'EOL'
server {
    listen 80;
    server_name _;

    root /var/www/wordpress;
    index index.php index.html index.htm;

    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        break;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|webp|svg)$ {
        expires 30d;
        access_log off;
    }
}
EOL

# PHP configuration tweaks
PHP_INI="/etc/php.ini"
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHP_INI
sed -i 's/memory_limit = .*/memory_limit = 256M/' $PHP_INI
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' $PHP_INI
sed -i 's/post_max_size = .*/post_max_size = 64M/' $PHP_INI
sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI

systemctl restart php-fpm
systemctl restart nginx

# Configure WordPress wp-config.php
cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sed -i "s/database_name_here/$RDS_DB_NAME/" /var/www/wordpress/wp-config.php
sed -i "s/username_here/$RDS_DB_USER/" /var/www/wordpress/wp-config.php
sed -i "s/password_here/$RDS_DB_PASS/" /var/www/wordpress/wp-config.php
sed -i "s/localhost/$RDS_HOST/" /var/www/wordpress/wp-config.php

chown -R nginx:nginx /var/www/wordpress
chmod -R 755 /var/www/wordpress

systemctl restart nginx
systemctl restart php-fpm


sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y amazon-cloudwatch-agent
# Create the CloudWatch Agent config file
cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    },
    "aggregation_dimensions": [
      [
        "AutoScalingGroupName"
      ]
    ]
  }
}
EOF

# Start the CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

# Enable agent to run on startup
systemctl enable amazon-cloudwatch-agent


