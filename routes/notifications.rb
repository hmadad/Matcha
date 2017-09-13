class Matcha < Sinatra::Application


  # ====================================================  GET PAGE  ====================================================

  get "/notifications" do
    if !isConnected?
      redirect "/"
    end
    @result = []
    @@client.query("SELECT * FROM notifications WHERE user_notified = '#{session[:auth]["id"]}' ORDER BY created_at DESC").each do |row|
      @result << row
    end
    if !request.websocket?
      erb :"notifications"
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

end