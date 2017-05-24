class Matcha < Sinatra::Application

  # Root
  get "/" do
    @result = []
    @@client.query("SELECT * FROM users WHERE sexe = '#{session[:auth]['orientation']}'").each do |row|
      @result << row
    end
    erb :index
  end

end