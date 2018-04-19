#1. Creating a database and loading the data

CREATE DATABASE supermarket;

show databases;

USE  supermarket;

CREATE TABLE IF NOT EXISTS aisle(
id INT(11) NOT NULL PRIMARY KEY,
aisle VARCHAR(100) NOT NULL
);

show tables;

CREATE TABLE IF NOT EXISTS product(
id INT(11)  NOT NULL PRIMARY KEY,
name VARCHAR(200),
aisle_id INT(11) NOT NULL,
department_id INT(11),
FOREIGN KEY(aisle_id) REFERENCES aisle(id),
FOREIGN KEY (department_id) REFERENCES department(id)
);

CREATE TABLE IF NOT EXISTS department(
id INT(11)  NOT NULL,
department VARCHAR(30),
PRIMARY KEY(id)
);

create table orders(
id int not null primary key,
user_id int,
eval_set varchar(10),
order_number int,
order_dow int,
order_hour_of_day int,
days_since_prior_order int
);

CREATE TABLE IF NOT EXISTS order_product(
order_id INT(11),
product_id INT(11),
add_to_cart_order INT(11),
reordered INT(11),
FOREIGN KEY (product_id) REFERENCES product(id),
FOREIGN KEY (order_id) REFERENCES orders(id)
);


LOAD DATA LOCAL INFILE '/Users/kaylaxie/Documents/SQL/DSO599SQL/Project/Archive/aisles.csv' INTO TABLE aisle
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/Users/kaylaxie/Documents/SQL/DSO599SQL/Project/Archive/departments.csv' INTO TABLE department
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/Users/kaylaxie/Documents/SQL/DSO599SQL/Project/Archive/orders.csv' 
INTO TABLE orders
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES 
;

LOAD DATA LOCAL INFILE '/Users/kaylaxie/Documents/SQL/DSO599SQL/Project/Archive/products.csv' INTO TABLE product
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/Users/kaylaxie/Documents/SQL/DSO599SQL/Project/Archive/order_products.csv' INTO TABLE order_product
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

#2. Selecting top 10 products
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=0
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=1
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=2
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=3
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=4
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=5
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10)
UNION
(SELECT op.product_id, p.name, COUNT(*) AS total_order_amount,o.order_dow AS the_day
FROM orders AS o
JOIN order_product AS op
ON op.order_id=o.id
JOIN product AS p
ON p.id=op.product_id
WHERE o.order_dow=6
GROUP BY op.product_id
ORDER BY total_order_amount DESC
LIMIT 10);

#3 Displaying the 5 most popular products in each aisle
CREATE TABLE IF NOT EXISTS unranked_data AS (
SELECT
(CASE WHEN order_dow = 0 THEN "Sun"
            WHEN order_dow = 1 THEN "Mon"
            WHEN order_dow = 2 THEN "Tue"
            WHEN order_dow = 3 THEN "Wed"
            WHEN order_dow = 4 THEN "Thu"
            WHEN order_dow = 5 THEN "Fri"
            WHEN order_dow = 6 THEN "Sat" END) AS day_of_week,
aisle,
product_id,
COUNT(product.id) AS total_counts
FROM order_product
JOIN orders ON order_product.order_id = orders.id
JOIN product ON order_product.product_id = product.id
JOIN aisle ON product.aisle_id = aisle.id
WHERE order_dow IN (1,2,3,4,5)
GROUP BY day_of_week, aisle, product_id
);

SELECT day_of_week, aisle, product_id, total_counts
FROM
     (SELECT day_of_week, aisle, product_id, total_counts, 
                  @day_aisle_rank := IF(@current_day_aisle = CONCAT(day_of_week, aisle), @day_aisle_rank + 1, 1) AS day_aisle_rank,
                  @current_day_aisle := CONCAT(day_of_week, aisle)
       FROM unranked_data
       ORDER BY day_of_week, aisle, total_counts DESC
     ) ranked
WHERE day_aisle_rank <= 5;

#4 Selecting top 10 products that the users have the most frequent reorder date
SELECT product_id, SUM(reordered)/COUNT(order_id) AS reorder_rate
FROM order_product
GROUP BY product_id
ORDER BY reorder_rate DESC
LIMIT 10;

#5 Business case study -1
#5.1 
CREATE TABLE IF NOT EXISTS shopper_aisle AS (
SELECT 
order_id,
product_id,
add_to_cart_order,
reordered,
aisle_id
FROM order_product
JOIN product ON order_product.product_id = product.id
JOIN aisle ON product.aisle_id = aisle.id
ORDER BY order_id, add_to_cart_order
);

#5.2
CREATE TABLE IF NOT EXISTS shopping_path AS (
SELECT order_id, GROUP_CONCAT(DISTINCT aisle_id ORDER BY add_to_cart_order) AS path
FROM shopper_aisle 
GROUP BY order_id
);

SELECT path,COUNT(*)
FROM shopping_path
GROUP BY path
ORDER BY COUNT(*) DESC
LIMIT 10;
    
#6
CREATE TABLE tmp1 AS 
(select product_a,
product_b,
count(distinct order_id) as buy_cnt_together  
from (
	select a.order_id,
	a.product_id as product_a,
	b.product_id as product_b 
	from order_product AS a join order_product AS b 
	on a.order_id = b.order_id
) c
group by product_a,
product_b);

SELECT product_a, product_b,buy_cnt_together
FROM tmp1
WHERE product_a<product_b
ORDER BY buy_cnt_together DESC;
