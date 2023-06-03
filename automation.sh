#!/bin/bash

# 1 - Perform an update of the package details and the package list at the start of the script.
apt update -y

#Initializing variables
myname='Snehal'
s3_bucket='upgrad-snehal'
timestamp=$(date '+%d%m%Y-%H%M%S')

# 2 - Installing the apache2 package if it is not already installed and Ensure that the apache2 service is running.
if [ $(dpkg --list | grep apache2 | cut -d ' ' -f 3 | head -1) == 'apache2' ]
then
        echo "Apache is already installed"
        echo "Checking for its state.."
        if [ $(systemctl status apache2 | grep disabled | cut -d ';' -f 2) == 'disabled' ]
        then
                systemctl enable apache2
                echo "Apache2 is enabled"
                systemctl start apache2
        else
                if [ $(systemctl status apache2 | grep active | cut -d ':' -f 2 | cut -d ' ' -f 2) == 'active' ]
                then
                        echo "Apache2 is already Running"
                else
                        systemct1 start apache2
                        echo "Apache2 started"
                fi
        fi
else
        echo "Apache2 not installed.."
        echo "Installing the Apache2"
        printf 'Y\n' | apt-get install apache2 -y
        echo "Installed Apache2.."
fi

# 3 - Creating a tar archive of apache2 access logs and error logs
tar -zvcf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

# 4 - Copying the archive to the S3 bucket and checking AWS CLI is installed or not
if [ $(dpkg --list | grep awscli | cut -d ' ' -f 3 | head -1) == 'awscli' ]
then
        aws s3 \
        cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
        s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
        echo "Added to s3 bucket.."
else
        echo "aws cli not installed..."
        apt install awscli -y
        aws s3 \
        cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
        s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
fi

# 5 - update data in inventory.html, if not present then created 
if [ -f "/var/www/html/inventory.html" ]; 
then
	printf "<p>" >> /var/www/html/inventory.html
	printf "\n\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 2,3)" >> /var/www/html/inventory.html
	printf "\t\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 4,5 | cut -d '.' -f 1)" >> /var/www/html/inventory.html
	printf "\t\t\t $(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 4,5 | cut -d '.' -f 2)" >> /var/www/html/inventory.html
	printf "\t\t\t\t$(ls -lrth /tmp/ | grep httpd | cut -d ' ' -f 6)" >> /var/www/html/inventory.html	
	printf "</p>" >> /var/www/html/inventory.html
	
else 
	touch /var/www/html/inventory.html
	printf "<p>" >> /var/www/html/inventory.html
	printf "\tLog Type\t\tDate Created\t\t\tType\t\t\tSize" >> /var/www/html/inventory.html
	printf "</p>" >> /var/www/html/inventory.html
	printf "<p>" >> /var/www/html/inventory.html

	printf "\n\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 2,3)" >> /var/www/html/inventory.html
	printf "\t\t$(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 4,5 | cut -d '.' -f 1)" >> /var/www/html/inventory.html
	printf "\t\t\t $(ls -lrth /tmp | grep httpd | cut -d ' ' -f 11 | cut -d '-' -f 4,5 | cut -d '.' -f 2)" >> /var/www/html/inventory.html
	printf "\t\t\t\t$(ls -lrth /tmp/ | grep httpd | cut -d ' ' -f 6)" >> /var/www/html/inventory.html

	printf "</p>" >> /var/www/html/inventory.html
	
fi

# 6 - Scheduling cronjob to run automation.sh
if [ -f "/etc/cron.d/automation" ];
then
	continue
else
	touch /etc/cron.d/automation
	printf "* * * * * root /root/Automation_Project/auotmation.sh" > /etc/cron.d/automation
fi
