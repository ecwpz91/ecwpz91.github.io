---
layout: post
title: CloudForms via OpenShift using Docker
date: '2017-09-08 18:25'
---

# Problem

The following describes the process of trying out CloudForms locally using an installation of Fedora 26.

# Solution

Use Local Cluster Management along with the OpenShift "oc cluster up" Wrapper script.

1. Open a terminal and install Docker.

  ```
  echo -n "root@$HOSTNAME "; su - root -c "dnf install docker -y"
  ```

2. Setup block-level storage driver (optional).

  Why? Performs better for write-heavy workloads (though not as well as Docker volumes).

  **WARNING** Not responsible for direct, indirect, incidental or consequential damages resulting from any defect, error or failure to perform.

  - (Re)boot the system.
  - Interrupt the boot loader menu countdown by pressing any key.
  - Move the cursor to the entry to be started.
  - Press e to edit the current entry.
  - Move the cursor to the line that starts with linux16\. This is the kernel command line.
  - Append `rd.break`
  - Press Ctrl+x to boot with these changes.

  ```
  # Mount the file system as read/write
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
  ```

3. Manage Docker as a non-root user (optional).

  ```
  groupadd docker
  usermod -aG docker $USER
  ```

4. Start Docker on boot.

  ```
  systemctl enable docker
  systemctl reboot
  ```

5. Download the Linux oc binary from Red Hat Customer Portal and place it in your path.

  ```
  #!/bin/bash

  TMP_DIR=$(mktemp --suffix oc-cli -d)
  OC_HOME=/usr/bin
  ARCHIVE=$HOME/Downloads/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz

  # Check if archive exists
  [[ ! -f $ARCHIVE ]] && echo "Archive not found" && exit 1

  # Extract tarball
  tar -xzf $ARCHIVE -C $TMP_DIR --strip 1 &>/dev/null

  # Add execution file mode
  chmod +x $TMP_DIR/oc

  # Install and setup bash completion
  echo -n "root@$HOSTNAME "; su - root -c "cp -f $TMP_DIR/oc $OC_HOME
                                         oc completion bash > /etc/bash_completion.d/oc-cli
                                         source /etc/bash_completion.d/oc-cli"

  # Source system wide initialization file
  source /etc/bashrc
  ```

6. Check that `sysctl net.ipv4.ip_forward` is set to 1.
7.

# Summary

[1]: https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md#linux
[2]: https://github.com/openshift-evangelists/oc-cluster-wrapper
[3]: https://access.redhat.com/downloads/content/290
