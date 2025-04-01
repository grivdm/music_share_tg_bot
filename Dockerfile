FROM ruby:3.2-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y build-essential git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

# Запускаем бота
CMD ["ruby", "bot.rb"]