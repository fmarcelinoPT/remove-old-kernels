#!/bin/bash -e
# Run this script without any arguments for a dry run
# Run the script with root and with exec arguments for removing old kernels and modules after checking
# the list printed in the dry run

uname -a
IN_USE=$(uname -a | awk '{ print $3 }')
echo "Your in use kernel is $IN_USE"
echo ""

OLD_KERNELS=$(
    dpkg --get-selections |
        grep -v "linux-headers-generic" |
        grep -v "linux-image-generic" |
        grep -v "linux-image-generic" |
        grep -v "${IN_USE%%-generic}" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $1 }'
)

if [[ -z "$OLD_KERNELS" ]]; then
  echo "No old kernels found."
else
  echo "Old Kernels to be removed:"
  echo "$OLD_KERNELS"
fi

echo ""

OLD_MODULES=$(
    ls /lib/modules |
    grep -v "${IN_USE%%-generic}" |
    grep -v "${IN_USE}"
)

if [[ -z "$OLD_MODULES" ]]; then
  echo "No old modules found."
else
  echo "Old Modules to be removed:"
  echo "$OLD_MODULES"
fi

echo ""
echo ""

# Combine check and message for clarity
if [[ -n "$OLD_KERNELS" || -n "$OLD_MODULES" ]]; then
  if [ "$1" == "exec" ]; then
    apt-get purge $OLD_KERNELS
    for module in $OLD_MODULES ; do
      rm -rf /lib/modules/$module/
    done
  else
    echo "If all looks good, run it again like this: sudo   
 remove_old_kernels.sh exec"
  fi
else
  echo "Nothing found to delete."
fi