FROM ubuntu:22.04

RUN apt update &&\
    apt install ruby-full=1:3.0~exp1 -y &&\
    apt install build-essential=12.9ubuntu3 -y &&\
    gem install jekyll:4.2.2 bundler:2.2.23 minima:2.5.1

RUN apt-get -y install git
WORKDIR /application

CMD bundle install && bundle exec jekyll serve --host 0.0.0.0 --force_polling
