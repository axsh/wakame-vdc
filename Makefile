ruby_ver ?= 1.9.2-p290

# should be in wakame-vdc
CURDIR ?= $(PWD)
RUBYDIR ?= $(CURDIR)/ruby

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

build-ruby-stamp: ruby-build ruby install-core-gem bundle-install
	touch $@

ruby-build:
	(cd $(CURDIR); git clone https://github.com/sstephenson/ruby-build.git)

ruby:
	(cd $(CURDIR)/ruby-build; ./bin/ruby-build $(ruby_ver) $(RUBYDIR))

install-core-gem: install-core-gem-stamp
install-core-gem-stamp:
	gem install bundler rake --no-rdoc --no-ri
	touch $@

bundle-install: bundle-install-stamp
bundle-install-stamp:
	(cd $(CURDIR)/dcmgr && bundle install --standalone --path vendor/bundle)
	# Use hijiki gem in local since the local version is the latest.
	(cd $(CURDIR)/frontend/dcmgr_gui && mkdir -p vendor/cache)
	(cd $(CURDIR)/client/ruby-hijiki && rake gem && mv pkg/ruby-hijiki-*.gem ../../frontend/dcmgr_gui/vendor/cache)
	(cd $(CURDIR)/frontend/dcmgr_gui && bundle install --standalone --path vendor/bundle)
	touch $@

clean:
	rm -rf $(CURDIR)/ruby-build $(RUBYDIR)
	rm -rf $(CURDIR)/dcmgr/vendor/bundle
	rm -rf $(CURDIR)/frontend/dcmgr_gui/vendor/bundle
	rm -f $(CURDIR)/build-ruby-stamp
	rm -f $(CURDIR)/bundle-install-stamp
	rm -f $(CURDIR)/install-core-gem-stamp

.PHONY: build clean install-core-gem bundle-install
