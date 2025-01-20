import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.model_selection import train_test_split

# Load your time series sales data
data = {
    "Date": pd.date_range(start="2023-01-01", periods=200, freq="D"),
    "Product": ["Product_A"] * 200,
    "Sales": np.concatenate([
        np.random.normal(100, 10, 180),  # Normal sales data
        np.random.uniform(200, 300, 20)  # Anomalous sales data
    ])
}
df = pd.DataFrame(data)

# Convert Date to datetime if not already
df['Date'] = pd.to_datetime(df['Date'])

# Feature extraction (use Date and Sales for this example)
df_features = df[['Sales']]

# Split the data into training and testing sets
X_train, X_test = train_test_split(df_features, test_size=0.2, random_state=42, shuffle=False)

# Initialize the Isolation Forest model
model = IsolationForest(n_estimators=100, contamination=0.1, random_state=42)

# Fit the model on the training data
model.fit(X_train)

# Predict anomalies on the test data (-1 indicates anomaly, 1 indicates normal)
X_test['Anomaly'] = model.predict(X_test)

# Add the anomaly labels back to the original test data
df_test = df.iloc[X_test.index]
df_test['Anomaly'] = X_test['Anomaly']

# Separate normal and anomalous data for visualization
anomalies = df_test[df_test['Anomaly'] == -1]
normal = df_test[df_test['Anomaly'] == 1]

# Print summary
print(f"Total test data points: {len(df_test)}")
print(f"Normal points: {len(normal)}")
print(f"Anomalies detected: {len(anomalies)}")

# Optionally save the results to a file
df_test.to_csv("timeseries_anomaly_detection_results.csv", index=False)

# Visualization
import matplotlib.pyplot as plt

plt.plot(df_test['Date'], df_test['Sales'], label='Sales', color='blue')
plt.scatter(anomalies['Date'], anomalies['Sales'], color='red', label='Anomalies', s=30)
plt.legend()
plt.title("Time Series Anomaly Detection with Isolation Forest")
plt.xlabel("Date")
plt.ylabel("Sales")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
