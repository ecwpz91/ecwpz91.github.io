---
layout: post
title: CloudForms via OpenShift using Docker
date: '2017-09-08 18:25'
---

# Problem

The following describes the process of trying out CloudForms via Docker locally using an installation of Fedora 26.

# Solution

Use [Local Cluster Management][1] along with the [OpenShift "oc cluster up" Wrapper script][2].

1. Open a terminal and install Docker.

       dnf install docker -y

2. Setup block-level storage driver (optional).

   Why? Performs better for write-heavy workloads (though not as well as Docker volumes).

   **WARNING** Not responsible for direct, indirect, incidental or consequential damages resulting from any defect, error or failure to perform.

       # (Re)boot the system
       # Interrupt the boot loader menu countdown by pressing any key
       # Move the cursor to the entry to be started
       # Press 'e' to edit the current entry
       # Move the cursor to the line that starts with linux16
       # Append 'rd.break'
       # Press 'ctrl+x' to boot with these changes, then perform the following:

       # Remount the file system as read/write
       mount -o rw,remount /sysroot

       # Mount lvm dependencies
       mount -B /proc /sysroot/proc
       mount -B /dev /sysroot/dev
       mount -B /sys /sysroot/sys
       mount -B /run /sysroot/run

       # Change root directory
       chroot sysroot/

       # Resize logical volume
       lvchange -a y fedora/home
       lvreduce -r -L -20GB /dev/fedora/home
       rm -rf /etc/sysconfig/docker-storage
       echo "VG=fedora" > /etc/sysconfig/docker-storage-setup
       docker-storage-setup
       lvextend -r -l +100%FREE /dev/fedora/docker-pool

       # Restart the system
       exit
       reboot

3. Manage Docker as a non-root user (optional).

       groupadd docker
       usermod -aG docker $USER

4. Start Docker on boot.

       systemctl enable docker
       systemctl reboot

5. Download the Linux oc binary from [Red Hat Customer Portal][3] and place it on your path.

   Alternatively, create and run the following script:

       #!/bin/bash

       TMP_DIR=$(mktemp --suffix oc-cli -d)
       OC_HOME=/usr/bin
       ARCHIVE=$HOME/Downloads/oc-3.6.173.0.21-linux.tar.gz

       # Check if archive exists
       [[ ! -f $ARCHIVE ]] && echo "Archive not found" && exit 1

       # Extract tarball
       tar -xzf $ARCHIVE -C $TMP_DIR &>/dev/null

       # Add execution file mode
       chmod +x $TMP_DIR/oc

       # Install and setup bash completion
       echo -n "root@$HOSTNAME "; su - root -c "cp -f $TMP_DIR/oc $OC_HOME
                                     oc completion bash > /etc/bash_completion.d/oc-cli
                                     source /etc/bash_completion.d/oc-cli"

       # Source system wide initialization file
       source /etc/bashrc

6. Check that `sysctl net.ipv4.ip_forward` is set to 1.

7. Edit the `/etc/sysconfig/docker` file and add `--insecure-registry 172.30.0.0/16` to the `OPTIONS` parameter.

       OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'

8. Create a new firewalld zone for the subnet and grant it access to the API and DNS ports.

       firewall-cmd --permanent --new-zone dockerc
       firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
       firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
       firewall-cmd --permanent --zone dockerc --add-port 53/udp
       firewall-cmd --permanent --zone dockerc --add-port 8053/udp
       firewall-cmd --reload

9. Install oc-cluster wrapper.

       #!/bin/bash
       OC_WRAPPER=$HOME/.local/share/oc-cluster-wrapper
       GITHUB_ZIP=https://github.com/openshift-evangelists/oc-cluster-wrapper/archive/master.zip

       # Download and extract
       curl -LOk ${GITHUB_ZIP} \
       && temp=$(mktemp -d) \
       && unzip -d ${temp} master.zip \
       && mkdir -p ${OC_WRAPPER} \
       && mv ${temp}/*/* ${OC_WRAPPER} \
       && rm -rf ${temp} master.zip

       # Add wrapper to PATH
       echo "PATH=$OC_WRAP:$PATH" >> $HOME/.bashrc

       # Create wrapper bash completion
       oc-cluster completion bash > $OC_WRAP/oc-cluster.bash

       # Add completion to PATH
       echo "source $OC_WRAP/oc-cluster.bash"

10. Start the OpenShift cluster and make the default user a cluster administrator.

        oc-cluster up
        oc login -u system:admin
        oc adm policy add-cluster-role-to-user cluster-admin developer
        oc login -u developer -p devel

11. Deploy CloudForms ontop of OpenShift.

        oc-cluster plugin-install cfme

12. Open a browser and goto `https://cloudforms-cfme.apps.127.0.0.1.nip.io`.

# Troubleshooting

## CloudForms setup fails on OpenShift

If the `postgresql` pod fails to schedule and shuts down, the `cloudforms` pod fails to deploy, or `https://cloudforms-cfme.apps.127.0.0.1.nip.io` won't load...

Try implementing the [patch][4] I've made (based off [PR #59][5]), like so:

    #!/bin/bash

    OC_WRAPPER=$HOME/.local/share/oc-cluster-wrapper
    PLUGIN_DIR=${OC_WRAPPER}/plugins.d
    GITHUB_CID=5bb77eb6e5eff1aa431d9f1db103afa14976dae9
    GITHUB_RAW=https://raw.githubusercontent.com/ecwpz91/oc-cluster-wrapper
    GITHUB_URI=${GITHUB_RAW}/${GITHUB_CID}/plugins.d/cfme.local.plugin

    pushd ${PLUGIN_DIR}
    mv cfme.local.plugin cfme.local.plugin.backup
    curl ${GITHUB_URI} > cfme.local.plugin
    popd

Then reset the environment using `oc-cluster destroy`, and repeat steps 10-12 above.

# Summary

This tutorial helps developers and operation engineers get hands-on with CloudForms and OpenShift locally using Docker containers only.

For any purist out there, and memory concerned individuals, this solution provides a great way to "cut the fat" associated with provisioning VMs.

Also, since CloudForms has a dependency on persistent volume storage, the wrapper script provides very useful functions for cluster profiling and local storage.

Pretty neat example of how open source community continues to drive innovation around container tooling, don't you think?

[1]: https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md#linux
[2]: https://github.com/openshift-evangelists/oc-cluster-wrapper
[3]: https://access.redhat.com/downloads/content/290
[4]: https://github.com/openshift-evangelists/oc-cluster-wrapper/compare/master...ecwpz91:master#diff-dc69f8a6772962ea80798d5ada35e9b7
[5]: https://github.com/openshift-evangelists/oc-cluster-wrapper/pull/59
