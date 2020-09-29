---
layout: "post"
title: "Building Dashbuilder using Podman"
date: "2020-09-29 05:56"
---

# Problem

The following describes the process of deploying [Dashbuilder](https://github.com/kiegroup/appformer/tree/master/dashbuilder) onto [Widlfly](https://www.wildfly.org/) via [Podman](https://podman.io/) using an installation of Fedora 31.

# Solution

Use Podman to quickly build and deploy Dashbuilder onto Wildfly.

1. Open a terminal and type the command `su -` to login as root user.
2. Get the most current version of all packages and podman.

        sudo dnf clean all
        sudo rm -rf /var/cache/dnf/*
        sudo dnf makecache fast
        sudo dnf update -y
        sudo dnf autoremove -y
        sudo dnf install -y slirp4netns podman

3. To increase the number of user namespaces in the kernel, type the following:

        sudo echo "user.max_user_namespaces=28633" > /etc/sysctl.d/userns.conf
        sudo sysctl -p /etc/sysctl.d/userns.conf

    Note that the user you're logged in as is automatically configured to be able to use rootless podman.

4. Check which version of Java is installed.

        java -version

    Note WildFly 19 is heavily tested and runs well on Java 8.

5. Dashbuilder requires Maven 3.6.3 (or greater). At the time of this post, this release of Maven is not yet provided by the default package manager repositories and therefore I need to install and add to the environment PATH manually. For your convenience you can source the following custom bash script and issue the command `install-maven` to automate the installation process, or use this [Ansible Galaxy role](https://github.com/gantsign/ansible-role-maven) too.

       #!/bin/bash
       install-maven() {
         [[ ! -d "$HOME/.local/share/maven" ]] && mkdir -p "$HOME/.local/share/maven"

         curl -L 'https://mirrors.gigenet.com/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz' \
         | tar -xzf - -C "$HOME/.local/share/maven" --strip 1

         ln -s "$HOME/.local/share/maven/bin/mvn" "$HOME/.local/bin/mvn"
       }

    Note that my [.bashrc](https://tldp.org/LDP/abs/html/sample-bashrc.html) file contains the uer specific environment variable `PATH="$HOME/.local/bin:$HOME/bin:$PATH"` to load the local bin folder for binary files maintained outside of the native OS package manager. You can verify that `mvn` is loaded from this path by reloading the interactive shell environment (restarting the terminal) and typing the command `which mvn`. Also, you can find other mvn paths (check if installed globally) using the command `whereis mvn` to determine all locations of Maven.

6. Check which version of Maven is installed.

        mvn -version

5. Download the Dashbuilder builder source code.

       curl -L 'https://github.com/kiegroup/appformer/archive/7.43.1.Final.tar.gz' \
       | tar -xzf - -C "$HOME/Downloads" appformer-7.43.1.Final/dashbuilder --strip 1

       
6. Change directory to location of downloaded Dashbuilder source code.

        cd $HOME/Downloads/dashbuilder

7. Package the source code as a WAR file using maven.

       mvn clean install -DskipTests -Dfull

    Once build is finished, you'll find the WAR distributions for Wildfly in `dashbuilder-distros/target/dashbuilder-1.0.0.Final-wildfly10.war`.

8. Create the local Containerfile to build containers and define reproducible image recipes.

        # Create file named `Containerfile` with the following contents:
        FROM jboss/wildfly:19.1.0.Final
        ADD dashbuilder-distros/target/dashbuilder-7.43.1.Final-wildfly10.war /opt/jboss/wildfly/standalone/deployments/
        CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]

5. Use `podman` to build an image using local Containerfile.

       podman build -t dashbuilder -f Containerfile .

6. Run image locally and boot in standalone mode with admin console available remotely.

       podman run --publish 8080:8080 --publish 9990:9990 -detach --name dashbuilder localhost/dashbuilder sh -c '/opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0'

7. Create an create a management user in the Default Realm for the management console at http://localhost:9990.

       podman exec -it dashbuilder /opt/jboss/wildfly/bin/add-user.sh -u 'adminuser' -p 'password1'

8. Create an Application user belonging to a single group:

       podman exec -it dashbuilder /opt/jboss/wildfly/bin/add-user.sh -a -u 'appuser1' -p 'password1!' -g 'admin'

9. Once application started, navigate to:

       http://localhost:8080/dashbuilder-7.43.1.Final-wildfly10

    Note use the Application user created in Step #8 to login to Dashboard Builder.

# Summary

This post was inspired by the [KieLive#8 Authoring Dashboards in Business Central](https://www.youtube.com/watch?v=5r6twEgspIM) video blog posting.

Dashbuilder is a general purpose dashboard and reporting web app which allows for:

* Visual configuration and personalization of dashboards
* Support for different types of visualizations using several charting libraries
* Full featured editor for the definition of chart visualizations
* Definition of interactive report tables
* Data extraction from external systems, through different protocols
* Support for both analytics and real-time dashboards

Check out the link to the video above where you go through the process of uploading and creating some really cool dashboards.

Thanks, and remember Knowledge is Everything (KIE)!
