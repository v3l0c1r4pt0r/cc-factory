FROM ubuntu:12.04

RUN apt-get update && apt-get upgrade -yq && apt-get install -yq gcc
