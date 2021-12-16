# Ceph-Cluster-Ansible

This project creates Proxmox VMs with ceph cluster.

# Before you start

To run project you need to prepare

 1. Two VM template with CentOS-8-Stream Cloud init (one with additional disk for osds, one for mons) 
 2. User for ansible playbok (
 
If you did above actions, you can set vairiables in <code>prepare-settings.sh</code>

# How to run

Befor you run ansible playbook, you need o preper all inventory.
To do it, run:

<code>
./prepare-settings.sh
</code>

To start building <code>Ceph-Cluster</code> play:

<code>
ansible-playbook -i inventory/ceph-cluster-inventory.yml createCephCluster.yml --ask-vault-pass
</code>


If you want to destroy created cluster, run:
  
<code>
./clear-config.sh
</code>
