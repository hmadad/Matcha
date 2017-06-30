class Matcha < Sinatra::Application

  # ====================================================  GET PAGE  ====================================================

  get "/search" do
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id NOT LIKE '#{session[:auth]['id']}' AND sexe = '#{orientation}'").each do |row|
      @result << row
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation
    end
    @km = {}
    @km == "illimite"
    erb :"search"
  end

  get "/search/:min/:max/:km/:tri/" do
    @params = params
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    if params[:order] == "score"
      order = "score"
    else
      order = "created_at"
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE id NOT LIKE '#{session[:auth]['id']}' AND sexe = '#{orientation}' AND sexe = '#{orientation}' AND age BETWEEN '#{params[:min]}' AND '#{params[:max]}' ORDER BY #{order} DESC").each do |row|
      @result << row
    end
    erb :"search"
  end

  get "/search/:min/:max/:km/:tri/:search" do
    if session[:auth]['orientation'] == "Femme"
      orientation = "Femme"
    elsif session[:auth]['orientation'] == "Homme"
      orientation = "Homme"
    else
      orientation = "Femme' OR sexe = 'HOMME"
    end
    if params[:order] == "score"
      order = "score"
    else
      order = "created_at"
    end
    if session[:auth]["location"] && session[:auth]["location"].to_i != 0
      @coord = loc(session[:auth]["location"].to_i)
    else
      @coord = stalkLocation
    end
    @result = []
    @@client.query("SELECT * FROM users WHERE interest REGEXP '##{params[:search]}(,|$)' AND id NOT LIKE '#{session[:auth]['id']}' AND sexe = '#{orientation}' AND age BETWEEN '#{params[:min]}' AND '#{params[:max]}' ORDER BY #{order} DESC").each do |row|
      @result << row
    end
    erb :"search"
  end

  # ====================================================  POST PAGE  ===================================================

  post "/search" do
    if params[:search][0] == '#'
      params[:search] = params[:search][1..params[:search].length]
    end
    if params[:min].empty?
      params[:min] = 18
    end
    if params[:max].empty?
      params[:max] = 120
    end
    if params[:km].empty?
      params[:km] = "illimite"
    end
    if params[:order].empty?
      params[:order] = "score"
    end
    redirect "/search/#{params[:min]}/#{params[:max]}/#{params[:km]}/#{params[:order]}/#{params[:search]}"
  end

end