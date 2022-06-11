@echo off

DOSKEY     g=git $*
DOSKEY    gs=git status $*
DOSKEY    gd=git diff $*
DOSKEY   gdc=git diff --cached $*
DOSKEY    ga=git add $*
DOSKEY   gap=git add -p $*
DOSKEY    gc=git commit -m $*
DOSKEY   gca=git commit --amend $*
DOSKEY   gac=git commit -am $*
DOSKEY    gb=git branch $*
DOSKEY   gbb=bash -c "git branch | grep '*' | cut -c 3-"
DOSKEY   gbd=bash -c "git branch -d $(git branch | grep -v '*')"
DOSKEY   gck=git checkout $*
DOSKEY    gl=git log --stat --graph $*
DOSKEY   glo=git log --stat --graph --oneline $*
DOSKEY   gla=git log --stat --graph --oneline --all $*
DOSKEY    gp=git push $*
DOSKEY    gr=git reset $*
DOSKEY   grH=git reset HEAD $*
DOSKEY   grh=git reset --hard $*
DOSKEY  grhH=git reset --hard HEAD
DOSKEY   gpl=git pull $*
DOSKEY   gst=git stash $*
DOSKEY  gsta=git stash apply $*
DOSKEY  gsts=git stash save $*
DOSKEY   gau=git update-index --assume-unchanged $*
DOSKEY  gnau=git update-index --no-assume-unchanged $*
DOSKEY  gauf=bash -c "git ls-files -v | grep '^[[:lower:]]'"
DOSKEY  gcmd=bash -c "cat /mnt/d/Documents/Repositories/dotfiles/Common.profile | grep -e 'alias *g' | grep -v 'grep'"

DOSKEY npmr=npm run $*

DOSKEY node6="C:\Program Files\nodejs-6\node.exe" $*
DOSKEY npm6="C:\Program Files\nodejs-6\npm.cmd" $*
