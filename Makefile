RELEASE_VERSION  =v0.1.5
SERVICE_NAME    ?=$(notdir $(shell pwd))
DOCKER_USERNAME ?=$(DOCKER_USER)
REMOTE_REPO_URL :=$(shell git config remote.origin.url)
PACKAGE_NAME    :=$(subst git@,,$(REMOTE_REPO_URL))
PACKAGE_NAME    :=$(subst .git,,$(PACKAGE_NAME))
PACKAGE_NAME    :=$(subst :,/,$(PACKAGE_NAME))

.PHONY: mod test run build dapr event image show imagerun lint clean, tag, init
all: test

tidy: ## Updates the go modules and vendors all dependencies 
	go mod tidy
	go mod vendor

test: mod ## Tests the entire project 
	go test -count=1 -race ./...

debug: tidy ## Runs uncompiled code in Dapr
	dapr run --app-id $(SERVICE_NAME) \
		 --app-port 50001 \
		 --protocol grpc \
		 --port 3500 \
         --components-path ./config \
         go run main.go

build: mod ## Builds local release binary
	CGO_ENABLED=0 go build -a -tags netgo -mod vendor -o bin/$(SERVICE_NAME) .

run: build ## Builds binary and runs it in Dapr
	dapr run --app-id $(SERVICE_NAME) \
		 --app-port 50001 \
		 --protocol grpc \
		 --port 3500 \
         --components-path ./config \
         bin/$(SERVICE_NAME) 

jsonevent: ## Publishes sample JSON message to Dapr pubsub API 
	curl -d '{ "from": "John", "to": "Lary", "message": "hi" }' \
     -H "Content-type: application/json" \
     "http://localhost:3500/v1.0/publish/events"

xmlevent: ## Publishes sample XML message to Dapr pubsub API 
	curl -d '<message><from>John</from><to>Lary</to></message>' \
     -H "Content-type: application/xml" \
     "http://localhost:3500/v1.0/publish/events"

binevent: ## Publishes sample binary message to Dapr pubsub API 
	curl -d '0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40' \
     -H "Content-type: application/octet-stream" \
     "http://localhost:3500/v1.0/publish/events"

image: mod ## Builds and publish docker image 
	docker build -t "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)" .
	docker push "$(DOCKER_USERNAME)/$(SERVICE_NAME):$(RELEASE_VERSION)"

lint: ## Lints the entire project 
	golangci-lint run --timeout=3m

tag: ## Creates release tag 
	git tag $(RELEASE_VERSION)
	git push origin $(RELEASE_VERSION)

clean: ## Cleans up generated files 
	go clean
	rm -fr ./bin
	rm -fr ./vendor

init: clean ## Resets go modules 
	rm -f go.*
	go mod init $(PACKAGE_NAME)
	go mod tidy 
	go mod vendor 

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk \
		'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
