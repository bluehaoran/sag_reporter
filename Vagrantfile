# -*- mode: ruby -*-
# vi: set ft=ruby :

# This file provisisons your Virtualbox (or some other Vagrant backend) and links your
# shared folders in.
#
# Note, even if you are running Ubuntu on Windows via the Windows Linux subsystem, you will need
# to run this natively through the command shell (CMD) or Powershell.
#
# Also, there are long-standing symlink issues on Windows shared drives, hence the 'setextradata' lines.
# These should be harmless if you are developing on Mac or Linux.

VAGRANTFILE_API_VERSION = "2" 

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/bionic64"        

  # Uncomment this if we need a specific IP address.
  config.vm.network "private_network", ip: "13.13.13.13"

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--name", "wp"]
    v.customize ["modifyvm", :id, "--memory", 4096]
  end

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # For Windows users
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/provision", "1"]
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/secret", "1"]
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/srv_config", "1"]
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/srv_www", "1"]
  end
  config.vm.synced_folder ".", "/vagrant", disabled: true # Disable default share

  # Use your local gitconfig on the box, so you can commit from within your Vagrant box.
  config.vm.provision :file, :source => "~/.gitconfig", :destination => "~/.gitconfig"

  # Anything in the SCRIPT block gets run at the end of the Vagrant boot dance.
  # To wit: some crucial web services don't come up properly in centos 5 for some reason.
  # This 'provision script' restarts them all manually, which fixes things.
  # config.vm.provision :shell do |s|
  #   s.inline = <<-SCRIPT
  #     echo `sudo /etc/init.d/nginx restart`
  #     echo `sudo /etc/init.d/mysqld restart`
  #     echo `sudo /etc/init.d/php-fpm restart`
  #     echo `sudo /etc/init.d/redis restart`
  #   SCRIPT
  # end
  
end
