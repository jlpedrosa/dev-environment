#!/bin/bash

# If your GOPATH has multiple paths, pick
# just one and use it instead of $GOPATH here.
# You must follow exactly this pattern,
# neither `$GOPATH/src/github.com/${your github profile name/`
# nor any other pattern will work.
export working_dir=$GOPATH/src/k8s.io

export user="jlpedrosa"

mkdir -p $working_dir
cd $working_dir
git clone git@github.com:$user/kubernetes.git

cd $working_dir/kubernetes
git remote add upstream git@github.com:kubernetes/kubernetes.git

git remote set-url --push upstream no_push


git fetch upstream
git checkout master
git rebase upstream/master
git push

export working_dir=$GOPATH/src/k8s.io
cd $working_dir
git clone git@github.com:$user/kubefed.git


cd $working_dir/kubefed
git remote add upstream git@github.com:kubernetes-sigs/kubefed.git
git remote set-url --push upstream no_push
git fetch upstream
git checkout master
git rebase upstream/master
git push