global.chai = require 'chai'
global.sinon = require 'sinon'

sinonChai = require 'sinon-chai'
global.chai.use sinonChai

global.CorsifyProxy = require '../lib/index.js'

global.corsify_test_config = new CorsifyProxy.Config(
  origins: 'http://localhost:3000,https://mysite.com'
  port: null)

global.assert = global.chai.assert
global.expect = global.chai.expect


bodyParser = require 'body-parser'
express = require 'express'
fs = require 'fs'
http = require 'http'

# Sets up the test backends.
class TestServers
  constructor: ->
    @createApp()
    @_http = http.createServer @_app
    @_address = null

  # The root URL for XHR tests.
  testOrigin: ->
    return null unless @_address
    "http://localhost:#{@_address.port}"

  # Starts listening to the test servers' sockets.
  #
  # @param {function()} callback called when the servers are ready to accept
  #   incoming connections
  # @return undefined
  listen: (callback) ->
    if @_address
      throw new Error 'Already listening'
    @_http.listen @_port, =>
      @_address = @_http.address()
      callback()

  # Stops listening to the test servers' sockets.
  #
  # @param {function()} callback called after the servers close their listen
  #   sockets
  # @return undefined
  close: (callback) ->
    unless @_address
      throw new Error 'Not listening'
    @_address = null
    @_http.close callback
    return

  # The server code.
  createApp: ->
    @_app = express()

    ## Middleware.

    @_app.use bodyParser.json(
        strict: true, type: 'application/json', limit: 65536)

    ## Routes

    # Tests request composition.
    @_app.all '/req', (request, response) ->
      statusCode = request.body?._status or 200
      jsonBody =
        method: request.method
        url: request.url
        headers: request.headers
        body: request.body
      response.status(statusCode).json jsonBody

    # Tests response composition.
    @_app.all '/res', (request, response) ->
      response.writeHead request.body.code, request.body.status,
                         request.body.headers
      if request.body.body
        response.end request.body.body
      else
        response.end()


global.TestServers = TestServers
