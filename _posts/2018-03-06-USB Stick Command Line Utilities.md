---
layout: post
title: "USB Stick Command Line Utilities"
date: "2018-03-06 16:15"
---

# Problem

The following describes some command line utilities encountered when dealing with USB devices on an installation of RHEL/CentOS.

# Solution

1. Before plugging in a USB stick (done later), open a terminal, login as root via `su -`.

2. First issue `df -HT` to list our system's currently attached mount points.

       Filesystem            Type      Size  Used Avail Use% Mounted on
       /dev/mapper/rhel-root xfs       xxxG  xxxG   xxG   x% /
       devtmpfs              devtmpfs   xxG     x   xxG   x% /dev
       tmpfs                 tmpfs      xxG     x   xxG   x% /dev/shm
       tmpfs                 tmpfs      xxG  xxxM   xxG   x% /run
       tmpfs                 tmpfs      xxG     x   xxG   x% /sys/fs/cgroup
       /dev/sda1             xfs       xxxG  xxxM  xxxM  xx% /boot
       /dev/mapper/rhel-home xfs       xxxG   xxM  xxxG  xx% /home
       tmpfs                 tmpfs     xxxG     x  xxxG   x% /run/user/0
       tmpfs                 tmpfs     xxxG     x  xxxG   x% /run/user/543218

3. Next type `lsblk -f` to examine the list of attached block devices.

       NAME          FSTYPE      LABEL UUID                      MOUNTPOINT
       sda
       ├─sda1        xfs               xxx-xxx-xxx-xxx-xxx-xxx   /boot
       └─sda2        LVM2_member       xxx-xxx-xxx-xxx-xxx-xxx
         ├─rhel-root xfs               xxx-xxx-xxx-xxx-xxx-xxx   /
         ├─rhel-swap swap              xxx-xxx-xxx-xxx-xxx-xxx   [SWAP]
         └─rhel-home xfs               xxx-xxx-xxx-xxx-xxx-xxx   /home

4. Then get the list of attached disk partitions to our system using `fdisk -l`.

       Disk /dev/sda: xxx GB, xxx bytes, xxx sectors
       Units = sectors of 1 * 512 = 512 bytes
       Sector size (logical/physical): 512 bytes / 512 bytes
       I/O size (minimum/optimal): 512 bytes / 512 bytes
       Disk label type: dos
       Disk identifier: 0x0006f012

          Device Boot      Start         End      Blocks   Id  System
       /dev/sda1   *         xxx         xxx         xxx   83  Linux
       /dev/sda2             xxx         xxx         xxx   8e  Linux LVM

       Disk /dev/mapper/rhel-root: xxx GB, xxx bytes, xxx sectors
       Units = sectors of 1 * 512 = 512 bytes
       Sector size (logical/physical): 512 bytes / 512 bytes
       I/O size (minimum/optimal): 512 bytes / 512 bytes


       Disk /dev/mapper/rhel-swap: xxx GB, xxx bytes, xxx sectors
       Units = sectors of 1 * 512 = 512 bytes
       Sector size (logical/physical): 512 bytes / 512 bytes
       I/O size (minimum/optimal): 512 bytes / 512 bytes


       Disk /dev/mapper/rhel-home: xxx GB, xxx bytes, xxx sectors
       Units = sectors of 1 * 512 = 512 bytes
       Sector size (logical/physical): 512 bytes / 512 bytes
       I/O size (minimum/optimal): 512 bytes / 512 bytes

5. OK, plug in a USB.
5. You can check for any issues with attaching our hardware device via `dmesg | tail -20`.

       ...
       [ 4654.519577] usb-storage 1-4:1.0: USB Mass Storage device detected
       [ 4654.519955] scsi host5: usb-storage 1-4:1.0
       [ 4654.520021] usbcore: registered new interface driver usb-storage
       [ 4654.525288] usbcore: registered new interface driver uas
       [ 4655.521678] scsi 5:0:0:0: Direct-Access SanDisk xxx xxx xxx PQ: x ANSI: x
       [ 4655.522240] sd 5:0:0:0: Attached scsi generic sg1 type 0
       [ 4655.523028] sd 5:0:0:0: [sdb] xxx 512-byte logical blocks: (xxx GB/xxx GiB)
       [ 4655.524886] sd 5:0:0:0: [sdb] Write Protect is off
       [ 4655.524889] sd 5:0:0:0: [sdb] Mode Sense: 43 00 00 00
       [ 4655.526010] sd 5:0:0:0: [sdb] Write cache: disabled, read cache: enabled
       [ 4655.542887] sd 5:0:0:0: [sdb] Attached SCSI removable disk

   The above looks good to me, but I suggest repeating the steps 2-4 again for good measure.

