library(RPostgres)
library(DBI)
library(quantregForest)
library(dplyr)
library(lubridate)
library(jsonlite)
library(dotenv)

# Load RFQR model
qrf <- readRDS(file = "qrf.rds")

#* Check token - Request body should contain a token to authenticate HTTP request
#* @filter checkAuth
function(req, res){
  
  request <- jsonlite::fromJSON(req$postBody)
  
  if(request$token != Sys.getenv('plumber_token_auth')) {
    
    return(list(message = "token is incorrect"))
    
  } else {
    plumber::forward()
  }
}

#* Update a table in PostGres -- Batch Deployment
#* @post /run
function(){
  
  # Connect to postgres database 
  con <- RPostgres::dbConnect(RPostgres::Postgres(),
                              dbname = Sys.getenv('dbname'), 
                              host = Sys.getenv('host'),
                              port = Sys.getenv('port'), # or any other port specified by your DBA
                              user = Sys.getenv('user'),
                              password = Sys.getenv('password'))
  
  # Read data
  input_data <- RPostgres::dbReadTable(con, 'input_data_ozone')
  
  # Fit model
  ## Split features and target variable
  X <- input_data[,c('Solar.R', 'Wind', 'Temp', 'Month', 'Day')]
  y <- input_data[, c('Ozone')]
  
  # Produce predictions for quantiles at every 4th quantile
  predictions <- predict(qrf, X, what = c(0.04, 0.5, 0.96))
  
  full_predictions <- cbind.data.frame(time = Sys.time(), predictions)
  
  # Write to DB
  RPostgres::dbWriteTable(conn = con, name = "Model_Predictions", value = full_predictions, overwrite = TRUE)
  
  # Close connection
  RPostgres::dbDisconnect(conn = con)
  
  return(list(message = "Update Successful"))
}