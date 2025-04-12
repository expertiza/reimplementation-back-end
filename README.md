# Expertiza Backend Re-Implementation

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version - 3.2.1

## Development Environment

### Prerequisites
- Verify that [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running.
- [Download](https://www.jetbrains.com/ruby/download/) RubyMine
- Make sure that the Docker plugin [is enabled](https://www.jetbrains.com/help/ruby/docker.html#enable_docker).


### Instructions
Tutorial: [Docker Compose as a remote interpreter](https://www.jetbrains.com/help/ruby/using-docker-compose-as-a-remote-interpreter.html)

### Video Tutorial

<a href="http://www.youtube.com/watch?feature=player_embedded&v=BHniRaZ0_JE
" target="_blank"><img src="http://img.youtube.com/vi/BHniRaZ0_JE/maxresdefault.jpg" 
alt="IMAGE ALT TEXT HERE" width="560" height="315" border="10" /></a>

### Database Credentials
- username: root
- password: expertiza 


# Password Reset Testing Guide

## Overview
The deployment does not allow creating new users. To facilitate testing, we have manually added a test email into the database. Follow the steps below to test the password reset functionality.

## Steps for Testing

1) Go to [http://152.7.177.227:3000/login](http://152.7.177.227:3000/login) and click on 'forget password' button.

2) Input the email address: **testoodd1234@gmail.com** and click on request password. 

3) Open another tab and log into Gmail using the following credentials:

   - **Email:** `testoodd1234@gmail.com`  
   - **Pass:** `Test@1234`

4) After logging in, you should be able to see the inbox and there should be an email from Expertiza Mailer(check spam folder if you don't see the email). Open the email and click on the link to reset the password. 

5) Type in the new password and reset it. Then head back to [http://152.7.177.227:3000/login](http://152.7.177.227:3000/login) and try logging in with the email and the new password that you set up.
