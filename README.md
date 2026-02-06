Power BI Dashboard : https://app.powerbi.com/reportEmbed?reportId=f6fb6132-301a-40be-b904-c152011e2640&autoAuth=true&ctid=cb2784f1-21fe-480e-b9ba-3346067b4f65

<h>Project: Loan Performance & Risk Analytics Pipeline</h>
Focus: Financial risk, exposure analysis, advanced SQL analytics

Project Goal 
Build a data analytics pipeline that transforms raw loan and guarantee data into risk and performance metrics using SQL, CTEs, and window functions.
End-to-end data engineering and analytics project transforming raw government loan approval data into a clean relational dataset and interactive Power BI dashboard.

Problem Statement
Government loan approval datasets are often published in inconsistent, non-typed, and analytics-unfriendly formats, making it difficult to analyze exposure risk, lender concentration, and approval trends.

This project builds a clean, query-optimized data model and analytics layer to answer:

How do approvals trend by year, state, and program?
Who are the top lenders by exposure?
How concentrated is approved loan risk?


Raw CSV (data.gov)
        ↓
MySQL (Staging → Cleaned Tables)
        ↓
SQL Transformations & Metrics
        ↓
Power BI Dashboard (Published Online)



Tech Stack

Database: MySQL
Data Modeling: SQL (DDL, DML, window logic equivalents)
Data Cleaning: STR_TO_DATE, REGEXP, NULL handling
Analytics: Aggregations, ranking, market share metrics
Visualization: Power BI (DAX, interactive dashboards)

Data Engineering Steps

1️⃣ Data Ingestion
Loaded raw government approval data into MySQL
Preserved original schema for traceability

2️⃣ Data Cleaning & Normalization
Converted string-based date fields to proper DATE types
Standardized "N/A", "TBD", and empty values → NULL
Normalized lender names using COALESCE(Primary Lender, Primary Applicant)
Converted NAICS/SIC codes from text → integer
Trimmed whitespace and renamed corrupted column headers

3️⃣ Schema Optimization
Enforced correct data types for:
Dates
Numeric exposure amounts
Industry codes
Enabled query-ready fact table design

4️⃣ Analytical SQL Layer
Built reusable queries to calculate:
Total approved and disbursed exposure
Outstanding and undisbursed exposure
Loan count and average loan size
Exposure metrics by:
Lender
State
Fiscal year
Program
Decision authority

5️⃣ Advanced Analytics
Market share (% of total exposure) by lender
Top-N lender ranking
Exposure concentration analysis
Time-series approval trends
