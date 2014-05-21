#!/bin/bash

# =======================================================================
# 
# SugarEnt-7.2.0-centos-mysql.sh
#
# Script to automate installing a LAMP stack for Sugar Enterprise 7.2.0
# on CentOS 6.5.
#
# This script assumes that you have installed a generic CentOS system
# from a CentOS 6.5 distribution.  This script has been tested with
# the Live CD distribution of CentOS 6.5.
#
# Written by: Remy Malan
# Date: May 2014
# License: MIT
# =======================================================================

# ===================================================================
# User specified options:
#
#   1. SUGAR_ZIP_BASE
#      Specify a SugarCRM .zip file to unzip into the Apache dir.
#      NOTE: This should be placed into a folder named "zip" at the
#      top level of the location where this script runs from.
#      In SUGAR_ZIP_BASE, specify the root name of the .zip file;
#      e.g. SUGAR_ZIP_BASE="foo" for a file named "foo.zip".
#      If this variable is not set then no unzip will take place.
#
#   2. SUGAR_HTML_TARGET
#      Specify the name for the installation in the /var/www/html
#      directory.  This option is only useful if option 1. above is
#      being used; i.e. SUGAR_ZIP_BASE is not empty.
#
#   3. PHP_TIMEZONE
#      Timezone for php.ini file if you are using PHP 5.3 or greater.
#      Use format found in: www.php.net/manual/en/timezones.php
# ===================================================================

#SUGAR_ZIP_BASE="SugarEnt-7.2.0"
SUGAR_ZIP_BASE=""
SUGAR_HTML_TARGET="sugarcrm"
PHP_TIMEZONE="America/Los_Angeles"

# ===================================================================
# Setup time stamp and logging.
# ===================================================================

LOGDIR="log"
mkdir -p $LOGDIR

TIMESTAMP="$(date +%F_%H-%M-%S)"
LOG="$LOGDIR/install.$TIMESTAMP.log"

# ===================================================================
# Print header.
# ===================================================================

HEADER="======== Installing ========"
START="Starting install : $TIMESTAMP"

echo $HEADER
echo $START
echo $HEADER >> $LOG
echo $START >> $LOG

# ===================================================================
# Update the distro.
# ===================================================================

echo "Update base OS..."
yum update -y >> $LOG 2>&1

# ===================================================================
# Install Apache.
# ===================================================================

echo "Installing Apache..."
yum install httpd -y >> $LOG 2>&1

# ===================================================================
# Install PHP including modules needed by Sugar.
# Document ref:
#     http://support.sugarcrm.com/02_Documentation/01_Sugar_Editions/02_Sugar_Enterprise/Sugar_Enterprise_7.2/Installation_and_Upgrade_Guide/#PHP
# ===================================================================

echo "Installing PHP..."
yum install php -y >> $LOG 2>&1
yum install php-bcmath php-gd php-imap php-mbstring php-mysql -y >> $LOG 2>&1

# ===================================================================
# Modify PHP config parameters for Sugar.
# Document ref:
#     http://support.sugarcrm.com/02_Documentation/01_Sugar_Editions/02_Sugar_Enterprise/Sugar_Enterprise_7.2/Installation_and_Upgrade_Guide/#PHP
# ===================================================================

# To Do.  The install will run without this step.

# ===================================================================
# Install MySQL.
# ===================================================================

echo "Installing MySQL..."
yum install mysql -y >> $LOG 2>&1
yum install mysql-server -y >> $LOG 2>&1

# ===================================================================
# Install Elasticsearch
# Sugar 7.2 uses Elasticsearch v0.90.10.
# Note: Java is needed for Elasticsearch.
# Document ref:
#    http://support.sugarcrm.com/04_Find_Answers/02KB/02Administration/100Install/Installing_and_Administering_Elasticsearch_for_Sugar_7/
# ===================================================================

echo "Installing Elasticsearch..."
yum install java-1.7.0-openjdk -y >> $LOG 2>&1
ESVER="elasticsearch-0.90.10.noarch.rpm"
ESDIR="es_rpm"
ESPATH="$ESDIR/$ESVER"
mkdir -p $ESDIR
if [ -e $ESPATH ]
then
  echo "Already downloaded $ESVER."
  echo "Already downloaded $ESVER." >> $LOG
else
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$ESVER >> $LOG 2>&1
  mv $ESVER $ESDIR/
fi
rpm -Uvh $ESPATH  >> $LOG 2>&1

# ===================================================================
# IMPORTANT FOR CENTOS
# Allow Apache to call Elasticsearch.
# Specific for CentOS as SELinux is turned on by default.
# ===================================================================

echo "Allowing Apache to call web service (SELinux setsebool)."
echo "Allowing Apache to call web service (SELinux setsebool)." >> $LOG

