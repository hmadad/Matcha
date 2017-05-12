# myapp.rb
require 'rubygems'
require 'mysql2'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pony'

client = Mysql2::Client.new(:host => "localhost", :username => "root")
db = client.query("CREATE DATABASE IF NOT EXISTS matcha")

client = Mysql2::Client.new(:host => "localhost", :username => "root", :database => "matcha", :encoding => 'utf8',)
users = client.query("CREATE TABLE IF NOT EXISTS `users`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `email` varchar(255) NOT NULL,
						 `username` varchar(255) NOT NULL,
						 `firstname` varchar(255) NOT NULL,
						 `lastname` varchar(255) NOT NULL,
						 `password` varchar(255) NOT NULL,
						 `sexe` varchar(50) DEFAULT NULL,
						 `orientation` varchar(50) DEFAULT NULL,
						 `bio` text DEFAULT NULL,
						 `interest` text DEFAULT NULL,
						 `liked` text DEFAULT NULL,
						 `score` integer NOT NULL DEFAULT '0',
						 `creation_date` DATETIME NOT NULL,
						 `confirmation_date` DATETIME,
						 `token` varchar(255) DEFAULT NULL,
						 `remember_token` varchar(255) DEFAULT NULL,
						 `image` text DEFAULT NULL,
						 `mode` integer NOT NULL DEFAULT '0',
						 `ip` varchar(255) DEFAULT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")


# Root
get "/" do
  erb :index
end

# Users
get "/users/sign_up" do
  erb :"users/sign_up"
end

get "/users/sign_in" do
  erb :"users/sign_in"
end

post '/users/sign_up' do
	params.inspect
	client.query("INSERT INTO users SET email = '#{params[:email]}', username = '#{params[:username]}', firstname = '#{params[:firstname]}', lastname = '#{params[:lastname]}', password = '#{params[:password]}', creation_date = '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}';")
	Pony.mail(:to => "#{params[:email]}", :from => 'no-reply@matcha.com', :subject => 'Confirmer votre compte', :body => '')
	Pony.mail(:to => "#{params[:email]}", :html_body => '<h1>Matcha - Confimer votre compte</h1>', :body => "In case you can't read html, Hello there.")
	Pony.mail(:to => "#{params[:email]}", :cc => '', :from => 'no-reply@matcha.com', :subject => 'Confirmer votre compte', :body => 'Matcha')

	# redirect "/users/sign_in"
end

# Other
