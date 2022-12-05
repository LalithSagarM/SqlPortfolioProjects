-- Analysing and finding Insights from 2011 Population Data or Census of Indian States
-- States are equivalant to Provinces and Districts are equivalant to Cities or Regions 

-- In this project, I try to use SQL to find and analyze the data and demonstrate my ability to utilize SQL commands starting from
-- simple data manipulation to use of aggregate Functions, Wildcards, Unions, Joins, Sub-Queries and Window Functions. 

-- Created Database and Imported Data

CREATE DATABASE indiapopulationproject;

USE indiapopulationproject;

SELECT * FROM data1;
SELECT * FROM data2;

-- Simple Data Cleaning

ALTER TABLE data1 CHANGE ï»¿District District VARCHAR(100);

-- Checking number of rows within Data
SELECT count(*) FROM data1;
SELECT count(*) FROM data2;

-- 1. What are the Population for select States? 
-- Filter Population data for only Two States (Kerala and Karnataka) 

SELECT 
    *
FROM
    data2
WHERE
    state IN ('Kerala' , 'Karnataka')
ORDER BY state;
-- -------------------------------------------------------------------------------
-- 2. What is Total Population of India as of 2011

SELECT 
    SUM(population) AS 'Total Population'
FROM
    data2;
-- --------------------------------------------------------------------------------
-- 3. What is the Average Population Growth Since Previous Census Data

SELECT 
    ROUND(AVG(growth), 4) AS 'Avg Growth'
FROM
    data1;
    
-- 3. Insight: The population has been growing at a fast pace, and is forcasted to over take China by 2023
-- -----------------------------------------------------------------------------------    
-- 4. What is Average Population Growth For Each State In India From Largest to Smallest

SELECT 
    state, ROUND(AVG(Growth),3) AS 'Avg Growth'
FROM
    data1
GROUP BY state
ORDER BY Avg(Growth) desc;
-- -------------------------------------------------------------------------------------
-- 5. Which are the Top 5 States with Highest Sex Ratio 

SELECT 
    state, ROUND(AVG(sex_ratio),0) AS Avg_Sex_Ratio
FROM
    data1
GROUP BY state
ORDER BY Avg_Sex_Ratio desc
Limit 5;

-- 5. Insight: 4 out of 5 States with Highest Sex Ratio are from South India with the exception of Uttarakhand
-- Tableau Visualization: 
-- https://public.tableau.com/app/profile/lalith.sagar/viz/sqltovizAnOverviewofFindingsFromCensusDataofIndia2011SQLProjectVisualization/SQLProject
-- ---------------------------------------------------------------------------------------
-- 6. Which States fall Below National Average for Litracy Rate
 -- Using Sub-Query to find states with Literacy Rate below Average Literacy Rate of 72.31
 
SELECT 
    state, ROUND(AVG(literacy), 2) AS state_literacy
FROM
    data1
GROUP BY state
HAVING state_literacy < (SELECT 
        AVG(literacy)
    FROM
        data1)
ORDER BY state_literacy DESC;

select avg(literacy) from data1;

-- --------------------------------------------------------------------------------------------------

-- 7 Which are top 3 and last 3 states based on litracy rates and combining the results using Union Operator
(SELECT 
    state, ROUND(AVG(literacy), 2) AS avg_literacy
FROM
    data1
GROUP BY state
ORDER BY AVG(literacy)
LIMIT 3) UNION (SELECT 
    state, ROUND(AVG(literacy), 2) AS avg_literacy
FROM
    data1
GROUP BY state
ORDER BY AVG(literacy) DESC
LIMIT 3)
;

-- --------------------------------------------------------------------------------------------------------------
-- 8. Listing Population for all States that start with leter A
SELECT 
    State, Population
FROM
    data2
WHERE
    state LIKE 'a%'
GROUP BY state;
-- ---------------------------------------------------------------------------------------------------------------

-- 9. How to find The Total Population during previous Census using the Percentage Growth Column and
-- the Percentage Increase in population since Previous Census (Using basic formulae, Sub-Queries and, Join)

SELECT 
    previous_census_population,
    current_population,
    ROUND(((current_population - previous_census_population) / previous_census_population) * 100,
            2) AS Percentage_Increase
FROM
    (SELECT 
        SUM(ROUND(population / (1 + (growth / 100)), 0)) AS previous_census_population,
            SUM(population) AS current_population
    FROM
        data1 d1
    JOIN data2 d2 ON d1.district = d2.district) d;
-- Insight: The Population of India has increased by 17.74 Percentage from Previous Census or Data Collection
-- ----------------------------------------------------------------------------------------------------------------------

-- 10. What are the Total number of people born Male and Female by States 
-- Found using the Sex Ratio (ratio of females/males) from Table 1 and 
-- Population from Table 2 using Sub-Queries and Inner Join

SELECT 
    d.state,
    SUM(d.males) AS total_males,
    SUM(d.females) AS total_females
FROM
    (SELECT 
        state,
            ROUND(population / (sex_ratio + 1), 0) AS males,
            ROUND((population * sex_ratio) / (sex_ratio + 1), 0) AS females
    FROM
        (SELECT 
        d2.state, d2.population, d1.sex_ratio / 1000 AS sex_ratio
    FROM
        data1 d1
    JOIN data2 d2 ON d1.district = d2.district) a) d
GROUP BY d.state;
-- ----------------------------------------------------------------------------------------------------------

-- How to Rank the top 3 Districts with highest literacy rate for every State 
-- using the RANK() Function
-- Please Note: Some states do not have 3 districts 

select a.* from
(select state,district,literacy,rank() over(partition by state order by literacy desc) as Literacy_Rank from data1)a
where Literacy_Rank < 4;
 
 -- Tableau Visualization: 
--  https://public.tableau.com/app/profile/lalith.sagar/viz/sqltovizAnOverviewofFindingsFromCensusDataofIndia2011SQLProjectVisualization/SQLProject
-- ---------------------------------------------------------------------------------------------------------------
