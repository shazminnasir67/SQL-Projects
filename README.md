# Customer Segmentation Analysis

## Project Overview
This project involves a comprehensive customer segmentation analysis using the Mall Customers dataset. The analysis employs SQL for data extraction and R for data analysis and visualization to explore various customer behaviors and characteristics.

## Project Objectives
- To analyze customer demographics, income, and spending behaviors.
- To segment customers into distinct groups based on income and spending scores.
- To provide actionable insights for marketing and business strategy.

## Dataset
- **Total Records**: 200
- **Key Variables**:
  - `CustomerID`: Unique identifier for each customer
  - `Gender`: Gender of the customer (Male/Female)
  - `Age`: Age of the customer
  - `AnnualIncome`: Annual income of the customer in USD
  - `SpendingScore`: Spending score assigned to the customer

### **2. Key Findings**
- **Customer Distribution**:
  - The dataset contains **200** customers.
  - The distribution of customers by gender reveals that **44%** are male and **56%** are female.

- **Age Analysis**:
  - The average age of customers is **38.85 years**, with a median age of **36 years** and a standard deviation of **13.93 years**.
  - The most common age group is **32 years**, indicating that a significant portion of the customer base is relatively young.

- **Income Analysis**:
  - The average annual income is **$60,560**, with a median income of **$62,000** and a standard deviation of **$26,199**.
  - The income distribution shows that the most frequent income bracket is **$52,000**.

- **Spending Score Analysis**:
  - The average spending score is **50.20**, with a median spending score of **50.00** and a standard deviation of **25.76**.
  - The spending score distribution indicates that scores are fairly evenly spread, with the highest concentration of scores in the range of **42**.

- **Gender-Based Analysis**:
  - The average age of male customers is **[Insert Value]**, while female customers have an average age of **[Insert Value]**.
  - Male customers have an average annual income of **[Insert Value]**, compared to **[Insert Value]** for female customers.
  - Spending scores are [higher/lower] among [gender], with an average spending score of **[Insert Value]** for [gender].

- **Income vs. Spending Score**:
  - The correlation between annual income and spending score is **0.0099**, indicating no significant relationship.
  - Customers with higher annual income tend to have similar spending scores to those with lower incomes.

- **Age vs. Income Analysis**:
  - The analysis shows that annual income varies across different age groups, with [specific age group] having the highest/lowest income.
  - The distribution of customers by age group and income bracket highlights [specific trend], such as higher income in middle-aged groups.

- **Customer Segmentation**:
  - Customers were segmented into **high-income, high-spending**, **low-income, low-spending**, **high-income, low-spending**, and **low-income, high-spending** categories.
  - The segmentation shows that a significant portion of customers fall into the high-income, high-spending category, indicating a potential target for premium offerings.

- **Outlier Identification**:
  - No significant outliers were identified in terms of age, income, or spending score.

### **3. Implications**
- The insights gained from this analysis can help in tailoring marketing strategies and improving customer engagement.
- Understanding the distribution of spending scores and income levels can assist in targeting high-value customers and designing promotions that align with their preferences.

### **4. Recommendations**
- Consider further analysis on specific customer segments to refine marketing strategies.
- Explore additional data points or external factors that may influence customer behavior and spending patterns.

### **5. Future Work**
- Incorporate additional variables or external datasets to enhance the segmentation and analysis.
- Implement machine learning techniques for more advanced customer segmentation and predictive modeling.

## Files Included
- `customer_segmentation_analysis.R`: R script for analysis and visualization
- `customer_data.csv`: Dataset used for analysis
- `README.md`: This README file

## Installation and Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/customer-segmentation-analysis.git
   ```
2. Navigate to the project directory:
   ```bash
   cd customer-segmentation-analysis
   ```
3. Open the `customer_segmentation_analysis.R` script in RStudio or your preferred R environment.
4. Load the dataset and run the analysis.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments
- [Mall Customers dataset](https://www.kaggle.com/vijaydhameliya/mall-customers) for providing the data.

