
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

model.generation(net_fname = file.path(wd, "net", paste0(net_name, ".PNPRO")))

files_to_move <- grep(list.files(pattern = paste0(net_name, "."), full.names = F), pattern='main', invert=TRUE, value=TRUE)

if (length(files_to_move) > 0) {
  sapply(files_to_move, function(f) {
    file.rename(from = f, to = file.path(solver_dir, basename(f)))
  })
} else {
  cat("No .rds files found for", fba_name, "\n")
}

model.analysis(solver_fname = "./input/Schlogl_reduced/Schlogl_reduced.solver",
               parameters_fname = "input/Schlogl_reduced/functions_analysis.csv",
               functions_fname = "./functions/Schlogl_reduced_Rfunctions.R",
               debug = T,
               f_time = 100,
               s_time = 1,
               i_time = 0)
