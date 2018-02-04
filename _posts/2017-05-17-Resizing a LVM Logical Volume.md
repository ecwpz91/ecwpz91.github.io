---
layout: post
title: "Resizing a LVM Logical Volume"
date: "2017-05-17 10:01"
---

# Problem

The following describes the process of resizing a logical volume using an installation of RHEL/CentOS.

# Notable

* If the XFS file system is used, a volume can be increased, but not decreased, in size.
* Decreasing an Ext4 file system can be done offline only, which means that you need to unmount it before you can resize it.
  * When resizing a LV with the file system it contains, nothing will happen to the file system, and its data will remain intact.
  * Most file system resizing operations can be done online, without any need to unmount the file system.

# Solution

## Layer 1: Physical Volume (PV)

1. Create a [MBR][1] or [GPT][2] partition.
2. Assign partition to PV.

        pvcreate /dev/${DEVICE}

3. Verify the PV.

        # Listing
        pvs

        # Summary
        pvdisplay

        # Hierarchical
        lsblk

## Layer 2: Volume Group (VG)

1. Change the size of the VG.

        # Increase
        vgextend ${VG_NAME} /dev/${DEVICE}

        # Reduce
        vgreduce ${VG_NAME} /dev/${DEVICE}

2.  Verify the VG.

        # Listing
        vgs

        # Summary
        vgdisplay

## Layer 3: Logical Volume (LV)

1. Change the size of the LV.

        # Increase relative size
        lvextend -r -l +50%FREE /dev/${VG_NAME}/${LV_NAME}

        # Decrease absolute size
        lvreduce -r -L -150M /dev/${VG_NAME}/${LV_NAME}

2. Verify the LV.

        # Listing
        lvs

        # Summary
        lvdisplay

        # Filesystem
        df -h

3. Create a file system on top of the LV.

        mkfs.xfs /dev/${VG_NAME}/${LV_NAME}

# Summary

The main part of LVM flexibility resides in how easy it is to resize a VG and LV backed by a PV.

[1]: https://ecwpz91.github.io/2017/05/16/Creating-a-Master-Boot-Record-Partition.html
[2]: https://ecwpz91.github.io/2017/05/16/Creating-a-GUID-Partition-Table-Partition.html
