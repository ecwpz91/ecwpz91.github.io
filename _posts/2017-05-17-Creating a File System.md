---
layout: post
title: "Creating a File System"
date: "2017-05-17 00:36"
---
# Problem

The following describes the process of putting a file system on top of a partition with `mkfs` using an installation of RHEL/CentOS.

# Notable

* Ext3/4 principle developer stated that BtrFS is the better direction because it offers improvements in scalability, reliability, and ease of management.
* VFAT is useful for USB thumb drives and data exchanges with other computers, e.g. Mac and Windows.
* By default `mkfs` without any specified options will format a device using the Ext2 file system.

# Solution

FILES  |
------ | ------
xfs    | &nbsp;The default file system for RHEL7.
Ext4   | &nbsp;The default file system in previous versions of RHEL (supported in RHEL7).
Ext3   | &nbsp;Prior version of Ext4.
Ext2   | &nbsp;Basic file system created in the 90s.
BtrFS  | &nbsp;File system based on the copy-on-write (COW) principle.
NTFS   | &nbsp;Not supported in RHEL7.
VFAT   | &nbsp;File system that is the functional equivalent of FAT32.

<br/>
1. Create either a [MBR][1] or [GPT][2] partition.
2. Choose which file system suites your use case.
3. Run the `mkfs` command.

        # Format a partition with the XFS
        mkfs.xfs /dev/${DEVICE}

        OR

        mkfs -t xfs /dev/${DEVICE}

    :information_source: The `-t` option will specify the file system type.

# Summary

As you may already know, a partition by itself is not very useful. It only becomes useful once you decide to do something with it. That usually means putting a file system on top of it!

[1]: https://ecwpz91.github.io/2017/05/16/Creating-a-Master-Boot-Record-Partition.html
[2]: https://ecwpz91.github.io/2017/05/16/Creating-a-GUID-Partition-Table-Partition.html
