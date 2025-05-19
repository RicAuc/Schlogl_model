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

da_vettore = function() {
  
  content = as.matrix(c(3.0e-07, 1.0e-04, 1.0e-03, 3.5e+00))
  return(content)
  
}

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

  # We will consider the same time points
  X1 <- output[which(output$Time %in% times_ref),"X1"]
  X1_ref <- X1_ref[which( times_ref %in% output$Time)]

  diff.X1 <- 1/length(times_ref)*sum(( X1 - X1_ref )^2 )

  return(diff.X1)
}

# msqd = function(reference, output) {
#   # Extract reference data
#   times_ref <- reference[1,]
#   X1_ref <- reference[2,]
#   
#   # Find matching time points in both datasets
#   matching_indices <- numeric(0)
#   ref_indices <- numeric(0)
#   
#   for (i in 1:length(output$Time)) {
#     for (j in 1:length(times_ref)) {
#       if (output$Time[i] == times_ref[j]) {
#         matching_indices <- c(matching_indices, i)
#         ref_indices <- c(ref_indices, j)
#       }
#     }
#   }
#   
#   # Extract X1 values at matching time points
#   X1 <- output$X1[matching_indices]
#   X1_ref_filtered <- X1_ref[ref_indices]
#   
#   # Calculate mean squared difference
#   diff.X1 <- 1/length(X1) * sum((X1 - X1_ref_filtered)^2)
#   
#   return(diff.X1)
# }
