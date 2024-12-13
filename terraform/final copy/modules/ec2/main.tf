resource "aws_launch_template" "ec2_template" {
  name          = "${var.project_name}-launch-template"
  image_id      = var.template_var.image_id
  instance_type = var.template_var.instance_type
  key_name      = var.template_var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [var.sg_ec2]
    subnet_id       = var.subnet_private_us_east_1a
  }

  user_data = base64encode(<<-EOF
#!/bin/bash

# Update the package manager
sudo apt-get update -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Nginx
sudo apt-get install -y nginx

# Variables
SECRET_NAME="token"
REPO_URL="https://github.com/HusnainIzhar/next-cicd.git"
APP_DIR="/home/ubuntu/app"

# Fetch the GitHub token from AWS Secrets Manager
GITHUB_TOKEN=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq -r '.token')

# Ensure the app directory exists
mkdir -p $APP_DIR
cd /home/ubuntu/app/next-cicd/my-app

# Clone the repository
if [ -d "next-cicd" ]; then
  echo "Repository already exists. Pulling latest changes..."
  cd next-cicd
  git reset --hard
  git pull origin main
else
  echo "Cloning the repository..."
  git clone https://$GITHUB_TOKEN@github.com/HusnainIzhar/next-cicd.git
  cd next-cicd
fi

# Navigate to the app directory
cd my-app

# Install dependencies
npm install

# Build the app
npm run build

# Install PM2 globally
sudo npm install -g pm2

# Restart the app with PM2
pm2 delete all
pm2 start npm --name "nextjs-app" -- start

# Configure Nginx
sudo bash -c 'cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF'

# Restart Nginx to apply the configuration
sudo systemctl restart nginx
            EOF
  )

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}
