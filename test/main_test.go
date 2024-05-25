package main_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

func metricsHandlerMock(w http.ResponseWriter, r *http.Request) {
	// Simulate serving Prometheus metrics
	fmt.Fprintf(w, "# HELP kube_secret_last_modified_time Unix timestamp of the last modification time of the secret.\n")
	fmt.Fprintf(w, "# TYPE kube_secret_last_modified_time gauge\n")
	fmt.Fprintf(w, "kube_secret_last_modified_time{namespace=\"default\", secret_name=\"my_secret\"} 1622505600\n")

	fmt.Fprintf(w, "# HELP kube_secret_scan_duration_seconds Duration of the last scan for checking secret modifications in seconds.\n")
	fmt.Fprintf(w, "# TYPE kube_secret_scan_duration_seconds gauge\n")
	fmt.Fprintf(w, "kube_secret_scan_duration_seconds 5.23\n")

	fmt.Fprintf(w, "# HELP kube_secret_modifications_total Total number of modifications detected in secrets.\n")
	fmt.Fprintf(w, "# TYPE kube_secret_modifications_total counter\n")
	fmt.Fprintf(w, "kube_secret_modifications_total{namespace=\"default\", secret_name=\"my_secret\"} 3\n")

	fmt.Fprintf(w, "# HELP kube_secret_last_scan_success Indicates if the last scan was successful (1 for success, 0 for failure).\n")
	fmt.Fprintf(w, "# TYPE kube_secret_last_scan_success gauge\n")
	fmt.Fprintf(w, "kube_secret_last_scan_success 1\n")
}

func TestMetricsEndpointContentType(t *testing.T) {
	req, err := http.NewRequest("GET", "/metrics", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(metricsHandlerMock)

	handler.ServeHTTP(rr, req)

	// Check the content type
	expectedContentType := "text/plain; charset=utf-8"
	if contentType := rr.Header().Get("Content-Type"); contentType != expectedContentType {
		t.Errorf("handler returned wrong content type: got %v want %v",
			contentType, expectedContentType)
	}
}