setsebool -P httpd_can_network_connect=1

# ===================================================================
# Modify Elasticsearch config parameters for Sugar.
# The first time this script is run from its directory, it will copy
# the original elasticsearch config files to a local directory for
# backup.
#
# Document ref:
#    http://support.sugarcrm.com/04_Find_Answers/02KB/02Administration/100Install/Installing_and_Administering_Elasticsearch_for_Sugar_7/#ES_Configuration
# ===================================================================

ES_CONFIG_BAK="es_config_bak"
mkdir -p $ES_CONFIG_BAK

ES_YML="elasticsearch.yml"
YML_BAK_PATH="$ES_CONFIG_BAK/$ES_YML"

if [ ! -e $YML_BAK_PATH ]
then
  echo "Making backup of $ES_YML."
  echo "Making backup of $ES_YML." >> $LOG
  cp /etc/elasticsearch/$ES_YML $ES_CONFIG_BAK/
fi

ES_YML_TMP="$ES_YML.$$.tmp"
cat /etc/elasticsearch/$ES_YML > /tmp/$ES_YML_TMP
cat /tmp/$ES_YML_TMP | ./awk/mod_es_yml.awk > /etc/elasticsearch/$ES_YML
rm /tmp/$ES_YML_TMP

ES_SYSCONFIG="elasticsearch"
CONFIG_BAK_PATH="$ES_CONFIG_BAK/$ES_SYSCONFIG"

if [ ! -e $CONFIG_BAK_PATH ]
then
  echo "Making backup of $ES_SYSCONFIG."
  echo "Making backup of $ES_SYSCONFIG." >> $LOG
  cp /etc/sysconfig/$ES_SYSCONFIG $ES_CONFIG_BAK/
fi

ES_SYSCONFIG_TMP="$ES_SYSCONFIG.$$.tmp"
cat /etc/sysconfig/$ES_SYSCONFIG > /tmp/$ES_SYSCONFIG_TMP
cat /tmp/$ES_SYSCONFIG_TMP | ./awk/mod_es_sysconfig.awk > /etc/sysconfig/$ES_SYSCONFIG
rm /tmp/$ES_SYSCONFIG_TMP

# ===================================================================
# Patch /etc/httpd/conf/httpd.conf to allow over writes.
# Sugar installer will complain if this property is set to "None".
# Note: the command below should only over-write the first use of
# AllowOverride.
# ===================================================================

echo "Setting httpd config to allow overrides..."
echo "Setting httpd config to allow overrides..." >> $LOG
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# ===================================================================
# This is for PHP 5.3 or greater.
# Patch php.ini file with timezone info.
# Leave PHP_TIMEZONE option at top blank to skip this step.  If you skip
# this step with PHP 5.3 or greater, the install still works; however,
# many annoying error messages will show up in the sugarcrm.log file.
# ===================================================================

# To Do.
if [ -n $PHP_TIMEZONE ]
then
  echo "*** Need to implement PHP timezone updater. ***"
fi

# ===================================================================
# Unzip and process the sugarcrm.zip file if it was set above.
# To do: find name of top-level in zip file and remove hardwired
# "SugarEnt-Full-7.2.0"
# ===================================================================

if [ ! -z $SUGAR_ZIP_BASE ]
then
  if [ -f "zip/$SUGAR_ZIP_BASE.zip" ]
  then
    echo "Unzipping zip/$SUGAR_ZIP_BASE.zip..."
    echo "Unzipping zip/$SUGAR_ZIP_BASE.zip..." >> $LOG
    rm -rf /var/www/html/$SUGAR_HTML_TARGET
    rm -rf /var/www/html/SugarEnt-Full-7.2.0
    unzip zip/$SUGAR_ZIP_BASE.zip -d /var/www/html >> $LOG 2>&1 
    mv /var/www/html/SugarEnt-Full-7.2.0 /var/www/html/$SUGAR_HTML_TARGET
    chown apache:apache -R /var/www/html/$SUGAR_HTML_TARGET
    chmod 755 -R /var/www/html/$SUGAR_HTML_TARGET
  else
    echo "File not found: zip/$SUGAR_ZIP_BASE.zip..."
    echo "File not found: zip/$SUGAR_ZIP_BASE.zip..." >> $LOG
  fi
else
  echo "Sugar zip file base name not set: \$SUGAR_ZIP_BASE"
  echo "Sugar zip file base name not set: \$SUGAR_ZIP_BASE" >> $LOG
fi

# ===================================================================
# Start services.
# Use the restart command in case anything was running.
# ===================================================================

service httpd restart
service elasticsearch restart
service mysqld restart

# ===================================================================
# Completed.
# ===================================================================

FOOTER="Done : $TIMESTAMP"
echo $FOOTER
echo $FOOTER >> $LOG

