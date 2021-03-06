--What is the city and state of the store which had the greatest increase in average daily revenue  from November to December?

SELECT sub.store, sub.MonthlyChange, str.city, str.state

FROM

(SELECT
         tr.store,   
         COUNT (DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.saledate END)) nDaysNov,
         COUNT(DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.saledate END)) nDaysDec,

         SUM (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.amt END) as NovRev,
         SUM (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.amt END) as DecRev,
         NovRev/nDaysNov as avgNov,
         DecRev/nDaysDec as avgDec,
         (avgDec -avgNov) as MonthlyChange
FROM trnsact tr
WHERE tr.stype='P' AND NOT(EXTRACT(MONTH FROM tr.saledate)=8 AND EXTRACT(year FROM tr.saledate)=2005)
GROUP BY tr.store
HAVING nDaysDec>=20 AND nDaysNov>=20) as sub

JOIN strinfo as str
ON str.store=sub.store
GROUP BY sub.store, sub.MonthlyChange, str.city, str.state
ORDER BY sub.MonthlyChange DESC;


--Write a query that determines the month in which each store had its maximum number 
--of sku units returned. During which month did the greatest number of stores have t
--heir maximum number of sku units returned

SELECT sub.M, sub.Ranking, COUNT(sub.ranking)

FROM
(SELECT
  store,
  CASE EXTRACT(MONTH FROM saledate)
   WHEN 1 then 'jan'
   WHEN 2 then 'feb'
   WHEN 3 then 'mar'
   WHEN 4 then 'apr'
   WHEN 5 then 'may'
   WHEN 6 then 'jun'
   WHEN 7 then 'jul'
   WHEN 8 then 'aug'
   WHEN 9 then 'sep'
   WHEN 10 then 'oct'
   WHEN 11 then 'nom'
   WHEN 12 then 'dec'
   END as m,
  COUNT(sku) as SkuNumRet,
ROW_NUMBER()OVER (PARTITION BY store ORDER BY store,SkuNumRet desc) as Ranking
FROM trnsact
QUALIFY Ranking <= 2
WHERE stype='R' and not (m='aug' AND EXTRACT(YEAR FROM saledate)=2005)
GROUP BY  store,m) sub

GROUP BY sub.M, sub.Ranking
ORDER BY sub.Ranking asc





--Which department within a particular store had the greatest decrease in average daily sales revenue from 
--August to September, and in what city and state was that store located?

select
         di.deptdesc,sk.dept,tr.store,   

         COUNT (distinct
         (CASE WHEN extract(month FROM tr.saledate)=8 then tr.saledate END)) nDaysAug,
         count(distinct
         (CASE WHEN extract(month FROM tr.saledate)=9 then tr.saledate END)) nDaysSep,

         sum(CASE WHEN extract(month FROM tr.saledate)=8 then tr.amt END) as augRev,
         sum(CASE WHEN extract(month FROM tr.saledate)=9 then tr.amt END) as sepRev,

         (sepRev/nDaysSep - augRev/nDaysAug) as MonthDiff,
         str.city, str.state

FROM trnsact tr 
JOIN strinfo as str ON str.store=tr.store
JOIN skuinfo as sk ON sk.sku=tr.sku
JOIN deptinfo di ON di.dept=sk.dept

WHERE tr.stype='P' AND NOT (extract(month FROM tr.saledate)=8 AND extract(year FROM tr.saledate)=2005)
HAVING nDaysAug>=20 AND nDaysSep>=20 AND AugRev>1000 AND SepRev>1000

GROUP BY sk.dept,tr.store,di.deptdesc, str.city, str.state
ORDER BY MonthDiff asc



--Compare the average daily revenue of the store with the highest msa_income and the store with the lowest median 
--msa_income (according to the msa_income field). In what city and state were these two stores, and which store had 
-- a higher average daily revenue? 

SELECT SUM(rads.tRevenue)/SUM(rads.ndays) as DayAverg,store_msa.msa_income Med_Income, store_msa.state, store_msa.city

FROM 
   (SELECT
    store,
    EXTRACT(month FROM saledate) as m,
    EXTRACT(year FROM saledate) y,
    COUNT(DISTINCT saledate) nDays,
    SUM(amt) tRevenue,
    tRevenue/nDays AVGdailyRev
    FROM trnsact
    WHERE stype='P' AND NOT (m=8 and y=2005)
    GROUP BY  store,m,y
    HAVING ndays>20) as Rads

JOIN store_msa
ON store_msa.store= rads.store

