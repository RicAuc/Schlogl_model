init.gen <- function() {
  
  yini.names <- "X1"
  y_ini <- c(250)
  
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
