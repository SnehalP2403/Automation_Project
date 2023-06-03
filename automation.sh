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
