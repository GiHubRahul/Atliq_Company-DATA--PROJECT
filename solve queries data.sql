use gdb023 
SELECT * FROM dim_customer ;
SELECT * FROM dim_product;
select * FROM fact_sales_monthly;

 /*customer working in atliq exclusive*/ 

SELECT distinct market FROM dim_customer 
WHERE customer = "Atliq Exclusive" ;

/* find unique product in 2021 and 2022 as a percentage */

 WITH cte1 AS (WITH cte as(SELECT DISTINCT(product_code) AS new_product_code,
 cost_year FROM fact_manufacturing_cost ORDER BY  cost_year) 
 SELECT 
    sum(CASE WHEN cost_year= '2020'  THEN 1 Else null end)AS unique_products_2020,
    sum(CASE WHEN cost_year= '2021'  THEN 1 Else null end)AS unique_products_2021
 FROM cte) SELECT unique_products_2020,unique_products_2021,
            IF( unique_products_2021>unique_products_2020 ,
            ROUND((ABS(unique_products_2021-unique_products_2020) *100/unique_products_2020),2),
            ROUND((ABS(unique_products_2021-unique_products_2020) *100/unique_products_2021),2)) AS 
             per_chg
 FROM cte1;

/*count unique product and segment */

 SELECT DISTINCT(segment) AS segment,COUNT(DISTINCT (product_code)) AS product_count FROM dim_product
 GROUP BY segment
 ORDER BY product_count DESC;

/*. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields*/
 
 WITH set_  AS (SELECT p.segment,COUNT(DISTINCT p.product_code) AS product_count_2020 FROM dim_product p
      INNER JOIN fact_sales_monthly s ON p.product_code=s.product_code WHERE fiscal_year=2020 
      GROUP BY segment ORDER BY product_count_2020 DESC ),
  cte5 AS(SELECT p.segment,COUNT(DISTINCT p.product_code) AS product_count_2021 FROM dim_product p
  INNER JOIN fact_sales_monthly s ON p.product_code=s.product_code WHERE fiscal_year=2021 GROUP BY segment
  ORDER BY product_count_2021 DESC )
 SELECT set_.segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020)
 AS Difference FROM set_ INNER JOIN cte5 ON set_.segment=cte5.segment ORDER BY Difference DESC;

/*Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,*/
 SELECT  * FROM
     (SELECT  p.product_code, p.product, m.manufacturing_cost FROM
      dim_product p INNER JOIN fact_manufacturing_cost m ON p.product_code = m.product_code
      ORDER BY manufacturing_cost DESC LIMIT 1) A 
 UNION 
 SELECT * FROM
     (SELECT p.product_code, p.product, m.manufacturing_cost FROM
     dim_product p INNER JOIN fact_manufacturing_cost m ON p.product_code = m.product_code
     ORDER BY manufacturing_cost ASC
     LIMIT 1) B;
     
     /*Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,*/

WITH cte13 AS(WITH cte6 AS(SELECT C.customer_code,C.customer,D.pre_invoice_discount_pct FROM dim_customer C 
INNER JOIN fact_pre_invoice_deductions D ON C.customer_code=D.customer_code WHERE C.market="India" AND D.fiscal_year=2021) 
SELECT cte6.*,(SELECT avg(pre_invoice_discount_pct) FROM cte6) AS average_value FROM cte6) 
SELECT customer_code,customer,ROUND(pre_invoice_discount_pct*100,2) AS average_discount_pct FROM cte13 WHERE pre_invoice_discount_pct >average_value ORDER BY           average_discount_pct DESC LIMIT 5 ;

/* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.*/

 SELECT DATE_FORMAT(date,'%M') as Month,YEAR(date) as Year,ROUND(SUM(fact_gross_price.gross_price*
 fact_sales_monthly.sold_quantity),2) as gross_sales_amount FROM fact_sales_monthly 
 INNER JOIN fact_gross_price ON  fact_sales_monthly.product_code=fact_gross_price.product_code
 INNER JOIN dim_customer ON fact_sales_monthly.customer_code=dim_customer.customer_code
 WHERE dim_customer.customer="Atliq Exclusive" group by Month,Year ;
 
 /*. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,*/
 WITH cte7 AS (SELECT date,MONTH(date) AS Month,sold_quantity FROM fact_sales_monthly 
 WHERE fiscal_year=2020 )SELECT  CASE WHEN Month IN (9,10,11) THEN '1' 
									   WHEN Month IN (12,1,2) THEN '2' 
                                       WHEN Month IN (3,4,5) THEN '3 '
                                       WHEN Month IN (6,7,8) THEN '4' 
                                   END AS Quarter ,SUM(sold_quantity) AS total_sold_quantity   
                       FROM cte7  GROUP BY Quarter ORDER BY total_sold_quantity DESC  ;
/*Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,*/

  WITH cte16 AS(SELECT C.channel,ROUND(SUM(A.sold_quantity*B.gross_price)/1000000,2) AS gross_sales_mln
  FROM fact_sales_monthly A 
  LEFT JOIN fact_gross_price B ON A.product_code=B.product_code
  LEFT JOIN dim_customer C ON A.customer_code=C.customer_code 
  WHERE A.fiscal_year=2021 GROUP BY C.channel  ORDER BY 2 DESC)
  SELECT *,ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2) AS percentage FROM cte16; 
  
  /* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,*/
  WITH cte12 AS(WITH cte11 AS(WITH cte10 AS(SELECT B.division,A.product_code,B.product,A.sold_quantity FROM fact_sales_monthly A 
  LEFT JOIN dim_product B ON A.product_code=B.product_code WHERE A.fiscal_year=2021) 
  SELECT  division,product_code,product,SUM(sold_quantity) AS total_sold_quantity
  FROM cte10 GROUP BY product) SELECT cte11.*,
  rank() OVER(partition by division order by total_sold_quantity DESC  ) AS rank_order from cte11 )
  SELECT * FROM cte12 WHERE rank_order < 4;




       