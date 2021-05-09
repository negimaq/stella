FROM python:3.9.3

RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> \
	/etc/apt/sources.list.d/google-chrome.list \
	&& wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | \
	apt-key add - \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y google-chrome-stable

RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
	&& curl -sS -o /tmp/chromedriver_linux64.zip \
	http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
	&& unzip /tmp/chromedriver_linux64.zip \
	&& mv chromedriver /usr/local/bin/

RUN pip install --upgrade pip \
	&& pip install selene==2.0.0a38
