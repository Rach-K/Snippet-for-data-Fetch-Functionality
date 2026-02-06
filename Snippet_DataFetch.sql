DROP TABLE IF Exists #OnDependDatascheduleid
select AA.LicenseAlt_key,A.DepReturnAlt_Key as
OnDependReturn,DepSubReturnAlt_Key,AA.Schedule_id,AA.ReturnType,
ROW_NUMBER() over (order by AA.Schedule_id) RN
Into #OnDependDatascheduleid
from ScheduleDetail AA
Inner Join (select distinct
A.LicenseAlt_key,A.Timekey,ReturnDate,B.DepReturnAlt_Key,B.DepSubReturnAlt_Key
from ScheduleDetail A Inner Join IOReturnFetchMatrix B On A.ReturnAlt_Key=B.ReturnAlt_Key
where Schedule_id=@Schedule_id ) A
ON AA.ReturnAlt_Key=A.DepReturnAlt_Key AND AA.Timekey=A.Timekey AND
AA.LicenseAlt_key=A.LicenseAlt_key
Inner JOIN ScheduleWorkflowDetail SW ON SW.Schedule_id=AA.Schedule_id AND
SW.WorkFlowStageAlt_Key>=4
where SW.EntityKey IN (SELECT MAX(EntityKey) FROM ScheduleWorkflowDetail GROUP BY
LicenseAlt_key,ReturnAlt_Key,Schedule_id)
ORDER BY SW.ActionDate DESC
DROP TABLE IF EXISTS #FactReturnData
SELECT RowId, ReturnRowAlt_Key, B.ReturnAlt_Key AS ReturnAlt_Key,
A.SubReturnAlt_Key,ReturnColumnAlt_Key, DataValue,Schedule_id, A.AuthorisationStatus
into #FactReturnData

FROM FactReturnData_Mod A
inner join DimSubReturn B
on A.SubReturnAlt_Key=B.SubReturnAlt_Key
WHERE ReturnType=@ReturnType
AND Schedule_id in (Select distinct Schedule_id from #OnDependDatascheduleid)
AND A.SubReturnAlt_Key in (Select distinct DepSubReturnAlt_Key from
#OnDependDatascheduleid)
AND Timekey=@TimeKey
and isnull(A.RowId,0)<>'9999'
DROP TABLE IF EXISTS #IOFetchData
select B.RowId,A.ReturnAlt_Key,A.ReturnShortName,A.SubReturnAlt_Key,A.ReturnRowAlt_Key,
A.ReturnColumnAlt_Key,B.DataValue
Into #IOFetchData from IOReturnFetchMatrix A
Inner Join #FactReturnData B
ON A.DepSubReturnAlt_Key=B.SubReturnAlt_Key AND
A.DepReturnRowAlt_Key=B.ReturnRowAlt_Key
AND A.DepReturnColumnAlt_Key=B.ReturnColumnAlt_Key
where A.Vaild='Y'

select * from IOFetchData