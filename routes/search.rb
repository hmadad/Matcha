class Matcha < Sinatra::Application

  # ====================================================  GET PAGE  ====================================================

  get "/search" do
    if !isConnected?
      redirect "/"
    end
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    elsif  session[:auth]['orientation'] == "Both" && session[:auth]['sexe'] && !session[:auth]['sexe'].empty?
      orientation = "Femme' OR sexe = 'HOMME') AND (orientation = '#{session[:auth]['sexe']}"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id NOT LIKE '#{session[:auth]['id']}' AND (sexe = '#{orientation}') ORDER BY created_at DESC").each do |row|
      @result << row
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation(request.ip)
    end
    @km = {}
    @km = "illimite"
    if !request.websocket?
      erb :"search"
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

  get "/search/:min/:max/:km/:order/" do
    if !isConnected?
      redirect "/"
    end
    @params = params
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    elsif  session[:auth]['orientation'] == "Both" && session[:auth]['sexe'] && !session[:auth]['sexe'].empty?
      orientation = "Femme' OR sexe = 'HOMME') AND (orientation = '#{session[:auth]['sexe']}"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    if params[:order] == "score"
      order = "score"
    else
      order = "created_at"
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation(request.ip)
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id NOT LIKE '#{session[:auth]['id']}' AND sexe = '#{orientation}' AND sexe = '#{orientation}' AND age BETWEEN '#{params[:min]}' AND '#{params[:max]}' ORDER BY #{order} DESC").each do |row|
      @result << row
    end
    if params[:order] == "tags"
      @result.each do |row|
        all_user = session[:auth]["interest"].split(", ")
        all_other = row["interest"].split(", ")
        comun = all_user & all_other
        taille = comun.length
        row = {:user => row, :lenght => taille}
      end
      @result.sort_by! do |item|
        item[:lenght]
      end
      @result = @result.reverse
    elsif params[:order] == "location"
      @result.each do |row|
        if row["location"] && row["location"].to_i != 0
          other_coords = loc(row["location"].to_i)
          distance = distance(@coord[0].to_f, @coord[1].to_f, other_coords[0].to_f, other_coords[1].to_f)
          row = {:user => row, :distance => distance}
        else
          row = nil
        end
      end
      @result.sort_by! do |item|
        item[:distance]
      end
      @result = @result.reverse
    end
    if !request.websocket?
      erb :"search"
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

  get "/search/:min/:max/:km/:order/:search" do
    if !isConnected?
      redirect "/"
    end
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    elsif  session[:auth]['orientation'] == "Both" && session[:auth]['sexe'] && !session[:auth]['sexe'].empty?
      orientation = "Femme' OR sexe = 'HOMME') AND (orientation = '#{session[:auth]['sexe']}"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    if params[:order] == "score"
      order = "score"
    else
      order = "created_at"
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation(request.ip)
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE interest REGEXP '##{params[:search]}(,|$)' AND id NOT LIKE '#{session[:auth]['id']}' AND sexe = '#{orientation}' AND age BETWEEN '#{params[:min]}' AND '#{params[:max]}' ORDER BY #{order} DESC").each do |row|
      @result << row
    end
    if params[:order] == "tags"
      @result.each do |row|
        comun = all_user & all_other
        taille = comun.length
        row = {:user => row, :lenght => taille}
      end
      @result.sort_by! do |item|
        item[:lenght]
      end
      @result = @result.reverse
    end
    if !request.websocket?
      erb :"search"
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

  post "/search" do
    if !isConnected?
      redirect "/"
    end
    if params[:search][0] == '#'
      params[:search] = params[:search][1..params[:search].length]
    end
    if params[:min].empty?
      params[:min] = 18
    end
    if params[:max].empty?
      params[:max] = 120
    end
    if params[:km].empty?
      params[:km] = "illimite"
    end
    if params[:order].empty?
      params[:order] = "score"
    end
    redirect "/search/#{params[:min]}/#{params[:max]}/#{params[:km]}/#{params[:order]}/#{params[:search]}"
  end

end