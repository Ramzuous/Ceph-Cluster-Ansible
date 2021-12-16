#!/bin/bash

# Remove clear-config.sh if exists

if test -f clear-config.sh;
then
        rm clear-config.sh
fi

echo ""
echo ""

echo "**************************************************************************"
echo "*************** Welcome in generation of ansible components **************"
echo "**************************************************************************"

echo ""
echo ""

#################################################################################
################################## Variables ####################################
#################################################################################

# Proxmox access
proxmox_user="root" # example: root
proxmox_pass="a0a713cee0" # Plain text

# Proxmox network
proxmox_domain_name="intern.marcant.net" # example: mydomain.net
proxmox_ip_three="192.168.4" # Only three octets (example: 192.168.0)
proxmox_ip_fourth_greater="211" # example: 50
proxmox_ip_fourth_smaller="200" # example: 10

# Template settings
template_mon_name="template-mon-c8" # Plain text
template_mon_id="9000"

template_osd_name="template-osd-c8" # Plain text
template_osd_id="9001"

# Hardware
boot_order="order=scsi0;ide2;net0" # example: order=scsi0;ide2;net0
scsi_hw="virtio-scsi-pci" # example: virtio-scsi-pci
virtio_disc="LVM-1,32,format=raw" # example
net0_hw="virtio,bridge=vmbr0" # example: virtio,bridge=vmbr0
cores_num="2"
vcpus_num="2"
memory_size="2048" # example 4096

# Ceph Features - Common
ceph_user="root" # exmaple: root
ceph_pass="test" # Plain text
ceph_network="192.168.4" # Only three octets, example: 192.168.0
netmask="24" # example: 24
gateway="192.168.4.1" # example: 192.168.0.1
nameserver="217.14.160.130" # example: 8.8.8.8
searchdomain="217.14.164.35" # example: 1.1.1.1
ceph_domain="intern.marcant.net" # example: mydomain.net
time_zone="Europe/Berlin" # Time zone (exmaple: Europe/Berlin)
keyboard_layout="de" # Keyboard layout for VMs (example: de)

# Ceph admin
target_node_admin="pve02" # example: pve01
ceph_admin_ip="192.168.4.215" # example: 192.168.0.10
ceph_admin_hostname="ceph-admin" # example: admin
ceph_admin_vm_id="199" # example: 199

# Ceph mon - admin is also ceph-mon
target_node_mon="pve04" # example: pve01
mon_ip_fourth_greater="231" # example: 40
mon_ip_fourth_smaller="230" # example: 38
ceph_mons_name_begin="ceph-mon" # example: mon
ceph_mons_vm_id_begin="30" # example: 30

# Ceph osd
target_node_osd="pve05" # example: pve01
osd_ip_fourth_greater="223" # example: 35
osd_ip_fourth_smaller="220" # exmaple 30
ceph_osds_name_begin="ceph-osd" # example: osd
ceph_osds_vm_id_begin="20" # example: 20

# Cephadm URL
ceph_url="https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm"

# Chrony server setup (example: server 0.europe.pool.ntp.org iburst\nserver 1.europe.pool.ntp.org )
chrony_server_set="server 0.europe.pool.ntp.org iburst\nserver 1.europe.pool.ntp.org iburst\nserver 2.europe.pool.ntp.org iburst\nserver 3.europe.pool.ntp.org iburst"

# Node on which user uses API
operation_node_short="pve12" # example: pve01

# Not to set
operation_node=$operation_node_short"."$proxmox_domain_name

#################################################################################

#################################################################################

echo "*****************************************************"
echo "Setting first values"
echo "*****************************************************"

echo ""
echo ""

echo "Creates & sets rsa key's"

ssh-keygen -t rsa -f id_rsa -q -N ""

idrsapub=`cat id_rsa.pub`

if [ ! -d ~/.ssh ];
then
        mkdir ~/.ssh
fi

cp id_rsa* ~/.ssh

echo ""
echo ""

echo "Creating folders"

mkdir host_vars

mkdir inventory

mkdir vars_files

mkdir group_vars

echo ""

echo "Generate group_vars/proxmox.yml"

