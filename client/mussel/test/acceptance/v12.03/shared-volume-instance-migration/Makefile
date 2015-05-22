all: test

test:
	for i in ./t.*; do echo "Running $$i"; $$i || exit; done
