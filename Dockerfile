FROM ruby:3.1

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV APP_ENV production
ENV RACK_ENV production
ENV PORT 8080
ENV BIND 0.0.0.0

CMD ["bundle", "exec", "ruby", "app.rb"]

