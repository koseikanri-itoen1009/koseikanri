/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * View Name       : xxcos_order_salesrep_info2_v
 * Description     : 営業担当ビュー(クイック受注用:顧客なし)
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/05/13    1.0   S.Tomita         [T1_0976]新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_salesrep_info2_v (
  name,
  salesrep_id,
  salesrep_number,
  start_date_active,
  end_date_active,
  effective_start_date,
  effective_end_date,
  employee_number,
  hatsurei_date,
  new_base_code,
  old_base_code
)
AS 
  SELECT
      jrs.name              name,
      jrs.salesrep_id       salesrep_id,
      jrs.salesrep_number   salesrep_number,
      jrs.start_date_active start_date_active,
      jrs.end_date_active   end_date_active,
      paaf.effective_start_date  effective_start_date,
      paaf.effective_end_date    effective_end_date,
      jrre.source_number    employee_number,
      TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' )          hatsurei_date,  --発令日
      paaf.ass_attribute5                                 new_base_code,  --拠点コード（新）
      paaf.ass_attribute6                                 old_base_code   --拠点コード（旧）
FROM   jtf_rs_salesreps         jrs
      ,jtf_rs_resource_extns    jrre
      ,per_all_assignments_f    paaf
      ,per_all_people_f         papf
      ,per_person_types         pept
      ,(
        SELECT
          TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --業務日付
        FROM
          dual
      )                               pd
WHERE
      jrre.category             =   'EMPLOYEE'
AND   jrs.resource_id           =   jrre.resource_id
AND   papf.person_id            =   jrre.source_id
AND   pept.business_group_id    =   fnd_global.per_business_group_id
AND   pept.system_person_type   =   'EMP'
AND   pept.active_flag          =   'Y'
AND   papf.person_type_id       =   pept.person_type_id
AND   paaf.person_id            =   papf.person_id
AND   nvl(jrs.org_id,   nvl(to_number(decode(substrb(userenv('CLIENT_INFO'),   1,   1),   ' ',
        NULL,   substrb(userenv('CLIENT_INFO'),   1,   10))),   -99)) =
         nvl(to_number(decode(substrb(userenv('CLIENT_INFO'),   1,   1),   ' ',
          NULL,   substrb(userenv('CLIENT_INFO'),   1,   10))),   -99)
AND   NVL(TRUNC(papf.effective_start_date),pd.process_date) <= pd.process_date
AND   NVL(TRUNC(papf.effective_end_date)  ,pd.process_date) >= pd.process_date
;
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.name                  IS  '従業員名称';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.salesrep_id           IS  'セールスID';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.salesrep_number       IS  'セールス番号';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.start_date_active     IS  '有効開始日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.end_date_active       IS  '有効終了日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.effective_start_date  IS  '有効開始日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.effective_end_date    IS  '有効終了日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.employee_number       IS  '従業員コード';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.hatsurei_date         IS  '発令日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.new_base_code         IS  '拠点コード（新）';
COMMENT ON  COLUMN  xxcos_order_salesrep_info2_v.old_base_code         IS  '拠点コード（旧）';
--
COMMENT ON  TABLE   xxcos_order_salesrep_info2_v                       IS  '営業担当ビュー(クイック受注用)';
