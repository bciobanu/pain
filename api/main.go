package main

import (
	"encoding/json"
	"github.com/BurntSushi/toml"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	"github.com/jinzhu/gorm"
	"golang.org/x/crypto/bcrypt"

	"errors"
	"io/ioutil"
	"log"
	"net/http"
	"path/filepath"
	"strings"
	"sync/atomic"
	"time"
)

type Configuration struct {
	JwtKey     string
	JwtTimeout uint32

	DB struct {
		Host string
		Port uint32
		Name string
		User string
		Pass string
	}
}

type Status struct {
	Requests     uint64 `json:"requests"`
	TokensIssued uint64 `json:"tokensIssued"`
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
var db *gorm.DB

func getEncoder(w http.ResponseWriter, r *http.Request) *json.Encoder {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "http://localhost:8081") // TODO: change to website domain
	w.Header().Set("Access-Control-Allow-Credentials", "true")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS, POST, PUT")
	w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization")
	atomic.AddUint64(&status.Requests, 1)
	return json.NewEncoder(w)
}

func GetStatus(w http.ResponseWriter, r *http.Request) {
	getEncoder(w, r).Encode(status)
}

func issueToken(user string) (*http.Cookie, error) {
	expirationTime := time.Now().Add(time.Duration(config.JwtTimeout) * time.Minute)
	claim := &Claim{
		Name: user,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claim)
	tokenString, err := token.SignedString([]byte(config.JwtKey))
	if err != nil {
		log.Fatal("Could not issue JWT token")
		return nil, errors.New("Could not issue JWT token")
	}
	atomic.AddUint64(&status.TokensIssued, 1)
	return &http.Cookie{
		Name:    "Token",
		Value:   tokenString,
		Expires: expirationTime,
	}, nil
}

func getCredentials(r *http.Request) (*Claim, error) {
	cookie, err := r.Cookie("Token")
	if err != nil {
		if err == http.ErrNoCookie {
			return nil, errors.New("Unauthorized")
		}
		return nil, errors.New("Bad request")
	}

	tokenString := cookie.Value
	token, err := jwt.ParseWithClaims(tokenString, &Claim{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.JwtKey), nil
	})
	if err != nil {
		return nil, errors.New("Bad request")
	}
	claim, ok := token.Claims.(*Claim)
	if !ok || !token.Valid {
		return nil, errors.New("Unauthorized")
	}

	const AfterExpiryTimeout = -30 * time.Second
	if time.Unix(claim.ExpiresAt, 0).Sub(time.Now()) < AfterExpiryTimeout {
		return nil, errors.New("Bad request")
	}
	return claim, nil
}

func Register(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	var registerData Credentials
	err := json.NewDecoder(r.Body).Decode(&registerData)
	if err != nil {
		encoder.Encode(Error{Error: "Could not parse request JSON"})
		return
	}
	if len(registerData.Name) == 0 || len(registerData.Password) == 0 {
		encoder.Encode(Error{Error: "Invalid data"})
		return
	}

	passHash, err := bcrypt.GenerateFromPassword([]byte(registerData.Password), 10)
	if err != nil {
		encoder.Encode(Error{Error: "Internal error, could not encrypt password"})
		return
	}
	dbUser := &User{
		Name:     registerData.Name,
		Passhash: string(passHash),
	}
	if err := db.Create(dbUser).Error; err != nil {
		encoder.Encode(Error{Error: "User already exists"})
		return
	}

	token, err := issueToken(registerData.Name)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}
	http.SetCookie(w, token)
}

func Login(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	var credentials Credentials
	err := json.NewDecoder(r.Body).Decode(&credentials)
	if err != nil {
		encoder.Encode(Error{Error: "Could not parse JSON"})
		return
	}

	var user User
	if err := db.Where("name = ?", credentials.Name).First(&user).Error; err != nil {
		encoder.Encode(Error{Error: "Invalid username"})
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.Passhash), []byte(credentials.Password)); err != nil {
		encoder.Encode(Error{Error: "Invalid password"})
		return
	}
	token, err := issueToken(credentials.Name)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}
	http.SetCookie(w, token)
}

func Refresh(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	claim, err := getCredentials(r)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}
	token, err := issueToken(claim.Name)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}
	http.SetCookie(w, token)
	encoder.Encode(claim)
}

func isAllowedImageExtension(extension string) bool {
	switch extension {
	case
		"jpg",
		"jpeg",
		"png":
		return true
	}
	return false
}

func uploadImage(r *http.Request) (*string, error) {
	image, header, err := r.FormFile("image")
	if err != nil {
		return nil, errors.New("Invalid image")
	}
	defer image.Close()
	extension := strings.TrimSuffix(header.Filename, filepath.Ext(header.Filename))
	if !isAllowedImageExtension(extension) {
		return nil, errors.New("Invalid image extension")
	}

	imageData, err := ioutil.ReadAll(image)
	if err != nil {
		return nil, errors.New("Could not read image data")
	}

	imageFile, err := ioutil.TempFile("images", "*."+extension)
	imageFileName := imageFile.Name()
	if err != nil {
		log.Fatal(err)
		return nil, errors.New("Internal server error")
	}
	defer imageFile.Close()
	if _, err := imageFile.Write(imageData); err != nil {
		log.Fatal(err)
		return nil, errors.New("Internal server error")
	}
	return &imageFileName, nil
}

func UploadPainting(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	claim, err := getCredentials(r)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}

	const MaxParseMemory = 32 << 20 // 32 mb
	if err := r.ParseMultipartForm(MaxParseMemory); err != nil {
		encoder.Encode(Error{Error: "Could not parse request"})
		return
	}

	year, err := time.Parse(r.FormValue("Year"), "YYYY")
	if err != nil {
		encoder.Encode(Error{Error: "Bad year formatting"})
		return
	}
	imagePath, err := uploadImage(r)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}

	painting := &Painting{
		UserName:    claim.Name,
		Name:        r.FormValue("Name"),
		Artist:      r.FormValue("Artist"),
		Year:        year,
		Medium:      r.FormValue("Medium"),
		CreatedAt:   time.Now().UTC(),
		Description: r.FormValue("Description"),
		ImagePath:   *imagePath,
	}
	if err := db.Create(painting).Error; err != nil {
		encoder.Encode(Error{Error: "Could not save painting"})
		return
	}
}

func GetPaintings(w http.ResponseWriter, r *http.Request) {
	encoder := getEncoder(w, r)
	claim, err := getCredentials(r)
	if err != nil {
		encoder.Encode(Error{Error: err.Error()})
		return
	}
	var paintings *[]Painting
	if err := db.Where("username = ?", claim.Name).Find(&paintings).Error; err != nil {
		log.Fatal(err)
		encoder.Encode(Error{Error: "Internal DB error"})
		return
	}
	encoder.Encode(paintings)
}

func main() {
	if _, err := toml.DecodeFile("config.toml", &config); err != nil {
		log.Fatal(err)
		return
	}
	status = Status{}
	db = initDatabase()

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/status", GetStatus).Methods("GET", "OPTIONS")
	router.HandleFunc("/register", Register).Methods("POST", "OPTIONS")
	router.HandleFunc("/login", Login).Methods("POST", "OPTIONS")
	router.HandleFunc("/refresh", Refresh).Methods("POST", "OPTIONS")
	router.HandleFunc("/upload-painting", UploadPainting).Methods("POST", "OPTIONS")
	router.HandleFunc("/paintings", GetPaintings).Methods("GET", "OPTIONS")
	log.Fatal(http.ListenAndServe(":8080", router))
}
