/*
 * ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0
 *
 * The contents of this file are subject to the Mozilla Public License
 * Version 1.1 (the "License"); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and
 * limitations under the License.
 *
 * The Original Code is librabbitmq.
 *
 * The Initial Developers of the Original Code are LShift Ltd, Cohesive
 * Financial Technologies LLC, and Rabbit Technologies Ltd.  Portions
 * created before 22-Nov-2008 00:00:00 GMT by LShift Ltd, Cohesive
 * Financial Technologies LLC, or Rabbit Technologies Ltd are Copyright
 * (C) 2007-2008 LShift Ltd, Cohesive Financial Technologies LLC, and
 * Rabbit Technologies Ltd.
 *
 * Portions created by LShift Ltd are Copyright (C) 2007-2009 LShift
 * Ltd. Portions created by Cohesive Financial Technologies LLC are
 * Copyright (C) 2007-2009 Cohesive Financial Technologies
 * LLC. Portions created by Rabbit Technologies Ltd are Copyright (C)
 * 2007-2009 Rabbit Technologies Ltd.
 *
 * Portions created by Tony Garnock-Jones are Copyright (C) 2009-2010
 * LShift Ltd and Tony Garnock-Jones.
 *
 * All Rights Reserved.
 *
 * Contributor(s): ______________________________________.
 *
 * Alternatively, the contents of this file may be used under the terms
 * of the GNU General Public License Version 2 or later (the "GPL"), in
 * which case the provisions of the GPL are applicable instead of those
 * above. If you wish to allow use of your version of this file only
 * under the terms of the GPL, and not to allow others to use your
 * version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the
 * notice and other provisions required by the GPL. If you do not
 * delete the provisions above, a recipient may use your version of
 * this file under the terms of any one of the MPL or the GPL.
 *
 * ***** END LICENSE BLOCK *****
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <sys/socket.h>

#include <stdint.h>
#include <amqp.h>
#include <amqp_framing.h>

#include <unistd.h>
#include <assert.h>
#include <getopt.h>

#define AMQP_CHANNEL 1
#define DEFAULT_PREFETCH 10

// from "example_utils.c"
void die_on_error(int x, char const *context) {
  if (x < 0) {
    char *errstr = amqp_error_string(-x);
    fprintf(stderr, "%s: %s\n", context, errstr);
    free(errstr);
    exit(1);
  }
}

/* Handle interrupts, shutdown nicely */
static int g_shutdown = 0;

void term_handler(int signum) {
  g_shutdown = 1;
  fprintf(stderr, "\nShutting down...\n");
}
void install_term_handler(int signum) {
  struct sigaction action;
  action.sa_handler = term_handler;
  action.sa_flags = 0;
  
  sigaction(signum, &action, NULL);
}

// from "example_utils.c"
void die_on_amqp_error(amqp_rpc_reply_t x, char const *context) {
  switch (x.reply_type) {
    case AMQP_RESPONSE_NORMAL:
      return;

    case AMQP_RESPONSE_NONE:
      fprintf(stderr, "%s: missing RPC reply type!\n", context);
      break;

    case AMQP_RESPONSE_LIBRARY_EXCEPTION:
      fprintf(stderr, "%s: %s\n", context, amqp_error_string(x.library_error));
      break;

    case AMQP_RESPONSE_SERVER_EXCEPTION:
      switch (x.reply.id) {
        case AMQP_CONNECTION_CLOSE_METHOD: {
          amqp_connection_close_t *m = (amqp_connection_close_t *) x.reply.decoded;
          fprintf(stderr, "%s: server connection error %d, message: %.*s\n",
          context,
          m->reply_code,
          (int) m->reply_text.len, (char *) m->reply_text.bytes);
          break;
        }
        case AMQP_CHANNEL_CLOSE_METHOD: {
          amqp_channel_close_t *m = (amqp_channel_close_t *) x.reply.decoded;
          fprintf(stderr, "%s: server channel error %d, message: %.*s\n",
          context,
          m->reply_code,
          (int) m->reply_text.len, (char *) m->reply_text.bytes);
          break;
        }
        default:
          fprintf(stderr, "%s: unknown server error, method id 0x%08X\n", context, x.reply.id);
          break;
      }
    break;
  }

  exit(1);
}


