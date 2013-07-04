ruby_ver ?= 1.9.3-p448

# should be in wakame-vdc
CURDIR ?= $(PWD)
RUBYDIR ?= $(CURDIR)/ruby

RUBY_MIRROR_SITE     ?= http://core.ring.gr.jp/archives/lang/ruby/
LIBYAML_MIRROR_SITE  ?= http://pyyaml.org/download/libyaml/
RUBYGEMS_MIRROR_SITE ?= http://production.cf.rubygems.org/rubygems/
RUBY_BUILD_REPO_URI  ?= https://github.com/sstephenson/ruby-build.git

CFLAGS := -fno-strict-aliasing
CXXFLAGS := -fno-strict-aliasing
# configure options set by ruby-build
CONFIGURE_OPTS := --disable-install-doc --enable-frame-address --enable-pthread --enable-ipv6 --with-bundled-sha1 --with-bundled-md5 --with-bundled-rmd160 --enable-rpath
ifneq (,$(findstring noopt,$(DEB_BUILD_OPTIONS)))
        CFLAGS += -g -O0
	CXXFLAGS += -g -O0
else
        CFLAGS += -g -O0
	CXXFLAGS += -g -O0
endif
export CFLAGS CXXFLAGS CONFIGURE_OPTS

PATH := $(RUBYDIR)/bin:${PATH}
export PATH

# unset GEM_HOME and GEM_PATH
unexport GEM_HOME GEM_PATH

build: build-ruby-stamp

build-ruby-stamp: ruby-build ruby bundle-install
	touch $@

ruby-build:
	(if [ -d ruby-build ]; then \
	  cd ruby-build; git pull; \
        else \
	  git clone $(RUBY_BUILD_REPO_URI); \
	fi)
	(cd $(CURDIR)/ruby-build; sed -i s,http://ftp.ruby-lang.org/pub/ruby/,$(RUBY_MIRROR_SITE), share/ruby-build/*)
	(cd $(CURDIR)/ruby-build; sed -i s,http://pyyaml.org/download/libyaml/,$(LIBYAML_MIRROR_SITE), share/ruby-build/*)
	(cd $(CURDIR)/ruby-build; sed -i s,http://production.cf.rubygems.org/rubygems/,$(RUBYGEMS_MIRROR_SITE), share/ruby-build/*)

ruby: ruby-stamp
ruby-stamp:
	(cd $(CURDIR)/ruby-build; ./bin/ruby-build $(ruby_ver) $(RUBYDIR))
	gem install bundler rake --no-rdoc --no-ri
	touch $@

bundle-install: bundle-install-stamp
bundle-install-stamp:
	(cd $(CURDIR)/dcmgr && bundle install --standalone --path vendor/bundle)
	# Use hijiki gem in local since the local version is the latest.
	(cd $(CURDIR)/frontend/dcmgr_gui && mkdir -p vendor/cache)
	(cd $(CURDIR)/frontend/admin && mkdir -p vendor/cache)
	(cd $(CURDIR)/tests/cucumber && mkdir -p vendor/cache)
	(cd $(CURDIR)/client/ruby-hijiki && rake gem && mv pkg/ruby-hijiki-*.gem ../../frontend/dcmgr_gui/vendor/cache)
	(cd $(CURDIR)/dolphin && mkdir -p vendor/cache)

	# in order to build rpm, client(ruby-hijiki)/ is no need.
	[ "$(RUBYDIR)" = "$(CURDIR)/ruby" ] || mv $(CURDIR)/client/ruby-hijiki $(CURDIR)/client/ruby-hijiki.saved
	(cd $(CURDIR)/frontend/dcmgr_gui && bundle install --standalone --path vendor/bundle)
	(cd $(CURDIR)/frontend/admin && bundle install --standalone --path vendor/bundle)
	(cd $(CURDIR)/dolphin && bundle install --standalone --path vendor/bundle)
	[ "$(RUBYDIR)" = "$(CURDIR)/ruby" ] || mv $(CURDIR)/client/ruby-hijiki.saved $(CURDIR)/client/ruby-hijiki

	touch $@

clean:
	rm -rf $(CURDIR)/ruby-build $(RUBYDIR)
	rm -rf $(CURDIR)/dcmgr/vendor/bundle
	rm -rf $(CURDIR)/frontend/dcmgr_gui/vendor/bundle
	rm -rf $(CURDIR)/frontend/admin/vendor/bundle
	rm -rf $(CURDIR)/dolphin/vendor/bundle
	rm -f $(CURDIR)/build-ruby-stamp
	rm -f $(CURDIR)/bundle-install-stamp
	rm -f $(CURDIR)/install-core-gem-stamp
	rm -f $(CURDIR)/ruby-build-stamp
	rm -f $(CURDIR)/ruby-stamp

.PHONY: build ruby-build ruby clean install-core-gem bundle-install
