class Matcha < Sinatra::Application



  # ====================================================  GET PAGE  ====================================================

  get "/messages" do
    @all = []
    @ok = 0
    @@client.query("SELECT * FROM conversations WHERE (user_id1 = #{session[:auth]['id']} OR user_id2 = #{session[:auth]['id']}) AND view = 1 ORDER BY last_message DESC").each do |row|
      @all << row
    end
    @all.each do |row|
      if row["view"] == 1
        @ok = 1
      end
    end
    erb :"messages/home_message"
  end

  get "/messages/:id" do
    @result = []
    @@client.query("SELECT * FROM conversations WHERE id = '#{params[:id]}'").each do |row|
      @result << row
    end
    if @result.empty?
      redirect :"/messages"
    end
    if (@result[0]["user_id1"] != session[:auth]["id"] && @result[0]["user_id2"] != session[:auth]["id"]) || @result[0]["view"] == 0
      redirect "/messages"
    end
    @messages = []
    @@client.query("SELECT * FROM messages WHERE conv_id = '#{params[:id]}'").each do |row|
      @messages << row
    end
    if @result[0]["user_id1"] == session[:auth]["id"]
      @other_user = findUser(@result[0]["user_id2"].to_i)
    else
      @other_user = findUser(@result[0]["user_id1"].to_i)
    end
    if !request.websocket?
      erb :"messages/messages"
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

  post "/messages/:id" do
    @result = []
    @@client.query("SELECT * FROM conversations WHERE id = '#{params[:id]}'").each do |row|
      @result << row
    end
    if (@result[0]["user_id1"] != session[:auth]["id"] && @result[0]["user_id2"] != session[:auth]["id"]) || @result[0]["view"] == 0
      flash[:danger] = "Reste tranquille petit coquin !"
      redirect :"/messages/#{params[:id]}"
    end
    params[:message].strip!
    if params[:message].empty?
      redirect :"/messages/#{params[:id]}"
    end
    time = Time.new
    @@client.query("INSERT INTO messages SET conv_id = '#{params[:id]}', user_id = '#{session[:auth]["id"]}', message = '#{@@coder.encode(params[:message])}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    @@client.query("UPDATE conversations SET last_message = '#{time.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = '#{params[:id]}'")
    redirect :"/messages/#{params[:id]}"
  end

end