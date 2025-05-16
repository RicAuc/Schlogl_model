
library(yaml)
library(epimod)
# downloadContainers()

wd  <- getwd()
input_dir <- file.path(wd, "input")
plot_dir  <- file.path(wd, "plots")

source(file.path(wd, "functions/visualize_dynamics.R"))

# load config
cfg <- yaml::read_yaml("config.yml")

# s = cfg$settings[[4]]
for (s in cfg$settings) {
  cat(">>> Processing:", s$name, "...\n")
  
  gen_args <- list(net_fname = file.path(wd, s$pnpro))
  if (!is.null(s$customCPP)) gen_args$transitions_fname <- s$customCPP
  do.call(model.generation, gen_args)
  
  ## 3) move generated artifacts  
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

  do.call(model.analysis, ana_args)
  
  trace <- file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace"))
  p <- plot_trace_dashboard_facet(
    trace_file = trace,
    title      = paste("Dynamics of", s$name),
    subtitle   = paste0("From '", s$name, "'"),
    ylab       = "Marking",
    xlab       = "Time",
    just_X1    = T,
    text_size  = 8.5,
    line_size = 0.75,
    palette    = "Dark2",
    max_cols   = 3
  )

  ggsave(file.path(plot_dir, paste0(s$name, "_dynamics.pdf")), p,
         height = 2.5, width = 2.5)
  
  additional_files <- c("ExitStatusFile", list.files(pattern="\\.log$"),
                        list.files(pattern="_analysis"),
                        "DockerID", ".Rhistory", "generation")
  unlink(additional_files[file.exists(additional_files)], recursive=TRUE, force=TRUE)
  
}
