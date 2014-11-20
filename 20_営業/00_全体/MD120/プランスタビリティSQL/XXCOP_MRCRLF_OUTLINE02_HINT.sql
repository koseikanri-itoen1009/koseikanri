UPDATE mrp_schedule_interface int
SET process_status = 4,
error_message =
SUBSTRB(TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS') ||
:message_text,1,240),
last_update_date=  SYSDATE,
last_updated_by = :user_id 
WHERE EXISTS (SELECT /*+ INDEX ( items MTL_SYSTEM_ITEMS_B_U1 ) */
              NULL FROM mtl_system_items items
         WHERE items.organization_id = int.organization_id
         AND items.inventory_item_id = int.inventory_item_id
         AND DECODE(NVL(items.repetitive_planning_flag, 'N'),'N',             1,2)=
             2)
AND(int.rate_end_date IS NULL OR 
    int.rate_end_date < int.schedule_date)
AND error_message     IS NULL
AND process_status = 3
AND request_id = :passed_req_id
