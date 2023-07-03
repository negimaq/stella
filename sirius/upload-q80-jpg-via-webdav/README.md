# upload-q80-jpg-via-webdav

```bash
$ docker build . -t upload-q80-jpg-via-webdav

$ cat <<EOF
WEBDAV_URL=https://xxxxxxxxxx
WEBDAV_USER=xxxxx
WEBDAV_PASSWORD=xxxxxxxxxx
EOF

$ docker run -it --rm --env-file .env upload-q80-jpg-via-webdav
```
