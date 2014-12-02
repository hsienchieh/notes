#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#


#
# This script attempts to automate the process of setting up the latest
# version of Redmine on a recent version of Fedora Linux, e.g., 
# Fedora Linux 20. 
#
# This script is created by the author of the blog post at
#   http://notesofaprogrammer.blogspot.com/2014/12/a-script-to-install-redmine-on-fedora.html
#





#
# change password and hostname to your actual choices
#

PGDBPASSWD=my_password
HOSTNAME=localhost.localdomain


#
# Constants not suppose to be changed
#

BUNDLE=/usr/bin/bundle
WEBROOTPARENT=/var/www
APACHE_USER=apache
PG_USER=postgres
PG_DATA=/var/lib/pgsql/data 

#
# make sure necessary packages are present
#

echo -n "Info: installing ruby ruby-devel rubygem-bundler httpd mod_passenger 
    postgresql-server postgresql-devel gcc ImageMagick ImageMagick-devel        
    wget tar ... "

yum install -y -q \
    ruby ruby-devel rubygem-bundler \
    httpd \
    mod_passenger \
    postgresql-server postgresql-devel \
    gcc \
    ImageMagick ImageMagick-devel \
    wget \
    tar  > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to install required Fedora packages"
    exit 1
fi
echo "done"





#
# download the lastest version of Redmine 
#

# determine the latest version of Redmine
echo -n "Info: determining the latest version of Redmine ... "

redminefn=`wget -q http://www.redmine.org/releases/ -O - | \
    awk -e 'match($0, /href="redmine-.*.tar.gz"/) { 
            print substr($0, RSTART+length("href=\""),
                RLENGTH - length("href=\"") - 1) 
        }' | sort -r | head -1`

echo ${redminefn} | grep -q "^redmine-"

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to determine the lastest version of Redmine."
fi
echo "done [Redmine <= ${redminefn}]"


# switch to ${WEBROOTPARENT}
echo -n "Info: switch to directory ${WEBROOTPARENT} ... "

if [ ! -d ${WEBROOTPARENT} ]; then
	echo -e "\nError: directory ${WEBROOTPARENT} does not exist."
    exit 1
fi

cd ${WEBROOTPARENT}

if [ $? -ne 0 ]; then
    echo -e "\nError: cannot switch to directory ${WEBROOTPARENT}."
    exit 1
fi

echo "done"


# download Redmine

echo -n "Info: downloading Redmine ... "

redmineurl=http://www.redmine.org/releases/${redminefn}
wget -q ${redmineurl}

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to download Redmine archive ${redmineurl}."
    exit 1
fi
echo "done"


# extract Redmine

echo -n "Info: extracting Redmine ... "
redminedirname=`tar -ztf ${redminefn} | head -1 | sed -e "s/\/$//"`

tar -xzf ${redminefn}

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to extract Redmine archive ${redminefn}."
    exit 1
fi
echo "done"





#
# set up path variables
#

RM_HOME=${WEBROOTPARENT}/${redminedirname}
GEM_HOME=${RM_HOME}/.bundle
RAKE=${GEM_HOME}/ruby/bin/rake

if [ -z ${RM_HOME} -o ! -d ${RM_HOME} ]; then
	echo "Error: The path to Redmine is not a valid path: ${RM_HOME}"
	exit 1
fi








#
# initalize PostgreSQL database system
#

echo -n "Info: initialize PostgreSQL database ... "

if [ -d ${PG_DATA}/pg_hba.conf ]; then
    echo -e "\nWarn: it appears that PostgreSQL database has been intialized"
else
    postgresql-setup initdb
fi

systemctl -q enable postgresql.service
systemctl -q start postgresql.service

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to start PostgreSQL database server"
    exit 1
fi
echo "done"


# set up Redmine database role

echo -n "Info: setting up Redmine database role ... "

echo "SELECT rolname FROM pg_roles WHERE rolname='redmine';" | \
    su postgres -c psql | grep -q redmine
if [ $? -ne 0 ]; then
    su postgres -c \
        "echo \"CREATE ROLE redmine 
            LOGIN ENCRYPTED PASSWORD '${PGDBPASSWD}' 
            NOINHERIT VALID UNTIL 'infinity';\" | psql" 
    if [ $? -eq 0 ]; then
        echo "Created Redmine database role"
    else
        echo -e "\nError: failed to create Redmine database role."
        exit 1
    fi
else
    echo -e "\nWarn: Redmine database role is already in place."
fi

# create Redmine database

echo -n "Info: preparing Redmine database ... "

echo "SELECT datname FROM pg_database WHERE datname='redmine';" | \
    su postgres -c psql | grep -q redmine
if [ $? -ne 0 ]; then
    su postgres -c \
        "echo \"CREATE DATABASE redmine 
            WITH ENCODING='UTF8' OWNER=redmine;\" | psql"
    if [ $? -eq 0 ]; then
        echo "Created Redmine database"
    else
        echo -e "\nError: failed to create Redmine database."
        exit 1
    fi
else
    echo -e "\nWarn: Redmine database is already in place."
fi

