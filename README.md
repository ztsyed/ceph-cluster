From this repository, you will generate Docker Containers and Fleet Service configuration for Ceph Cluster. Therefore, you **need** an existing fleet cluster running. It is also useful to have a private registry running. This registry should also be accessible to the target machines running the containers.

This work is inspired from http://github.com/peterrosell/ceph-coreos-vagrant, https://github.com/ceph/ceph-docker,and https://github.com/deis/deis/

## Set up your own docker registry

	docker run -d -v /path/to/registry_data:/registry -e STORAGE_PATH=/registry registry

Run this to set your docker registry. It will be used by the makefile. **Dont forget the trailing `/`**

	export DOCKER_REGISTRY=my-docker-server:5000/

## Create Fleet Services
This basically injects $DOCKER_REGISTRY in the service templates

``` bash
make services-from-templates
```
This will user `services/templates` to create services in `gen/services` folder.

## Build and Push Docker Containers

Make docker containers

``` bash
make build
```

Push containers to the registry
``` bash
make push
```

## Configure FleetCtl
If you are talking to a remote fleet cluster, use FLEETCTL_ENDPOINT

``` bash
export FLEETCTL_ENDPOINT=http://x.x.x.x:4001
```

Verify fleetctl is working

``` bash
fleetctl list-machines
```


## Start Cluster
First run bootstrap. This will create `/env/environment` file for each node in the cluster, which contains node's hostname, ip and machine id. We will source this file when launching services and the values to start services

``` bash
fleetctl start ceph-bootstrap.service
```

####Run Ceph Monitor

``` bash
fleetctl start ceph-monitor@1.service
```

####Run Ceph OSD
** You need preppare disks before launching this **
In the current setup, we **EXPECT** to have `dev/sda` that is formatted with btrfs. The command to format is `mkfs.btrfs --label osd_disk /dev/sda`.

``` bash
fleetctl start ceph-osd@1.service
```
if you want to run on all nodes, then use the following, assuming you have `n` number of nodes

``` bash
fleetctl start ceph-osd@{1..n}.service
```

####Run Ceph Medatadata

``` bash
fleetctl start ceph-metadata@1.service
```

####Run Ceph Gateway

``` bash
fleetctl start ceph-gateway@1.service
```


## Verify Cluster Status
Easiest way is to use the ceph-base container (we built that earlier) and  inside that use ceph to check cluster health

```bash
docker run -ti $DOCKER_REGISTRYceph-base /bin/bash
```
Inside the container
```bash
confd -onetime -config-file /app/confd.toml -node <YOUR_ETCD_HOST>:4001
```
The configuration is stored at /etc/ceph inside the container. Now run `ceph -w` to view the cluster status.

## Create S3 user

```bash
radosgw-admin user create --uid=johndoe --display-name="John Doe" --email=john@example.com
```