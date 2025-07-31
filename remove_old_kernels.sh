#!/bin/bash -e

# Cross-compatible script to remove old kernels on Ubuntu or Red Hat-based systems
# Dry run by default; use 'exec' as first argument to perform deletions

OS=""
IN_USE_KERNEL=$(uname -r)
IN_USE_SHORT=${IN_USE_KERNEL%%-*}

echo "In-use kernel: $IN_USE_KERNEL"
echo ""

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Ubuntu / Debian
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    echo "Detected Debian-based system: $OS"

    OLD_KERNELS=$(
        dpkg --get-selections |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        grep -v "${IN_USE_SHORT}" |
        awk '{ print $1 }'
    )

    OLD_MODULES=$(
        ls /lib/modules |
        grep -v "${IN_USE_KERNEL}"
    )

    if [[ -n "$OLD_KERNELS" || -n "$OLD_MODULES" ]]; then
        echo "Old kernel packages to remove:"
        echo "$OLD_KERNELS"
        echo ""
        echo "Old kernel modules to remove:"
        echo "$OLD_MODULES"
        echo ""

        if [[ "$1" == "exec" ]]; then
            apt-get purge -y $OLD_KERNELS
            for mod in $OLD_MODULES; do
                rm -rf "/lib/modules/$mod"
            done
        else
            echo "Dry run completed. To delete, run as: sudo $0 exec"
        fi
    else
        echo "No old kernels/modules found to delete."
    fi

# Red Hat / CentOS / Rocky / AlmaLinux
elif [[ "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "rocky" || "$OS" == "almalinux" || "$OS" == "fedora" ]]; then
    echo "Detected Red Hat-based system: $OS"

    OLD_KERNELS=$(
        rpm -q kernel |
        grep -v "$IN_USE_KERNEL"
    )

    OLD_MODULES=$(
        ls /lib/modules |
        grep -v "${IN_USE_KERNEL}"
    )

    if [[ -n "$OLD_KERNELS" || -n "$OLD_MODULES" ]]; then
        echo "Old kernel RPMs to remove:"
        echo "$OLD_KERNELS"
        echo ""
        echo "Old kernel modules to remove:"
        echo "$OLD_MODULES"
        echo ""

        if [[ "$1" == "exec" ]]; then
            if command -v dnf >/dev/null 2>&1; then
                dnf remove -y $OLD_KERNELS
            else
                yum remove -y $OLD_KERNELS
            fi
            for mod in $OLD_MODULES; do
                rm -rf "/lib/modules/$mod"
            done
        else
            echo "Dry run completed. To delete, run as: sudo $0 exec"
        fi
    else
        echo "No old kernels/modules found to delete."
    fi

else
    echo "Unsupported or unknown OS: $OS"
    exit 2
fi
