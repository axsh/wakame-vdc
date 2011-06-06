PARTS="01_setup-base.sh 02_setup-ruby.sh 03_setup-wakame-vdc.sh 04_configure-startup.sh 91_generate-demo-resource.sh 99_setup-developer.sh"
SCRIPT_URI=https://github.com/hansode/wakame-vdc2-builder/raw/11.04/ubuntu/10.04/


all:
	@echo $@

fetch:
	for part in "$(PARTS)"; do [ -f $$part ] || wget --no-check-certificate $(SCRIPT_URI)/$$part; done

prepare: fetch
	for part in "$(PARTS)"; do chmod +x $$part; done

wakame: prepare
	sudo ./01_setup-base.sh
	sudo ./02_setup-ruby.sh
	sudo ./03_setup-wakame-vdc.sh
	# sudo ./04_configure-startup.sh
	@echo $@

demo: prepare
	sudo ./91_generate-demo-resource.sh
	@echo $@

developer: prepare
	sudo ./01_setup-base.sh
	sudo ./02_setup-ruby.sh
	# no need root authorization
	sudo su - wakame -c "`pwd`/99_setup-developer.sh"
	@echo $@

force-developer: clean developer
	@echo $@

development: developer

clean:
	for part in "$(PARTS)"; do [ -f $$part ] && rm -f $$part || :; done
