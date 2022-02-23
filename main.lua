local weblit = require('weblit')
local route = require('./src/routes').route

local host = os.getenv("LATTLESHIP_HOST")
local port = os.getenv("LATTLESHIP_PORT")

--- Main app entry
-- bind host and port from env variables
-- sest multiple routes for corresponding paths
weblit.app
	-- Bind host and port
	.bind({host = host, port = port})
	-- Configuration
	.use(require('weblit-logger'))
	.use(require('weblit-auto-headers'))
	.use(require('weblit-etag-cache'))
	-- Routes
	.route({ method="GET", path = "/" }, route.game)
	.route({ method="GET", path = "/start" }, route.start)
	.route({ method="POST", path = "/refresh" }, route.refresh)
	.route({ method="POST", path = "/pick" }, route.pick)
	-- Start the server
	.start()
