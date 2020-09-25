FROM rocker/verse:4.0.2

RUN R -e "install.packages(c('RPostgres', 'DBI', 'dplyr' ,'lubridate', 'plumber', 'httr', 'quantregForest', 'jsonlite'), repos = 'http://cran.us.r-project.org')"

RUN R -e "install.packages(c('dotenv'), repos = 'http://cran.us.r-project.org')"


COPY plumber.R plumber.R
COPY .env .env
COPY qrf.rds qrf.rds

EXPOSE 8000

ENTRYPOINT ["R", "-e", "library(plumber); library(RPostgres); library(jsonlite); library(quantregForest); library(dotenv); plumb('plumber.R')$run(port=8000, host='0.0.0.0')"]

