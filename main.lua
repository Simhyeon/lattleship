local weblit = require('weblit')
local static = require('weblit-static')
local route = require('./src/routes').route

local port = os.getenv("LATTLESHIP_PORT")

weblit.app
  .bind({host = "127.0.0.1", port = port})
  -- Configuration
  .use(require('weblit-logger'))
  .use(require('weblit-auto-headers'))
  .use(require('weblit-etag-cache'))
  -- Routes
  -- TODO: Possibley static file
  .route({ method="GET", path = "/" }, route.game)
  .route({ method="GET", path = "/start" }, route.start)
  .route({ method="POST", path = "/pick" }, route.pick)
  -- Start the server
  .start()
