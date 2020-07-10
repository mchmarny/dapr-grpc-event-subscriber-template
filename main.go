package main

import (
	"log"
	"os"
	"strings"

	"github.com/dapr/go-sdk/server/event"

	daprd "github.com/dapr/go-sdk/server/grpc"
)

var (
	logger      = log.New(os.Stdout, "", 0)
	servicePort = getEnvVar("PORT", "50001")
	topicName   = getEnvVar("TOPIC_NAME", "events")
)

func main() {
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

	return nil
}

func getEnvVar(key, fallbackValue string) string {
	if val, ok := os.LookupEnv(key); ok {
		return strings.TrimSpace(val)
	}
	return fallbackValue
}
