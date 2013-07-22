ruby_ver ?= 2.0.0-p247

# should be in wakame-vdc
CURDIR ?= $(PWD)
RUBYDIR ?= $(CURDIR)/ruby

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

build-ruby-stamp: ruby-build ruby
	touch $@

ruby-build:
	(if [ -d ruby-build ]; then \
	  cd ruby-build; git pull; \
        else \
	  git clone $(RUBY_BUILD_REPO_URI); \
	fi)

ruby: ruby-stamp
ruby-stamp:
	(cd $(CURDIR)/ruby-build; ./bin/ruby-build $(ruby_ver) $(RUBYDIR))
	gem install bundler --no-rdoc --no-ri
	touch $@

clean:
	rm -rf $(CURDIR)/ruby-build $(RUBYDIR)
	rm -f $(CURDIR)/build-ruby-stamp
	rm -f $(CURDIR)/ruby-build-stamp
	rm -f $(CURDIR)/ruby-stamp

.PHONY: build ruby-build ruby clean bundle-install
