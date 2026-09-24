
# Week 3: Containerizing the Incident Tracker

## What this does
Packages the Flask incident tracking app into a Docker image and runs it as a container, reachable on port 8080.

## Requirements
- Docker
- A .env file in app/ containing FLASK_SECRET_KEY

## Build and run
From the week-3 directory:

# Week 3: Containerizing the Incident Tracker

##What does it do:
The packages of the flask incident is tracking the app into a Docker image and runs as a container, to reachable on the port 8080

##Reqires:
- Docker
- .env file in app/ that contains FLASK_SECRET_KEY

##Build and running:
In the Week #3 directory:

cd app
docker build -t incident-tracker:1.0
docker run -d -p 8080:5000 --env-file .env --name incident-tracker incident-tracker:1.0

##Results:
curl http://localhost:8080
or
vist http://localhost:8080 through website

##Limitation:
Data doesn't persist if the container is removed since there is no persistent volume that is configured
