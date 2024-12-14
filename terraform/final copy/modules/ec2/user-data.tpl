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
              NAME = $(project_name)
              HOSTNAME=$(hostname)
              # Create an HTML file that displays the instance's hostname
              echo "<html>
              <head>
                  <title>EC2 Instance- $$NAME</title>
              </head>
              <body>
                  <h1>Welcome to your EC2 Instance!</h1>
                  <p>Your hostname is: \$$HOSTNAME</p>
              </body>
              </html>" | sudo tee /var/www/html/index.html > /dev/null