all:
	coffee --bare -c .
	lessc default.less > site.css

run:
	coffee --bare -c .
	lessc default.less > site.css
	python -m SimpleHTTPServer 3000
