insert into MRP_SCHEDULE_DATES(mps_transaction_id,schedule_level,
  supply_demand_type,last_update_date,last_updated_by,creation_date,
  created_by,last_update_login,inventory_item_id,organization_id,
  schedule_designator,schedule_date,schedule_workdate,rate_end_date,
  schedule_quantity,original_schedule_quantity,repetitive_daily_rate,
  schedule_origination_type,source_forecast_designator,reference_schedule_id,
  schedule_comments,source_organization_id,source_schedule_designator,
  source_sales_order_id,reservation_id,forecast_id,program_application_id,
  program_id,program_update_date,request_id,source_code,source_line_id,
  attribute1,attribute2,attribute3,attribute4,attribute5,attribute6,
  attribute7,attribute8,attribute9,attribute10,attribute11,attribute12,
  attribute13,attribute14,attribute15,old_transaction_id,to_update,project_id,
  task_id,line_id)select /*+ INDEX ( sys MTL_SYSTEM_ITEMS_B_U1 ) */DECODE(int.transaction_id,null ,
  mrp_schedule_dates_s.nextval ,int.transaction_id) ,2 ,
  DECODE(desig.schedule_type,2,2,1) ,sysdate  ,:b0 ,sysdate  ,:b0 ,(-1) ,
  int.inventory_item_id ,int.organization_id ,int.schedule_designator ,
  TRUNC(int.new_schedule_date) ,
  TRUNC(MRP_CALENDAR.PREV_WORK_DAY(int.organization_id,1,
  int.new_schedule_date)) ,TRUNC(int.new_rate_end_date) ,
  DECODE(NVL(sys.REPETITIVE_PLANNING_FLAG,'N'),'N',int.schedule_quantity,null 
  ) ,int.schedule_quantity ,DECODE(NVL(sys.REPETITIVE_PLANNING_FLAG,'N'),'N',
  null ,int.schedule_quantity) ,7 ,null  ,DECODE(desig.schedule_type,2,
  mrp_schedule_dates_s.nextval ,null ) ,
  SUBSTRB(((DECODE(int.schedule_comments,' ','',(int.schedule_comments||' - ')
  )||'Loaded ')||TO_CHAR(sysdate ,'DD-MON-RR HH24:MI:SS')),1,240) ,
  int.organization_id ,int.schedule_designator ,null  ,null  ,null  ,null  ,
  null  ,sysdate  ,:b2 ,int.source_code ,int.source_line_id ,int.attribute1 ,
  int.attribute2 ,int.attribute3 ,int.attribute4 ,int.attribute5 ,
  int.attribute6 ,int.attribute7 ,int.attribute8 ,int.attribute9 ,
  int.attribute10 ,int.attribute11 ,int.attribute12 ,int.attribute13 ,
  int.attribute14 ,int.attribute15 ,null  ,null  ,
  DECODE(org.project_reference_enabled,1,int.project_id,null ) ,
  DECODE(org.project_reference_enabled,1,DECODE(org.project_control_level,2,
  int.task_id,null ),null ) ,int.line_id  from MTL_PARAMETERS org ,
  MRP_SCHEDULE_INTERFACE int ,MRP_PLAN_ORGANIZATIONS_V mpo ,
  MRP_SCHEDULE_DESIGNATORS desig ,MTL_SYSTEM_ITEMS sys where 
  ((((((((((desig.schedule_designator=int.schedule_designator and 
  desig.schedule_designator=mpo.compile_designator(+)) and 
  desig.organization_id=mpo.organization_id(+)) and 
  NVL(mpo.planned_organization,desig.organization_id)=int.organization_id) 
  and org.organization_id=int.organization_id) and sys.organization_id=
  int.organization_id) and sys.inventory_item_id=int.inventory_item_id) and 
  process_status=3) and ((int.action is null  and ((int.transaction_id is  
  not null  and int.schedule_quantity>0) or int.transaction_id is null )) or 
  int.action in ('I','U'))) and int.request_id=:b2) and error_message is null 
  )