# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.omnibus.chef_version = :latest

  config.vm.provision "chef_solo" do |chef|
    chef.add_recipe "apt"
    chef.add_recipe "build-essential"
    chef.add_recipe "boost::source"
    chef.add_recipe "pickleng"
  end

  config.vm.provision :file, source: '~/.ssh', destination: '/home/vagrant/'

  config.vm.box = "ubuntu/vivid64"
  config.vm.box_url = "https://vagrantcloud.com/ubuntu/boxes/vivid64/versions/20150722.0.0/providers/virtualbox.box"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.auto_detect = true
  end

  config.ssh.forward_agent = true
  config.ssh.forward_x11 = true

  config.vm.synced_folder "./", "/home/vagrant/synced"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
    vb.customize ['modifyvm', :id, '--cpus', '4']
    vb.customize ['modifyvm', :id, '--ioapic', 'on']
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
end