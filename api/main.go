package main

import (
	"encoding/json"
	"github.com/BurntSushi/toml"
	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

type Configuration struct {
	JwtKey     string
	JwtTimeout time.Duration
}

type Status struct {
	NumRequests uint64 `json:"numRequests"`
}

type Credentials struct {
	Name     string `json:"name"`
	Password string `json:"password"`
}

type Claim struct {
	Name string `json:"name"`
	jwt.StandardClaims
}

type Error struct {
	Error string `json:"error"`
}

var config Configuration
var status Status

func getEncoder(w http.ResponseWriter, r *http.Request) *json.Encoder {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(200)
	atomic.AddUint64(&status.NumRequests, 1)
	return json.NewEncoder(w)
}

func GetStatus(w http.ResponseWriter, r *http.Request) {
	getEncoder(w, r).Encode(status)
}

func Register(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	var registerData Credentials
	err := json.NewDecoder(r.Body).Decode(&registerData)
	if err != nil {
		encoder.Encode(Error{Error: "Could not parse request JSON"})
		return
	}

	responseError := Error{
		Error: "Not implemented error",
	}
	encoder.Encode(responseError)
}

func Login(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	var credentials Credentials
	err := json.NewDecoder(r.Body).Decode(&credentials)
	if err != nil {
		encoder.Encode(Error{Error: "Could not parse JSON"})
		return
	}

	// TODO: check credentials

	expirationTime := time.Now().Add(config.JwtTimeout)
	claim := &Claim{
		Name: credentials.Name,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claim)
	tokenString, err := token.SignedString([]byte(config.JwtKey))
	if err != nil {
		encoder.Encode(Error{Error: "JWT creation error"})
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name:    "token",
		Value:   tokenString,
		Expires: expirationTime,
	})
}

func Refresh(w http.ResponseWriter, r *http.Request) {
	atomic.AddUint64(&status.NumRequests, 1)

	cookie, err := r.Cookie("token")
	if err != nil {
		if err == http.ErrNoCookie {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	tokenString, claim := cookie.Value, &Claim{}
	token, err := jwt.ParseWithClaims(tokenString, claim, func(token *jwt.Token) (interface{}, error) {
		return config.JwtKey, nil
	})
	if err == jwt.ErrSignatureInvalid || !token.Valid {
		w.WriteHeader(http.StatusUnauthorized)
		return
	} else if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	const AfterExpiryTimeout = 30 * time.Second
	if time.Unix(claim.ExpiresAt, 0).Sub(time.Now()) > AfterExpiryTimeout {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	expirationTime := time.Now().Add(config.JwtTimeout)
	claim.ExpiresAt = expirationTime.Unix()
	newToken := jwt.NewWithClaims(jwt.SigningMethodHS256, claim)
	newTokenString, err := newToken.SignedString(config.JwtKey)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	http.SetCookie(w, &http.Cookie{
		Name:    "token",
		Value:   newTokenString,
		Expires: expirationTime,
	})
}

func main() {
	if _, err := toml.DecodeFile("config.toml", &config); err != nil {
		log.Fatal("Could not parse config file")
		return
	}
	status = Status{}

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/status", GetStatus).Methods("GET")
	router.HandleFunc("/register", Register).Methods("POST")
	router.HandleFunc("/login", Login).Methods("POST")
	router.HandleFunc("/entries", Refresh).Methods("POST")
	log.Fatal(http.ListenAndServe(":8080", router))
}
