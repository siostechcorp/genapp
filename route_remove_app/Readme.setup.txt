README.txt

Setup
1. mkdir /tmp/routeSIOS
2. Download script tar file
3. Untar in a directory /tmp/routeSIOS
4. Use GUI to create a gen/app resource
5. Specify /tmp/routeSIOS/restore for the restore script
6. Select remaining scripts
7. Input the <ip destination> <mask> <interface>  space separated into the field.  See example info below
8. Select Yes for put in service
9. Extend hierarchy

Example:
Here is the route list for my system with my problem route highlighted

[root@baymax ipA]# netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.3.254    0.0.0.0         UG        0 0          0 eth0
10.10.20.0      0.0.0.0         255.255.255.0   U         0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.252.0   U         0 0          0 eth0

The destination for the info field in this example will be 10.10.20.0
The mask for this example will be 24 (it must be in the correct mask notation)
The device for this example will be eth0

Here is the info field for my resource:
# lcdstatus
ROOT of RESOURCE HIERARCHY
RT: id=RT app=gen type=app state=OSU
        initialize=(AUTORES_ISP) automatic restore to IN-SERVICE by LifeKeeper
        info=10.10.20.0 24 eth0
