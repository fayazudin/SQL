#sql codes for ad_hoc requests

# 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
select distinct market from dim_customer where region ="apac" and customer ="atliq exclusive";

# 2.What is the percentage of unique product increase in 2021 vs. 2020?
with cet1 as (select (select count(distinct product_code) as unique_product_2020 from fact_gross_price s where fiscal_year=2020)
as unique_product_2020,
(select count(distinct product_code) as unique_product_2021 from fact_gross_price  where fiscal_year=2021) as unique_product_2021
from fact_gross_price)
select *, (unique_product_2021-unique_product_2020)*100/ unique_product_2020 as pct_change_in_unique_product from cet1 limit 1;

# 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select segment, count(distinct product_code) as unique_product from dim_product group by segment
order by unique_product desc;

# 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
	#view created for improving readability of code
    #view for segment column in fact_sales_montly table
    select s.date, s.product_code, s.fiscal_year, p.segment from fact_sales_monthly s join dim_product p on 
    s.product_code=p.product_code;
    #view for unique product count in fy2020
    select segment, count(distinct product_code) as unique_product_2020 from segment_sales where fiscal_year
=2020  group by segment;
     #view for unique product count in fy2021
     select segment, count(distinct product_code) as unique_product_2021 from segment_sales where fiscal_year
=2021 group by segment;
    #Ans for question no. 4
    with cet1 as (select s.segment, s.unique_product_2020, p.unique_product_2021 from segementp_2020 s join segmentp_2021 p
on s.segment=p.segment)
select *, (unique_product_2021-unique_product_2020)as difference
from cet1 order by difference desc;

# 5.Get the products that have the highest and lowest manufacturing costs.
(select p.product_code, p.product, m.manufacturing_cost from dim_product p join fact_manufacturing_cost m
on p.product_code=m.product_code where m.cost_year = 2021 order by manufacturing_cost desc limit 5)
union 
(select p.product_code, p.product, m.manufacturing_cost from dim_product p join fact_manufacturing_cost m
on p.product_code=m.product_code where m.cost_year = 2021 order by manufacturing_cost asc limit 5);

# 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
select p.customer_code, c.customer, round(avg(pre_invoice_discount_pct),2) as avg_pre_invoice_dist_pct 
from fact_pre_invoice_deductions p join dim_customer c on p.customer_code= c.customer_code 
where p.fiscal_year= 2021 and c.market= "india"
group by p.customer_code, c.customer order by avg_pre_invoice_dist_pct desc limit 5;

# 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions.
select s.date , s.fiscal_year , round(sum(sold_quantity*gross_price),2) as gross_total_amt
from fact_sales_monthly s join fact_gross_price g on s.product_code=g.product_code and s.fiscal_year=
g.fiscal_year join dim_customer c on c.customer_code=s.customer_code where customer= "Atliq Exclusive"
group by s.date , s.fiscal_year order by s.date;

# 8.In which quarter of 2020, got the maximum total_sold_quantity?
    #view for quater wise sold quantity for year 2020
    with cet1 as (select 
case when month(date) = "9,10,11" then "Q1"
when month(date) = "12,1,2" then "Q2"
when month(date) = "3,4,5" then "Q3"
else "Q4" 
end as Quater, s.sold_quantity from fact_sales_monthly s where fiscal_year=2020 )
select* from cet1;
      #Answer of question no. 8
      select Quater, sum(sold_quantity) as total_sold_quantity from quater_2020_data group by quater order by 
total_sold_quantity desc;

# 9. Which channel helped to bring more gross sales(in millions) in the fiscal year 2021 and the percentage of contribution?
with cet1 as (select c.channel, round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln from fact_sales_monthly s
join fact_gross_price g on s.product_code=g.product_code join dim_customer c on c.customer_code=s.customer_code
where s.fiscal_year=2021 group by c.channel)
select *, gross_sales_mln*100/sum(gross_sales_mln) over() as pct_contri from cet1 order by 
pct_contri desc;
# 9.1. Addtional analysis: Which channel helped to bring more gross (in millions) sales in the fiscal year 2020 and the percentage of contribution? Also show customers count of each channel.
with cet2 as (select c.channel, round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln, 
count(distinct s.customer_code) as customer_count from fact_sales_monthly s
join fact_gross_price g on s.product_code=g.product_code join dim_customer c on c.customer_code=s.customer_code
where s.fiscal_year=2020 group by c.channel)
select *, gross_sales_mln*100/sum(gross_sales_mln) over() as pct_contri from cet2 order by 
pct_contri desc;
# same query of 9.1. for 2021 with total customer count from each channel (for comparison purpose)
with cet2 as (select c.channel, round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln, 
count(distinct s.customer_code) as customer_count from fact_sales_monthly s
join fact_gross_price g on s.product_code=g.product_code join dim_customer c on c.customer_code=s.customer_code
where s.fiscal_year=2021 group by c.channel)
select *, gross_sales_mln*100/sum(gross_sales_mln) over() as pct_contri from cet2 order by 
pct_contri desc;

# 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
     #view created for total sold quantity 
     select s.product_code, sum(s.sold_quantity) as total_sold_quantity from fact_sales_monthly s
where fiscal_year=2021 
group by s.product_code;
      #Answer of question no. 10
      with cet1 as (select s.product_code, p.division, p.product, s.total_sold_quantity 
 from total_qty_for_topn_product s join dim_product p on s.product_code=p.product_code), cet2 as
(select*, dense_rank() over (partition by division order by total_sold_quantity desc) as rank_no from 
cet1)
select * from cet2 where rank_no<=3;
      



