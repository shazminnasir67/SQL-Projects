# Market-Basket-Analysis.R
# Author: Shazmin
# Date: 2024-08-14

# Load required packages
if (!requireNamespace("arulesViz", quietly = TRUE)) install.packages("arulesViz")
if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("reshape2", quietly = TRUE)) install.packages("reshape2")
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("arules", quietly = TRUE)) install.packages("arules")

library(plotly)
library(dplyr)
library(reshape2)
library(lubridate)
library(ggplot2)
library(arules)
library(arulesViz)

# Load data
data <- read.csv("D:/PROJECTS/SQLProject/Market-Basket-Analysis/data/OnlineRetail.csv")
data$InvoiceDate <- as.POSIXct(data$InvoiceDate, format="%m/%d/%Y %H:%M", tz = "UTC")
data$Date <- as.Date(data$InvoiceDate)
data$Hour <- hour(data$InvoiceDate)
data$DayOfWeek <- weekdays(data$Date)

# Visualizing Transaction Patterns

## Heatmaps and Time Series Plots

### Heatmap of Average Transaction Size by Day of Week and Hour

# Calculate average transaction size
data_summary <- data %>%
  filter(Quantity > 0) %>%
  group_by(DayOfWeek, Hour) %>%
  summarize(AverageTransactionSize = mean(Quantity), .groups = 'drop')

# Reshape data for heatmap
data_heatmap <- dcast(data_summary, Hour ~ DayOfWeek, value.var = "AverageTransactionSize", fill = 0)
data_heatmap_long <- melt(data_heatmap, id.vars = "Hour")

# Plot interactive heatmap using plotly
plot_ly(data_heatmap_long, x = ~variable, y = ~Hour, z = ~value, type = "heatmap",
        colors = c("lightblue", "darkblue"),
        colorbar = list(title = "Average Transaction Size")) %>%
  layout(title = "Heatmap of Average Transaction Size by Day of Week and Hour",
         xaxis = list(title = "Day of Week"),
         yaxis = list(title = "Hour of Day"),
         coloraxis = list(colorbar = list(title = "Average Transaction Size"))) %>%
  config(displayModeBar = TRUE)

### Heatmap of Revenue by Day of Week and Hour

# Aggregation to calculate revenue by day of week and hour
data_summary <- data %>%
  filter(Quantity > 0) %>%
  group_by(DayOfWeek, Hour) %>%
  summarize(Revenue = sum(UnitPrice * Quantity), .groups = 'drop')

# Reshape data for heatmap
data_heatmap <- dcast(data_summary, Hour ~ DayOfWeek, value.var = "Revenue", fill = 0)
data_heatmap_long <- melt(data_heatmap, id.vars = "Hour")

# Plot interactive heatmap using plotly
plot_ly(data_heatmap_long, x = ~variable, y = ~Hour, z = ~value, type = "heatmap",
        colors = c("white", "steelblue"),
        colorbar = list(title = "Revenue")) %>%
  layout(title = "Heatmap of Revenue by Day of Week and Hour",
         xaxis = list(title = "Day of Week"),
         yaxis = list(title = "Hour of Day"),
         coloraxis = list(colorbar = list(title = "Revenue"))) %>%
  config(displayModeBar = TRUE)

### Time Series Plot of Revenue Over Time

# Time series plot of total revenue over time
data_time_series <- data %>%
  group_by(Date = as.Date(InvoiceDate)) %>%
  summarize(Revenue = sum(UnitPrice * Quantity), .groups = 'drop')

ggplot(data_time_series, aes(x = Date, y = Revenue)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Revenue Over Time",
       x = "Date",
       y = "Revenue")

# Aggregating the Data

## Handling Missing Values and Negative Quantities

data <- data %>%
  na.omit() %>%
  filter(Quantity > 0)

# Inspect the cleaned data
head(data)
summary(data)

# Association Rule Mining Preparation

## Transform Transaction Data

# Filter and aggregate data
transaction_data <- data %>%
  filter(Quantity > 0) %>%
  group_by(InvoiceNo) %>%
  summarize(items = paste(StockCode, collapse = ",")) %>%
  ungroup()

# Create transactions object
split_items <- strsplit(transaction_data$items, ",")
basket_data <- as(split_items, "transactions")

# Generate and inspect association rules
rules <- apriori(basket_data, parameter = list(support = 0.01, confidence = 0.5))
inspect(rules)

## Generating and Evaluating Rules

# Generate frequent itemsets and association rules
frequent_itemsets <- apriori(basket_data, parameter = list(support = 0.01, target = "frequent itemsets"))
rules <- apriori(basket_data, parameter = list(support = 0.01, confidence = 0.5, target = "rules"))

# Inspect top rules
inspect(head(sort(rules, by = "support"), 10))
inspect(head(sort(rules, by = "confidence"), 10))
inspect(head(sort(rules, by = "lift"), 10))

## Plotting Rules

# Check the number of rules
cat("Number of rules generated:", length(rules), "\n")

# Plot the rules if there are any
if (length(rules) > 0) {
  # Save the plot to a PNG file with increased size
  png("rules_plot.png", width = 1200, height = 1200, res = 150)
  plot(rules, method = "matrix", control = list(reorder = "measure"))
  dev.off()
  
  # Alternatively, plot interactively
  plot_ly(data = as(rules, "data.frame"), x = ~support, y = ~confidence, color = ~lift, type = 'scatter', mode = 'markers')
  
} else {
  message("No rules to plot.")
}

# Comparative Analysis

## Product Performance Comparison

# Aggregate data for comparative analysis
product_performance <- data %>%
  group_by(StockCode) %>%
  summarize(Revenue = sum(UnitPrice * Quantity), .groups = 'drop')

# Comparative bar chart
ggplot(product_performance, aes(x = reorder(StockCode, -Revenue), y = Revenue, fill = StockCode)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Comparison of Product Performance",
       x = "Product",
       y = "Revenue") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Save the final rules to a CSV file
write(rules, file = "rules.csv", sep = ",")
