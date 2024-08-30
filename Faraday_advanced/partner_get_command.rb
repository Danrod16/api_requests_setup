# Este comando ejecuta la request necesaria para obtener un pedido.
#
# Para la request:
# - Crea un Faraday Connection object (con la url base del partner) que posee todos los headers segun Fedicom
# - Pasa el token del partner a dicho Connection para que lo añada en el header 'Authorization'
# - Ejecuta la get hacía la ruta de pedidos
#
# Devuelve un Hash que contiene el HTTP status y el body de la response (sin parsear en JSON)
# Si hay algun error repite la request 3 veces y devuelve self.result a nil si no lo consigue
#
# Input:
# - partner object
# - cliente object
# - request body to forward, already parsed to JSON
#
# Output (en este caso no hace falta el JSON.parse de la response):
# - result[:status, response_body_json]

class AuthenticationError < StandardError; end

class PartnerGetPedidoCommand < BaseCommand
  private

  attr_reader :partner, :cliente, :numero_pedido

  def initialize(partner, cliente, numero_pedido)
    @partner = partner
    @cliente = cliente
    @numero_pedido = numero_pedido
  end

  # reload the partner because if the auth fails, the token get renew
  def partner_connection
    PartnerConnectionCommand.call(partner.base_url, cliente.reload.auth_token).result
  end

  def payload
    return unless partner.present? && cliente.present? && numero_pedido.present?

    retries = 0

    begin
      response = partner_connection.get(PARTNER_PATH_GET_PEDIDOS % numero_pedido)
      raise AuthenticationError if token_is_invalid(response)

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

  def token_is_invalid(response)
    /AUTH-00[127]/.match?(response.body)
  end
end
