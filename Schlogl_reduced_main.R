
library(epimod)
# downloadContainers()

wd = getwd()
input_dir = file.path(wd, "input")

nets_list = list.files(file.path(wd, "net"))
net_name = gsub(".PNPRO", "", nets_list[3])

solver_dir = paste0(input_dir, "/", net_name)

if( !dir.exists(solver_dir) ) {
  dir.create(solver_dir) 
}