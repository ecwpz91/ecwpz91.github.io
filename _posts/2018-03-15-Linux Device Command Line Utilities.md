---
layout: post
title: "Linux Device Command Line Utilities"
date: "2018-03-15 14:45"
---

# Problem

The following describes some command line utilities encountered when dealing with USB devices on an installation of RHEL/CentOS.

# Solution

1. Open a terminal and type the command `su -` to login as root user.
2. Type the command `df -HT` to get the list of attached mount points.

       Filesystem            Type     Size Used Avail Use% Mounted on
       /dev/mapper/rhel-root xfs      xxxG xxxG   xxG   x% /
       devtmpfs              devtmpfs  xxG    x   xxG   x% /dev
       tmpfs                 tmpfs     xxG    x   xxG   x% /dev/shm
       tmpfs                 tmpfs     xxG xxxM   xxG   x% /run
       tmpfs                 tmpfs     xxG    x   xxG   x% /sys/fs/cgroup
       /dev/sda1             xfs      xxxG xxxM  xxxM  xx% /boot
       /dev/mapper/rhel-home xfs      xxxG  xxM  xxxG  xx% /home
       tmpfs                 tmpfs    xxxG    x  xxxG   x% /run/user/0
       tmpfs                 tmpfs    xxxG    x  xxxG   x% /run/user/543218

3. Type the command `lsblk -f` to get the list of attached block devices.

       NAME          FSTYPE      LABEL UUID                    MOUNTPOINT
       sda
       ├─sda1        xfs               xxx-xxx-xxx-xxx-xxx-xxx /boot
       └─sda2        LVM2_member       xxx-xxx-xxx-xxx-xxx-xxx
         ├─rhel-root xfs               xxx-xxx-xxx-xxx-xxx-xxx /
         ├─rhel-swap swap              xxx-xxx-xxx-xxx-xxx-xxx [SWAP]
         └─rhel-home xfs               xxx-xxx-xxx-xxx-xxx-xxx /home

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

8. Type the command `umount TARGET` to unmount the target (e.g. `unmount /mnt/iso`) filesystem.
9. Use the `dd` command to format the USB stick by copying zeros, random numbers (secure, but takes longer), or a file to the target file system.

         # Zeros, zilch, or null
         dd if=/dev/zero of=/dev/sdb bs=512k

         # Randomized numbers
         dd if=/dev/urandom of=/dev/sdb bs=512k

         # Copying a file (USB boot media)
         dd if=/root/image.iso of=/dev/sdb bs=8M status=progress oflag=direct

10. Type the command `fdisk SOURCE` (<=4GB) or `gdisk SOURCE` (>4GB) to begin manipulating the device disk partition table. The following describes how to create a 4GB USB stick with a FAT32 filesystem after wiping the device with zero data.

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

    Either reboot, or use the following command to write the changes to the kernel.

         partprobe

    Create a FAT32 file system on our new primary partition.

         yum -y install dosfstools
         mkfs.vfat /dev/sdb1

    Reattach device without removal.

         eject /dev/sdb1; sleep 1; eject -t /dev/sdb1

    Mount device partition.

         mount /dev/sdb1 /mnt/dvdiso/

    Unmount the device.

         umount /dev/sdb

    Backup the first megabyte of raw blocks of the device.

         dd if=/dev/sdb of=/root/diskfile bs=1MB count=1

    Backup the static information about the filesystems.

         cp /etc/fstab /root/fstab

# Summary

While many Linux distros have tools like liveusb-creator on Fedora, I prefer the above tools due to cross-platform compatibility reasons.

For instance, the `dd` command line utility, is available on most Unix-like operating systems including Linux distributions and OS X, and [has a Windows port available too][2].

Also, both Unix/Linux systems use a similar device naming scheme for disk drives. That is, [`/dev/`][3] directory is the location of special or device files, `sd` identifies a device that can store data, `b`, the letter immediately after `/dev/sd` signifies the order in which it was first found (e.g. `sda`,`sdb` ... `sdAa`), and `1`, the number after `/dev/sdb` identifies the partition on the device, so `/dev/sda2` would mean the second partition on the first device

Shout out to this [TL;DR][4] on explaining how this naming convention came about. Thanks!

Anyways, if you're looking for more information on partitions and filesystems in general check out my past posts on [Creating a Master Boot Record (MBR) Partition][5], [Creating a GUID Partition Table (GPT) Partition][6], and [Creating a File System][7].

[1]: https://fedoraproject.org/wiki/How_to_create_and_use_Live_USB#Command_line_.22direct_write.22_method_.28most_operating_systems.2C_non-graphical.2C_destructive.29
[2]: http://www.chrysocome.net/dd
[3]: http://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s06.html
[4]: https://superuser.com/questions/558156/what-does-dev-sda-for-linux-mean?answertab=votes#tab-top
[5]: https://ecwpz91.github.io/2017/05/16/Creating-a-Master-Boot-Record-Partition.html
[6]: https://ecwpz91.github.io/2017/05/16/Creating-a-GUID-Partition-Table-Partition.html
[7]: https://ecwpz91.github.io/2017/05/17/Creating-a-File-System.html
