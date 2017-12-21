#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'qiita_information'
require 'json'

data = QiitaInformation::Organization.new('access').users.map do |user|
  items = user.items.map do |item|
    {
      title: item.title,
      url: item.url,
      date: item.date,
      like: item.like,
      hatebu: item.hatebu
    }
  end

  {
    user: user.name,
    items: items
  }
end

puts JSON.pretty_generate(data)
