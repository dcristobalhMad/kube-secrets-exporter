package worker

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/dcristobalhMad/kube-secrets-exporter/pkg/metrics"
	"github.com/prometheus/client_golang/prometheus"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

func worker(id int, clientset *kubernetes.Clientset, namespaces <-chan string, wg *sync.WaitGroup) {
	defer wg.Done()
	for ns := range namespaces {
		secrets, err := clientset.CoreV1().Secrets(ns).List(context.TODO(), metav1.ListOptions{})
		if err != nil {
			log.Printf("Worker %d: Error fetching secrets in namespace %s: %v", id, ns, err)
			continue
		}

		for _, secret := range secrets.Items {
			if secret.CreationTimestamp.IsZero() {
				continue
			}
			modificationTime := secret.GetCreationTimestamp().Time

			// Format modification time as date string
			modificationDate := modificationTime.Format("2006-01-02 15:04:05")

			labels := prometheus.Labels{
				"namespace":   ns,
				"secret_name": secret.Name,
				"date":        modificationDate,
				"timestamp":   fmt.Sprintf("%d", modificationTime.Unix()), // keep Unix timestamp for reference
			}

			metrics.Mu.Lock()
			key := ns + "/" + secret.Name
			lastModTime, exists := metrics.LastModificationTimes[key]
			if !exists || modificationTime.After(lastModTime) {
				metrics.LastModificationTimes[key] = modificationTime
				metrics.SecretModifications.With(labels).Inc()
			}
			metrics.Mu.Unlock()

			metrics.SecretModificationTime.With(labels).Set(float64(modificationTime.Unix()))
		}
	}
}

func RecordSecretModificationTimes(clientset *kubernetes.Clientset, workerCount int) {
	start := time.Now()
	metrics.LastScanSuccess.Set(0) // Assume failure until successful completion

	namespaces, err := clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		log.Printf("Error fetching namespaces: %v", err)
		return
	}

	namespaceChan := make(chan string, len(namespaces.Items))
	var wg sync.WaitGroup

	for i := 0; i < workerCount; i++ {
		wg.Add(1)
		go worker(i, clientset, namespaceChan, &wg)
	}

	for _, ns := range namespaces.Items {
		namespaceChan <- ns.Name
	}
	close(namespaceChan)

	wg.Wait()

	duration := time.Since(start).Seconds()
	metrics.SecretScanDuration.Set(duration)
	metrics.LastScanSuccess.Set(1) // Successful scan

	metrics.LogMetrics() // Log metrics after each scan
}
