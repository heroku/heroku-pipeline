class Cisaurus

  CLIENT_VERSION = "0.11"
  DEFAULT_HOST = ENV['CISAURUS_HOST'] || "cisaurus.heroku.com"

  def initialize(api_key, host = DEFAULT_HOST, api_version = "v1")
    protocol  = (host.start_with? "localhost") ? "http" : "https"
    @base_url = "#{protocol}://:#{api_key}@#{host}"
    @ver_url  = "#{@base_url}/#{api_version}"
  end

  def downstreams(app, depth=nil)
    handle_error do
      MultiJson.load RestClient.get pipeline_resource(app, "downstreams"), options(params :depth => depth)
    end
  end

  def addDownstream(app, ds)
    handle_error do
      RestClient.post pipeline_resource(app, "downstreams", ds), "", options
    end
  end

  def removeDownstream(app, ds)
    handle_error do
      RestClient.delete pipeline_resource(app, "downstreams", ds), options
    end
  end

  def diff(app)
    handle_error do
      MultiJson.load RestClient.get pipeline_resource(app, "diff"), options
    end
  end

  def promote(app, interval = 2)
    handle_error do
      response = RestClient.post pipeline_resource(app, "promote"), "", options
      while response.code == 202
        response = RestClient.get @base_url + response.headers[:location], options
        sleep(interval)
        yield
      end
      MultiJson.load response
    end
  end

  private

  def pipeline_resource(app, *extras)
    "#{@ver_url}/" + extras.unshift("apps/#{app}/pipeline").join("/")
  end

  def params(tuples = {})
    { :params => tuples.reject { |k,v| k.nil? || v.nil? } }
  end

  def options(extras = {})
    {
        'User-Agent'       => "cli-plugin/#{CLIENT_VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }.merge(extras)
  end

  def handle_error(&request)
    begin
      request.call
    rescue RestClient::Exception => e
      body = MultiJson.load e.response
      if !body.nil? && (body.has_key? 'error')
        raise Heroku::Command::CommandFailed, body['error']
      else
        raise e
      end
    end
  end

end
