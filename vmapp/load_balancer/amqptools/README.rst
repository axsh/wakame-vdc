Command line AMQP clients
=========================

amqpspawn and amqpsend allow the simple sending and receiving of AMQP messages
from the command line or shell scripts.  You will require an existing AMQP
broker such as RabbitMQ to be running somewhere on an accessible network.

They use rabbitmq-c (http://hg.rabbitmq.com/rabbitmq-c/), and the rabbitmq
library can be statically compiled-in so as to only leave standard libc
dependencies.  The resident memory footprint is under one megabyte, making them
perfect for low resource environments.

amqpspawn
---------

amqpspawn binds to an exchange and queue using a binding key, and can spawn a
program on message retrieval, or send the same information to stdout.

There's a hardcoded maximum message size of 10MB.  If you need to send larger
messages, consider splitting them into smaller blocks.

$ ./amqpspawn --help::

  Usage: ./amqpspawn [options] exchange bindingkey
  Options:
    --host/-h host         specify the host (default: "amqpbroker")
    --port/-P port         specify AMQP port (default: 5672)
    --vhost/-v vhost       specify vhost (default: "/")
    --queue/-q queue       specify queue name (default: auto-generated)
    --execute/-e program   program to execute
    --user/-u username     specify username (default: "guest")
    --password/-p password specify password (default: "guest")
    --foreground/-f        do not daemonise (default: daemonise with -e)
    --passive              do not create the queue if it doesn't exist
    --exclusive            declare the queue as exclusive
    --durable              declare the queue should survive broker restart
  
  The following environment variables may also be set:
    AMQP_HOST, AMQP_PORT, AMQP_VHOST, AMQP_USER, AMQP_PASSWORD, AMQP_QUEUE
    AMQP_QUEUE_PASSIVE, AMQP_QUEUE_EXCLUSIVE, AMQP_QUEUE_DURABLE
  
  Program will be called with the following arguments: routing_key, tempfile
     tempfile contains the raw bytestream of the message
  
  If program is not supplied, the above format will be printed to stdout

  Example:
  $ amqpspawn -h amqp.example.com -P 5672 -u guest -p guest \
  amq.fanout mykey --foreground -e ./onmessage.sh


amqpsend
--------

amqpsend sends a message to an exchange using the specified routing key.
You may also pass a filename as input.
  
$ ./amqpsend --help::
  
  Usage: ./amqpsend [options] exchange routingkey [message]
  Options:
    --host/-h host         specify the host (default: "amqpbroker")
    --port/-P port         specify AMQP port (default: 5672)
    --vhost/-v vhost       specify vhost (default: "/")
    --file/-f filename     send contents of file as message
    --user/-u username     specify username (default: "guest")
    --password/-p password specify password (default: "guest")
    --persistent           mark message as persistent
    --no-persistent        mark message as NOT persistent
  
  The following environment variables may also be set:
    AMQP_HOST, AMQP_PORT, AMQP_VHOST, AMQP_USER, AMQP_PASSWORD, AMQP_PERSISENT
  Acceptable values for AMQP_PERSISENT are '1' (No Persist) and '2' (Persist)

  With no -f option and no message, message contents will be read from standard
  input. 
  
  Example:
  $ amqpsend -h amqp.example.com -P 5672 amq.fanout mykey "HELLO AMQP"
  $ amqpsend -h amqp.example.com -P 5672 amq.fanout mykey -f /etc/hosts
  $ echo "HELLO AMQP" | amqpsend -h amqp.example.com -P 5672 amq.fanout mykey
  
