class PartnerConnectionCommand < BaseCommand
  private

  attr_reader :url

  def initialize(url)
    @url = url
  end

  def accept
    'application/json'
  end

  def content_type
    'application/json'
  end

  def headers
    { 'accept': accept, 'Content-Type': content_type }
  end

  def payload
    raise ApiExceptionHandler::ParamsMissing unless url.present?

    @result = Faraday.new(
        url: url,
        headers: headers
    )
  end
end
