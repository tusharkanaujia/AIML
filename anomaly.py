import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import matplotlib.pyplot as plt

# Load the dataset (replace with your CSV file path)
data = pd.read_csv('sales_data.csv')

# Feature Engineering - Extract relevant columns (e.g., Units_Sold, Total_Sales)
features = data[['Units_Sold', 'Total_Sales']]

# Initialize the Isolation Forest model
model = IsolationForest(contamination=0.1, random_state=42)

# Fit the model on the features
data['Anomaly'] = model.fit_predict(features)

# Convert the anomaly column to human-readable labels
data['Anomaly'] = data['Anomaly'].map({1: 'Normal', -1: 'Anomaly'})

# Print anomalies in a human-readable format
anomalies = data[data['Anomaly'] == 'Anomaly']
if anomalies.empty:
    print("No anomalies detected.")
else:
    print("Anomalies detected in the following records:")
    for idx, row in anomalies.iterrows():
        print(f"Date: {row['Date']}, Product: {row['Product_Name']}, Units Sold: {row['Units_Sold']}, Total Sales: ${row['Total_Sales']:.2f}")
    
# Visualizing the anomalies
plt.figure(figsize=(10, 6))
plt.scatter(data['Date'], data['Total_Sales'], color=data['Anomaly'].map({'Normal': 'blue', 'Anomaly': 'red'}), label='Sales')

# Highlight anomalies
anomalies = data[data['Anomaly'] == 'Anomaly']
plt.scatter(anomalies['Date'], anomalies['Total_Sales'], color='red', label='Anomalies')

# Labeling and displaying the plot
plt.xlabel('Date')
plt.ylabel('Total Sales')
plt.title('Sales Anomaly Detection')
plt.xticks(rotation=45)
plt.legend()
plt.tight_layout()
plt.show()
