# Starts up the CorsifyProxy server.
bootServer = ->
  Config = require('./config.coffee')
  config = new Config(
      origins: (process.env['ALLOWED_ORIGINS'] || '')
      port: process.env['PORT'] || '3000'
  )
  server = config.server()
  server.listen ->
    console.info "Listening for connections at #{server.listenAddress()}"


module.exports = bootServer
