#!/usr/bin/env bash
#
# setup-gecko.sh
# Copyright (C) 2017 KuoE0 <kuoe0.tw@gmail.com>
#
# Distributed under terms of the MIT license.
#

if [ "$#" != "1" ]; then
	echo "usage: setup-gecko.sh [folder]"
	exit 1
fi

# absolute path of current directory
OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
	SCRIPTPATH=$(realpath "$0" | xargs -0 dirname)
else
	SCRIPTPATH=$(readlink -f "$0" | xargs -0 dirname)
fi

WORK_DIR="$1"
GECKO_DIR="$WORK_DIR/gecko-dev"

if [ ! -d "$WORK_DIR" ]; then
	mkdir -p "$WORK_DIR"
fi

################################################################################
# Setup git-cinnabar
################################################################################
CINNABAR_REPO="https://github.com/glandium/git-cinnabar"
CINNABAR_DIR="$WORK_DIR/git-cinnabar"
git clone "$CINNABAR_REPO" "$CINNABAR_DIR"
export PATH="$CINNABAR_DIR:$PATH"

pip install requests
git cinnabar download

if [ -d "$GECKO_DIR" ]; then
	while [ "$REPLY" != "y" ] && [ "$REPLY" != "n" ]; do
		read -p "${GECKO_DIR} is existed. Delete it? [y/N] "
		REPLY=$(echo $REPLY | tr '[:upper:]' '[:lower:]')
		if [ "$REPLY" = "" ]; then
			REPLY="n"
		fi
	done
	if [ "$REPLY" = "y" ]; then
		rm -rf "$GECKO_DIR"
	else
		echo "Please specify another folder."
		exit 1
	fi
fi
mkdir -p "$GECKO_DIR"
cd "$GECKO_DIR"
git init
git config fetch.prune true
git config push.default upstream

# mozilla-central
git remote add central hg::https://hg.mozilla.org/mozilla-central -t branches/default/tip
# mozilla-inbound
git remote add inbound hg::https://hg.mozilla.org/integration/mozilla-inbound -t branches/default/tip
git remote set-url --push inbound hg::ssh://hg.mozilla.org/integration/mozilla-inbound

# for short name
git config remote.central.fetch +refs/heads/branches/default/tip:refs/remotes/central/default
git config remote.inbound.fetch +refs/heads/branches/default/tip:refs/remotes/inbound/default

# try server
git remote add try hg::https://hg.mozilla.org/try
git config remote.try.skipDefaultUpdate true
git remote set-url --push try hg::ssh://hg.mozilla.org/try
git config remote.try.push +HEAD:refs/heads/branches/default/tip

################################################################################
# Setup my Gecko
################################################################################
GECKO_REPO="git@github.com:KuoE0/gecko-dev.git"
git remote add origin "$GECKO_REPO"

# update all remote branch
git remote update

# create master branch
git checkout origin/master
git checkout -b master
git branch -u origin/master master

################################################################################
# Setup mozconfigwrapper
################################################################################
git clone "https://github.com/mozilla/moz-git-tools.git" "$WORK_DIR/moz-git-tools"
pip install mozconfigwrapper
echo "$SCRIPTPATH/mozconfigs" > $GECKO_DIR/BUILDWITH_HOME

################################################################################
# Setup autoenv
################################################################################
ln -s "$SCRIPTPATH/autoenv.zsh" "$GECKO_DIR/.autoenv.zsh"
ln -s "$SCRIPTPATH/autoenv_leave.zsh" "$GECKO_DIR/.autoenv_leave.zsh"
read "Please install tarrasch/zsh-autoenv to enable autoenv!"

################################################################################
# Setup Gecko development environment
################################################################################
cd "$GECKO_DIR"
git checkout central/default
./mach bootstrap

################################################################################
# Setup llvm and clang for stylo
################################################################################
sudo apt install clang-3.9 llvm-3.9
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.9 10
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.9 10
