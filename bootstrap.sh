#!/bin/bash

echo "Fix model first, this is a base model"

#
#
#


version=$1
vlan=$2
vlanranges=$3 # syntax 100:200
ext185network=$4  # syntax 192.168.185.41:192.168.185.70 
routeraddr=$5 # syntax 194.47.157.32/27
tag=$6

modelname=$(echo "os-$version-$tag")
series='bionic' #Default 


echo "Launching: $version, on VLAN = $vlan with $ext185network as network range and $routeraddr as router, juju model = $modelname."


## Log settings
datm=$(date +'%F %R') 
echo "$datm  => $version $vlan $vlanranges $ext185network $routeraddr $tag" >> deployedSettings
##Adjust to suit user/credential in MAAS. Technically you can use the same credentials to build multiple models, however its easier to track
##users in MAAS, as it is not aware of the models.

##juju add-model --credential <MAAS-credential> <MODELNAME>
juju add-model --credential $version $modelname #queen os-queen


#Adjust to match model name.
juju switch :$modelname #seos-queen
juju status

defspaces="internal admin=admin internal=internal public=public data=internal cluster=cluster"

if [ $version = "mitaka" ]; then  
# Mitaka
    echo "Doing Mitaka"
    series='xenial'
    juju deploy cs:bundle/openstack-base-54 --bind $defspaces
fi

if [ $version = "queen" ]; then  
    # Queen
    echo "Doing Queen"
    series='bionic'
    juju deploy cs:bundle/openstack-base-56 --bind $defspaces
fi

if [ $version = "queen2" ]; then  
    # Queen
    echo "Doing Queen ver2"
    series='bionic'
    juju deploy cs:bundle/openstack-base-58 
fi

if [ $version = "rocky" ]; then  
    # Queen
    echo "Doing Rocky ver2"
    series='bionic'
    ## NOTE; Config spaces in bundle config, until --bind works  
    juju deploy ./bionic-rocky/os-nplstack.yaml 
fi

if [ $version = "stein" ]; then  
    # Queen
    echo "Doing Stein"
    series='bionic'
    ## NOTE; Config spaces in bundle config, until --bind works
    #cs:bundle/openstack-base-59
    juju deploy ./bundle61/bundle.yaml  --overlay ./bundle61/openstack-base-spaces-overlay.yaml
fi




##
# Make sure that nova-ceph pool has been created.
# The default in charm was a pool called 'nova', It was not created, check if ceph charm missing
# that, as the glance and cinder-cephs are created 
#juju config nova-compute rbd-pool=nova-compute
juju config nova-compute libvirt-image-backend=rbd 


#Enable console access from horizon,ssh  no
juju config nova-cloud-controller console-access-protocol=novnc
##Make sure that THIS IP is registered properly, so that will forward to the instanve.
##I.e. iptables in intGw and routing in c4500 (to point to intGw), that translates public IP to private.
##The same applies for the horizon dashboard.
#juju config nova-cloud-controller console-proxy-ip=194.47.151.116

#juju config neutron-api vlan-ranges=physnet1:100:200
juju config neutron-api vlan-ranges=physnet1:$vlanranges

#juju config neutron-gateway vlan-ranges=physnet1:100:200
juju config neutron-gateway vlan-ranges=physnet1:$vlanranges

juju config neutron-openvswitch bridge-mappings=physnet1:br-ex
juju config neutron-openvswitch data-port=br-ex:eno2

#juju config neutron-openvswitch vlan-ranges=physnet1:100:200
juju config neutron-openvswitch vlan-ranges=physnet1:$vlanranges

## Added to simplify juju interaction with openstack cloud.
#juju deploy glance-simplestreams-sync 
#juju add-relation keystone glance-simplestreams-sync
    


juju config neutron-api dhcp-agents-per-network=2
juju config neutron-api flat-network-providers='physnet1'
juju config neutron-api global-physnet-mtu=9000


#juju add-unit nova-compute --constraints cpu-cores=32


## Generate cert..certbot, copy here.
# sudo cp /etc/letsencrypt/{key,csr}/*.pem .
#juju config openstack-dashboard ssl_key="$(base64 0000_key-certbot.pem)" ssl_cert="$(base64 0000_csr-certbot.pem)";
#juju config openstack-dashboard enforce-ssl=true



#Adjust to match model name.
echo "Launch another screen/terminal, wait for deployment and cfg to complete.Then " 
echo "As long as "
echo "juju wait juju wait --model $modelname"
juju wait juju wait --model $modelname
echo "does not work."

