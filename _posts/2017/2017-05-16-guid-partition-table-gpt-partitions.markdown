---
layout: "post"
title: "GUID Partition Table (GPT) Partitions"
date: "2017-05-16 17:24"
---

The following describes the process of creating an GPT partition with `gdisk` using an installation of RHEL/CentOS.

* If a disk is configured with a GPT already, or it is a new wiped disk that has a size greater than 2TiB (1024^4), you must use `gdisk` to create partitions.

* Do **NOT** ever use `gdisk` on a disk that has been formatted with `fdisk` and already contains `fdisk` partitions.

Device |
-- | --
/dev/sda | A hard disk that uses the SCSI driver.
/dev/hda | The legacy IDE disk device type.
/dev/vda | A disk in a KVM virtual machine that uses the virtio disk driver.
/dev/xvda | A disk in a Xen virtual machine that uses the Xen virtual disk driver.

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

**[NOTE]** if you experience any issues with `partprobe`, reboot the system.
