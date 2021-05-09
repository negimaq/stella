#!/bin/bash

TARGET_VOLUMES=("procyon_mysql" "procyon_nc" "procyon_redis")
TARGET_DIRS=("/var/lib/mysql" "/var/www/html" "/data")

BACKUP_DIR=$(cd $(dirname $0); pwd)/backup/$(date "+%Y%m%d%H%M")
BACKUP_IMAGE="busybox:latest"

if [ ${#TARGET_VOLUMES[@]} -ne ${#TARGET_DIRS[@]} ]; then
	echo "[ERROR] TARGET_VOLUMESとTARGET_DIRSの要素数が一致しません"
	exit 1
fi

mkdir -p $BACKUP_DIR

for((i=0; i<${#TARGET_VOLUMES[@]}; i++)); do
	target_volume=${TARGET_VOLUMES[i]}
	target_dir=${TARGET_DIRS[i]}
	docker run --rm -v $target_volume:$target_dir:ro -v $BACKUP_DIR:/backup $BACKUP_IMAGE \
		sh -c "tar cvf /backup/${target_volume}.tar.gz $target_dir"
done
