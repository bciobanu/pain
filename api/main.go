package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"sync/atomic"
)

type Status struct {
	NumRequests uint64 `json:"numRequests"`
}

type Register struct {
	Name     string `json:"name"`
	Password string `json:"password"`
}

type Error struct {
	Error string `json:"error"`
}

var status Status

func getEncoder(w http.ResponseWriter, r *http.Request) *json.Encoder {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(200)
	atomic.AddUint64(&status.NumRequests, 1)
	return json.NewEncoder(w)
}

func getStatus(w http.ResponseWriter, r *http.Request) {
	getEncoder(w, r).Encode(status)
}

func register(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	var registerData Register
	err := json.NewDecoder(r.Body).Decode(&registerData)
	if err != nil {
		responseError := Error{
			Error: "Could not parse request JSON",
		}
		encoder.Encode(responseError)
		return
	}

	responseError := Error{
		Error: "Not implemented error",
	}
	encoder.Encode(responseError)
}

func main() {
	status = Status{}
	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/status", getStatus).Methods("GET")
	router.HandleFunc("/register", register).Methods("POST")
	log.Fatal(http.ListenAndServe(":8080", router))
}
