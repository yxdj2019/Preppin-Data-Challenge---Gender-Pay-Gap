create database paygap;

use paygap;

-- union all tables
DROP TABLE IF EXISTS Table_all;
CREATE TABLE IF NOT EXISTS Table_all AS 
(SELECT * FROM
    2017_to_2018 
UNION ALL SELECT 
    *
FROM
    2018_to_2019 
UNION ALL SELECT 
    *
FROM
    2019_to_2020 
UNION ALL SELECT 
    *
FROM
    2020_to_2021 
UNION ALL SELECT 
    *
FROM
    2021_to_2022);
    
    
-- INSERT YEAR AND REPORT COLUMNS
ALTER TABLE Table_all ADD YEAR INT;
ALTER TABLE Table_all ADD REPORT TEXT;

UPDATE Table_all
SET YEAR=date_format(DueDate, '%Y')-1;

UPDATE Table_all
SET REPORT=CONCAT_WS(' ', YEAR, 'to', YEAR+1);

-- KEEP THE NECESSARY COLUMNS
CREATE TABLE IF NOT EXISTS Table_output
AS
SELECT YEAR, REPORT, EmployerName, CurrentName, EmployerId, DiffMedianHourlyPercent
FROM Table_all;

DROP TABLE Table_all;


-- UPDATE EMPLOYERNAME --USE Non-Aggregate WINDOW FUNCTION -- FIRST_VALUE
CREATE TABLE IF NOT EXISTS PayGap_output
AS
SELECT YEAR, REPORT, EmployerId, FIRST_VALUE(CurrentName) OVER ( Partition by EmployerId  Order by YEAR desc) AS EmployerName, DiffMedianHourlyPercent
FROM Table_output;

DROP TABLE Table_output;

-- ADD PAY_GAP COLUMN
ALTER TABLE PayGap_output ADD PAY_GAP TEXT;

UPDATE PayGap_output 
SET 
    PAY_GAP = 'In this organisation, men\'s and women\'s median hourly pay is equal.'
WHERE
    DiffMedianHourlyPercent = 0;

UPDATE PayGap_output
SET PAY_GAP="In this organisation, women's median hourly pay is X% lower than men's.",
	PAY_GAP=REPLACE(PAY_GAP, 'X', CONVERT(DiffMedianHourlyPercent, CHAR))
WHERE DiffMedianHourlyPercent>0;

UPDATE PayGap_output
SET PAY_GAP="In this organisation, women's median hourly pay is X% higher than men's.",
	PAY_GAP=REPLACE(PAY_GAP, 'X', CONVERT(abs(DiffMedianHourlyPercent), CHAR))
WHERE DiffMedianHourlyPercent<0;