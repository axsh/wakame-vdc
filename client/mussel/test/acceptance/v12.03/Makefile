all: test

test: 1shot lb-cluster instance-clone

1shot:
	(cd $@ && make)
lb-cluster:
	(cd $@ && make)
instance-clone:
	(cd $@ && make)

.PHONY: 1shot lb-cluster instance-clone
