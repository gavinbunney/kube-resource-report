.PHONY: test docker push

IMAGE            ?= hjacobs/kube-resource-report
VERSION          ?= $(shell git describe --tags --always --dirty)
TAG              ?= $(VERSION)

default: docker

.PHONY:
install:
	poetry install

.PHONY:
lint: install
	poetry run pre-commit run --all-files

.PHONY:
test: install lint
	poetry run coverage run --source=kube_resource_report -m py.test
	poetry run coverage report

docker:
	docker build --build-arg "VERSION=$(VERSION)" -t "$(IMAGE):$(TAG)" .
	@echo 'Docker image $(IMAGE):$(TAG) can now be used.'

debug: docker
	kubectl proxy --accept-hosts .* &
	docker run --rm -it -e CLUSTERS=http://docker.for.mac.localhost:8001 --user=$(id -u) -v $(shell pwd)/output:/output $(IMAGE):$(TAG) /output
	pkill -9 -f "kubectl proxy"
	open output/index.html

push: docker
	docker push "$(IMAGE):$(TAG)"
	docker tag "$(IMAGE):$(TAG)" "$(IMAGE):latest"
	docker push "$(IMAGE):latest"

.PHONY: version
version:
	poetry version $(VERSION)
	sed -i 's,$(IMAGE):[0-9.]*,$(IMAGE):$(TAG),g' README.rst deploy/*.yaml
	sed -i 's,version: v[0-9.]*,version: v$(VERSION),g' deploy/*.yaml

.PHONY: release
release: push version
