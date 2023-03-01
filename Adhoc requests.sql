#Adhoc Rq#1
SELECT customer,market,region FROM gdb023.dim_customer where region='APAC' and customer='Atliq Exclusive'
order by market;


#ADHOC RQ#2
WITH unique_products_2020 AS (SELECT 
	COUNT(DISTINCT p.product_code) AS unique_products_2020
	FROM fact_sales_monthly s
	join dim_product p
		on s.product_code=p.product_code
where fiscal_year=2020), unique_products_2021 AS (SELECT 
	COUNT(DISTINCT p.product_code) AS unique_products_2021
	FROM fact_sales_monthly s
	join dim_product p
		on s.product_code=p.product_code
where fiscal_year=2021
)
SELECT 
  unique_products_2020, 
  unique_products_2021, 
  concat((unique_products_2021 - unique_products_2020)/unique_products_2020*100 ,  '%') AS percentage_chg 
FROM 
	unique_products_2020, 
	unique_products_2021;


#ADHOC RQ#3
select segment, 
count( distinct product_code) as product_count
from dim_product
group by segment
order by product_count DESC;


#ADHOC RQ#4 
with product_2020 As
( select segment, 
count( distinct p.product_code) as product_count_2020
from dim_product p
inner join fact_sales_monthly sm on p.product_code=sm.product_code
where sm.fiscal_year=2020
group by segment
order by product_count_2020 DESC
)
, product_2021 As
( select segment, 
count( distinct p.product_code) as product_count_2021
from dim_product p
inner join fact_sales_monthly sm on p.product_code=sm.product_code
where sm.fiscal_year=2021
group by segment
#order by product_count_2021 DESC
)
	
select product_2020.segment ,product_count_2020,product_count_2021, (product_count_2021-product_count_2020) as difference
from product_2020
INNER JOIN product_2021 ON product_2020.segment = product_2021.segment;


#ADHOC RQ#5
(SELECT p.product , p.product_code, m.manufacturing_cost
from dim_product p , fact_manufacturing_cost m
where p.product_code = m.product_code and 
m.manufacturing_cost = ( select max(m.manufacturing_cost) 
where p.product_code= m.product_code)
order by m.manufacturing_cost desc
limit 1)
union all
(SELECT p.product , p.product_code, m.manufacturing_cost
from dim_product p , fact_manufacturing_cost m
where p.product_code = m.product_code and 
m.manufacturing_cost = ( select min(m.manufacturing_cost) 
where p.product_code= m.product_code)
order by m.manufacturing_cost
limit 1) ;


#ADHOC RQ#6
SELECT 
	d.customer_code,
    c.customer,
    concat(round(avg(pre_invoice_discount_pct),2),'%') as average_discount_percentage
    
FROM fact_pre_invoice_deductions d
JOIN dim_customer c 
	ON c.customer_code=d.customer_code
WHERE fiscal_year=2021 
AND market="India"
group by customer
order by average_discount_percentage desc
LIMIT 5;


#ADHOC RQ#7
select monthname(date)as month, year(date) as year, 
sum((g.gross_price*s.sold_quantity)) as Gross_Sales_Amount
from fact_sales_monthly s
 join fact_gross_price g 
 on s.product_code= g.product_code
 join dim_customer c 
 on c.customer_code=s.customer_code
 where c.customer='Atliq Exclusive'
 group by month,year
 order by year;


#ADHOC RQ#8
select 
case
when month(date) in (9,10,11) then 'Quarter 1'
when month(date) in (12,1,2) then 'Quarter 2'
when month(date) in (3,4,5) then 'Quarter 3'
when month(date) in (6,7,8) then 'Quarter 4'
end as Quarter ,
sum(sold_quantity) as Total_sold_quantity
from fact_sales_monthly
where fiscal_year='2020'
group by Quarter;


#ADHOC RQ#9
with channels as(
SELECT channel,round(SUM(g.gross_price * s.sold_quantity)) AS 'gross_sales_mln' 
FROM gdb023.fact_gross_price as g inner join gdb023.fact_sales_monthly as s
on g.product_code=s.product_code and g.fiscal_year=s.fiscal_year
inner join gdb023.dim_customer as c
on c.customer_code=s.customer_code
where s.fiscal_year='2021'
group by channel)
select channel , gross_sales_mln ,round((gross_sales_mln*100))/sum(gross_sales_mln) 
over() 
as  percentage
from channels
order by percentage desc;


#ADHOC RQ#10
with top3 as
(
SELECT p.division ,
 p.product, p.product_code,
 sum(s.sold_quantity) as total_sold_quantity,
 dense_rank() over(partition by division order by sum(s.sold_quantity) desc ) as rank_order
FROM 
dim_product p
 join fact_sales_monthly s on
p.product_code=s.product_code
 where s.fiscal_year='2021'
group by product,division,product_code
)
select *
from top3
where rank_order <= 3
;
