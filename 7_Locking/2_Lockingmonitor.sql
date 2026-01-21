SELECT
    r.session_id AS [Blockierter_SessionID],
    r.status AS [Status],
    r.command AS [Command],
    r.blocking_session_id AS [Blockierende_SessionID],
    r.wait_type AS [WaitType],
    r.wait_time AS [WaitTime_ms],
    r.wait_resource AS [WaitResource],
    r.cpu_time,
    r.logical_reads,
    r.reads,
    r.writes,
    r.start_time AS [RequestStartTime],
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS [Duration_sec],
    DB_NAME(r.database_id) AS [Database],
    s.host_name AS [Blockierter_Host],
    s.program_name AS [Blockierter_Programm],
    s.login_name AS [Blockierter_Login],
    txt.text AS [Blockierter_SQL],
    bl.host_name AS [Blockierende_Host],
    bl.program_name AS [Blockierende_Programm],
    bl.login_name AS [Blockierende_Login],
    txtb.text AS [Blockierende_SQL],
    r.blocking_session_id
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS txt
LEFT JOIN sys.dm_exec_sessions bl ON r.blocking_session_id = bl.session_id
OUTER APPLY (
    SELECT text
    FROM sys.dm_exec_requests br
    OUTER APPLY sys.dm_exec_sql_text(br.sql_handle)
    WHERE br.session_id = r.blocking_session_id
) AS txtb
WHERE r.blocking_session_id <> 0
ORDER BY [Duration_sec] DESC;
