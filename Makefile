include includes.mk

FLEET_VERSION=0.9.1

TEMPLATE_IMAGES=monitor osd gateway metadata
BUILT_IMAGES=base $(TEMPLATE_IMAGES)

DAEMON_IMAGE = $(IMAGE_PREFIX)ceph-daemon:$(BUILD_TAG)
DAEMON_DEV_IMAGE = $(DEV_REGISTRY)/$(DAEMON_IMAGE)
MONITOR_IMAGE = $(IMAGE_PREFIX)ceph-monitor:$(BUILD_TAG)
MONITOR_DEV_IMAGE = $(DEV_REGISTRY)/$(MONITOR_IMAGE)
GATEWAY_IMAGE = $(IMAGE_PREFIX)ceph-gateway:$(BUILD_TAG)
GATEWAY_DEV_IMAGE = $(DEV_REGISTRY)/$(GATEWAY_IMAGE)

SERVICE_TEMPLATES := $(shell cd services/templates && find *)
SERVERS :=1 2 3

build: check-docker
	@# Build base first due to dependencies
	docker build -t ceph-base:$(BUILD_TAG) base/
	$(foreach I, $(TEMPLATE_IMAGES), \
		sed -e "s/#FROM is generated dynamically by the Makefile/FROM ceph-base:${BUILD_TAG}/g" $(I)/Dockerfile.template > $(I)/Dockerfile ; \
		docker build -t ceph-$(I):$(BUILD_TAG) $(I)/ ; \
	)

push: check-docker check-registry
	$(foreach I, $(BUILT_IMAGES), \
		docker tag -f ceph-$(I):$(BUILD_TAG) $(IMAGE_PREFIX)ceph-$(I):$(BUILD_TAG) ; \
		docker push $(IMAGE_PREFIX)ceph-$(I):$(BUILD_TAG) ; \
		docker tag -f ceph-$(I):$(BUILD_TAG) $(IMAGE_PREFIX)ceph-$(I):latest ; \
		docker push $(IMAGE_PREFIX)ceph-$(I):latest ; \
	)

clean: check-docker check-registry
	$(foreach I, $(BUILT_IMAGES), \
		docker rmi $(IMAGE_PREFIX)ceph-$(I):$(BUILD_TAG) ; \
		docker rmi $(IMAGE_PREFIX)ceph-$(I):$(BUILD_TAG) ; \
	)

full-clean: check-docker check-registry
	$(foreach I, $(BUILT_IMAGES), \
		docker images -q $(IMAGE_PREFIX)ceph-$(I) | xargs docker rmi -f ; \
		docker images -q $(IMAGE_PREFIX)ceph-$(I) | xargs docker rmi -f ; \
	)

dev-release: push set-image

services-from-templates: check-awk
	@mkdir -p gen/services
	@$(foreach I, $(SERVICE_TEMPLATES), \
		awk '{while(match($$0,"[$$][$$]{[^}]*}")) {var=substr($$0,RSTART+3,RLENGTH -4);gsub("[$$][$$]{"var"}",ENVIRON[var])}}1' < services/templates/$I > gen/services/$I.service && \
		echo 'Created service file: $I.service' ; \
	)

show-machines:
	@export FLEETCTL_TUNNEL=$(shell vagrant ssh-config | sed -n "s/[ ]*HostName[ ]*//gp" | sed -n '1p'):$(shell vagrant ssh-config | sed -n "s/[ ]*Port[ ]*//gp" | sed -n '1p')
	@fleetctl list-machines

watch-cluster:
	watch -n .5 'fleetctl list-units ; echo "" ; fleetctl list-unit-files'

create-s3-test-user:
	vagrant ssh core-03 -- -t docker exec -it ceph-gateway radosgw-admin user create --uid=johndoe --display-name="John Doe" --email=john@example.com