WHERE store_msa.msa_income IN ((SELECT MAX(msa_income) FROM store_msa), (SELECT MIN(msa_income)FROM store_msa))

GROUP BY Med_Income, store_msa.state,store_msa.city





--Divide the msa_income groups up so that msa_incomes between 1 and 20,000 are labeled 'low', msa_incomes 
--between 20,001 and 30,000 are labeled 'med-low', msa_incomes between 30,001 and 40,000 are labeled 'med-
--high', and msa_incomes between 40,001 and 60,000 are labeled 'high'. Which of these groups has the highest 
--average daily revenue per store?

SELECT sa.Incomeg, SUM(rads.nDays)/SUM(rads.tRevenue) as AvgRev

FROM 
(SELECT
  store,
  EXTRACT(MONTH FROM saledate) as m,
  EXTRACT(YEAR FROM saledate) y,
  COUNT(DISTINCT saledate) nDays,
  SUM(AMT) tRevenue,
  tRevenue/nDays AVGdailyRev
  FROM trnsact
  WHERE stype='P' AND NOT (m=8 AND y=2005)
  GROUP BY  store,m,y
  HAVING ndays>20) as Rads

JOIN (SELECT store,msa_income,
     CASE
     WHEN msa_income>1 AND msa_income<=20000     then  'low'
     WHEN msa_income>20000 AND msa_income<=30000 then 'med-low'
     WHEN msa_income>30000 AND msa_income<=40000 then 'med-high'
     WHEN msa_income>40000 AND msa_income<=60000 then 'high'
     END as IncomeG
     FROM store_msa) as sa

ON sa.store= rads.store

GROUP BY sa.incomeg






--Divide stores up so that stores with msa populations between 1 and 100,000 are labeled 'very small', stores 
--with msa populations between 100,001 and 200,000 are labeled 'small', stores with msa populations between 
--200,001 and 500,000 are labeled 'med_small', stores with msa populations between 500,001 and 1,000,000 are 
--labeled 'med_large', stores with msa populations between 1,000,001 and 5,000,000 are labeled “large”, and 
--stores with msa_incomes greater than 5,000,000 are labeled “very large”. What is the average daily revenue for a store in a “very large” population msa?

SELECT sa.popG, SUM(rads.tRevenue)/SUM(rads.nDays) as avgrev
FROM 
   (SELECT
   store,
   EXTRACT(MONTH FROM saledate) as m,
   EXTRACT(YEAR FROM saledate) y,
   COUNT(DISTINCT saledate) nDays,
   SUM(AMT) tRevenue,
   tRevenue/nDays AVGdailyRev,
   CASE WHEN EXTRACT(YEAR FROM saledate) = 2005 AND EXTRACT(MONTH FROM saledate) = 8 THEN 'exclude' END as exclude_flag
   FROM trnsact
   WHERE stype='P' AND exclude_flag IS NULL
   GROUP BY  store,m,y
HAVING ndays>20) as Rads

JOIN (SELECT store,msa_income,
     CASE
     WHEN msa_pop>1 AND msa_pop<=100000     THEN  'very small'
     WHEN msa_pop>100000 AND msa_pop<=200000 THEN 'small'
     WHEN msa_pop>200000 AND msa_pop<=500000 THEN 'med_small'
     WHEN msa_pop>500000 AND msa_pop<=1000000 THEN 'med_large'
     WHEN msa_pop>1000000 AND msa_pop<=5000000 THEN 'large'
     WHEN msa_pop>5000000 THEN 'very large' 
     END as popG
    FROM store_msa) as sa
ON sa.store= rads.store

GROUP BY sa.popG




--Which department in which store had the greatest percent increase in average daily sales revenue from 
--November to December, and what city and state was that store located in? Only examine departments whose 
--total sales were at least $1,000 in both November and December.


SELECT sub.deptdesc, sub.dept, sub.store, sub.PerIncr, str.city, str.state

FROM

(SELECT
         di.deptdesc,sk.dept,tr.store,   

         COUNT (DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.saledate END)) nDaysNov,
         COUNT(DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.saledate END)) nDaysDec,

         SUM(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.amt END) as novRev,
         SUM(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.amt END) as decRev,

         novRev/nDaysNov as avgNov,
         decRev/nDaysDec as avgDec,
         (avgDec - avgNov)/avgNov PerIncr

         FROM trnsact tr
         JOIN skuinfo as sk
         ON sk.sku=tr.sku
         JOIN deptinfo di
         ON di.dept=sk.dept
         WHERE tr.stype='P' AND NOT (EXTRACT(MONTH FROM tr.saledate)=8 AND EXTRACT(YEAR FROM tr.saledate)=2005)
         GROUP BY sk.dept,tr.store,di.deptdesc
         HAVING nDaysNov>=20 AND nDaysDec>=20 AND NovRev>1000 AND DecRev>1000 ) as sub

