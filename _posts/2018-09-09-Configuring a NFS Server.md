---
layout: "post"
title: "Configuring a NFS Server"
date: "2018-27-09 09:28"
---

# Problem

The following describes the process of configuring NFS using an installation of RHEL/CentOS.

# Notable

* On RHEL 7, NFSv4 is the default version used and maintains backwards compatibility with earlier protocols.
* The meaning of the export table options (`rw`, `all_squash`, etc.) can be found using the command `man exports`.
* Check out the man pages for fstab format and options for the nfs file systems using the command `man 5 nfs`.

# Solution

## Set up the NFS server

1. Install required utilities for NFS

        yum -y install rpcbind nfs-utils policycoreutils-python

2. Create NFS server share directory

        mkdir -p /srv/nfsexport

3. Set ownership of the directory

        chown -R nfsnobody:nfsnobody /srv

4. Set permissions of the directory

        chmod -R 755 /srv/*

5. Change the label of `/srv/nfsexport`, recursively, to the nfs_t type in order to allow the NFS server to access share.

        semanage fcontext --add --type nfs_t "/srv/nfsexport(/.*)?"

6. Apply the SELinux policy setting to the file system

        restorecon -R -v /srv/nfsexport

7. Start the NFS server

        systemctl start nfs-server

8. Enable the service to start at boot

        systemctl enable nfs-server

9. Update NFS server export table to share the newly created directory

        echo "/srv/nfsexport *(rw,all_squash)" >> /etc/exports

    **Notice** This allows both read and write requests on this NFS volume and maps all UID/GID to the anonymous user.

10. Make all changes effective by reloading the configuration file.

        exportfs -r

11. Open firewall for NFS server

        firewall-cmd --permanent --add-service=nfs
        firewall-cmd --permanent --add-service=mountd
        firewall-cmd --permanent --add-service=rpc-bind
        firewall-cmd --reload

12. Verify the NFS share has been mounted

        showmount -e localhost

## Set up the NFS client

1. Attempt to access the NFS server

        NFS_SERVER="" && showmount -e $NFS_SERVER

2. Create the mount point

        mkdir -p /mnt/nfsshare

3. Create an `/etc/fstab` entry for the NFS server

        NFS_SERVER="" && echo "$NFS_SERVER:/srv/nfsexport /mnt/nfsshare nfs defaults 0 0" >> /etc/exports

4. Mount the exported NFS share directory

        mount -a

5. Verify the NFS share is mounted and writable

        touch /mnt/nfsshare/test.txt
        ls -l /mnt/nfsshare

# Summary

NFS is an Internet Standard protocol created by Sun Microsystems in 1984. NFS was developed to allow file sharing between systems residing on a local area network.

In NFS, an NFS server is offering shares, which are also referred to as `exports`, and the NFS client mounts the share to it's local file system and supports three versions of the NFS protocol: NFS version 2 [RFC1094](https://tools.ietf.org/html/rfc1094), NFS version 3 [RFC1813](https://tools.ietf.org/html/rfc1813), and NFS version 4 [RFC3530](https://tools.ietf.org/html/rfc3530).

To use an NFS, you should follow these two steps:

-   Mount it - attach the local file system found on some device to the big tree file tree, the file hierarchy, rooted at `/` of the server.
-   Access it - mount the NFS share into the local file system of the NFS client computer.

# Troubleshooting

If you're using `iptables` for configuring security instead of `firewalld`, use the following commands to open the firewall for the NFS server:

        # Set the firewall rules to allow access to the NFS service
        iptables -I INPUT 1 -p tcp --dport 2049 -j ACCEPT
        iptables -I INPUT 1 -p tcp --dport 20049 -j ACCEPT
        iptables -I INPUT 1 -p tcp --dport 111 -j ACCEPT

        # Save the firewall rules
        service iptables save
