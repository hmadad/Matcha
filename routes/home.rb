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
    @@client.query("SELECT COUNT(id) as nb FROM notifications WHERE user_notified = '#{session[:auth]['id']}' AND vu = '0'").each do |row|
      @nb << row
    end
    erb :index
  end

  get "/testou" do
      url = 'http://localhost:8080/'
      uri = URI(url)
      response = Net::HTTP.get(uri)
      JSON.parse(response)
      tab = eval(response)
      tab.inspect
  end

end