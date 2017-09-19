class Matcha < Sinatra::Application






  # ====================================================  GET PAGE  ====================================================
  get "/users/profile" do
    if !isConnected?
      redirect "/"
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id = '#{session[:auth]["id"]}'").each do |row|
      @result << row
    end
    if !request.websocket?
      erb :"users/profile"
    else
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end
        ws.onmessage do |msg|
          EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    end
  end

  get "/users/profile/:id" do
    if !isConnected?
      redirect "/"
    end
    if isBlocked?(params[:id])
      redirect "/"
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
      @result << row
    end
    @result = @result[0]
    check = []
    @@client.query("SELECT * FROM notifications WHERE user_notified = '#{params[:id]}' AND user_id = '#{session[:auth]["id"]}' AND vu = '0'").each do |row|
      check << row
    end
    if check.empty? && params[:id] != session[:auth]["id"]
      time = Time.new
      id = session[:auth]["id"]
      @@client.query("INSERT INTO notifications SET user_id = '#{id}', user_notified = '#{params[:id]}', message = '#{session[:auth]["username"]}, à regardé votre page de profile', type = '3', vu = '0', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    end
    if !request.websocket?
      erb :"users/user"
    else
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end
        ws.onmessage do |msg|
          EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    end
  end

  # ====================================================  POST PAGE  ===================================================
  post "/users/profile" do
    if !isConnected?
      redirect "/"
    end
    if params[:email].empty? || params[:username].empty? || params[:firstname].empty? || params[:lastname].empty?
      flash[:danger] = "Tout les champs avec une étoile sont obligatoires"
      redirect "/users/profile"
    end
    if !params[:email].match(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
      flash[:danger] = "L'email n'est pas valide"
      redirect "/users/profile"
    end
    if !params[:username].match(/^[a-zA-Z0-9_]+$/)
      flash[:danger] = "Le nom d'utilisateur n'est pas valide"
      redirect "/users/profile"
    end
    result = []
    @@client.query("SELECT * FROM users WHERE email = '#{params[:email]}'").each do |row|
      result << row
    end
    if !result.empty?
      if session[:auth]["id"] != result[0]["id"]
        flash[:danger] = "l'adresse email est deja utilisé"
        redirect "/users/profile"
      end
    end
    result = []
    @@client.query("SELECT * FROM users WHERE username = '#{params[:username]}'").each do |row|
      result << row
    end
    if !result.empty?
      if session[:auth]["id"] != result[0]["id"]
        flash[:danger] = "Le nom d'utilisateur est deja utilisé"
        redirect "/users/profile"
      end
    end
    if !params[:location].nil? && !params[:location].match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
      flash[:danger] = "Code postal invalide"
      redirect "/users/profile"
    end
    if params[:location].nil?
      params[:location] = 0
    end
    if params[:age] && (params[:age].to_i < 18 || params[:age].to_i > 120)
      flash[:danger] = "Age invalide"
      redirect "/users/profile"
    end
    if !params[:sexe].nil? && params[:sexe] != "Homme" && params[:sexe] != "Femme"
      flash[:danger] = "Sexe invalide"
      redirect "/users/profile"
    end
    if !params[:orientation].nil? && params[:orientation] != "Homme" && params[:orientation] != "Femme" && params[:orientation] != "Both"
      flash[:danger] = "Orientation invalide"
      redirect "/users/profile"
    end
    if params[:bio].length > 255
      flash[:danger] = "Biographie trop longue"
      redirect "/users/profile"
    end
    if !params[:interest].nil?
      split = params[:interest].split(', ')
      i = 0
      split.each do |row|
        row.strip!
        split[i] = row.gsub(' ', '')
        if row[0] != '#'
          flash[:danger] = "Le format d'un de vos tag est invalide. Exemple: #tags1, #tags2"
          redirect "/users/profile"
        else
          if row[1, row.length].include? "#"
            flash[:danger] = "le tag ne peu pas contenir de '#' sauf pour commencer le tag"
            redirect "/users/profile"
          end
          result = []
          @@client.query("SELECT * FROM tags WHERE name = '#{@@coder.encode(row)}'").each do |row|
            result << row
          end
          if result.empty?
            time = Time.new
            id = session[:auth]["id"]
            @@client.query("INSERT INTO tags SET user_id = '#{id}', name = '#{@@coder.encode(row)}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
          end
        end
        i += 1
      end
      params[:interest] = split.join(', ')
    end
    if params[:profile] || params[:image2] || params[:image3] || params[:image4] || params[:image5]
      extension = ["jpeg", "jpg", "png"]

      root = ::File.dirname(__FILE__).chomp("routes") + "public/images/" + session[:auth]['id'].to_s

      Dir.mkdir(root) unless File.exists?(root)

      if params[:profile]
        profile = params[:profile][:filename]
        f_profile = params[:profile][:tempfile]
        path_profile = root + "/" + profile
        name_p = profile.prepend("/images/#{session[:auth]['id']}/")
      end
      if params[:image2]
        image2 = params[:image2][:filename]
        f_image2 = params[:image2][:tempfile]
        path_image2 = root + "/" + image2
        name_2 = image2.prepend("/images/#{session[:auth]['id']}/")
      end
      if params[:image3]
        image3 = params[:image3][:filename]
        f_image3 = params[:image3][:tempfile]
        path_image3 = root + "/" + image3
        name_3 = image3.prepend("/images/#{session[:auth]['id']}/")
      end
      if params[:image4]
        image4 = params[:image4][:filename]
        f_image4 = params[:image4][:tempfile]
        path_image4 = root + "/" + image4
        name_4 = image4.prepend("/images/#{session[:auth]['id']}/")
      end
      if params[:image5]
        image5 = params[:image5][:filename]
        f_image5 = params[:image5][:tempfile]
        path_image5 = root + "/" + image5
        name_5 = image5.prepend("/images/#{session[:auth]['id']}/")
      end

      if (verify_extensions(profile) == 0) || (verify_extensions(image2) == 0) || (verify_extensions(image3) == 0) || (verify_extensions(image4) == 0) || (verify_extensions(image5) == 0)
        flash[:danger] = 'YOU SHALL NOT PASS !'
        redirect "/users/profile"
      else
        if f_profile
          File.open(path_profile, 'wb') do |f|
            f.write(f_profile.read)
          end
          @@client.query("UPDATE users SET profile = '#{name_p}' WHERE id = '#{session[:auth]['id']}'")
        end

        if f_image2
          File.open(path_image2, 'wb') do |f|
            f.write(f_image2.read)
          end
          @@client.query("UPDATE users SET image2 = '#{name_2}' WHERE id = '#{session[:auth]['id']}'")
        end

        if f_image3
          File.open(path_image3, 'wb') do |f|
            f.write(f_image3.read)
          end
          @@client.query("UPDATE users SET image3 = '#{name_3}' WHERE id = '#{session[:auth]['id']}'")
        end

        if f_image4
          File.open(path_image4, 'wb') do |f|
            f.write(f_image4.read)
          end
          @@client.query("UPDATE users SET image4 = '#{name_4}' WHERE id = '#{session[:auth]['id']}'")
        end

        if f_image5
          File.open(path_image5, 'wb') do |f|
            f.write(f_image5.read)
          end
          @@client.query("UPDATE users SET image5 = '#{name_5}' WHERE id = '#{session[:auth]['id']}'")
        end

        files = Dir[root += "/*"]
        files_in_db = @@client.query("SELECT profile, image2, image3, image4, image5 FROM users WHERE id = '#{session[:auth]['id']}'").each(:as.to_s => :array)

        tab = []
        if files_in_db[0]['profile']
          tab << files_in_db[0]['profile'].prepend(File.dirname(__FILE__).chomp("routes") + "public")
        end

        if files_in_db[0]['image2']
          tab << files_in_db[0]['image2'].prepend(File.dirname(__FILE__).chomp("routes") + "public")
        end

        if files_in_db[0]['image3']
          tab << files_in_db[0]['image3'].prepend(File.dirname(__FILE__).chomp("routes") + "public")
        end

        if files_in_db[0]['image4']
          tab << files_in_db[0]['image4'].prepend(File.dirname(__FILE__).chomp("routes") + "public")
        end

        if files_in_db[0]['image5']
          tab << files_in_db[0]['image5'].prepend(File.dirname(__FILE__).chomp("routes") + "public")
        end

        compared = files - tab
        compared.each do |img|
          File.delete(img)
        end
        flash[:success] = 'Vos images on été mis a jour avec succès'
      end
    end
    id = session[:auth]["id"]
    @@client.query("UPDATE users SET email = '#{@@coder.encode(params[:email])}', username = '#{@@coder.encode(params[:username])}', lastname = '#{@@coder.encode(params[:lastname])}', firstname = '#{@@coder.encode(params[:firstname])}', location = '#{@@coder.encode(params[:location])}', age = '#{@@coder.encode(params[:age].to_i)}', sexe = '#{@@coder.encode(params[:sexe])}', orientation = '#{@@coder.encode(params[:orientation])}', bio = '#{@@coder.encode(params[:bio])}', interest = '#{@@coder.encode(params[:interest])}' WHERE id = '#{id}'")
    result = []
    @@client.query("SELECT * FROM users WHERE id = '#{session[:auth]['id']}'").each do |row|
      result << row
    end
    session[:auth] = result[0]
    flash[:success] = 'Vos informations ont étaient mis à jour avec succès'
    redirect "/users/profile"
  end
end