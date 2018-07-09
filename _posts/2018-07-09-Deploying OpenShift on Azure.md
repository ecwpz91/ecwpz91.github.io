---
layout: "post"
title: "Deploying OpenShift on Azure"
date: "2018-07-09 5:56"
---

# Problem

The following describes some lessons learned when trying out [Red Hat OpenShift Container Platform on Microsoft Azure](https://access.redhat.com/documentation/en-us/reference_architectures/2018/html-single/deploying_and_managing_openshift_3.9_on_azure/) using an installation of RHEL/CentOS.

# Solution

Here are a few things you should consider prior to trying it out yourself.

1. [Azure free account](https://azure.microsoft.com/en-us/free/)

    Requires a valid credit card to sign register - gift cards not accepted #wompwomp

    Also, [free trial subscriptions are not eligible for limit or quota increases](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-quota-errors).

2. Create a resource group

    See post on [not able to set same name for Azure key Vault in different subscription](https://stackoverflow.com/questions/37563126/not-able-to-set-same-name-for-azure-key-vault-in-different-subscription).

    The solution in my case was to register a missing resource provider, like so:

         az provider register --namespace Microsoft.KeyVault

3. [Create a service principal](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/openshift-prerequisites#create-a-service-principal)

    Role assignment creation failed because the original scopes `az group show --name keyvaultrg --query id` command includes quotation marks.

    Also, there is no need to include the `--password` parameter if this is the first time you’re provisioning. As in, Azure will auto generate the password for you.

    This is the command I used on an installation of RHEL/CentOS:

         az ad sp create-for-rbac --name openshift --role contributor --scopes $(az group show --name keyvaultrg --query id | sed -e 's/\"\(.*\)\"/\1/')

4. [Missing authorization to perform action](https://blogs.msdn.microsoft.com/azure4fun/2016/10/20/common-problem-when-using-azure-resource-groups-rbac/)

    I needed fix RBAC by adding `Microsoft.Resources/subscriptions/resourcegroups/read` to my account.

5. Consider using a tool to generate Azure ARM templates

    The JSON templates provided out-of-the-box by Microsoft deploy 1x bastion, 3x master, 3x infra, 3x app nodes.

    But, for purposes of a small proof-of-concept (POC) environment I needed something a little smaller. So I began hacking away _manually_.

    Hindsight is 20/20, and if you are an OpenShift guru, but not an Azure expert... Expect to find post- deployment issues with things like storage provisioning.

    For instance, I didn't understand the different Azure storage tiers, and when I tried to deploy OpenShift and afterwards the pods backed by persistent storage it'll failed since `Premium_LRS` is not supported for [VM size](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general) `Basic_A2`. Basically, I needed to deploy nodes that support premo storage - doh.

    The point is, I could have saved myself some time if I had either broken the ARM template into multiple small subsections that got assembled post- modification, or Googled for a tool that I could use to update the template and redeploy from afterwards.

# Summary

Let me start by saying I've found the experience of deploying [OpenShift on Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/openshift-get-started) to be quite pleasurable.

But, in order to reduce the recommended deployment to a OCP proof-of-concept architecture I had to do some significant hacking when dealing with the Microsoft ARM templates.

So, if you don't mind troubleshooting, or have some time on your hands... Please consider making a contribution to my [github project](https://github.com/ecwpz91/openshift-arm-setup), which is a result of the effort described above.
