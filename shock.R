# Initial attempt to calculate  shock => volume jump * price change
library(TTR)
# Calculate the shock using weekly and monthly vwap delta
#
shock.2 <- function(symbol, db) {
  query <- paste("select * from bhav where symbol = '", symbol, "' and series='EQ'", sep='')
  bhav <- dbGetQuery(db, query)
  bhav$date  <-  as.Date(bhav$date, format='%Y-%m-%d')
  bhav <- bhav[,c("date", "tottrdqty", "tottrdval")]
 
  bhav$vwap <- bhav$tottrdval / bhav$tottrdqty
  
  bhav$vwap.w <- NA
  for (i in (5:nrow(bhav))) { 
    bhav$vwap.w[i] <- sum(bhav$tottrdval[(i-4):i]) /  sum(bhav$tottrdqty[(i-4):i])
  }
  
  bhav$vwap.m <- NA
  for (i in (20:nrow(bhav))) { 
    bhav$vwap.m[i] <- sum(bhav$tottrdval[(i-19):i]) /  sum(bhav$tottrdqty[(i-19):i])
  }
  
  bhav$shock.w <- c(NA, diff(log(bhav$vwap.w))*100)
  bhav$shock.m <- c(NA, diff(log(bhav$vwap.m))*100)
  
  bhav$ret   <- c(NA, diff(log(bhav$vwap)))
  bhav$ret.5d <- NA
  for (i in (1:(nrow(bhav)-5)) ) { bhav$ret.5d[i] <- sum(bhav$ret[(i+1):(i+5)]) }
  bhav$ret.20d <- NA
  for (i in (1:(nrow(bhav)-20)) ) { bhav$ret.20d[i] <- sum(bhav$ret[(i+1):(i+20)]) }
  
  return(bhav)
  
}

effect.ma <- function(symbol, db) {
  #query <- paste("select * from delivery where symbol = '", symbol, "' and series='EQ'", sep='')
  #volume <- dbGetQuery(db, query)
  #volume$date  <-  as.Date(volume$date, format='%Y-%m-%d')
  query <- paste("select * from bhav where symbol = '", symbol, "' and series='EQ'", sep='')
  bhav <- dbGetQuery(db, query)
  bhav$date  <-  as.Date(bhav$date, format='%Y-%m-%d')
  bhav <- bhav[,c("date", "tottrdqty", "tottrdval")]
  #volume <- volume[, c("date", "percent")]
  #df <- merge(bhav, volume, by="date")
  df <- bhav
  df$vwap <- df$tottrdval / df$tottrdqty
  df$vwap.50d <- SMA(df$vwap, n = 50)
  df$vwap.200d <- SMA(df$vwap, n = 200)
  
  df$flag.50d <- ifelse(df$vwap.50d > df$vwap, 1, 0)
  df$flag.200d <- ifelse(df$vwap.200d > df$vwap, 1, 0)
  
  df$ret   <- c(0.0, diff(log(df$vwap))) 
  
  df$ret.5d <- NA
  for (i in (1:(nrow(df)-5)) ) { df$ret.5d[i] <- sum(df$ret[(i+1):(i+5)]) }
  df$ret.20d <- NA
  for (i in (1:(nrow(df)-20)) ) { df$ret.20d[i] <- sum(df$ret[(i+1):(i+20)]) }
  
  return(df)
}


calc.shocks <- function(dbname="~/backup/longt/db/nsedata.db") {
  library(RSQLite)
  my.db <- dbConnect(SQLite(), dbname)
  all.shocks   <- NULL  
  idx <- read.csv('index.csv', sep=';')
  cnx500 <- idx[idx$INDEX_FLG=='CNX 500',]
  symbols <- cnx500[,2]
  for (s in symbols) {
    print(s)
    effect.symbol <- try(effect.ma(s, my.db))
    if(class(effect.symbol) == "try-error") next;
    
    n <- nrow(effect.symbol)
    df <- data.frame(symbol=s, effect.symbol[,c("date", "vwap", "flag.50d", "flag.200d", "ret.5d", "ret.20d")])
    all.shocks <- rbind(all.shocks, df)
    }
  return(all.shocks)
}