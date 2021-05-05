require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  def self.protect_from_forgery
    @@protect_from_forgery = true
  end

  # Setup the controller
  def initialize(req, res, route_params={}) 
    @req = req
    @res = res
    @params = req.params.merge(route_params)
    @already_built_response = false
    @@protect_from_forgery ||= false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    if !@already_built_response
      @res.location = url
      @res.status = 302

      session.store_session(res)
      @already_built_response = true
    else
      raise "Can't double render!"
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if !@already_built_response
      @res.content_type = content_type
      @res.write(content)

      session.store_session(res)
      flash.store_flash(res)
      @already_built_response = true
    else
      raise "Can't double render!"
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    file_path = File.join("views", self.class.to_s.underscore, "#{template_name.to_s}.html.erb")
    file = File.read(file_path)

    content = ERB.new(file).result(binding)

    render_content(content, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    if @@protect_from_forgery && @req.request_method != 'GET'
      check_authenticity_token
    else
      form_authenticity_token
    end
      
    self.send(name)
    
    if !@already_built_response
      render(name)
      @already_built_response = true
    end
  end

  def form_authenticity_token
    @auth_token ||= SecureRandom::urlsafe_base64
    res.set_cookie('authenticity_token', { path: '/', value: @auth_token })
    @auth_token
  end

  def check_authenticity_token
    cookie = @req.cookies["authenticity_token"]
    unless cookie && cookie == params["authenticity_token"]
      raise "Invalid authenticity token"
    end
  end
end