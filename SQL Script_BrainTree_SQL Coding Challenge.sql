-- PAYPAL'S BRAINTREE SQL CODING CHALLENGE

-- Let's begin by creating a schema for the tables that would be imported
CREATE SCHEMA braintree_sql_coding_challenge;

-- The next step will be to set the new schema created as default, so all tables created for this project would be situated in this database.
USE braintree_sql_coding_challenge;

-- Having set the new schema as default, i will proceed to create the structure of the tables expected to be in this schema and import the data for each table accordingly.

-- The Continent Map Table Creation
DROP TABLE IF EXISTS continent_map; -- This would delete the continent map table if it already existed in the schema.

CREATE TABLE continent_map (
country_code TEXT,
continent_code VARCHAR(100)
);

-- The Continents Table Creation
DROP TABLE IF EXISTS continents;

CREATE TABLE continents (
continent_code TEXT,
continent_name VARCHAR(100)
);

-- The Countries Table Creation
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
country_code TEXT,
country_name TEXT
);

-- The Per Capita Table Creation
DROP TABLE IF EXISTS per_capita;

CREATE TABLE per_capita (
	country_code TEXT,
    year INT,
    gdp_per_capita DECIMAL(20, 10)
);

-- The structures of all the tables expected to be in the schema have been created; I will therefore proceed to importing the data for each table.

-- Data Importation for Continent Map Table
LOAD DATA INFILE "C:/Program Files/MySQL/Data_Set/Paypal_BrainTree_Coding Challenge/continent_map.csv" INTO TABLE continent_map
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Data Importation for Continents Table
LOAD DATA INFILE "C:/Program Files/MySQL/Data_Set/Paypal_BrainTree_Coding Challenge/continents.csv" INTO TABLE continents
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Data Importation for Countries Table
LOAD DATA INFILE "C:/Program Files/MySQL/Data_Set/Paypal_BrainTree_Coding Challenge/countries.csv" INTO TABLE countries
FIELDS TERMINATED BY '|' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Data Importation for Per Capita Table
LOAD DATA INFILE "C:/Program Files/MySQL/Data_Set/Paypal_BrainTree_Coding Challenge/per_capita.csv" INTO TABLE per_capita
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Moving forward, let's preview all the tables+data in our database

-- Previewing the Continent Map Table
SELECT * FROM continent_map;

-- Previewing the Continents Table
SELECT * FROM continents;

-- Previewing the Countries Table
SELECT * FROM countries;

-- Previewing the Per Capita Table
SELECT * FROM per_capita;

-- Data Integrity and Cleanup Exercise

-- Data Cleaning - Task 1:
/* 
- Alphabetically list all of the country codes in the continent_map table that appear more than once. 
- Display any values where country_code is null as country_code = "FOO" and 
  make this row appear first in the list, even though it should alphabetically sort to the middle.
*/

-- Updating country codes with Null Values to 'FOO'
UPDATE continent_map
	SET country_code = 'FOO'
    WHERE country_code = "";
	
-- Listing all the country codes that appeared more than once
WITH temp_table AS -- Creating a temp table to introduce a sorting technique in which 'FOO' will appear first in the list. 
(SELECT country_code,
	CASE
		WHEN country_code = 'FOO' THEN 0
        ELSE 1
        END AS sorting_technique -- The Case statement is used to make the country code 'FOO' appear first in the list.
FROM continent_map
GROUP BY country_code
HAVING COUNT(country_code) > 1)
SELECT country_code 
FROM temp_table
ORDER BY sorting_technique ASC, country_code ASC;

-- Data Cleaning - Task 2:
/*
- For all countries that have multiple rows in the continent_map table, delete all multiple records leaving only the 1 record per country. 
- The record that you keep should be the first one when sorted by the continent_code alphabetically ascending. 
*/

SET @@autocommit = 0; -- The autocommit (storing definitions and manipulations to the database automatically) is turned off with this line.
-- The need to turn off autocommit is due wanting to delete the rows from the data and autocommiting these changes wrongly would have an adverse effect on the schema.

