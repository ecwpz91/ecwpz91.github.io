---
layout: "post"
title: "Getting Started with Quay Container Registry and Buildah"
date: "2018-08-20 14:00"
---

# Problem

The following describes the process of trying out Quay Container Registry and Buildah using an installation of RHEL/CentOS.

# Solution

1. The first step is to install the dependencies for Buildah.

    **[IMPORTANT]** To run Buildah on Red Hat Enterprise Linux or CentOS, version 7.4 or higher is required.

        yum -y install make \
                       golang \
                       bats \
                       btrfs-progs-devel \
                       device-mapper-devel \
                       glib2-devel \
                       gpgme-devel \
                       libassuan-devel \
                       libseccomp-devel \
                       ostree-devel \
                       git \
                       bzip2 \
                       golang-github-cpuguy83-go-md2man \
                       runc \
                       skopeo-containers

2. Install the latest `golang` locally.

    On RHEL 7.4, I was unable to `make` Buildah using `go version go1.3.3 linux/amd64`, so I prioritized `~/.local/bin` over `/usr/bin`.

    First, install Golang outside of 'yum' package manager.

        $ curl -L 'https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz' | tar -xvzf - -C $HOME/.local --strip 1 &>/dev/null

    Then setup the environment to [manage projects and public packages independently](https://www.ardanlabs.com/blog/2013/08/organizing-code-to-support-go-get.html).

        $ cat <<EOF >>~/.bashrc
        export GOROOT=$HOME/.local
        export GOPATH=$HOME/.go/Projects
        export GOPATH=$HOME/.go/PublicPackages:$GOPATH
        export GOBIN=$HOME/.local/bin
        export PATH=$GOROOT/bin:$PATH
        # export GOMAXPROCS='1'
        EOF

3. Optionally, [add support for uninstalling custom go packages via shell script](http://akzcool.blogspot.com/2018/06/bash-how-to-uninstall-custom-go-package.html).

    Thanks to Abhishek Kumar for providing enhancement and credit for my [original script](https://stackoverflow.com/questions/13792254/removing-packages-installed-with-go-get#answer-50069549).

4. Prefer to use upstream `go-md2man` (source of Buildah issues mentioned in Step 2).

        $ go get github.com/cpuguy83/go-md2man

6. [Install Buildah](https://github.com/projectatomic/buildah/blob/master/install.md#rhel-centos)

        $ mkdir ~/buildah
        $ cd ~/buildah
        $ export GOPATH=`pwd`
        $ git clone https://github.com/projectatomic/buildah ./src/github.com/projectatomic/buildah
        $ cd ./src/github.com/projectatomic/buildah
        $ make
        $ sudo make install
        $ buildah --help

7. Create a [Quay.io](https://quay.io/) user account

    In order to be able to log into Quay Container Registry using the Docker CLI you need to create a user account first.

    I did this by using my [GitHub account to sign in](https://quay.io/signin/) and then reset my password because when I tried to create a new account I never received an email.

    ¯\\_(ツ)_/¯

8. Create a Docker CLI Password

    Go to your Quay account settings page and create an encrypted password for more security.

9. Sign into Quay.io

    To sign into Quay.io, execute the docker login quay.io command:

        $ docker login quay.io
        Username: myusername
        Password: myencryptedpassword

10. Create a new container

    First we’ll create a container with a single new file based off of the CentOS base image:

        # ctr1=`buildah from ${1:-docker.io/centos}`
        # buildah run $ctr1 -- /bin/bash -c 'echo "Hello Buildah!" >> /tmp/newfile'

11. Use `buildah containers` to list running containers:

        CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME
        71d3440c6064     *     5182e96772bf docker.io/library/centos:latest  centos-working-container

    Make note of the **container id**; we’ll need it for the commit command.

12. Tag the container to an image

    We next need to tag the container to a known image name

    Note that the username must be your Quay.io username and reponame is the new name of your repository.

        # buildah commit 71d3440c6064 quay.io/myusername/echofun
        Getting image source signatures
        Skipping fetch of repeat blob sha256:1d31b5806ba40b5f67bde96f18a181668348934a44c9253b420d5f04cfb4e37a
        Copying blob sha256:0d8fede6b2c6d05d95edc1c5d0b8dba4e6c7e31628e0a8dfb4eb419f3d05cdf4
         161 B / 161 B [============================================================] 0s
        Copying config sha256:ae853012674b8421cd3155a29a5e28c01660c3eff1309309ba3f23d973006a4c
         1.18 KiB / 1.18 KiB [======================================================] 0s
        Writing manifest to image destination
        Storing signatures
        ae853012674b8421cd3155a29a5e28c01660c3eff1309309ba3f23d973006a4c

13. Get the image ID

        # buildah images
        IMAGE ID             IMAGE NAME                                               CREATED AT             SIZE
        5182e96772bf         docker.io/library/centos:latest                          Aug 6, 2018 15:21      208 MB
        ae853012674b         quay.io/myusername/echofun:latest                           Aug 20, 2018 15:10     208 MB

14. Push the image to Quay.io

        # buildah push --authfile /home/username/.docker/config.json ae853012674b docker://quay.io/myusername/echofun:latest
        Getting image source signatures
        Copying blob sha256:1d31b5806ba40b5f67bde96f18a181668348934a44c9253b420d5f04cfb4e37a
         198.64 MiB / 198.64 MiB [=================================================] 15s
        Copying blob sha256:07ed723f8db4953eb6c86d436d3a5e411b5adf572215e791bfad0f3b2030a33a
         3.00 KiB / 3.00 KiB [======================================================] 0s
        Copying config sha256:ae853012674b8421cd3155a29a5e28c01660c3eff1309309ba3f23d973006a4c
         1.18 KiB / 1.18 KiB [======================================================] 1s
        Writing manifest to image destination
        Copying config sha256:ae853012674b8421cd3155a29a5e28c01660c3eff1309309ba3f23d973006a4c
         0 B / 1.18 KiB [-----------------------------------------------------------] 0s
        Writing manifest to image destination
        Writing manifest to image destination
        Storing signatures

15. Pull the image from Quay.io using Docker

    A docker pull could be used to update the repository locally

        $ docker pull quay.io/myusername/echofun

16. Run the image locally in order to verify the the `/tmp/newfile` exists

        $ docker run -detach --name echofun quay.io/myusername/echofun sh -c 'while true; do sleep 1000; done'
        $ docker exec -it echofun /bin/bash
        [root@c6328f332102 /]# cat /tmp/newfile
        Hello Buildah!
        [root@c6328f332102 /]#

# Summary

The purpose of this tutorial is to demonstrate how Buildah can be used to build container images compliant with the Open Container Initiative (OCI) image specification, checked into a remote registry, and run locally using the Docker daemon.

Buildah is a tool that facilitates building OCI container images and I suggest checking out [Dan Walsh: Latest Container Technologies](https://www.youtube.com/watch?v=I0cOn1psf5o), as well as [Getting Started with Buildah](https://www.projectatomic.io/blog/2017/11/getting-started-with-buildah/).

Whereas, Quay provides a market leading enterprise container registry solution, available as both software and hosted service, usable standalone or with OpenShift, fully supported by Red Hat.

Also, the inspiration for this post was [Getting Started with Quay.io](https://docs.quay.io/solution/getting-started.html) and you could even use the[ Red Hat Container Development Kit](https://developers.redhat.com/products/cdk/overview/)'s `minishift ssh` command to perform the step above if you do not have docker locally installed and need an all-in-one pre-built container development environment.

That's all for now, and I hope this helps you get started with some of the latest container tech!
