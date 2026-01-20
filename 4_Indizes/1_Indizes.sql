/* =============================================
   Indizes
   ============================================= 

-----------------------------------------   
Clustered Index (Gruppierter Index)
-----------------------------------------
Dies ist der wichtigste Index. Er bestimmt die physikalische Sortierreihenfolge 
der Daten in der Tabelle. Da die Daten physisch nur einmal sortiert sein können, 
gibt es nur einen Clustered Index pro Tabelle.

Funktionsweise: Die Datenzeilen selbst werden in den blauen „Blättern“
(Leaf Nodes) des Index-Baums gespeichert. Eine Tabelle mit Clustered Index 
nennt man Clustered Table, eine ohne nennt man Heap.

Einsatz:
	Meistens automatisch auf dem Primary Key (Primärschlüssel).
	...was fragwürdig sein kann.

Für Spalten, die häufig sortiert (ORDER BY), gruppiert (GROUP BY) 
oder in Bereichen abgefragt werden (BETWEEN).

Für Spalten mit hoher Eindeutigkeit (z. B. ID-Spalten).

-------------------------------------------------
Non-Clustered Index (Nicht-gruppierter Index)
-------------------------------------------------
Dieser Index ist eine separate Struktur, die losgelöst von den 
eigentlichen Datenzeilen gespeichert wird. Er enthält eine Kopie der 
indizierten Spalten und einen Zeiger (Pointer) auf die echte Datenzeile.

Funktionsweise: Wie das Stichwortverzeichnis am Ende eines Buches: 
	Es steht dort, wo das Wort zu finden ist (Seitenzahl), 
	aber der Inhalt des Buches selbst wird nicht umsortiert. 
	Man kann viele Non-Clustered Indizes pro Tabelle haben (bis zu 999).

Einsatz:
	Für Spalten, die oft in der WHERE-Klausel oder JOIN-Bedingung stehen 
	(z. B. KundenName, RechnungsDatum, Fremdschlüssel).
	
	Um Abfragen zu beschleunigen, die nicht den Primärschlüssel verwenden.

----------------------------------------------------
Unique Index (Eindeutiger Index)
----------------------------------------------------

Dieser Index stellt sicher, dass keine doppelten Werte in der indizierten Spalte vorkommen.
	Zweck: Dient primär der Datenintegrität (Verhinderung von Duplikaten), nicht nur der Performance.
	Besonderheit: Ein PRIMARY KEY erstellt automatisch einen Unique Index. 
				  Man kann ihn aber auch auf andere Spalten (z. B. E-Mail-Adresse oder Ausweisnummer) 
				  legen.
----------------------------------------------------
Composite Index (Zusammengesetzter Index)
----------------------------------------------------

Ein Index, der mehrere Spalten in einem einzigen Indexschlüssel zusammenfasst (z. B. Nachname + Vorname).
	Wichtig: Die Reihenfolge der Spalten bei der Erstellung ist entscheidend! 
			 Der Index sortiert zuerst nach Spalte A, dann nach Spalte B.

	Einsatz: Eine Abfrage, die nach Nachname filtert, nutzt den Index. 
			 Eine Abfrage, die nur nach Vorname filtert, kann ihn oft nicht 
			 effizient nutzen (Linkshändigkeit des Index).

----------------------------------------------------
Index mit eingeschlossenen Spalten (Included Columns)
----------------------------------------------------

Dies ist eine Erweiterung eines Non-Clustered Index. Man fügt Spalten hinzu, 
die nicht Teil des Sortierschlüssels sind, sondern nur als „Nutzlast“ auf der Blattebene 
des Index mitgeführt werden.

	Zweck: Umgeht die Größenbeschränkungen für Indexschlüssel (max. 900 Bytes oder 16 Spalten) 
		   und ermöglicht abdeckende Indizes (siehe unten).

	Beispiel: Index auf KundenID (zum Suchen), aber Telefonnummer ist „included“ 
			 (zum Anzeigen, ohne die Haupttabelle lesen zu müssen).

----------------------------------------------------
Covering Index (Abdeckender Index)
----------------------------------------------------

Dies ist kein spezieller Befehl, sondern ein Idealzustand. Man spricht 
von einem „Covering Index“, wenn ein Non-Clustered Index alle Spalten enthält, 
die eine bestimmte Abfrage benötigt (sowohl für WHERE als auch für SELECT).

	Vorteil: Der SQL Server muss gar nicht mehr in der eigentlichen Tabelle 
			 (Clustered Index / Heap) nachsehen. Die Antwort kommt zu 100 % aus dem Index.

	Performance: Das ist die schnellstmögliche Zugriffsart für eine Abfrage. 
				 Erreicht wird dies meist durch Included Columns.

----------------------------------------------------
Filtered Index (Gefilterter Index)
----------------------------------------------------

Ein Non-Clustered Index, der eine WHERE-Klausel enthält. Er indiziert nur einen Teil der Zeilen.

	Einsatz: Wenn man oft nur nach einer Teilmenge sucht.

	Beispiel: Eine Spalte Lieferdatum ist oft NULL (noch nicht geliefert). 
			  Ein Index WHERE Lieferdatum IS NOT NULL ist winzig klein und 
			  extrem schnell für Abfragen nach offenen Lieferungen, 
			  ignoriert aber alle abgeschlossenen.

----------------------------------------------------
Partitioned Index (Partitionierter Index)
----------------------------------------------------

Hierbei wird der Index (genau wie die Tabelle) physisch in mehrere 
kleinere Einheiten (Partitionen) zerteilt, meist basierend auf 
einem Datumsbereich oder einer ID-Spanne.

	Einsatz: Bei sehr großen Tabellen (Data Warehousing, Milliarden Zeilen).

	Vorteil: Ermöglicht das schnelle Laden oder Löschen riesiger 
			 Datenblöcke (Partition Switching) und verbessert die 
			 Wartung (z. B. Index-Rebuild nur für den aktuellen Monat 
			 statt für die letzten 10 Jahre).


   
   
   
 
 
 
 
 
 */