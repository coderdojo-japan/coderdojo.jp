FROM ruby:3.1.4

ENV LANG C.UTF-8

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
    nodejs \
    libpq-dev \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

ENV ENTRYKIT_VERSION 0.4.0


RUN mkdir /app

WORKDIR /app

RUN bundle config build.nokogiri --use-system-libraries

ENTRYPOINT [ "./entrypoint.rb" ]
