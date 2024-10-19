-- 1.What is the total amount each customer spent at the restaurant?

SELECT 
	customer_id,
    SUM(price) AS total_amount 
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2.How many days has each customer visited the restaurant?

SELECT 
	customer_id,
    COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;

-- 3.What was the first item from the menu purchased by each customer?

WITH ranked_food AS
(
SELECT
	customer_id,
    product_name,
    order_date,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk 
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
)
SELECT 
	customer_id,
    product_name 
FROM ranked_food
WHERE rnk<2
GROUP BY customer_id,product_name;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	product_name,
    COUNT(*) AS purchase_count 
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY purchase_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH order_rank AS (
	SELECT 
        s.customer_id, 
        m.product_name, 
        COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rnk	
    FROM sales s
    JOIN menu m 
		ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id, 
    product_name,
    purchase_count
FROM order_rank
WHERE rnk = 1;

-- 6.Which item was purchased first by the customer after they became a member?

WITH member_orders AS (
		SELECT 
			s.customer_id,
			product_name,
			order_date,
            join_date,
			DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rnk 
		FROM sales AS s
		JOIN menu AS m ON s.product_id = m.product_id
		JOIN members AS mem ON s.customer_id = mem.customer_id
		WHERE order_date>=join_date
)
SELECT 
	customer_id,
    product_name 
FROM member_orders
WHERE rnk = 1;

-- 7.Which item was purchased just before the customer became a member?

WITH non_member_orders AS (
		SELECT 
			s.customer_id,
			product_name,
            order_date,
            join_date,
			DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS rnk 
		FROM sales AS s
		JOIN menu AS m	ON s.product_id = m.product_id
		JOIN members AS mem	ON s.customer_id = mem.customer_id
		WHERE order_date<join_date
)
SELECT 
	customer_id,
	product_name 
FROM non_member_orders
WHERE rnk = 1;

-- 8.What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
    COUNT(*) AS total_items,
    SUM(price) AS amount_spent 
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
JOIN members AS mem
	ON mem.customer_id = s.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id
ORDER BY customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
	customer_id,
    SUM(CASE
        WHEN product_name = 'sushi' THEN (price*10)*2
        ELSE price*10
        END) AS points
FROM sales AS s
JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY customer_id;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
		SUM(
        CASE 
			WHEN product_name = 'sushi' THEN price*10*2
            WHEN s.order_date <= DATE_ADD(mem.join_date, INTERVAL 6 DAY) THEN price*10*2
            ELSE price*10
        END
    ) AS points_earned
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE order_date >= join_date AND order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY s.customer_id
ORDER BY customer_id;

-- 1st Bonus Question

SELECT 
	s.customer_id,
    order_date,
    product_name,
    price,
	CASE 
		WHEN order_date >= join_date THEN 'Y'
		WHEN order_date < join_date THEN 'N'
        ELSE 'N'
	END AS member_status
FROM sales AS s
JOIN menu AS m 
ON m.product_id = s.product_id
LEFT JOIN members AS mem
ON mem.customer_id = s.customer_id
ORDER BY customer_id,order_date;


-- 2nd Bonus Questions
WITH cte AS
(SELECT 
	s.customer_id,
    order_date,
    product_name,
    price,
	CASE 
		WHEN order_date >= join_date THEN 'Y'
		WHEN order_date < join_date THEN 'N'
        ELSE 'N'
	END AS member_status
FROM sales AS s
JOIN menu AS m 
ON m.product_id = s.product_id
LEFT JOIN members AS mem
ON mem.customer_id = s.customer_id
ORDER BY customer_id,order_date
)
SELECT 
		*,
		CASE 
			WHEN member_status = 'N' THEN NULL
			ELSE DENSE_RANK() OVER(PARTITION BY customer_id,member_status ORDER BY order_date)
			END AS ranking
from cte;