echo "Wait for user input"
echo "Fix DNS issue in containers (Bionic)."
echo " append in /etc/netplan/99-juju.yaml;"
echo "search: [maas] "
echo "after nameservers, before addressess"
echo "juju ssh 2/lxd/2  sed -i '/nameservers:/a          search: [maas]' /etc/netplan/99-juju.yaml"
echo "juju ssh 2/lxd/2 sudo netplan apply"
#juju ssh 2/lxd/2  sed -i '/nameservers:/a          search: [maas]' /etc/netplan/99-juju.yaml
#juju ssh 2/lxd/2 sudo netplan apply
echo "Fix nova-api-metadata"
echo "juju ssh 0 "
echo "sudo su -"
echo "systemctl unmask nova-api-metadata.service"
echo "systemctl start nova-api-metadata.service"
echo "systemctl status nova-api-metadata.service"


read -p "Press any key to continue"
#

echo "Openstack deployed"


echo "Wait some time... 60s to stabilize."
sleep 60

#
#echo "Check Ceph"
#pools=$(sudo ceph osd pool ls)
#
#if [[ $pools  != *"nova-compute"* ]]; then
#    echo "Creating nova-compute pool"
#    sudo ceph osd pool create nova-compute 64
#fi
#
#if [[ $pools  != *"glance"* ]]; then
#    echo "Creating glance pool"
#    sudo ceph osd pool create glance 64
#fi
#
#if [[ $pools  != *"cinder-ceph"* ]]; then
#    echo "Creating cinder-ceph pool"
#    sudo ceph osd pool create cinder-ceph 64
#fi
#
    


# Seems to be fixed in Queen2/Rocky
#if [ $version = "queen" ]; then 
#    echo "Wait for user input"
#    echo "Fix DNS issue in containers (Bionic)."
#    echo " append in /etc/netplan/99-juju.yaml;"
#    echo "search: [maas] "
#    echo "after nameservers, before addressess"
#    echo "juju ssh 2/lxd/2  sed -i '/nameservers:/a          search: [maas]' /etc/netplan/99-juju.yaml"
#    echo "juju ssh 2/lxd/2 sudo netplan apply"
#    juju ssh 2/lxd/2  sed -i '/nameservers:/a          search: [maas]' /etc/netplan/99-juju.yaml
#    juju ssh 2/lxd/2 sudo netplan apply
#
#    read -p "Enter to cont."
#    echo "Moving on"
#fi

bundle=bundle54 #default bundle

if [ $version = "mitaka" ]; then  
    #Mitaka
    echo "Mitaka version bundle"
    . bundle54/novarc
    bundle=bundle54
fi

if [ $version = "queen" ]; then  
    #Queen
    echo "Queen version bundle"
    . bundle56/openrc
    bundle=bundle56
fi


if [ $version = "queen2" ]; then  
    #Queen
    echo "Queen2 version bundle"
    . bundle58/openrc
    bundle=bundle58
fi

if [ $version = "rocky" ]; then  
    #Queen
    echo "Rocky version bundle"
    . bionic-rocky/openrc
    bundle=bionic-rocky
fi

if [ $version = "stein" ]; then  
    #Queen
    echo "Stein version bundle"
    . bundle61/openrc
    bundle=bundle61
fi



echo "Push in security rules, icmp and ssh" 
openstack security group rule create --description 'SSH' --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0 default
openstack security group rule create --description 'SSH' --protocol icmp --remote-ip 0.0.0.0/0 default

####
## Fix; addresses in 185 network , adjust VLAN ranges??  
##


## ADjust too fit network plan, i.e. the external networks of the environment. 
echo "Create networks"
#./$bundle/neutron-ext-net-ksv3 --network-type flat -g 192.168.185.1 -c 192.168.185.0/24 -f 192.168.185.41:192.168.185.70 ext_net

./$bundle/neutron-ext-net-ksv3 --network-type flat -g 192.168.185.1 -c 192.168.185.0/24 -f $ext185network ext_net

if [[ $version = "rocky" ]]
then
    ./$bundle/neutron-tenant-net-ksv3 -p admin -r provider-router --network-type vxlan internal 10.5.5.0/24
else
    ./$bundle/neutron-tenant-net-ksv3 -p admin -r provider-router internal 10.5.5.0/24
fi

