class Matcha < Sinatra::Application

  # ====================================================  GET PAGE  ====================================================

  get "/search" do
    erb :"search"
  end

  get "/search/:search" do
    @result = []
    @@client.query("SELECT * FROM users WHERE interest REGEXP '##{params[:search]}(,|$)' AND id NOT LIKE '#{session[:auth]['id']}'").each do |row|
      @result << row
    end
    erb :"search"
  end

  # ====================================================  POST PAGE  ===================================================

  post "/search" do
    redirect "/search/#{params[:search]}"
  end

end