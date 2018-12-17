#!/bin/bash

# This file Sets up LCI/SAG development on a Vagrant Box.
# This file assumes it is being run as root.

# echo "Updating Ubuntu Sources. This will take a while."
apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1

# Installing APT packages
echo "Installing Packages..."
echo "...rbenv"
apt-get install -y rbenv  > /dev/null 2>&1
echo "...libreadline-dev"
apt-get install -y libreadline-dev  > /dev/null 2>&1
echo "...nodejs"
apt-get install -y nodejs  > /dev/null 2>&1
echo "...Postgresql"
apt install -y postgresql postgresql-contrib libpq-dev > /dev/null 2>&1

# rbenv MUST be installed as a single user (Vagrant).
# If it is installed as root, bad things will happen, and good things will fail to happen.
echo "Initialising rbenv"
su vagrant -c 'rbenv init' > /dev/null 2>&1
echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc

#  Install the ruby-build plugin for rbenv which will let rbenv install new versions of Ruby.
if [ ! -d /home/vagrant/.rbenv/plugins/ruby-build ]; then
	su vagrant -c 'git clone https://github.com/rbenv/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build' > dev/null 2>&1
else
	# Already installed; run an update instead.
	su vagrant vagrant-c 'pushd /home/vagrant/.rbenv/plugins/ruby-build; git pull' > dev/null 2>&1
fi

echo "Installing Ruby 2.5.1"
su vagrant -c 'rbenv install -s 2.5.1'
su vagrant -c 'rbenv global 2.5.1'

# # Globally install Rails
su vagrant -l -c 'gem install --install-dir /home/vagrant/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0 rails -v 4.2.10' 

# # Rehash Shims.
su vagrant -c 'rbenv rehash' 

# ########################################
# Postgresql

# fixing listen_addresses on postgresql.conf
# Uncomment the below if there are issues connecting to Postgres.
# sudo sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/9.1/main/postgresql.conf

# sudo cat >> /etc/postgresql/10/main/pg_hba.conf <<EOF
# # Accept all IPv4 connections - FOR DEVELOPMENT ONLY!!!
# host    all         all         0.0.0.0/0             md5
# EOF

su postgres -c "psql -c \"create user vagrant with password 'vagrant';\" "
su postgres -c "psql -c \"alter user vagrant with createdb;\" "
su postgres -c "psql -c \"alter user vagrant with superuser;\" "