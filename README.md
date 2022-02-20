# Ceph-Cluster-Ansible

This project creates Proxmox VMs with ceph cluster. It installs cephcluster with podman.

# Before start:

Prepare templates with cloud init CentOS 8 Stream. One of them needs to have addistional disk for osd VMs.

Additional: create special user on device that runs ansible script for creating cluster would be helpful. Script needs ssh key which is generated by <code>prepare-settings.sh</code>

Cluster create:

1. Set variables in prepare-settings.sh - it generates: host_vars, inventory, group_vars, vars_files and set everything to use cluster

2. Run: 
	<code>chmod +x prepare-settings.sh
	./prepare-settings.sh</code>

3. Run: 
   <code>ansible-playbook -i inventory/ceph-cluster-inventory.yml createCephCluster.yml --ask-vault-pass</code>

# Cluster update:

1. Set variables in update-prepare-settings.sh
	
2. Run:
	<code>chmod +x update-prepare-settings.sh
	./update-prepare-settings.sh</code>

3. Run: 
   <code>ansible-playbook -i inventory/ceph-cluster-inventory.yml updateCephCluster.yml --ask-vault-pass</code>

When there is a problem with update script, just run it again.

# Destroy cluster:

This comand  will destroy whole cluster's nodes, also created by update

<code>./clear-config.sh</code>

----------------------------------------------------------------------------------------------------------------------------

# Manual method to prepare ceph cluster creating settings:

User can also create/update manualy update settings (without running prepare-settings.sh or update-prepare-settings.sh).

Manual preparing settings to create cluster:

1. Create ssh key - it is needed to connect with VMS:

	<code>ssh-keygen -t rsa -f id_rsa -q -N ""</code>

2. Copy ssh key to user's home directorie:

	<code>cp id_rsa ~/.ssh</code>

3. Create directories:
	* host_vars
	* inventory
	* vars_files
	* group_vars

4. Create group_vars

   group_vars/proxmox.yml
    
   vault pass can be created by
   ansible-vault encrypt_string <proxmox user password>
   
     example:
   
     <code>cat group_vars/proxmox.yml
     ansible_user: root
     ansible_password: <vault value>
     ansible_port: 22
	     ansible_connection: ssh</code>
   
   group_vars/cephcluster.yml
     
     example:
	
    <code> cat group_vars/cephcluster.yml
	 ansible_user: root
	 ansible_port: 22
	 ansible_connection: ssh</code>
   
5. Create host_vars for every ceph host in cluster and every node in proxmox cluster:

	example:
	
    <code>cat host_vars/pve01.example.domain.net.yml
	 ansible_host: 192.168.0.200</code>

6. Create inventory for all hosts

	example:
	
    <code>cat inventory/ceph-cluster-inventory.yml
    all:
      children:
        proxmox:
          hosts:
            pve01.example.domain.net:
            pve02.example.domain.net:
			pve03.example.domain.net:
			pve04.example.domain.net:
			pve05.example.domain.net:
			pve06.example.domain.net:
            pve07.example.domain.net:
            pve08.example.domain.net:
    	cephcluster:
      	  children:
            cephadmin:
              hosts:
                admin:
            cephclients:
              children:
                cephmons:
                  hosts:
                    mon-0:
                    mon-1:
                    mon-2:
                cephosds:
                  hosts:
                    osd-0:
                    osd-1:
                    osd-2:
                    osd-3:</code>

