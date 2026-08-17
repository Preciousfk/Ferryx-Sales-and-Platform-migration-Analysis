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

# Load Data using DuckDB
@st.cache_data
def metrics():
