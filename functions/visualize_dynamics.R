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

plot_sensitivity = function() {
  
  load(file.path(wd, paste0(s$name, "_", "analysis"), paste0(s$name, "-", "analysis.RData")))
  
  load("./results_sensitivity_analysis/ranking_Schlogl_general-sensitivity.RData")
  reference <- as.data.frame(read.csv("Input/reference_data.csv",
                                      header = FALSE,
                                      sep = ""))
  
  listFile = list.files(file.path(wd, paste0(s$name, "_", "analysis")), pattern = ".trace")
  
  configID = t(sapply(1:length(listFile),
                     function(x){
                       return(c(x,config[[1]][[x]][[3]]))
                     }))
  
  id.traces = as.numeric(gsub("[^[:digit:].]", "", listFile) )
  
  ListTraces = lapply(id.traces,
                     function(x){
                       trace.tmp=read.table(
                         paste0(file.path(wd, paste0(s$name, "_analysis"), 
                                          paste0(s$name, "-", "analysis", "-")), x, ".trace"), header = T)
                       trace.tmp = data.frame(trace.tmp,ID=rank[which(rank[,2]==x),1])
                       return(trace.tmp)
                     })
  
  rank2<-lapply(id.traces,
                function(x){
                  k1<-config[[5]][[x]][[3]]
                  k2<-config[[4]][[x]][[3]]
                  rnk.tmp=data.frame(ID=x,distance = rank$measure[which(rank[,2]==x)],k1_rate=k1, k2_rate=k2)
                  return(rnk.tmp)
                })
  
  rank2 <- do.call("rbind", rank2)
  traces <- do.call("rbind", ListTraces)
  
  plX1<-ggplot( )+
    geom_line(data=traces,
              aes(x=Time/7,y=X1,group=ID,col=ID))+
    geom_line(data=reference,
              aes(x=V1/7,y=V2),
              col="red")+
    theme(axis.text=element_text(size=18),
          axis.title=element_text(size=20,face="bold"),
          legend.text=element_text(size=18),
          legend.title=element_text(size=20,face="bold"),
          legend.position="right",
          legend.key.size = unit(1.3, "cm"),
          legend.key.width = unit(1.3,"cm") )+
    labs(x="Time", y="X1",col="Distance")
  
  ColMax<-max((rank2$distance-min(rank2$distance))/max(rank2$distance))
  
  pl<-ggplot(rank2,aes(x=k1_rate,y=k2_rate,col=(distance-min(distance))/max(distance)))+
    geom_point(size=3)+
    theme(axis.text=element_text(size=18),
          axis.title=element_text(size=20,face="bold"),
          legend.text=element_text(size=18),
          legend.title=element_text(size=20,face="bold")) +
    labs(title="",col="distance",x= "k1",y="k2")+
    scale_colour_gradientn(colours = c("black","deepskyblue2","cyan"),
                           values= c(0,.002,1),
                           breaks=c(0,ColMax),
                           labels=c("min","max"))
  
}

plot_stochastics = function(f_time, s_time, i_time) {
  # Load required libraries
  library(ggplot2)
  library(reshape2)
  
  # Read trace data
  trace <- file.path(wd, paste0(s$name, "_analysis/", s$name, "-analysis-1.trace"))
  ssa_profiles <- read.table(trace, header = TRUE) %>% select(c(Time, X1))
  
  chunks = split(ssa_profiles, ceiling(seq_len(nrow(ssa_profiles))/(f_time+1)))
  
  # Reshape data to long format for plotting
  ssa_long <- melt(chunks, id.vars = "Time", variable.name = "Trajectory", value.name = "Value")  
  
  mean_data = ssa_long %>%
    group_by(Time) %>%
    dplyr::summarize(Mean = mean(Value, na.rm=TRUE))
  
  # Create the plot
  p = ggplot() +
    geom_line(data = ssa_long, aes(x = Time, y = Value, group = L1), alpha = 0.3) +
    geom_line(data = mean_data, aes(x = Time, y = Mean), color = "red", linewidth = 0.75) +
    labs(title = "Stochastic Trajectories", x = "Time", y = "Value") +
    theme_minimal()
  
  return(p)
}
