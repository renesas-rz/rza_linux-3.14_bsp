# set prompt
PS1='$ '

# aliases
alias ll='ls -lap'

# Add /root/bin and /root/scripts to our PATH to make it
# easier to run demos
PATH=$PATH:/root/bin:/root/scripts

# Remove all those extra tty deivces we'll never use
# by deleting "/dev/tty10-63" (makes /dev easier to browse)
if [ -e /dev/tty10 ] ; then
  for i in $(seq 10 1 63); do rm /dev/tty$i ; done
fi

# Set date/time
date -s "2014-13-01 9:00:00"

# Automatically run demos here by putting them here