#openstack network create  --provider-physical-network physnet1 --provider-network-type vlan --provider-segment 131 --description White --external ext-white
openstack network create  --provider-physical-network physnet1 --provider-network-type vlan --provider-segment $vlan --description White --external ext-white
openstack network create internal2
neutron subnet-create internal2 10.5.6.0/24  --name internal2_subnet   ##Replace to openstack syntax
openstack router create whiterouter
neutron router-gateway-set whiterouter ext-white
neutron router-interface-add whiterouter internal2_subnet

##Adjust to suit network plan
#neutron subnet-create ext-white 194.47.157.32/27  --name ext_white_subnet   ##Replace to openstack syntax
neutron subnet-create ext-white $routeraddr  --name ext_white_subnet   ##Replace to openstack syntax


echo "Grabbing Images"
curl http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img | openstack image create --public --container-format=bare --disk-format=qcow2 xenial
curl http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img | openstack image create --public --container-format=bare --disk-format=qcow2 bionic


echo "Creating flavors"
openstack flavor create --ram 2048 --disk 20 --vcpu 1 m1.small-no
openstack flavor create --ram 4096 --disk 20 --vcpu 1 m1.medium-no
openstack flavor create --ram 8192 --disk 20 --vcpu 1 m1.large-no

openstack flavor create --ram 2048 --disk 20 --vcpu 2 n1.small-no
openstack flavor create --ram 4096 --disk 20 --vcpu 2 n1.medium-no
openstack flavor create --ram 8192 --disk 20 --vcpu 2 n1.large-no

openstack flavor create --ram 2048 --disk 20 --vcpu 3 o1.small-no
openstack flavor create --ram 4096 --disk 20 --vcpu 3 o1.medium-no
openstack flavor create --ram 8192 --disk 20 --vcpu 3 o1.large-no


## 
echo "Update Quota defaults"
echo "vcpu instance floating-ip"
openstack quota set --instances 10 default
openstack quota set --floating-ip 5 default
openstack quota set --cores 20 default
openstack quota set --snapshots 6 default
openstack quota set --volumes 6 default
    


echo "a key"
openstack keypair create --public-key /home/ats/.ssh/id_rsa.pub Babba


echo "Deploy instance, associate ip"
openstack server create --flavor m1.small-no --image bionic  --network internal2 --key-name Babba Chappie
whiteaddress=$(openstack floating ip create --subnet ext_white_subnet ext-white | grep 'floating_ip_address' | awk '{print $4}' )
openstack server add floating ip Chappie  $whiteaddress

echo "Give the device time to boot, 60s"
sleep 60
echo "ping it"

ping -c 5 $whiteaddress


##Not working, code does work, but containers remain on 10.30 network  
#echo "Fix API endpoints"
#for service in cinder keystone glance nova-cloud-controller neutron-api;
#do
#    if [ $service = "nova-cloud-controller" ]
#    then
#	servicedns="nova";
#    elif [ $service = "neutron-api" ]
#    then
#	 servicedns="neutron";
 #   else
#	servicedns=$service;
#   fi
#					       
#    juju config $service os-admin-network=192.168.189.0/24
#    juju config $service os-admin-hostname=$servicedns.admin.queen2.nplab.bth.se
#    juju config $service os-internal-network=192.168.190.0/24
#    juju config $service os-internal-hostname=$servicedns.internal.queen2.nplab.bth.se
#    juju config $service os-public-network=192.168.191.0/24
#    juju config $service os-public-hostname=$servicedns.public.queen2.nplab.bth.se
#done
#juju config nova-compute os-internal-network=192.168.190.0/24



##Adding devices
#juju add-machine -n 1 --constraints cores=32 --series bionic
#This returns fail, or an machine ID, <machineid>.
#juju add-unit nova-compute --to <machineid>
# This will add neutron-openvswitch and ntp as well.

#List default quotas, should give something but error..
#openstack quota show --default

#
#openstack hypervisor list


#openstack network agent list
#openstack compute service list
#openstack compute service delete 8
#openstack compute service list
#openstack network agent delete 807bd65f-38c2-4d4a-ad52-f3400adaff86


### Add Glance Stream Sync, add as container on existing bionic machine, cf above for compute   
#juju add-machine lxd:<machineid> --series bionic
#juju deploy --series bionic --to 4/lxd/1  cs:glance-simplestreams-sync-15
#juju add-relation keystone glance-simplestreams-sync



#### HEAT
## Unclear on order..Have not tried..
#juju run-action heat/0 domain-setup
#juju deploy heat --bind "public=public-space internal=internal-space admin=admin-space shared-db=internal-space"