echo "ansible_user:" $proxmox_user >> group_vars/proxmox.yml

echo ""
echo ""

echo "Set ansible vault"

ansible-vault encrypt_string $proxmox_pass >> group_vars/proxmox.yml

sed -i 's/!/ansible_password: !/' group_vars/proxmox.yml

echo "ansible_port: 22" >> group_vars/proxmox.yml
echo "ansible_connection: ssh" >> group_vars/proxmox.yml

echo ""
echo ""

echo "Generate group_vars/cephcluster.yml"

echo "ansible_user:" $ceph_user >> group_vars/cephcluster.yml
echo "ansible_port: 22" >> group_vars/cephcluster.yml
echo "ansible_connection: ssh" >> group_vars/cephcluster.yml

echo ""
echo ""

echo "*****************************************************"
echo "Setting proxmox node for ansible"
echo "*****************************************************"

echo ""
echo ""

echo "all:" >> inventory/ceph-cluster-inventory.yml
echo "  children:" >> inventory/ceph-cluster-inventory.yml
echo "    proxmox:" >> inventory/ceph-cluster-inventory.yml
echo "      hosts:" >> inventory/ceph-cluster-inventory.yml

i=1

echo "Setting host_vars & inventory"

echo ""
echo ""

while [ $proxmox_ip_fourth_smaller -le $proxmox_ip_fourth_greater ]
do
        if [ $i -gt 9 ]
        then

                node_name="pve"$i

        else
                node_name="pve0"$i
        fi

        proxmox_ip=$proxmox_ip_three"."$proxmox_ip_fourth_smaller

        proxmox_name=$node_name'.'$proxmox_domain_name

        echo "ansible_host: "$proxmox_ip >> host_vars/$proxmox_name".yml"


        echo "        "$proxmox_name":" >> inventory/ceph-cluster-inventory.yml

        proxmox_ip_fourth_smaller=$((proxmox_ip_fourth_smaller+1))
        i=$((i+1))

done

echo "Set inventory - static"

echo "    cephcluster:" >> inventory/ceph-cluster-inventory.yml
echo "      children:" >> inventory/ceph-cluster-inventory.yml
echo "        cephadmin:" >> inventory/ceph-cluster-inventory.yml
echo "          hosts:" >> inventory/ceph-cluster-inventory.yml
echo "            "$ceph_admin_hostname":" >> inventory/ceph-cluster-inventory.yml
echo "        cephclients:" >> inventory/ceph-cluster-inventory.yml
echo "          children:" >> inventory/ceph-cluster-inventory.yml

echo ""
echo ""

echo "Set vars_files/ceph-admin-vars.yml"

echo ""
echo ""

echo "ansible_host: "$ceph_admin_ip >> host_vars/$ceph_admin_hostname.yml


echo "ceph_admin_vars:" >> vars_files/ceph-admin-vars.yml
echo "  - { vm_id: "$ceph_admin_vm_id", ceph_user: "$ceph_user", ceph_pass: '"$ceph_pass"', vm_name: '"$ceph_admin_hostname"', network_cloud: 'ip="$ceph_admin_ip"/"$netmask,"gw="$gateway"', nameserver_cloud: '"$nameserver"', searchdomain_cloud: '"$searchdomain"', scsi_hw: '"$scsi_hw"', net0_hw: '"$net0_hw"', target_node: '"$target_node_admin"', ip_cloud: '"$ceph_admin_ip"', operation_node_short: "$operation_node_short", api_user: "$proxmox_user"@pam, api_pass: "$proxmox_pass", memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", ceph_domain: "$ceph_domain", template_name: "$template_mon_name", template_id: "$template_mon_id", idrsapub: '"$idrsapub"' }" >> vars_files/ceph-admin-vars.yml

echo ""
echo ""

echo "*****************************************************"
echo "Set ceph mons"
echo "*****************************************************"

echo ""
echo ""

echo "Setting host_vars, inventory & vars_files/ceph-mon-vars.yml"

echo "ceph_mon_vars:" >> vars_files/ceph-mon-vars.yml

echo ""
echo ""

i=0

