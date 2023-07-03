# upload-q80-jpg-via-webdav

```bash
$ docker build . -t upload-q80-jpg-via-webdav

$ cat <<EOF
CONCURRENCY=12
WEBDAV_DOMAIN=https://xxxxxxxxxx.xxx
WEBDAV_PATH=/path/to/dir/
WEBDAV_USER=xxxxx
WEBDAV_PASSWORD=xxxxxxxxxx
EOF

$ docker run -it --rm -e .env -v ./target:/original:ro upload-q80-jpg-via-webdav
```
