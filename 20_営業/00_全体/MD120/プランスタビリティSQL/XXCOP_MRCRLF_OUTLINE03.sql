UPDATE mrp_schedule_interface int
SET process_status = 4,
error_message =
SUBSTRB(TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS') ||
:message_text,1,240),
last_update_date=  SYSDATE,
last_updated_by = :user_id 
WHERE EXISTS
(SELECT NULL FROM mtl_system_items sys
            WHERE sys.organization_id = int.organization_id
              AND sys.inventory_item_id = int.inventory_item_id
              AND sys.effectivity_control = 2)
AND error_message IS NULL
AND process_status = 3
AND request_id = :passed_req_id
