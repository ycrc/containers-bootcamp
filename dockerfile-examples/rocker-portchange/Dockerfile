# comment with the "#"
# I want to change the port rstudio server listens on

# FROM the image layers stored on https://hub.docker.com/r/rocker/geospatial
# the tag 3.5.1 is tied to the R version
FROM rocker/geospatial:3.5.1

# Tell people who I am, my own version
LABEL maintainer="b.evans@yale.edu" version=0.01

# set an environment variable
ENV RSTUDIO_PORT=30301

# store that variable for rstudio server 
RUN echo "www-port=${RSTUDIO_PORT}" >> /etc/rstudio/rserver.conf