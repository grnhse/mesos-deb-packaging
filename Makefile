VERSION?=0.28.0
OS?=ubuntu
OS_VERSION=trusty
OS_ID=14.04
DATE=$(shell date -u +'%Y%m%d%H%M%S')
PREBUILT=?false
ifeq ($(PREBUILT),true)
  _PREBUILT=--prebuilt
else
  _PREBUILT=
endif

.PHONY: dist.tgz
dist.tgz:
	git ls-files | xargs tar czf dist.tgz

package: build/mesos-$(VERSION)-$(OS).deb

build/mesos-$(VERSION)-$(OS).deb: build_mesos docker.build_$(OS_VERSION)
	docker run --rm -ti -v $(CURDIR)/build:/usr/src/build \
	  mesos_build:$(OS_VERSION) \
	    ./build_mesos \
	    --build-version $(OS)-$(DATE) \
	    --nominal-version $(VERSION) $(_PREBUILT)

docker.build_trusty:
	docker build \
	  -t mesos_build:trusty \
	  -f Dockerfile.build_trusty \
	  .

docker.build_xenial:
	docker build \
	  -t mesos_build:xenial \
	  -f Dockerfile.build_xenial \
	  .

docker.run_trusty: # build/mesos-$(VERSION)-$(OS).deb
	@cp Dockerfile.trusty build/Dockerfile
	docker build \
	  -t mesos:trusty \
	  -f build/Dockerfile \
	  --build-arg DEB_NAME=mesos-$(VERSION)-$(OS)_$(OS_ID).deb \
	  build

docker.run_xenial: # build/mesos-$(VERSION)-$(OS).deb
	@cp Dockerfile.xenial build/Dockerfile
	docker build \
	  -t mesos:xenial \
	  -f build/Dockerfile \
	  --build-arg DEB_NAME=mesos-$(VERSION)-$(OS)_$(OS_ID).deb \
	  build

clean:
	rm -f build/* *.deb *.egg *.rpm dist.tgz

dist-clean: clean
	sudo rm -rf mesos-repo

docker-clean:
	docker rmi -f \
	  mesos:xenial \
	  mesos:trusty \
	  mesos_build:trusty \
	  mesos_build:xenial