START TRANSACTION;

-- I will begin this task by creating a view with my last query
CREATE VIEW duplicated_countries AS
WITH temp_table AS -- Creating a temp table to introduce a sorting technique in which 'FOO' will appear first in the list. 
(SELECT country_code,
	CASE
		WHEN country_code = 'FOO' THEN 0
        ELSE 1
        END AS sorting_technique -- The Case statement is used to make the country code 'FOO' appear first in the list.
FROM continent_map
GROUP BY country_code
HAVING COUNT(country_code) > 1)
SELECT country_code 
FROM temp_table
ORDER BY sorting_technique ASC, country_code ASC;

-- The next step is to retrieve a table of all country code and their respective continent_code
CREATE VIEW duplicated_countries_continent_code AS
SELECT c.country_code,
	c.continent_code
FROM continent_map c
JOIN duplicated_countries d ON c.country_code = d.country_code
GROUP BY country_code
ORDER BY country_code;

-- Our final step would be to remove all duplicated rows with the view created.
DELETE continent_map
FROM continent_map
JOIN duplicated_countries_continent_code dc ON continent_map.country_code = dc.country_code
WHERE continent_map.country_code = dc.country_code AND continent_map.continent_code <> dc.continent_code;

-- The result from the previous query worked quite alright but the country_code 'FOO' have 3 rows with the same continent codes. Two out of these rows need to be removed before moving forward.
-- Since, all the FOO rows have the same values in multiple column, a new column will be crated to include unqiue values using the auto-increment function.

-- Adding the Auto Increment Column
ALTER TABLE continent_map
	ADD COLUMN id INT PRIMARY KEY AUTO_INCREMENT;

-- Now we have unique values for the duplicated rows and can easily delete the unwanted rows.
SELECT * FROM continent_map
WHERE country_code = '';

-- Deleting the unwanted rows
DELETE FROM continent_map
WHERE id IN (173, 174);

-- We can now commit all the transactions to effect the changes in our database
COMMIT;

-- Let's preview the Continent Map to confirm our changes
SELECT * FROM continent_map; -- The result confirms that all duplicated rows have been removed.

-- The Last step in our data cleaning task is to drop the auto-increment column created.
ALTER TABLE continent_map
	DROP COLUMN id;
    
COMMIT; -- Committing the transaction to our schema.

-- Let's set auto-commit back to normal
SET @@autocommit = 1;

-- Exploratory Data Analysis Tasks

-- EDA - TASK 1:
-- List the countries ranked 10-12 in each continent by the percent of year-over-year growth descending from 2011 to 2012

-- The initial step to be taken in solving this task is to create views to store records of gdp_per_capital individually for 2011 and 2012
-- Creating view for 2012 records
DROP VIEW IF EXISTS gdp_2012;

CREATE VIEW gdp_2012 AS
SELECT country_code,
	ROUND(gdp_per_capita, 2) total_gdp
FROM per_capita
WHERE year = 2012;

SELECT * FROM gdp_2012;

-- Creating view for 2011 records
DROP VIEW IF EXISTS gdp_2011;

CREATE VIEW gdp_2011 AS
SELECT country_code,
	ROUND(gdp_per_capita, 2) total_gdp
FROM per_capita
WHERE year = 2011;

SELECT * FROM gdp_2011;

-- 
SELECT c.continent_name continent_name,
	co.country_code country_code,
    co.country_name country_name,
    CONCAT(ROUND((((g.total_gdp - gd.total_gdp) / gd.total_gdp) * 100),2), '%') growth_percent
FROM countries co 
JOIN gdp_2012 g ON co.country_code = g.country_code
JOIN gdp_2011 gd ON g.country_code = gd.country_code
JOIN continent_map cm ON gd.country_code = cm.country_code
LEFT OUTER JOIN continents c ON cm.continent_code = c.continent_code;

-- The result printed null for the continent name column and this occured because there is a whitespace in all the rows under the continent code column in the continent map table.
-- The next step would be to remove the whitespaces in all rows under the continent code column.

