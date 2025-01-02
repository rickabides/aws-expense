AWS Service Expense Tracker

This Shiny app allows you to analyze AWS expenses by service, providing insights through historical trends, forecasting, and anomaly detection. The app dynamically loads AWS Cost Explorer CSV reports, enabling you to visualize and evaluate costs by individual services.

Features
	•	File Upload: Upload AWS Cost Explorer CSV files dynamically.
	•	Service-Specific Analysis: Select a service to analyze using a dropdown menu.
	•	Historical Trends: View past expenses as time-series data.
	•	Forecasting: Predict future expenses using ARIMA models.
	•	Anomaly Detection: Identify unusual patterns or spikes in service costs using Z-scores and rolling averages.

Requirements

Software Requirements
	•	R (>= 4.3.0)
	•	RStudio (optional but recommended)

R Package Dependencies

The following R packages are required and can be installed using:

install.packages(c("shiny", "tidyverse", "forecast", "lubridate", "conflicted", "zoo"))

File Format
	•	The app expects CSV files formatted exactly like AWS Cost Explorer exports.
	•	Example file: example_aws_data.csv (included).

File Structure:
	•	Column 1: Date in YYYY-MM-DD format.
	•	Remaining Columns: Costs by AWS service (e.g., EC2, S3).
	•	First row includes totals, which the app automatically excludes during processing.

How to Use the App

1. Clone the Repository

``git clone <repository_url>``
``cd aws-expense-tracker``

2. Launch the App

Open RStudio or the R terminal and run:

``shiny::runApp()``

3. Upload Data
	1.	Click the “Browse” button to upload your AWS Cost Explorer CSV report.
	2.	Select the service from the dropdown menu to analyze specific service costs.

4. Explore Tabs
	•	Historical Data: View past trends for the selected service.
	•	Forecast: Predict future expenses based on time-series data.
	•	Forecast Data: View predicted values in tabular format.
	•	Anomaly Detection: Highlight unusual spikes or dips in costs.

Example Dataset

A sample dataset, example_aws_data.csv, is included to demonstrate the application.
	•	Simply upload this file to explore the app’s features.

Limitations
	•	Data Requirements: The app expects AWS Cost Explorer CSV format; any deviations may cause errors.
	•	Short Time-Series Data: Forecasting and anomaly detection may be less accurate for datasets shorter than 12 months.
	•	No Warranty: This application is provided as-is with no warranty. Use at your own risk.

Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue to report bugs or suggest improvements.

License

This project is licensed under the MIT License.

Let me know if you’d like any further updates or clarifications!
