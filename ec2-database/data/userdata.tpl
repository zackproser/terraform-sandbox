#!/bin/bash 

sudo docker pull zackproser/go-hello-world:latest

sudo docker run -d -p 80:80 zackproser/go-hello-world:latest

echo "Docker run exit code $?"

sudo docker ps -a 
