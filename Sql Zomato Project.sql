
# I have created a dummy data and performed certain tasks over it.

create database project;

use project;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup
(userid integer,
gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-01-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


# Q1- What is the total amount each customer is spending?

select a.userid, sum(b.price) as total_amount_spent
from sales as a
inner join 
product as b
on a.product_id=b.product_id
group by userid
;
-- userid 1 has spent 5230, userid 2 has spent 4570 and userid 3 has spent 2510

# Q2- How many days each customer visited zomato?

select userid, count(distinct (created_date)) as visited_zomato from sales 
group by userid;
-- userid 1 has visited 7 times, userid 2 has visited 4 times and userid 3 has visited 5 times.

# Q3- What was the first project purchased by each customer?

select * from 
(select *, rank() over (partition by userid order by created_date) as rnk from sales) 
a
where rnk=1;
-- Each customers first product was 1. So, we can say that productid 1 is attracting customer.

# Q4- What is the most purchased item from the menu and how many times was it purchased by all the customers?

select userid, count(product_id) from sales where product_id=
(select product_id from sales
group by product_id
order by count(product_id) desc
limit 1) 
group by userid; 
-- Productid 2 was the most purchased product by all the customers and it count was 7. 
-- So, we can say that Productid 1 is the first product customers are buying but Productid 2 is the purchased more.

# Q5 - Which item was most popular for each of the customer?

select * from
(select *, rank() over (partition by userid order by cnt desc) rnk from
(select userid, product_id ,count(product_id) cnt from sales
group by userid, product_id)a )b	
where rnk=1;

--  userid 1 has productid 2 as fav, userid 2 has productid 3 as fav and userid 3 has productid 2 as fav.

# Q6 Which item was first purchased by the customer they became a member?

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

select * from 
(select c.*,rank() over (partition by userid order by created_date asc ) rnk from
(select a.gold_signup_date,b.userid,b.created_date,b.Product_id from goldusers_signup a
inner join sales b 
on a.userid = b.userid and
created_date>=gold_signup_date) c)d
where rnk = 1 ;

-- userid 1 has purchased productid 3 and userid 3 has purchased productid 2, as first product after buying gold_signup membership.

# Q7 Which item was purchased by customer just before becoming a member?

select * from
(select c.*, rank() over (partition by userid order by created_date desc) rnk from
(select a.gold_signup_date,b.userid,b.created_date,b.Product_id from goldusers_signup a
inner join sales b 
on a.userid = b.userid and
created_date<gold_signup_date) c)d
where rnk=1;

-- Before becoming a member userid 1 has purchased productid 2 and userid3 has purchased productid 2.

# Q8 What is the total order and amount spent for each member before they became a member?

select * from product;
select * from sales;

select c.userid,count(c.product_id) product_id,sum(d.price) Total_amount from 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date
from sales a
inner join goldusers_signup b
on a.userid=b.userid
where created_date<gold_signup_date)c
inner join product d
on c.product_id=d.product_id
group by c.userid
order by sum(d.price) desc;

-- Userid 1 has ordered 5 products worth 4030 and userid3 has ordered 3 products worth 2720 before becoming a member.

# Q9 If buying each product generates points for eg 5rs=2 Zomato point and 
# each product has different purchasing point for eg for p1 5rs = 1 , p2 10rs = 5, 5rs = 2.5 and p3 5rs = 1 Zomato points.
# Calculate points collected by each customer and for which product most points has been given till now ?


select userid,sum(zomato_points) Total_zomato_points from
(select e.*, amt/points zomato_points from
(select d.*,
case
	when product_id = 1 or product_id= 3 then 5
    else 2
end points
from
(select userid,product_id,sum(price) amt
from
(select a.userid,a.product_id,b.price 
from sales a
inner join product b
on a.product_id = b.product_id)c
group by userid,product_id)d)e)f
group by userid ;

select * from 
(select *, rank() over(order by total_points_given desc) rnk from
(select product_id, sum(total_points) total_points_given from
(select e.*,amt/points total_points from
(select d.*,case when product_id =1 and product_id=3 then 5 when product_id=2 then 2 end as points from
(select c.userid,c.product_id,sum(price) amt from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id)c
group by userid,product_id)d)e)f group by product_id)f)g where rnk=1;

-- Points collected by each customer is 1829 for userid1, 1697 for userid2 and 763 userid3.
-- Productid 2 has given 3045 zomato points.

# Q10 In the first year after a customer joins a gold program (including their join date) irrespective of what the customer has purchased
# they earn 5 zomato points for every 10rs spent who earned more 1 or 3 and what was their points earnings in their first year?

select c.* , d.price*0.5 total_zomato_p_1yr from 
(select a.*,b.gold_signup_date from 
sales a
inner join 
goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date and created_date<=date_add(gold_signup_date,interval 1 year))c
inner join 
product d on c.product_id=d.product_id
order by total_zomato_p_1yr desc limit 1;

-- Userid 3 has earned 435 zomato points and userid 1 has earned 165 in 1st yr. So, userid 3 has earned more zomato points than userid 1.

# Q11 Rank all the transaction of the customer by date

select *,
rank() over(partition by userid order by created_date)rnk from sales;

# Q12 rank all the transaction of each member whenever they are zomato gold member for non gold member transaction mark as na.

select c.* , case when gold_signup_date is null then 'na' else rank() over (partition by userid order by created_date desc) end as rnk from
(select a.*,b.gold_signup_date from 
sales a
left join 
goldusers_signup b
on a.userid = b.userid and created_date>=gold_signup_date)c;

# Project Completed.