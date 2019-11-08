package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/alexdzyoba/counter64"
	"github.com/gin-gonic/gin"
)

func main() {
	done := make(chan bool)
	counter := counter64.New()
	go counter.Count(done)

	start := time.Now()

	router := gin.Default()
	router.LoadHTMLFiles("templates/index.tmpl")
	router.GET("/", func(c *gin.Context) {
		val := counter.Read()
		dec := fmt.Sprintf("%020d", val)
		hex := fmt.Sprintf("0x%016x", val)
		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"decimal":     dec,
			"hexademical": hex,
			"started":     start,
		})
	})

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	go func() {
		err := srv.ListenAndServe()
		if err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v\n", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("shutdown server")

	done <- true
	ctx := context.Background()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("server shutdown error: %v", err)
	}
}
