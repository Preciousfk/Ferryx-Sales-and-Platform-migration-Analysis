import streamlit as st
import duckdb
import plotly.express as px

# Page Setup
st.set_page_config(page_title="Ferryx Sales Migration Dashboard", layout="wide")

st.title("📊 Ferryx Sales & Platform Migration Dashboard")
st.markdown("Comparing **WooCommerce** vs. **Squarespace** performance.")

# Load Data using DuckDB
@st.cache_data
def load_data():
    df = duckdb.sql("""
        SELECT 
            Website,
            COUNT(DISTINCT Order_Number) AS Total_Orders,
            ROUND(SUM(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount), 2) AS Net_Revenue,
            ROUND(AVG(Order_Total_Amount - Order_Total_Tax_Amount - Order_Refund_Amount), 2) AS AOV,
            ROUND(SUM(Order_Refund_Amount), 2) AS Total_Refunds
        FROM 'Ferryx_Sales_Data.csv'
        GROUP BY Website
    """).df()
    return df

try:
    data = load_data()

    # Top KPI Metrics
    col1, col2, col3 = st.columns(3)
    col1.metric("Total Net Revenue", f"£{data['Net_Revenue'].sum():,.2f}")
    col2.metric("Total Orders", f"{data['Total_Orders'].sum():,}")
    col3.metric("Total Refunds Issued", f"£{data['Total_Refunds'].sum():,.2f}")

    st.markdown("---")

    # Interactive Bar Chart
    fig = px.bar(
        data, 
        x="Website", 
        y="Net_Revenue", 
        color="Website", 
        title="Net Revenue by Platform (£)",
        text_auto=True
    )
    st.plotly_chart(fig, use_container_width=True)

    # Raw Summary Table
    st.subheader("Summary Table")
    st.dataframe(data, use_container_width=True)

except Exception as e:
    st.error(f"Could not load data: {e}")
    st.info("Make sure 'Ferryx_Sales_Data.csv' is saved in the exact same folder as app.py!")
