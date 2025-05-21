library(ggplot2)
library(dplyr)
library(tidyr)
library(RColorBrewer)
library(patchwork)

plot_ref <- function(refdata = ref_trace, outdir = file.path(wd, "plots")) {
  if (!all(c("Time", "X1") %in% colnames(refdata))) {
    stop("Expected columns 'Time' and 'X1' not found in the trace.")
  }
  
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  
  outfile <- file.path(outdir, "plot_ref.pdf")
  pdf(outfile, width = 6, height = 4)
  
  plot(
    refdata$Time, refdata$X1,
    type = "l", col = "#7d0000", lwd = 2,
    xlab = "Time", ylab = "X1",
    main = "Reference Trajectory: Upper Stable State"
  )
  grid()
  
  dev.off()
  message("Plot saved to: ", outfile)
}

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

plot_sensitivity <- function(title,
                             subtitle,
                             axis_title_size,
                             axis_text_size,
                             legend_text_size,
                             legend_title_size) {
  
  # -- load data (assumes wd and s$name in scope) --
  load(file.path(wd, paste0(s$name, "_analysis"), paste0(s$name, "-analysis.RData")))
  load("./results_sensitivity_analysis/ranking_Schlogl_general-sensitivity.RData")
  reference <- read.csv("input/upper_stable_state.csv",
                        header = FALSE, sep = "") %>%
    rename(TimeRef = V1, X1Ref = V2) %>%
    mutate(Time = TimeRef / 7)
  
  # collect traces
  listFile  <- list.files(file.path(wd, paste0(s$name, "_analysis")), pattern = "\\.trace$")
  id_traces <- as.numeric(gsub("[^0-9]", "", listFile))
  traces    <- lapply(id_traces, function(x) {
    df <- read.table(file.path(wd, paste0(s$name, "_analysis"),
                               paste0(s$name, "-analysis-", x, ".trace")),
                     header = TRUE)
    df$ID <- x
    df$Time <- df$Time / 7
    return(df)
  }) %>%
    bind_rows()
  
  # prepare ranking data
  rank2 <- lapply(id_traces, function(x) {
    k1 <- config[[5]][[x]][[3]]
    k2 <- config[[4]][[x]][[3]]
    data.frame(ID       = x,
               distance = rank$measure[rank[,2] == x],
               k1_rate  = k1,
               k2_rate  = k2)
  }) %>%
    bind_rows() %>%
    mutate(rel_dist = (distance - min(distance)) / (max(distance) - min(distance)))
  
  # ---- plot 1: trajectories vs reference ----
  plX1 <- ggplot() +
    geom_line(data = traces,
              aes(x = Time, y = X1, group = factor(ID)),
              color = "steelblue", alpha = 0.3) +
    geom_line(data = reference,
              aes(x = Time, y = X1Ref),
              color = "firebrick", size = 1) +
    labs(title    = title,
         subtitle = subtitle,
         x        = "Time (normalized)",
         y        = "X1 count") +
    theme_minimal() +
    theme(
      plot.title       = element_text(size = axis_title_size + 2, face = "bold"),
      plot.subtitle    = element_text(size = axis_title_size, margin = margin(b = 8)),
      axis.title       = element_text(size = axis_title_size),
      axis.text        = element_text(size = axis_text_size),
      legend.position  = "none",
      panel.grid.minor = element_blank()
    )
  
  # ---- plot 2: parameter scattercolored by relative distance ----
  plParams <- ggplot(rank2, aes(x = k1_rate, y = k2_rate, color = rel_dist)) +
    geom_point(size = 3) +
    scale_color_gradient2(low = "blue", mid = "cyan", high = "red", midpoint = 0.5,
                          name = "Rel. dist") +
    labs(x = expression(k[1]),
         y = expression(k[2]),
         color = "Relative\nerror") +
    theme_minimal() +
    theme(
      axis.title       = element_text(size = axis_title_size),
      axis.text        = element_text(size = axis_text_size),
      legend.title     = element_text(size = legend_title_size, face = "bold"),
      legend.text      = element_text(size = legend_text_size),
      panel.grid.minor = element_blank()
    )
  
  # return a list of plots
  list(trajectories = plX1, parameter_space = plParams)
}

