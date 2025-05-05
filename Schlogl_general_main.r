
library(epimod)
# downloadContainers()

wd = getwd()
input_dir = file.path(wd, "input")

nets_list = list.files(file.path(wd, "net"))
net_name = gsub(".PNPRO", "", nets_list[2])

solver_dir = paste0(input_dir, "/", net_name)

if( !dir.exists(solver_dir) ) {
  dir.create(solver_dir) 
}

model.generation(net_fname = file.path(wd, "net", paste0(net_name, ".PNPRO")),
                 transitions_fname = file.path(wd, "functions", "Schlogl_general_functions.cpp"))

files_to_move <- list.files(pattern = net_name, full.names = F)

if (length(files_to_move) > 0) {
  sapply(files_to_move, function(f) {
    file.rename(from = f, to = file.path(solver_dir, basename(f)))
  })
} else {
  cat("No .rds files found for", fba_name, "\n")
}

model.analysis(solver_fname = file.path(solver_dir, paste0(net_name, ".solver")),
               parameters_fname = file.path(wd, "input", net_name, "initData.csv"),
               functions_fname = file.path(wd, "functions/Schlogl_general_Rfunctions.R"),
               debug = T,
               f_time = 100,
               s_time = 1,
               i_time = 0,
               user_files = file.path(wd, "input", net_name, "Kinetics_Parameters"))
