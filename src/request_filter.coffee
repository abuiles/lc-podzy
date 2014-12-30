# Logic for deciding which requests get serviced.
class RequestFilter
  # Creates a request filter.
  #
  # @param {Object} options options
  # @param {Array<String>} origins the list of allowed values for the HTTP
  #   Origin header
  constructor: (options) ->
    @_origins = {}
    for origin in options.origins
      @_origins[origin] = true

  # Checks if a request should be serviced.
  #
  # @param {http.IncomingMessage} request the HTTP request
  # @return {Boolean} true if the given request should be serviced, false
  #   otherwise
  allow: (request) ->
    origin = request.headers['origin']
    return false unless origin
    @_origins[origin] || false


module.exports = RequestFilter
