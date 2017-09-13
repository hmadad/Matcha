class Matcha < Sinatra::Application

  # Root
  get "/" do
    if !isConnected?
      redirect "/users/sign_in"
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE sexe = '#{session[:auth]['orientation']}'").each do |row|
      @result << row
    end
    @nb = []
    @@client.query("SELECT COUNT(notifications.id) as nb FROM notifications WHERE user_notified = '#{session[:auth]['id']}' AND notifications.vu = '0'").each do |row|
      @nb << row
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