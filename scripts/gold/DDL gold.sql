/*
==============================================================
DDL Script: Create Gold Views
==============================================================

Script Purpose:
This script creates views for the Gold layer in the data warehouse.
The Gold layer represents the final dimension and fact tables (Star Schema).

Each view performs transformations and combines data from the Silver layer
to produce a clean, enriched, and business-ready dataset.

Usage:
  - These views can be queried directly for analytics and reporting.

==============================================================
*/

--  ================================================================
-- Create Dimension Table: gold_layer.dim_customers
--  ================================================================

IF OBJECT_ID('gold_layer.dim_customers','V') IS NOT NULL
	DROP VIEW Gold_Layer.dim_customers

GO
CREATE VIEW Gold_layer.dim_customers AS

SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	cci.cst_id AS customer_id,
	cci.cst_key AS customer_number,
	cci.cst_firstname AS first_name,
	cci.cst_lastname AS last_name,
	ela.CNTRY AS country,
	cst_marital_status AS marital_status,
	CASE WHEN cci.cst_gndr!='n/a' THEN cci.cst_gndr
		 ELSE COALESCE(eca.GEN,'n/a')
	END gender,
	eca.BDATE AS birthdate,
	cci.cst_create_date AS create_date

FROM Silver_Layer.cdm_cust_info cci
	LEFT JOIN Silver_Layer.erp_cust_az12 eca
ON cci.cst_key=eca.CID
	LEFT JOIN Silver_Layer.erp_loc_a101 ela
ON cci.cst_key=ela.CID

GO


--  ================================================================
-- Create Dimension Table: gold_layer.dim_products
--  ================================================================

IF OBJECT_ID('gold_layer.dim_products','V') IS NOT NULL
	DROP VIEW Gold_Layer.dim_products

GO
CREATE VIEW Gold_layer.dim_products AS

SELECT ROW_NUMBER() OVER(ORDER BY cpi.prd_id) AS product_key, --Creating a surrogate key for easy manipulation
	   cpi.prd_id AS product_id,
	   cpi.sls_key AS product_number,
	   cpi.prd_nm AS product_name,
	   cpi.id_category AS category_id,
	   epcg.CAT AS category,
	   epcg.SUBCAT AS subcategory,	   
	   epcg.MAINTENANCE AS maintenance,
	   cpi.prd_cost AS cost,
	   cpi.prd_line AS product_line,
	   cpi.prd_start_dt AS start_date
FROM Silver_Layer.cdm_prd_info cpi
LEFT JOIN Silver_Layer.erp_px_cat_g1v2 epcg
ON cpi.id_category=epcg.ID
WHERE prd_end_dt IS NULL    ---Filter Out All Historical Data

GO


--  ================================================================
-- Create Fact Table: gold_layer.fact_sales
--  ================================================================

IF OBJECT_ID('gold_layer.fact_sales','V') IS NOT NULL
	DROP VIEW Gold_Layer.fact_sales
GO

CREATE VIEW Gold_layer.fact_sales AS

SELECT
	 csd.sls_ord_num AS order_number,
	 dc.customer_key,
	 dp.product_key,
	 csd.sls_order_dt AS order_date,
	 csd.sls_ship_dt AS ship_date,
	 csd.sls_due_dt AS due_date,
	 csd.sls_sales AS sales_amount,
	 csd.sls_quantity AS quantity,
	 csd.sls_price AS price
FROM Silver_Layer.cdm_sales_details csd
LEFT JOIN Gold_Layer.dim_customers dc
	ON csd.sls_cust_id=dc.customer_id
LEFT JOIN Gold_Layer.dim_products dp
	ON csd.sls_prd_key=dp.product_number

GO