grep -q "host redmine redmine ::1/128 md5" ${PG_DATA}/pg_hba.conf
if [ $? -ne 0 ]; then
    sed -e \
        "/host.*all.*all.*::1\/128.*ident/i host redmine redmine ::1/128 md5" \
        --in-place=.bu ${PG_DATA}/pg_hba.conf  
    echo "done"
else
    echo -e "\nWarn: ${PG_DATA}/pg_hba.conf aleady configured"
fi

echo -n "Info: restarting PostgreSQL database server ... "
systemctl -q restart postgresql.service
if [ $? -ne 0 ]; then
    echo -e "\nError: failed to restart postgresql.service"
    exit 1
fi
echo "done"




#
# config Redmine for database connection
#

echo -n "Info: configuring Redmine database connection ... "
if [ -f ${RM_HOME}/config/database.yml ]; then
    grep -q "username: redmine" ${RM_HOME}/config/database.yml
    if [ $? -eq 0 ]; then
        echo -e "\nWarn: ${RM_HOME}/config/database.yml already exists."
    else
        echo -e "\n\nproduction:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: ${PGDBPASSWD}
  encoding: utf8" >> ${RM_HOME}/config/database.yml
       echo "done"
    fi
else
  echo "production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: ${PGDBPASSWD}
  encoding: utf8" > ${RM_HOME}/config/database.yml
  echo "done"
fi





#
# install Redmine's Ruby dependencies
#

# make apache able to login
sed -e "s/^\(${APACHE_USER}:.*\)\/sbin\/nologin$/\1\/bin\/bash/" \
    --in-place=.bu /etc/passwd

chown -R ${APACHE_USER} ${RM_HOME}

echo -n "Info: installing Redmine Ruby dependencies usinb bundle ... "
cd ${WEBROOTPARENT}/${redminedirname}

su ${APACHE_USER} -c \
    "${BUNDLE} install --path ${GEM_HOME} --without development test"

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to install Ruby dependencies."
    exit 1
fi
echo "Installed Redmine Ruby dependencies."




#
# Generate Redmine's secrete token
#

echo -n "Info: generating Redmine secret token ... "
su ${APACHE_USER} -c "${BUNDLE} exec \"${RAKE} generate_secret_token\""

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to generate Redmine secret token"
    exit 1
fi
echo "generated Redmine secret token"




#
# load initial Remdine data
#
echo -n "Info: loading Redmine data to database ... "
su ${APACHE_USER} -c \
    "${BUNDLE} exec \"RAILS_ENV=production ${RAKE} db:migrate\""

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to loading Redmine data to database"
    exit 1
fi
echo "loaded Redmine data to database"




#
# Set up Redmine for Apache's Phusion Passenger module
#
echo -n "Info: configuring Phusion Passenger for Apache HTTP Server ... "

grep -q "ServerName ${HOSTNAME}" /etc/httpd/conf.d/passenger.conf
if [ $? -ne 0 ]; then
    echo "<VirtualHost *:80>
  SetEnv GEM_HOME ${GEM_HOME}/ruby
  ServerName ${HOSTNAME}
  DocumentRoot ${RM_HOME}/public
  <Directory ${RM_HOME}/public>
    AllowOverride all
    Options -MultiViews
  </Directory>
</VirtualHost>" >> /etc/httpd/conf.d/passenger.conf
else
    echo -e "\nWarn: it appears that the configuration for Phusion Passenger is already in place"
fi
echo "done"






#
# Set up permissions to run Redmine
#
echo -n "Info: setting up permissions ... "

mkdir -p ${RM_HOME}/tmp ${RM_HOME}/tmp/pdf ${RM_HOME}/public/plugin_assets

# Base permissions.

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}
chmod -R u=rw,g=r,o-rwx ${RM_HOME}
chmod -R ug+X ${RM_HOME}
chcon -R -u system_u -t httpd_sys_content_t ${RM_HOME}

# Writable directories.
chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/log
chcon -R -t httpd_log_t ${RM_HOME}/log

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/tmp
chcon -R -t httpd_tmpfs_t ${RM_HOME}/tmp

chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/files
chcon -R -t httpd_sys_script_rw_t ${RM_HOME}/files

# set up permissions
chown -R ${APACHE_USER}:${APACHE_USER} ${RM_HOME}/public/plugin_assets
chcon -R -t httpd_sys_script_rw_t ${RM_HOME}/public/plugin_assets

# Set permission to the shared objects used by Ruby GEM files
find -P ${GEM_HOME} -type f -name "*.so*" -exec chcon -t lib_t {} \;


# make sure SELinux is enforced
setenforce 1

systemctl -q enable httpd.service
systemctl -q start httpd.service

if [ $? -ne 0 ]; then
    echo -e "\nError: failed to start httpd.service."
    exit 1
fi
echo "done"




#
# clean up
#

# make apache nologin
sed -e "s/^\(${APACHE_USER}:.*\)\/bin\/bash$/\1\/sbin\/nologin/" \
    --in-place=.bu /etc/passwd
rm -f ${WEBROOTPARENT}/${redminefn}

#
# declare victory
# 
echo -e "\n\nInfo: finished setting up Redmine"
