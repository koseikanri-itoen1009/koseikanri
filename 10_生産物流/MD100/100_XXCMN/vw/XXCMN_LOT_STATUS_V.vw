  CREATE OR REPLACE FORCE VIEW apps.xxcmn_lot_status_v (
    lot_status
  , status_desc
  , prod_class_code
  , raw_mate_turn_m_reserve
  , raw_mate_turn_rel
  , pay_provision_m_reserve
  , pay_provision_rel
  , move_inst_m_reserve
  , move_inst_a_reserve
  , move_inst_rel
  , ship_req_m_reserve
  , ship_req_a_reserve
  , ship_req_rel
  ) AS 
  SELECT flv.lookup_code as lot_status
        ,flv.meaning as status_desc
        ,flv2.attribute2
        ,flv2.attribute3
        ,flv2.attribute4
        ,flv2.attribute5
        ,flv2.attribute6
        ,flv2.attribute7
        ,flv2.attribute8
        ,flv2.attribute9
        ,flv2.attribute10
        ,flv2.attribute11
        ,flv2.attribute12
  FROM   fnd_lookup_values flv,
         fnd_lookup_values flv2
  WHERE  flv.lookup_type = 'XXCMN_LOT_STATUS'
  AND    flv.language = 'JA'
  AND    flv.enabled_flag = 'Y'
  AND    NVL(flv.start_date_active,TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
  AND    NVL(flv.end_date_active  ,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
  AND    flv.lookup_code = flv2.attribute1
  AND    flv2.lookup_type = 'XXCMN_CAN_RESERVE'
  AND    flv2.language = 'JA'
  AND    flv2.enabled_flag = 'Y'
  AND    NVL(flv2.start_date_active,TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
  AND    NVL(flv2.end_date_active  ,TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
  ;