all: test

test: 1shot lb-cluster instance-clone sg-cluster alarm

1shot:
	(cd $@ && make)
lb-cluster:
	(cd $@ && make)
instance-clone:
	(cd $@ && make)
sg-cluster:
	(cd $@ && make)
alarm:
	(cd $@ && make)

.PHONY: 1shot lb-cluster instance-clone sg-cluster alarm
