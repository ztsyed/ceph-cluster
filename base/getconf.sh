#!/bin/bash -e
/usr/local/bin/confd -onetime -config-file /app/confd.toml -node $ETCD