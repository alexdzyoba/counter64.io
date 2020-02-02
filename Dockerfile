FROM golang:1.13-alpine as builder
WORKDIR /counter64.io
COPY . .
RUN go install

FROM alpine:3.10
WORKDIR /app
COPY --from=builder /counter64.io/templates /app/templates
COPY --from=builder /go/bin/counter64.io /app/counter64.io
EXPOSE 8080
CMD ["/app/counter64.io"]
