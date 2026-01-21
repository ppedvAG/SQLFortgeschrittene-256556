create database Graphdb
GO

--A---->B
--B<----A

use graphdb
go
drop table if exists person
drop table  if exists friendof

CREATE TABLE Person (
  ID INTEGER PRIMARY KEY,
  name VARCHAR(100)
) AS NODE;


CREATE TABLE friendOf AS EDGE;


INSERT INTO Person VALUES (1,'Stefan');
INSERT INTO Person VALUES (2,'Daniel');
INSERT INTO Person VALUES (3,'John');
INSERT INTO Person VALUES (4,'Mary');
INSERT INTO Person VALUES (5,'Jacob');
INSERT INTO Person VALUES (6,'Julie');
INSERT INTO Person VALUES (7,'Alice');
INSERT INTO Person VALUES (8,'Hans');
INSERT INTO Person VALUES (9,'Max');
INSERT INTO Person VALUES (10,'Susi');


INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 2), 
 (SELECT $node_id FROM Person WHERE ID = 1));

INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 3), 
 (SELECT $node_id FROM Person WHERE ID = 2));

INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 4), 
 (SELECT $node_id FROM Person WHERE ID = 3));


INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 3), 
 (SELECT $node_id FROM Person WHERE ID = 4));

INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 5), 
 (SELECT $node_id FROM Person WHERE ID = 4));


INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 4), 
 (SELECT $node_id FROM Person WHERE ID = 7));

 
INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 8), 
 (SELECT $node_id FROM Person WHERE ID = 7));



INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 10), 
 (SELECT $node_id FROM Person WHERE ID = 4));

INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 10), 
 (SELECT $node_id FROM Person WHERE ID = 8));



  INSERT INTO friendof 
VALUES 
((SELECT $node_id FROM Person WHERE ID = 7), 
 (SELECT $node_id FROM Person WHERE ID = 3));


 select * from friendOf

 --Welche direkten Freunde hat
SELECT p1.name, p2.name
FROM 
	Person p1, friendof, person p2
WHERE 
	MATCH (p1-(friendof)->p2)
AND p1.name = 'John';

SELECT person.name, p2.name
FROM Person, friendof, person p2
WHERE MATCH (Person-(friendof)->p2)
AND Person.name = 'Mary';

--und in 2ter Linie
 SELECT p1.name, p3.name
FROM Person p1, friendof fo, person p2, friendof fo2, person p3
WHERE MATCH (p1-(fo)->p2-(fo2)->p3)
AND p1.name = 'Jacob';


--und wer kennt sich gegenseitig

select p1.name, p2.name
from person p1, person p2 , friendof fo, friendof fo2
where match(p1-(fo)->p2-(fo2)->p1) and p1.name = 'mary'

--Wer kennt Mary
select p1.name, p2.name
from person p1, person p2 , friendof fo, friendof fo2
where match(p1-(fo)->p2<-(fo2)-p1) and p2.name = 'mary'


select string_agg(lastname,'; ') from northwind..employees


SELECT
   Person1.name AS PersonName, 
   STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends
FROM
   Person AS Person1,
   friendOf FOR PATH AS fo,
   Person FOR PATH  AS Person2
WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2)+))--Distanz egal
AND Person1.name = 'Hans'



SELECT
   Person1.name AS PersonName, 
   STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends
FROM
   Person AS Person1,
   friendOf FOR PATH AS fo,
   Person FOR PATH  AS Person2
WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2){1,4})) --Distanz bestimmen
AND Person1.name = 'Hans'


--last_Node finden
SELECT PersonName, Friends
FROM (  
 SELECT
       Person1.name AS PersonName, 
       STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
       LAST_VALUE(Person2.name) WITHIN GROUP (GRAPH PATH) AS LastNode
   FROM
       Person AS Person1,
       friendOf FOR PATH AS fo, --muss für die Siche entlang der Kanten/Pfade angegeben werden 
       Person FOR PATH  AS Person2
   WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2)+))
   AND Person1.name = 'Hans'
) AS Q
WHERE Q.LastNode = 'John'



---kürzesten Wege zu allen vernetzten Freunden
SELECT
   Person1.name AS PersonName, 
   STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends
FROM
   Person AS Person1,
   friendOf FOR PATH AS fo,
   Person FOR PATH  AS Person2
WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2)+))
AND Person1.name = 'Hans'


SELECT PersonName, Friends, levels
FROM (  
   SELECT
       Person1.name AS PersonName, 
       STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
       LAST_VALUE(Person2.name) WITHIN GROUP (GRAPH PATH) AS LastNode,
       COUNT(Person2.name) WITHIN GROUP (GRAPH PATH) AS levels
   FROM
       Person AS Person1,
       friendOf FOR PATH AS fo,
       Person FOR PATH  AS Person2
   WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2)+))
   AND Person1.name = 'Hans'
   	) AS Q
WHERE Q.LastNode = 'Stefan'

--2 Hops entfernt
SELECT PersonName, Friends
FROM (
    SELECT
        Person1.name AS PersonName, 
        STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
        COUNT(Person2.name) WITHIN GROUP (GRAPH PATH) AS levels
    FROM
        Person AS Person1,
        friendOf FOR PATH AS fo,
        Person FOR PATH  AS Person2
    WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2){1,3}))
    AND Person1.name = 'Jacob'
) Q
WHERE Q.levels = 2



--Sympathie
alter table person add sympathie int

update Person set sympathie = id % 3
update Person set sympathie = 5 where sympathie = 0

select * from person


SELECT PersonName, Friends, levels
FROM (
    SELECT
        Person1.name AS PersonName, 
        STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
        sum(Person2.sympathie) WITHIN GROUP (GRAPH PATH) AS levels
    FROM
        Person AS Person1,
        friendOf FOR PATH AS fo,
        Person FOR PATH  AS Person2
    WHERE MATCH(SHORTEST_PATH(Person1(-(fo)->Person2){1,3}))
    AND Person1.name = 'Jacob'
) Q
WHERE Q.levels >1


select * from person

