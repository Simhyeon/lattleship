# Setup environments
setup:
	# Install luvit + lit
	@curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
	@mkdir bin -p
	# Move binary files
	@mv luvit bin
	@mv luvi bin
	@mv lit bin
	# Install dependencies
	@./bin/lit install
	# Install rad
	@curl -OL https://github.com/Simhyeon/r4d/releases/download/1.8.0-rc.1/rad-musl-basic
	@cp rad-musl-basic ./bin/rad
	# Set appropriate permissions
	@chmod 755 ./bin/rad ./bin/luvit

# Build file to serve
# - Don't suppress
build: bundle.html

bundle.html: index.html style.css index.js
	./bin/rad -a fin index.html -o $@

# Serve
# - Don't suppress
serve: bundle.html
	./bin/luvit ./main.lua

.PHONY:
	rad
	luvit
