  return {
    name = "simoncreek/lattleship",
    version = "0.0.1",
    description = "Battleship game for web",
    tags = { "lua", "lit", "luvit" },
    license = "MIT",
    author = { name = "simoncreek", email = "simoncreek@tutanota.com" },
    homepage = "https://github.com/simhyeon/lattleship",
	dependencies = {
		"creationix/weblit",
	},
    files = {
      "**.lua",
      "!test*"
    }
  }
