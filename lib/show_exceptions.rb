require 'erb'

class ShowExceptions
  attr_accessor :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue => e
      render_exception(e)
    end
  end

  private

  def render_exception(e)
    ['500', {'Content-type' => 'text/html'}, e.inspect]
  end
end