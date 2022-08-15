default:
	dune build

ds: default
	python3 -m http.server -d _build/default 2333

ghp: default
	rm -r site
	mkdir -p site
	cp -R _build/default/redraw.bc.js _build/default/main.js _build/default/index.html _build/default/src site
	ghp-import site
	git push origin gh-pages