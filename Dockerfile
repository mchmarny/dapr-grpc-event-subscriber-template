FROM golang:1.14.4 as builder

WORKDIR /src/
COPY . /src/

ARG VERSION=v0.0.1-default

ENV VERSION=$VERSION
ENV GO111MODULE=on

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -a -tags netgo -ldflags \
    "-w -extldflags '-static' -X main.Version=${VERSION}" \
    -mod vendor -o ./service .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /src/service .

ENTRYPOINT ["./service"]
