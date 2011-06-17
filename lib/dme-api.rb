
require 'json'
require 'open-uri'
require 'openssl'
require 'optparse'
require 'rest_client'
require 'socket'
require 'time'

class DME

  def initialize(api_key, secret_key, domain)

    @@dme_rest_url = "http://api.dnsmadeeasy.com/V1.2/domains/"

    @api_key = api_key
    @secret_key = secret_key
    @domain = domain
  end

  def get(name)
    response = RestClient.get(get_url(), get_headers())

    # find the record we want
    JSON.parse(response.to_str).select { |x| x["name"] == name }.first
  end

  def create(record)
    response = RestClient.post get_url(),
                            record.to_json,
                            get_headers(:"content-type" => :json)
    JSON.parse(response)
  end

  def delete(id)
    response = RestClient.delete get_url(id), get_headers()
  end


  private

  def get_url(id = nil)
    u = @@dme_rest_url + @domain + "/records"
    if not id.nil? then
      u += "/#{id}"
    end
    return u
  end

  def get_headers(additional_headers = {})
    t = Time.now.httpdate
    hmac = OpenSSL::HMAC.hexdigest('sha1', @secret_key, t)
    {
      :"x-dnsme-apiKey"      => @api_key,
      :"x-dnsme-hmac"        => hmac,
      :"x-dnsme-requestDate" => t,
      :accept                =>:json
    }.merge(additional_headers)
  end

end
