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

              # Update the package list
              sudo apt update -y

              # Install Apache
              sudo apt install -y apache2

              # Start the Apache service
              sudo systemctl start apache2

              # Enable Apache to start on boot
              sudo systemctl enable apache2

              # Get the hostname of the EC2 instance
              HOSTNAME=$(hostname)

              # Create an HTML file that displays the instance's hostname
              echo "<html>
              <head>
                  <title>EC2 Instance</title>
              </head>
              <body>
                  <h1>Welcome to your EC2 Instance!</h1>
                  <p>Your hostname is: \$HOSTNAME</p>
              </body>
              </html>" | sudo tee /var/www/html/index.html > /dev/null
            EOF
  )

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}
