package main

import (
	"context"
	"log"
	"os"
	"strings"

	"github.com/dapr/go-sdk/server/event"

	dapr "github.com/dapr/go-sdk/client"
	daprd "github.com/dapr/go-sdk/server/grpc"
)

var (
	// Version will be set during build
	Version = "v0.0.1-default"

	logger = log.New(os.Stdout, "", 0)

	servicePort = getEnvVar("PORT", "50001")
	topicName   = getEnvVar("TOPIC_NAME", "events")
	storeName   = getEnvVar("STORE_NAME", "store")

	daprClient dapr.Client
)

func main() {
	// create Dapr client
	c, err := dapr.NewClient()
	if err != nil {
		logger.Fatalf("error creating Dapr client: %v", err)
	}
	daprClient = c

	// create serving server and add to it a handler
	server, err := daprd.NewServer(servicePort)
	if err != nil {
		log.Fatalf("failed to start the server: %v", err)
	}

	// add handler to it a handler
	server.AddTopicEventHandler(topicName, eventHandler)

	// start the server to handle incoming events
	if err := server.Start(); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func eventHandler(event *event.TopicEvent) error {
	logger.Printf("received event ID:%s for topic:%s)", event.ID, event.Topic)

	//TODO: do something with that event

	logger.Printf("saving event ID:%s data:%s", event.ID, string(event.Data))
	return daprClient.SaveStateData(context.Background(), storeName, event.ID, event.Data)
}

func getEnvVar(key, fallbackValue string) string {
	if val, ok := os.LookupEnv(key); ok {
		return strings.TrimSpace(val)
	}
	return fallbackValue
}
