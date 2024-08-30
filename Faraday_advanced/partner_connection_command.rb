# Este comando genera un objeto Faraday Connection hacía un partner
#
# Input:
# - url base del sitribuidor (ej. https://cofares)
# - token needed for authentication. If nil, the Authorization header will be omitted

class PartnerConnectionCommand < BaseCommand
  private

  attr_reader :url, :token

  def initialize(url, token = nil)
    @url = url
    @token = token
  end

  def accept
    'application/json'
  end

  def software_id
    '75'
  end

  def content_type
    'application/json'
  end

  def headers
    headers = { 'accept': accept,
                'Content-Api-Version': API_VERSION,
                'Software-ID': software_id,
                'Content-Type': content_type }
    headers.merge!('Authorization': "Bearer #{token}" ) if token.present?
    headers
  end

  def payload
    raise ApiExceptionHandler::ParamsMissing unless url.present?

    @result = Faraday.new(
        url: url,
        headers: headers,
        ssl: { verify: false }
    )
  end
end
