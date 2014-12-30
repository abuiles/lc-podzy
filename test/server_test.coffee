url = require 'url'

request = require 'request'
sinon = require 'sinon'

describe 'HTTP server', ->
  beforeEach (done) ->
    @sandbox = sinon.sandbox.create()
    @testServers = new TestServers()
    @testServers.listen =>
      @testOrigin = @testServers.testOrigin()
      @server = corsify_test_config.server()
      @server.listen =>
        @httpRoot = @server.httpUrl()
        done()
  afterEach (done) ->
    @sandbox.restore()
    @testServers.close =>
      @server.close done

  it 'proxies GET returning 200 correctly', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/req"
      headers:
        cookie: 'session=pleaseremove'
        cookie2: 'session2=pleaseremovetoo'
        origin: 'https://mysite.com'
        'x-custom': 'please-preserve'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 200
      expect(response.headers['access-control-allow-origin']).to.equal '*'
      expect(response.headers['access-control-expose-headers'].split(',').
          sort().join(',')).to.
          equal 'connection,content-length,content-type,date,etag,x-powered-by'
      expect(response.headers['content-type']).to.equal(
          'application/json; charset=utf-8')
      json = JSON.parse body
      expect(json.method).to.equal 'GET'
      expect(json.url).to.equal '/req'
      expect(json.headers).not.to.have.property 'origin'
      expect(json.headers).not.to.have.property 'cookie'
      expect(json.headers).not.to.have.property 'cookie2'
      expect(json.headers['x-custom']).to.equal 'please-preserve'
      done()

  it 'proxies POST returning 201 correctly', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/req"
      headers:
        'content-type': 'application/json; charset=utf-8'
        cookie: 'session=pleaseremove'
        cookie2: 'session2=pleaseremovetoo'
        origin: 'https://mysite.com'
        'x-custom': 'please-preserve'
      body: JSON.stringify(_status: 201)
    request.post requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 201
      expect(response.headers['access-control-allow-origin']).to.equal '*'
      expect(response.headers['access-control-expose-headers'].split(',').
          sort().join(',')).to.
          equal 'connection,content-length,content-type,date,x-powered-by'
      expect(response.headers['content-type']).to.equal(
          'application/json; charset=utf-8')
      json = JSON.parse body
      expect(json.method).to.equal 'POST'
      expect(json.url).to.equal '/req'
      expect(json.headers).not.to.have.property 'origin'
      expect(json.headers).not.to.have.property 'cookie'
      expect(json.headers).not.to.have.property 'cookie2'
      expect(json.headers['content-type']).to.equal(
          'application/json; charset=utf-8')
      expect(json.headers['x-custom']).to.equal 'please-preserve'
      done()

  it 'proxies POST redirecting correctly', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/res"
      headers:
        'content-type': 'application/json; charset=utf-8'
        origin: 'https://mysite.com'
      body: JSON.stringify(
        code: 302
        status: 'Redirected'
        headers: {
          'content-type': 'text/plain'
          'content-length': 'You are being redirected.'.length
          location: "#{@testOrigin}/target"
        }
        body: 'You are being redirected.')
    request.post requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 302
      expect(response.headers['access-control-allow-origin']).to.equal '*'
      expect(response.headers['access-control-expose-headers'].split(',').
          sort().join(',')).to.equal(
            'connection,content-length,content-type,date,location,x-powered-by')
      expect(response.headers['location']).to.equal(
          "#{@httpRoot}/#{@testOrigin}/target")
      done()

  it '403s on GET from disallowed Origin', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/req"
      headers:
        origin: 'https://notmysite.com'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 403
      expect(response.headers['content-type']).to.equal 'text/plain'
      expect(response.body).to.match(/allowed origin/i)
      done()

  it '403s on GET without an Origin', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/req"
      headers:
        origin: 'https://notmysite.com'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 403
      expect(response.headers['content-type']).to.equal 'text/plain'
      expect(response.body).to.match(/allowed origin/i)
      done()

  it "400s on GET /", (done) ->
    requestOptions =
      url: "#{@httpRoot}/"
      headers:
        origin: 'https://mysite.com'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 400
      expect(response.headers['content-type']).to.equal 'text/plain'
      expect(response.body).to.match(/empty/i)
      done()

  it "400s on GET /favicon.ico", (done) ->
    requestOptions =
      url: "#{@httpRoot}/favicon.ico"
      headers:
        origin: 'https://mysite.com'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 400
      expect(response.headers['content-type']).to.equal 'text/plain'
      expect(response.body).to.match(/protocol/i)
      done()

  it "500s on network error", (done) ->
    requestOptions =
      url: "#{@httpRoot}/http://0.0.0.0/req"
      headers:
        origin: 'https://mysite.com'
    request.get requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 500
      expect(response.headers['content-type']).to.equal(
          'application/json; charset=utf-8')
      expect(response.headers['access-control-allow-origin']).to.equal '*'
      json = JSON.parse response.body
      expect(json).to.have.property 'proxyError'
      expect(json.proxyError.code).to.equal 'ECONNREFUSED'
      done()

  it 'responds to OPTIONS correctly', (done) ->
    requestOptions =
      url: "#{@httpRoot}/#{@testOrigin}/req"
      method: 'OPTIONS'
      headers:
        origin: 'https://mysite.com'
        'access-control-request-headers': 'X-Header1,X-Header2'
        'access-control-request-method': 'POST'
    request requestOptions, (error, response, body) =>
      expect(error).not.to.be.ok
      expect(response.statusCode).to.equal 200
      expect(response.headers['access-control-allow-origin']).to.equal '*'
      expect(response.headers['access-control-allow-headers']).to.equal(
        'X-Header1,X-Header2')
      expect(response.headers['access-control-allow-methods']).to.equal(
        'POST')
      done()
