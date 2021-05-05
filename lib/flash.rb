require 'json'

class Flash
  attr_accessor :now

  def initialize(req)
    @next_flash = {}
    @now = {}

    json_cookie = req.cookies['_rails_lite_app_flash']
    @flash = JSON::parse(json_cookie) if !json_cookie.nil?
    @flash ||= {}    
  end

  def [](key)
    @flash.merge(@now)[key.to_s]
  end

  def []=(key, val)
    @flash[key] = @next_flash[key] = val
  end

  def store_flash(res)
    res.set_cookie('_rails_lite_app_flash', { path: '/', value: @next_flash.to_json })
  end
end