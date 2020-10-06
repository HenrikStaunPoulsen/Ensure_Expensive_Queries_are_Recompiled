
-- from https://www.brentozar.com/archive/2020/09/i-would-love-a-cost-threshold-for-recompile-setting/


;WITH XMLNAMESPACES  
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
    SELECT TOP 1000 st.text
        ,cp.size_in_bytes
        ,cp.plan_handle
        ,QP.query_plan
        ,n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost
        ,try_convert(decimal(9,4), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) AS StatementSubTreeCost
    FROM sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS QP
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
    WHERE cp.objtype = N'Adhoc'
        AND cp.usecounts = 1
    OPTION(RECOMPILE);


/* turn this into something that invalidates plans that cost more than 500 qb) */
;WITH XMLNAMESPACES  
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT TOP 1000 st.text
        ,cp.size_in_bytes
        ,cp.plan_handle
        ,QP.query_plan
        ,n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost
        ,try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) AS StatementSubTreeCost
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS QP
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > 1
--WHERE try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > 500
OPTION(RECOMPILE);


/* turn this into something that invalidates plans that cost more than 500 qb) */
set nocount on
declare @sql nvarchar(max)=''
;WITH XMLNAMESPACES  
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT @sql += 'DBCC FREEPROCCACHE (0x' +  convert(varchar(max), cp.plan_handle, 2) + ')
'
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS QP
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE try_convert(decimal(9,4), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > 1
--WHERE try_convert(decimal(9,4), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > 500.0
OPTION(RECOMPILE);

exec longprint @sql

exec sp_executesql @sql
