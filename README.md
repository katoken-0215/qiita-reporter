# Qiita reporter

## Usage

1. Install qiita_information gem
2. Run below

```shell
bundle exec ruby main.rb > 20170101.json
# Next day
bundle exec ruby main.rb > 20170102.json

ruby diff.rb 20170101.json 20170102.json > mail.html

MAIL_SUBJECT="Today's qiita report" \
MAIL_FROM="your@mail.host" \
MAIL_TO="to@mail.host" \
SMTP_SERVER="smtp@server" \
ruby mail.rb < mail.html
```
