library(ggplot2)

# Plot weights -----------------------------------------------------------------
windowSize <- 15
weights <- 1 / (1 + abs(seq_len(windowSize) - (windowSize + 1) / 2))
days <- seq_len(windowSize) - ceiling(windowSize / 2)
vizData <- data.frame(day = days, weight = weights)
ggplot(vizData, aes(x = day, y = weight)) +
  geom_area(alpha = 0.7) +
  scale_x_continuous("Day", breaks = days) +
  scale_y_continuous("Weight")
ggsave(filename = file.path(folder, "weights.png"), width = 5, height = 5, dpi = 200)
