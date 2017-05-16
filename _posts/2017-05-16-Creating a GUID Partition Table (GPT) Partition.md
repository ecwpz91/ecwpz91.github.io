---
layout: post
title: "Creating a GUID Partition Table (GPT) Partition"
date: "2017-05-16 18:07"
---

# Problem

The following describes the process of creating an GPT partition with `gdisk` using an installation of RHEL/CentOS.

# Notable

* If a disk is configured with a GPT already, or it is a new wiped disk that has a size greater than 2TiB (1024^4), you must use `gdisk` to create partitions.

* Do **NOT** ever use `gdisk` on a disk that has been formatted with `fdisk` and already contains `fdisk` partitions.

* On computers using the new Unified Extensible Firmware Interface (UEFI) BIOS system, GPT partitions are the only way to address disks.

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

3. Run the  `gdisk` command.

        gdisk /dev/${DEVICE}

4. Type `n` to add a new partition.
5. Use the default suggestion that specifies the first sector on disk that the new partition will start on.
6. Specify the last sector that the partition will end on. If you use the default, then you will not have any disk space left to create additional partitions or logical volumes. To use another last sector:
  * Enter the number of the last sector you want to use.
  * Enter +number to create a partition that sizes a specific number of sectors.
  * Enter +number(K,M,G,T,P) to specify the size you want to assign to the partition in KiB, MiB, GiB, TiB, or PiB.

7. You are now asked to set the partition type (8300 default).
  * 8200: Linux swap
  * 8300: Linux
  * 8e00: Linux LVM

8. Pres `p` to show an overview and verify the output.
9. Write the changes to the disk and exit by pressing `w`.
10. Either reboot, or use the following command to write the changes to the kernel.

        partprobe

    :information_source: if you experience any issues with `partprobe`, reboot the system.

# Summary

The need for GPT partitioning originates from the fact that hard drives are much larger today than they were in the past. In fact, the original partitioning scheme (MBR) was only 64 bytes, which resulted in a max of four partition table entries.

Although one could workaround this limitation in MBR by using an extended partition to reach a max of 15 logical partitions, you'd be risking the failure of all logical partitions that exist within it if something were to go wrong.

Using GUID offers the following benefits:
* Max partition size of 8 ZiB
* Support for a maximum of 128 partition table entries
* Disk size can be greater than 2TiB
* No need to distinguish between primary, extended, and logical partitions due to a larger partitioning scheme
* Easily identify partitions using a global unique ID (GUID)
* A backup copy of the GPT is created at the end of the disk by default
