Server = require './server.coffee'
Corsifier = require './corsifier.coffee'
RequestFilter = require './request_filter.coffee'

# Assembles the server's components based on a configuration.
class Config
  # Loads a JSON configuration.
  #
  # @param {Object} json a JSON configuration dictionary
  # @option options {String} origins comma-separated list of allowed values for
  #   the Origin header
  # @option options {String} port the port to listen to for HTTP requests
  constructor: (json) ->
    @_config =
      corsifier: {}
      requestFilter:
        origins: json.origins.split(',')
      server:
        port: json.port

  # @return {Server} the server built from this configuration
  server: ->
    @_server ||= new Server @requestFilter(), @corsifier(), @_config.server

  # @return {Corsifier} the CORS manipulator built from this configuration
  corsifier: ->
    @_corsifier ||= new Corsifier @_config.corsifier

  # @return {RequestFilter} the request filter built from this configuration
  requestFilter: ->
    @_requestFilter ||= new RequestFilter @_config.requestFilter

module.exports = Config
