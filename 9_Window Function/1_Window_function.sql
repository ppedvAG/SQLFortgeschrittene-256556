						 --Window Function
--DENSE RANK  NTILE   RANK

select 
	shipcountry, freight,
	rank() over (order by freight asc)
from orders


select 
	shipcountry, freight,
	dense_rank() over (order by freight asc)
from orders

select 
	shipcountry, freight,
	row_number() over (order by freight asc)
from orders


select 
	shipcountry, freight,
Ntile(5) over (order by freight asc)
from orders

--Ntile (830)--?

--aufsummieren
select shipcountry, freight,
		sum(freight)over (order by freight asc)
from orders


--aufsummmieren pro Land

select shipcountry, freight,
	sum(freight) over (partition by shipcountry order by freight asc )
from orders

--mit RANG


select shipcountry, freight,
	sum(freight) over (partition by shipcountry order by freight asc )
	,
	row_number() over (partition by shipcountry order by freight asc) 
from orders


--sorry
select shipcountry, freight,
	sum(freight) over (partition by shipcountry order by freight asc )
	,
	row_number() over (partition by shipcountry order by freight asc) 
from orders
where 
	row_number() over (partition by shipcountry order by freight asc)  = 1
 

--aber CTE :-)


--ginge mit MAX auch

--und wie wäre es mit immer die top 3??

with cte
as
(
select shipcountry, freight,
	sum(freight) over (partition by shipcountry order by freight asc ) as Summe
	,
	row_number() over (partition by shipcountry order by freight asc)  as Rang
from orders)
select * from cte where   Rang = 1



select shipcountry,orderid,  freight , min(freight) 
from orders
group by shipcountry, orderid, freight


;with cte
as
(
select orderid, employeeid, customerid, freight, 
ROW_NUMBER() over (partition by employeeid order by freight desc) Rang
from orders 
---where rang between 1 and 3
--order by employeeid asc	 , freight	 desc
) 
select * from cte where rang between 1 and 3



--where rang = 1


--RANK-- Unterschied zu Row_number.. Rang wird übersprungen

select orderid, employeeid, customerid, freight, 
RANK() over (partition by employeeid order by freight desc) Rang
from orders


---------dense_rank----------
--vergibt gleichen Rang mehrmals---


select freight , rank() over (order by freight),
				dense_Rank() over (order by freight) from orders
order by freight asc

 ---Frage: select * from orders






----NTILE----
--aufteilen in gleiche Anzahl ---

select ntile(4) over (order by freight)
, freight from orders

--Freight 0 100 A
--100  bis 500 B
--> 500 C



select 
		customerid, freight , 
				case 
					when  freight < 100 then 'A'
					when  freight > 500 then 'C'
					else 'B'
				end as Kunden
from orders

--NTILE(4) 4 gleiche teile

select orderid, employeeid, customerid, freight, 
NTILE(4) over (partition by employeeid order by freight desc) Rang
from orders



-- berechnet die relative Position eines angegebenen Werts in einer Gruppe von Werten
 select orderid, employeeid, customerid, freight, 
CUME_DIST() over (partition by employeeid order by freight desc) Rang
from orders	   order by  2,4,5

  
--relativen Rang eines Werts innerhalb eines Abfrageresultsets oder einer Partition ermitteln
select orderid, employeeid, customerid, freight, 
CUME_DIST() over (order by freight asc) Rang,
PERCENT_RANK() over (order by freight asc) Rang,
PERCENTILE_CONT(0.5) within group  (order by freight) over (partition by employeeid)  Rang	 --Quantil auf Grundlage einer kontinuierlichen Verteilung des Spaltenwerts i
from orders	   order by  2 desc,5


CUME_DIST (Transact-SQL)	LEAD (Transact-SQL)
FIRST_VALUE (Transact-SQL)	PERCENTILE_CONT (Transact-SQL)
LAG (Transact-SQL)	PERCENTILE_DISC (Transact-SQL)
LAST_VALUE (Transact-SQL)	PERCENT_RANK (Transact-SQL)


select orderid, customerid, freight,
--rank() over (order by freight),
rank() over (partition by customerid order by freight),
ntile(20) over (order by freight), 
eomonth(getdate())		  
from orders


--Window Function

----F() OVER(PARTITION BY Col1 ORDER BY Col2 DESC)

--ROW_NUMBER------------
--fortlaufende Zahl--

select APPROX_COUNT_DISTINCT(customerid) from ku



select 	
	 orderid,productid
	 ,sum(unitprice*quantity) over (partition by orderid)  as RngSumme
	  ,unitprice*quantity
	 from [Order Details]
	 order by 1,2


  select * from [order details]











---auch mit AGG---
--Prozentanteil
--Anteil der Pos in % rel zur Rechnugssumme
select 
		orderid,productid, 
	 sum(unitprice*quantity) over (partition by orderid),
	 cast(1 *  (unitprice*quantity)/sum(unitprice*quantity) over (partition by orderid) 
		* 100 as Decimal(5,2))
	 from [Order Details]
	 order by 1,4

	 select eomonth(getdate())

 -----------------------------------------------------------------------------------------------------


 select eomonth(getdate())


 
drop table t
 CREATE TABLE T (a INT, b INT, c INT);   
GO  
INSERT INTO T VALUES (1, 1, -3), (2, 2, 4), (3, 1, NULL), (4, 3, 1), (5, 2, NULL), (6, 1, 5);   
select * from t

  
SELECT b, c,   
    LAG(2*c, b*(SELECT MIN(b) FROM T), -c/2.0) OVER (ORDER BY a) AS i  
FROM T;

SELECT b, c,   
    LEAD(2*c, b*(SELECT MIN(b) FROM T), -c/2.0) OVER (ORDER BY a) AS i  
FROM T;

