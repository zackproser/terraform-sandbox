package main

import (
	"fmt"
	"net/http"
)

func main() {
	fmt.Println("App starting up...")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("Request received from: %v\n", r.Header.Get("User-Agent"))
		fmt.Fprintf(w, "Go web service up and running!")
	})

	http.ListenAndServe(":80", nil)
}
