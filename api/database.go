package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	"log"
	_ "github.com/lib/pq"
)

type User struct {
	Name     string
	Passhash string
}

func initDatabase() *gorm.DB {
	const NumAttempts = 5

	connection := fmt.Sprintf(
		"host=%s port=%d dbname=%s user=%s password=%s sslmode=disable",
		config.DB.Host, config.DB.Port, config.DB.Name, config.DB.User, config.DB.Pass)

	for attempt := 0; attempt < NumAttempts; attempt++ {
		db, err := gorm.Open("postgres", connection)
		if err == nil {
			log.Println("Connected to DB..")
			db.AutoMigrate(User{})
			log.Println("Finished running migrations")
			return db
		} else {
			log.Println(err)
		}
	}

	log.Fatalf("Could not connect to DB after %d attempts", NumAttempts)
	return nil
}
