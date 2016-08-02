---
layout: post
title: "Installing ASP.NET 5 on RHEL"
date: "2016-03-15 16:16"
---

# Objectives
After completing this lab, you should be able to:

- Install ASP.NET 5 on RHEL7

# Prerequisites

1. Install/enable the [epel-release](http://bit.ly/1uKFUHt) package.

        # Install Extra Packages for Enterprise Linux (EPEL).
        $ curl -sLO https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        $ sudo yum -y install epel-release-latest-7.noarch.rpm

    Or (if previously installed)

        # Set 'enabled=1'
        $ sudo vi /etc/yum.repos.d/epel.repo

2. Install/enable the [mono-complete](http://bit.ly/1PK1Q1q) package.

        # Add the Mono Project GPG signing key
        $ sudo rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"

        # Add the package repository
        $ sudo yum-config-manager --add-repo http://download.mono-project.com/repo/centos/

    Or (if previously installed)

        # Set 'enabled=1'
        $ sudo vi /etc/yum.repos.d/download.mono-project.com_repo_centos_.repo

3. Install the latest [Mozilla CA root certificate bundle](https://rpmfind.net/linux/rpm2html/search.php?query=ca-certificates).

4. Update the system packages to reflect changes.

        $ sudo yum clean all && sudo yum -y update

# Install .NET Version Manager (DNVM)

Use the DNVM to install different versions of the .NET Execution Environment (DNX) on Linux.

1. Download and install DNVM.

2. Verify the installation.

        $ dnvm

    ![DNVM Help Text]({{ site.url }}/images/2016/02/dnvm.png)

# Install the .NET Execution Environment (DNX)

The .NET Execution Environment (DNX) is used to build and run .NET projects. Use DNVM to install DNX for Mono (see Choosing the Right .NET For You on the Server).

:information_source: DNX support for .NET Core is not available for CentOS, Fedora and derivative in this release, but will be enabled in a future release.

**To install DNX for Mono:**

3. Install [Mono](http://bit.ly/1zNxyES), the open source .NET framework.

    The mono-devel package enables code compilation.

        $ sudo yum -y install mono-devel

    The mono-complete package installs everything (recommend).

        $ sudo yum -y install mono-complete

    The referenceassemblies-pcl package installs PCL compilation. support

        $ sudo yum -y install referenceassemblies-pcl

    The ca-certificates-mono package installs SSL certificates for HTTPS connections.

        $ sudo yum -y install ca-certificates-mono

:information_source: Some systems are configured in a way so that the necessary package isn’t pulled in when Mono is installed, in those cases **make sure the `ca-certificates-mono` package is installed**. See the Mono installation [notes](http://bit.ly/1PJYMCt) for further details.

# Install DNX for Mono:

    $ dnvm upgrade -r mono

  :information_source: By default DNVM will install DNX for Mono if no runtime is specified.

# Install Libuv

[Libuv](http://bit.ly/1TtGNUC) is a multi-platform asynchronous IO library that is used by [Kestrel](http://bit.ly/1PJSWkF), a cross-platform HTTP server for hosting ASP.NET 5 web applications.

    $ sudo yum -y install automake libtool wget
    $ tar -zxf libuv-v1.8.0.tar.gz
    $ cd libuv-v1.8.0
    $ sudo sh autogen.sh && sudo ./configure
    $ sudo make && sudo make check
    $ sudo make install
    $ sudo ln -s /usr/lib64/libdl.so.2 /usr/lib64/libdl
    $ sudo ln -s /usr/local/lib/libuv.so.1.0.0 /usr/lib64/libuv.so

:information_source: `libuv.so` may already be linked, which is **OK**.

# Resources
- http://bit.ly/1Oj1BX9

# Manage containers with the OpenShift Web-Terminal

**docker pull**: Download an image from a registry, making it available to the local Docker daemon.

    $ sudo docker pull microsoft/dotnet

![Docker 'pull' Command]({{ site.url }}/images/2016/02/docker-pull.png)

**docker images**: List images available from the local Docker daemon.

    $ sudo docker images

![Docker 'images' Command]({{ site.url }}/images/2016/02/docker-images.png)

# Building images with Dockerfiles
