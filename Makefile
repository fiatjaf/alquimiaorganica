all:
	./node_modules/.bin/browserify -t coffeeify app.coffee > bundle.js
	lessc site.less > site.css

run:
	make
	python -m SimpleHTTPServer 3000
