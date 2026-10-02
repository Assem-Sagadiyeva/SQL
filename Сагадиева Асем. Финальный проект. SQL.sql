-- Загрузка БД и подготовка данных:
CREATE DATABASE Customer_tansactions;
SET SQL_SAFE_UPDATES = 0;
UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY Age INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL (10,3),
Sum_payment DECIMAL (10,3));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Transactions_final.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM transactions;
SET SQL_SAFE_UPDATES = 1;

# Задача 1: Вывести:
-- список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период:
SELECT ID_client, COUNT(DISTINCT MONTH(date_new)) AS active_months
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING active_months = 12;

-- средний чек за период с 01.06.2015 по 01.06.2016:
SELECT ID_client,
	COUNT(DISTINCT MONTH(date_new)) AS active_months, 
    AVG (Sum_payment) AS avg_bill
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING active_months = 12;

-- средняя сумма покупок за месяц:
SELECT ID_client,
	COUNT(DISTINCT MONTH(date_new)) AS active_months, 
    AVG (Sum_payment) AS avg_bill,
    SUM(Sum_payment) / 12 AS avg_monthly_purchase_amount
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING active_months = 12;

-- количество всех операций по клиенту за период;
SELECT ID_client,
	COUNT(DISTINCT MONTH(date_new)) AS active_months, 
    AVG (Sum_payment) AS avg_bill,
    SUM(Sum_payment) / 12 AS avg_monthly_purchase_amount,
    COUNT(Id_check) AS total_transactions
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING active_months = 12;

# Задача 2. Вывести:
-- a) средняя сумма чека в месяц:
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
    AVG (Sum_payment) AS avg_bill
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY transaction_month;

-- b) среднее количество операций в месяц:
SELECT 
	transaction_month,
    AVG(monthly_operations) AS avg_monthly_operations
FROM (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
        COUNT(Id_check) AS monthly_operations
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY transaction_month
   ) AS monthly_counts
 GROUP BY transaction_month;

-- c) среднее количество клиентов, которые совершали операции:
SELECT 
	transaction_month,
    AVG(active_clients) AS avg_active_clients
FROM (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
        COUNT(DISTINCT ID_client) AS active_clients
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY transaction_month
   ) AS monthly_counts
 GROUP BY transaction_month;
 
-- d) долю от общего количества операций за год и долю в месяц от общей суммы операций:
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
    COUNT(Id_check) / SUM(COUNT(Id_check)) OVER() * 100 AS operations_share_year,
    SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER() * 100 AS sum_share_year
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY transaction_month;
 
 -- e) вывести % соотношение M/F/NA в каждом месяце с их долей затрат:
 
SELECT t.date_new, t.Sum_payment, c.gender -- объединила 2 таблицы: покупки с полом
FROM transactions t
LEFT JOIN customers c
ON t.ID_client = c.ID_client;

SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS transaction_month, -- это у меня месяцы
    COALESCE(c.Gender, 'NA') AS gender, -- если в поле будет NULL значение, то функция заменит ее на значение "NA".
    COUNT(t.Id_check) AS monthly_operations, -- кол-во операции в месяц
    SUM(t.Sum_payment) AS monthly_sum -- сумма выручки
FROM transactions t
LEFT JOIN customers c
ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY transaction_month, gender
ORDER BY transaction_month, gender;

SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS transaction_month,
    COALESCE(c.Gender, 'NA') AS gender,
    COUNT(t.Id_check) / SUM(COUNT(t.Id_check)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 AS operations_share_month, -- Доля операций за месяц (%)
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 AS spend_share_month -- Доля выручки за месяц (%)
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY transaction_month, gender
ORDER BY transaction_month, gender;

# Задача 3. Вывести:
-- возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации,
-- с параметрами сумма и количество операций за весь период,
SELECT 
    CASE 
	    WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS age_group,
	COUNT(t.Id_check) AS total_operations, -- кол-во операции за весь период
	SUM(t.Sum_payment) AS total_sum -- сумма за весь период   
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client -- объединила 2 таблицы: покупки с полом
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY age_group
ORDER BY age_group;

-- и поквартально - средние показатели и %.
SELECT 
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
    CASE 
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS age_group,
    
    COUNT(t.Id_check) AS total_operations,
    SUM(t.Sum_payment) AS total_sum,
    AVG(t.Sum_payment) AS avg_bill,
    
    COUNT(t.Id_check) / SUM(COUNT(t.Id_check)) OVER(PARTITION BY CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new))) * 100 AS operations_share_pct,
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new))) * 100 AS sum_share_pct

FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY quarter, age_group
ORDER BY quarter, age_group;
