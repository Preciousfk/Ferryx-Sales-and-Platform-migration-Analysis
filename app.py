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


Ferryx_metrics = duckdb.sql("""
SELECT count(customer_identifier) as total_customers, 
count(distinct(Customer_identifier)) as Unique_customers, 
count(Order_Number) as Total_Orders,
Round(SUM(Item_Cost) - SUM(Order_Refund_Amount),2) AS Net_Product_Sales,
ROUND(SUM(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount), 2) AS Net_Commercial_Revenue
from read_csv_auto('Ferryx_Sales_Data.csv')
;

""").df()

st.subheader("📊 Detailed Metric Breakdown")

# Extract row values
row = Ferryx_metrics.iloc[0]

st.subheader("📌 Overall Ferryx Performance")

# Create 5 columns
c1, c2, c3, c4, c5 = st.columns(5)

with c1:
    with st.container(border=True):
        st.metric("Total Customers", f"{row['Total_Customers']:,}")
with c2:
    with st.container(border=True):
        st.metric("Unique Customers", f"{row['Unique_Customers']:,}")
with c3:
    with st.container(border=True):
        st.metric("Total Orders", f"{row['Total_Orders']:,}")
with c4:
    with st.container(border=True):
        st.metric("Net Product Sales", f"£{row['Net_Product_Sales']:,.2f}")
with c5:
    with st.container(border=True):
        st.metric("Net Commercial Rev.", f"£{row['Net_Commercial_Revenue']:,.2f}")

# # Format numeric values nicely
# formatted_df = Ferryx_metrics.copy()
# formatted_df["Net_Commercial_Revenue"] = formatted_df["Net_Commercial_Revenue"].apply(lambda x: f"£{x:,.2f}")
# formatted_df["Net_Product_Sales"] = formatted_df["Net_Product_Sales"].apply(lambda x: f"£{x:,.2f}")
# formatted_df["Total_Orders"] = formatted_df["Total_Orders"].apply(lambda x: f"{x:,}")
# formatted_df["Unique_Customers"] = formatted_df["Unique_Customers"].apply(lambda x: f"{x:,}")

# # Transpose table to list metrics as rows and websites as columns
# pivot_table = formatted_df.set_index("Website").T

# st.dataframe(pivot_table, use_container_width=True)