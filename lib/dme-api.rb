
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

  # get the DNS record for the given hostname
  def get(name)
    response = RestClient.get(get_url(), get_headers())

    # find the record we want
    JSON.parse(response.to_str).select { |x| x["name"] == name }.first
  end

  # create a new DNS record
  #
  # record should be a hash with the following values:
  #
  # { "name"        => hostname,
  #   "type"        => "CNAME",
  #   "data"        => publicname,
  #   "gtdLocation" => "DEFAULT",
  #   "ttl"         => 300 }
  #
  # name = hostname
  # data = host/IP it should resolve to
  #
  # e.g., for type="CNAME": name="www", data="web01.domain.com.",
  #                         or data="web01" for short
  #
  def create(record)
    response = RestClient.post get_url(),
                            record.to_json,
                            get_headers(:"content-type" => :json)
    JSON.parse(response)
  end

  # delete the DNS record with the given id. id can be retrieved by
  # first calling get()
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
