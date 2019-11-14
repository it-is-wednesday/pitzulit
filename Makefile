build:
	dune build bin/main.exe
	cp _build/default/bin/main.exe ./pitzulit

test:
	dune runtest
