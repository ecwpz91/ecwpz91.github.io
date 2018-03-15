---
layout: post
title: "USB Stick Command Line Utilities"
date: "2018-03-06 16:15"
---

# Problem

The following describes some command line utilities encountered when dealing with USB devices on an installation of Fedora/RHEL/CentOS.

# Solution

1. Open a terminal and type the command `su -` to login as root user.
2. Type the command `df -HT` to get the list of attached mount points.

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

3. Type the command `lsblk -f` to get the list of attached block devices.

       NAME          FSTYPE      LABEL UUID                      MOUNTPOINT
       sda
       ├─sda1        xfs               xxx-xxx-xxx-xxx-xxx-xxx   /boot
       └─sda2        LVM2_member       xxx-xxx-xxx-xxx-xxx-xxx
         ├─rhel-root xfs               xxx-xxx-xxx-xxx-xxx-xxx   /
         ├─rhel-swap swap              xxx-xxx-xxx-xxx-xxx-xxx   [SWAP]
         └─rhel-home xfs               xxx-xxx-xxx-xxx-xxx-xxx   /home

4. Type the command `fdisk -l` to get list of attached disk partitions.

       Disk /dev/sda: xxx GB, xxx bytes, xxx sectors
       Units = sectors of 1 * 512 = 512 bytes
       Sector size (logical/physical): 512 bytes / 512 bytes
       I/O size (minimum/optimal): 512 bytes / 512 bytes
       Disk label type: dos
       Disk identifier: 0x0006f012

       Device Boot      Start         End      Blocks   Id  System
       /dev/sda1   *      xxx         xxx         xxx   83  Linux
       /dev/sda2          xxx         xxx         xxx   8e  Linux LVM

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

5. Plug in a USB stick.
6. Type the command `dmesg | tail -20` to any issues with attaching the device.

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

7. Type the command `findmnt /dev/sdb` to see if the device is mounted or not. Expected output is either nothing if the device is not mounted, or similar to the following output if the device is mounted.

       TARGET   SOURCE   FSTYPE  OPTIONS
       /mnt/iso /dev/sdb    fat  ro,relatime

   **Please note the `TARGET` and `SOURCE` column if the device is mounted.**

8. Type the command `umount TARGET` to unmount the device (e.g. `umount /dev/sdb`).
9. Type the command `dd if=/dev/${DEVICE} of=/root/diskfile bs=1MB count=1` to backup the first megabyte of raw blocks of the device for easy rollback.
10. Type the command `cp /etc/fstab /root/fstab` to backup the static information about the filesystems before manipulating the device disk partition table.
11. Type the command `fdisk SOURCE` (<=4GB) or `gdisk SOURCE` (>4GB) to begin manipulating the device disk partition table. For example, the following describes formatting a 4GB USB stick with FAT32:

   Format the USB stick by copying zero or random number (secure, but takes longer) data to the target file system.

         # Zeros, zilch, or null
         dd if=/dev/zero of=/dev/sdb bs=512k

         # Randomized numbers
         dd if=/dev/urandom of=/dev/sdb bs=512k

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

    Reattach device without removal.

         eject /dev/sdb1; sleep 1; eject -t /dev/sdb1

    Mount device partition.

         mount /dev/sdb1 /mnt/dvdiso/

8. Copy a file (from standard input to standard output, by default) with a changeable I/O block size, while optionally performing conversions on it.

       # Example of creating a USB boot media
       dd if=/root/image.iso of=/dev/sdb bs=8M status=progress oflag=direct

# Summary

It has to do with the way linux (and all unixes) name their drives, much in the way that windows uses C:, D:, etc. (NOTE: This is what we call a metaphor. In other words, a blatant lie that helps people understand without being even remotely accurate. Read on for a more detailed explanation...)

/dev/ is the part in the unix directory tree that contains all "device" files -- unix traditionally treats just about everything you can access as a file to read from or write to.
sd originally identified a SCSI device, but since the wildgrowth of USB (and other removable) data carriers it became a catch-all for any block device (another unix term; in this context, anything capable of carrying data) that wasn't already accessible via IDE. When SATA came around, the developers figured it'd be much easier and much more convenient for everyone to add it into the existing framework rather than write a whole new framework.
The letter immediately after sd signifies the order in which it was first found -- a,b,c...z, Aa...Az... etc. (Not that there are many situations in the real world where more than 26 discrete block devices are on the same bus...)
Finally, the number after that signifies the partition on the device. Note that because of the rather haphazard way PCs handle partitioning there are only four "primary" partitions, so the numbering will be slightly off from the actual count. This isn't a terrible problem as the main purpose for the naming scheme is to have a unique and recognizable identifier for each partition found in this manner...
So /dev/sda9 means the ninth partition on the first drive.

command line utility, which is available on most Unix-like operating systems, including Linux distributions and OS X, and [has a Windows port available too][2].


Use the `dd` command to overwrite an installation ISO image directly to the USB device.


[1]: https://fedoraproject.org/wiki/How_to_create_and_use_Live_USB#Command_line_.22direct_write.22_method_.28most_operating_systems.2C_non-graphical.2C_destructive.29
[2]: http://www.chrysocome.net/dd
