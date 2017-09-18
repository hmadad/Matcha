class Matcha < Sinatra::Application

  # ====================================================  GET PAGE  ====================================================

  get "/likes" do
    if !isConnected?
      redirect "/"
    end
    @result = []
    @@client.query("SELECT * FROM likes WHERE user_id = '#{session[:auth]["id"]}'").each do |row|
      @result << row
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation(request.ip)
    end
    if !request.websocket?
      erb :"likes"
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
  post "/likes/like/:id" do
    if !isConnected?
      redirect "/"
    end
    if session[:auth]["id"] == params[:id]
      flash[:danger] = "Vous vous aimez trop, arretez ca !"
      redirect "/"
    end
    result = []
    @@client.query("SELECT * FROM likes WHERE user_id = '#{session[:auth]["id"]}' AND user_liked = '#{params[:id]}'").each do |row|
      result << row
    end
    if !result.empty?
      flash[:danger] = "Vous aimez deja cette personne"
      redirect "/"
    end
    time = Time.new
    @@client.query("INSERT INTO likes SET user_id = '#{session[:auth]["id"]}', user_liked = #{params[:id]}, created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    @@client.query("UPDATE users SET score = score + 1 WHERE id = #{params['id']}")
    @@client.query("INSERT INTO notifications SET user_id = '#{session[:auth]["id"]}', user_notified = '#{params[:id]}', message = '#{session[:auth]["username"]}, a aimé votre profile', vu = '0',  type = '1', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    result = []
    @@client.query("SELECT * FROM likes WHERE (user_id = '#{session[:auth]["id"]}' AND user_liked = '#{params[:id]}') OR (user_id = '#{params[:id]}' AND user_liked = '#{session[:auth]["id"]}')").each do |row|
      result << row
    end
    if result.length == 2
      result = []
      @@client.query("SELECT * FROM conversations WHERE (user_id1 = '#{session[:auth]["id"]}' AND user_id2 = '#{params[:id]}') OR (user_id2 = '#{session[:auth]["id"]}' AND user_id1 = '#{params[:id]}')").each do |row|
        result << row
      end
      if !result.empty?
        @@client.query("UPDATE conversations SET view = '1', last_message = '#{time.strftime('%Y-%m-%d %H:%M:%S')}' WHERE (user_id1 = '#{session[:auth]["id"]}' AND user_id2 = '#{params[:id]}') OR (user_id2 = '#{session[:auth]["id"]}' AND user_id1 = '#{params[:id]}')")
      else
        @@client.query("INSERT INTO conversations SET user_id1 = '#{session[:auth]["id"]}', user_id2 = '#{params[:id]}', view = '1', last_message = '#{time.strftime('%Y-%m-%d %H:%M:%S')}', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
      end
      flash[:success] = "Félicitation, vous pouvez maintenant discuter avec votre nouvelle interlocuteur"
      redirect "/"
    end
    flash[:success] = "Vous venez de like une personne"
    redirect "/"
  end
  post "/likes/dislike/:id" do
    if !isConnected?
      redirect "/"
    end
    if session[:auth]["id"] == params[:id]
      flash[:danger] = "Vous ne pouvez pas ne pas vous aimez! Ca serai triste :("
      redirect "/"
    end
    result = []
    @@client.query("SELECT * FROM likes WHERE user_id = '#{session[:auth]["id"]}' AND user_liked = #{params[:id]}").each do |row|
      result << row
    end
    if result.empty?
      flash[:danger] = "Vous ne pouvez pas ne pas aimez une personne que vous n'aimez deja pas !"
      redirect "/"
    end
    time = Time.new
    result = []
    @@client.query("SELECT * FROM likes WHERE (user_id = '#{session[:auth]["id"]}' AND user_liked = '#{params[:id]}') OR (user_id = '#{params[:id]}' AND user_liked = '#{session[:auth]["id"]}')").each do |row|
      result << row
    end
    @@client.query("DELETE FROM likes WHERE user_id = '#{session[:auth]["id"]}' AND user_liked = #{params[:id]}")
    @@client.query("UPDATE users SET score = score - 1 WHERE id = #{params['id']}")
    @@client.query("INSERT INTO notifications SET user_id = '#{session[:auth]["id"]}', user_notified = '#{params[:id]}', message = '#{session[:auth]["username"]}, a dislike votre profile', vu = '0',  type = '2', created_at = '#{time.strftime('%Y-%m-%d %H:%M:%S')}'")
    if result.length == 2
      @@client.query("UPDATE conversations SET view = '0' WHERE (user_id1 = '#{session[:auth]["id"]}' AND user_id2 = '#{params[:id]}') OR (user_id2 = '#{session[:auth]["id"]}' AND user_id1 = '#{params[:id]}')")
      flash[:success] = "Vous avez dislike votre interlocuteur ! Vous ne pouvez plus discuter avec lui"
      redirect "/"
    end
    flash[:success] = "Vous venez de dislike une personne avec succès! Tristesse !"
    redirect "/"
  end
end