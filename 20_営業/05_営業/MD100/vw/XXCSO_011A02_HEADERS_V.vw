/*************************************************************************
 * 
 * VIEW Name       : xxcso_011a02_headers_v
 * Description     : CSO_011_A02_ìÆË^­ËõæÊwb_r[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/12/22    1.0  T.Maruyama    ñì¬
 *  2010/03/15    1.1  T.Maruyama    E_{Ò®_01888 PTÎô
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
category_id,
requisition_header_id
)
AS
SELECT
      prh.segment1                    po_req_number             -- wËÔ
,     mcb.segment1                    category_name             -- JeS¼
,     DECODE(   prlv.work_hope_year
              || prlv.work_hope_month
              || prlv.work_hope_day
             ,NULL
             ,NULL
             ,  prlv.work_hope_year 
              || '/' || prlv.work_hope_month 
              || '/' || prlv.work_hope_day
                                 )    work_hope_date            -- ìÆó]ú
,     prlv.install_at_customer_code   install_at_customer_code  -- ÚqCD
,     xcav.party_name                 party_name                -- Úq¼
,     prlv.sp_decision_number         sp_decision_number        -- SPêÔ
,     (
       SELECT distinct first_value(xcm.contract_number)  --iÅVÌmèÏ_ñNoj
                       over(partition by xcm.sp_decision_header_id 
                                      order by xcm.last_update_date desc, xcm.contract_management_id desc)
              AS final_contract_number
       FROM   xxcso_contract_managements xcm
       ,      xxcso_sp_decision_headers  xsdh
       WHERE  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
       AND    xsdh.sp_decision_number   = prlv.sp_decision_number
       AND    xcm.status                = '1'  --mèÏ
      )                               final_contract_number     -- _ñÔ
,     posts1.meaning                  po_req_status_name        -- wËXe[^X¼
,     prh.approved_date               po_req_approved_date      -- wË³Fú
,     NVL(xwrp.interface_flag,'N')    vdms_interface_flag       -- ©Ì@ÇSAgÏ
,     DECODE(NVL(xwrp.interface_flag,'N')
            ,'N'
            ,NULL
            ,TO_CHAR(xwrp.last_update_date,'yyyy/mm/dd hh24:mi:ss')
            )                         vdms_interface_datetime   -- ©Ì@ÇSAgú
,     ph.segment1                     po_number                 -- ­Ô
,     posts2.meaning                  po_status_name            -- ­Xe[^X¼
,     ph.approved_date                po_approved_date          -- ­³Fú
,     prlv.install_code               install_code              -- Ýup¨CD
,     prlv.withdraw_install_code      withdraw_install_code     -- øgp¨CD
,     prlv.abolishment_install_code   abolishment_install_code  -- püp¨CD
,     prh.creation_date               po_req_creation_date      -- wËì¬ú
,     xev.employee_number             employee_number           -- ì¬ÒCD
,     xev.full_name                   full_name                 -- ì¬Ò¼
,     (
       CASE
         WHEN   xev.issue_date > to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
         THEN   xev.work_base_code_old
         ELSE   xev.work_base_code_new
         END
      )                               work_base_code            -- ì¬Ò_CD
,     (
       /* 2010/03/15 t.maruyama E_{Ò®_01888 PTÎô start*/
       --SELECT  xab.base_name
       SELECT  /*+ use_concat*/
       /* 2010/03/15 t.maruyama E_{Ò®_01888 PTÎô end*/
               xab.base_name
       FROM    xxcso_aff_base_v xab
       WHERE   (
                 (    xev.issue_date > to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
                  AND xab.base_code = xev.work_base_code_old )
               OR        
                 (    xev.issue_date <= to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
                  AND xab.base_code = xev.work_base_code_new )
               )
      )                               work_base_name            -- ì¬Ò_¼
,     prh.authorization_status        po_req_h_auth_status      -- wËXe[^X
,     ph.authorization_status         po_h_auth_status          -- ­Xe[^X
,     prlv.requisition_line_id        requisition_line_id       -- wË¾×ID
,     flvv.attribute1                 category_kind             -- JeSíÊ
,     xcav.sale_base_code             sale_base_code            -- ãS_
,     prlv.po_req_ln_creation_date    po_req_ln_creation_date   -- wË¾×ì¬ú
,     prlv.category_id                category_id               -- JeSID
/* 2010/03/15 t.maruyama E_{Ò®_01888 PTÎô start*/
,     prlv.requisition_header_id      requisition_header_id     -- wËwb_ID
/* 2010/03/15 t.maruyama E_{Ò®_01888 PTÎô end*/
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
                ) sp_decision_number         --SPêÔ
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'INSTALL_AT_CUSTOMER_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) install_at_customer_code   --ÝuæÚqCD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_YEAR'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_year             --ìÆó]N
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_MONTH'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_month            --ìÆó]
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_DAY'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_day             --ìÆó]ú
        ,       prl.attribute1 install_code            --Ýu¨CD
        ,       prl.attribute2 withdraw_install_code   --øg¨CD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'ABOLISHMENT_INSTALL_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) abolishment_install_code   --pü¨CD
        ,       prl.creation_date            po_req_ln_creation_date --ì¬ú
        FROM    po_requisition_lines prl
      )                         prlv       -- wËîñ
,     po_requisition_headers prh           -- wËwb_
,     po_req_distributions prd             -- wËÀ
,     po_headers ph                        -- ­wb_
,     po_distributions pd                  -- ­À
,     xxcso_wk_requisition_proc xwrp       -- ìÆË^­îñAgÎÛe[u
,     mtl_categories_b mcb                 -- iÚJeS
,     fnd_lookup_values_vl flvv            -- QÆ^CviJeSj
,     fnd_lookup_values_vl posts1          -- QÆ^CviwËXe[^Xj
,     fnd_lookup_values_vl posts2          -- QÆ^Cvi­Xe[^Xj
,     xxcso_employees_v    xev             -- ]Æõr[
,     xxcso_cust_accounts_v xcav           -- Úq}X^r[
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

COMMENT ON TABLE XXCSO_011A02_HEADERS_V IS 'CSO_011_A02_wb_r[';