echo "            cephmons:" >> inventory/ceph-cluster-inventory.yml
echo "              hosts:" >> inventory/ceph-cluster-inventory.yml

while [ $mon_ip_fourth_smaller -le $mon_ip_fourth_greater ]
do

        mon_ip=$ceph_network"."$mon_ip_fourth_smaller

        mon_name=$ceph_mons_name_begin"-"$i
		
		if ! test -f host_vars/$mon_name.yml;
		then

			echo "Setting host_vars/"$mon_name".yml, inventory/ceph-cluster-inventory.yml & vars_files/ceph-mon-vars.yml"

			echo "ansible_host: "$mon_ip >> host_vars/$mon_name".yml"

			echo "                "$mon_name":" >> inventory/ceph-cluster-inventory.yml

			echo "  - { vm_id: "$ceph_mons_vm_id_begin$i", ceph_user: "$ceph_user", ceph_pass: '"$ceph_pass"', vm_name: '"$mon_name"', network_cloud: 'ip="$mon_ip"/"$netmask,"gw="$gateway"', nameserver_cloud: '"$nameserver"', searchdomain_cloud: '"$searchdomain"', scsi_hw: '"$scsi_hw"', net0_hw: '"$net0_hw"', target_node: '"$target_node_mon"', ip_cloud: '"$mon_ip"', operation_node_short: "$operation_node_short", api_user: "$proxmox_user"@pam, api_pass: "$proxmox_pass", memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", ceph_domain: "$ceph_domain", template_name: "$template_mon_name", template_id: "$template_mon_id", idrsapub: '"$idrsapub"' }" >> vars_files/ceph-mon-vars.yml
		
		else
			echo "File host_vars/"$mon_name".yml exists"
		fi

        mon_ip_fourth_smaller=$((mon_ip_fourth_smaller+1))
        i=$((i+1))

done

echo ""
echo ""

echo "*****************************************************"
echo "Set ceph osds"
echo "*****************************************************"

echo ""
echo ""

echo "Setting host_vars, inventory & vars_files/ceph-osd-vars.yml"

echo "ceph_osd_vars:" >> vars_files/ceph-osd-vars.yml

echo ""
echo ""

i=0

echo "            cephosds:" >> inventory/ceph-cluster-inventory.yml
echo "              hosts:" >> inventory/ceph-cluster-inventory.yml

while [ $osd_ip_fourth_smaller -le $osd_ip_fourth_greater ]
do

        osd_ip=$ceph_network"."$osd_ip_fourth_smaller

        osd_name=$ceph_osds_name_begin"-"$i
		
		if ! test -f host_vars/$osd_name.yml;
		then

			echo "Setting host_vars/"$osd_name".yml, inventory/ceph-cluster-inventory.yml & vars_files/ceph-osd-vars.yml"

			echo "ansible_host: "$osd_ip >> host_vars/$osd_name".yml"

			echo "                "$osd_name":" >> inventory/ceph-cluster-inventory.yml

			echo "  - { vm_id: "$ceph_osds_vm_id_begin$i", ceph_user: "$ceph_user", ceph_pass: '"$ceph_pass"', vm_name: '"$osd_name"', network_cloud: 'ip="$osd_ip"/"$netmask,"gw="$gateway"', nameserver_cloud: '"$nameserver"', searchdomain_cloud: '"$searchdomain"', scsi_hw: '"$scsi_hw"', net0_hw: '"$net0_hw"', target_node: '"$target_node_osd"', ip_cloud: '"$osd_ip"', operation_node_short: "$operation_node_short", api_user: "$proxmox_user"@pam, api_pass: "$proxmox_pass", memory_size: "$memory_size", cores_num: "$cores_num", vcpus_num: "$vcpus_num", ceph_domain: "$ceph_domain", template_name: "$template_osd_name", template_id: "$template_osd_id", idrsapub: '"$idrsapub"' }" >> vars_files/ceph-osd-vars.yml
		
		else
			echo "File host_vars/"$osd_name".yml exists"
		fi

        osd_ip_fourth_smaller=$((osd_ip_fourth_smaller+1))
        i=$((i+1))

done

echo "*****************************************************"
echo "Setting other values"
echo "*****************************************************"

