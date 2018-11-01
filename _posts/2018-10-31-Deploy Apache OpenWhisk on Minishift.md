---
layout: "post"
title: "Deploy Apache OpenWhisk on Minishift"
date: "2018-10-31 21:17"
---

# Problem

The following describes the process of deploying Apache OpenWhisk on [Red Hat Container Development Kit](https://developers.redhat.com/products/cdk/overview/) using an installation of RHEL/CentOS.

# Solution

1. Set Up the KVM Driver.

        sudo /bin/bash -c '# Install Docker Machine v0.15.0
                           curl -L 'http://bit.ly/2CPLoyp' -o /usr/local/bin/docker-machine \
                           && chmod +x /usr/local/bin/docker-machine

                           # Install Docker Machine KVM driver for Docker Machine
                           curl -L 'http://bit.ly/2CU65sN' -o /usr/local/bin/docker-machine-driver-kvm \
                           && chmod +x /usr/local/bin/docker-machine-driver-kvm

                           # Install libvirt and qemu-kvm on your system
                           yum install libvirt qemu-kvm

                           # Add yourself to the libvirt group
                           usermod -a -G libvirt $USER

                           # Start the libvirtd service
                           systemctl start libvirtd
                           systemctl enable libvirtd'

2. Install [CDK](https://access.redhat.com/documentation/en-us/red_hat_container_development_kit/3.6/pdf/getting_started_guide/Red_Hat_Container_Development_Kit-3.6-Getting_Started_Guide-en-US.pdf) (minishift).

3. Configure `minishift` with ample resources.

        minishift config set cpus 2
        minishift config set memory 8GB

4. Configure components needed to run `minishift`.

        minishift setup-cdk

5. Start `minishift`.

        minishift start

6. Make the `oc` command available in your PATH.

        eval $(minishift oc-env)

7. Create a new project for [OpenWhisk](https://openwhisk.apache.org).

        oc new-project openwhisk

8. Deploy [OpenWhisk](https://github.com/apache/incubator-openwhisk) in your project using the latest ephemeral template.

        TEMPLATE_PARAMS="INVOKER_MEMORY_REQUEST=512Mi INVOKER_MEMORY_LIMIT=512Mi INVOKER_JAVA_OPTS=-Xmx256m INVOKER_MAX_CONTAINERS=2 COUCHDB_MEMORY_REQUEST=256Mi COUCHDB_MEMORY_LIMIT=256Mi" \
        && oc process -f https://git.io/openwhisk-template $TEMPLATE_PARAMS | oc create -f -

9. Install OpenWhisk CLI ([wsk](https://github.com/apache/incubator-openwhisk-cli/blob/master/README.md)).

        sudo /bin/bash -c 'curl -L 'http://bit.ly/2DdLSPF' | tar -xvzf - -C /bin wsk &>/dev/null'

10. Config `wsk` CLI Authentication

        AUTH_SECRET=$(oc get secret whisk.auth -o yaml | grep "system:" | awk '{print $2}' | base64 --decode) \
        && wsk property set --auth $AUTH_SECRET --apihost $(oc get route/openwhisk --template="{{.spec.host}}")

11. Optionally, install Whisk Deploy ([wskdeploy](https://github.com/apache/incubator-openwhisk-wskdeploy/blob/master/README.md)) to help deploy and manage all your OpenWhisk [Packages](https://github.com/apache/incubator-openwhisk/blob/master/docs/packages.md), [Actions](https://github.com/apache/incubator-openwhisk/blob/master/docs/actions.md), [APIs](https://github.com/apache/incubator-openwhisk/blob/master/docs/rest_api.md), [Triggers and Rules](https://github.com/apache/incubator-openwhisk/blob/master/docs/triggers_rules.md) using a single command.

        sudo /bin/bash -c 'curl -L 'http://bit.ly/2CWlidd' | tar -xvzf - -C /bin wskdeploy &>/dev/null'

12. Verify your OpenWhisk environment.

        wsk --insecure list
        wsk --insecure action invoke /whisk.system/utils/echo --param message hello --blocking

    Note that the `--insecure` option avoids the validation error triggered by the self-signed cert in the nginx service.

13. Check out [Getting started with OpenWhisk](https://github.com/apache/incubator-openwhisk/blob/master/docs/README.md).

# Summary

OpenWhisk is [largely credited to IBM for seeding](https://en.wikipedia.org/wiki/Bluemix). It is an open source implementation of a cloud-first distributed event-based programming service that allows calling of a specific function in response to an event without requiring any resource management from the developer.

Click [here](https://github.com/apache/incubator-openwhisk-external-resources) to see a curated list of awesome OpenWhisk things!
