#!/bin/bash

convert_images() {
	original_path=$1
	child_dir=$(dirname "/workdir/${1#/original/}")

	# 1 枚ずつ解像度を見て、大きい方が 3000 px以上だった場合は 50 % のオプション追加
	additional_opts=""
	max_pixels=$(identify -ping -format "%w\n%h" "$original_path" | sort -nr | head -1)
	if [ $max_pixels -ge 3000 ]; then
		additional_opts+="-resize 50%"
	fi

	mogrify -format jpg -quality 80% $additional_opts -define jpeg:extent=800kb -strip -interlace Plane -path "$child_dir" "$original_path"
	echo "converted image: $original_path"
}

export -f convert_images

for cmd in curl xmlstarlet nkf pdfimages identify mogrify; do
	if ! command -v $cmd &> /dev/null; then
		echo "command not found: $cmd"
		exit 1
	fi
done

if [ -z $CONCURRENCY ]; then
	CONCURRENCY=8
fi
echo "concurrency: $CONCURRENCY"

if [ -z $WEBDAV_DOMAIN ]; then
	read -p "webdav domain: " WEBDAV_DOMAIN
fi

if [ -z $WEBDAV_PATH ]; then
	read -p "webdav path: " WEBDAV_PATH
fi

if [ -z $WEBDAV_USER ]; then
	read -p "webdav username: " WEBDAV_USER
fi

if [ -z $WEBDAV_PASSWORD ]; then
	read -p "webdav password: " WEBDAV_PASSWORD
fi

tree -d -L 2 --noreport /original
if [ $? -ne 0 ]; then
	echo "directory not found: /original"
	exit 1
fi

IFS=$'\n'
for opd in $(find /original -mindepth 1 -maxdepth 1 -type d); do
	for ocd in $(find $opd -mindepth 1 -maxdepth 1 -type d); do
		cdbn=$(basename $ocd)
		cdbn_raw=${cdbn#__}
		pdbn=$(basename $(dirname $ocd))

		cdbn_e=$(echo $cdbn | nkf -WwMQ | tr = %)
		cdbn_raw_e=$(echo $cdbn_raw | nkf -WwMQ | tr = %)
		pdbn_e=$(echo $pdbn | nkf -WwMQ | tr = %)

		echo -e "\n-----"
		echo "parent dir: $pdbn"
		if [[ $cdbn != $cdbn_raw ]]; then
			echo -e " child dir: $cdbn_raw (image file names will not be changed)\n"
		else
			echo -e " child dir: $cdbn\n"
		fi

		p_dirs=$(curl -s -X PROPFIND -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} \
			-H 'Depth:1' ${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/ | \
			xmlstarlet sel -N x="DAV:" -t -v "//x:href" | nkf -w --url-input)
		if [ $? -ne 0 ]; then
			echo "failed to list parent directories: ${WEBDAV_PATH%/}"
			exit 1
		fi

		p_ex=0
		for p_dir in $p_dirs; do
			p_dir=${p_dir#${WEBDAV_PATH}}

			if [[ $p_dir == */ ]]; then
				p_dir=$(basename $p_dir)
				if [ $p_dir = $pdbn ]; then
					p_ex=1
				fi
			fi
		done

		if test $p_ex -eq 1; then
			c_dirs=$(curl -s -X PROPFIND -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} \
				-H 'Depth:1' ${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/${pdbn_e}/ | \
				xmlstarlet sel -N x="DAV:" -t -v "//x:href" | nkf -w --url-input)
			if [ $? -ne 0 ]; then
				echo "failed to list child directories: ${WEBDAV_PATH%/}/${pdbn}/"
				exit 1
			fi

			c_ex=0
			for c_dir in $c_dirs; do
				c_dir=${c_dir#${WEBDAV_PATH%/}/${pdbn}/}

				if [[ $c_dir == */ ]]; then
					c_dir=$(basename $c_dir)
					if [ $c_dir = $cdbn ]; then
						c_ex=1
					fi
				fi
			done

			if test $c_ex -eq 1; then
				echo "already exists: ${WEBDAV_PATH%/}/${pdbn}/${cdbn}"
				continue
			fi
		else
			# parent dir の作成
			curl -s -X MKCOL -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} \
				${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/${pdbn_e}/
			if [ $? -ne 0 ]; then
				echo "failed to create parent directory: ${WEBDAV_PATH%/}/${pdbn}/"
				exit 1
			fi
			echo "parent directory created: ${WEBDAV_PATH%/}/${pdbn}/"
		fi

		# child dir の作成
		curl -s -X MKCOL -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} \
			${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/${pdbn_e}/${cdbn_raw_e}/
		if [ $? -ne 0 ]; then
			echo "failed to create child directory: ${WEBDAV_PATH%/}/${pdbn}/${cdbn}/"
			exit 1
		fi
		echo "child directory created: ${WEBDAV_PATH%/}/${pdbn}/${cdbn}/"

		# PDF から画像を抽出
		original_images=$(find /original/${pdbn}/${cdbn}/ -mindepth 1 -maxdepth 1 -type f)
		original_images_count=$(echo "$original_images" | wc -l)

		if [ $original_images_count -eq 0 ]; then
			echo "original image not found: /original/${pdbn}/${cdbn}/"
			continue
		elif [ $original_images_count -eq 1 ]; then
			if [[ $original_images == *.pdf ]]; then
				pdfimages -all $original_images image
				rm $original_images
			fi
		fi

		# 画像の変換
		child_dir="/workdir/${pdbn}/${cdbn}/"
		mkdir -p "$child_dir"
		echo "$original_images" | xargs -I@ -P${CONCURRENCY} -n1 bash -c 'convert_images "@"'
		if [ $? -ne 0 ]; then
			echo "failed to convert images: /original/${pdbn}/${cdbn}/"
			exit 1
		fi

		cd "$child_dir"

		# 画像の rename
		# child dir が "__" から始まる場合は rename しない
		if [[ $cdbn == $cdbn_raw ]]; then
			find *.jpg | sort -V | awk '{ printf "mv \"%s\" %05d.jpg\n", $0, NR }' | bash
			if [ $? -ne 0 ]; then
				echo "failed to rename images: $child_dir"
				exit 1
			fi
		fi

		# 画像のアップロード
		for p in $(find *.jpg); do
			curl -s -X PUT -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} \
				${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/${pdbn_e}/${cdbn_raw_e}/ \
				-T "$p"
			if [ $? -ne 0 ]; then
				echo "failed to upload image: $p"
				exit 1
			fi
			echo "image uploaded: $p"
		done

		echo "upload complete: ${WEBDAV_DOMAIN%/}${WEBDAV_PATH%/}/${pdbn_e}/${cdbn_raw_e}/"
	done
done
