
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

model.analysis(solver_fname = file.path(wd, "input", net_name, paste0(net_name, ".solver")),
               debug = T,
               f_time = 15,
               s_time = 1,
               i_time = 0)

# Files to check and remove
files_to_check <- c("ExitStatusFile", list.files(pattern = "\\.log$"), list.files(pattern = "DockerID"))
# Filter to only existing files
files_to_remove <- files_to_check[file.exists(files_to_check)]

# Remove the files if they exist
if (length(files_to_remove) > 0) {
  file.remove(files_to_remove)
  cat("Removed", length(files_to_remove), "files:", paste(files_to_remove, collapse=", "), "\n")
} else {
  cat("No matching files found in working directory.\n")
}

source(file.path("functions/visualize_dynamics.R"))

# Basic visualization - automatically detects all variables
p = plot_trace_dashboard(trace_file = file.path(wd, paste0(net_name, "_analysis", "/", net_name, "-analysis-1.trace")),
                     title = "Schlögl Model Dynamics",
                     subtitle = "Trace data",
                     ylab = "Value",
                     xlab = "Time",
                     line_color = "darkred",
                     fill_color = "red",   # light green
                     line_size = 1.2,
                     text_size = 14)

ggsave(file.path("plots/",paste0( net_name, "dynamics.pdf")), height = 3, width = 4)
