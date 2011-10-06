all: deploy-manifest

deploy-manifest:
	find manifest -type f | sed s,^manifest/,, | while read line; do \
	  echo ... $$line; \
	  [ -f /$$line ] || sudo cp manifest/$$line /$$line; \
	  diff manifest/$$line /$$line || sudo cp manifest/$$line /$$line; \
	done
