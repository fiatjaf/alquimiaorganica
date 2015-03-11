all:
	./node_modules/.bin/browserify -t coffeeify --extension=".coffee" app.coffee > bundle.js
	lessc site.less > site.css

watch:
	lessc site.less > site.css
	./node_modules/.bin/watchify -t coffeeify --extension=".coffee" app.coffee -o bundle.js

run:
	python -m SimpleHTTPServer 3000
