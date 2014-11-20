/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_salesrep_info_v
 * Description     : 営業担当ビュー(クイック受注用)
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/1/26     1.0   T.Tyou           新規作成
 *  2009/5/12     1.1   S.Tomita         [T1_0964]カラムコメント間違い修正
 *  2009/5/13     1.2   S.Tomita         [T1_0976]クイック受注オーガナイザセキュリティ対応
 *  2009/09/03    1.3   M.Sano           障害番号0001227 対応
 *  2012/06/06    1.4   N.Koyama         E_本稼動_09610対応
 *
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_order_salesrep_info_v (
  name,
  salesrep_id,                            --
  salesrep_number,                        --
  account_number,
  start_date_active,
  end_date_active,
  effective_start_date,
  effective_end_date,
-- 2012/06/06 Ver1.4 Add Start
  papf_effective_start_date,
  papf_effective_end_date,
-- 2012/06/06 Ver1.4 Add End
  employee_number,
  hatsurei_date,
  new_base_code,
  old_base_code,
  sale_base_code,
  past_sale_base_code,
  delivery_base_code
)
AS 
SELECT
      jrs.name              name,
      jrs.salesrep_id       salesrep_id,
      jrs.salesrep_number   salesrep_number,
      cust.account_number   account_number,
      jrs.start_date_active start_date_active,
      jrs.end_date_active   end_date_active,
      paaf.effective_start_date  effective_start_date,
      paaf.effective_end_date    effective_end_date,
-- 2012/06/06 Ver1.4 Add Start
      papf.effective_start_date  papf_effective_start_date,
      papf.effective_end_date    papf_effective_end_date,
-- 2012/06/06 Ver1.4 Add End
      jrre.source_number    employee_number,
      TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' )          hatsurei_date,                --発令日
      paaf.ass_attribute5                                 new_base_code,                --拠点コード（新）
      paaf.ass_attribute6                                 old_base_code,                --拠点コード（旧）
      cust.sale_base_code,
      cust.past_sale_base_code,
      cust.delivery_base_code
FROM   jtf_rs_salesreps          jrs
      ,jtf_rs_resource_extns    jrre
      ,per_all_assignments_f    paaf
      ,per_all_people_f         papf
      ,per_person_types         pept
      ,(
        SELECT xca.sale_base_code,
               xca.past_sale_base_code,
               xca.delivery_base_code,
               hca.account_number
        FROM   hz_cust_accounts     hca,
               xxcmm_cust_accounts  xca
        WHERE  hca.cust_account_id   = xca.customer_id
       ) cust
--      ,(
-- 2009/09/03 Ver1.3 Mod Start
--        SELECT TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --業務日付
--        FROM   dual
-- 2012/06/06 Ver1.4 Del Start
--        SELECT TRUNC( xpd.process_date ) process_date
--        FROM   xxccp_process_dates  xpd
-- 2009/09/03 Ver1.3 Mod End
--       ) pd
-- 2012/06/06 Ver1.4 Del End
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
-- 2012/06/06 Ver1.4 Del Start
--AND   NVL(TRUNC(papf.effective_start_date),pd.process_date) <= pd.process_date
--AND   NVL(TRUNC(papf.effective_end_date)  ,pd.process_date) >= pd.process_date
-- 2012/06/06 Ver1.4 Del End
;

COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.name                  IS  '従業員名称';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.salesrep_id           IS  'セールスID';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.salesrep_number       IS  'セールス番号';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.account_number        IS  '顧客コード';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.start_date_active     IS  '有効開始日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.end_date_active       IS  '有効終了日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.effective_start_date  IS  '有効開始日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.effective_end_date    IS  '有効終了日';
-- 2012/06/06 Ver1.4 Add Start
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.papf_effective_start_date  IS  '従業員有効開始日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.papf_effective_end_date    IS  '従業員有効終了日';
-- 2012/06/06 Ver1.4 Add End
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.employee_number       IS  '従業員コード';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.hatsurei_date         IS  '発令日';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.new_base_code         IS  '拠点コード（新）';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.old_base_code         IS  '拠点コード（旧）';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.sale_base_code        IS  '売上拠点';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.past_sale_base_code   IS  '前月売上拠点';
COMMENT ON  COLUMN  xxcos_order_salesrep_info_v.delivery_base_code    IS  '納品拠点';
--
COMMENT ON  TABLE   xxcos_order_salesrep_info_v                       IS  '営業担当ビュー(クイック受注用)';
