#!/bin/bash

TARGET_VOLUMES=("procyon_mysql" "procyon_nc" "procyon_redis")
TARGET_DIRS=("/var/lib/mysql" "/var/www/html" "/data")

BACKUP_DIR=$(cd $(dirname $0); pwd)/backup
BACKUP_DIR=$BACKUP_DIR/$(ls -1 $BACKUP_DIR | sort -nr | head -n 1 | tr -d "\r\n")
BACKUP_IMAGE="busybox:latest"

if [ ${#TARGET_VOLUMES[@]} -ne ${#TARGET_DIRS[@]} ]; then
	echo "[ERROR] TARGET_VOLUMESとTARGET_DIRSの要素数が一致しません"
	exit 1
fi

for((i=0; i<${#TARGET_VOLUMES[@]}; i++)); do
	target_volume=${TARGET_VOLUMES[i]}
	target_dir=${TARGET_DIRS[i]}
	docker run --rm -v $target_volume:$target_dir -v $BACKUP_DIR:/backup:ro $BACKUP_IMAGE \
		sh -c "rm -rf ${target_dir}/* ${target_dir}/..?* ${target_dir}/.[!.]* \
		&& tar xvf /backup/${target_volume}.tar.gz"
done
