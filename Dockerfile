ARG PORT=8080

FROM ubuntu:20.04

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
COPY requirements.txt .
RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install -r requirements.txt
RUN apt-get install -y xvfb
RUN apt-get install -y fluxbox
RUN apt-get install -y wget
RUN apt-get install -y wmctrl
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update && apt-get -y install google-chrome-stable
RUN rm -f /usr/local/lib/python3.8/dist-packages/dataframe_image/screenshot.py
COPY ./src/patch/_screenshot.py /usr/local/lib/python3.8/dist-packages/dataframe_image/

COPY ./src/ /src/
EXPOSE $PORT

ENTRYPOINT ["python3", "/src/entry.py"]
