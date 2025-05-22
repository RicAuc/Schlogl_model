init.gen <- function() {
  
  yini.names <- "X1"
  y_ini <- 250
  
  names(y_ini) <- yini.names
  y_ini = y_ini[yini.names]
  
  return(y_ini)
}

kinetic_parameters <- function(file, n) {
  as.numeric(read.csv(file, header = FALSE)[[1]][n])
}

# da_vettore = function() {
#   
#   content = as.matrix(c(3.0e-07, 1.0e-04, 1.0e-03, 3.5e+00))
#   return(content)
#   
# }

init.sensitivity = function(n, min, max) {
  round(runif(n, min, max), 1)
}

target<-function(output)
{
  ret <- output[,"X1"]
  return(as.data.frame(ret))
}

msqd = function(reference, output) {

  reference[1,] -> times_ref
  reference[2,] -> X1_ref
  
  print("FLAG")
  
  # We will consider the same time points
  X1 <- output[which(output$Time %in% times_ref),"X1"]
  X1_ref <- X1_ref[which( times_ref %in% output$Time)]

  diff.X1 <- 1/length(times_ref)*sum(( X1 - X1_ref )^2 )

  return(diff.X1)
}

init.gen_extended <- function(n) {
  
  yini.names <- c("X_A", "X1", "X_B")
  y_ini <- c(100000, 250, 200000)
  
  names(y_ini) <- yini.names
  y_ini = y_ini[yini.names][n]
  
  return(y_ini)
}

k1_cal<-function(optim_v, n){return(optim_v[1])}
k2_cal<-function(optim_v, n) {return(optim_v[2])}
k3_cal<-function(optim_v, n) {return(optim_v[3])}
k4_cal<-function(optim_v, n) {return(optim_v[4])}
