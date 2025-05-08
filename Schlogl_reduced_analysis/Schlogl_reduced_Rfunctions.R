
init.gen <- function() {
  
  yini.names <- "X1"
  y_ini <- c(250)
  
  names(y_ini) <- yini.names
  y_ini = y_ini[yini.names]
  
  return(y_ini)
}

kinetic_parameters = function(path.data) {
  
  # path.data="./input/Schlogl_reduced/KineticsParameters"
  content <- readLines(path.data)
  # writeLines(content, path.data)
  
  parameters = as.matrix(as.double(content))
  
  return(parameters)
}

test = function() {
  
  # content = as.matrix(c(3.0e-07, 1.0e-04, 1.0e-03, 3.5e+00))
  content = as.matrix(c(222222, 3333333, 4444444, 5555555))
  
  return(content)
  
}

