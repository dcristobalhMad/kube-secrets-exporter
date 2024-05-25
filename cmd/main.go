package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/dcristobalhMad/kube-secrets-exporter/pkg/client"
	"github.com/dcristobalhMad/kube-secrets-exporter/pkg/worker"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	clientset, err := client.GetKubernetesClient()
	if err != nil {
		log.Fatalf("Error getting Kubernetes client: %v", err)
	}

	go func() {
		for {
			worker.RecordSecretModificationTimes(clientset, 5) // Adjust the number of workers as needed
			time.Sleep(5 * time.Minute)                        // Adjust the interval as needed
		}
	}()

	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})

	log.Println("Beginning to serve on port :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