7. Alright, let's make sure the device isn't mounted using `findmnt /dev/sdb`.

   Our output should be null, but if you see something similar to the following:

       TARGET   SOURCE   FSTYPE  OPTIONS
       /mnt/iso /dev/sdb    fat  ro,relatime

   Then use `umount /mnt/iso` to unmount the device.

9. Once the USB device has been unmounted, we can begin to manipulate it using `dd`, `fdisk` (<= 4GB), and `gdisk` (> 4GB) like so:

   Use Case #1: Live USB Boot Media

       dd if=/root/image.iso of=/dev/sdb bs=8M status=progress oflag=direct

   Wait for `dd` to finish writing the image to the device and it is ready to be used as a boot device.

   Use Case #2: Complete USB Wipe

       # Zero data
       dd if=/dev/zero of=/dev/sdb bs=512k

       # Nandom numbers (secure, but takes longer)
       dd if=/dev/urandom of=/dev/sdb bs=512k

   Use Case #3: USB Partition Wipe

         # Backup the first megabyte of raw blocks for easy rollback
         dd if=/dev/${DEVICE} of=/root/diskfile bs=1MB count=1

          # Backup the fstab file as well
          cp /etc/fstab /root/fstab

          # Zeros
          dd if=/dev/zero of=/dev/sdb1 bs=512k

          # Numbers
          dd if=/dev/urandom of=/dev/sdb1 bs=512k

   **Notice** the number `1` after `sdb` (more on that later).

   Use Case #4: Manipulate the attached device partition table via `fdisk /dev/sdb`. For instance, the following describes how to create a FAT32 USB drive.

    Create a new primary partition.

         Command (m for help): n
         Partition type:
            p   primary (0 primary, 0 extended, 4 free)
            e   extended
         Select (default p): p
         Partition number (1-4, default 1): 1
         First sector (2048-62521343, default 2048):
         Using default value 2048
         Last sector, +sectors or +size{K,M,G} (2048-62521343, default 62521343): +4G
         Partition 1 of type Linux and of size 4 GiB is set

    Change the partition type to FAT32.

         Command (m for help): t
         Selected partition 1
         Hex code (type L to list all codes): b

         WARNING: If you have created or modified any DOS 6.xpartitions, please see the fdisk manual page for additionalinformation.

         Changed type of partition 'Linux' to 'W95 FAT32'

    Set active partition used when plugging our device in.

         Command (m for help): a
         Selected partition 1

         Command (m for help): p

         Disk /dev/sdb: 32.0 GB, 32010928128 bytes, 62521344 sectors
         Units = sectors of 1 * 512 = 512 bytes
         Sector size (logical/physical): 512 bytes / 512 bytes
         I/O size (minimum/optimal): 512 bytes / 512 bytes
         Disk label type: dos
         Disk identifier: 0x96bd7628

            Device Boot      Start         End      Blocks   Id  System
         /dev/sdb1   *        2048     8390655     4194304    b  W95 FAT32

    Write the changes made to the master boot record.

         Command (m for help): w
         The partition table has been altered!

         Calling ioctl() to re-read partition table.
         Syncing disks.   

    Create a FAT32 file system.

         mkfs.vfat /dev/sdb1

    Reattach device without removal (laziness).

         eject /dev/sdb1; sleep 1; eject -t /dev/sdb1

    Mount device partition.

         mount /dev/sdb1 /mnt/dvdiso/

# Summary

command line utility, which is available on most Unix-like operating systems, including Linux distributions and OS X, and [has a Windows port available too](http://www.chrysocome.net/dd).


Use the `dd` command to overwrite an installation ISO image directly to the USB device.
