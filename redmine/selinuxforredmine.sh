#!/bin/bash

# 
# This file is a revision of 
#    http://www.redmine.org/attachments/download/4495/RedmineAndSELinux
# that is written by Sascha Sanches and is available at 
#    http://www.redmine.org/projects/redmine/wiki/RedmineAndSELinuxOnCentOS
#
# Fedora Linux 20 has a policy module passenger.pp that makes the job
# simpler.
#

#
#  Variables: change these to match your setup.
#

if [ $# -ge 1 ]; then
    RM_HOME=$1
else
    RM_HOME=/var/www/redmine
fi

if [ $# -ge 2 ]; then
    GEM_HOME=$2
else
    GEM_HOME=${RM_HOME}/.bundle
fi

if [ -z ${RM_HOME} -o ! -d ${RM_HOME} ]; then
	echo Error: The path to Redmine is not a valid path: ${RM_HOME}.
	exit 1
fi

APACHE_USER=apache

###########################################################
# These permissions are needed for Apache to run Redmine. #
###########################################################

#
# Base permissions.
#

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}
chmod -R u=rw,g=r,o-rwx ${RM_HOME}
chmod -R ug+X ${RM_HOME}
chcon -R -u system_u -t httpd_sys_content_t ${RM_HOME}

#
# Writable directories.
#

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/log
chcon -R -t httpd_log_t ${RM_HOME}/log

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/tmp
chcon -R -t httpd_tmpfs_t ${RM_HOME}/tmp

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/files
chcon -R -t httpd_sys_script_rw_t ${RM_HOME}/files

if [ ! -d ${RM_HOME}/public/plugin_assets ]; then
	echo Info: Creating directory ${RM_HOME}/public/plugin_assets.
fi
chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/public/plugin_assets
chcon -R -t httpd_sys_script_rw_t ${RM_HOME}/public/plugin_assets

#
# Set permission to the shared objects used by Ruby GEM files
#

find -P ${GEM_HOME} -type f -name "*.so*" -exec chcon -t lib_t {} \;

