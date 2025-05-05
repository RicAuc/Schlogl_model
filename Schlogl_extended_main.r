
library(epimod)
# downloadContainers()
library(dplyr)
library(ggplot2)
library(patchwork)

wd = getwd()

nets_list = list.files(file.path(wd, "net"))

net_name = gsub(".PNPRO", "", nets_list[1])

input_dir = file.path(wd, "input")

solver_dir = paste0(input_dir, "/", net_name)
if( !dir.exists(solver_dir) ) {
  dir.create(solver_dir) 
}

model.generation(net_fname = file.path(wd, "net", paste0(net_name, ".PNPRO")))

files_to_move <- list.files(pattern = net_name, full.names = F)

if (length(files_to_move) > 0) {
  sapply(files_to_move, function(f) {
    file.rename(from = f, to = file.path(solver_dir, basename(f)))
  })
} else {
  cat("No .rds files found for", fba_name, "\n")
}

model.analysis(solver_fname = file.path(solver_dir, paste0(net_name, ".solver")),
               f_time = 100,
               s_time = 1
)

source(file.path("functions", "ModelAnalysisPlot.R"))

AnalysisPlot = ModelAnalysisPlot(traces_path = file.path(wd, paste0(net_name, "_", "analysis")))

p = AnalysisPlot$list.plX1$plX1.1 + 
  AnalysisPlot$list.plAll$plAll.1

ggsave(file.path(wd, "plots", paste0(net_name, "_dynamics.pdf")), p, height = 3.5, width = 9)
