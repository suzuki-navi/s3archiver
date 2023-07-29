#!/bin/bash

set -Ceu

target=$1
base_path=$2
num=$3

hash_path=$base_path.$num.hash

(
    cd $target
    find . | LC_ALL=C sort
    find . -type f | xargs cat | sha1sum | cut -b-40
) >| $hash_path.txt
cat $hash_path.txt | sha1sum | cut -b-40 >| $hash_path

