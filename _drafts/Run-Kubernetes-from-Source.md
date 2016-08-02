---
layout: post
title: "Build and Run Kubernetes from Source"
date: "2016-03-15 19:12"
---

# Objectives
After completing this lab, you should:

- Develop Kubernetes locally on your host.

# Prerequisites

  1. Install `libseccomp-devel` package (http://bit.ly/1URgtDp)

# Kubernetes Development (Optional)

To get started, [fork](https://help.github.com/articles/fork-a-repo) the [origin repository](https://github.com/kubernetes/kubernetes).

:exclamation: Requires Go version 1.4.x or 1.5.x

### Here's how to get setup:

The commands below require that you have $GOPATH set ([$GOPATH docs](https://golang.org/doc/code.html#GOPATH)). We highly recommend you put Kubernetes' code into your GOPATH. Note: the commands below will not work if there is more than one directory in your `$GOPATH`.

```sh
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
# Replace "$YOUR_GITHUB_USERNAME" below with your github username
git clone https://github.com/$YOUR_GITHUB_USERNAME/kubernetes.git
cd kubernetes
git remote add upstream 'https://github.com/kubernetes/kubernetes.git'
```

  [IMAGE]

### Create a branch and make changes

```sh
git checkout -b myfeature
# Make your code changes
```

### Keeping your development fork in sync

```sh
git fetch upstream
git rebase upstream/master
```

Note: If you have write access to the main repository at github.com/kubernetes/kubernetes, you should modify your git configuration so that you can't accidentally push to upstream:

```sh
git remote set-url --push upstream no_push
```

### Committing changes to your fork

Before committing any changes, please link/copy these pre-commit hooks into your .git
directory. This will keep you from accidentally committing non-gofmt'd go code.

```sh
cd kubernetes/.git/hooks/
ln -s ../../hooks/pre-commit .
```

Then you can commit your changes and push them to your fork:

```sh
git commit
git push -f origin myfeature
```

### Creating a pull request

1. Visit https://github.com/$YOUR_GITHUB_USERNAME/kubernetes
2. Click the "Compare and pull request" button next to your "myfeature" branch.
3. Check out the pull request [process](pull-requests.md) for more details


## godep and dependency management

Kubernetes uses [godep](https://github.com/tools/godep) to manage dependencies. It is not strictly required for building Kubernetes but it is required when managing dependencies under the Godeps/ tree, and is required by a number of the build and test scripts. Please make sure that ``godep`` is installed and in your ``$PATH``.

### Installing godep

There are many ways to build and host go binaries. Here is an easy way to get utilities like `godep` installed:

1) Ensure that [mercurial](http://mercurial.selenic.com/wiki/Download) is installed on your system. (some of godep's dependencies use the mercurial
source control system).  Use `apt-get install mercurial` or `yum install mercurial` on Linux, or [brew.sh](http://brew.sh) on OS X, or download
directly from mercurial.

2) Create a new GOPATH for your tools and install godep:

```sh
export GOPATH=$HOME/go-tools
mkdir -p $GOPATH
go get github.com/tools/godep
```

3) Add $GOPATH/bin to your path. Typically you'd add this to your ~/.profile:

```sh
export GOPATH=$HOME/go-tools
export PATH=$PATH:$GOPATH/bin
```

Note:
At this time, godep update in the Kubernetes project only works properly if your version of godep is < 54.

To check your version of godep:

```sh
$ godep version
godep v53 (linux/amd64/go1.5.3)
```

### Using godep

Here's a quick walkthrough of one way to use godeps to add or update a Kubernetes dependency into Godeps/\_workspace. For more details, please see the instructions in [godep's documentation](https://github.com/tools/godep).

1) Devote a directory to this endeavor:

_Devoting a separate directory is not required, but it is helpful to separate dependency updates from other changes._

```sh
export KPATH=$HOME/code/kubernetes
mkdir -p $KPATH/src/k8s.io/kubernetes
cd $KPATH/src/k8s.io/kubernetes
git clone https://path/to/your/fork .
# Or copy your existing local repo here. IMPORTANT: making a symlink doesn't work.
```

2) Set up your GOPATH.

```sh
# Option A: this will let your builds see packages that exist elsewhere on your system.
export GOPATH=$KPATH:$GOPATH
# Option B: This will *not* let your local builds see packages that exist elsewhere on your system.
export GOPATH=$KPATH
# Option B is recommended if you're going to mess with the dependencies.
```

3) Populate your new GOPATH.

```sh
cd $KPATH/src/k8s.io/kubernetes
godep restore
```

[IMAGE]

4) Next, you can either add a new dependency or update an existing one.

```sh
# To add a new dependency, do:
cd $KPATH/src/k8s.io/kubernetes
go get path/to/dependency
# Change code in Kubernetes to use the dependency.
godep save ./...

# To update an existing dependency, do:
cd $KPATH/src/k8s.io/kubernetes
go get -u path/to/dependency
# Change code in Kubernetes accordingly if necessary.
godep update path/to/dependency/...
```

_If `go get -u path/to/dependency` fails with compilation errors, instead try `go get -d -u path/to/dependency`
to fetch the dependencies without compiling them.  This can happen when updating the cadvisor dependency._


5) Before sending your PR, it's a good idea to sanity check that your Godeps.json file is ok by running `hack/verify-godeps.sh`

_If hack/verify-godeps.sh fails after a `godep update`, it is possible that a transitive dependency was added or removed but not
updated by godeps.  It then may be necessary to perform a `godep save ./...` to pick up the transitive dependency changes._

It is sometimes expedient to manually fix the /Godeps/godeps.json file to minimize the changes.

Please send dependency updates in separate commits within your PR, for easier reviewing.

6) If you updated the Godeps, please also update `Godeps/LICENSES` by running `hack/update-godep-licenses.sh`.

## Testing

Three basic commands let you run unit, integration and/or e2e tests:

```sh
cd kubernetes
hack/test-go.sh  # Run unit tests
hack/test-integration.sh  # Run integration tests, requires etcd
go run hack/e2e.go -v --build --up --test --down  # Run e2e tests
```

See the [testing guide](testing.md) for additional information and scenarios.

## Regenerating the CLI documentation

```sh
hack/update-generated-docs.sh
```