JOIN strinfo as str
ON str.store=sub.store
GROUP BY sub.deptdesc, sub.dept, sub.store, PerIncr, str.city, str.state
ORDER BY sub.PerIncr DESC





--Which department in which store had the greatest percent increase in average daily sales revenue from November to December, 
--and what city and state was that 
--store located in? Only examine departments whose total sales were at least $1,000 in both November and December.

SELECT
         di.deptdesc,sk.dept,str.store,   
         COUNT (DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.saledate END)) as nDaysNov,
         COUNT(DISTINCT
         (CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.saledate END)) as nDaysDec,

         SUM(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=11 then tr.amt END) as novRev,
         SUM(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=12 then tr.amt END) as decRev,

         novRev/nDaysNov as avgNov,
         decRev/nDaysDec as avgDec,
         (avgDec - avgNov)/avgNov PerIncr,
         str.city, 
         str.state

FROM trnsact tr JOIN strinfo as str
ON str.store=tr.store
JOIN skuinfo as sk
ON sk.sku=tr.sku
JOIN deptinfo di
ON di.dept=sk.dept

WHERE tr.stype='P' AND NOT (EXTRACT(MONTH from tr.saledate)=8 AND EXTRACT(YEAR FROM tr.saledate)=2005)

GROUP BY di.deptdesc, sk.dept, str.store, str.city, str.state 
HAVING nDaysNov>=20 AND nDaysDec>=20 AND NovRev>1000 AND DecRev>1000 
ORDER BY PerIncr DESC




--Identify the department within a particular store that had the greatest decrease innumber of items sold from 
--August to September. How many fewer items did that department sell in September compared to August, and in 
--what city and state was that store located?

SELECT  tr.store,di.deptdesc,str.city, str.state,

         COUNT (DISTINCT(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=8 THEN tr.saledate END)) nDaysAug,
         COUNT (DISTINCT(CASE WHEN EXTRACT(MONTH FROM tr.saledate)=9 THEN tr.saledate END)) nDaysSep,
 
         SUM(CASE WHEN extract(MONTH FROM tr.saledate)=8 then tr.quantity END) as augNsku,
         SUM(CASE WHEN extract(MONTH FROM tr.saledate)=9 then tr.quantity END) as sepNsku,
         (sepNsku- augNsku) as MonthDiff

FROM trnsact tr JOIN strinfo as str ON str.store=tr.store
JOIN skuinfo as sk ON sk.sku=tr.sku
JOIN deptinfo di ON di.dept=sk.dept

WHERE tr.stype='P' AND NOT(extract(month FROM tr.saledate)=8 AND extract(year FROM tr.saledate)=2005)
GROUP BY  tr.store,str.city, str.state,di.deptdesc
HAVING nDaysAug>=20 AND nDaysSep>=20
ORDER BY MonthDiff ASC;



--For each store, determine the month with the minimum average daily revenue. 
--For each of the twelve months of the year, count how many stores' minimum average
--daily revenue was in that month. During which month(s) did over 100 stores have their minimum average daily revenue?

SELECT M, Ranking, COUNT (ranking) Num_Month_Low

FROM
(SELECT
  store,
  CASE EXTRACT(MONTH FROM saledate)
   WHEN 1 THEN 'jan'
   WHEN 2 THEN 'feb'
   WHEN 3 THEN 'mar'
   WHEN 4 THEN 'apr'
   WHEN 5 THEN 'may'
   WHEN 6 THEN 'jun'
   WHEN 7 THEN 'jul'
   WHEN 8 THEN 'aug'
   WHEN 9 THEN 'sep'
   WHEN 10 THEN 'oct'
   WHEN 11 THEN 'nom'
   WHEN 12 THEN 'dec'
   END as m,
  COUNT(DISTINCT saledate) nDays,
  SUM(amt) tRevenue,
  tRevenue/nDays AVGdailyRev,
ROW_NUMBER()OVER (PARTITION BY store ORDER BY store,AVGdailyRev ASC) as Ranking
FROM trnsact
QUALIFY Ranking <= 1
WHERE stype='P' AND NOT (EXTRACT(MONTH FROM saledate)=8 AND EXTRACT(YEAR FROM saledate)=2005)
GROUP BY  store,m
HAVING ndays>=20) SUB

GROUP BY M, Ranking
ORDER BY Num_Month_Low




