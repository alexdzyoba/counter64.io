run: install
	$(GOPATH)/bin/counter64.io

install:
	go install

build:
	docker build -t alexdzyoba/counter64.io .

push: build
	docker push alexdzyoba/counter64.io

.PHONY: run install build push
