# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

### System Dependencies
* Ruby version - 3.2.1
* Mysql2 (gem) - 0.5.5

### Configuration
* Changed database username, password
* Renamed yml file

### Database Initialization
* Install MySQL
  * Mac - ``` brew install mysql ```
* Install gem mysql2
* ```bundle install ```
* Start MySQL Server - ``` mysql.server start ```
* Login as root
  * Create new user - ``` CREATE USER '<username>'@'localhost' IDENTIFIED BY '<password>'; ```
  * Grant privileges - ``` GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO '<username>'@'localhost' WITH GRANT OPTION; ```

### Database initialization
* ```rake db:create```
* ```rake db:migrate```

### Swagger Tests
```rails rswag:specs:swaggerize```

Runs Swagger API Document creation

Creates a .yaml file.

Run ```rails s```

Documentation page - ```<host-name>/api-docs```

### Testing

[![SC2 Video](https://img.youtube.com/vi/ZAh80Gj5A5U/0.jpg)](http://www.youtube.com/watch?v=ZAh80Gj5A5U)

### Add more ...
* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
