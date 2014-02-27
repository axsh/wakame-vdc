#!/bin/bash

set -e

cd ${prefix_path}/dolphin
time bundle exec rake db:cassandra:clean
time bundle exec rake db:cassandra:migrate

exit 0
