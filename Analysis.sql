use inclass;
show tables;
select * from bank_account_transaction;
select * from bank_account_details;
select * from bank_account_relationship_details;
select * from bank_customer;
select * from bank_customer_export;
select * from bank_customer_messages;
select * from bank_holidays;
select * from bank_interest_rate;

-- Q1 Print credit card transactions with sum of transaction_amount on all Fridays and
   -- sum of transaction_amount on all other days --
   --------- SUB_QUERY -----------
select abs(sum(if(dayname(transaction_date)="friday",transaction_amount,0)))FRIDAY,
abs(sum(if(dayname(transaction_date)!="friday",transaction_amount,0)))NON_FRIDAYS
FROM  bank_account_transaction 
where account_number in 
(select account_number from bank_account_details where account_type like "%credit_card%"); -- using sub_query--
----- WITH_CLAUSE ---------
with trans as 
(select T2.* from
(select account_number from bank_account_details where account_type like"%credit_card%") as T1,
bank_account_transaction as T2
where T1.account_number=T2.account_number)
select abs(sum(if(dayname(transaction_date)="friday",transaction_amount,0)))FRIDAY,
abs(sum(if(dayname(transaction_date)!="friday",transaction_amount,0)))NON_FRIDAYS
FROM  trans;

-- Q2 Show the details of credit cards along with the
 -- aggregate transaction amount during holidays and non_holidays --
 -- using WITH CLAUSE --
with tran as 
(select T2.* from
(select account_number from bank_account_details where account_type like"%credit_card%") as T1,
bank_account_transaction as T2
where T1.account_number=T2.account_number)
select account_number,
abs(sum(if(transaction_date in (select holiday from bank_holidays),transaction_amount,0)))holidays,
abs(sum(if(transaction_date not in(select holiday from bank_holidays),transaction_amount,0)))non_holidays
 from tran
 group by account_number;
 -- USING SUB QUERY --
 select trans.account_number,
 abs(sum(if(transaction_date in (select holiday from bank_holidays),transaction_amount,0))) as holidays,
abs(sum(if(transaction_date not in(select holiday from bank_holidays),transaction_amount,0)))as non_holidays
from (select T2.* from
(select account_number from bank_account_details where account_type like"%credit_card%") as T1,
bank_account_transaction as T2
where T1.account_number=T2.account_number) trans
group by account_number; 
 
 
 -- Q3 Generate a report to Send Ad-hoc holiday greetings - “Happy Holiday” for
 -- all transactions occurred during Holidays in 3rd month --
 with holi as
 (select * from bank_account_transaction
 where transaction_date in (select holiday from bank_holidays
 where month(transaction_date)=3))
 select holi.account_number,holi.transaction_date,"happy holiday" message
 from holi;
 
-- Q4 Calculate the Bank accrued interest with respect to their RECURRING DEPOSITS for any deposits older than 30 days .
-- Note: Accrued interest calculation = transaction_amount * interest_rate
-- Note: use CURRENT_DATE() --

 with rec as 
 (select T2.* 
 from (select * from bank_account_details where account_type="recurring deposits")as T1,
 bank_account_transaction as T2
 where T1.account_number=T2.account_number)
 select rec.account_number,IR.account_type,SUM(rec.transaction_amount * IR.interest_rate) as accrued_interest
 from rec,bank_interest_rate IR
 where IR.account_type="recurring deposits" and rec.transaction_date< date_sub(curdate(),interval 30 day)
 group by rec.account_number;
 
 -- Q5 Display the Savings Account number whose corresponding Credit cards and 
 -- AddonCredit card transactions have occured more than one timE --
 with sav as 
 (select BAT.*,BARD.linking_account_number,BARD.account_type
 from(select * from bank_account_relationship_details
 where account_type in ("credit card","add-on credit card"))BARD,
 bank_account_transaction BAT
 where BAT.account_number=BARD.account_number)
 select BAD.account_number as savings_an,
		BAD.account_type as savings_at,
        sav.account_number as creditcard_account_number,
        sav.account_type as creditcard_account_type,
        count(sav.account_number) as count_of_transactions
 from sav,bank_account_details BAD
 where BAD.account_number=sav.linking_account_number
 group by BAD.account_number,BAD.account_type,sav.account_number,sav.account_type
 having count_of_transactions>1;
 
 -- Q6.Display the Savings Account number whose corresponding AddonCredit card transactions have occured atleast once.
-- PRE-requisite ( The below record is needed for the next two questions.
-- If you had already added above , ignore this )
-- INSERT INTO BANK_CUSTOMER_EXPORT VALUES ('123008',"Robin", "3005-1,Heathrow", "NY" , "1897614000");
 with sav as 
 (select BAT.*,BARD.linking_account_number,BARD.account_type
 from(select * from bank_account_relationship_details
 where account_type in ("add-on credit card"))BARD,
 bank_account_transaction BAT
 where BAT.account_number=BARD.account_number)
 select BAD.account_number as savings_an,
		BAD.account_type as savings_at,
        sav.account_number as creditcard_account_number,
        sav.account_type as creditcard_account_type,
        count(sav.account_number) as count_of_transactions
 from sav,bank_account_details BAD
 where BAD.account_number=sav.linking_account_number
 group by BAD.account_number,BAD.account_type,sav.account_number,sav.account_type
 having count_of_transactions=1;
 
-- Q7 Print the customer_id and length of customer_id using Natural join on
-- Tables :bank_customer and bank_customer_export
-- Note: Do not use table alias to refer to column names.
select customer_id,length(customer_id) as length 
from bank_customer cus
natural join bank_customer_export ex;

-- Q8 Print customer_id, customer_name and other common columns from both the 
-- Tables : bank_customer & bank_customer_export without missing any matching customer_id key column records.
-- Note: refer datatype conversion if found any missing records
select cu.customer_id,cuex.customer_name
from bank_customer cu
natural join bank_customer_export cuex;

 
 
 

 
 