select
  SUM(b) OVER(ORDER BY a RANGE UNBOUNDED PRECEDING) "Range" 
  ,SUM(b) OVER(ORDER BY a ROWS UNBOUNDED PRECEDING) "Rows"   
  ,SUM(b) OVER(ORDER BY a ROWS Between CURRENT ROW and 2 Following )     
  ,SUM(b) OVER(ORDER BY a ROWS Between 2 FOLLOWING and 3 Following )    
  ,SUM(b) OVER(ORDER BY a ROWS Between 2 Preceding    and 2 Following ) 
  from T
------------------------------------------------------------------------------------------




---,SUM(Col1) OVER (PARTITION BY Col2)
---ORDER BY Col3   ROWS UNBOUNDED PRECEDING)--aufsummieren

select * from t1
select id, sum(x) over ( order by id  ROWS UNBOUNDED PRECEDING) 
from t1

select orderid, 
	sum(unitprice*quantity)
		over ( order by orderid ROWS UNBOUNDED PRECEDING) ,
	sum(unitprice*quantity)
		over ( order by orderid RANGE UNBOUNDED PRECEDING),
	sum(unitprice*quantity)
		OVER(ORDER BY orderid ROWS Between CURRENT ROW and 2 Following )    	
  ,sum(unitprice*quantity)
		OVER(ORDER BY orderid ROWS Between 2 FOLLOWING and 3 Following )    
  ,sum(unitprice*quantity)
		OVER(ORDER BY orderid ROWS Between 2 Preceding and 2 Following ) 
from [order details]



--best verkaufte Product pro Jahr und MItarbeiter und im Vergleich zu Gesamtumsatz
--Wie hoch war also der Anteil eines Verkäufers pro Produkt und Jahr am Gesamtumsatz
--im Jahr 1996 Produkt Pavlova

;WITH CTE
as
(
select distinct 
		e.LastName, p.ProductName,	year(orderdate) as jahr
		,sum(od.unitprice*quantity) over (partition by e.lastname, productname order by year(orderdate)) as UpLP
		,sum(od.unitprice*quantity)over (partition by year(orderdate),productname ) as UpJP
from orders o 
				inner join [order details] od on o.OrderID=od.OrderID
				inner join Employees e on e.EmployeeID=o.EmployeeID
				inner join products p on p.ProductID=od.ProductID
--order by e.LastName, year(orderdate),UpLP desc--,productname 
)
select lastname, productname, jahr, UpLP, convert(decimal(4,2),Uplp/UpJP) AnteilamGesamtUmsatz from cte
where productname = 'Pavlova' and jahr = 1996
order by lastname,jahr,productname



select EmployeeID, YEAR(orderdate),
		sum(freight) as aktFracht,
		LAG(sum(Freight),1,0) over (partition by employeeid 
									order by year(orderdate)) 
									as VorJahr
from orders 
group by EmployeeID, YEAR(OrderDate)
order by 1



select * from products




--Welche Produkte wurden am meisten pro QUarta und Jahr am besten verkauft
with cte as
(
select productname, year(orderdate)	as jahr ,datepart(qq,orderdate)as Quartal, 
		sum(od.quantity)  as Menge	,
		 rank() over (partition by  year(orderdate), datepart(qq,orderdate) order by  sum(od.quantity) desc)  as RANG

from 
	orders o 
	inner join  [order details]   od on o.orderid = od.orderid
	inner join products p on od.productid = p.productid		
group by 
		   productname	  ,year(orderdate)	 ,datepart(qq,orderdate)
 )
 select *	from cte  where RANG between 1 and 3


 --all time Top verkaufte produkte		 --kommt am h?ufgisten unter den TOP 3 vor
 with cte as
(
select productname, year(orderdate)	as jahr ,datepart(qq,orderdate)as Quartal,  sum(od.quantity)  as Menge	,
		 rank() over (partition by  year(orderdate), datepart(qq,orderdate) order by  sum(od.quantity) desc)  as RANG

from 
	orders o 
	inner join  [order details]   od on o.orderid = od.orderid
	inner join products p on od.productid = p.productid		
group by 
		   productname	  ,year(orderdate)	 ,datepart(qq,orderdate)
 )
select Productname, count(*) from cte 
where Rang in (1,2,3)
group by productname  order by 2 desc


select datediff(dd,requireddate, shippeddate),requireddate, shippeddate from orders

--Gibt es Produkte , die im aktuellen Monat (1998 Monat) 3 	h?tten nachbestellt werden sollen	---noch nicht geliefert und auf Lager sind weniger als Reorderlevel
select 	  year(orderdate), month(orderdate),p.productname, Menge=sum(od.quantity) 	,p.unitsinstock, p.reorderlevel
from 
	orders o 
	inner join  [order details]   od on o.orderid = od.orderid
	inner join products p on od.productid = p.productid		
	where datediff(dd,requireddate, shippeddate) > 0	
group by 	  year(orderdate) ,month(orderdate)  , p.productname,p.unitsinstock, p.reorderlevel
order by 1 desc, 2 desc


 --Wo haben wir weniger auf Lager als bestellt und nicht 


select year(orderdate) as Jahr, datepart(qq,orderdate) as Quartal ,
	   p.productname,
	    sum(quantity) over (
				partition by  year(orderdate) , datepart(qq,orderdate), p.productname 
					
						    )
from orders o inner join  [order details]   od
on o.orderid = od.orderid
inner join products p on od.productid = p.productid			 
group by   year(orderdate),	  datepart(qq,orderdate)   ,p.productname
order by jahr, quartal asc



select EOMONTH(getdate())

select * from sys.dm_exec_Query_plan_Stats





-------------RANK-----------------


	select string_Agg(Lastname,';') over (order by employeeid) from employees

	select * from [order details]

	--
