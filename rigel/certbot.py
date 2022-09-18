#!/usr/local/bin/python

import subprocess

# GOOGLE_CREDENTIALS_JSON_PATH=/google-credentials.json
# echo $GOOGLE_CREDENTIALS | base64 -d > $GOOGLE_CREDENTIALS_JSON_PATH
# chmod 600 $GOOGLE_CREDENTIALS_JSON_PATH


subprocess.run([
"certbot", "certonly",
	"--agree-tos",
	"--dns-google",
	"--dns-google-credentials $GOOGLE_CREDENTIALS_JSON_PATH",
	"--dns-google-propagation-seconds 30",
	"--domains ${WEB_DOMAINS// /,}",
	"--email ${EMAIL}",
    ])

