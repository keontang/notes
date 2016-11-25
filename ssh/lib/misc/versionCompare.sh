#!/bin/bash

# Compare two strings in dot separated version format: X.Y.Z, A.B.C.D
# For example:
#   1            1            =
#   2.1          2.2          <
#   3.0.4.10     3.0.4.2      >
#   4.08         4.08.01      <
#   3.2.1.9.8144 3.2          >
#   3.2          3.2.1.9.8144 <
#   1.2          2.1          <
#   2.1          1.2          >
#   5.6.7        5.6.7        =
#   1.01.1       1.1.1        =
#   1.1.1        1.01.1       =
#   1            1.0          =
#   1.0          1            =
#   1.0.2.0      1.0.2        =
#   1..0         1.0          =
#   1.0          1..0         =
#
# Input:
#   $1: version_1
#   $2: version_2
#
# Output:
#   0: version_1 == version_2
#   1: version_1 > version_2
#   2: version_1 < version_2
function version_compare () {
    if [[ $1 == $2 ]]; then
        return 0
    fi

    local IFS=.
    local i ver1=($1) ver2=($2)

    # Fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # Fill empty fields in ver2 with zeros
            ver2[i]=0
        fi

        # version_1 > version_2
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi

        # version_1 < version_2
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done

    # version_1 == version_2
    return 0
}