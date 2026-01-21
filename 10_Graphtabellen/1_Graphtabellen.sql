--------------------------------------------------
--- GRAPH Tabellen   -----------------------------
--------------------------------------------------

/*
Graphtabellen (eingeführt mit SQL Server 2017) sind ein Feature, 
das es ermöglicht, komplexe Beziehungen (Many-to-Many) einfach
und performant abzubilden als mit klassischen Joins und Fremdschlüsseln.

dazu benötigt man spezielle Tabellen:

NODE (Knoten): Das sind die "Dinge" (Objekte).
Beispiel: Mitarbeiter, Produkte, Städte.
Eigtl normale Tabellen, aber mit einer Spalte $node_id.

EDGE (Kanten): Das sind die Verbindungen.
Beispiel: BerichtetAn, GekauftVon, BefreundetMit.
Sie hat intern $from_id und $to_id und stellen die Beziehung zwischen den Nodes dar.
Edge Tabellen können , aber müssen nicht, weitere Spalten haben, um eine Eigenschaften 
der Beziehung darzustellen

*/

-- Die Objekte (Knoten)
CREATE TABLE Personen (
    ID INT PRIMARY KEY, 
    Name VARCHAR(100)
) AS NODE;

-- Die Beziehung (Kante)
CREATE TABLE Mag (
    SeitWann DATE
) AS EDGE;

-- Nodes füllen
INSERT INTO Personen VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Charlie');

-- Edges füllen (Alice mag Bob)
INSERT INTO Mag ($from_id, $to_id, SeitWann)
VALUES (
    (SELECT $node_id FROM Personen WHERE Name = 'Alice'),
    (SELECT $node_id FROM Personen WHERE Name = 'Bob'),
    '2023-01-01'
);
INSERT INTO Mag ($from_id, $to_id, SeitWann)
VALUES (
    (SELECT $node_id FROM Personen WHERE Name = 'Bob'),
    (SELECT $node_id FROM Personen WHERE Name = 'Charlie'),
    '2023-02-01'
);


Select 
p1.name, p2.name
from 
    Personen p1, Mag m, personen p2 
 where match (p1-(m)->p2) 
      and p1.name = 'Alice'


Select 
p1.name, p2.name,p3.name
from 
    Personen p1, Mag m, personen p2 , Mag m2, Personen P3
    where match (p1-(m)->p2-(m2)->p3)
      and p1.name = 'Alice'


Select 
p1.name, 
STRING_AGG (p2.name,' kennt ') WITHIN GROUP (GRAPH PATH)
from 
    Personen p1, 
    Mag  for path m, 
    personen for path p2
 WHERE MATCH(SHORTEST_PATH(p1(-(m)->p2)+))
               and p1.name = 'Alice'




ALTER TABLE Mag add km int 
update mag set km = 3 where  seitwann ='2023-01-01'
update mag set km = 2 where  seitwann ='2023-02-01'


Select 
p1.name, 
STRING_AGG (p2.name,' kennt ') WITHIN GROUP (GRAPH PATH),
SUM(m.km) WITHIN GROUP (GRAPH PATH)
from 
    Personen p1, 
    Mag  for path m, 
    personen for path p2
 WHERE MATCH(SHORTEST_PATH(p1(-(m)->p2)+))
               and p1.name = 'Alice'


--LAST_VALUE / COUNT  

-- Distanznähe kann auch angeben werden: {mindestens, maximal}
-- bei Shotest_path muss immer 1 für mindestens stehen
 WHERE MATCH(SHORTEST_PATH(p1(-(m)->p2){1,3}))


 Select 
p1.name, 
STRING_AGG (p2.name,' kennt ') WITHIN GROUP (GRAPH PATH),
SUM(m.km) WITHIN GROUP (GRAPH PATH)
from 
    Personen p1, 
    Mag  for path m, 
    personen for path p2
 WHERE MATCH(SHORTEST_PATH(p1(-(m)->p2){1,2}))
               and p1.name = 'Alice'
