# myapp.rb
require 'rubygems'
require 'mysql2'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pony'
require 'sinatra/flash'
require 'htmlentities'
require 'securerandom'
enable :sessions


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
						 `created_at` DATETIME NOT NULL,
						 `confirmation_date` DATETIME,
						 `token` varchar(60) DEFAULT NULL,
						 `remember_token` varchar(255) DEFAULT NULL,
						 `image` text DEFAULT NULL,
						 `mode` integer NOT NULL DEFAULT '0',
						 `ip` varchar(255) DEFAULT NULL,
						 PRIMARY KEY (`id`)
					   ) ENGINE=MyISAM DEFAULT CHARSET=utf8;")

coder = HTMLEntities.new

def isConnected()
  if session[:auth].nil?
    return false
  end
    return true
end

# Root
get "/" do
  if isConnected == false
    redirect "/users/sign_in"
  end
  erb :index
end

# Users

get "/users/sign_in" do
  if isConnected == true
    redirect "/"
  end
  erb :"users/sign_in"
end

post "/users/sign_in" do
  result = []
  client.query("SELECT * FROM users WHERE (username = '#{params[:UsernameOrEmail]}' OR email = '#{params[:usernameOrEmail]}') AND confirmation_date IS NOT NULL").each do |row|
    result << row
  end
  if !result.empty?
    if Digest::SHA256.hexdigest(params[:password]) == result[0]["password"]
      session[:auth] = result[0]
      flash[:success] = "Connexion reussi"
      redirect "/"
    end
  end
  flash[:danger] = "Nom d'utilisateur / Email ou mot de passe incorrect"
  redirect "/users/sign_in"
end

get "/users/sign_up" do
  if isConnected == true
    redirect "/"
  end
  erb :"users/sign_up"
end

post '/users/sign_up' do
  if params[:email].empty? && params[:username].empty?
    flash[:danger] = "Tout les champs sont obligatoires"
    redirect "/users/sign_up"
  end
  if !params[:email].match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
    flash[:danger] = "L'email n'est pas valide"
    redirect "/users/sign_up"
  end
  if !params[:username].match(/^[a-zA-Z0-9_]+$/)
    flash[:danger] = "Le nom d'utilisateur n'est pas valide"
    redirect "/users/sign_up"
  end
  result = []
  client.query("SELECT * FROM users WHERE email = '#{params[:email]}'").each do |row|
    result << row
  end
  if !result.empty?
    flash[:danger] = "l'adresse email est deja utilisé"
    redirect "/users/sign_up"
  end
  result = []
  client.query("SELECT * FROM users WHERE username = '#{params[:username]}'").each do |row|
    result << row
  end
  if !result.empty?
    flash[:danger] = "Le nom d'utilisateur est deja utilisé"
    redirect "/users/sign_up"
  end
  if params[:password] != params[:password_conf]
    flash[:danger] = "Les mots de passe ne sont pas identiques"
    redirect "/users/sign_up"
  end
  time = Time.new
  token = SecureRandom.hex(60)
  client.query("INSERT INTO users SET email = '#{coder.encode(params[:email])}', username = '#{coder.encode(params[:username])}', lastname = '#{coder.encode(params[:lastname])}', firstname = '#{coder.encode(params[:firstname])}', password = '#{Digest::SHA256.hexdigest(coder.encode(params[:password]))}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}', token = '#{token}'")
  flash[:success] = "Votre inscription c'est effectué avec succès"
  Pony.mail({
                :to => 'you@example.com',
                :via => :smtp,
                :via_options => {
                    :address        => 'localhost',
                    :port           => '1025'
                },
                :subject => 'Matcha - Confirmation du compte',
                :body => "Bonjour, afin de valider votre compte, merci de vous rendre sur ce lien: http://localhost:4567/users/registered/#{client.last_id}/#{token}"
            })
  redirect "/users/sign_in"
end

get "/users/registered/:id/:token" do
  result = []
  client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
    result << row
  end
  if result[0]["token"] == params[:token]
    time = Time.new
    client.query("UPDATE users SET token = NULL, confirmation_date = '#{time.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{params[:id]}")
    flash[:success] = "Votre compte a été activé avec succès"
  end
  redirect "/"
end

get "/users/sign_out" do
  session[:auth] = nil
  flash[:success] = "Vous avez été déconnecté avec succès"
  redirect "/"
end

get '/test/:name' do
  SecureRandom.hex(60)
end

# Other
