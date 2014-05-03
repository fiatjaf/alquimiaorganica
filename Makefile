all:
	coffee --bare -c .
	lessc site.less > site.css

run:
	make
	python -m SimpleHTTPServer 3000
