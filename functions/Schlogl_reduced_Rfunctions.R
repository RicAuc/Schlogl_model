
init.gen <- function() {
  # places' names
  yini.names <- "X1"
  
  # initial marking
  y_ini <- c(250)
  
  names(y_ini) <- yini.names
  y_ini = y_ini[yini.names]
  
  return(y_ini)
}

kinetic_parameters = function(n, path.data) {
  
  kp = read.table(path.data, sep = "\n")
  k = kp[n, ]
  
  return(k)
}

