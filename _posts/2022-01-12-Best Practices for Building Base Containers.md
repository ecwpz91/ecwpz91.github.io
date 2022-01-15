---
layout: "post"
title: "Best Practices for Building Base Containers"
date: "2022-01-12 02:13"
---

# Problem

I've gone through the process of building base containers several times and wanted to provide others guidance as to what I remind myself when starting out. 

# Solution

So, here are my commandments:

1. Don’t build from scratch
  * [Red Hat Container Images](https://catalog.redhat.com/software/containers/explore)
  * [Red Hat Universal Base Image](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) & [UBI FAQ](https://developers.redhat.com/articles/ubi-faq)
  * [OpenShift base images](https://github.com/sclorg/s2i-base-container)
  * [Common helper script](https://github.com/sclorg/container-common-scripts)

2. Avoid running as root
* [Unknown user when running Docker container](http://blog.dscpl.com.au/2015/12/unknown-user-when-running-docker.html)
* [OpenShift Container Platform-specific guidelines](https://docs.openshift.com/container-platform/4.9/openshift_images/create-images.html)

3. Package a single app per container

4. Properly handle PID 1, signal handling, and zombie processes

5. Optimize for the Docker build cache
* Adopt the Filesystem Hierarchy Standard ([FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)) to only have one [COPY](https://github.com/sclorg/s2i-base-container/blob/master/core/Dockerfile#L61) command to target container

6. Build the smallest image possible
* Reduce the amount of clutter in your image
* Clean temporary files

7. Use vulnerability scanning in Container Registry
* Carefully consider whether to use a public image

8. Properly tag images during build and when pulling an image use a specific version (not just latest)

9. Be mindful of licenses

10. Use native OS package manager (yum, apt, etc.) as much as possible
* [Fedora Package Browser](https://packages.fedoraproject.org/)
* [Fedora Package Sources](https://src.fedoraproject.org/)
* [Red Hat Package Browser](https://access.redhat.com/downloads/content/package-browser)
* [CentOS Package Browser](http://mirror.centos.org/centos/)
* [Debian Packages](https://www.debian.org/distrib/packages)
* [Ubuntu Packages Search](https://packages.ubuntu.com/)

11. During initialization scripts, explicitly [set path to execution programs](https://unix.stackexchange.com/questions/29608/why-is-it-better-to-use-usr-bin-env-name-instead-of-path-to-name-as-my)

12. Set environment variables and unset sensitive ones

13. [Set standard identifiers](https://github.com/projectatomic/ContainerApplicationGenericLabels)

14. Include documentation on usage

15. Learn from vendor’s best practices
* [Building containerized applications with Red Hat](https://developers.redhat.com/topics/containers)
* [Project Atomic’s Container Best Practices Guide](https://github.com/projectatomic/container-best-practices)
* [Red Hat’s Container Security Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/container_security_guide/index)
* [Google’s best practices](https://cloud.google.com/architecture/best-practices-for-building-containers)
* [Docker’s best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
* [Red Hat’s Getting Started with Containers](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/getting_started_with_containers/index)
* [Red Hat’s Recommended Practices for Container Development](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/recommended_practices_for_container_development/index)
* [Red Hat’s for Migrating to Containerized Applications](https://www.redhat.com/rhdc/managed-files/mi-best-practices-container-migration-ebook-f9195kc-201710-en_2.pdf)
* [Finding, Running, and Building Containers with podman, skopeo, and buildah](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html-single/managing_containers/index#finding_running_and_building_containers_with_podman_skopeo_and_buildah)
* [Creating and managing applications on OpenShift Container Platform](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.7/html/applications/index)
* [Creating and managing images and imagestreams in OpenShift Container Platform](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.7/html/images/index)

# Summary

If you're looking for some examples of containers I've built, check out this [GitHub repo](https://github.com/ecwpz91/containers).