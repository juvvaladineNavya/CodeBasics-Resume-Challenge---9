/*  Ques - 1 : Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free).
'This information will help us identify high-value products that are currently being heavily discounted, 
which can be useful for evaluating our pricing and promotion strategies.*/

SELECT DISTINCT product_name , base_price
FROM dim_products JOIN fact_events USING(product_code)
WHERE base_price > 500 AND promo_type = "BOGOF";

/* Ques - 2: Generate a report that provides an overview of the number of stores in each city. 
The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence. 
The report includes two essential fields: city and store count, which will assist in optimizing our retail operations.*/

SELECT city, count(store_id) AS No_of_stores  FROM dim_stores
GROUP BY city
ORDER BY No_of_stores DESC;

/* Ques -3 Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
The report includes three key fields: campaign _name, total revenue(before_promotion), total revenue(after_promotion). 
This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)*/

WITH Afterpromo  AS 
(
SELECT  campaign_id,concat(round(sum(Base_price_AfterPromo*quantity_sold_after_promo)/1000000, 2), 'M') AS AfterPromoRevenue
FROM (
SELECT campaign_id, 
CASE
WHEN promo_type = '50% OFF' THEN base_price *0.50
WHEN promo_type = '25% OFF' THEN base_price *0.75
WHEN promo_type = '33% OFF' THEN base_price *0.67
WHEN promo_type = 'BOGOF' THEN round(base_price /2,0)
WHEN promo_type = '500 Cashback' THEN base_price-500
END AS Base_price_AfterPromo,
CASE
when promo_type ="BOGOF" THEN `quantity_sold(after_promo)` *2 
ELSE`quantity_sold(after_promo)`
END AS quantity_sold_after_promo
FROM fact_events ) AS  Ptype 
GROUP BY campaign_id
 ),
Beforepromo AS 
(
SELECT campaign_id,concat(round(sum(`quantity_sold(before_promo)` *base_price)/1000000,2), 'M') AS BeforePromoRevenue 
FROM fact_events
GROUP BY campaign_id 
)
SELECT campaign_name , BeforepromoRevenue,  AfterpromoRevenue 
FROM Beforepromo JOIN Afterpromo USING (campaign_id) 
JOIN dim_campaigns USING(campaign_id); 

/* Ques-4: Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, isu%, and rank order. 
This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales. NOTE:::::
ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage increase/decrease in quantity sold (after promo) compared to quantity sold (before promo) */

WITH CTE1 AS 
(
SELECT category, 
concat(round(sum(quantity_sold_after_promo - `quantity_sold(before_promo)`)/sum( `quantity_sold(before_promo)`) *100 ,2),'%')AS ISU 
FROM
(SELECT product_code, campaign_id,
CASE
WHEN promo_type ="BOGOF" THEN `quantity_sold(after_promo)` *2 
ELSE`quantity_sold(after_promo)`
END AS quantity_sold_after_promo , `quantity_sold(before_promo)`
FROM fact_events) AS SQ1
JOIN dim_products USING(product_code) 
JOIN dim_campaigns USING(campaign_id)
WHERE campaign_name = "Diwali"
GROUP BY category
) 
SELECT * , RANK() OVER( ORDER BY  ISU DESC) AS ISU_Rank
FROM CTE1;

/* Ques - 4: Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
The report will provide essential information including product name, category, and ir%.
This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.*/

WITH Afterpromo  AS 
(
SELECT  product_code,concat(round(sum(Base_price_AfterPromo*quantity_sold_after_promo)/1000000, 2), 'M') AS AfterPromoRevenue
FROM (
SELECT product_code, 
CASE
WHEN promo_type = '50% OFF' THEN base_price *0.50
WHEN promo_type = '25% OFF' THEN base_price *0.75
WHEN promo_type = '33% OFF' THEN base_price *0.67
WHEN promo_type = 'BOGOF' THEN round(base_price /2,0)
WHEN promo_type = '500 Cashback' THEN base_price-500
END AS Base_price_AfterPromo,
CASE
WHEN promo_type ="BOGOF" THEN `quantity_sold(after_promo)` *2 
ELSE`quantity_sold(after_promo)`
END AS quantity_sold_after_promo
FROM fact_events ) AS  Ptype 
GROUP BY product_code
 ),
Beforepromo AS 
(
SELECT product_code,concat(round(sum(`quantity_sold(before_promo)` *base_price)/1000000,2), 'M') AS BeforePromoRevenue 
FROM fact_events
GROUP BY product_code
)
SELECT product_name,category,
concat(round((AfterpromoRevenue-BeforepromoRevenue)/ BeforepromoRevenue * 100,2),'%') AS IR,
RANK() OVER( ORDER BY (AfterpromoRevenue-BeforepromoRevenue )/ BeforepromoRevenue * 100 DESC) AS Rank_IR
FROM Beforepromo JOIN Afterpromo USING (product_code) 
JOIN dim_products d USING(product_code)
LIMIT 5;