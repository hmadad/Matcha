# encoding: utf-8
require 'rubygems'
require 'mysql2'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pony'
require 'sinatra/flash'
require 'htmlentities'
require 'securerandom'
enable :sessions

class Matcha < Sinatra::Application

  @@client = Mysql2::Client.new(:host => "localhost", :username => "root")
  @@client.query("CREATE DATABASE IF NOT EXISTS matcha")

  @@client = Mysql2::Client.new(:host => "localhost", :username => "root", :database => "matcha", :encoding => 'utf8',)

  @@coder = HTMLEntities.new

  def isConnected?
    if !session[:auth].nil?
      return true
    else
      return false
    end
  end

end

require_relative 'routes/init'