[TOC]

## `remove_old_kernels.sh`

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This script is designed to help manage and remove old Linux kernels and their associated modules from a system, helping to free up disk space and maintain a clean environment. Here's a breakdown of what each part of the script does:

### 1. Script Header and Usage Instructions

```bash
#!/bin/bash -e
# Run this script without any arguments for a dry run
# Run the script with root and with exec arguments for removing old kernels and modules after checking
# the list printed in the dry run
```

- The script uses the Bash shell (`#!/bin/bash`) and the `-e` flag causes the script to exit immediately if any command fails.
- The comments explain that the script can be run in a "dry run" mode without arguments, or with the "exec" argument to actually perform the cleanup.

### 2. Identifying the Currently In-Use Kernel

```bash
uname -a
IN_USE=$(uname -a | awk '{ print $3 }')
echo "Your in use kernel is $IN_USE"
```

- The `uname -a` command displays system information, including the currently running kernel version.
- The script then extracts the kernel version using `awk` and stores it in the `IN_USE` variable.
- This kernel version is important because it should not be removed.

### 3. Finding Old Kernels to Remove

```bash
OLD_KERNELS=$(
    dpkg --get-selections |
        grep -v "linux-headers-generic" |
        grep -v "linux-image-generic" |
        grep -v "linux-image-generic" |
        grep -v "${IN_USE%%-generic}" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $1 }'
)
echo "Old Kernels to be removed:"
echo "$OLD_KERNELS"
```

- The script uses `dpkg --get-selections` to list all installed packages.
- The `grep` commands filter out the current kernel and its generic versions, ensuring the currently active kernel is not selected for removal.
- The remaining packages, which include older kernels, headers, and modules, are captured in the `OLD_KERNELS` variable.
- These are the kernel packages that the script suggests for removal.

### 4. Finding Old Kernel Modules to Remove

```bash
OLD_MODULES=$(
    ls /lib/modules |
    grep -v "${IN_USE%%-generic}" |
    grep -v "${IN_USE}"
)
echo "Old Modules to be removed:"
echo "$OLD_MODULES"
```

- The script lists the directories under `/lib/modules` which usually contain kernel modules.
- It then filters out the directory for the currently running kernel and stores the rest in `OLD_MODULES`.
- These are the old module directories that could be safely removed.

### 5. Conditional Execution for Actual Removal

```bash
if [ "$1" == "exec" ]; then
  apt-get purge $OLD_KERNELS
  for module in $OLD_MODULES ; do
    rm -rf /lib/modules/$module/
  done
else
    echo "If all looks good, run it again like this: sudo remove_old_kernels.sh exec"
fi
```

- If the script is run with the `exec` argument, it proceeds to remove the identified old kernels using `apt-get purge`.
- The script also removes the old module directories using `rm -rf`.
- If the script is run without the `exec` argument, it only prints the old kernels and modules that would be removed, serving as a "dry run."

### Summary

- The script is a safe way to clean up old kernels and modules from a Linux system.
- Running it without arguments shows what would be removed, while running it with the `exec` argument actually performs the cleanup.
- This approach helps avoid accidentally removing the kernel currently in use.

### Usage

#### 1. Analyze what can be deleted (dry run)

```bash
bash remove_old_kernels.sh
```

#### 2. Execute kernel deletion

```bash
sudo bash remove_old_kernels.sh exec
```
