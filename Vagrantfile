Vagrant.configure("2") do |config|
  #### patch until fix https://github.com/hashicorp/vagrant/issues/13404#issuecomment-2490437792
  config.vagrant.plugins = {
    'vagrant-vbguest' => {
      'sources' =>[
        'vagrant-vbguest-0.32.1.gem',
        'https://rubygems.org/', # needed but not used
      ],
    }
  }
  #######
  config.vbguest.installer_options = { allow_kernel_upgrade: true }
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
  end

  config.vm.define "bookworm_vlan" do |bookworm_vlan|
    bookworm_vlan.vm.box = "debian/bookworm64"
    bookworm_vlan.ssh.insert_key = true
    bookworm_vlan.vm.hostname = "bookworm-vlan"
    bookworm_vlan.vm.boot_timeout = 600
    bookworm_vlan.vbguest.auto_update = false
    bookworm_vlan.vm.provision "shell",
      inline: "ip link set dev eth0 down; ip link set eth0 name eth0.101; ip link set dev eth0.101 up; dhclient -r eth0.101; dhclient eth0.101"
    bookworm_vlan.vm.provision "shell",
      inline: "apt-get update && apt-get remove -y dkms && apt-get -y install dkms && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && apt-get -y install python3-pip curl && rm -rf /usr/lib/python3.11/EXTERNALLY-MANAGED && python3 -m pip install ansible" 
    bookworm_vlan.vm.provision "ansible" do |a|
      a.verbose = "v"
      a.limit = "all"
      a.playbook = "testing/being_tested.yml"
      a.extra_vars = {
        "ansible_become_pass" => "vagrant",
        "ansible_python_interpreter" => "/usr/bin/python3",
        "sshd_admin_net" => ["0.0.0.0/0"],
        "sshd_allow_groups" => ["vagrant", "sudo", "debian", "ubuntu"],
        "system_upgrade" => "false",
        "manage_aide" => "false"
      }
    end
  end

  config.vm.define "bookworm" do |bookworm|
    bookworm.vm.box = "debian/bookworm64"
    bookworm.disksize.size = '25GB'
    bookworm.ssh.insert_key = true
    bookworm.vm.hostname = "bookworm"
    bookworm.vm.boot_timeout = 600
    bookworm.vbguest.auto_update = false
    bookworm.vm.provision "shell",
      inline: "apt-get update && apt-get remove -y dkms && apt-get -y install dkms && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && apt-get -y install python3-pip curl && rm -rf /usr/lib/python3.11/EXTERNALLY-MANAGED && python3 -m pip install ansible" 
    bookworm.vm.provision "ansible" do |a|
      a.verbose = "v"
      a.limit = "all"
      a.playbook = "testing/being_tested.yml"
      a.extra_vars = {
        "ansible_become_pass" => "vagrant",
        "ansible_python_interpreter" => "/usr/bin/python3",
        "sshd_admin_net" => ["0.0.0.0/0"],
        "sshd_allow_groups" => ["vagrant", "sudo", "debian", "ubuntu"],
        "system_upgrade" => "false",
     }
    end
  end

  config.vm.define "jammy" do |jammy|
    jammy.vm.box = "ubuntu/jammy64"
    jammy.ssh.insert_key = true
    jammy.vm.hostname = "jammy"
    jammy.vm.boot_timeout = 600
    jammy.vm.provision "shell",
      inline: "apt-get update && apt-get -y install python3-pip curl && python3 -m pip install ansible"
    jammy.vm.provision "ansible" do |a|
      a.verbose = "v"
      a.limit = "all"
      a.playbook = "testing/being_tested.yml"
      a.extra_vars = {
        "sshd_admin_net" => ["0.0.0.0/0"],
        "sshd_allow_groups" => ["vagrant", "sudo", "ubuntu"],
        "ansible_python_interpreter" => "/usr/bin/python3",
      }
     end
   end

end