UPDATE continent_map
	SET continent_code = REPLACE(continent_code, '\r', '');
    
-- Now, let's try again.
WITH temp_table AS
	(SELECT c.continent_name continent_name,
		co.country_code country_code,
		co.country_name country_name,
		CONCAT(ROUND((((g.total_gdp - gd.total_gdp) / gd.total_gdp) * 100), 2), '%') growth_percent
	FROM countries co 
	JOIN gdp_2012 g ON co.country_code = g.country_code
	JOIN gdp_2011 gd ON g.country_code = gd.country_code
	JOIN continent_map cm ON gd.country_code = cm.country_code
	LEFT OUTER JOIN continents c ON cm.continent_code = c.continent_code)
SELECT ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY growth_percent DESC) rank_num,
	continent_name,
    country_code,
    country_name,
    growth_percent
FROM temp_table;

-- In order to retrieve the countries ranked 10-12 in each continent, I will proceed to create the previous query as a view and retrieve the requested data accordingly.
DROP VIEW IF EXISTS gdp_2011_2012_table;

CREATE VIEW gdp_2011_2012_table AS
WITH temp_table AS
	(SELECT c.continent_name continent_name,
		co.country_code country_code,
		co.country_name country_name,
	CONCAT(ROUND((((g.total_gdp - gd.total_gdp) / gd.total_gdp) * 100), 2), '%') growth_percent
	FROM countries co 
	JOIN gdp_2012 g ON co.country_code = g.country_code
	JOIN gdp_2011 gd ON g.country_code = gd.country_code
	JOIN continent_map cm ON gd.country_code = cm.country_code
	LEFT OUTER JOIN continents c ON cm.continent_code = c.continent_code)
SELECT ROW_NUMBER() OVER (PARTITION BY continent_name ORDER BY growth_percent DESC) rank_num,
	continent_name,
    country_code,
    country_name,
    growth_percent
FROM temp_table;

-- Let's retrieve the data requested.
SELECT rank_num,
	continent_name,
    country_code,
    country_name,
    growth_percent
FROM gdp_2011_2012_table
WHERE rank_num BETWEEN 10 AND 12;

-- EDA - TASK 2:
-- For the year 2012, create a 3 column, 1 row report showing the percent share of gdp_per_capita for the following regions
 
 -- Creating a view to store the records for GDP in 2012.
 CREATE VIEW gdp_summation_2012 AS
 SELECT p.country_code,
	cm.continent_code,
    p.gdp_per_capita
    FROM per_capita p
    JOIN continent_map cm ON p.country_code = cm.country_code
    WHERE p.year = 2012;
 
 
 -- Let's retrieve the requested data
 SELECT 
	CONCAT(ROUND(
		((SELECT SUM(gdp_per_capita) FROM gdp_summation_2012 WHERE continent_code = 'AS') / 
        (SELECT SUM(gdp_per_capita) FROM gdp_summation_2012) * 100), 2), '%') Asia,
            
	CONCAT(ROUND(
		((SELECT SUM(gdp_per_capita) FROM gdp_summation_2012 WHERE continent_code = 'EU') / 
        (SELECT SUM(gdp_per_capita) FROM gdp_summation_2012) * 100), 2), '%') Europe,
             
	CONCAT(ROUND(
		((SELECT SUM(gdp_per_capita) FROM gdp_summation_2012 WHERE continent_code NOT IN ('AS', 'EU')) / 
        (SELECT SUM(gdp_per_capita) FROM gdp_summation_2012) * 100), 2), '%') Rest_of_the_world;
            
-- EDA - TASK 3:
-- What is the count of countries and sum of their related gdp_per_capita values for the year 2007 where the string 'an' (case insensitive) appears anywhere in the country name?

SELECT COUNT(co.country_name) country_name,
	CONCAT('$',ROUND(SUM(p.gdp_per_capita),2)) total_gdp
FROM countries co
JOIN per_capita p ON co.country_code = p.country_code
WHERE p.year = 2007 AND co.country_name LIKE '%an%';

-- EDA - TASK 4:
-- Repeat question 4a, but this time make the query case sensitive

