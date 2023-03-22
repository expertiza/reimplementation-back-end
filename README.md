# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

### Design Document
https://expertiza.csc.ncsu.edu/index.php/CSC/ECE_517_Spring_2023_-_E2316._Reimplement_sign_up_sheet_controller.rb

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

https://user-images.githubusercontent.com/100992314/226822121-39cbd1a7-2724-4ca7-8052-a25fa7b67fea.mp4


### Add more ...
* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
