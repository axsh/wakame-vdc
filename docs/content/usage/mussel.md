## Overview

In this guide we are going to cover the most basic Wakame-vdc functionality using the Mussel CLI. Wakame-vdc uses a RESTful Web API to take commands from its users. Any tool that can send basic HTTP requests is able to interface with Wakame-vdc. For example the following [cURL](http://curl.haxx.se) command could be used to start an [instance](../jargon-dictionary.md#hva).

    curl -fsSkL \
     -H X_VDC_ACCOUNT_UUID:a-shpoolxx \
     -X POST \
     --data-urlencode cpu_cores=1 \
     --data-urlencode hypervisor=openvz \
     --data-urlencode image_id=wmi-lbnode1d64 \
     --data-urlencode memory_size=256 \
     --data-urlencode ssh_key_id=ssh-ruekc3bs \
     --data-urlencode ~/myinstance/vifs.json \
     http://127.0.0.1:9001/api/12.03/instances.yml

Always typing cURL commands wouldn't be very convenient though. For one, it doesn't tell you which arguments the API takes. Also you would have to remember very specific details about the API. For example, the above command shows that the account UUID goes in the HTTP header. It also shows that the WebAPI's full path is `http://<webapi-ip-address>:<webapi-port>/api/<webapi-version>/<resource>.<output-format>`. That's a lot to remember.

The Mussel CLI client is actually an extensive [Bash](https://www.gnu.org/software/bash/bash.html) script that wraps around cURL. Executing the cURL command from above in Mussel would look like this:

    mussel instance create \
     --cpu-cores   1 \
     --hypervisor  openvz \
     --image-id    wmi-lbnode1d64 \
     --memory-size 256 \
     --ssh-key-id  ssh-ruekc3bs \
     --vifs        ~/myinstance/vifs.json
