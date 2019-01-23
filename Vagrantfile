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
REQUIRED_PLUGINS        = %w(vagrant-vbguest)

Vagrant.require_version ">= 2.0.3"

# Ensure Vagrant vb-guest is installed
plugins_to_install = REQUIRED_PLUGINS.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing required plugins: #{plugins_to_install.join(' ')}"
  if system "vagrant plugin install #{plugins_to_install.join(' ')}"
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "Installation of one or more plugins has failed. Aborting. Please read the Bike Index README."
  end
end


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/bionic64"        

  # Uncomment this if we need a specific IP address.
  config.vm.network "private_network", ip: "13.13.13.13"

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--name", "sag"]
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
  # config.vm.synced_folder ".", "/vagrant", disabled: false # Disable default share
  config.vm.synced_folder ".", "/sag_reporter", disabled: false # Disable default share

  # Use your local gitconfig on the box, so you can commit from within your Vagrant box.
  config.vm.provision :file, :source => "~/.gitconfig", :destination => "~/.gitconfig"

  # This 'provision script' restarts them all manually, which fixes things.
  config.vm.provision :shell, path: "vagrant-provision.sh", privileged: true
  
end
