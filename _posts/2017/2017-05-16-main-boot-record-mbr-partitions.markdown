---
layout: "post"
title: "Main Boot Record (MBR) Partitions"
date: "2017-05-16 16:53"
---

Device Name | Description
--|--
/dev/sda  |  A hard disk that uses the SCSI driver.
/dev/hda  |  The legacy IDE disk device type.
/dev/vda  |  A disk in a KVM virtual machine that uses the virtio disk driver.
/dev/xvda |  A disk in a Xen virtual machine that uses the Xen virtual disk driver.

1. Backup the first MB of raw blocks for easy rollback.


    dd if=/dev/${DEVICE_NAME} of=/root/diskfile bs=1MB count=1

2. Backup the `fstab` file as well.


    cp /etc/fstab /root/fstab

3. Run the  `fdisk` command.


    fdisk /dev/${DEVICE_NAME}

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


    fdisk -l /dev/${DEVICE_NAME}
    cat /proc/partitions

12. Either reboot, or use the following command to write the changes to the kernel.


    partprobe

**[NOTE]** if you experience any issues with `partprobe`, reboot the system.
