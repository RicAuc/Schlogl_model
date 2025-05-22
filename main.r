
library(yaml)
library(epimod)
library(devtools)
# install_github("https://github.com/qBioTurin/epimod", ref="epimod_pFBA")
# install_github("https://github.com/qBioTurin/epimod", ref="master")
# downloadContainers()
library(parallel)

wd  <- getwd()
input_dir <- file.path(wd, "input")
plot_dir  <- file.path(wd, "plots")

source(file.path(wd, "functions/visualize_dynamics.R"))

f_time = 50
s_time = 0.1
i_time = 0
nodes = 2

cfg <- yaml::read_yaml("config.yml")

reference_trace = file.path(input_dir, "upper_stable_state.csv")
save_ref = 1
ref_col_names = c("Time", "X1")

if ( file.exists(reference_trace) ) {
  ref_trace = read.table(reference_trace, header = FALSE, sep = " ")
  colnames(ref_trace) = ref_col_names
  plot_ref()
  save_ref = FALSE
  
} else {
  cat("Reference trace file not found.", "\n")
  cat("generate reference data ... ", "\n")
  
  s = cfg$settings[[save_ref]]
  
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
  
  do.call(model.analysis, ana_args)
  
  trace <- read.table(
    file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace")), 
    header = TRUE, sep = "", dec = ".")
  
  write.table(trace, file = reference_trace,
              sep = " ", col.names=FALSE, row.names = FALSE)
  
  save_ref = TRUE
}

# s = cfg$settings[[13]]
for (s in cfg$settings) {
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
  
  if( s$SSA ) {
    ana_args$solver_type = "SSA"
    ana_args$parallel_processors = detectCores()
    ana_args$n_run = ana_args$parallel_processors*nodes
  }
  
  if ( s$sensitivity ) {
    
    ana_args$parallel_processors = detectCores()
    ana_args$n_config = ana_args$parallel_processors*nodes
    ana_args$reference_data = reference_trace
    ana_args$distance_measure = "msqd"
    ana_args$target_value = "target"
    
    do.call(model.sensitivity, ana_args)
    
  } else {
    
    if ( s$calibration ) {
      
      ini_v = read.table(file.path(wd, paste0("input/KineticsParameters", "_", s$name)), header = F)
      # Relative variation ±20%
      variation <- 0.25
      ini_v = ini_v$V1
      
      # ana_args$s_time = 0.1
      ana_args$parallel_processors = detectCores()
      ana_args$reference_data = reference_trace
      ana_args$distance_measure = "msqd"
      ana_args$ini_v = ini_v
      ana_args$ub_v <- ini_v * (1 + variation)
      ana_args$lb_v <- ini_v * (1 - variation)
      ana_args$max.time = 10
      
      do.call(model.calibration, ana_args)
    } else {
      do.call(model.analysis, ana_args)
    }
  }
  
  if( s$SSA ) {
    p = plot_stochastics(f_time, s_time, i_time,
                         title = paste("Dynamics of", s$name, "solver: SSA"), 
                         subtitle = paste0("From '", s$name, "'", " - n_run: ", ana_args$n_run),
                         axis_title_size = 8, 
                         axis_text_size = 8,
                         title_size = 9, 
                         subtitle_size = 9)
    
    ggsave(file.path(plot_dir, paste0(s$name, "_dynamics", "_SSA_",".pdf")), p,
           height = 3, width = 4)
  } 
  
  if ( s$sensitivity ) {
    list_sens_results <- plot_sensitivity(
      title            = "Sensitivity Analysis",
      subtitle         = "Sensitivity Analysis Subtitle",
      axis_title_size  = 8, 
      axis_text_size   = 8,
      title_size       = 9, 
      subtitle_size    = 9
    )
  }
  
  if( !s$SSA && !s$calibration ) {
    
    p <- plot_trace_dashboard_facet(
      trace_file = file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace")),
      title      = paste("Dynamics of", s$name),
      subtitle   = paste0("From '", s$name, "'"),
      ylab       = "Marking",
      xlab       = "Time",
      just_X1    = TRUE,
      text_size  = 8.5,
      line_size  = 0.75,
      palette    = "Dark2",
      max_cols   = 3)
    
    ggsave(file.path(plot_dir, paste0(s$name, "_dynamics.pdf")), p,
           height = 2.5, width = 2.5)
    
  } else {
    calibration_plotting(
      results_dir       = file.path(wd, paste0(s$name, "_calibration")),
      reference_file    = reference_trace,
      model_name        = s$name,
      variable_ref      = "X1",
      ref_col_names     = c("Time", "X1"),
      optim_trace       = file.path(wd, paste0(s$name, "_calibration"), paste0(s$name, "-calibration_optim-config.csv")),
      output_plot       = file.path(wd, "plots", paste0(s$name, "-calibration_plot.pdf")),
      width             = 4,
      height            = 2.5,
      title_text        = "Calibration Output vs Reference",
      subtitle_text     = NULL,
      title_size        = 12,
      subtitle_size     = 10,
      axis_title_size   = 10,
      axis_text_size    = 10,
      legend_title_size = 9,
      legend_text_size  = 9
    )
}
  
  additional_files <- c("ExitStatusFile", list.files(pattern="\\.log$"),
                        list.files(pattern="_analysis"),
                        "dockerID", ".Rhistory", "generation")
  unlink(additional_files[file.exists(additional_files)], recursive=TRUE, force=TRUE)
  
}
