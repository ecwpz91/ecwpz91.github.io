---
layout: "post"
title: "OpenShift and a Raspi NFS Gluster Cluster"
date: "2022-01-19 18:54"
---

# Problem

The following describes the process of setting up OpenShift to use a NFS-based storage class backed by a Gluster cluster on Raspberry Pi for dynamic provisioning of K8s Persistent Volumes via Persistent Volume Claims.

# Hardware - Raspberry Pi Cluster

![Raspberry Pi Cluster](/images/2022-01-19-191443.png)

# Solution

Install the operating system on all Raspberry Pi nodes in the cluster. We'll be using Fedora 35 Server.

1. Download [Fedora ARM image](https://getfedora.org/).
2. Prepare the SD card, manually.

        xzcat ./Fedora-Server-35-x.x.aarch64.raw.xz | dd status=progress bs=4M of=/dev/sdX

3. [Boot OS](https://fedoraproject.org/wiki/Architectures/ARM/Raspberry_Pi#Booting_Fedora_on_the_Raspberry_Pi_for_the_first_time) - setup authentication and network connection.
4. [Resize after initial-setup](https://fedoraproject.org/wiki/Architectures/ARM/Raspberry_Pi#Resize_after_initial-setup) (optional).

Format, check, and mount external physical drives for all nodes in the cluster. To simplify disk management, use LVM.

1. Create a Physical Volume (PV).

        pvcreate /dev/sdX

2. Create a Volume Group (VG).

        vgcreate gluster /dev/sdX

3. Create a Logical Volume (LV).

        lvcreate -n save -l 100%FREE gluster

4. Format the LV.

        mkfs.xfs /dev/gluster/save

5. Create a target directory for mounting the LV.

        mkdir -p /srv/gnfs

6. Backup `fstab`.

        cp /etc/fstab "/etc/fstab.$(date +"%Y-%m-%d")"

7. Modifying `fstab` to mount the filesystem during boot.

        vim /etc/fstab
        # fstab
        ....
        /dev/gluster/save       /srv/gnfs               xfs     defaults,_netdev,nofail        0 2

8. Mount the filesystem with `mount -a` and verify using `df -hT`.

Install GlusterFS Server on all nodes in the cluster.

    dnf -y install glusterfs-server
    systemctl enable --now glusterd
    gluster --version

If `firewalld` is running, allow GlusterFS service on all nodes.

    firewall-cmd --add-service=glusterfs --permanent
    firewall-cmd --reload

Create a directory for GlusterFS volume on all nodes.

    mkdir -p /srv/gnfs/dstb

Configure clustering on a node (use any node).

1. Probe nodes.

        [root@node03 ~]# gluster peer probe node01
        [root@node03 ~]# gluster peer probe node02
        [root@node03 ~]# gluster peer probe node03 (primary, will have nfs-ganesha)
        [root@node03 ~]# gluster peer probe node04

2. Confirm status.

        [root@node03 ~]# gluster peer status

3. Create volume.

        [root@node03 ~]# gluster volume create vol_gnfs_dstb replica 4 transport tcp \
                         node03:/srv/gnfs/dstb \
                         node01:/srv/gnfs/dstb \
                         node02:/srv/gnfs/dstb \
                         node04:/srv/gnfs/dstb

4. Start volume.

        [root@node03 ~]# gluster volume start vol_gnfs_dstb

5. Confirm volume info.

        [root@node03 ~]# gluster volume info

Install NFS-Ganesha on the primary node.

    [root@node03 ~]# dnf -y install nfs-ganesha-gluster

Export GlusterFS volume as NFS.

1. Backup Ganesha config.

        [root@node03 ~]# cp /etc/ganesha/ganesha.conf "/etc/ganesha/ganesha.conf.$(date +"%Y-%m-%d")"

2. Modify Ganesha config, see [exporting GlusterFS volume via NFS-Ganesha](https://docs.gluster.org/en/v3/Administrator%20Guide/NFS-Ganesha%20GlusterFS%20Integration/#step-by-step-procedures-to-exporting-glusterfs-volume-via-nfs-ganesha) or [example export config](https://raw.githubusercontent.com/phdeniel/nfs-ganesha/master/src/config_samples/export.txt) for options documentation.

        [root@node03 ~]# vim /etc/ganesha/ganesha.conf
        # ganesha.conf
        ...
            NFS_CORE_PARAM {
            ## Allow NFSv3 to mount paths with the Pseudo path, the same as NFSv4,
            ## instead of using the physical paths.
            #mount_path_pseudo = true;       
            
            ## Configure the protocols that Ganesha will listen for.  This is a hard
            ## limit, as this list determines which sockets are opened.  This list
            ## can be restricted per export, but cannot be expanded.
            #Protocols = 3,4,9P;

            #Use supplied name other tha IP In NSM operations                     
            NSM_Use_Caller_Name = true;
          
            #Copy lock states into "/var/lib/nfs/ganesha" dir
            Clustered = false;        

            #Use a non-privileged port for RQuota 
            Rquota_Port = 875;
            NFS_Port = 2049;      
            MNT_Port = 20048;
            NLM_Port = 38468;
        }
        ...
        EXPORT                                                                         
        {                          
            ## Export Id (mandatory, each EXPORT must have a unique Export_Id)
            Export_Id = 1;        
                                                                                                                                                                                                                                                                                  
            ## Exported path (mandatory)                   
            Path = "/mnt/gnfs"; 
                              
            ## Pseudo Path (required for NFSv4 or if mount_path_pseudo = true)
            Pseudo = "/mnt/gnfs"; 
                                                                                                                                                                                                                                                                                  
            ## Restrict the protocols that may use this export.  This cannot allow
            ## access that is denied in NFS_CORE_PARAM.
            Protocols = "3","4";           
                                                            
            ## Access type for clients.  Default is None, so some access must be
            ## given. It can be here, in the EXPORT_DEFAULTS, or in a CLIENT block
            Access_type = RW;
    
            ## Whether to squash various users.                             
            Squash = No_root_squash;                                              
                                
            ## Allowed security types for this export
            SecType = "sys";                           

            ## Exporting FSAL                                   
            FSAL {  
                    name = GLUSTER;                                               
                    hostname = "localhost";        
                    volume = "vol_gnfs_dstb";
            }
                                                                                    
            Transports = "UDP","TCP"; # Transport protocols supported             
            Disable_ACL = TRUE;  # To enable/disable ACL           
        }
        ...

3. Start and enable NFS-Ganesha.

        [root@node03 ~]# systemctl enable --now nfs-ganesha

4. If `firewalld` is running, allow NFS services.

        [root@node03 ~]# firewall-cmd --add-service=nfs --permanent
        [root@node03 ~]# firewall-cmd --add-service=mountd --permanent
        [root@node03 ~]# firewall-cmd --add-service=rpc-bind --permanent
        [root@node03 ~]# firewall-cmd --reload

5. Verify sockets are listening and the NFS share has been mounted.

        [root@node03 ~]# ss -nltupe | grep -E ':2049|:20048|:111'
        [root@node03 ~]# showmount -e localhost

Configure OpenShift to use [K8s NFS Subdir External Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner.git) as default storage class.

1. Clone the git repo and change directory.

        git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner.git
        cd nfs-subdir-external-provisioner

2. Replace the namespace parameter and backup the `rbac.yaml` file.

        sed -i.backup 's/namespace:.*/namespace: nfs-storage/g' ./deploy/rbac.yaml

3. Replace the namespace parameter and backup the `deployment.yaml` file.

        sed -i.backup 's/namespace:.*/namespace: nfs-storage/g' ./deploy/deployment.yaml

4. Modify the `deployment.yaml` file.

        vim ./deploy/deployment.yaml
        # deployment.yaml
        ...
                    - name: NFS_SERVER
                      value: NFS.GANESHA.IP.ADDRESS (primary, will have nfs-ganesha)
                    - name: NFS_PATH
                      value: /mnt/gnfs
              volumes:
                - name: nfs-client-root
                  nfs:
                    server: NFS.GANESHA.IP.ADDRESS (primary, will have nfs-ganesha)
                    path: /mnt/gnfs
        ...

5. Backup the `class.yaml` file.

        cp -v ./deploy/class.yaml ./deploy/class.yaml.backup

6. Modify the `class.yaml` file.

        vim ./deploy/class.yaml
        # class.yaml
        ...
        metadata:
          annotations:
            storageclass.kubernetes.io/is-default-class: 'true'
          name: managed-nfs-storage
        ...

Perform the following commands as the OpenShift cluster admin.

1. Create a new OpenShift project.

        oc new-project nfs-storage

2. Deploy the NFS subdir external provisioner.

        oc create -f ./deploy/rbac.yaml
        oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:nfs-storage:nfs-client-provisioner
        oc create -f ./deploy/deployment.yaml
        oc create -f ./deploy/class.yaml

# Summary

Congratulations! You've successfully created a NFS-based storage class on OpenShift that is backed by a Gluster cluster on Raspberry Pi.