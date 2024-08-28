# Load Required Libraries
library(dplyr)
library(ggplot2)
library(readr)
library(cluster)
library(mice)
library(GGally)
library(FactoMineR)
library(psych)
library(caret)
library(randomForest)
library(xgboost)
library(pROC)
library(PRROC)

# Load Data
customer <- read_csv("D:/PROJECTS/SQLProject/Churn-Prediction/Telco-Customer-Churn.csv")
customer_churn <- read_csv("D:/PROJECTS/SQLProject/Churn-Prediction/Telco-Customer-Churn.csv")

# Data Exploration and Preparation
# Basic Summary
summary(customer_churn)

# Advanced Statistical Summaries
customer_churn %>%
  group_by(Churn) %>%
  summarise(across(c(MonthlyCharges, tenure, TotalCharges), list(mean = mean, sd = sd, median = median)))

# Visualizations
ggplot(customer_churn, aes(x = Churn, y = MonthlyCharges)) + 
  geom_boxplot() + 
  ggtitle("Monthly Charges by Churn")

ggplot(customer_churn, aes(x = TotalCharges, fill = Churn)) + 
  geom_histogram(bins = 30, alpha = 0.7) + 
  ggtitle("Total Charges Distribution by Churn")

# Examine Customer Demographics
# Correlation Analysis
customer_churn$Churn <- as.factor(customer_churn$Churn)
customer_dummies <- model.matrix(~ Churn - 1, data = customer_churn)
customer_churn$TotalCharges[is.na(customer_churn$TotalCharges)] <- median(customer_churn$TotalCharges, na.rm = TRUE)
customer_combined <- cbind(customer_churn[, c("MonthlyCharges", "tenure", "TotalCharges")], customer_dummies)
correlation_matrix <- cor(customer_combined)
print(correlation_matrix)

# Regression Analysis
model <- glm(Churn ~ MonthlyCharges + tenure + TotalCharges, data = customer_churn, family = binomial)
summary(model)

# Service Usage Overview
# Visualize Differences
ggplot(customer_churn, aes(x = MonthlyCharges, color = Churn)) + 
  geom_density() + 
  ggtitle("Density Plot of Monthly Charges by Churn")

ggplot(customer_churn, aes(x = Churn, y = tenure)) + 
  geom_boxplot() + 
  ggtitle("Tenure by Churn Status")

# Data Cleaning and Feature Engineering
# Identify Missing Values
colSums(is.na(customer))

# Advanced Imputation
imputed_data <- mice(customer_churn, m = 5, method = 'pmm', seed = 123)
completed_data <- complete(imputed_data)

# Create Derived Features
customer_churn <- customer_churn %>%
  mutate(TotalCharges_per_MonthlyCharges = TotalCharges / MonthlyCharges)

# Exploratory Data Analysis (EDA)
# Analyze Churn by Customer Segments
# Clustering
set.seed(123)
clustering <- kmeans(customer_churn[, c("MonthlyCharges", "tenure", "TotalCharges")], centers = 3)
customer_churn$cluster <- clustering$cluster

ggplot(customer_churn, aes(x = MonthlyCharges, y = tenure, color = as.factor(cluster))) + 
  geom_point() + 
  ggtitle("Customer Segments")

# Advanced Visualizations
ggpairs(customer_churn, columns = c("MonthlyCharges", "tenure", "TotalCharges", "Churn"))

# Correlation Analysis
# Principal Component Analysis (PCA)
pca_result <- PCA(customer_churn %>% select(MonthlyCharges, tenure, TotalCharges), scale.unit = TRUE)
plot(pca_result, choix = "var")

# Factor Analysis
fa_result <- fa(customer_churn %>% select(MonthlyCharges, tenure, TotalCharges), nfactors = 2)
print(fa_result)

# Model Building
# Prepare Data for Modeling
train_index <- createDataPartition(customer_churn$Churn, p = 0.7, list = FALSE)
train_data <- customer_churn[train_index, ]
test_data <- customer_churn[-train_index, ]
train_data$Churn <- as.factor(train_data$Churn)
train_data <- na.omit(train_data)

# Feature Selection
control <- rfeControl(functions = rfFuncs, method = "cv", number = 10)
results <- rfe(train_data %>% select(-Churn), train_data$Churn, sizes = c(1:5), rfeControl = control)
print(results)

# Build Churn Prediction Model
# Logistic Regression
model_logistic <- glm(Churn ~ MonthlyCharges + tenure + TotalCharges, data = train_data, family = binomial)
summary(model_logistic)

# Random Forest
model_rf <- randomForest(Churn ~ MonthlyCharges + tenure + TotalCharges, data = train_data)
print(model_rf)

# Gradient Boosting
train_data <- train_data %>%
  mutate_if(is.character, as.factor) %>%
  mutate_if(is.factor, as.numeric)
dtrain <- xgb.DMatrix(data = as.matrix(train_data %>% select(-Churn)), label = as.numeric(train_data$Churn) - 1)
model_xgb <- xgboost(data = dtrain, nrounds = 10, objective = "binary:logistic")

# Evaluate Model Performance
# ROC-AUC
pred_probs_logistic <- predict(model_logistic, test_data, type = "response")
roc_result_logistic <- roc(test_data$Churn, pred_probs_logistic)
plot(roc_result_logistic)
auc(roc_result_logistic)

pred_probs_rf <- predict(model_rf, test_data, type = "prob")[, "Yes"]
roc_result_rf <- roc(test_data$Churn, pred_probs_rf)
plot(roc_result_rf, main = "ROC Curve for Random Forest")
auc(roc_result_rf)

test_data_numeric <- test_data %>%
  mutate_if(is.character, as.factor) %>% 
  mutate_if(is.factor, as.numeric)
dtest <- xgb.DMatrix(data = as.matrix(test_data_numeric %>% select(-Churn)))
pred_probs_xgb <- predict(model_xgb, dtest)
roc_result_xgb <- roc(test_data$Churn, pred_probs_xgb)
plot(roc_result_xgb, main = "ROC Curve for Gradient Boosting")
auc(roc_result_xgb)

# Precision-Recall Curves
churn_numeric <- as.numeric(test_data$Churn == "Yes")
scores_class0 <- as.numeric(pred_probs_logistic[churn_numeric == 1])
scores_class1 <- as.numeric(pred_probs_logistic[churn_numeric == 0])
prroc_result <- pr.curve(scores.class0 = scores_class0, scores.class1 = scores_class1, curve = TRUE)
plot(prroc_result)


