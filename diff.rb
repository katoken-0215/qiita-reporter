#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'

require 'json'
require 'set'

Users = Struct.new(:users) do
  def find_by_name(name)
    users.find { |user| user.name == name }
  end
end

User = Struct.new(:name, :items)

UserDiff = Struct.new(:name, :items)

Items = Struct.new(:items) do
  def find_by_url(url)
    items.find { |item| item.url == url }
  end
end

Item = Struct.new(:title, :username, :url, :date, :like, :hatebu) do
  def diff(other)
    if like - other.like + (hatebu - other.hatebu) > 0
      ItemDiff.new(title, username, url, date,
                   like - other.like,
                   hatebu - other.hatebu)
    end
  end
end

ItemDiff = Struct.new(:title, :username, :url, :date, :like, :hatebu)

def load_json(s)
  users = JSON.parse(s).map do |entry|
    items = entry['items'].map do |item|
      Item.new(item['title'], entry['user'], item['url'], item['date'], item['like'], item['hatebu'])
    end
    User.new(entry['user'], Items.new(items))
  end
  Users.new(users)
end

users_old = load_json(File.read(ARGV[0]))
users_new = load_json(File.read(ARGV[1]))

# New users
new_users = []
new_items = []
updated_items = []

users_new.users.each do |user_new|
  user_old = users_old.find_by_name(user_new.name)
  if user_old.nil?
    new_users << user_new
  else
    user_new.items.items.each do |item|
      item_old = user_old.items.find_by_url(item.url)
      if item_old.nil?
        new_items << item
      else
        itemdiff = item.diff(item_old)
        unless itemdiff.nil?
          updated_items << itemdiff
        end
      end
    end
  end
end


updated_items = updated_items.sort_by! do |item|
  item.like + item.hatebu
end

updated_items.reverse!

## report mail

unless new_items.length == 0 && updated_items.length == 0
  puts <<-"EOS"
<html>
<head>
<meta charset="UTF-8">
<style>
body: { border: gray solid 1px; }
a[href] { color: #15c; }
h1, h2 { border-bottom: gray solid 1px; }
li { line-height: 1.7; }
</style>
</head>
<body>
<h1>今週のQiita Organizationの動き</h1>
EOS

  unless new_users.length == 0
    puts '<h2>新しいユーザ</h2>'
    puts '<ul>'
    new_users.each do |user|
      puts "<a href=\"http://qiita.com/#{ user.name }\">#{ user.name }</a>"
    end
    puts '</ul>'
  end

  unless new_items.length == 0
    puts '<h2>新しい投稿</h2>'
    puts '<ul>'

    new_items.each do |item|
      puts '<li>' +
        %(<a href="#{ item.url }">#{ item.title }</a>) +
        %((<a href="http://qiita.com/#{ item.username }">#{ item.username }</a>)) +
        '</li>'
    end

    puts '</ul>'
  end

  unless updated_items.length == 0
    puts '<h2>ストック、Tweet、はてブ、シェア</h2>'

    puts '<ul>'

    updated_items.each do |item|
      puts '<li>' +
        %(<a href="#{ item.url }">#{ item.title }</a> ) +
        %((<a href="http://qiita.com/#{ item.username }">#{ item.username }</a>) )
      puts %(<a href="#{ item.url }">ストック(+#{ item.like })</a>) if item.like > 0
      puts %(<a href="https://b.hatena.ne.jp/entry/#{ item.url }">はてブ(+#{ item.hatebu })</a> ) if item.hatebu > 0
      puts '</li>'
    end

    puts '</ul>'
  end
  puts <<-"EOS"
<hr>
</body>
</html>
EOS
end
