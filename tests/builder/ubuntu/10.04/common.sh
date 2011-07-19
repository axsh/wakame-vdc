
export LANG=C
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

which gem >/dev/null && {
  export PATH="$(gem environment gemdir)/bin:$PATH"
} || :
