# E2370 Join Team Requests Controller (Expertiza Backend Re-Implementation)
![GitHub top language](https://img.shields.io/github/languages/top/manoj-ayyappan/csc517_program3_E2370)
![GitHub contributors](https://img.shields.io/github/contributors/manoj-ayyappan/csc517_program3_E2370)
![GitHub repo size](https://img.shields.io/github/repo-size/manoj-ayyappan/csc517_Program3_E2370)
<img src=https://img.shields.io/badge/License-MIT-red></img>


These are the requirements for the project - 

* Ruby version - 3.2.1
* Rails version - 7.0.4.2

These links mey help you to install Ruby and Ruby on Rails on your Mac
1. Ruby on Rails guide 1 [Click here](https://mac.install.guide/rubyonrails/5.html)
2. Ruby on Rails guide 2 [Click here](https://mac.install.guide/rubyonrails/7.html)

## Development Environment

### Prerequisites
- Verify that [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running.
- [Download](https://www.jetbrains.com/ruby/download/) RubyMine
- Make sure that the Docker plugin [is enabled](https://www.jetbrains.com/help/ruby/docker.html#enable_docker).

### Instructions
Tutorial: [Docker Compose as a remote interpreter](https://www.jetbrains.com/help/ruby/using-docker-compose-as-a-remote-interpreter.html)

### Work done
- Created new methods for the Join Team Requests Controller to support CRUD functionality. 
- Added an accept and decline method. 
- Modified the status to use constants such as 'PENDING', 'ACCEPTED', and 'DECLINED' instead of 'P', 'D', 'A'.

### Video Tutorial

<a href="http://www.youtube.com/watch?feature=player_embedded&v=BHniRaZ0_JE
" target="_blank"><img src="http://img.youtube.com/vi/BHniRaZ0_JE/maxresdefault.jpg" 
alt="IMAGE ALT TEXT HERE" width="560" height="315" border="10" /></a>

### Database Credentials
- username: root
- password: expertiza

### Future Work
We have already tested the program using Postman but Swagger for some reason does not recognise our testing requests and fails to work. 
- Testing using Swagger

### Team
1. Manoj Ayyappan
2. Pradeep Patil
3. Maya Patel
