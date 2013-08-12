Metric Libs
==============

Metric Libs is utility that collecting data, system monitoring and alerting.

### Build gem
```
$ gem build ./metric_libs.gemspec 
```
### Install gem
```
$ gem install ./metric_libs-0.0.1.gem
```
### Using

```
irb> require 'rubygems'
irb> require 'metric_libs'
irb> MetricLibs::TimeSeries.new
=> #<MetricLibs::TimeSeries:0x00000000fab9f0 @timeseries=#<SortedSet: {}>>
```

License
---------

Copyright (c) Axsh Co.
Components are included distribution under LGPL 3.0 and Apache 2.0
