RequestFilter = CorsifyProxy.RequestFilter

describe 'RequestFilter', ->
  beforeEach ->
    @request = headers: {}

  describe 'with a single host', ->
    beforeEach ->
      @filter = new RequestFilter origins: ['http://localhost:3000']

    it 'rejects Origin-less requests', ->
      expect(@filter.allow(@request)).to.equal false

    it 'rejects requests with the wrong Origin host', ->
      @request.headers.origin = 'http://mysite.com'
      expect(@filter.allow(@request)).to.equal false

    it 'rejects requests with the wrong Origin protocol', ->
      @request.headers.origin = 'https://localhost:3000'
      expect(@filter.allow(@request)).to.equal false

    it 'accepts requests with a matching Origin', ->
      @request.headers.origin = 'http://localhost:3000'
      expect(@filter.allow(@request)).to.equal true

  describe 'with multiple hosts', ->
    beforeEach ->
      @filter = new RequestFilter(
          origins: ['http://localhost:3000', 'https://mysite.com'])

    it 'rejects Origin-less requests', ->
      expect(@filter.allow(@request)).to.equal false

    it 'rejects requests with the wrong Origin host or protocol', ->
      @request.headers.origin = 'http://mysite.com'
      expect(@filter.allow(@request)).to.equal false
      @request.headers.origin = 'https://localhost:3000'
      expect(@filter.allow(@request)).to.equal false

    it 'accepts requests with a matching Origin', ->
      @request.headers.origin = 'http://localhost:3000'
      expect(@filter.allow(@request)).to.equal true
      @request.headers.origin = 'https://mysite.com'
      expect(@filter.allow(@request)).to.equal true


