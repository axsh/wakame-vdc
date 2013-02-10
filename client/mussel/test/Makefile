all: test

test: unit component

unit:
	(cd $@ && make)
component:
	(cd $@ && make)
integration:
	(cd $@ && make)
acceptance:
	(cd $@ && make)

.PHONY: unit component integration acceptance
