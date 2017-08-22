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
    erb :"/users/blocked"
  end

  # ====================================================  POST PAGE  ===================================================

  post "/blocked/:id" do
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
    flash["success"] = "Vous venez de bloquer #{@user[0]["username"]}"
    redirect "/"
  end

  post "/unblock/:id" do
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
    flash["success"] = "Vous venez de débloquer #{@user[0]["username"]}"
    redirect "/"
  end

end