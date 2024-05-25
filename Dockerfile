FROM golang:1.22 as builder

WORKDIR /app

COPY . .

RUN go build -o kube-secrets-exporter cmd/main.go

FROM scratch

COPY --from=builder /app/kube-secrets-exporter /kube-secrets-exporter

ENTRYPOINT ["/kube-secrets-exporter"]
