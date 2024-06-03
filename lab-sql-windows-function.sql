-- PART 1

USE sakila;

-- Rank films by their length and create an output table that includes the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.

SELECT
    title,
    length,
    RANK() OVER (ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL AND length > 0;

-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. 
-- Filter out any rows with null or zero values in the length column.

SELECT
    title,
    length,
    rating,
    RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL AND length > 0;


-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. 
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH actor_on_film AS (
    SELECT
        fa.actor_id,
        a.first_name,
        a.last_name,
        COUNT(*) AS film_count
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY fa.actor_id, a.first_name, a.last_name),
greatest_actor AS (
    SELECT
        film_id,
        actor_id,
        DENSE_RANK() OVER (PARTITION BY film_id ORDER BY film_count DESC) AS 'rank'
    FROM film_actor fa
    JOIN actor_on_film aof ON fa.actor_id = aof.actor_id)
SELECT
    f.title,
    a.first_name,
    a.last_name,
    aof.film_count
FROM film f
JOIN greatest_actor ga ON f.film_id = ga.film_id
JOIN actor a ON ga.actor_id = a.actor_id
JOIN actor_on_film aof ON a.actor_id = aof.actor_id
WHERE ga.rank = 1;

-- PART 2

-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

WITH MonthlyActiveCustomers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m'))
SELECT
    month,
    active_customers
FROM MonthlyActiveCustomers;

-- Step 2. Retrieve the number of active users in the previous month.

WITH MonthlyActiveCustomers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM
        rental
    GROUP BY
        DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT
    month,
    LAG(active_customers, 1) OVER (ORDER BY month) AS prev_month_active_customers
FROM
    MonthlyActiveCustomers;

-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.

WITH MonthlyActiveCustomers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM
        rental
    GROUP BY
        DATE_FORMAT(rental_date, '%Y-%m')
),
MonthlyWithPrev AS (
    SELECT
        month,
        active_customers,
        LAG(active_customers, 1) OVER (ORDER BY month) AS prev_month_active_customers
    FROM
        MonthlyActiveCustomers
)
SELECT
    month,
    active_customers,
    prev_month_active_customers,
    ((active_customers - prev_month_active_customers) / prev_month_active_customers) * 100 AS pct_change
FROM
    MonthlyWithPrev
WHERE
    prev_month_active_customers IS NOT NULL;

-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH CustomerRentals AS (
    SELECT
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m') AS month
    FROM
        rental
    GROUP BY
        customer_id, DATE_FORMAT(rental_date, '%Y-%m')
),
MonthlyActiveCustomers AS (
    SELECT
        month,
        customer_id
    FROM
        CustomerRentals
),
CurrentAndPrevMonth AS (
    SELECT
        cur.month AS current_month,
        cur.customer_id AS current_customer,
        prev.customer_id AS prev_customer
    FROM
        MonthlyActiveCustomers cur
    JOIN
        MonthlyActiveCustomers prev ON cur.customer_id = prev.customer_id
    WHERE
        DATE_SUB(cur.month, INTERVAL 1 MONTH) = prev.month
)
SELECT
    current_month,
    COUNT(DISTINCT current_customer) AS retained_customers
FROM
    CurrentAndPrevMonth
GROUP BY
    current_month;
    
    -- No customers retained??