#!/bin/bash

set -Ceu

S3ARCHIVER_PATH=$(cd $(dirname $0)/..; pwd)

target=$1

if [ -z "$target" ]; then
    echo "Target not specified" >&2
    exit 1
fi

mkdir -p $target
target=$(cd $target; pwd)
name=$(basename $target)

. $S3ARCHIVER_PATH/s3-config.sh

archive_dir=$S3ARCHIVER_PATH/archive
mkdir -p $archive_dir

s3_last_ls_line=$(aws s3 ls s3://$s3_archive_bucket/$s3_archive_prefix/$name.tar.gz. | LC_ALL=C sort | tail -n1)
if [ -z "$s3_last_ls_line" ]; then
    echo "Not found: s3://$s3_archive_bucket/$s3_archive_prefix/$name.tar.gz" >&2
    exit 1
else
    s3_last_fname=$(echo "$s3_last_ls_line" | awk '{print $4}')
    s3_last_num=$(echo "$s3_last_fname" | sed -E -e 's/^.+\.tar\.gz\.([0-9]+)$/\1/')
    if [ -z "$s3_last_num" ]; then
        echo "Not found: s3://$s3_archive_bucket/$s3_archive_prefix/$name.tar.gz" >&2
        exit 1
    fi
fi

mkdir -p $archive_dir
echo "pull from s3://$s3_archive_bucket/$s3_archive_prefix/$name.tar.gz.$s3_last_num"
aws s3 cp s3://$s3_archive_bucket/$s3_archive_prefix/$name.tar.gz.$s3_last_num $archive_dir/$name.tar.gz.$s3_last_num

(
    cd $(dirname $target)
    tar xzf $archive_dir/$name.tar.gz.$s3_last_num
)

bash $S3ARCHIVER_PATH/lib/dir-hash.sh $target $archive_dir/$name.tar.gz $s3_last_num

