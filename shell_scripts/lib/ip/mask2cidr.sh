#!/bin/bash

# Function calculates number of bit in a netmask
#
function mask2cidr() {
    nbits=0
    local IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

# Tests
# mask2cidr 255.255.255.0
#   output: 24
# mask2cidr 255.255.254.0
#   output: 23
