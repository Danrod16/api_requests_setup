class PartnerGetCommand < BaseCommand
  private

  attr_reader :partner

  def initialize(partner)
    @partner = partner
  end

  # reload the partner because if the auth fails, the token get renew
  def partner_connection
    PartnerConnectionCommand.call(partner.base_url).result
  end

  def payload
    return unless partner.present?

    retries = 0

    begin
      response = partner_connection.get(PARTNER_GET_PATH)
      # raise AuthenticationError (si por alguna razon la authentication ha fallado)

      @result = { status: response.status, response_body_json: response.body }
    rescue AuthenticationError
      if (retries += 1) <= 3
        RefreshClienteOutboundTokenService.call(cliente)
        retry
      end
    rescue URI::InvalidURIError => exception
      Rollbar.error(exception)
    rescue JSON::ParserError => exception
      Rollbar.error(exception)
    rescue Faraday::ConnectionFailed
      if (retries += 1) <= 3
        sleep(retries * 3)
        retry
      end
    end
  end
end
