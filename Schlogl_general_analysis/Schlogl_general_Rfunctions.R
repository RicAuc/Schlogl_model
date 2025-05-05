
init.gen <- function() {
  # places' names
  yini.names <- "X1"
  
  # initial marking
  y_ini <- c(250)
  
  names(y_ini) <- yini.names
  y_ini = y_ini[yini.names]
  
  return(y_ini)
}
