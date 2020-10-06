
go
create or alter procedure dbo.Ensure_Expensive_Queries_are_Recompiled (
	@RecompileAbove int = 500, -- query bucks
	@debug tinyint = 0
/*
test harness:
	exec dbo.Ensure_Expensive_Queries_are_Recompiled 500, 1
*/
)
as begin
	set xact_abort, nocount on

	/* turn this into something that invalidates plans that cost more than 500 query bucks) */
	if @debug=1 begin -- list expensive queries
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
		WHERE try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > @RecompileAbove
		OPTION(RECOMPILE);
	end

	declare @sql nvarchar(max)=''
	;WITH XMLNAMESPACES  
		(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
	SELECT @sql += 'DBCC FREEPROCCACHE (0x' +  convert(varchar(max), cp.plan_handle, 2) + ') /* ' + replace(replace(left(st.text, 100), char(10), ''), char(13), '') + '... */
	'
	FROM sys.dm_exec_cached_plans AS cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS QP
	CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
	--WHERE try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > 1
	WHERE try_convert(decimal(9,0), n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')) > @RecompileAbove
	OPTION(RECOMPILE);

	if @debug=1 exec dbo.longprint @sql
	exec sp_executesql @sql
end
go