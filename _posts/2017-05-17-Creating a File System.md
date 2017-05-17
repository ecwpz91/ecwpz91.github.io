---
layout: post
title: "Creating a File System"
date: "2017-05-17 00:36"
---
# Problem

The following describes the process of putting a file system on top of a partition with `mkfs` using an installation of RHEL/CentOS.

# Notable

* The Ext3 and Ext4 principle developer stated that BtrFS is the better direction because "it offers improvements in scalability, reliability, and ease of management."
* In 2015, Btrfs was adopted as the default file system for SUSE Linux Enterprise Server 12.
* VFAT is usefule for USB thumb drives and data exchanges with other computers.

# Solution

FILES  |
------ | ------
xfs    | &nbsp;The default file system for RHEL7.
Ext4   | &nbsp;The default file system in previous versions of RHEL (supported in RHEL7).
Ext3   | &nbsp;Prior version of Ext4.
Ext2   | &nbsp;Basic file system created in the 90s.
BtrFS  | &nbsp;File system based on the copy-on-write (COW) principle that is intended to address the lack of pooling, snapshots, checksums, and integral multi-device spanning in Linux file systems.
NTFS   | &nbsp;Not supported in RHEL7.
VFAT   | &nbsp; A file system that offers compatibility with Windows and Mac, it is the functional equivalent of the FAT32 file system.

<br/>
1. Determine your target MBR or GPT partition disk device name.
2. Choose which file system suites your use case.
3. Run the `mkfs` command.

        # Format a partition with the XFS
        mkfs.xfs /dev/${DEVICE}

        OR

        mkfs -t xfs /dev/${DEVICE}

    :information_source: The `-t` option will specify the file system type.

# Summary

As you may already know, a partition by itself is not very useful. It only becomes useful once you decide to do something with it. That usually means putting a file system on top of it.

Also, by default `mkfs` without any specified options will format a device using the Ext2 file system.
