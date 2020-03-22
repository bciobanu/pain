package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/lib/pq"
	"log"
	"time"
)

type User struct {
	Name     string
	Passhash string
}

type Painting struct {
	UserName string
	Owner    User `gorm:"foreignkey:UserName"`

	Name        string
	Artist      string
	Year        time.Time
	Medium      string
	CreatedAt   time.Time
	Description string
	ImagePath   string
	Hits        uint32
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
			db.AutoMigrate(Painting{})
			log.Println("Finished running migrations")
			return db
		} else {
			log.Println(err)
		}
	}

	log.Fatalf("Could not connect to DB after %d attempts", NumAttempts)
	return nil
}
