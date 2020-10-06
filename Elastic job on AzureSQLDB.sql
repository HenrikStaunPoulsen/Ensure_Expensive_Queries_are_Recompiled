
EXEC jobs.sp_delete_job @job_name='Ensure_Expensive_Queries_are_Recompiled', @force=1
EXEC jobs.sp_add_job @job_name='Ensure_Expensive_Queries_are_Recompiled', @description='Ensure_Expensive_Queries_are_Recompiled',  @schedule_interval_type='Hours', @schedule_interval_count = 1, @schedule_start_time ='2020-10-06 10:00', @enabled=1
EXEC jobs.sp_add_jobstep @job_name='Ensure_Expensive_Queries_are_Recompiled', @command=N'exec dbo.Ensure_Expensive_Queries_are_Recompiled 100;',@credential_name='mycred',@target_group_name='PoolGroup'

