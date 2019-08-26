FROM golang:1.8

WORKDIR /go/src/app
COPY basic-sample.go .

RUN go get -u github.com/lib/pq

CMD ["go", "run", "basic-sample.go"]