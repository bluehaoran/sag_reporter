#!/bin/bash

# This file Sets up LCI/SAG development on a Vagrant Box.
#
# There are some known issues with the provisioning and this may occasionally fail. 
# As far as we can tell, this is because of a bug in apt-get and not in our script.
# If this happens, this script can be rerun to fix things manually.
#
# sudo /sag_reporter/vagrant-provision.sh

# This file assumes it is being run as root.
if [ "$USER" = "root" ]; then
	echo 'root user successfully detected'
else
	echo "root user not detected. Failing provision script."
	exit 1
fi

echo '##############################################################'
echo "Updating Ubuntu Sources. This will take a while."
apt-get update -y > /dev/null 2>&1
echo "Return Value: $?"

echo '##############################################################'
echo "Updating Ubuntu Packages. This will take a while."
apt-get upgrade -y > /dev/null 2>&1
echo "Return Value: $?"

echo '##############################################################'
# Installing APT packages
echo "Installing Packages..."
echo "...rbenv"
n=0
until [ $n -ge 5 ]
do
	echo "...rbenv: attempt $n"
	apt-get install -y rbenv > /dev/null 2>&1 && break
	echo ".....fail."
	n=$[$n+1]
done

echo '##############################################################'
echo "...rubydev"
apt-get install -y ruby-dev > /dev/null 2>&1
echo "Return Value: $?"

echo '##############################################################'
echo "...libreadline-dev"
apt-get install -y libreadline-dev  > /dev/null 2>&1
echo "Return Value: $?"

echo '##############################################################'
echo "...nodejs"
apt-get install -y nodejs  > /dev/null 2>&1
echo "Return Value: $?"

echo '##############################################################'
echo "...Postgresql"
apt install -y postgresql postgresql-contrib libpq-dev > /dev/null 2>&1

# rbenv MUST be installed as a single user (Vagrant).
# If it is installed as root, bad things will happen, and good things will fail to happen.
# if [ ! -d /home/vagrant/.rbenv/plugins/ruby-build ]; then
# 	echo "Installing rbenv"
# 	su vagrant -c 'git clone https://github.com/rbenv/rbenv.git /home/vagrant/.rbenv' > /dev/null 2>&1
# else
# 	echo "Updating rbenv"
# 	# Already installed; run an update instead.
# 	su vagrant -c 'pushd /home/vagrant/.rbenv; git pull; popd' > /dev/null 2>&1
# fi
# chmod a+x ~/.rbenv/bin/*
# ln -s ~/.rbenv/bin/rbenv /usr/bin/rbenv

echo '##############################################################'
echo "Initialising rbenv"
su vagrant -c 'rbenv init' > /dev/null 2>&1
echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc

#  Install the ruby-build plugin for rbenv which will let rbenv install new versions of Ruby.
if [ ! -d /home/vagrant/.rbenv/plugins/ruby-build ]; then
	# Occasionally, the script files in ruby-build are checked out with the wrong line endings
	# (due to shared drive settings and gitconfig). This forces git to check out the executable
	# files with unix line endings (otherwise rbenv install won't work correctly)
	su vagrant -c "git config --global core.autocrlf false"

	su vagrant -c 'git clone https://github.com/rbenv/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build' > /dev/null 2>&1
else
	# Already installed; run an update instead.
	su vagrant -c 'pushd /home/vagrant/.rbenv/plugins/ruby-build; git pull; popd' > /dev/null 2>&1
fi

echo '##############################################################'
echo "Installing Ruby 2.5.1"
su vagrant -c '/usr/bin/rbenv install -s 2.5.1'

echo "Globalising Ruby 2.5.1"
su vagrant -c '/usr/bin/rbenv global 2.5.1'

echo "Globally install Bundler"
su vagrant -l -c 'gem install --install-dir /home/vagrant/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0 bundler' 

echo "Globally install Rails"
su vagrant -l -c 'gem install --install-dir /home/vagrant/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0 rails -v 4.2.10' 

echo "Rehash Shims."
su vagrant -c 'rbenv rehash' 
echo '##############################################################'
# Postgresql

# fixing listen_addresses on postgresql.conf
# Uncomment the below if there are issues connecting to Postgres.
# sudo sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/9.1/main/postgresql.conf

# sudo cat >> /etc/postgresql/10/main/pg_hba.conf <<EOF
# # Accept all IPv4 connections - FOR DEVELOPMENT ONLY!!!
# host    all         all         0.0.0.0/0             md5
# EOF

echo "Initialise Postgresql Database"
su postgres -c "psql -c \"create user vagrant with password 'vagrant';\" "
su postgres -c "psql -c \"alter user vagrant with createdb;\" "
su postgres -c "psql -c \"alter user vagrant with superuser;\" "