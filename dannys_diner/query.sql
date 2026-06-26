-- 1.What is the total amount each customer spent at the restaurant?
select customer_id,
       sum(price) as total_spent
from sales
join menu
on sales.product_id=menu.product_id
group by customer_id
order by customer_id;


-- 2.How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as date
from sales
group by customer_id
order by customer_id;


-- 3.What was the first item from the menu purchased by each customer?
with cte_order as (
  select sales.customer_id,
       product_name,
       row_number() over(
       partition by sales.customer_id
       order by sales.order_date,sales.product_id
       ) as item_order
 from sales
 join menu
 on sales.product_id = menu.product_id
) 
select * from cte_order
where item_order = 1;



-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select sales.product_id,
       product_name,
       count(*) as times
from sales
join menu
on sales.product_id = menu.product_id
group by product_name,sales.product_id
order by times desc
limit 1;


-- 5.Which item was the most popular for each customer?
with 
customer_status as(
select customer_id,
       product_name,
       count(*) as order_count
from sales
join menu
on sales.product_id = menu.product_id
group by customer_id,product_name
),


ranked_item as(
select customer_id,
       product_name,
       order_count,
       rank() over(
       partition by customer_id
       order by order_count desc
       ) as rnk
from customer_status
)


select customer_id,product_name,order_count,rnk
from ranked_item
where rnk=1;


DROP TABLE IF EXISTS membership_validation;
CREATE TEMP TABLE membership_validation AS
SELECT
   sales.customer_id,
   sales.order_date,
   menu.product_name,
   menu.price,
   members.join_date,
   CASE WHEN sales.order_date >= members.join_date
     THEN 'X'
     ELSE ''
     END AS membership
FROM dannys_diner.sales
 INNER JOIN dannys_diner.menu
   ON sales.product_id = menu.product_id
 LEFT JOIN dannys_diner.members
   ON sales.customer_id = members.customer_id
  WHERE join_date IS NOT NULL
  ORDER BY 
    customer_id,
    order_date;

CREATE TEMPORARY TABLE membership_validation AS
SELECT
   sales.customer_id,
   sales.order_date,
   menu.product_name,
   menu.price,
   members.join_date,
   CASE WHEN sales.order_date >= members.join_date
     THEN 'X'
     ELSE ''
     END AS membership
FROM dannys_diner.sales
 INNER JOIN dannys_diner.menu
   ON sales.product_id = menu.product_id
 LEFT JOIN dannys_diner.members
   ON sales.customer_id = members.customer_id
  WHERE join_date IS NOT NULL
  ORDER BY 
    customer_id,
    order_date;

-- 6. Which item was purchased first by the customer after they became a member?
-- Note: In this question, the orders made during the join date are counted within the first order as well

select
   customer_id,product_name,order_date,purchase_order
from (select customer_id,product_name,order_date,
       rank() over(
       partition by customer_id
       order by order_date
       )as purchase_order
from membership_validation
where membership = 'X') t
where purchase_order=1;

-- 7. Which item was purchased just before the customer became a member?
with
t as
(select customer_id,product_name,order_date,
        rank() over(
        partition by customer_id
        order by order_date desc
        ) as purchase_order
      from membership_validation
where membership = '')

select customer_id,product_name,order_date,purchase_order
from t
where purchase_order = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
WITH 
t AS
(
    SELECT customer_id, product_name, price
    FROM membership_validation
    WHERE membership = ''
)
SELECT 
    customer_id,
    COUNT(product_name) AS times,
    SUM(price) AS total_price
FROM t
GROUP BY customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,
       sum(case
              when product_name='sushi' then price*20
           else price*10
           end) total_points
from membership_validation
group by customer_id
order by total_points



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- --create temp table for days validation within the first week membership
select customer_id,
