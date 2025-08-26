This project focuses on analyzing sales data using SQL. The dataset is stored in a PostgreSQL database with three main tables.
The goal is to demonstrate SQL querying skills and provide actionable insights for sales strategy.

## Database Schema

The project uses 3 main tables:

dim_customers – Customer details (e.g., ID, name, location).

dim_products – Product catalog (e.g., ID, product name, category, price).

fact_sales – Transactional sales records (e.g., sales ID, customer ID, product ID, quantity, date).

## Setup Instructions

1. Install PostgreSQL

Download & install PostgreSQL

Create a new database (e.g., salesdb).

2. Load Data

Run create_tables.sql to create the tables.

Import the CSV files (dim_customers.csv, dim_products.csv, fact_sales.csv) into the respective tables

3. Run Analysis Queries

Open sales_queries.sql and execute queries to analyze sales.

## Goals of the Project

Understand customer purchasing behavior.

Identify high-performing products.

Track sales trends over time.

Provide a foundation for business reporting.
