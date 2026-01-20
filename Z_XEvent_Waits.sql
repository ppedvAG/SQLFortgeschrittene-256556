CREATE EVENT SESSION [CaptureResourceWaits] ON SERVER 
ADD EVENT sqlos.wait_completed(SET collect_wait_resource=(1)
    ACTION(sqlserver.session_id)
    WHERE ([package0].[equal_uint64]([sqlserver].[session_id],(64))))
ADD TARGET package0.ring_buffer(SET max_memory=(8192))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

