class Matcha < Sinatra::Application

  # ====================================================  GET PAGE  ====================================================

  get "/blocked" do
    if !isConnected?
      redirect "/"
    end
    @result = []
    @@client.query("SELECT * FROM blocked WHERE user_id = '#{session[:auth]["id"]}'").each do |row|
      @result << row
    end
    if !request.websocket?
      erb :"/users/blocked"
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

  post "/blocked/:id" do
    if !isConnected?
      redirect "/"
    end
    if params[:id] == session[:auth]["id"]
      flash["danger"] = "Vous ne pouvez pas vous bloquer vous même"
      redirect "/"
    end
    @user = []
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
      @user << row
    end
    if @user.empty?
      flash["danger"] = "L'utilisateur en question n'existe pas !"
      redirect "/"
    end
    @blocked = []
    @@client.query("SELECT * FROM blocked WHERE user_id = '#{session[:auth]["id"]}' AND user_blocked = '#{params[:id]}'").each do |row|
      @blocked << row
    end
    if !@blocked.empty?
      flash["danger"] = "L'utilisateur en question est deja bloqué !"
      redirect "/"
    end
    time = Time.new
    @@client.query("INSERT INTO blocked SET user_id = '#{session[:auth]["id"]}', user_blocked = '#{params[:id]}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    conv = findConv(params[:id])
    @@client.query("UPDATE conversations SET view = '0' WHERE id = '#{conv['id']}'")
    flash["success"] = "Vous venez de bloquer #{@user[0]["username"]}"
    redirect "/"
  end

  post "/unblock/:id" do
    if !isConnected?
      redirect "/"
    end
    if params[:id] == session[:auth]["id"]
      flash["danger"] = "Vous ne pouvez pas vous débloquer vous même"
      redirect "/"
    end
    @user = []
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
      @user << row
    end
    if @user.empty?
      flash["danger"] = "L'utilisateur en question n'existe pas !"
      redirect "/"
    end
    @blocked = []
    @@client.query("SELECT * FROM blocked WHERE user_id = '#{session[:auth]["id"]}' AND user_blocked = '#{params[:id]}'").each do |row|
      @blocked << row
    end
    if @blocked.empty?
      flash["danger"] = "L'utilisateur en question est n'est actuellement pas bloqué !"
      redirect "/"
    end
    time = Time.new
    @@client.query("DELETE FROM blocked WHERE user_id = '#{session[:auth]["id"]}' AND user_blocked = '#{params[:id]}'")
    conv = findConv(params[:id])
    @@client.query("UPDATE conversations SET view = '1' WHERE id = '#{conv['id']}'")
    flash["success"] = "Vous venez de débloquer #{@user[0]["username"]}"
    redirect "/"
  end

  post "/reported/:id" do
    if !isConnected?
      redirect "/"
    end
    if params[:id] == session[:auth]["id"]
      flash["danger"] = "Vous ne pouvez pas vous reporter vous même"
      redirect "/"
    end
    @user = []
    @@client.query("SELECT * FROM users WHERE id = '#{params[:id]}'").each do |row|
      @user << row
    end
    if @user.empty?
      flash["danger"] = "L'utilisateur en question n'existe pas !"
      redirect "/"
    end
    @blocked = []
    @@client.query("SELECT * FROM blocked WHERE user_id = '#{session[:auth]["id"]}' AND user_blocked = '#{params[:id]}'").each do |row|
      @blocked << row
    end
    if !@blocked.empty?
      flash["danger"] = "L'utilisateur en question est deja bloqué !"
      redirect "/"
    end
    time = Time.new
    @@client.query("INSERT INTO blocked SET user_id = '#{session[:auth]["id"]}', user_blocked = '#{params[:id]}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    @@client.query("UPDATE users SET report = report + 1 WHERE id = '#{params[:id]}'")
    flash["success"] = "Vous venez de bloquer #{@user[0]["username"]}"
    redirect "/"
  end

end