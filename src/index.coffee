CorsifyProxy =
  bootServer: require('./boot_server.coffee')
  Config: require('./config.coffee')
  Corsifier: require('./corsifier.coffee')
  RequestFilter: require('./request_filter.coffee')
  Server: require('./server.coffee')


module.exports = CorsifyProxy
