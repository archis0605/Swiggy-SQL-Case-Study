/* 1. Find customers who have never ordered food. */
with cte as (
	select *
	from users u
	left join orders o using(user_id))
select name as cust_name
from cte
where order_id is null;

/* 2. Find the average price per dish. */
select round(avg(price)) as avg_price_per_dish
from menu;

/* 3. Find the top restaurant in terms of the number of orders for a given month. */
with cte1 as (
	select monthname(date) as month, r_id, count(order_id) as orders_cnt
	from orders o
	group by 1,2
	order by 1),
cte2 as (
	select *, dense_rank() over(partition by month order by orders_cnt desc) as rnk
	from cte1)
select month, r.r_name, orders_cnt
from cte2 c
inner join restaurants r using(r_id)
where rnk = 1;

/* 4. Find the monthly sales of restaurants where the monthly revenue is greater than 500. */
with cte as (
	select o.r_id, r.r_name, month(date) as month, sum(amount) as month_rev
	from orders o
	inner join restaurants r using(r_id)
	group by 1,2,3
	order by 1,3)
select *
from cte
where month_rev > 500;

/* 5. Show all orders with order details for a particular customer between 2022-06-01 and 2022-08-01. */
select name, date, f_name, type, cuisine, r_name, amount, delivery_time, 
	delivery_rating, partner_name, restaurant_rating
from orders o
left join order_details od using(order_id)
left join food f using (f_id)
left join users u using(user_id)
left join restaurants r using(r_id)
left join delivery_partners p using(partner_id)
where date between '2022-06-01' and '2022-08-01' and name is not null
order by 1,2;

/* 6. Find restaurants with max repeated customers. */
with cte as (
	select r_id, user_id, count(user_id) as cnt
	from orders
	group by 1,2
	order by 1)
select r.r_name, u.name
from cte c
left join users u using(user_id)
left join restaurants r using(r_id)
where cnt = (select max(cnt) from cte);

/* 7. Month over month revenue growth of Swiggy. */
with cte1 as (
	select year(date) as year, month(date) as month, sum(amount) as revenue
	from orders
	group by 1,2),
cte2 as (
	select *, ifnull(lag(revenue) over(order by month asc),0) as prev_revenue
	from cte1)
select year, month,
	if(prev_revenue <> 0, round(((revenue/prev_revenue)-1)*100,1), 0) as MoM_Growth
from cte2;

/* 8. Find each customers favourite food. */
with cte1 as (
	select user_id, f_name, count(*) as food_cnt
	from orders o
	left join order_details od using(order_id)
	left join food f using(f_id)
	group by 1, 2),
cte2 as (
	select *, dense_rank() over(partition by user_id order by food_cnt desc) as food_rnk
	from cte1)
select user_id, f_name as cust_favourite_food
from cte2
where food_rnk = 1;

/* 9. Month-over-month revenue growth of a restaurant. */
with cte1 as (
	select r_id, year(date) as year, month(date) as month, sum(amount) as revenue
	from orders
	group by 1,2,3),
cte2 as (
	select *, ifnull(lag(revenue) over(partition by r_id order by month asc),0) as prev_revenue
	from cte1)
select r_id, concat(month,"-",year) as month_year,
	if(prev_revenue <> 0, round(((revenue/prev_revenue)-1)*100,1), 0) as MoM_Growth
from cte2
order by 1,2;
