---
layout: post
title: "Getting and Installing Ansible Tower"
date: "2017-06-22 15:01"
---

# Problem

The following describes the process of trying out Ansible Tower locally using an installation of Fedora 25.

# Notable

* Make sure you enable Legacy/CSM Boot Support in UEFI Firmware (BIOS).
* CentOS 7/6/5 and Red Hat (RHEL) 7/6/5 needs [EPEL][1] repository.
* If you want to install vagrant via `dnf install vagrant`, first follow [Gems installation][2].

# Solution

Use Ansible's official Vagrant box to quickly build an Ansible Tower VM.

1. Update kernel version.

        # Enable VirtualBox repo
        pushd /etc/yum
        wget http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
        popd

        # Get the most current version of all packages
        dnf clean all
        rm -rf /var/cache/dnf/*
        dnf makecache fast
        dnf update -y
        dnf autoremove -y

        # Reboot
        reboot

2. Install [VirtualBox][3].

        # Install dependency packages
        dnf install -y binutils gcc make patch libgomp glibc-headers glibc-devel \
                       kernel-headers kernel-devel dkms

        # Install latest version
        dnf install VirtualBox-5.1

        # Rebuild kernel modules
        /usr/lib/virtualbox/vboxdrv.sh setup

        # Add yourself to the VirtualBox group
        usermod -a -G vboxusers username

        # Start VirtualBox
        VirtualBox

3. Install [Vagrant][4].

        # If you installed gems from Fedora official repo (see notables above)
        dnf install vagrant

        # Otherwise, follow Vagrant's online documentation.

4. Use `libvirt` as a non-root user.

        # Check if the group already exists
         grep -o libvirt.* /etc/group

        # If not, create it
        groupadd -g 986 libvirt

        # Add user account to the libvirt group
        usermod -aG libvirt username

        # Verify that the user is added to the libvirt group
        groups username

4. Create a personal directory for saving Ansible Tower Vagrantfile's.

        # Create a new directory with name path
        mkdir -p $HOME/virt/ansible-tower/2.1.4

5. Change into the newly created directory and execute the following commands:

        pushd $HOME/virt/ansible-tower/2.1.4

        # Create a new Vagrantfile using the Tower base box from Ansible
        varant init tower http://vms.ansible.com/ansible-tower-2.1.4-virtualbox.box

        # Build the Tower VM.
        vagrant up

        # Log into the VM, and Tower will display a message with connection information
        vagrant ssh

6. Visit the URL provided by the login welcome message (something like `https://10.42.0.42/`), and after confirming a security exception for the Ansible Tower certificate, login with the credentials from Step 6.

7. At this point, you will need to register a free trial license of Ansible Tower following the instructions on the screen. The free trial allows you to use all of Tower’s features for up to 10 servers, and is great for experimenting and seeing how Tower fits into your workflow. After you get the license (it’s a block of JSON which you paste into the license field), you should get to Tower’s default dashboard page.

# Summary

Ansible Tower is centered around the idea of organizing Projects (which run your playbooks via Jobs) and Inventories (which describe the servers on which your playbooks should be run) inside of Organizations. Organizations are then set up with different levels of access based on Users and Credentials grouped in different Teams. It’s a little overwhelming at first, but once the initial structure is configured, you’ll see the power and flexibility Tower’s Project workflow affords.

# Resources

* [Ansible for DevOps: Server and Configuration Management for Humans][5]
* [VirtualBox 5.1 on Fedora 25/24, CentOS/RHEL 7.3/6.9/5.11][6]

[1]: https://fedoraproject.org/wiki/EPEL
[2]: https://developer.fedoraproject.org/tech/languages/ruby/gems-installation.html
[3]: https://www.virtualbox.org/wiki/Downloads
[4]: https://www.vagrantup.com/downloads.html
[5]: https://www.ansiblefordevops.com/
[6]: https://www.if-not-true-then-false.com/2010/install-virtualbox-with-yum-on-fedora-centos-red-hat-rhel/
