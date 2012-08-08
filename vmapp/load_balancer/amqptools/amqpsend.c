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

#include <stdint.h>
#include <amqp.h>
#include <amqp_framing.h>

#include <unistd.h>
#include <assert.h>
#include <getopt.h>

#define BUFFERSIZE 8096

// from "example_utils.c"
void die_on_error(int x, char const *context) {
  if (x < 0) {
    char *errstr = amqp_error_string(-x);
    fprintf(stderr, "%s: %s\n", context, errstr);
    free(errstr);
    exit(1);
  }
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
    fprintf(stderr, "Usage: %s [options] exchange routingkey [message]\n", program_name);
    fprintf(stderr, "\n");
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --host/-h host         specify the host (default: \"amqpbroker\")\n");
    fprintf(stderr, "  --port/-P port         specify AMQP port (default: 5672)\n");
    fprintf(stderr, "  --vhost/-v vhost       specify vhost (default: \"/\")\n");
    fprintf(stderr, "  --file/-f filename     send contents of file as message\n");
    fprintf(stderr, "  --user/-u username     specify username (default: \"guest\")\n");
    fprintf(stderr, "  --password/-p password specify password (default: \"guest\")\n");
    fprintf(stderr, "  --persistent           mark message as persistent\n");
    fprintf(stderr, "  --no-persistent        mark message as not persistent\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "The following environment variables may also be set:\n");
    fprintf(stderr, "  AMQP_HOST, AMQP_PORT, AMQP_VHOST, AMQP_USER, AMQP_PASSWORD, AMQP_PERSISTENT\n");
    fprintf(stderr, "Acceptable values for AMQP_PERSISENT are '1' (Not Persistent) and '2' (Persistent)\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "With no -f option and no message, message contents will be read from standard input.\n"); 
    fprintf(stderr, "\n");
    fprintf(stderr, "Example:\n");
    fprintf(stderr, "$ amqpsend -h amqp.example.com -P 5672 amq.fanout mykey \"HELLO AMQP\"\n");
    fprintf(stderr, "$ amqpsend -h amqp.example.com -P 5672 amq.fanout mykey -f /etc/hosts\n");
    fprintf(stderr, "$ echo \"HELLO AMQP\" | amqpsend -h amqp.example.com -P 5672 amq.fanout mykey\n\n");
}

// shamelessly taken from the public domain
int load_file_into_memory(const char *filename,  char **result) {
  int size = 0;
  FILE *f = fopen(filename, "rb");
  if(f == NULL) {
    *result = NULL;
    return -1;
  }
  fseek(f, 0, SEEK_END);
  size = ftell(f);
  fseek(f, 0, SEEK_SET);
  *result = (char *)malloc(size);
  if(size != fread(*result, sizeof(char), size, f)) {
    free(*result);
    fclose(f);
    return -2;
  }
  fclose(f);
  return size;
}

int load_stdin_into_memory(char **file) {
  int size = 0, read = 0;
  char *buffer = (char *)malloc(sizeof(char) * BUFFERSIZE);
  do {
    size += (read = fread(buffer, sizeof(char), BUFFERSIZE, stdin));
    if (ferror(stdin)) {
      free(*file);
      free(buffer);
      return -1;
    }
    *file = (char *)realloc((void *)*file, sizeof(char) * size);
    memcpy(*file + (sizeof(char) * (size - read)), buffer, read);
  } while (read == BUFFERSIZE);   
  free(buffer);
  return size;
}

int main(int argc, char **argv) {
  char const *hostname = "amqpbroker"; // amqp hostname
  int port = 5672; // amqp port
  static int verbose_flag = 0; // be verbose?
  static int persistent = 1;
  int c; // for option parsing
  char const *exchange = "";
  char const *routingkey = "";
  char const *vhost = "/";
  char const *username = "guest";
  char const *password = "guest";
  char const *filename = NULL;
  amqp_bytes_t messagebody;

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
  if (NULL != getenv("AMQP_PERSISTENT"))
    persistent = atoi(getenv("AMQP_PERSISTENT"));

  while(1) {
    static struct option long_options[] =
    {
      {"verbose", no_argument,  &verbose_flag, 1},
      {"user", required_argument, 0, 'u'},
      {"password", required_argument, 0, 'p'},
      {"vhost", required_argument, 0, 'v'},
      {"host", required_argument, 0, 'h'},
      {"port", required_argument, 0, 'P'},
      {"file", required_argument, 0, 'f'},
      {"persistent", no_argument, &persistent, 2},
      {"no-persistent", no_argument, &persistent, 1},
      {"help", no_argument, 0, '?'},
      {0, 0, 0, 0}
    };
    int option_index = 0;
    c = getopt_long(argc, argv, "v:h:P:u:p:f:?",
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
        filename = optarg;
        break;
      case 'u':
        username = optarg;
        break;
      case 'p':
        password = optarg;
        break;
      case '?':
      default:
        print_help(argv[0]);
        exit(1);
    }
  }

  // if ((argc-optind) < 2 || (NULL == filename && (argc-optind) < 3)) {
  if ((argc-optind) < 2) {
    print_help(argv[0]);
    return 1;
  }
  exchange = argv[optind];
  routingkey = argv[optind+1];
  if(NULL == filename) {
    if ((argc-optind) >= 3) {
      messagebody = amqp_cstring_bytes(argv[optind+2]);
    } else {
      char *file = NULL;
      int size = load_stdin_into_memory(&file);
      if (size >= 0) {
        messagebody = (amqp_bytes_t) {.len = size, .bytes = (void *)file};
      } else {
        fprintf(stderr, "Error reading from STDIN\n");
        exit(size);
      }
    }
  } else {
    char *bytes = NULL;
    int size = load_file_into_memory(filename, &bytes);
    if(size >= 0) {
      messagebody = (amqp_bytes_t) {.len = size, .bytes = (void *)bytes};
    } else {
      fprintf(stderr, "Error reading from file: %s\n", filename);
      exit(size);
    }
  }

  if ((persistent != 1) && (persistent != 2)) {
	fprintf(stderr, "Value '%u' not valid AMQP_PERSIST value ('1' and '2' only)\n", persistent);
	exit(1);
  }

  conn = amqp_new_connection();

  die_on_error(sockfd = amqp_open_socket(hostname, port), "Opening socket");
  amqp_set_sockfd(conn, sockfd);
  die_on_amqp_error(amqp_login(conn, vhost, 0, 131072, 0,
                               AMQP_SASL_METHOD_PLAIN,
                               username, password),
		    "Logging in");
  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

  {
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = persistent; // persistent delivery mode
    die_on_error(amqp_basic_publish(conn,
                                    1,
                                    amqp_cstring_bytes(exchange),
                                    amqp_cstring_bytes(routingkey),
                                    0,
                                    0,
                                    &props,
                                    messagebody),
                 "Sending message");
  }

  if(NULL != filename) // he who allocates, shall free
    free(messagebody.bytes);
  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS),
                    "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS),
                    "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connectiong");
  return 0;
}
