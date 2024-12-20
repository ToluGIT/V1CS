#Base image
FROM ubuntu:latest

#Simulate malware sample
RUN apt update && apt install -y curl && curl -OL https://secure.eicar.org/eicarcom2.zip
