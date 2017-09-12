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
    erb :index
  end

  get "/testou" do
    idconv = 1
      result = []
      @@client.query("SELECT COUNT(id) FROM messages WHERE conv_id = '#{idconv}' AND user_id NOT LIKE '#{session[:auth]["id"]}' AND vu = '0'").each do |row|
        result << row
      end
      result[0]["COUNT(id)"].inspect
  end

end