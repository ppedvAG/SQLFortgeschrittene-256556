/*  

Columnstore

SQL Server 2025 (17.x) Preview hat die folgenden Features hinzugefügt:

Sortierter nicht gruppierter Columnstore verbessert die Abfrageleistung 
in Echtzeit-Betriebsanalysen.


Ein sortierter Columnstore-Index (gruppiert oder nicht gruppiert) 
kann jetzt online erstellt oder neu erstellt werden.

Sie können in der ONLINE = ON angeben, wenn die ORDER Klausel vorhanden ist. 
Weitere Informationen zu Onlineindexvorgängen finden Sie unter 
"Online ausführen von Indexvorgängen".

Verbesserte Sortierqualität für sortierte gruppierte Spaltenspeicherindizes.

In SQL Server 2025 (17.x) Preview wird beim Online-Erstellen 
eines sortierten gruppierten Columnstore-Index der Sortieralgorithmus verwendet
, der tempdb nutzt, anstatt die Daten im Arbeitsspeicher zu sortieren. 
Wenn 
--> MAXDOP für den Indexaufbau 1 --> ist, erzeugt der Build einen 
vollständig geordneten gruppierten Spaltenspeicherindex
, der keine überlappenden Segmente enthält.

Dies kann die Leistung von Abfragen mithilfe des Indexes verbessern. 
Der Indexaufbau kann jedoch aufgrund der zusätzlichen E/A-Vorgänge
, die für Dateiauslagerungen tempdb erforderlich sind, länger dauern.

Wenn bereits ein bestehender gruppierter Column-Store-Index vorhanden ist
, können Abfragen den Index weiterhin verwenden
, während der ordnungsgemäße Online-Indexrebuild ausgeführt wird.

Verbesserte Datenbank- und Dateiverkleinerungsvorgänge.

In früheren Versionen von SQL Server können die Datenseiten
, die von einem gruppierten Columnstore-Index mit Spalten des 
LOB-Datentyps wie varchar(max), nvarchar(max), varbinary(max) 
verwendet werden, nicht durch Verkleinerungsvorgänge verschoben werden. 
Als Ergebnis kann das Verkleinern weniger effektiv sein
, um Platz in den Datendateien freizugeben.

In SQL Server 2025 (17.x) Preview können sowohl DBCC SHRINKDATABASE-Befehl 
als auch DBCC SHRINKFILE-Befehl Datenseiten verschieben
, die von den LOB-Spalten in Spaltenspeicherindizes verwendet werden.


SQL 2022


SQL Server 2022 (16.x) hat die folgenden Features hinzugefügt:

Sortierte gruppierte Columnstore-Indizes verbessern die Leistung für 
Abfragen basierend auf sortierten Spalten-Prädikaten. Sortierte 
Spaltenspeicherindizes können die Leistung verbessern, 
indem Segmente von Daten vollständig übersprungen werden. 
Dies kann den IO-Bedarf für Abfragen von Columnstore-Daten 
drastisch reduzieren. 

Prädikatpushdown mit gruppierter Columnstore-Rowgroup-Eliminierung 
von Zeichenfolgen verwendet Grenzwerte, um Zeichenfolgensuchen zu optimieren. 
Alle Columnstore-Indizes profitieren von einer verbesserten 
Segmentlöschung nach Datentyp. Ab SQL Server 2022 (16.x) 
erweitern sich diese Segmentlöschfunktionalitäten auf 
Zeichenfolgen-, Binär- und GUID-Datentypen sowie den datetimeoffset-Datentyp 
für Skalierungen größer als zwei. Zuvor wurde die Eliminierung des 
Spaltenspeichersegments nur auf numerische Datentypen, Datums- und Zeitdatentypen 
und den datetimeoffset Datentyp mit einer Genauigkeit kleiner oder 
gleich zwei angewendet. Nach dem Upgrade auf eine Version von SQL Server
, die die Eliminierung von Min/Max-Segmenten bei Zeichenfolgen unterstützt 
(SQL Server 2022 (16.x) und höher), profitiert der Spaltenspeicherindex 
nicht von diesem Feature, bis er mit ALTER INDEX REBUILD oder 
CREATE INDEX WITH (DROP_EXISTING = ON)neu erstellt wird.

Beseitigung von Columnstore-Zeilengruppen für den Präfix von LIKE-Prädikaten
, zum Beispiel column LIKE 'string%'. Die Segmenteliminierung wird für 
die Verwendung von LIKE ohne Präfix wie z. B. column LIKE '%string' nicht unterstützt.
