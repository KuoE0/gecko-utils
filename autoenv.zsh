################################################################################
# Usage: ln -s </path/to/this/file> $GECKO/.autoenv.zsh
################################################################################
OS=$(uname)

autostash GECKO=$(git rev-parse --show-toplevel)
alias mach="$GECKO/mach"
alias mb="mach build"
alias mbb="mach build binaries"
alias mt="mach try"

LOCATE="locate"
[[ "$OS" = "Darwin" ]] && LOCATE="mdfind" # use `mdfind` in OS X as locate

# Load completion for mach
autoload bashcompinit
bashcompinit
source "$GECKO/python/mach/bash-completion.sh"

if which mozconfigwrapper.sh 2>/dev/null 1>/dev/null; then
	export BUILDWITH_HOME="$(cat BUILDWITH_HOME)"
	source mozconfigwrapper.sh

	# Append current mozconfig's to shell prompt
	[[ -z ${ORIGIN_PROMPT+x} ]] && ORIGIN_PROMPT=$PROMPT
	update_prompt() {
		# update $MOZCONFIG
		export MOZCONFIG="$BUILDWITH_HOME/$(cat $BUILDWITH_HOME/.active)"
		CONFIG=$(basename $MOZCONFIG)
		PROMPT="%F{242}${CONFIG} ${ORIGIN_PROMPT}"
	}
	add-zsh-hook precmd update_prompt
else
	echo "Please install mozconfigwrapper with following command..."
	echo ""
	echo "    $ pip install mozconfigwrapper"
	echo ""
fi

TOOL_PATH=""

# Load Rust compiler
if [ -d "$HOME/.cargo/bin" ]; then
	TOOL_PATH="$HOME/.cargo/bin:$TOOL_PATH"
else
	echo "Please run 'mach bootstrap' to install rust compiler."
fi

# Load git-mozreview
if [ -d "$HOME/.mozbuild/version-control-tools/git/commands" ]; then
	TOOL_PATH="$HOME/.mozbuild/version-control-tools/git/commands:$TOOL_PATH"
else
	echo "Please run 'mach mercurial-setup' to install version-control-tools."
fi

# Load git-cinnabar
if echo "$PATH" | grep -q "git-cinnabar"; then
	echo "git-cinnabar is already ready!"
else
	if [[ -z ${CINNABAR_PATH+x} ]]; then
		# cache CINNABAR_PATH
		export CINNABAR_PATH=$($LOCATE git-cinnabar | grep "git-cinnabar$" | sort | head -n 1)
		if [[ "$CINNABAR_PATH" = "" ]]; then
			echo "Please install git-cinnabar with following command..."
			echo ""
			echo "    $ git clone https://github.com/glandium/git-cinnabar"
			echo ""
		fi
	fi

	if [[ "$CINNABAR_PATH" != "" ]]; then
		TOOL_PATH="$CINNABAR_PATH:$TOOL_PATH"
		echo "git-cinnabar is ready!"
	fi
fi

autostash PATH="$TOOL_PATH:$PATH"
