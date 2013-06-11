
# Dolphine

Dolphine is notification service.

### Copy Settings File

```
$ cp -ip ./config/dolphin.conf.example ./config/dolphin.conf
```

### Edit config

```
$ vi ./config/dolphin.conf
```

./config/dolphin.conf
```
from=yourname@yourdomain
```

### Start Service

```
$ ./bin/dolphin_server
```

```
I, [2013-03-12T14:41:17.533784 #27820]  INFO -- : [11950120] [Dolphin::RequestHandler] Running on ruby 1.9.3 with selected Celluloid::TaskThread
I, [2013-03-12T14:41:17.533922 #27820]  INFO -- : [11950120] [Dolphin::RequestHandler] Listening on http://127.0.0.1:9004
```

### Add Notification

```
$ MAIL_TO=example@example.com ruby ./example/client/put_notification.rb
```

### Add Event

```
$ ruby ./example/client/post_event.rb
```

### Tempolary mail

```
$ ls ./tmp/mails
```

### Run Test Case

```
$ bundle exec rake spec
```