SELECT COUNT(co.country_name) country_name,
	CONCAT('$',ROUND(SUM(p.gdp_per_capita),2)) total_gdp
FROM countries co
JOIN per_capita p ON co.country_code = p.country_code
WHERE p.year = 2007 AND co.country_name LIKE BINARY '%an%';

-- EDA - TASK 5:
-- Find the sum of gpd_per_capita by year and the count of countries for each year that have non-null gdp_per_capita where 
-- (i) the year is before 2012 and 
-- (ii) the country has a null gdp_per_capita in 2012

WITH temp_table AS
(SELECT country_code,
	gdp_per_capita
FROM per_capita
WHERE year = 2012 AND gdp_per_capita = "")
SELECT p.year,
	COUNT(t.country_code) country_count,
    CONCAT('$', ROUND(SUM(p.gdp_per_capita), 2)) total_gdp
FROM per_capita p
JOIN temp_table t ON p.country_code = t.country_code
WHERE year < 2012 AND p.gdp_per_capita <> ""
GROUP BY year
ORDER BY year ASC;

-- EDA TASK 6:
-- (i) create a single list of all per_capita records for year 2009
-- (ii) continent_name ascending, characters 2 through 4 (inclusive) of the country_name descending
-- (iii) create a running total of gdp_per_capita by continent_name
-- (iv) return only the first record from the ordered list for which each continent's running total of gdp_per_capita meets or exceeds $70,000.00 

WITH temp_table AS
(SELECT c.continent_name continent_name,
	co.country_code country_code,
    co.country_name country_name,
    p.gdp_per_capita total_gdp,
    SUM(p.gdp_per_capita) OVER (PARTITION BY continent_name ORDER BY SUBSTRING(country_name, 2, 3) DESC) gdp_running_total -- This answered question (iii)
FROM per_capita p
JOIN countries co ON p.country_code = co.country_code
JOIN continent_map cm ON co.country_code = cm.country_code
LEFT OUTER JOIN continents c ON cm.continent_code = c.continent_code
WHERE year = 2009 -- This filter answered question (i)
ORDER BY continent_name ASC, SUBSTRING(country_name, 2, 3) DESC) -- The ORDER BY arrangement here answered question (ii)
SELECT 
	FIRST_VALUE(continent_name) OVER (PARTITION BY continent_name ORDER BY gdp_running_total)continent_name,
	FIRST_VALUE(country_code) OVER (PARTITION BY continent_name ORDER BY gdp_running_total) country_code,
    FIRST_VALUE(country_name) OVER (PARTITION BY continent_name ORDER BY gdp_running_total) country_name,
    CONCAT('$', ROUND(FIRST_VALUE(gdp_running_total) OVER (PARTITION BY continent_name ORDER BY gdp_running_total), 2)) gdp_running_total
FROM temp_table
WHERE gdp_running_total >= 70000
GROUP BY continent_name;

-- EDA - TASK 7:
-- Find the country with the highest average gdp_per_capita for each continent for all years
SELECT
	MIN(ranking) ranking,
    continent_name,
    country_code,
    country_name,
    CONCAT('$', ROUND(avg_gdp_per_capita, 2)) avg_gdp_per_capital
FROM
	(SELECT 
		ROW_NUMBER() OVER (PARTITION BY c.continent_name ORDER BY p.gdp_per_capita DESC) ranking,
		c.continent_name continent_name,
		co.country_code country_code,
		co.country_name country_name,
		SUM(p.gdp_per_capita) gdp_per_capita,
		COUNT(p.year) no_of_years,
		(SUM(p.gdp_per_capita) / COUNT(p.year)) avg_gdp_per_capita
	FROM per_capita p
	JOIN countries co ON p.country_code = co.country_code
	JOIN continent_map cm ON co.country_code = cm.country_code
	LEFT OUTER JOIN continents c ON cm.continent_code = c.continent_code
	GROUP BY country_name) temp_table
    GROUP BY continent_name;
    
    -- THE END 
    -- THANK YOU
    