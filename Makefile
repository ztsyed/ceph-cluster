include includes.mk


TEMPLATE_IMAGES=monitor osd gateway metadata
BUILT_IMAGES=base $(TEMPLATE_IMAGES)

SERVICE_TEMPLATES := $(shell cd services/templates && find *)

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

services-from-templates: check-awk check-registry
	@mkdir -p gen/services
	@$(foreach I, $(SERVICE_TEMPLATES), \
		awk '{while(match($$0,"[$$][$$]{[^}]*}")) {var=substr($$0,RSTART+3,RLENGTH -4);gsub("[$$][$$]{"var"}",ENVIRON[var])}}1' < services/templates/$I > gen/services/$I.service && \
		echo 'Created service file: $I.service' ; \
	)

watch-cluster:
	watch -n .5 'fleetctl list-units ; echo "" ; fleetctl list-unit-files'