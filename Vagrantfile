
Vagrant.configure(2) do |config|
  config.vm.define 'heidrun' do |heidrun|
    heidrun.vm.box = 'hashicorp/precise64'
    heidrun.vm.hostname = 'heidrun'
    heidrun.vm.network :private_network, ip: '192.168.50.21'
    heidrun.vm.network "forwarded_port", guest: 8983, host: 8983
    heidrun.vm.network "forwarded_port", guest: 3000, host: 3000
    heidrun.vm.provider 'virtualbox' do |vb|
      vb.memory = 1024
    end
    heidrun.vm.provision 'ansible' do |ansible|
      ansible.playbook = 'provisioning/provision.yml'
    end
  end
end
