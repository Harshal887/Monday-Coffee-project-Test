SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;
SELECT * FROM products;

--Question1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT
    city_name,
	population,
	city_rank
FROM city

SELECT
    city_name,
	population,
	city_rank
FROM city
ORDER BY 2 desc


SELECT
    city_name,
	population * 0.25,
	city_rank
FROM city
ORDER BY 2 desc

SELECT
    city_name,
	(population * 0.25)/1000000 as coffee_counsumers_in_millions,
	city_rank
FROM city
ORDER BY 2 desc


SELECT
    city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_counsumers_in_millions,
	city_rank
FROM city
ORDER BY 2 desc

-- Question 2. Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT *,
     EXTRACT(YEAR FROM sale_date) as year,
	 EXTRACT (qtr FROM sale_date) as qtr
FROM sales

SELECT *,
     EXTRACT(YEAR FROM sale_date) as year,
	 EXTRACT (quarter FROM sale_date) as qtr
FROM sales
WHERE
    EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT (quarter FROM sale_date) = 4

-- for total revenue

SELECT
     SUM(total) as total_revenue
FROM sales
WHERE
    EXTRACT(YEAR FROM sale_date) = 2023
	AND
	EXTRACT (quarter FROM sale_date) = 4

-- for the city revenue

SELECT
     ci.city_name,
     SUM(total) as total_revenue
FROM sales as s 
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE
    EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT (quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

-- Question3. Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT * 
FROM products as p
LEFT JOIN 
sales AS s 
ON s.product_id = p.product_id

-- frind out each product and no of orders that wwe have received for each product.

SELECT
    p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN 
sales AS s 
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


---Question.4. Average Sales Amount per City
-- What is the average sales amount per customer in each city?


-- city and total sale
-- no cx in each these city

SELECT
    ci.city_name,
    SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx
FROM sales as s 
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

 -- average sales amount per customer in each city?
SELECT
    ci.city_name,
    SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
	        SUM(s.total)::numeric/
	            COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx

FROM sales as s
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC



-- Question.5 
-- City Population and Coffee Consumers(25%)
-- Provide a list of cities along with their populations and estimated coffee consumer
-- return city_name, total current cx, emtimated coffee consumer (25%)

WITH city_table as 

(
   SELECT 
       city_name,
	   ROUND((population * 0.25)/1000000, 2) as coffee_consumers
   FROM city
), 
customers_table
AS
(
    SELECT
	     ci.city_name,
		 COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s 
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
    customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


--- Question.6 Top Selling Products by City
--- What are the top 3 selling products in each city based on sales volume?
SELECT * 
FROM -- TABLE 
(
   SELECT
     ci.city_name,
	 p.product_name,
	 COUNT(s.sale_id) as total_orders,
	 DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
FROM sales as s 
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id 
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC
) as t1
WHERE RANK <=3


-- Quetion 7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?



SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
    s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

-- Question8. Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
-- conclusions

WITH city_table
AS
(
  SELECT
      ci.city_name,
	  SUM(s.total) as total_revenue,
	  COUNT(DISTINCT s.customer_id) as total_cx,
	  ROUND(
	          SUM(S.total)::numeric/
			      COUNT(DISTINCT s.customer_id)::numeric
				  ,2) as avg_sale_pr_cx

  FROM sales as s 
  JOIN customers as c 
  ON s.customer_id = c.customer_id
  JOIN city as ci
  ON ci.city_id = c.city_id
  GROUP BY 1
  ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
    city_name,
	estimated_rent
FROM city
)
SELECT
    cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
	    cr.estimated_rent::numeric/ct.total_cx::numeric
        , 2)avg_rent_per_cx


FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC




-- Quetion.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly). 
-- BY EACH CITY

WITH
monthly_sales
AS 
(  
    SELECT
        ci.city_name,
	    EXTRACT(MONTH FROM sale_date) as month, 
	    EXTRACT(YEAR FROM sale_date) as YEAR,
	    SUM(s.total) as total_sale
    FROM sales as s 
    JOIN customers as c 
    ON c.customer_id = s.customer_id
    JOIN  city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 3, 2
),
growth_ratio
AS
(
       SELECT 
           city_name,
           month,
           year,
           total_sale as cr_month_sale,
	       LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
       FROM monthly_sales
)

SELECT
    city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
	    (cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
	    , 2
	    ) as growth_ratio

FROM growth_ratio
WHERE 
    last_month_sale IS NOT NULL

--Quetion10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
  SELECT
      ci.city_name,
	  SUM(s.total) as total_revenue,
	  COUNT(DISTINCT s.customer_id) as total_cx,
	  ROUND(
	          SUM(S.total)::numeric/
			      COUNT(DISTINCT s.customer_id)::numeric
				  ,2) as avg_sale_pr_cx

  FROM sales as s 
  JOIN customers as c 
  ON s.customer_id = c.customer_id
  JOIN city as ci
  ON ci.city_id = c.city_id
  GROUP BY 1
  ORDER BY 2 DESC
),
city_rent
AS
(
     SELECT
          city_name,
	      estimated_rent,
	      ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
     FROM city
)
SELECT
    cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
	    cr.estimated_rent::numeric/
		                           ct.total_cx::numeric
        , 2)avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- RECOMENDATION 
-- CITY 1: PUNE
       
	    1. Avg rent per cx is very less,
		2. Highest total revenue,
		3. Avg_sale per cx is also high

-- City 2: DELHI
        
        1.Highest Estimated coffee consumer which is 7.7M
		2.Highest total cx which is 68
		3.Avg rent per cx 330(still uner 500)

-- City 3. JAIPUR 
        
		1. HIghest cx no which is 69
		2. Avg rent per cx is very less 156
		3. Avg sale per cx is better which is at 11.6k

 


