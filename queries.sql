-- Creation of the tables
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');






-- Question 1
-- Total amount spent by each customer
SELECT sales.customer_id customer, SUM(menu.price) total_amount
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Question 2
-- Number of days each customer visited the restaurant
SELECT customer_id customer, COUNT(DISTINCT order_date) num_of_days
FROM sales
GROUP BY customer_id;

-- Question 3
-- First item from the menu purchased by each customer
SELECT DISTINCT ON (sa.customer_id) sa.customer_id customer, me.product_name
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
GROUP BY sa.customer_id, sa.order_date, me.product_id, me.product_name
ORDER BY sa.customer_id, sa.order_date;

-- Question 4
-- Most purchased item on the menu
SELECT me.product_name, COUNT(sa.product_id) qty_sold
FROM menu me
JOIN sales sa
ON me.product_id = sa.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Question 5
-- Most popular item for each customer
SELECT DISTINCT ON (sa.customer_id) sa.customer_id customer, me.product_name, COUNT(sa.product_id) qty_sold
FROM menu me
JOIN sales sa
ON me.product_id = sa.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC
LIMIT 3;

-- Still on Question 5. This query shows that Customer B bought the same quantity of each item.
-- Total quantity of each item purchased by customer B
SELECT sa.customer_id customer, me.product_name, COUNT(sa.product_id) qty_sold
FROM menu me
JOIN sales sa
ON me.product_id = sa.product_id
WHERE sa.customer_id = 'B'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Question 6
-- First item purchased by a customer after becoming a member
SELECT DISTINCT ON (sa.customer_id) sa.customer_id, me.product_name
FROM menu me
JOIN sales sa
ON me.product_id = sa.product_id
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE sa.order_date >= mem.join_date
ORDER BY sa.customer_id, sa.order_date;

-- Question 7
-- The item purchased by a customer just before becoming a member
SELECT DISTINCT ON (customer_id) customer_id, product_name, order_date
FROM(
    SELECT sa.customer_id customer_id, me.product_name product_name, sa.order_date order_date
    FROM menu me
    JOIN sales sa
    ON me.product_id = sa.product_id
    JOIN members mem
    ON sa.customer_id = mem.customer_id
    WHERE sa.order_date < mem.join_date
    GROUP BY sa.customer_id, me.product_name, sa.order_date
    ORDER BY sa.customer_id, sa.order_date DESC
) prior_membership_orders
ORDER BY customer_id;

-- Question 8
-- Total items and amount spent by each customer before becoming a member
SELECT sa.customer_id customer_id, COUNT(sa.product_id) total_items,
        SUM(me.price) total_amount
FROM menu me
JOIN sales sa
ON me.product_id = sa.product_id
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE sa.order_date < mem.join_date
GROUP BY 1;

-- Question 9
-- Total points earned by customers if each $1 spent equates to 10 points and
--sushi has a 2x points multiplier
SELECT s.customer_id customer,
SUM(
    CASE
        WHEN me.product_name = 'sushi' THEN (me.price * 10) * 2
        ELSE me.price * 10
    END
) points
FROM sales s
JOIN menu me
ON s.product_id = me.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Question 10
-- Points earned by customer in January
SELECT s.customer_id customer,
SUM(
    CASE
        WHEN s.order_date BETWEEN mem.join_date AND (mem.join_date + 6)
        THEN (me.price * 20)
        WHEN me.product_name = 'sushi' THEN (me.price * 20)
        ELSE me.price * 10
    END
) points
FROM sales s
JOIN members mem
ON s.customer_id = mem.customer_id
JOIN menu me
ON s.product_id = me.product_id
WHERE s.order_date >= '2021-01-01' AND s.order_date < '2021-02-01'
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Bonus Questions

-- Question 1
-- Joined tables
SELECT s.customer_id, s.order_date, me.product_name, me.price,
    CASE
        WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales s
LEFT JOIN menu me
ON s.product_id = me.product_id
LEFT JOIN members mem
ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date, me.product_name;

-- Question 2
-- Ranked table
WITH joined AS (
    SELECT s.customer_id, s.order_date, me.product_name, me.price,
        CASE
            WHEN s.order_date >= mem.join_date THEN 'Y'
            ELSE 'N'
        END AS member
    FROM sales s
    LEFT JOIN menu me
    ON s.product_id = me.product_id
    LEFT JOIN members mem
    ON s.customer_id = mem.customer_id
    ORDER BY s.customer_id, s.order_date, me.product_name
)

SELECT customer_id, order_date, product_name, price, member,
    CASE
        WHEN member = 'Y' THEN RANK() OVER(
                                             PARTITION BY customer_id, member
                                            ORDER BY order_date)
    END AS ranking
FROM joined
ORDER BY customer_id;