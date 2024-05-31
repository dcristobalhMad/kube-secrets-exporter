package metrics

import (
	"log"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

var (
	SecretModificationTime = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "kube_secret_last_modified_time",
			Help: "Last modification time of Kubernetes secrets in Unix timestamp",
		},
		[]string{"namespace", "secret_name", "date", "timestamp"},
	)
	SecretScanDuration = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "kube_secret_scan_duration_seconds",
			Help: "Duration of the scan for checking secret modifications",
		},
	)
	SecretModifications = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "kube_secret_modifications_total",
			Help: "Total number of modifications detected in secrets",
		},
		[]string{"namespace", "secret_name", "date", "timestamp"},
	)
	LastScanSuccess = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "kube_secret_last_scan_success",
			Help: "Indicates if the last scan was successful (1 for success, 0 for failure)",
		},
	)
	LastModificationTimes = make(map[string]time.Time)
	Mu                    sync.Mutex
)

func init() {
	prometheus.MustRegister(SecretModificationTime)
	prometheus.MustRegister(SecretScanDuration)
	prometheus.MustRegister(SecretModifications)
	prometheus.MustRegister(LastScanSuccess)
}

func LogMetrics() {
	metrics, err := prometheus.DefaultGatherer.Gather()
	if err != nil {
		log.Printf("Error gathering metrics: %v", err)
		return
	}

	for _, metricFamily := range metrics {
		log.Printf("# HELP %s %s\n", metricFamily.GetName(), metricFamily.GetHelp())
		log.Printf("# TYPE %s %s\n", metricFamily.GetName(), metricFamily.GetType().String())
		for _, metric := range metricFamily.GetMetric() {
			log.Printf("%v\n", metric)
		}
	}
}
