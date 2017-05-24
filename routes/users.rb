class Matcha < Sinatra::Application

  @@client.query("CREATE TABLE IF NOT EXISTS `users`
					   (
						 `id` int(11) NOT NULL AUTO_INCREMENT,
						 `email` varchar(255) NOT NULL,
						 `username` varchar(255) NOT NULL,
						 `firstname` varchar(255) NOT NULL,
						 `lastname` varchar(255) NOT NULL,
						 `password` varchar(255) NOT NULL,
						 `sexe` varchar(50) DEFAULT NULL,
						 `orientation` varchar(50) DEFAULT NULL,
						 `bio` longtext DEFAULT NULL,
						 `interest` longtext DEFAULT NULL,
						 `liked` longtext DEFAULT NULL,
						 `score` integer NOT NULL DEFAULT '0',
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

  # ====================================================  GET PAGE  ====================================================
  get "/users/sign_in" do
    if isConnected?
      redirect "/"
    end
    erb :"users/sign_in"
  end

  get "/users/sign_up" do
    if isConnected?
      redirect "/"
    end
    erb :"users/sign_up"
  end

  get "/users/registered/:id/:token" do
    result = []
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
      result << row
    end
    if result[0]["token"] == params[:token]
      time = Time.new
      @@client.query("UPDATE users SET token = NULL, confirmation_date = '#{time.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{params[:id]}")
      flash[:success] = "Votre compte a été activé avec succès"
    end
    redirect "/"
  end

  get "/users/forget" do
    erb :"users/forget"
  end

  get "/users/forget/:id/:token" do
    result = []
    time = Time.new
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}' AND remember_token IS NOT NULL AND remember_token = '#{params[:token]}' AND reset_date > DATE_SUB('#{time.strftime('%Y-%m-%d %H:%M:%S')}', INTERVAL 30 MINUTE)").each do |row|
      result << row
    end
    if !result.empty?
      erb :"users/reset"
    else
      redirect "/"
    end
  end

  get "/users/sign_out" do
    session[:auth] = nil
    flash[:success] = "Vous avez été déconnecté avec succès"
    redirect "/"
  end

  # ====================================================  POST PAGE  ===================================================

  post "/users/sign_in" do
    result = []
    @@client.query("SELECT * FROM users WHERE (username = '#{params[:UsernameOrEmail]}' OR email = '#{params[:usernameOrEmail]}') AND confirmation_date IS NOT NULL").each do |row|
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

  post '/users/sign_up' do
    if params[:email].empty? || params[:username].empty? || params[:firstname].empty? || params[:lastname].empty? || params[:password].empty? || params[:password_conf].empty?
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
    @@client.query("SELECT * FROM users WHERE email = '#{params[:email]}'").each do |row|
      result << row
    end
    if !result.empty?
      flash[:danger] = "l'adresse email est deja utilisé"
      redirect "/users/sign_up"
    end
    result = []
    @@client.query("SELECT * FROM users WHERE username = '#{params[:username]}'").each do |row|
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
    @@client.query("INSERT INTO users SET email = '#{@@coder.encode(params[:email])}', username = '#{@@coder.encode(params[:username])}', lastname = '#{@@coder.encode(params[:lastname])}', firstname = '#{@@coder.encode(params[:firstname])}', password = '#{Digest::SHA256.hexdigest(@@coder.encode(params[:password]))}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}', token = '#{token}'")
    flash[:success] = "Vous avez reçu un email afin de finaliser votre inscription"
    Pony.mail({
                  :to => 'you@example.com',
                  :via => :smtp,
                  :via_options => {
                      :address        => 'localhost',
                      :port           => '1025'
                  },
                  :subject => 'Matcha - Confirmation du compte',
                  :body => "Bonjour, afin de valider votre compte, merci de vous rendre sur ce lien: http://localhost:3000/users/registered/#{@@client.last_id}/#{token}"
              })
    redirect "/users/sign_in"
  end

  post "/users/forget" do
    if !params[:email].match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
      flash[:danger] = "L'email n'est pas valide"
      redirect "/users/forget"
    end
    result = []
    @@client.query("SELECT * FROM users WHERE email = '#{params[:email]}' AND confirmation_date IS NOT NULL").each do |row|
      result << row
    end
    if !result.empty?
      time = Time.new
      token = SecureRandom.hex(60)
      @@client.query("UPDATE users SET remember_token = '#{token}', reset_date ='#{time.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = '#{result[0]["id"]}'")
      flash[:success] = "Un email vous a été envoyé afin de reinitialisé votre mot de passe"
      Pony.mail({
                    :to => 'you@example.com',
                    :via => :smtp,
                    :via_options => {
                        :address        => 'localhost',
                        :port           => '1025'
                    },
                    :subject => 'Matcha - Confirmation du compte',
                    :body => "Bonjour, afin de reinitialiser votre mot de passe, merci de vous rendre sur ce lien: http://localhost:3000/users/forget/#{result[0]["id"]}/#{token}"
                })
      redirect "/users/sign_in"
    end
    flash[:danger] = "Cet email ne correspond à aucun utilisateur"
    redirect "/users/forget"
  end

  post "/users/forget/:id/:token" do
    if params[:password] != params[:password_conf]

      redirect "/users/forget/#{params[:id]}/#{params[:token]}"
    end
    result = []
    time = Time.new
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}' AND remember_token IS NOT NULL AND remember_token = '#{params[:token]}' AND reset_date > DATE_SUB('#{time.strftime('%Y-%m-%d %H:%M:%S')}', INTERVAL 30 MINUTE)").each do |row|
      result << row
    end
    if !result.empty?
      @@client.query("UPDATE users SET password = '#{Digest::SHA256.hexdigest(coder.encode(params[:password]))}', reset_date = NULL, remember_token = NULL")
      flash[:success] = "Votre mot de passe a été reinitialisé avec succès"
    end
    redirect "/"
  end
end