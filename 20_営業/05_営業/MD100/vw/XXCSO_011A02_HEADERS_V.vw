/*************************************************************************
 * 
 * VIEW Name       : xxcso_011a02_headers_v
 * Description     : CSO_011_A02_作業依頼／発注依頼検索画面ヘッダビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/12/22    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_011a02_headers_v
(
po_req_number,
category_name,
work_hope_date,
install_at_customer_code,
install_at_customer_name,
sp_decision_number,
final_contract_number,
po_req_status_name,
po_req_approved_date,
vdms_interface_flag,
vdms_interface_datetime,
po_number,
po_status_name,
po_approved_date,
install_code,
withdraw_install_code,
abolishment_install_code,
po_req_creation_date,
employee_number,
full_name,
work_base_code,
work_base_name,
po_req_h_auth_status,
po_h_auth_status,
requisition_line_id,
category_kind,
sale_base_code,
po_req_ln_creation_date,
category_id
)
AS
SELECT
      prh.segment1                    po_req_number             -- 購買依頼番号
,     mcb.segment1                    category_name             -- カテゴリ名
,     DECODE(   prlv.work_hope_year
              || prlv.work_hope_month
              || prlv.work_hope_day
             ,NULL
             ,NULL
             ,  prlv.work_hope_year 
              || '/' || prlv.work_hope_month 
              || '/' || prlv.work_hope_day
                                 )    work_hope_date            -- 作業希望日
,     prlv.install_at_customer_code   install_at_customer_code  -- 顧客CD
,     xcav.party_name                 party_name                -- 顧客名
,     prlv.sp_decision_number         sp_decision_number        -- SP専決番号
,     (
       SELECT distinct first_value(xcm.contract_number)  --（最新の確定済契約書No）
                       over(partition by xcm.sp_decision_header_id 
                                      order by xcm.last_update_date desc, xcm.contract_management_id desc)
              AS final_contract_number
       FROM   xxcso_contract_managements xcm
       ,      xxcso_sp_decision_headers  xsdh
       WHERE  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
       AND    xsdh.sp_decision_number   = prlv.sp_decision_number
       AND    xcm.status                = '1'  --確定済
      )                               final_contract_number     -- 契約書番号
,     posts1.meaning                  po_req_status_name        -- 購買依頼ステータス名
,     prh.approved_date               po_req_approved_date      -- 購買依頼承認日
,     NVL(xwrp.interface_flag,'N')    vdms_interface_flag       -- 自販機管理S連携済
,     DECODE(NVL(xwrp.interface_flag,'N')
            ,'N'
            ,NULL
            ,TO_CHAR(xwrp.last_update_date,'yyyy/mm/dd hh24:mi:ss')
            )                         vdms_interface_datetime   -- 自販機管理S連携日
,     ph.segment1                     po_number                 -- 発注番号
,     posts2.meaning                  po_status_name            -- 発注ステータス名
,     ph.approved_date                po_approved_date          -- 発注承認日
,     prlv.install_code               install_code              -- 設置用物件CD
,     prlv.withdraw_install_code      withdraw_install_code     -- 引揚用物件CD
,     prlv.abolishment_install_code   abolishment_install_code  -- 廃棄用物件CD
,     prh.creation_date               po_req_creation_date      -- 購買依頼作成日
,     xev.employee_number             employee_number           -- 作成者CD
,     xev.full_name                   full_name                 -- 作成者名
,     (
       CASE
         WHEN   xev.issue_date > to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
         THEN   xev.work_base_code_old
         ELSE   xev.work_base_code_new
         END
      )                               work_base_code            -- 作成者拠点CD
,     (
       SELECT  xab.base_name
       FROM    xxcso_aff_base_v xab
       WHERE   (
                 (    xev.issue_date > to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
                  AND xab.base_code = xev.work_base_code_old )
               OR        
                 (    xev.issue_date <= to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
                  AND xab.base_code = xev.work_base_code_new )
               )
      )                               work_base_name            -- 作成者拠点名
,     prh.authorization_status        po_req_h_auth_status      -- 購買依頼ステータス
,     ph.authorization_status         po_h_auth_status          -- 発注ステータス
,     prlv.requisition_line_id        requisition_line_id       -- 購買依頼明細ID
,     flvv.attribute1                 category_kind             -- カテゴリ種別
,     xcav.sale_base_code             sale_base_code            -- 売上担当拠点
,     prlv.po_req_ln_creation_date    po_req_ln_creation_date   -- 購買依頼明細作成日
,     prlv.category_id                category_id               -- カテゴリID
FROM  (
        SELECT  prl.requisition_line_id
        ,       prl.requisition_header_id
        ,       prl.category_id
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'SP_DECISION_NUMBER'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) sp_decision_number         --SP専決番号
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'INSTALL_AT_CUSTOMER_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) install_at_customer_code   --設置先顧客CD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_YEAR'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_year             --作業希望年
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_MONTH'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_month            --作業希望月
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_DAY'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_day             --作業希望日
        ,       prl.attribute1 install_code            --設置物件CD
        ,       prl.attribute2 withdraw_install_code   --引揚物件CD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'ABOLISHMENT_INSTALL_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) abolishment_install_code   --廃棄物件CD
        ,       prl.creation_date            po_req_ln_creation_date --作成日
        FROM    po_requisition_lines prl
      )                         prlv       -- 購買依頼情報
,     po_requisition_headers prh           -- 購買依頼ヘッダ
,     po_req_distributions prd             -- 購買依頼搬送
,     po_headers ph                        -- 発注ヘッダ
,     po_distributions pd                  -- 発注搬送
,     xxcso_wk_requisition_proc xwrp       -- 作業依頼／発注情報連携対象テーブル
,     mtl_categories_b mcb                 -- 品目カテゴリ
,     fnd_lookup_values_vl flvv            -- 参照タイプ（カテゴリ）
,     fnd_lookup_values_vl posts1          -- 参照タイプ（購買依頼ステータス）
,     fnd_lookup_values_vl posts2          -- 参照タイプ（発注ステータス）
,     xxcso_employees_v    xev             -- 従業員ビュー
,     xxcso_cust_accounts_v xcav           -- 顧客マスタビュー
WHERE prlv.requisition_header_id  = prh.requisition_header_id
AND   prd.requisition_line_id(+)  = prlv.requisition_line_id
AND   pd.req_distribution_id(+)   = prd.distribution_id
AND   ph.po_header_id(+)          = pd.po_header_id
AND   xwrp.requisition_line_id(+) = prlv.requisition_line_id
AND   mcb.category_id            = prlv.category_id
AND   flvv.lookup_type           = 'XXCSO1_PO_CATEGORY_TYPE'
AND   flvv.meaning               = mcb.segment1
AND   posts1.lookup_type         = 'AUTHORIZATION STATUS'
AND   posts1.lookup_code         = prh.authorization_status
AND   posts2.lookup_type(+)      = 'AUTHORIZATION STATUS'
AND   posts2.lookup_code(+)      = ph.authorization_status
AND   xev.user_id                = prh.created_by
AND   xev.start_date            <= TRUNC(prh.creation_date)
AND   NVL(xev.end_date, TRUNC(prh.creation_date)) 
                                >= TRUNC(prh.creation_date)
AND   xev.employee_start_date   <= TRUNC(prh.creation_date)
AND   xev.employee_end_date     >= TRUNC(prh.creation_date)
AND   xev.assign_start_date     <= TRUNC(prh.creation_date)
AND   xev.assign_end_date       >= TRUNC(prh.creation_date)
AND   xcav.account_number(+)     = prlv.install_at_customer_code
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_011A02_HEADERS_V IS 'CSO_011_A02_ヘッダビュー';