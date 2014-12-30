# Corisfy Proxy

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)
[![Build Status](https://travis-ci.org/pwnall/node-corsify-proxy.svg)](https://travis-ci.org/pwnall/node-corsify-proxy)
[![API Documentation](http://img.shields.io/badge/API-Documentation-ff69b4.svg)](http://coffeedoc.info/github/pwnall/node-corsify-proxy)
[![NPM Version](http://img.shields.io/npm/v/corsify-proxy.svg)](https://www.npmjs.org/package/node-corsify-proxy)

This is a [node.js](http://nodejs.org/) HTTP proxy that adds
[Cross-Origin Resource Sharing (CORS)](http://www.w3.org/TR/cors/)
headers to incoming HTTP requests, for use with
[XMLHttpRequest level 2](http://www.w3.org/TR/XMLHttpRequest2/).

The server was designed to be deployed to [Heroku](https://www.heroku.com/)
using free resources, so it fits in a single dyno. The code has great test
coverage using [mocha](http://visionmedia.github.io/mocha/).


## Easy Setup

Click the ''Deploy to Heroku'' button at the top of this page to create your own
W3gram server running on Heroku. Don't worry, the project only uses free
add-ons!

Make sure to add both your development server (e.g., `http://localhost:3000`)
and your production sever (e.g., `https://www.yourapp.com`) to the list of
allowed origins.

Make requests to the CORS-disabled server, including the protocol and path.

```bash
curl -i https://corsify-test.herokuapp.com/https://google.com
```



## Development Setup

Install all dependencies.

```bash
npm install
```

Run the server in development mode.

```bash
npm start
```


## License

This project is Copyright (c) 2014 Victor Costan, and distributed under the MIT
License.
