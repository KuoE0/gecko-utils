################################################################################
# Usage: ln -s </path/to/this/file> $GECKO/.autoenv_leave.zsh
################################################################################

unalias mach
complete -r mach
PROMPT=${ORIGIN_PROMPT}
unset ORIGIN_PROMPT
add-zsh-hook -d precmd update_prompt
