---
layout: post
title: "Creating a Master Boot Record (MBR) Partition"
date: "2017-05-16 18:05"
---

# Problem

The following describes the process of creating an MBR partition with `fdisk` using an installation of RHEL/CentOS.

# Solution

DEVICE     |
---------- | ----------
/dev/sda   | &nbsp;A hard disk that uses the SCSI driver.
/dev/hda   | &nbsp;The legacy IDE disk device type.
/dev/vda   | &nbsp;A disk in a KVM virtual machine that uses the virtio disk driver.
/dev/xvda  | &nbsp;A disk in a Xen virtual machine that uses the Xen virtual disk driver.

<br/>
1. Backup the first megabyte of raw blocks for easy rollback.

        dd if=/dev/${DEVICE} of=/root/diskfile bs=1MB count=1

2. Backup the `fstab` file as well.

        cp /etc/fstab /root/fstab

3. Run the  `fdisk` command.

        fdisk /dev/${DEVICE}

4. Check how much disk space is available. Press `p` to see an overview of the current disk allocation. Look for the total number of sectors and compare it to the last sector that is currently used. If the last partition does not end on the last sector, you have space available to create a new partition.

5. Type `n` to add a new partition.
6. MBR partitions are limited to a max of four logical partitions. If you need more than four logical partitions, select the extended option `e` in order to create logical partitions within an extended partition. Keep in mind that if there is an issue with the extended partition, all logical partitions will be affected. Otherwise, select the primary option `p` to create a primary partition.
7. Use the default suggestion that specifies the first sector on disk that the new partition will start on.
8. Specify the last sector that the partition will end on. If you use the default, then you will not have any disk space left to create additional partitions or logical volumes. To use another last sector:
  * Enter the number of the last sector you want to use.
  * Enter +number to create a partition that sizes a specific number of sectors.
  * Enter +number(K,M,G) to specify the size you want to assign to the partition in KiB, MiB, or GiB.

9. Define the partition type by pressing `t` to change it.
  * 82: Linux swap
  * 83: Linux
  * 8e: Linux LVM

10. Write the changes to the disk and exit by pressing `w`.
11. Compare the in-memory kernel partition table by issuing the following commands:

        fdisk -l /dev/${DEVICE}
        cat /proc/partitions

12. Either reboot, or use the following command to write the changes to the kernel.

        partprobe

    :information_source: if you experience any issues with `partprobe`, reboot the system.

# Summary

The MBR contains all that is needed to start a computer and is known as the first 512 bytes on a hard drive. Although still used today,the  GUID Partition Table (GPT) partitioning scheme has become the norm in order to address the ever growing size of hard drives.