void print_help(const char *program_name) {
  fprintf(stderr, "Usage: %s [options] exchange bindingkey\n", program_name);
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  --host/-h host         specify the host (default: \"amqpbroker\")\n");
  fprintf(stderr, "  --port/-P port         specify AMQP port (default: 5672)\n");
  fprintf(stderr, "  --vhost/-v vhost       specify vhost (default: \"/\")\n");
  fprintf(stderr, "  --queue/-q queue       specify queue name (default: auto-generated)\n");
  fprintf(stderr, "  --execute/-e program   program to execute\n");
  fprintf(stderr, "  --user/-u username     specify username (default: \"guest\")\n");
  fprintf(stderr, "  --password/-p password specify password (default: \"guest\")\n");
  fprintf(stderr, "  --number/-n n          retrieve a maxium n messages. 0 = unlimited (default: 0)\n");
  fprintf(stderr, "  --foreground/-f        do not daemonise (default: daemonise with -e)\n");
  fprintf(stderr, "  --passive              do not create the queue if it doesn't exist\n");
  fprintf(stderr, "  --exclusive            declare the queue as exclusive\n");
  fprintf(stderr, "  --durable              declare the queue should survive broker restart\n");
  fprintf(stderr, "  --no-ack               do not send acks to the server (WARNING: may cause data loss!)\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Refer to the AMQP documentation for full explanation of the passive,\n");
  fprintf(stderr, "exclusive and durable options.\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "The following environment variables may also be set:\n");
  fprintf(stderr, "  AMQP_HOST, AMQP_PORT, AMQP_VHOST, AMQP_USER, AMQP_PASSWORD, AMQP_QUEUE\n");
  fprintf(stderr, "  AMQP_QUEUE_PASSIVE, AMQP_QUEUE_EXCLUSIVE, AMQP_QUEUE_DURABLE\n\n");
  fprintf(stderr, "Program will be called with the following arguments: routing_key, tempfile\n");
  fprintf(stderr, "   tempfile contains the raw bytestream of the message\n\n");
  fprintf(stderr, "If program is not supplied, the above format will be printed to stdout\n\n");
  fprintf(stderr, "Example:\n");
  fprintf(stderr, "$ amqpspawn -h amqp.example.com -P 5672 -u guest -p guest \\\n");
  fprintf(stderr, "  amq.fanout mykey --foreground -e ./onmessage.sh\n\n");
  fprintf(stderr, "$ amqpspawn -h amqp.example.com -P 5672 -u guest -p guest -q myqueue --durable \\\n");
  fprintf(stderr, "  default animals.dogs.* --foreground \n\n");
}

int main(int argc, char **argv) {
  char const *hostname = "amqpbroker"; // amqp hostname
  int port = 5672; // amqp port
  static int verbose_flag = 0; // be verbose?
  static int foreground_flag = 0;
  static int passive = 0;  // declare queue passively?
  static int exclusive = 0;  // declare queue as exclusive?
  static int durable = 0;  // decalre queue as durable?
  static int no_ack = 0;
  static int msg_limit = 0; // maxiumum number of messages to retrieve
  int const no_local = 1;   // we never want to see messages we publish
  int c; // for option parsing
  char const *exchange = "";
  char const *bindingkey = "";
  char const *vhost = "/";
  char const *username = "guest";
  char const *password = "guest";
  char const *program = NULL;
  char const *program_args = NULL;
  amqp_bytes_t queue = AMQP_EMPTY_BYTES;

  int sockfd;
  amqp_connection_state_t conn;

  amqp_bytes_t queuename;

  if (NULL != getenv("AMQP_HOST"))
    hostname = getenv("AMQP_HOST");
  if (NULL != getenv("AMQP_PORT"))
    port = atoi(getenv("AMQP_PORT"));
  port = port > 0 ? port : 5672; // 5672 is the default amqp port
  if (NULL != getenv("AMQP_VHOST"))
    vhost = getenv("AMQP_VHOST");
  if (NULL != getenv("AMQP_USER"))
    username = getenv("AMQP_USER");
  if (NULL != getenv("AMQP_PASSWORD"))
    password = getenv("AMQP_PASSWORD");
  if (NULL != getenv("AMQP_QUEUE"))
    queue = amqp_cstring_bytes(getenv("AMQP_QUEUE"));
  if (NULL != getenv("AMQP_QUEUE_PASSIVE"))
    passive = atoi(getenv("AMQP_QUEUE_PASSIVE"));
  if (NULL != getenv("AMQP_QUEUE_EXCLUSIVE"))
    exclusive = atoi(getenv("AMQP_QUEUE_EXCLUSIVE"));
  if (NULL != getenv("AMQP_QUEUE_DURABLE"))
    durable = atoi(getenv("AMQP_QUEUE_DURABLE"));
  if (NULL != getenv("AMQP_MSG_LIMIT"))
    msg_limit = atoi(getenv("AMQP_MSG_LIMIT"));
  msg_limit = msg_limit > 0 ? msg_limit : 0; // default to unlimited

  while(1) {
    static struct option long_options[] =
    {
      {"verbose", no_argument,  &verbose_flag, 1},
      {"user", required_argument, 0, 'u'},
      {"password", required_argument, 0, 'p'},
      {"vhost", required_argument, 0, 'v'},
      {"host", required_argument, 0, 'h'},
      {"port", required_argument, 0, 'P'},
      {"number", required_argument, 0, 'n'},
      {"foreground", no_argument, 0, 'f'},
      {"passive", no_argument, &passive, 1},
      {"exclusive", no_argument, &exclusive, 1},
      {"durable", no_argument, &durable, 1},
      {"no-ack", no_argument, &no_ack, 1},
      {"execute", required_argument, 0, 'e'},
      {"queue", required_argument, 0, 'q'},
      {"help", no_argument, 0, '?'},
      {0, 0, 0, 0}
    };
    int option_index = 0;
    c = getopt_long(argc, argv, "v:h:P:u:p:n:fe:q:?",
                    long_options, &option_index);
    if(c == -1)
      break;

    switch(c) {
      case 0: // no_argument
        break;
      case 'v':
        vhost = optarg;
        break;
      case 'h':
        hostname = optarg;
        break;
      case 'P':
        port = atoi(optarg);
        port = port > 0 ? port : 5672; // 5672 is the default amqp port
        break;
      case 'f':
        foreground_flag = 1;
      case 'n':
        msg_limit = atoi(optarg);
        msg_limit = msg_limit > 0 ? msg_limit : 0; // deafult to unlimited
        break;
      case 'e':
        program = optarg;
        break;
      case 'u':
        username = optarg;
        break;
      case 'p':
        password = optarg;
        break;
      case 'q':
        queue = amqp_cstring_bytes(optarg);
        break;
      case '?':
      default:
        print_help(argv[0]);
        exit(1);
    }
  }

  if ((argc-optind) < 2) {
    print_help(argv[0]);
    return 1;
  }
  exchange = argv[optind];
  bindingkey = argv[optind+1];

  if (NULL != program) {
    // check that the program is executable
    char *wend;
    wend = strchr(program, ' ');
    if(wend){
        *wend = '\0';
        program_args = wend+1;
    }
    if (0 != access(program, X_OK)) {
        fprintf(stderr, "Program doesn't have execute permission, aborting: %s\n", program);
        exit(-1);
      }
    if(wend){
        *wend = ' ';
    }
  }

  if ((passive != 0) && (passive != 1)) {
    fprintf(stderr, "Queue option 'passive' must be 0 or 1: %u\n", passive);
    exit(-1);
  }
  if ((exclusive != 0) && (exclusive != 1)) {
    fprintf(stderr, "Queue option 'exclusive' must be 0 or 1: %u\n", exclusive);
    exit(-1);
  }
  if ((durable != 0) && (durable != 1)) {
    fprintf(stderr, "Queue option 'durable' must be 0 or 1: %u\n", durable);
    exit(-1);
  }

  conn = amqp_new_connection();

  die_on_error(sockfd = amqp_open_socket(hostname, port), "Opening socket");
  amqp_set_sockfd(conn, sockfd);
  die_on_amqp_error(amqp_login(conn, vhost,
                               0,         /* channel_max */
                               10485760,  /* max frame size, 10MB */
                               30,        /* heartbeat, 30 secs */
                               AMQP_SASL_METHOD_PLAIN,
                               username, password),
        "Logging in");
  amqp_channel_open(conn, AMQP_CHANNEL);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");
  {
    int optval = 1;
    socklen_t optlen = sizeof(optlen);
    setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, &optval, optlen);
  }
  {
    amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, AMQP_CHANNEL, queue, passive,
        durable, exclusive, 1, AMQP_EMPTY_TABLE);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring queue");
    queuename = amqp_bytes_malloc_dup(r->queue);
    if (queuename.bytes == NULL) {
      fprintf(stderr, "Out of memory while copying queue name\n");
      return 1;
    }
  }

  amqp_queue_bind(conn, AMQP_CHANNEL, queuename, amqp_cstring_bytes(exchange),
                  amqp_cstring_bytes(bindingkey), AMQP_EMPTY_TABLE);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Binding queue");

  /* Set our prefetch to the maximum number of messages we want to ensure we
   * don't take more than we want according to --number option from user */
  int prefetch_limit = DEFAULT_PREFETCH;
  if (msg_limit > 0 && msg_limit <= 65535)
    prefetch_limit = msg_limit;

  amqp_basic_qos(conn, AMQP_CHANNEL, 0, prefetch_limit, 0);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Setting Basic QOS (prefetch limit)");

  amqp_basic_consume(conn, AMQP_CHANNEL, queuename, AMQP_EMPTY_BYTES, no_local, no_ack, exclusive,
                     AMQP_EMPTY_TABLE);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Consuming");

  // If executing a program, daemonise
  if(NULL != program && 0 == foreground_flag)
  {
    pid_t pid, sid;
    pid = fork();
    if (pid < 0) {
      exit(EXIT_FAILURE);
    } else if(pid > 0) {
      exit(EXIT_SUCCESS);
    }
    umask(0);
    sid = setsid();
    if (sid < 0)
      exit(EXIT_FAILURE);
  }

  {
    amqp_frame_t frame;
    int result;
    int status = 0; /* wait() status, used whether to send ACK */

    amqp_basic_deliver_t *d;
    amqp_basic_properties_t *p;
    size_t body_target;
    size_t body_received;

    install_term_handler(SIGINT);
    install_term_handler(SIGTERM);
    install_term_handler(SIGHUP);

    int msg_count = 0;
    while (1) {
      char tempfile[] = "/tmp/amqp.XXXXXX";
      int tempfd;

      // exit if we've reached our maximum message count
      if((0 != msg_limit) && (msg_limit == msg_count))
        break;
      // we haven't reached our limit; move on to the next
      msg_count++;

      if(g_shutdown == 1)
          break;

      amqp_maybe_release_buffers(conn);
      result = amqp_simple_wait_frame(conn, &frame);
      //printf("Result %d\n", result);
      if (result < 0)
        break;

      //printf("Frame type %d, channel %d\n", frame.frame_type, frame.channel);
      if (frame.frame_type == AMQP_FRAME_HEARTBEAT) {
        // send the same heartbeat frame back
        amqp_send_frame(conn, &frame);
        continue;
      } else if (frame.frame_type != AMQP_FRAME_METHOD)
        continue;

      //printf("Method %s\n", amqp_method_name(frame.payload.method.id));
      if (frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD)
        continue;

      d = (amqp_basic_deliver_t *) frame.payload.method.decoded;
      /*
      printf("Delivery %u, exchange %.*s routingkey %.*s\n",
       (unsigned) d->delivery_tag,
       (int) d->exchange.len, (char *) d->exchange.bytes,
       (int) d->routing_key.len, (char *) d->routing_key.bytes);
      */
      result = amqp_simple_wait_frame(conn, &frame);
      if (result < 0)
        break;

      if (frame.frame_type != AMQP_FRAME_HEADER) {
        fprintf(stderr, "Expected header!");
        abort();
      }
      p = (amqp_basic_properties_t *) frame.payload.properties.decoded;
      /*
      if (p->_flags & AMQP_BASIC_CONTENT_TYPE_FLAG) {
  printf("Content-type: %.*s\n",
         (int) p->content_type.len, (char *) p->content_type.bytes);
      }
      printf("----\n");
      */
      body_target = frame.payload.properties.body_size;
      body_received = 0;

      tempfd = mkstemp(tempfile);
      //tempfd = open(tempfile, O_WRONLY | O_CREAT | O_EXCL, 660);
      while (body_received < body_target) {
        result = amqp_simple_wait_frame(conn, &frame);
        if (result < 0)
          break;

        if (frame.frame_type != AMQP_FRAME_BODY) {
          fprintf(stderr, "Expected body!");
          abort();
        }

        body_received += frame.payload.body_fragment.len;
        assert(body_received <= body_target);

        if (write(tempfd, frame.payload.body_fragment.bytes,
                          frame.payload.body_fragment.len) < 0) {
          perror("Error while writing received message to temp file");
        }
      }

      close(tempfd);

      {
        char *routekey = (char *)calloc(1, d->routing_key.len + 1);
        strncpy(routekey, (char *)d->routing_key.bytes, d->routing_key.len);

        if(NULL != program) {
          // fork and run the program in the background
          pid_t pid = fork();
          if (pid == 0) {
            if(execl(program, program, program_args, routekey, tempfile, NULL) == -1) {
              perror("Could not execute program");
              exit(EXIT_FAILURE);
            }
          } else {
            status = 0;
            wait(&status);
          }
        } else {
          // print to stdout & flush.
          printf("%s %s\n", routekey, tempfile);
          fflush(stdout);
        }
        free(routekey);
      }

      // send ack on successful processing of the frame
      if((0 == status) && (0 == no_ack))
        amqp_basic_ack(conn, frame.channel, d->delivery_tag, 0);


      if (body_received != body_target) {
        /* Can only happen when amqp_simple_wait_frame returns <= 0 */
        /* We break here to close the connection */
        break;
      }
    }
  }

  die_on_amqp_error(amqp_channel_close(conn, AMQP_CHANNEL, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connection");

  return 0;
}
