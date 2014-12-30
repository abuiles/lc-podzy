Corsifier = CorsifyProxy.Corsifier

describe 'Corsifier', ->
  beforeEach ->
    @corsifier = new Corsifier({})

  describe '#stripCors', ->
    beforeEach ->
      @request =
          __headers: {}
          removeHeader: (header) -> delete @__headers[header]

    it 'removes cookie headers', ->
      @request.__headers =
          cookie: 'session=pleaseremoveme'
          cookie2: 'session=pleaseremovemetoo'
          'content-type': 'application/json'
          'content-length': 42
      @corsifier.stripCors @request
      expect(@request.__headers).to.deep.equal(
          'content-type': 'application/json'
          'content-length': 42)

    it 'removes CORS headers', ->
      @request.__headers =
          'content-type': 'application/json'
          'content-length': 42
          'access-control-request-method': 'POST'
          'access-control-request-headers': 'X-Header1,X-Header2'
          origin: 'http://mysite.com'
      @corsifier.stripCors @request
      expect(@request.__headers).to.deep.equal(
          'content-type': 'application/json'
          'content-length': 42)

  describe '#addCors', ->
    beforeEach ->
      @request =
          headers: { host: 'proxiedhost.com' }, _originalHost: 'proxy:8989',
          connection: { encrypted: false }
      @response = headers: {}

    it 'always adds the origin and expose CORS headers', ->
      @corsifier.addCors @response, @request
      expect(@response.headers).to.deep.equal(
          'access-control-expose-headers': '',
          'access-control-allow-origin': '*')

    it 'removes cookies headers', ->
      @response.headers['set-cookie'] = 'pleaseremoveme'
      @response.headers['set-cookie2'] = 'pleaseremoveme2'
      @corsifier.addCors @response, @request
      expect(@response.headers).to.deep.equal(
          'access-control-expose-headers': '',
          'access-control-allow-origin': '*')

    describe 'with request-headers', ->
      beforeEach ->
        @request.headers['access-control-request-headers'] =
            'X-Header1,X-Header2'

      it 'adds the headers CORS header', ->
        @corsifier.addCors @response, @request
        expect(@response.headers).to.deep.equal(
            'access-control-expose-headers': '',
            'access-control-allow-origin': '*',
            'access-control-allow-headers': 'X-Header1,X-Header2')

    describe 'with request-method', ->
      beforeEach ->
        @request.headers['access-control-request-method'] = 'PUT'

      it 'adds the methods CORS header', ->
        @corsifier.addCors @response, @request
        expect(@response.headers).to.deep.equal(
            'access-control-expose-headers': '',
            'access-control-allow-origin': '*',
            'access-control-allow-methods': 'PUT')

    describe 'with location in response', ->
      beforeEach ->
        @response.headers.location = 'http://proxiedhost.com/target'

      describe 'with http request', ->
        it 'rewrites the location header', ->
          @corsifier.addCors @response, @request
          expect(@response.headers).to.deep.equal(
              'access-control-expose-headers': 'location',
              'access-control-allow-origin': '*',
              location: 'http://proxy:8989/http://proxiedhost.com/target')

      describe 'with direct https request', ->
        beforeEach ->
          @request.connection.encrypted = true

        it 'rewrites the location header', ->
          @corsifier.addCors @response, @request
          expect(@response.headers).to.deep.equal(
              'access-control-expose-headers': 'location',
              'access-control-allow-origin': '*',
              location: 'https://proxy:8989/http://proxiedhost.com/target')

        describe 'with proxied http request', ->
          beforeEach ->
            @request.headers['x-forwarded-proto'] = 'http'

          it 'rewrites the location header', ->
            @corsifier.addCors @response, @request
            expect(@response.headers).to.deep.equal(
                'access-control-expose-headers': 'location',
                'access-control-allow-origin': '*',
                location: 'http://proxy:8989/http://proxiedhost.com/target')

      describe 'with proxied https request', ->
        beforeEach ->
          @request.headers['x-forwarded-proto'] = 'https'

        it 'rewrites the location header', ->
          @corsifier.addCors @response, @request
          expect(@response.headers).to.deep.equal(
              'access-control-expose-headers': 'location',
              'access-control-allow-origin': '*',
              location: 'https://proxy:8989/http://proxiedhost.com/target')
