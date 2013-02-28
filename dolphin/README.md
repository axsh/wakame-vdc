
# Dolphine

Dolphine is notification service.

### Copy Settings File

```
$ cp -ip ./config/settings.example ./config/settings
```

### Edit settings

```
$ vi ./config/settings
```

./config/settings
```
from=yourname@yourdomain
```

### Start Service

```
$ ./bin/server
```

```
INFO -- : [9089060] [Dolphin::RequestHandler] Listening on http://127.0.0.1:3000
```

### Add Notification

```
$ MAIL_TO=example@example.com ruby ./example/client/notification.rb post
```

### Add Event

```
$ ruby ./example/client/event.rb post
```

### Tempolary mail

```
$ ls ./tmp/mails
```

### Run Test Case

```
$ bundle exec rake spec
```
