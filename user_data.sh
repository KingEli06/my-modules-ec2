#!/bin/bash
# Update system and install Apache
sudo yum update -y
sudo yum install -y httpd

# Start Apache and enable it to run on boot
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a simple index.html file
sudo echo "<html><body><h1>WebForx warriors Hooyah!!! from $(hostname -f)</h1></body></html>" > /var/www/html/index.html