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

### Add more ...
* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...