package main

//We import 4 important libraries
//1. “net/http” to access the core go http functionality
//2. “fmt” for formatting our text
//3. “html/template” a library that allows us to interact with our html file.
//4. "time" - a library for working with date and time.
import (
	"fmt"
	"net/http"

	"html/template"
)

// Create a struct that holds information to be displayed in our HTML file
type Welcome struct {
	Name string
}

// Go application entrypoint
func main() {
	//Instantiate a Welcome struct object and pass in some random information.
	//We shall get the name of the user as a query parameter from the URL
	welcome := Welcome{"Anonymous"}

	//We tell Go exactly where we can find our html file. We ask Go to parse the html file (Notice
	// the relative path). We wrap it in a call to template.Must() which handles any errors and halts if there are fatal errors

	templates := template.Must(template.ParseFiles("/gratigen/templates/welcome-template.html"))

	//Our HTML comes with CSS that go needs to provide when we run the app. Here we tell go to create
	// a handle that looks in the gratigen directory, go then uses the "/gratigen/" as a url that our
	//html can refer to when looking for our css and other files.
	http.Handle("/stylesheets/",
		http.StripPrefix("/stylesheets/",
			http.FileServer(http.Dir("/stylesheets/"))))

	http.Handle("/gratigen/", //final url can be anything
		http.StripPrefix("/gratigen/",
			http.FileServer(http.Dir("/gratigen/")))) //Go looks in the relative "gratigen" directory first using http.FileServer(), then matches it to a
	//url of our choice as shown in http.Handle("/gratigen/"). This url is what we need when referencing our css files
	//once the server begins. Our html code would therefore be <link rel="stylesheet"  href="/gratigen/stylesheet/...">
	//It is important to note the url in http.Handle can be whatever we like, so long as we are consistent.

	//This method takes in the URL path "/" and a function that takes in a response writer, and a http request.
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {

		//Takes the name from the URL query e.g ?name=Martin, will set welcome.Name = Martin.
		if name := r.FormValue("name"); name != "" {
			welcome.Name = name
		}
		//If errors show an internal server error message
		//I also pass the welcome struct to the index.html file.
		if err := templates.ExecuteTemplate(w, "index.html", welcome); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})

	//Start the web server, set the port to listen to 8080. Without a path it assumes localhost
	//Print any errors from starting the webserver using fmt
	fmt.Println("Listening")
	fmt.Println(http.ListenAndServe(":8080", nil))
}
