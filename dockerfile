# 使いたいバージョン次第で書き換える https://hub.docker.com/_/ruby
FROM ruby:3.5-rc

RUN apt-get update && apt-get install -y git

WORKDIR /usr/src/app

# 3000番ポートを解放
EXPOSE 3000