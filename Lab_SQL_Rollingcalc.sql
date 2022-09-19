use sakila;

-- 1. Get number of monthly active customers.

select * from rental;

-- converting date format to year and month in separate columns
create or replace view customers_activity as
	select customer_id, convert(rental_date, date) as activity_date, 
    date_format(convert(rental_date, date), "%m") as activity_month,
    date_format(convert(rental_date, date), "%y") as activity_year
    from rental;

select * from customers_activity;

-- creating new viw with the count of distint active customers per month
create or replace view monthly_active_customers as
  select activity_month, activity_year, count(distinct customer_id) as active_customers
  from customers_activity
  group by activity_year, activity_month
  order by activity_year, activity_month;
  
  select * from monthly_active_customers;

-- 2. Active users in the previous month.

-- using lag to get the info from the last month
 select activity_year, activity_month,
         active_customers,
         lag(active_customers) over (partition by activity_year order by activity_month) as last_month_customer
  from monthly_active_customers; 

-- 3. Percentage change in the number of active customers.

create or replace view difference_monthly_active_customers as
  with cte_view as (
	select activity_year, activity_month,
           active_customers,
           lag(active_customers) over (partition by activity_year order by activity_month) as last_month_customers
	from monthly_active_customers
     )
     select 
        activity_year,
        activity_month,
        active_customers,
        (active_customers - last_month_customers) as monthly_difference,
        ((active_customers - last_month_customers) / last_month_customers) as monthly_difference_percentage
	from cte_view;

select * from difference_monthly_active_customers;

-- 4. Retained customers every month.

-- monhtly active customers (detailed)
create or replace view distinct_customers as
  select distinct customer_id as active_id,
         activity_year,
         activity_month
  from customers_activity
  order by activity_year, activity_month, customer_id;

select * from distinct_customers;

-- customers that rented films this month and also last month
create or replace view recurrent_customers as
  select d1.active_id, d1.activity_year, d1.activity_month 
  from distinct_customers d1
  join distinct_customers d2
  on d1.activity_year = d2.activity_year
  and d1.activity_month = d2.activity_month +1 -- to get consecutive months (attention: we are not covering case december yy- jan yy+1)
  and d1.active_id = d2.active_id -- to get recurrent users
  order by d1.active_id, d1.activity_year, d1.activity_month;
  
  select * from recurrent_customers;

-- counting the number of recurrent customers per month

create or replace view total_recurrent_customers as
    select activity_year, activity_month, count(active_id) as recurrent_customers
    from recurrent_customers
    group by activity_year, activity_month;
    
    select * from total_recurrent_customers;



