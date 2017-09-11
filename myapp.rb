# encoding: utf-8
require 'rubygems'
require 'mysql2'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pony'
require 'sinatra/flash'
require 'htmlentities'
require 'securerandom'
require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'json'
require 'sinatra'
require 'sinatra-websocket'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

set :server, 'thin'
set :sockets, []
enable :sessions

class Matcha < Sinatra::Application

  @@client = Mysql2::Client.new(:host => "localhost", :username => "root")
  @@client.query("CREATE DATABASE IF NOT EXISTS matcha")

  @@client = Mysql2::Client.new(:host => "localhost", :username => "root", :database => "matcha", :encoding => 'utf8')

  @@client.query("CREATE TABLE IF NOT EXISTS `users`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `email` varchar(255) NOT NULL,
						 `username` varchar(255) NOT NULL,
						 `firstname` varchar(255) NOT NULL,
						 `lastname` varchar(255) NOT NULL,
						 `password` varchar(255) NOT NULL,
             `location` integer DEFAULT NULL,
             `age` varchar(50) DEFAULT NULL,
						 `sexe` integer DEFAULT NULL,
						 `orientation` varchar(50) DEFAULT NULL,
						 `bio` longtext DEFAULT NULL,
						 `interest` longtext DEFAULT NULL,
						 `liked` longtext DEFAULT NULL,
						 `score` integer NOT NULL DEFAULT '0',
             `vu` integer NOT NULL DEFAULT '0',
						 `created_at` DATETIME NOT NULL,
						 `confirmation_date` DATETIME,
						 `token` varchar(255) DEFAULT NULL,
						 `remember_token` varchar(255) DEFAULT NULL,
             `reset_date` DATETIME,
						 `image` text DEFAULT NULL,
						 `mode` integer NOT NULL DEFAULT '0',
						 `ip` varchar(255) DEFAULT NULL,
             `profile` longtext DEFAULT NULL,
             `image2` longtext DEFAULT NULL,
             `image3` longtext DEFAULT NULL,
             `image4` longtext DEFAULT NULL,
             `image5` longtext DEFAULT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `tags`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `user_id` int(11) NOT NULL,
						 `name` varchar(255) NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `likes`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `user_id` int(11) NOT NULL,
						 `user_liked` int(11) NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `notifications`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `user_id` int(11) NOT NULL,
             `user_notified` int(11) NOT NULL,
						 `message` varchar(255) NOT NULL,
             `type` int(11) NOT NULL,
             `vu` int(11) NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `messages`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `conv_id` int(11) NOT NULL,
						 `user_id` int(11) NOT NULL,
             `message` longtext NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `conversations`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `user_id1` int(11) NOT NULL,
             `user_id2` int(11) NOT NULL,
             `view` int(11) NOT NULL,
             `last_message` DATETIME NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@client.query("CREATE TABLE IF NOT EXISTS `blocked`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `user_id` int(11) NOT NULL,
             `user_blocked` int(11) NOT NULL,
						 `created_at` DATETIME NOT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

  @@coder = HTMLEntities.new

  def isConnected?
    if !session[:auth].nil?
      return true
    else
      return false
    end
  end

  def verify_extensions(image)
    if !image
      return 1
    end
    extension = ['jpeg', 'jpg', 'png']
    tab = image.to_s.split(".")
    if tab.count > 2
      return 0
    elsif extension.include? tab[1] == false
      return 0
    end
    return 1
  end

  def isLiked?(id)
    result = []
    @@client.query("SELECT * FROM likes WHERE user_id = '#{session[:auth]["id"]}' AND user_liked = '#{id}'").each do |row|
      result << row
    end
    if !result.empty?
      return true
    end
    return false
  end

  def findUser(id)
    result = []
    @@client.query("SELECT * FROM users WHERE id = '#{id}'").each do |row|
      result << row
    end
    return result
  end

  def stalkLocation
    url = 'http://freegeoip.net/json/'
    uri = URI(url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
    tab = eval(response)
    lat = tab[:latitude]
    lon = tab[:longitude]
    return [lat,lon]
  end

  def loc(code)
    if code.to_s.length == 1
      nb = "0"
      nb += code.to_s
      nb += "000"
    elsif code.to_s.length == 2
      nb = code.to_s
      nb += "000"
    end
    if nb == "75000"
      nb = "75001"
    end
    url = "http://api.zippopotam.us/fr/" + nb
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    new_lat = data["places"][0]['latitude']
    new_lng = data["places"][0]['longitude']
    return [new_lat,new_lng]
  end

  def distance(lat_a_degre, lon_a_degre, lat_b_degre, lon_b_degre)

    earth_rayon = 6378000 # Rayon de la terre en mètre

    lat_a = deg2rad(lat_a_degre)
    lon_a = deg2rad(lon_a_degre)
    lat_b = deg2rad(lat_b_degre)
    lon_b = deg2rad(lon_b_degre)

    result = earth_rayon * (Math::PI/2 - Math::asin( Math::sin(lat_b) * Math::sin(lat_a) + Math::cos(lon_b - lon_a) * Math::cos(lat_b) * Math::cos(lat_a)))
    return result / 1000
  end

  def deg2rad(value)
    return (Math::PI * value)/180;
  end

  def isBlocked?(id)
    result = []
    @@client.query("SELECT * FROM blocked WHERE (user_id = '#{session[:auth]["id"]}' OR user_id = '#{id}') AND (user_blocked = '#{id}' OR user_blocked = '#{session[:auth]["id"]}')").each do |row|
      result << row
    end
    if !result.empty?
      return true
    end
    return false
  end

end

require_relative 'routes/init'