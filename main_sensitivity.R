
library(yaml)
# install_github("https://github.com/qBioTurin/epimod", ref="epimod_pFBA")
library(epimod)
library(parallel)
# downloadContainers()

wd  <- getwd()
input_dir <- file.path(wd, "input")
plot_dir  <- file.path(wd, "plots")

source(file.path(wd, "functions/visualize_dynamics.R"))

# load config
cfg <- yaml::read_yaml("config.yml")

s = cfg$settings[[8]]

cat(">>> Processing:", s$name, "...\n")

gen_args <- list(net_fname = file.path(wd, s$pnpro))
if (!is.null(s$customCPP)) gen_args$transitions_fname <- s$customCPP
do.call(model.generation, gen_args)

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
  f_time         = 50,
  s_time         = 1,
  i_time         = 0
)
if (!is.null(s$parameters)) ana_args$parameters_fname <- s$parameters
if (!is.null(s$functions))  ana_args$functions_fname  <- s$functions
if (!is.null(s$user_files)) ana_args$user_files       <- s$user_files

file.copy(from = s$user_files,
          to = file.path(input_dir, s$name, basename(s$user_files)),
          overwrite = TRUE)

if (s$sensitivity) {
  
  ana_args$parallel_processors = detectCores()
  ana_args$n_config = ana_args$parallel_processors*1
  ana_args$reference_data = "input/upper_stable_state.csv"
  ana_args$distance_measure = "msqd"
  ana_args$target_value = "target"
    
  do.call(model.sensitivity, ana_args)
  
  plot_sensitivity()
  
} else {
  do.call(model.analysis, ana_args)
}
