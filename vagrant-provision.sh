#!/bin/bash

# This file Sets up LCI/SAG development on a Vagrant Box.
# This file assumes it is being run as root.

# echo "Updating Ubuntu Sources. This will take a while."
# apt-get update -y > /dev/null 2>&1
# apt-get upgrade -y > /dev/null 2>&1

# # Installing APT packages
# echo "Installing Packages..."
# echo "...rbenv"
# apt-get install -y rbenv  > /dev/null 2>&1
# echo "...libreadline-dev"
# apt-get install -y libreadline-dev  > /dev/null 2>&1
# echo "...nodejs"
# apt-get install -y nodejs  > /dev/null 2>&1
# echo "...Postgresql"
# apt install -y postgresql postgresql-contrib libpq-dev > /dev/null 2>&1

# rbenv MUST be installed as a single user (Vagrant).
# If it is installed as root, bad things will happen, and good things will fail to happen.
# echo "Initialising rbenv"
# su -c 'rbenv init' vagrant > /dev/null 2>&1
# echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc

# #  Install the ruby-build plugin for rbenv which will let rbenv install new versions of Ruby.
# if [ ! -d /home/vagrant/.rbenv/plugins/ruby-build ]; then
# 	su -c 'git clone https://github.com/rbenv/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build' vagrant > dev/null 2>&1
# else
# 	su -c 'pushd /home/vagrant/.rbenv/plugins/ruby-build; git pull' vagrant > dev/null 2>&1
# fi

# echo "Installing Ruby 2.5.1"
# su -c 'rbenv install -s 2.5.1' vagrant
# su -c 'rbenv global 2.5.1' vagrant

# # Globally install Rails
# su -l -c 'gem install --install-dir /home/vagrant/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0 rails -v 4.2.10' vagrant

# # Rehash Shims.
# su -c 'rbenv rehash' vagrant


