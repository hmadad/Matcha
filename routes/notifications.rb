class Matcha < Sinatra::Application


  # ====================================================  GET PAGE  ====================================================

  get "/notifications" do
    @result = []
    @@client.query("SELECT * FROM notifications WHERE user_notified = '#{session[:auth]["id"]}' ORDER BY created_at DESC").each do |row|
      @result << row
    end
    erb :"notifications"
  end

  # ====================================================  POST PAGE  ===================================================

end