require "json"

class Cisaurus

  CLIENT_VERSION = "0.4-PRE-ALPHA"

  def initialize(api_key, host = "cisaurus.herokuapp.com", api_version = "v1")
    @base_url = "http://:#{api_key}@#{host}"
    @ver_url  = "#{@base_url}/#{api_version}"
  end

  def downstreams(app)
    JSON.parse RestClient.get pipeline_resource(app, "downstreams"), headers
  end

  def addDownstream(app, ds)
    RestClient.post pipeline_resource(app, "downstreams", ds), "", headers
  end

  def removeDownstream(app, ds)
    RestClient.delete pipeline_resource(app, "downstreams", ds), headers
  end

  def promote(app, interval = 2)
    response = RestClient.post pipeline_resource(app, "promote"), "", headers
    while response.code == 202
      response = RestClient.get @base_url + response.headers[:location], headers
      sleep(interval)
      yield
    end
    JSON.parse response
  end

  private

  def pipeline_resource(app, *extras)
    "#{@ver_url}/" + extras.unshift("apps/#{app}/pipeline").join("/")
  end

  def headers
    {
        'User-Agent'       => "cli-plugin/#{CLIENT_VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }
  end
end