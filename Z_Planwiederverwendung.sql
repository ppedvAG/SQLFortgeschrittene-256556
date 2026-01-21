Select orderid, customerid as Kdnr, freight
from orders o
--where 		kdnr = 'ALFKI'
order by kdnr


--Logischer Fluss:

---> FROM (ALIAS) --> JOIN ---> WHERE --> GROUP BY --> HAVING
--> SELECT (ALIAS) --> ORDER BY --> DISTINCT| 

select country, sum(freight)
from
orders

group by country having sum(freight)



select  top 13 with ties * from orders order by freight

--wieviele Kunden gibt es pro Land

select country, city,  count(*) from customers
group by country, city with rollup
order by 1,2


select country, city,  count(*) from customers
group by country, city with cube


select * from orders where orderid = 10248

select 
	* 
	from orders where  orderid = 10248

SELECT * from ORDERS 



dbcc freeproccache

select * from customers where customerid = 'ALFKI'


select * from customers where Customerid = 'ALFKI'


select * from customers 
	where customerid = 'ALFKI'

select usecounts, cacheobjtype,[TEXT] from
	sys.dm_exec_cached_plans P
		CROSS APPLY sys.dm_exec_sql_text(plan_handle)
	where cacheobjtype ='Compiled PLan'
		AND [TEXT] not like '%dm_exec_cached_plans%'


		
		select * from orders where orderid = 10

		
		select * from orders where orderid = 300


		
		select * from orders where orderid = 40000


select * 
	from		   customers c
		inner merge join orders o			on c.customerid = o.CustomerID

select * 
	from		   customers c
		inner loop join orders o			on c.customerid = o.CustomerID

select * 
	from		   customers c
		inner hash join orders o			on c.customerid = o.CustomerID
