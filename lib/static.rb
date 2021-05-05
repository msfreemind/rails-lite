class Static
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    res = Rack::Response.new

    match_data = /public\/.+/.match(req.path)

    if !match_data.nil?
      file_path = File.join("lib", match_data.to_s)

      if File.exist?(file_path)        
        file = File.read(file_path)       
        res.write(file)
      else
        res.status = 404
        res.write("File not found!")
      end

      return [res.status, res.headers, res.body]
    else
      @app.call(env)
    end
  end
end