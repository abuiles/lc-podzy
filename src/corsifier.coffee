# Logic for manipulating CORS requests.
class Corsifier
  # Creates a CORS manipulator.
  #
  # @param {Object} options options
  constructor: (options) ->
    null

  # Strips CORS information from a HTTP request.
  #
  # @param {http.ClientRequest} request the proxied HTTP request
  # @return undefined
  stripCors: (request) ->
    # Remove cookies.
    # Cookies are problematic when the CORSifying proxy is used for multiple
    # sites, and useCredentials is set to true. In that case, each site would
    # receive the other sites' cookie jars. Disabling cookies is a safe
    # default.
    # TODO(pwnall): this should be configurable
    request.removeHeader 'cookie'
    request.removeHeader 'cookie2'

    # Remove CORS headers.
    # Over-zealous servers or firewalls might bounce requests that have CORS
    # headers. Therefore, it's safer to remove them. Bouncing CORS requests
    # isn't a good security measure, as any computer with Internet access can
    # make non-CORS requests using non-browser software.
    # TODO(pwnall): this should be configurable
    request.removeHeader 'origin'
    request.removeHeader 'access-control-request-method'
    request.removeHeader 'access-control-request-headers'
    return

  # Adds CORS headers to an HTTP response.
  #
  # @param {http.IncomingMessage} response the original HTTP response
  # @param {http.IncomingMessage} request the incoming HTTP request
  # @return undefined
  addCors: (response, request) ->
    delete response.headers['set-cookie']
    delete response.headers['set-cookie2']

    # NOTE: this should run before we add any CORS-related headers to the
    #       response
    response.headers['access-control-expose-headers'] =
        Object.keys(response.headers).join ','

    response.headers['access-control-allow-origin'] = '*'
    if requestMethod = request.headers['access-control-request-method']
      response.headers['access-control-allow-methods'] = requestMethod
    if requestHeaders = request.headers['access-control-request-headers']
      response.headers['access-control-allow-headers'] = requestHeaders

    if location = response.headers['location']
      if protoHeader = request.headers['x-forwarded-proto']
        protocol = protoHeader
      else if request.connection.encrypted
        protocol = 'https'
      else
        protocol = 'http'
      host = request._originalHost
      response.headers['location'] = "#{protocol}://#{host}/#{location}"

    return


module.exports = Corsifier
