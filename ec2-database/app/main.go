package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	fmt.Println("App starting up...")

	// Ensure the DB connection string was passed in on startup
	dbConnString := os.Getenv("DB_CONNECTION_URI")
	if dbConnString == "" {
		panic("Must provide a valid DB connection URI via environment variable DB_CONNECTION_URI")
	}

	user := "golang"
	password := "gocrazy999"

	connectionString := fmt.Sprintf("%s:%s@tcp(%s)/golang_webservice", user, password, dbConnString)

	db, err := sql.Open("mysql", connectionString)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		panic(fmt.Sprintf("Error pinging the database: %s", err))
	} else {
		fmt.Println("Pinged database successfully!")
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("Request received from: %v\n", r.Header.Get("User-Agent"))

		rows, err := db.Query("update visits set hits = hits + 1")
		if err != nil {
			fmt.Printf("Error updating hit count: %s", err)
		}
		rows.Close()

		var count int
		selectErr := db.QueryRow("select hits from visits").Scan(&count)

		if selectErr != nil {
			fmt.Printf("Error selecting hit count: %s", selectErr)
		}

		fmt.Fprintf(w, fmt.Sprintf("Go web service up and running! Total page views: %v", count))
	})

	http.ListenAndServe(":80", nil)
}
