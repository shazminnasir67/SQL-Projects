
library(dplyr)
library(ggplot2)
library(lubridate)
library(DBI)
library(RPostgres)
library(lubridate)
library(viridis)

# Connect to PostgreSQL
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "postgres",
  host = "localhost",
  port = 5432,  
  user = "postgres",
  password = "like1212"
)
query <- "
SELECT userId, productId, rating, TO_TIMESTAMP(timestamp) AS rating_date
FROM amazon_product_reviews
"

# Fetch the data into an R dataframe
ratings_data <- dbGetQuery(con, query)

# Close the connection once data is fetched
dbDisconnect(con)

# Inspect the first few rows of the dataset
head(ratings_data)

# Summary of the dataset
summary(ratings_data)

# Check the structure of the dataset
str(ratings_data)

# Plot the distribution of ratings
ggplot(ratings_data, aes(x = rating)) +
  geom_histogram(binwidth = 0.5, fill = "blue", color = "black") +
  labs(title = "Distribution of Ratings",
       x = "Rating",
       y = "Frequency") +
  theme_minimal()

# Sample 10,000 rows from the dataset
sampled_data <- ratings_data %>%
  sample_n(10000)

# Plot ratings over time
ggplot(sampled_data, aes(x = rating_date, y = rating)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "loess", color = "red") +
  labs(title = "Ratings Over Time",
       x = "Date",
       y = "Rating") +
  theme_minimal()

# Create a new column for the month
ratings_data <- ratings_data %>%
  mutate(rating_month = floor_date(rating_date, "month"))

# Calculate average rating per month
monthly_avg_ratings <- ratings_data %>%
  group_by(rating_month) %>%
  summarise(avg_rating = mean(rating))

# Plot the average rating per month
ggplot(monthly_avg_ratings, aes(x = rating_month, y = avg_rating)) +
  geom_line(color = "blue", size = 1) +
  labs(title = "Average Rating Per Month",
       x = "Month",
       y = "Average Rating") +
  theme_minimal()

# Count ratings per month
heatmap_data <- ratings_data %>%
  group_by(rating_month, rating) %>%
  summarise(count = n()) %>%
  ungroup()

# Plot the heatmap
ggplot(heatmap_data, aes(x = rating_month, y = factor(rating))) +
  geom_tile(aes(fill = count), color = "white") +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "Heatmap of Ratings Distribution Over Time",
       x = "Year-Month",
       y = "Rating",
       fill = "Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Identify top products by average rating
top_products <- ratings_data %>%
  group_by(productid) %>%
  summarise(avg_rating = mean(rating), count = n()) %>%
  arrange(desc(avg_rating)) %>%
  slice(1:5)  

# Filter data for top products
top_products_data <- ratings_data %>%
  filter(productid %in% top_products$productid)


# Plot bar chart for average ratings of top products
ggplot(top_products, aes(x = reorder(productid, avg_rating), y = avg_rating, fill = avg_rating)) +
  geom_bar(stat = "identity") +
  coord_flip() +  # Flip coordinates to make the bar chart horizontal
  scale_fill_viridis_c() +
  labs(title = "Top 5 Products by Average Rating",
       x = "Product ID",
       y = "Average Rating") +
  theme_minimal()

# Plot rating trends for top products
ggplot(top_products_data, aes(x = rating_date, y = rating, color = factor(productid))) +
  geom_line(alpha = 0.8) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Rating Trends for Top Products",
       x = "Date",
       y = "Rating",
       color = "Product ID") +
  theme_minimal()


ratings_data <- ratings_data %>%
  mutate(rating_date = as.Date(rating_date, origin = "1970-01-01"))  # Adjust the origin if your timestamps are different


# Plot boxplot of ratings by month
ggplot(ratings_data, aes(x = factor(month(rating_date)), y = rating)) +
  geom_boxplot(fill = "skyblue", color = "black") +
  labs(title = "Boxplot of Ratings by Month",
       x = "Month",
       y = "Rating") +
  theme_minimal()

# Plot density of ratings
ggplot(ratings_data, aes(x = rating)) +
  geom_density(fill = "skyblue", alpha = 0.8, color = "black") +
  labs(title = "Density Plot of Ratings",
       x = "Rating",
       y = "Density") +
  theme_minimal()

# Calculate average rating vs. number of ratings per product
product_popularity <- ratings_data %>%
  group_by(productid) %>%
  summarise(avg_rating = mean(rating), rating_count = n())

# Plot average rating vs. number of ratings
ggplot(product_popularity, aes(x = rating_count, y = avg_rating)) +
  geom_point(alpha = 0.6, color = "blue") +
  geom_smooth(method = "loess", color = "red") +
  labs(title = "Average Rating vs. Number of Ratings",
       x = "Number of Ratings",
       y = "Average Rating") +
  theme_minimal()


# Aggregate data by week and calculate average rating
weekly_avg_ratings <- ratings_data %>%
  mutate(week = floor_date(rating_date, "week")) %>%
  group_by(week) %>%
  summarise(avg_rating = mean(rating))

# Plot the time series of average weekly ratings
ggplot(weekly_avg_ratings, aes(x = week, y = avg_rating)) +
  geom_line(color = "blue", size = 1) +
  geom_point(color = "red", size = 0.5) +
  labs(title = "Time Series of Average Weekly Ratings",
       x = "Week",
       y = "Average Rating") +
  theme_minimal()

