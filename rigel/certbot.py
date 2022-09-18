#!/usr/local/bin/python

import os
import re
import time
import base64
import subprocess

GOOGLE_CREDENTIALS_JSON_PATH = "/google-credentials.json"
GOOGLE_PROPAGATION_SECONDS = 30

email = os.environ.get("EMAIL")
domains_list = os.environ.get("WEB_DOMAINS").split()
google_credentials_json = base64.b64decode(
    os.environ.get("GOOGLE_CREDENTIALS").encode()
).decode()

with open(GOOGLE_CREDENTIALS_JSON_PATH, mode="w") as f:
    f.write(google_credentials_json)

os.chmod(GOOGLE_CREDENTIALS_JSON_PATH, 0o0600)

domains_dict = {}
for d in domains_list:
    m = re.search(r"([a-z0-9-_]+\.[a-z0-9-_]+)\.?$", d)
    sld = m.group(1)

    if sld not in domains_dict:
        domains_dict[sld] = []

    domains_dict[sld].append(d)

for sld, l in domains_dict.items():
    subprocess.run(
        [
            "certbot",
            "certonly",
            "--agree-tos",
            "--keep-until-expiring",
            "--dns-google",
            "--dns-google-credentials",
            GOOGLE_CREDENTIALS_JSON_PATH,
            "--dns-google-propagation-seconds",
            str(GOOGLE_PROPAGATION_SECONDS),
            "--domains",
            ",".join(l),
            "--email",
            email,
        ]
    )

    time.sleep(60)
