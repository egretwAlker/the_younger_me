default:
	dune build
# strict:
# 	dune build --release
ds: default
	python3 -m http.server -d _build/default 2333
