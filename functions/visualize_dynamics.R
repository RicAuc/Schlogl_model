plot_trace_dashboard <- function(trace_file,
                                 title = "Visitors Over Time",
                                 subtitle = "Trace data from simulation",
                                 ylab = "Value",
                                 xlab = "Value",
                                 line_color = "darkred",   # dark green
                                 fill_color = "red",   # light green
                                 line_size = 1.2,
                                 text_size = 14) {
  
  # Required libraries
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  
  # Load and reshape data
  trace <- read.table(trace_file, header = TRUE, sep = "", dec = ".")
  if (!"Time" %in% colnames(trace)) stop("First column must be 'Time'")
  
  trace_long <- trace %>%
    pivot_longer(cols = -Time, names_to = "Variable", values_to = "Value")
  
  # If multiple variables, use only the first for dashboard-style plot
  if (length(unique(trace_long$Variable)) > 1) {
    warning("Multiple variables detected. Only the first will be plotted.")
    trace_long <- trace_long %>% filter(Variable == unique(Variable)[1])
  }
  
  # Create the plot
  ggplot(trace_long, aes(x = Time, y = Value)) +
    geom_area(fill = fill_color, alpha = 0.075) +
    geom_line(color = line_color, size = line_size) +
    labs(
      title = title,
      subtitle = subtitle,
      x = xlab,
      y = ylab
    ) +
    theme_minimal(base_size = text_size) +
    theme(
      plot.title = element_text(face = "bold", size = text_size + 2, hjust = 0),
      plot.subtitle = element_text(color = "gray40", size = text_size - 2, hjust = 0),
      axis.title.y = element_text(face = "bold", color = "#444444"),
      axis.text = element_text(color = "#444444"),
      panel.grid.major = element_line(color = "gray85", size = 0.3),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "#f8f9fa", color = NA),
      legend.position = "none"
    )
}
