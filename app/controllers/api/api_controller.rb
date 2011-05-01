class Api::ApiController < ActionController::Base
  before_filter :ensure_context
  before_filter :ensure_signed
  
  private
  def ensure_context
    return error('the key is not valid') if !Id.valid?(params[:key])
    
    @game = Game.find_by_id(params[:key])
    return error('the key is not valid') if @game.nil?
    
    @version = params[:v].to_i
    return error('unknown version') unless @version == 2
  end
  
  def ensure_signed
    signature = params.delete(:sig)
    raw = params.reject{|key, value| key == 'action' || key == 'controller'}.sort{|a, b| a[0] <=> b[0]}.join('|') + '|' + @game.secret

    return error('invalid signature') unless Digest::SHA1.hexdigest(raw) == signature
    @signed = true
  end
  
  def ensure_leaderboard
    lid = Id.from_string(params[:lid])
    error('missing or invalid lid (leaderboard id) parameter') and return if lid.nil?
    
    @leaderboard = Leaderboard.find_by_id(lid)
    error("id doesn't belong to a leaderboard") and return if @leaderboard.nil?
  end
  
  def ensure_player
    return unless ensure_params(:username, :userkey)
    @player = Player.new(params[:username], params[:userkey])
    
    unless @player.valid?
      error('username and userkey are both required, and username must be 30 or less characters') 
    end
  end

  def ensure_params(*keys)
    valid = true
    keys.each do |key|
      unless params.include?(key)
        error("missing required #{key} value")
        valid = false
        return
      end
    end
    valid
  end
  
  def ok
    render :json => {:ok => true}
  end

  def error(message, data = nil)
    payload = {:error => message}
    payload[:data] = data unless data.nil?
    render :status => 400, :json => payload
    true
  end
end