
library(yaml)
library(epimod)
# downloadContainers()
library(parallel)

wd  <- getwd()
input_dir <- file.path(wd, "input")
plot_dir  <- file.path(wd, "plots")

source(file.path(wd, "functions/visualize_dynamics.R"))

cfg <- yaml::read_yaml("config.yml")

save_ref = TRUE

s = cfg$settings[[3]]

for (s in cfg$settings) {
  cat(">>> Processing:", s$name, "...\n")
  
  gen_args <- list(net_fname = file.path(wd, s$pnpro))
  if (!is.null(s$customCPP)) gen_args$transitions_fname <- s$customCPP
  do.call(model.generation, gen_args)
  
  f_time = 50; s_time = 1; i_time = 0
  
  nodes = 2
  
  solver_dir <- file.path(wd, "input", s$name)
  if (!dir.exists(solver_dir)) dir.create(solver_dir, recursive=TRUE)
  files <- setdiff(
    list.files(pattern=paste0(s$name, "\\.")), 
    grep("main", list.files(), value=TRUE)
  )
  file.rename(files, file.path(solver_dir, files))
  ana_args <- list(
    solver_fname   = file.path(solver_dir, paste0(s$name, ".solver")),
    debug          = TRUE,
    # debug          = FALSE,
    f_time         = f_time,
    s_time         = s_time,
    i_time         = i_time
  )
  if (!is.null(s$parameters)) ana_args$parameters_fname <- s$parameters
  if (!is.null(s$functions))  ana_args$functions_fname  <- s$functions
  if (!is.null(s$user_files)) ana_args$user_files       <- s$user_files
  
  file.copy(from = s$user_files,
            to = file.path(input_dir, s$name, basename(s$user_files)),
            overwrite = TRUE)
            
  if (s$calibration) {
    ana_args$parallel_processors = detectCores()
    ana_args$n_config = ana_args$parallel_processors*nodes
    ana_args$reference_data = "input/upper_stable_state.csv"
    ana_args$distance_measure = "msqd"
    ana_args$ini_v = c(248, 0.06, 0.0005, 300, 5)
    ana_args$ub_v = c(250, 0.08, 0.0002, 800, 8),
    ana_args$lb_v = c(247, 0.02, 0.00001, 100, 2),
    ana_args$max.time = 1
    
    do.call(model.calibration, ana_args)
  }
    
  additional_files <- c("ExitStatusFile", list.files(pattern="\\.log$"),
                        list.files(pattern="_analysis"),
                        "dockerID", ".Rhistory", "generation")
  unlink(additional_files[file.exists(additional_files)], recursive=TRUE, force=TRUE)
  
}
