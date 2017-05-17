---
layout: post
title: "Creating a LVM Logical Volume"
date: "2017-05-17 00:58"
---

# Problem

The following describes the process of creating the three layers in the LVM architecture using an installation of RHEL/CentOS.

# Notable

* XFS file systems do not allow logical volume size reduction, which is used as the default on RHEL7.
* By default `vgcreate` will automatically flag a physical volume that is doesn't have a type associated with it  (e.g. `8e` for MBR or `8300` for GPT).

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

1. Assign PV to VG.

        vgcreate ${VG_NAME} /dev/${DEVICE}

2. Verify the VG.

        # Listing
        vgs

        # Summary
        vgdisplay

### Physical Extent (PE)

When creating a VG, a PE size is used. The PE size defines the size of the building blocks used to create logical volumes.

By default, the extent size is 4MiB. Also, the PE size is **always** specified as a multiple of 2MiB, with a maximum size of 128 MiB. Use the `-s` option to specify the PE size.

### Logical Extent (LE)

When working with an Ext4 file system, a LE size is used. The LE size defines the size of the building blocks used to create logical volumes.

:information_source: The extent size on LVM are in no way related to the extent sizes that are used on the file systems.

## Layer 3: Logical Volume (LV)

  1. Assign LV to VG.

          # Absolue size
          lvcreate -n ${LV_NAME} -L 100M ${VG_NAME}

          # Relative size
          lvcreate -n ${LV_NAME} -l 50% FREE ${VG_NAME}

2. Verify the LV.

          # Listing
          lvs

          # Summary
          lvdisplay

3. Create a file system on top of the LV.

          mkfs.xfs /dev/${VG_NAME}/${LV_NAME}

# Summary

The idea is simple:
1. If you are running out of disk space on a LV, take available from the VG.
2. If there isn't disk space available in the VG, add a PV.

[1]: https://ecwpz91.github.io/2017/05/16/Creating-a-Master-Boot-Record-Partition.html
[2]: https://ecwpz91.github.io/2017/05/16/Creating-a-GUID-Partition-Table-Partition.html
