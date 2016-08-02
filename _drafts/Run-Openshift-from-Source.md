---
layout: post
title: "Build and Run OpenShift from Source"
date: "2016-03-15 16:18"
---

# Objectives
After completing this lab, you should:

- Develop OpenShift locally on your host.

# Prerequisites

Before you start using OpenShift for local development purposes you need to satisfy the following requirements.

Even if these are already installed, it’s probably a good idea to update to the latest version. You can either install it as a package or via another installer, or download the source code and compile it yourself.

1. Install [Git](http://bit.ly/1WQ50nb), a free and open source distributed version control system.

2. Install [Go](http://bit.ly/22iiZZc), an open source programming language designed primarily for systems programming.

  After downloading a binary release suitable for your system, please follow the [installation instructions](http://bit.ly/22iiZZc).

  If you are building from source, follow the [source installation instructions](http://bit.ly/1S2FWr9).

  See the [release history](http://bit.ly/1Val9EJ) for more information about Go releases.

  - **Microsoft Windows** <br/> *Windows XP or later, Intel 64-bit processor* <br/>
    [go1.4.windows-amd64.msi]({{ site.url }}/downloads/go1.4.windows-amd64.msi) (54MB) <br/>
    <sub>SHA256: 6a7d9bd90550ae1e164d7803b3e945dc8309252b</sub>

  - **Apple OS X** <br/> *OS X 10.8 or later, Intel 64-bit processor* <br/>
    [go1.4.darwin-amd64.pkg]({{ site.url }}/downloads/go1.4.darwin-amd64.pkg) (63MB) <br/>
    <sub>SHA256: 2043aaf5c1363e483c6042f8685acd70ec9e41f8</sub>

  - **Linux** <br/> *Linux 2.6.23 or later, Intel 64-bit processor* <br/>
    [go1.4.linux-amd64.tar.gz]({{ site.url }}/downloads/go1.4.linux-amd64.tar.gz) *(63MB)* <br/>
    <sub>SHA256: cd82abcb0734f82f7cf2d576c9528cebdafac4c6</sub>

  - **Source** <br/>
    [go1.4.src.tar.gz]({{ site.url }}/downloads/go1.4.src.tar.gz) *(11MB)* <br/>
    <sub>SHA256: 6a7d9bd90550ae1e164d7803b3e945dc8309252b</sub>

  :exclamation: You must install Go version 1.4 and NOT use $HOME/go directory for Go installation. Also, if you require 32-bit click [here](https://golang.org/dl/).\

3. Verify Your Go Installation (Optional)

  Check that the Go language installation folder is set and exists.

        $ cat /etc/profile.d/go.sh

  [IMAGE]

        $ whereis go

  [IMAGE]

  Or, list the directory contents...

        $ ls /usr/local/go

  [IMAGE]

  Check the Go language version.

        $ go version

  ![Go Version Command]({{ site.url }}/images/2016/03/go-version.png)

4. Create, compile, and run your first Go language application.

  Check that Go is installed correctly by setting up a workspace and building a simple program, as follows.

  Create a directory to contain your [workspace](https://golang.org/doc/code.html#Workspaces), $HOME/workspace/go for example, and set the GOPATH environment variable to point to that location.

        $ export GOPATH=$HOME/workspace/go

  You should put the above command in your shell startup script ($HOME/.bashrc for example). On Windows, follow these [instructions](https://golang.org/doc/install#windows_env) to set the GOPATH environment variable on your system.

  [IMAGE]

  Check that the Go custom workspace environment PATH is set.

        $ env | grep GO

  [IMAGE]

  Next, make the directories src/github.com/user/hello inside your workspace (if you use GitHub, substitute your user name for user), and inside the hello directory create a file named hello.go with the following contents:

        $ cat << EOF > hello.go
          package main

          import "fmt"

          func main() {
            fmt.Printf("hello, world\n")
          }
          EOF

  [IMAGE]

  Then compile it with the go tool:

        $ go install src/github.com/user/hello

  The command above will put an executable command named hello (or hello.exe) inside the bin directory of your workspace. Execute the command to see the greeting:

        $ $GOPATH/bin/hello
        hello, world

  If you see the "hello, world" message then your Go installation is working.

  [IMAGE]

  Before rushing off to write Go code please read the How to Write Go Code document, which describes some essential concepts about using the Go tools.

6. Create a new GOPATH for your tools and install godep:

```sh
export GOPATH=$HOME/go-tools
mkdir -p $GOPATH
go get github.com/tools/godep
```

[IMAGE]

5. Install [Docker](http://bit.ly/1mpoVwk), a  CLI (command line interface) and API (application program interface) for creating and managing containers.

  :exclamation: OpenShift requires Docker 1.8.2 or higher.
  The exact version requirement is documented [here](https://docs.openshift.org/latest/install_config/install/prerequisites.html#installing-docker).

6. Install Etcd

  etcd Version: 2.2.1

# OpenShift Development

To get started, [fork](https://help.github.com/articles/fork-a-repo) the [origin repository](https://github.com/openshift/origin).

#### Here's how to get setup:

1. For Go, Git and optionally also Docker, follow the links below to get to installation information for these tools: +
** [Installing Go]. You must install Go 1.4 and NOT use $HOME/go directory for Go installation.
** http://git-scm.com/book/en/v2/Getting-Started-Installing-Git[Installing Git]
** https://docs.docker.com/installation/[Installing Docker].
+
NOTE:

2. Next, create a Go workspace directory: +
+
----
$ mkdir $HOME/go
----
3. In your `.bashrc` file or `.bash_profile` file, set a GOPATH and update your PATH: +
+
----
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export OS_OUTPUT_GOPATH=1
----
4. Open up a new terminal or source the changes in your current terminal.  Then clone this repo:

        $ mkdir -p $GOPATH/src/github.com/openshift
        $ cd $GOPATH/src/github.com/openshift
        $ git clone git://github.com/<forkid>/origin  # Replace <forkid> with the your github id
        $ cd origin
        $ git remote add upstream git://github.com/openshift/origin

5.  From here, you can generate the OpenShift binaries by running:

        $ make clean build

6.  Next, assuming you have not changed the kubernetes/openshift service subnet configuration from the default value of 172.30.0.0/16, you need to instruct the Docker daemon to trust any Docker registry on the 172.30.0.0/16 subnet.  If you are running Docker as a service via `systemd`, add the `--insecure-registry 172.30.0.0/16` argument to the options value in `/etc/sysconfig/docker` and restart the Docker daemon.  Otherwise, add "--insecure-registry 172.30.0.0/16" to the Docker daemon invocation, eg:

        $ docker -d --insecure-registry 172.30.0.0/16

7.  Then, the OpenShift firewalld rules are also a work in progress. For now it is easiest to disable firewalld altogether:

        $ sudo systemctl stop firewalld

8.  Firewalld will start again on your next reboot, but you can manually restart it with this command when you are done running OpenShift:

        $ sudo systemctl start firewalld

9.  Now change into the directory with the OpenShift binaries, and start the OpenShift server:

        $ cd _output/local/bin/linux/amd64
        $ sudo ./openshift start

+
NOTE: Replace "linux/amd64" with the appropriate value for your platform/architecture.

10.  Launch another terminal, change into the same directory you started OpenShift, and deploy the private docker registry within OpenShift with the following commands (note, the --credentials option allows secure communication between the internal OpenShift Docker registry and the OpenShift server, and the --config option provides your identity (in this case, cluster-admin) to the OpenShift server):

        $ sudo chmod +r openshift.local.config/master/openshift-registry.kubeconfig
        $ sudo chmod +r openshift.local.config/master/admin.kubeconfig
        $ ./oadm registry --create --credentials=openshift.local.config/master/openshift-registry.kubeconfig --config=openshift.local.config/master/admin.kubeconfig

11.  If it is not there already, add the current directory to the $PATH, so you can leverage the OpenShift commands elsewhere.

12.  You are now ready to edit the source, rebuild and restart OpenShift to test your changes.

13.  NOTE:  to properly stop OpenShift and clean up, so that you can start fresh instance of OpenShift, execute:

        $ sudo pkill -x openshift
        $ docker ps | awk 'index($NF,"k8s_")==1 { print $1 }' | xargs -l -r docker stop
        $ mount | grep "openshift.local.volumes" | awk '{ print $3}' | xargs -l -r sudo umount
        $ cd <to the dir you ran openshift start> ; sudo rm -rf openshift.local.*

# Set environment variables

# Create Symbolic Links

  #### Kubernetes shortcuts

    $ ln -s $KUBE_ROOT/cluster/kubectl.sh /usr/bin/kubectl

  #### OpenShift shortcuts

    $ ln -s $OPENSHIFT_CONFIG_ROOT/openshift.local.etcd /var/lib/origin/openshift.local.etcd
    $ ln -s $OPENSHIFT_CONFIG_ROOT/openshift.local.volumes /var/lib/origin/openshift.local.volumes

    $ ln -s $OPENSHIFT_CONFIG_ROOT/openshift.local.config/node-$BINDING_ADDRESS /etc/origin/node
    $ ln -s $OPENSHIFT_CONFIG_ROOT/openshift.local.config/master /etc/origin/master

    $ ln -s $OPENSHIFT_CONFIG_ROOT/openshift /usr/bin/openshift
    $ ln -s $OPENSHIFT_CONFIG_ROOT/oc /usr/bin/oc
    $ ln -s $OPENSHIFT_CONFIG_ROOT/oadm /usr/bin/oadm

# Generate configuration files

      Instantiate Master and Node configuration files.

        $ openshift start --write-config=openshift.local.config \
          --hostname=$BINDING_ADDRESS \
          --public-master=$BINDING_ADDRESS \
          --master=$BINDING_ADDRESS

      Move the SkyDNS server binding to an available port on localhost

        $ vi openshift.local.config/master/master-config.yaml

          </----------------------------------------------------------
            ...
            dnsConfig:
             bindAddress: 127.0.0.1:8053
            ...
          ----------------------------------------------------------/>

      Update routingConfig use provided cloud domain (see http://bit.ly/1P2appl)

        $ vi openshift.local.config/master/master-config.yaml

        </----------------------------------------------------------
          ...
          routingConfig:
            subdomain: apps.iad2.csb
          ...
        ----------------------------------------------------------/>

      Start with local config file to generate Node folder structure

      $ openshift start \
        --master-config=openshift.local.config/master/master-config.yaml \
        --node-config=openshift.local.config/node-$BINDING_ADDRESS/node-config.yaml

      Expose the RO endpoint to unsecured connections

        $ cat >> openshift.local.config/node-$BINDING_ADDRESS/node-config.yaml << DONE
          kubeletArguments:
           read-only-port:
           - "10266"
          DONE

# Setup Source-to-image

#### Dependencies

1. Docker >= 1.6
2. Go >= 1.4
3. (optional) Git

#### Dependencies

Assuming Go and Docker are installed and configured, execute the following commands:

    $ go get github.com/openshift/source-to-image
    $ cd ${GOPATH}/src/github.com/openshift/source-to-image
    $ export PATH=$PATH:${GOPATH}/src/github.com/openshift/source-to-image/_output/local/bin/linux/amd64/
    $ hack/build-go.sh
