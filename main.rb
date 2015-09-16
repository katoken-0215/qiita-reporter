#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'

require 'nokogiri'
require 'faraday'
require 'json'
require 'date'

URL_QIITA_ORGANIZATION = 'http://qiita.com/organizations/access/members'
URL_HATEBU_API = 'http://b.hatena.ne.jp/entry/json/'
URL_TWITTER_API = 'http://urls.api.twitter.com/1/urls/count.json?url='
URL_FACEBOOK_SHARE_API = 'http://graph.facebook.com/?id='

class Organization
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def users
    body = Faraday.get(URL_QIITA_ORGANIZATION).body
    Nokogiri::HTML(body).css('a.organizationMemberList_userName').map { |username| User.new(username.text) }
  end
end

class User
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def items
    user_page_url = "http://qiita.com/#{@name}/items"
    body = Faraday.get(user_page_url).body
    Nokogiri::HTML(body).css('article.publicItem').map do |node|
      a = node.at_css('h1 a')
      title = a.text
      url = "http://qiita.com#{a['href']}"
      Item.new(title, url)
    end
  end
end

class Item
  attr_reader :title

  def initialize(title, url)
    @title = title
    @url = url
  end

  def date
    body = Faraday.get(@url).body
    time = Nokogiri::HTML(body).at_css('time[itemprop=datePublished]')
    Date.parse(time.content)
  end

  def stock
    body = Faraday.get(@url).body
    Nokogiri::HTML(body).at_css('span.js-stocksCount').text.strip.to_i
  end

  def hatebu
    body = Faraday.get(URL_HATEBU_API + @url).body
    if body != 'null'
      JSON.parse(body)['count'].to_i
    else
      0
    end
  end

  def tweet
    body = Faraday.get(URL_TWITTER_API + @url).body
    JSON.parse(body)['count']
  end

  def share
    body = Faraday.get(URL_FACEBOOK_SHARE_API + @url).body
    JSON.parse(body)['shares'] || 0
  end

  def to_hash
    {
      title: @title,
      url: @url,
      date: date,
      stock: stock,
      hatebu: hatebu,
      tweet: tweet,
      share: share
    }
  end
end

all_items = Organization.new('access').users.map do |user|
  { user: user.name, items: user.items.map(&:to_hash) }
end

puts JSON.pretty_generate(all_items)
