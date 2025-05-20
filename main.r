
library(yaml)
library(epimod)
# downloadContainers()
library(parallel)

wd  <- getwd()
input_dir <- file.path(wd, "input")
plot_dir  <- file.path(wd, "plots")

source(file.path(wd, "functions/visualize_dynamics.R"))

cfg <- yaml::read_yaml("config.yml")

save_ref = FALSE

# s = cfg$settings[[12]]
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
    # debug          = TRUE,
    debug          = FALSE,
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
    ana_args$reference_data = "input/upper_stable_state.csv"
    ana_args$distance_measure = "msqd"
    ana_args$target_value = "target"
    
    do.call(model.sensitivity, ana_args)
    
  } else {
    
    if ( s$calibration ) {
      ana_args$parallel_processors = detectCores()
      ana_args$reference_data = "input/upper_stable_state.csv"
      ana_args$distance_measure = "msqd"
      ana_args$ini_v = c(0.06, 0.00015, 300, 5)
      ana_args$ub_v = c(0.08, 0.0002, 800, 8)
      ana_args$lb_v = c(0.02, 0.00001, 100, 2)
      ana_args$max.time = 1
      
      do.call(model.calibration, ana_args)
    } else {
      do.call(model.analysis, ana_args) 
    }
  }
  
  if(s$SSA) {
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
  
  if (s$sensitivity) {
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
    
    if(save_ref) {
      trace <- read.table(
        file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace")), 
        header = TRUE, sep = "", dec = ".")
      
      write.table(trace, file = file.path(wd, "input", "upper_stable_state.csv"), 
                  sep=",", col.names=FALSE, row.names = FALSE)
    }
    
    ggsave(file.path(plot_dir, paste0(s$name, "_dynamics.pdf")), p,
           height = 2.5, width = 2.5)
  } else {
    # plot_calibration()
  }
  
  additional_files <- c("ExitStatusFile", list.files(pattern="\\.log$"),
                        list.files(pattern="_analysis"),
                        "dockerID", ".Rhistory", "generation")
  unlink(additional_files[file.exists(additional_files)], recursive=TRUE, force=TRUE)
  
}
