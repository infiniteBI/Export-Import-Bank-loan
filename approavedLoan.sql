
-- Taking a view of the data and see all the columns

select *
from data_gov.approvaldata;

-- Cleaning the data | check the table data type
describe data_gov.approvaldata;

-- changing the date column to date format
alter table data_gov.approvaldata
modify column `Decision Date` date,
modify column `Effective Date` date,
modify column `Expiration Date` date,
modify column `Primary Export Product NAICS/SIC code` DECIMAL(10,0) ;


SET SQL_SAFE_UPDATES = 0;

-- updating Effective Date's to date format
SELECT `Effective Date`
FROM data_gov.approvaldata
WHERE STR_TO_DATE(`Effective Date`, '%m/%d/%Y') IS NULL
  AND `Effective Date` IS NOT NULL;
  
UPDATE data_gov.approvaldata
SET `Effective Date` = '1900-01-01'
WHERE `Effective Date` IN ('N/A', 'TBD', '');

UPDATE data_gov.approvaldata
SET `Effective Date` = STR_TO_DATE(`Effective Date`, '%m/%d/%Y')
WHERE `Effective Date` NOT IN ('1900-01-01');


-- updating Decision Date's to date format
SELECT `Decision Date`
FROM data_gov.approvaldata
WHERE STR_TO_DATE(`Decision Date`, '%Y-%m-%d') IS NULL
  AND `Decision Date` IS NOT NULL;
  
UPDATE data_gov.approvaldata
SET `Decision Date` = '1900-01-01'
WHERE `Decision Date` IN ('N/A', 'TBD', '');

UPDATE data_gov.approvaldata
SET `Decision Date` = STR_TO_DATE(`Effective Date`, '%Y-%m-%d')
WHERE `Decision Date` IS NOT NULL;

-- updating Expiration Date's to date format
SELECT `Expiration Date`
FROM data_gov.approvaldata
WHERE STR_TO_DATE(`Expiration Date`, '%m/%d/%Y') IS NULL
  AND `Expiration Date` IS NOT NULL;
  
UPDATE data_gov.approvaldata
SET `Expiration Date` = '1900-01-01'
WHERE `Expiration Date` IN ('N/A', 'TBD', '');

UPDATE data_gov.approvaldata
SET `Expiration Date` = STR_TO_DATE(`Effective Date`, '%Y-%m-%d')
WHERE `Expiration Date` IS NOT NULL;

-- updating Primary Export Product NAICS/SIC code's to numerical format

UPDATE data_gov.approvaldata
SET `Primary Export Product NAICS/SIC code` = NULL
WHERE `Primary Export Product NAICS/SIC code` REGEXP '[^0-9]';

ALTER TABLE data_gov.approvaldata
MODIFY COLUMN `Primary Export Product NAICS/SIC code` INT;

alter table data_gov.approvaldata
rename column `ï»¿Fiscal Year` to `Fiscal Year`;

UPDATE data_gov.approvaldata
set 
		`Fiscal Year` = trim(`Fiscal Year`),
        `Fiscal Year` = nullif(`Fiscal Year`, 'N/A'),
		`Unique Identifier` = trim(`Unique Identifier`) ,
        `Unique Identifier` = nullif(`Unique Identifier`, 'N/A'),
		`Decision`= trim(`Decision`) ,
		`Decision`= nullif(`Decision`, 'N/A');

SET SQL_SAFE_UPDATES = 1;

/*
 1 - Metric to calculate:  
	  Total authorized amount
	  Total disbursed amount
	  Total outstanding exposure
	  Average loan size
	  Loan count
2 - Year-over-Year growth
3 - Top lenders by exposure share
4 - Risk profile: outstanding vs approved ratio
5 - Loan lifecycle analysis (duration)
6 - Small vs non-small business dependency // Woman owned and minority business dependency
7 - Detect anomalous loans
8 - Decision authority performance matrix
*/

-- Total authorized amount , Total disbursed amount,  Total outstanding exposure,  Average loan size,  Loan count

select `Primary Exporter State Name`, coalesce(`Primary Lender`,`Primary Applicant`) as Lender,
	count(*) as loan_count,
	sum(`Approved/Declined Amount`) as Total_Approved,
    sum(`Disbursed/Shipped Amount`) as Total_disbursed,
    (sum(`Approved/Declined Amount`)- sum(`Disbursed/Shipped Amount`)) as total_difference,
    sum(`Undisbursed Exposure Amount`) as Total_Undisbursed ,
    sum(`Outstanding Exposure Amount`) as Total_Outstanding ,
    sum(`Small Business Authorized Amount`) as Total_Small_Business ,
    sum(`Woman Owned Authorized Amount`) as Total_Woman_Business ,
    sum(`Minority Owned Authorized Amount`) as Total_Minority_Business
from data_gov.approvaldata
where (`Primary Applicant` != 'N/A' or `Primary Lender` != 'N/A') and `Decision` = 'Approved'
group by `Primary Exporter State Name`, Lender
order by Total_Approved desc
;

select `decision`,`term` ,`program`,  sum(`Approved/Declined Amount`) as Total_Approved
from data_gov.approvaldata
group by `decision`,`term`,`program`
order by `decision`,`term` ;


select `Decision Authority`,`Primary Applicant`,`Primary Lender`
from data_gov.approvaldata
-- where `program`= 'Insurance'
group by `Decision Authority`,`Primary Applicant`,`Primary Lender`;



