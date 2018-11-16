# bootstrap
Using Juju Charms and Bundles to deploy Openstack on MAAS

Requirements:
1) MAAS cloud, and associted user/credentials. 
2) Juju controller. 

The MAAS setup should be 

                  +--------------deployment------------------------------------------------------
Internet ------MAAS             node1(eno1->deployment, eno2->others) ...  nodeN(eno1->deployment, eno2->others) ...
Networks          +---------------------------------------------------------------------------------------

BMC is handled magically :) 




Usage; 
./bootstrap.sh rocky 131 100:110 192.168.185.10:192.168.185.39 194.4x.1xx.33/27 20181116r1


This would deploy 'rocky' using the credential called rocky.
It will use vlan 100 to 110 for VMs...
It will create four networks, two external a) 192.168.185.10:192.168.185.39 and b) 19x.4x.1xx.33/27.
The 192.168.185.0/24 expects an external dhcp, the 194.4x.1xx.33 expects that a router is at .33. 
20181116r1 is just a tag, as to track/log. 

