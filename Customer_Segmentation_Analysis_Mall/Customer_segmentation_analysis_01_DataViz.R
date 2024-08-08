install.packages("RMySQL")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("cluster")
install.packages("factoextra")
install.packages("readr")

library(dplyr)
library(RMySQL)
library(ggplot2)
library(factoextra)
library(cluster)
library(readr)

setwd("C:/ProgramData/MySQL/MySQL Server 8.0/Data/mall_customers")
customer<- read_csv("mall_customers.csv")

head(customer)

ggplot(customer , aes(x= Gender))+
  geom_bar(fill='skyblue')+
  labs(title = "Distribution of Customers by Gender", x = "Gender", y = "Count")

ggplot(customer, aes(x = Age)) +
  geom_histogram(binwidth = 2, fill = "orange") +
  labs(title = "Age Distribution of Customers", x = "Age", y = "Count")
customer <- customer %>%
  rename(SpendingScore = `Spending Score (1-100)`,
         AnnualIncome = `Annual Income (k$)`)


customer$SpendingScore <- as.numeric(customer$SpendingScore)
customer$AnnualIncome <- as.numeric(customer$AnnualIncome)

ggplot(customer, aes(x = SpendingScore)) +
  geom_histogram(binwidth = 4, fill = "purple", color = "black") +
  labs(title = "Spending Score Distribution", x = "Spending Score", y = "Count") +
  theme_minimal()

ggplot(customer, aes(x = AnnualIncome)) +
  geom_histogram(binwidth = 5, fill = "pink", color = "black") +
  labs(title = "Annual Income Distribution", x = "Annual Income (k$)", y = "Count") +
  theme_minimal()

ggplot(customer, aes(x = AnnualIncome, y = SpendingScore)) +
  geom_point(color = "blue") +
  labs(title = "Income vs Spending Score", x = "Annual Income (k$)", y = "Spending Score")

ggplot(customer, aes(x = Age, y = AnnualIncome)) +
  geom_point(color = "red") +
  labs(title = "Age vs Annual Income", x = "Age", y = "Annual Income (k$)")

ggplot(customer , aes(x= Age , y =SpendingScore ))+
  geom_point(color="red")+
  labs(title = "AGE vs SpendingScore" , x= "Age" , y = "Annual Income")

customer %>%
  mutate(Segment = case_when(
    AnnualIncome >= mean(AnnualIncome) & SpendingScore >= mean(SpendingScore) ~ "High Income, High Spending",
    AnnualIncome >= mean(AnnualIncome) & SpendingScore < mean(SpendingScore) ~ "High Income, Low Spending",
    AnnualIncome < mean(AnnualIncome) & SpendingScore >= mean(SpendingScore) ~ "Low Income, High Spending",
    TRUE ~ "Low Income, Low Spending"
  )) %>%
  ggplot(aes(x = Segment, fill = Segment)) +
  geom_bar() +
  labs(title = "Customer Segmentation", x = "Segment", y = "Count")+
  theme(axis.text.x = element_blank())
