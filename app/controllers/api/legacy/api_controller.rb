class Api::Legacy::ApiController < ActionController::Base
  before_filter :ensure_context
  
  private
  def ensure_context
    @version = params[:v].to_i
    return error('unknown version') unless @version == 1
    @game = Game.find_by_id(params[:key])
    return error('the key is not valid') if @game.nil?
    return error('invalid signature') unless valid_signature?(params, @game.secret)
  end
  
  def ensure_leaderboard
    return error('missing leaderboard id')  if params[:leaderboard_id].blank?
    @leaderboard = Leaderboard.find_by_id(Id.from_string(params[:leaderboard_id]))
    return error('invalid leaderboard') if @leaderboard.nil? || @leaderboard.game_id != @game.id
    true
  end
  
  def ensure_player(within = nil)
    username = within.nil? ? params[:username] : params[within][:username]
    unique = within.nil? ? params[:unique] : params[within][:unique]
    return error('missing username') if username.blank?
    return error('missing unique') if unique.blank?
    @player = Player.new(username, unique)
    return error('username and unique are both required, and username must be 30 or less characters')  unless @player.valid?
    true
  end
  
  def error(message, data = nil)
    payload = {:error => message}
    payload[:info] = flatten(data) unless data.blank?
    render :status => 400, :json => payload
    false
  end
  
  def valid_signature?(params, secret)
    return false if params[:sig].blank? && params[:sig2].blank?
    if params[:sig2].blank?
      signature = params.delete :sig
      md5 = true
    else
      signature = params.delete :sig2
      md5 = false
    end
    signature == get_signature(params, secret, md5)
  end

  def get_signature(params, secret, md5)
    raw = get_signature_string(params, secret)
    md5 ? Digest::MD5.hexdigest(raw) : Digest::SHA1.hexdigest(raw)
  end

  def get_signature_string(params, secret)
    filtered = params.reject{|key, value| key == 'action' || key == 'controller'}.to_a  
    extract(filtered).sort.collect {|k,v| [k,v].join('=') }.join("&") + "&" + secret
  end

  def extract(hash)
    newHash = Hash.new
    hash.each do |k, v|
      if v.is_a?(Hash)
        newHash.merge!(extract(v))
      elsif v.is_a?(Array)
        newHash[k] = v.join('-')
      else
        newHash[k] = v
      end
    end
    newHash
  end
end