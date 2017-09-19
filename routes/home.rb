class Matcha < Sinatra::Application

  # Root
  get "/" do
    if !isConnected?
      redirect "/users/sign_in"
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
    @@client.query("SELECT * FROM users WHERE (sexe = '#{orientation}') AND id NOT LIKE '#{session[:auth]['id']}'").each do |row|
      @result << row
    end
    @nb = []
    @@client.query("SELECT COUNT(notifications.id) as nb FROM notifications WHERE user_notified = '#{session[:auth]['id']}' AND notifications.vu = '0'").each do |row|
      @nb << row
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation(request.ip)
    end
    if !request.websocket?
      erb :index
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

end