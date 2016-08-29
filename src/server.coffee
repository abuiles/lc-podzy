http = require 'http'
url = require 'url'

httpProxy = require 'http-proxy'


# HTTP proxying logic.
class Server
  # Sets up the Web and WebSocket servers.
  #
  # @param {RequestFilter} requestFilter the logic that determines if requests
  #   should be proxied or not
  # @param {Corsifier} corsifier the logic for manipulating CORS requests
  # @param {Object} options server configuration
  # @option options {String} port the port to bind to
  constructor: (requestFilter, corsifier, options) ->
    @_port = parseInt options.port
    @_address = null

    @_requestFilter = requestFilter
    @_corsifier = corsifier

    @_proxy = httpProxy.createProxyServer secure: true
    @_proxy.on 'proxyReq', @_onProxyRequest.bind(@)
    @_proxy.on 'proxyRes', @_onProxyResponse.bind(@)
    @_proxy.on 'error', @_onProxyError.bind(@)
    @_http = http.createServer()
    @_http.on 'request', @_onHttpRequest.bind(@)
    return

  # Starts listening to the server's socket.
  #
  # @param {function()} callback called when the server is ready to accept
  #   incoming connections
  # @return undefined
  listen: (callback) ->
    if @_address
      throw new Error 'Already listening'
    @_http.listen @_port, =>
      @_address = @_http.address()
      callback()
    return

  # Stops listening to this server's socket.
  #
  # @param {function()} callback called after the server closes its listen
  #   socket
  # @return undefined
  close: (callback) ->
    unless @_address
      throw new Error 'Not listening'
    @_address = null
    @_http.close callback
    return

  # This server's HTTP URL.
  #
  # @return {String} the URL to send HTTP requests to; null if the server
  #   didn't start listening
  httpUrl: (callback) ->
    return null unless @_address
    "http://localhost:#{@_address.port}"

  # Developer-friendly listen address.
  #
  # This is intended to be displayed in "Listening to ..." messages.
  #
  # @return {String} the listening socket's address, formatted as host:port
  listenAddress: ->
    return null unless @_address
    "#{@_address.address}:#{@_address.port}"

  # Called when a HTTP request is received.
  #
  # @param {http.IncomingMessage} request the incoming HTTP request
  # @param {http.ServerResponse} response the HTTP response
  # @return undefined
  _onHttpRequest: (request, response) ->
    unless true || @_requestFilter.allow request
      @_textError response, 403,
          "Are you making an XHR request from an allowed origin?\n"
      return

    rawUrl = request.url.substring 1
    # NOTE: the URL-parsing code in http-proxy isn't very robust, so we do our
    #       own parsing and shield it from invalid URLs
    unless typeof rawUrl is 'string' && rawUrl.length > 0
      @_textError response, 400,
          "Empty request path; request path must be an absolute URL\n"
      return

    parsedUrl = url.parse rawUrl
    unless parsedUrl.protocol
      @_textError response, 400,
          "Empty protocol; request path must be an absolute URL\n"
      return

    request.url = parsedUrl.path
    request._originalHost = request.headers.host
    request.headers.host = parsedUrl.host
    proxyTarget = "#{parsedUrl.protocol}//#{parsedUrl.host}"

    @_proxy.web request, response, target: proxyTarget
    return

  _textError: (response, status, message) ->
    response.writeHead status,
        'content-type': 'text/plain', 'Content-Length': message.length
    response.end message
    return

  # Called to modify the proxied HTTP request.
  #
  # Removes cookie headers.
  #
  # @param {http.ClientRequest} proxyRequest the proxied HTTP request
  # @param {http.IncomingMessage} request the incoming HTTP request
  # @param {http.ServerResponse} response the HTTP response
  # @param {Object} options
  # @return undefined
  _onProxyRequest: (proxyRequest, request, response, options) ->
    @_corsifier.stripCors proxyRequest
    return

  # Called to modify a proxied HTTP response.
  #
  # @param {http.IncomingMessage} proxyResponse the response to the proxied
  #   HTTP request
  # @param {http.IncomingMessage} request the incoming HTTP request
  # @param {http.ServerResponse} response the HTTP response
  # @return undefined
  _onProxyResponse: (proxyResponse, request, response) ->
    @_corsifier.addCors proxyResponse, request
    return

  # Called when the HTTP proxy encounters an error.
  #
  # @param {http.IncomingMessage} request the HTTP request
  # @param {http.ServerResponse} response the HTTP response
  _onProxyError: (error, request, response) ->
    if response.headersSent
      # The proxied host sent less/more bytes than it declared in
      # Content-Length; handling this would require buffering all responses,
      # which isn't worth it.
      return
    response.writeHead 500,
        'content-type': 'application/json; charset=utf-8',
        'access-control-allow-origin': '*'
    response.end JSON.stringify(proxyError: error)
    return


module.exports = Server