7. In vars_files create files:
   * ceph-admin-vars.yml (first line: ceph_admin_vars:)
   * ceph-mon-vars.yml (first line: ceph_mon_vars:)
   * ceph-osd-vars.yml (first line: ceph_osd_vars:)

   Every ot those files should have items which are used in yaml scripts
     - vm_id - id of vm which will be created
     - ceph_user - cloud init user, it needs to be the same like ansible_user in group_vars/cephcluster.yml and the same for every ceph node
     - ceph_pass - cloud init password
     - vm_name - name of VM
     - network_cloud - cloud init network, this setting needs to be written between apostrophes and all ceph clusters need to be in the same network (example: network_cloud: 'ip=192.168.0.20/24,gw=192.168.0.1') 
     - ip_cloud - cloud init ip (example: ip_cloud:'192.168.0.20')
     - nameserver_cloud - cloud init setting (ip address)
     - searchdomain_cloud  - cloud init setting (ip address)
     - scsi_hw - hardware vm setting (example: scsi_hw: 'virtio-scsi-pci')
     - net0_hw - hardware vm setting (example: net0_hw: 'virtio,bridge=vmbr0')
     - memory_size - hardware vm setting, oparation memory (example: memory_size: 2048)
     - cores_num - hardware vm setting, number of cores which are availabe on VM (intiger number)
     - vcpus_num - hardware vm setting, number of hotplugged vcpus (intiger number)
     - target_node - node on which VM has to be created
     - operation_node_short - node from which we using API and and on which templates are placed (example: operation_node_short: pve02)
     - api_user - user which use proxmox API (example: api_user: root@pam)
     - api_pass - password for API user (plain text)
     - ceph_domain - domain for ceph (example: ceph_domain: example.domain.net)
     - template_name - name of the template which will be cloned to create VM
     - template_id - vm id number which will be cloned to create VM
     - idrsapub - public key created in 1. point (it needs to be public key in text between apostrophes, path to this doesn't work)

   In ceph-admin-vars.yml can be only one group of items defined. This VM uses ceph-deploy to create ceph cluster.

   In ceph-mon-vars.yml and ceph-osd-vars.yml can be defined as much group of items as user needs. The number of group of items are setting for each VM.

   examples:

   <code>cat vars_files/ceph-admin-vars.yml
   ceph_admin_vars:
     - { vm_id: 700, ceph_user: root, ceph_pass: 'test', vm_name: 'admin', network_cloud: 'ip=192.168.0.15/24,gw=192.168.0.1', nameserver_cloud: '8.8.8.8', searchdomain_cloud: '1.1.1.1', scsi_hw: 'virtio-scsi-pci', net0_hw: 'virtio,bridge=vmbr0', target_node: 'pve02', ip_cloud: '192.168.0.15', operation_node_short: pve01, api_user: root@pam, api_pass: <proxmox api user password>, memory_size: 2048, cores_num: 2, vcpus_num: 2, ceph_domain: example.domain.net, template_name: template-mon, template_id: 9002, idrsapub: '<rsa_public_key>' }
      
   cat vars_files/ceph-mon-vars.yml
   ceph_mon_vars:
     - { vm_id: 806, ceph_user: root, ceph_pass: 'test', vm_name: 'mon-6', network_cloud: 'ip=192.168.0.36/24,gw=192.168.0.1', nameserver_cloud: '8.8.8.8', searchdomain_cloud: '1.1.1.1', scsi_hw: 'virtio-scsi-pci', net0_hw: 'virtio,bridge=vmbr0', target_node: 'pve04', ip_cloud: '192.168.0.36', operation_node_short: pve01, api_user: root@pam, api_pass: <proxmox api user password>, memory_size: 2048, cores_num: 2, vcpus_num: 2, ceph_domain: example.domain.net, template_name: template-mon, template_id: 9002, idrsapub: '<rsa_public_key>' }
     - { vm_id: 807, ceph_user: root, ceph_pass: 'test', vm_name: 'mon-7', network_cloud: 'ip=192.168.0.37/24,gw=192.168.0.1', nameserver_cloud: '8.8.8.8', searchdomain_cloud: '1.1.1.1', scsi_hw: 'virtio-scsi-pci', net0_hw: 'virtio,bridge=vmbr0', target_node: 'pve04', ip_cloud: '192.168.0.37', operation_node_short: pve01, api_user: root@pam, api_pass: <proxmox api user password>, memory_size: 2048, cores_num: 2, vcpus_num: 2, ceph_domain: example.domain.net, template_name: template-mon, template_id: 9002, idrsapub: '<rsa_public_key>' }</code>

8. In vars_files create ceph-vars.yml with two headers (vars and other_vars)
   
   Under vars should be placed ansible_python_interpreter
   
   Under othe_vars needs to be added one group of item with following items:
     - chrony_server_set - schrony server configuration, it needs to have apostrophes (example: chrony_server_set: 'server 0.europe.pool.ntp.org iburst\nserver 1.europe.pool.ntp.org')
     - time_zone - time zone of the place where ceph nodes are
     - keyboard_layout - layout of keyboard configured on VMs
     - ceph_url - link to dowload cephadm (example: https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm )
	 - proxmox_user - user which is created in proxmox cluster and was used in group_vars/proxmox.yml
     - ceph_user - cloud init user, it needs to be the same like ceph_user in vars_files/ceph-admin-vars.yml, vars_files/ceph-mon-vars.yml and vars_files/ceph-osd-vars.yml
   
   example:
   
  <code> cat vars_files/ceph-vars.yml
   vars:
     ansible_python_interpreter: '/usr/bin/python3
   other_vars:
     - { chrony_server_set: 'server 0.europe.pool.ntp.org iburst\nserver 1.europe.pool.ntp.org iburst\nserver 2.europe.pool.ntp.org iburst\nserver 3.europe.pool.ntp.org iburst', ceph_url: <url_to_cephadm>, time_zone: Europe/Berlin, keyboard_layout: de, proxmox_user: root, ceph_user: root }</code>

9. Change two variables in createCephCluster.yml and one in destroyVMS.yml
     - operation_node_to_add - is placed in both files, needs to be the same (example: pve01.example.domain.net)
	 - boot_order_to_add - is placed only in createCephCluster.yml, needs to be between apostrophes (example: order=scsi0;ide2;net0)
	 - ceph_admin_ip_to_add - is placed only in createCephCluster.yml, ip address of admin node, is only to display information after finishing all tasks (example: 192.168.0.4)

Manual method to prepare ceph cluster update settings:

1. Create host_vars for new ceph host

	example:
	
    <code>cat host_vars/mon-5.yml
	ansible_host: 192.168.0.56</code>
	
2. Add node(s) in proper groups in inventory/ceph-cluster-inventory.yml

3. Change two variables in updateCephCluster.yml
     - operation_node_to_add - (example: pve01.example.domain.net)
	 - boot_order_to_add - needs to be between apostrophes (example: order=scsi0;ide2;net0)

4. Create vars_files/ceph-new-hosts-vars.yml and add the same items like in ceph-mon-vars.yml or ceph-osd-vars.yml
   Items from proper sections (from ceph_new_mon_vars to ceph_mon_vars, from ceph_new_osd_vars to ceph_osd_vars))vars_files/ceph-new-hosts-vars.yml need to be added to vars_files/ceph-osd-vars.yml and vars_files/ceph-mon-vars.yml. It will be needed to this and further updates.
   
	 examples:
	 
	 <code>ceph_new_mon_vars:
	   - { vm_id: 806, ceph_user: root, ceph_pass: 'test', vm_name: 'mon-6', network_cloud: 'ip=192.168.0.36/24,gw=192.168.0.1', nameserver_cloud: '8.8.8.8', searchdomain_cloud: '1.1.1.1', scsi_hw: 'virtio-scsi-pci', net0_hw: 'virtio,bridge=vmbr0', target_node: 'pve04', ip_cloud: '192.168.0.36', operation_node_short: pve01, api_user: root@pam, api_pass: <proxmox api user password>, memory_size: 2048, cores_num: 2, vcpus_num: 2, ceph_domain: example.domain.net, template_name: template-mon, template_id: 9002, idrsapub: '<rsa_public_key>' }
	 ceph_new_osd_vars:
	   - { vm_id: 607, ceph_user: root, ceph_pass: 'test', vm_name: 'osd-7', network_cloud: 'ip=192.168.0.27/24,gw=192.168.0.1', nameserver_cloud: '8.8.8.8', searchdomain_cloud: '1.1.1.1', scsi_hw: 'virtio-scsi-pci', net0_hw: 'virtio,bridge=vmbr0', target_node: 'pve05', ip_cloud: '192.168.0.27', operation_node_short: pve01, api_user: root@pam, api_pass: <proxmox api user password>, memory_size: 2048, cores_num: 2, vcpus_num: 2, ceph_domain: example.domain.net, template_name: template-osd, template_id: 9003, idrsapub: '<rsa_public_key>' }</code>
	
	If you want to do next update of your cluster, you need to remove 'vars_files/ceph-new-hosts-vars.yml' and repeat points 1-4 with new settings. 
	Don't remove added to update group of items from vars_files/ceph-osd-vars.yml and vars_files/ceph-mon-vars.yml. They will be needed when you want to remove VMs.

If you want to create only one group of VMS (only mon(s) or only osd(s)), you need to comment - "{{ ceph_new_osd_vars }}" or - "{{ ceph_new_mon_vars }}" out with # in updateCephCluster.yml this items which you don't need.

if you create only osd(s), comment task:
  - Add mons

if you create only mon(s), comment task:
  - Add osds
  
----------------------------------------------------------------------------------------------------------------------------  
  
Advices:

Items like vm_id, vm_name, ip_cloud need etc. to be unique for each possition in every vars_files. It's important for proper working creating or updating cluster.

If settings for update are set, you should run ansible update script. In other case it'll create some problems with further actions.

Sometimes VMs can have a problem with starting when we're running one of ansile script. To repare it, you need to stop and start VM(s) with that problem and run script again.
  
When it's no possibility to start VM form update config, only possibility to repair it is to delete damaged VM and run update script again.