plot_stochastics <- function(f_time, s_time, i_time,
                             title, subtitle,
                             axis_title_size, axis_text_size,
                             title_size, subtitle_size) {
  
  # Read trace data
  trace_file <- file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace"))
  ssa_profiles <- read.table(trace_file, header = TRUE) %>% 
    select(Time, X1 = X1)
  
  # Split into runs and re-bind with a Trajectory ID
  runs <- split(ssa_profiles, ceiling(seq_len(nrow(ssa_profiles)) / (f_time + 1)))
  ssa_long <- bind_rows(runs, .id = "Trajectory") %>%
    mutate(Trajectory = factor(Trajectory),
           Value      = X1) %>%
    select(Time, Trajectory, Value)
  
  # Compute mean trajectory
  mean_data <- ssa_long %>%
    group_by(Time) %>%
    summarize(Mean = mean(Value, na.rm = TRUE), .groups = "drop")
  
  # Build the plot
  p <- ggplot() +
    # plot all individual runs, grouping by Trajectory
    geom_line(
      data = ssa_long,
      aes(x = Time, y = Value, group = Trajectory),
      alpha = 0.25,
      color = "black"
    ) +
    geom_line(
      data = mean_data,
      aes(x = Time, y = Mean),
      inherit.aes = FALSE,
      color = "firebrick",
      linewidth  = 0.9
    )+
    labs(title    = title,
         subtitle = subtitle,
         x        = "Time",
         y        = "X1 count") +
    theme_minimal() +
    theme(
      plot.title       = element_text(size = title_size, face = "bold"),
      plot.subtitle    = element_text(size = subtitle_size, margin = margin(b = 8)),
      axis.title       = element_text(size = axis_title_size),
      axis.text        = element_text(size = axis_text_size),
      panel.grid.major = element_line(color = "grey80"),
      panel.grid.minor = element_blank()
    )
  
  return(p)
}

# calibration_plotting.R

calibration_plotting <- function(results_dir,
                                 reference_file,
                                 optim_trace,
                                 output_plot,
                                 width,
                                 height,
                                 base_font_size) {
  
  # —— 1. Load reference trajectory & optimization trace ——
  reference_df = read.table(reference_trace, header = FALSE, sep = ",")
  colnames(ref_trace) = c("Time", "X1")
  optim_params <- read.table(optim_trace, header = T)
  
  read_trace <- function(id) {
    trace_file <- file.path(
      results_dir,
      stringr::str_c("extended_calibration-calibration-", id, ".trace")
    )
    df <- read.table(trace_file, header = T )
    dist <- optim_params %>% filter(id == !!id) %>% pull(distance)
    df %>% mutate(Distance = dist)
  }
  
  all_traces <- optim_params$id %>% purrr::map_dfr(read_trace)
  
  p <- ggplot(all_traces, aes(x = Time, y = X1, group = Distance, color = Distance)) +
    geom_line(alpha = 0.4) +
    geom_line(data = reference_df, aes(x = Time, y = X1),
              color = "red", linewidth = 1.1) +
    scale_color_gradient(
      low      = "red",
      mid      = "white",
      high     = "blue",
      midpoint = median(all_traces$Distance),
      name     = "Calibration\nerror"
    ) +
    labs(
      title = "Calibration Trajectories vs. Reference",
      x     = "Time",
      y     = "X1"
    ) +
    theme_minimal(base_size = base_font_size) +
    theme(
      plot.title      = element_text(face = "bold", size = base_font_size + 2),
      axis.title      = element_text(face = "bold"),
      legend.position = "right",
      legend.title    = element_text(face = "bold"),
      legend.text     = element_text(size = base_font_size - 2),
      panel.grid.minor = element_blank()
    )
  
  # —— 5. Save plot ——
  ggsave(filename = output_plot, plot = p,
         width = width, height = height)
  
  invisible(p)
}
