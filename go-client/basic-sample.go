package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

const (
	host        = "roach1"
	port        = 26257
	user        = "jpointsman"
	dbname      = "jpointsmandb"
	sslrootcert = "/cockroach/cockroach-data/ca.crt"
	sslkey      = "/cockroach/cockroach-data/client.jpointsman.key"
	sslcert     = "/cockroach/cockroach-data/client.jpointsman.crt"
)

var (
	name string
)

func main() {
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s "+
		"dbname=%s sslmode=require ssl=true sslrootcert=%s sslkey=%s sslcert=%s",
		host, port, user, dbname, sslrootcert, sslkey, sslcert)

	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("error connecting to the database: ", err)
	}
	defer db.Close()

	rows, err := db.Query(
		"SHOW DATABASES;")
	if err != nil {
		log.Fatal(err)
	} else {

		for rows.Next() {
			err := rows.Scan(&name)
			if err != nil {
				log.Fatal(err)
			}
			log.Println(name)
		}
	}
}