select `Decision Authority`, count(*) as loan_count,
	sum(`Approved/Declined Amount`) as Total_Approved,
    sum(`Disbursed/Shipped Amount`) as Total_disbursed,
    (sum(`Approved/Declined Amount`)- sum(`Disbursed/Shipped Amount`)) as total_difference,
    sum(`Undisbursed Exposure Amount`) as Total_Undisbursed ,
    sum(`Outstanding Exposure Amount`) as Total_Outstanding ,
    sum(`Small Business Authorized Amount`) as Total_Small_Business ,
    sum(`Woman Owned Authorized Amount`) as Total_Woman_Business ,
    sum(`Minority Owned Authorized Amount`) as Total_Minority_Business
from data_gov.approvaldata
where (`Primary Applicant` != 'N/A' or `Primary Lender` != 'N/A') and `Decision` = 'Approved'
group by `Decision Authority`;


-- 2 - Year-over-Year growth

with yearly as (
    select
        `Fiscal Year`,
        sum(`Approved/Declined Amount`) as Total_Approved
    from data_gov.approvaldata
    group by `Fiscal Year`
)
select
    `Fiscal Year`,
    total_approved,
    total_approved  - lag(total_approved) over (order by `Fiscal Year`) AS year_change,
    ROUND(
        100 * (
            total_approved
            - lag(total_approved) over (order by `Fiscal Year`)
        )
        / NULLIF(LAG(total_approved) over (order by `Fiscal Year`), 0),
        2
    ) AS year_growth_pct
from yearly
order by `Fiscal Year`;

-- 3 - Top lenders by exposure share

select
     coalesce(`Primary Lender`, `Primary Applicant`) as lender,
    sum(`Approved/Declined Amount`) as Total_Approved,
    ROUND(
        100 * sum(`Approved/Declined Amount`)
        / SUM(sum(`Approved/Declined Amount`)) over (),
        2
    ) AS market_share_pct
from data_gov.approvaldata
group by lender
order by total_approved DESC;

-- 4 - Risk profile: outstanding vs approved ratio
select
    `Primary Exporter State Name` AS state,
    sum(`Outstanding Exposure Amount`) as Total_Outstanding,
    sum(`Approved/Declined Amount`) as Total_Approved,
    ROUND(
        sum(`Outstanding Exposure Amount`) / NULLIF(sum(`Approved/Declined Amount`), 0),
        3
    ) AS outstanding_ratio
from data_gov.approvaldata
group by state
order by outstanding_ratio desc;

-- 5 - Loan lifecycle analysis (duration)
select
    `Program`,
    count(*) AS loan_count,
    round(AVG(DATEDIFF(`Expiration Date`, `Effective Date`)), 0) AS avg_loan_days,
    round(MIN(DATEDIFF(`Expiration Date`, `Effective Date`)), 0) AS min_loan_days,
    round(MAX(DATEDIFF(`Expiration Date`, `Effective Date`)), 0) AS max_loan_days
FROM data_gov.approvaldata
WHERE `Effective Date` IS NOT NULL
  AND `Expiration Date` IS NOT NULL
GROUP BY `Program`
ORDER BY avg_loan_days DESC;


-- 6 - Small vs non-small business dependency // Woman owned and minority business dependency

select
    `Fiscal Year`,
    sum(`Approved/Declined Amount`) as Total_Approved,
    sum(`Small Business Authorized Amount`) as Total_Small_Business,
    round(
        sum(`Small Business Authorized Amount`)
        / NULLIF(sum(`Approved/Declined Amount`), 0),
        2
    ) AS small_business_ratio,
    sum(`Woman Owned Authorized Amount`) as Total_Woman_Business,
    round(
        sum(`Woman Owned Authorized Amount`)
        / NULLIF(sum(`Approved/Declined Amount`), 0),
        2
    ) AS Woman_business_ratio,
    sum(`Minority Owned Authorized Amount`) as Total_Minority_Business,
    round(
        sum(`Minority Owned Authorized Amount`)
        / NULLIF(sum(`Approved/Declined Amount`), 0),
        2
    ) AS Minority_business_ratio
from data_gov.approvaldata
group by `Fiscal Year`
order by `Fiscal Year`;

-- 7 - Detect anomalous loans
select *
from (
    select
        coalesce(`Primary Lender`, `Primary Applicant`) as lender,
        `Approved/Declined Amount` as approved_amt,
        AVG(`Approved/Declined Amount`) OVER (PARTITION BY coalesce(`Primary Lender`, `Primary Applicant`)) AS avg_lender_amt,
        `Approved/Declined Amount`
          / NULLIF(AVG(`Approved/Declined Amount`) OVER (PARTITION BY `Primary Lender`), 0) AS size_vs_avg
    from data_gov.approvaldata
) t
where size_vs_avg > 5 and lender != 'N/A'
order by size_vs_avg desc;

-- 8 - Decision authority performance matrix
select
    `Decision Authority`,
    `Program`,
    COUNT(*) AS loan_count,
    SUM(`Approved/Declined Amount`) AS total_approved,
    ROUND(AVG(`Approved/Declined Amount`), 2) AS avg_loan_size
from data_gov.approvaldata
group by `Decision Authority`, `Program`
order by total_approved desc;
