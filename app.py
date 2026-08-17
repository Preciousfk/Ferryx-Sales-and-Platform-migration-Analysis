import streamlit as st
import duckdb
import plotly.express as px

#load data
@st.cache_data
def load_raw_data():
    return duckdb.sql("SELECT * FROM 'Ferryx_Sales_Data.csv'").df()

# Assign to your master variable
raw_data = load_raw_data()

# Page Setup
st.set_page_config(page_title="Ferryx Sales Migration Dashboard", layout="wide")

st.title("📊 Ferryx Sales & Platform Migration Dashboard")
st.markdown("Comparing **WooCommerce** vs. **Squarespace** performance.")

# 1. Fetch data from raw_data (or read_csv_auto)
platform_metrics = duckdb.sql("""
    SELECT 
        Website,
        COUNT(Customer_Identifier) AS Total_Customers, 
        COUNT(DISTINCT Customer_Identifier) AS Unique_Customers, 
        COUNT(Order_Number) AS Total_Orders,
        ROUND(SUM(Item_Cost) - SUM(Order_Refund_Amount), 2) AS Net_Product_Sales,
        ROUND(SUM(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount), 2) AS Net_Commercial_Revenue
    FROM raw_data
    GROUP BY Website
""").df()

st.subheader("📊 Detailed Metric Breakdown")

# Format numeric values nicely
formatted_df = platform_metrics.copy()
formatted_df["Net_Commercial_Revenue"] = formatted_df["Net_Commercial_Revenue"].apply(lambda x: f"£{x:,.2f}")
formatted_df["Net_Product_Sales"] = formatted_df["Net_Product_Sales"].apply(lambda x: f"£{x:,.2f}")
formatted_df["Total_Orders"] = formatted_df["Total_Orders"].apply(lambda x: f"{x:,}")
formatted_df["Unique_Customers"] = formatted_df["Unique_Customers"].apply(lambda x: f"{x:,}")

# Transpose table to list metrics as rows and websites as columns
pivot_table = formatted_df.set_index("Website").T

st.dataframe(pivot_table, use_container_width=True)