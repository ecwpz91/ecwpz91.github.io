---
layout: post
title: CloudForms via OpenShift using Docker
date: '2017-09-08 18:25'
---

# Problem

The following describes the process of trying out CloudForms via OpenShift using Docker on Fedora 26.

# Solution

Use [Local Cluster Management][1] along with the [OpenShift "oc cluster up" Wrapper script][2].

1. Open a terminal and install Docker.

       dnf install docker -y

2. Grow the file system and [set up storage for docker][6].

       # Start one systemd unit and stop all others
       systemctl isolate multi-user.target

       # Unmount the partition by logging in as root and typing:
       VG_NAME=fedora
       LV_NAME=home

       umount /dev/${VG_NAME}/${LV_NAME}

       # Resize logical volume
       lvchange -a y ${VG_NAME}/${LV_NAME}
       lvreduce -r -L -20GB /dev/${VG_NAME}/${LV_NAME}
       docker-storage-setup --reset
       echo "VG=${VG_NAME}" >> /etc/sysconfig/docker-storage-setup
       docker-storage-setup

       # Start docker on boot
       systemctl enable docker

       # Manage docker as a non-root user (optional)
       groupadd docker
       usermod -aG docker ${USER}

       # Restart the system
       systemctl reboot

3. Download the Linux `oc` binary from [Red Hat Customer Portal][3] and place it on your path.

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
       oc completion bash > $HOME/.local/bin/oc.bash

       # Source bash profile
       source $HOME/.bashrc

4. Check that `sysctl net.ipv4.ip_forward` is set to 1.

5. Edit `/etc/sysconfig/docker` as root and add the following to the `OPTIONS` parameter.

       OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16 --log-opt max-size=1M --log-opt max-file=3'

       # Restart the docker service
       systemctl restart docker

6. Create a new firewalld zone for the subnet and grant it access to the API and DNS ports.

       # First, check if firewalld is enabled and active
       systemctl is-enabled firewalld
       systemctl is-active firewalld

       # If not, do so accordingly
       systemctl enable firewalld
       systemctl start firewalld

       # Configure the following firewall settings
       firewall-cmd --permanent --new-zone dockerc
       firewall-cmd --permanent --zone dockerc --add-source 172.17.0.0/16
       firewall-cmd --permanent --zone dockerc --add-port 8443/tcp
       firewall-cmd --permanent --zone dockerc --add-port 53/udp
       firewall-cmd --permanent --zone dockerc --add-port 8053/udp
       firewall-cmd --reload

7. Install `oc-cluster` wrapper script.

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
       echo "PATH=${OC_WRAPPER}:$PATH" >> $HOME/.bashrc

       # Create bash completion
       oc-cluster completion bash > $HOME/.local/bin/oc-cluster.bash

       # Source bash profile
       source $HOME/.bashrc

8. Start the OpenShift cluster and make the default user a cluster administrator.

        oc-cluster up
        oc login -u system:admin
        oc adm policy add-cluster-role-to-user cluster-admin developer
        oc login -u developer -p devel

9. Deploy CloudForms on top of OpenShift.

        oc-cluster plugin-install cfme

10. Open a browser and visit `https://cloudforms-cfme.apps.127.0.0.1.nip.io`.

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
[6]: https://docs.openshift.com/container-platform/latest/install_config/install/host_preparation.html#configuring-docker-storage