echo ""
echo ""

echo "Set static vars_files/ceph-vars.yml"

echo "vars:" >> vars_files/ceph-vars.yml
echo "  ansible_python_interpreter: '/usr/bin/python3'" >> vars_files/ceph-vars.yml

echo "other_vars:" >> vars_files/ceph-vars.yml

echo "  - { chrony_server_set: '"$chrony_server_set"', ceph_url: "$ceph_url", time_zone: "$time_zone", keyboard_layout: "$keyboard_layout", proxmox_user: "$proxmox_user", ceph_user: "$ceph_user" }" >> vars_files/ceph-vars.yml

echo ""
echo ""

echo "Setting operation node"

sed -i 's/operation_node_to_add/'$operation_node'/g' createCephCluster.yml

sed -i 's/operation_node_to_add/'$operation_node'/' destroyVMS.yml

sed -i 's/ceph_admin_ip_to_add/'$ceph_admin_ip'/' createCephCluster.yml

sed -i 's/boot_order_to_add/'$boot_order'/' createCephCluster.yml

echo ""
echo ""

echo '#!/bin/bash' >> clear-config.sh

echo "" >> clear-config.sh

echo "# This script destroys all cluster and configuration" >> clear-config.sh

echo "" >> clear-config.sh

echo 'echo "Play ansible-playbook to remove VMs and ssh keys"' >> clear-config.sh

echo "" >> clear-config.sh

echo "ansible-playbook -i inventory/ceph-cluster-inventory.yml destroyVMS.yml --ask-vault-pass" >> clear-config.sh

echo "" >> clear-config.sh

echo 'echo "If Ansible script deleted all components, type: yes"' >> clear-config.sh

echo 'echo "Only this answer will be acceptable"' >> clear-config.sh

echo 'read -p "so?": confirm' >> clear-config.sh

echo "" >> clear-config.sh

echo "if [ \$confirm == 'yes' ]" >> clear-config.sh

echo "then" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -f id_rsa;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm id_rsa" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -f id_rsa.pub;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm id_rsa.pub" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -f ~/.ssh/id_rsa;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -f ~/.ssh/id_rsa" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -f ~/.ssh/id_rsa.pub;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -f ~/.ssh/id_rsa.pub" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -d group_vars;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -r group_vars" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -d host_vars;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -r host_vars" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -d inventory;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -r inventory" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	if test -d vars_files;" >> clear-config.sh
echo "	then" >> clear-config.sh
echo "		rm -r vars_files" >> clear-config.sh
echo "	fi" >> clear-config.sh

echo "" >> clear-config.sh

echo "	sed -i 's/"$operation_node"/operation_node_to_add/g' createCephCluster.yml" >> clear-config.sh

echo "" >> clear-config.sh

echo "  sed -i 's/"$operation_node"/operation_node_to_add/g' destroyVMS.yml" >> clear-config.sh

echo "" >> clear-config.sh

echo "	sed -i 's/"$ceph_admin_ip"/ceph_admin_ip_to_add/' createCephCluster.yml" >> clear-config.sh

echo "" >> clear-config.sh

echo "	sed -i 's/"$boot_order"/boot_order_to_add/' createCephCluster.yml" >> clear-config.sh

echo "" >> clear-config.sh

echo "	echo 'All cluster and ansible configuration for it, were destroyed'" >> clear-config.sh

echo "" >> clear-config.sh

echo "else" >> clear-config.sh

echo "" >> clear-config.sh

echo '	echo "You did not confirm that you destroyed cluster"' >> clear-config.sh

echo '	echo "Files will not be deleted"' >> clear-config.sh

echo "" >> clear-config.sh

echo "fi" >> clear-config.sh

echo "" >> clear-config.sh

chmod +x clear-config.sh

echo ""
echo ""

echo "**************************************************************************"
echo "********************* All components are set *****************************"
echo "**************************************************************************"

echo ""
echo ""

echo "Now, you just need to run project by:"

echo ""

echo "ansible-playbook -i inventory/ceph-cluster-inventory.yml createCephCluster.yml --ask-vault-pass"

echo ""
echo ""