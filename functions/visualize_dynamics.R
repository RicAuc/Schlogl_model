library(ggplot2)
library(dplyr)
library(tidyr)
library(RColorBrewer)
library(patchwork)

plot_trace_dashboard_facet <- function(trace_file,
                                       title = "Dynamical Simulation",
                                       subtitle = NULL,
                                       ylab = "Value",
                                       xlab = "Time",
                                       line_size,
                                       text_size,
                                       palette = "Set1",
                                       just_X1,
                                       max_cols = 3) {
  
  trace <- read.table(trace_file, header = TRUE, sep = "", dec = ".")
  if (!"Time" %in% colnames(trace)) stop("First column must be 'Time'")
  
  trace_long <- trace %>%
    pivot_longer(cols = -Time, names_to = "Variable", values_to = "Value")
  
  variables <- unique(trace_long$Variable)
  n_vars <- length(variables)

  y_max <- max(trace_long$Value, na.rm = TRUE)

  # Setup color palette
  base_colors <- if (n_vars <= 8) {
    brewer.pal(n = max(3, n_vars), name = palette)
  } else {
    colorRampPalette(brewer.pal(8, palette))(n_vars)
  }
  
  if(just_X1) {
    variables = "X1"
    n_vars <- length(variables)
    y_max <- max(filter(trace_long, Variable == "X1")$Value, na.rm = TRUE)
  } 
  
  # Build individual plots
  plot_list <- lapply(seq_along(variables), function(i) {
    v <- variables[i]
    df <- filter(trace_long, Variable == v)
    ggplot(df, aes(x = Time, y = Value)) +
      geom_area(fill = base_colors[i], alpha = 0.1) +
      geom_line(color = base_colors[i], linewidth = line_size) +
      ylim(NA, y_max) + 
      labs(title = v, x = xlab, y = ylab) +
      theme_minimal(base_size = text_size) +
      theme(
        plot.title = element_text(face = "bold", size = text_size, hjust = 0.5),
        axis.title = element_text(color = "#444444"),
        axis.text = element_text(color = "#444444"),
        panel.grid.major = element_line(color = "gray85", linewidth = 0.3),
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "#f8f9fa", color = NA)
      )
  })

  # Determine layout
  n_cols <- min(n_vars, max_cols)

  # Combine with patchwork
  combined_plot <- wrap_plots(plot_list, ncol = n_cols) +
    plot_annotation(
      title = title,
      subtitle = subtitle,
      theme = theme(
        plot.title = element_text(face = "bold", size = text_size, hjust = 0),
        plot.subtitle = element_text(size = text_size, hjust = 0, color = "gray40")
      )
    )

  return(combined_plot)
}

