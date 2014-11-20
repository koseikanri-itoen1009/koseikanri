/*************************************************************************
 * 
 * VIEW Name       : xxcso_011a02_headers_v
 * Description     : CSO_011_A02_��ƈ˗��^�����˗�������ʃw�b�_�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/12/22    1.0  T.Maruyama    ����쐬
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
      prh.segment1                    po_req_number             -- �w���˗��ԍ�
,     mcb.segment1                    category_name             -- �J�e�S����
,     DECODE(   prlv.work_hope_year
              || prlv.work_hope_month
              || prlv.work_hope_day
             ,NULL
             ,NULL
             ,  prlv.work_hope_year 
              || '/' || prlv.work_hope_month 
              || '/' || prlv.work_hope_day
                                 )    work_hope_date            -- ��Ɗ�]��
,     prlv.install_at_customer_code   install_at_customer_code  -- �ڋqCD
,     xcav.party_name                 party_name                -- �ڋq��
,     prlv.sp_decision_number         sp_decision_number        -- SP�ꌈ�ԍ�
,     (
       SELECT distinct first_value(xcm.contract_number)  --�i�ŐV�̊m��ό_��No�j
                       over(partition by xcm.sp_decision_header_id 
                                      order by xcm.last_update_date desc, xcm.contract_management_id desc)
              AS final_contract_number
       FROM   xxcso_contract_managements xcm
       ,      xxcso_sp_decision_headers  xsdh
       WHERE  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
       AND    xsdh.sp_decision_number   = prlv.sp_decision_number
       AND    xcm.status                = '1'  --�m���
      )                               final_contract_number     -- �_�񏑔ԍ�
,     posts1.meaning                  po_req_status_name        -- �w���˗��X�e�[�^�X��
,     prh.approved_date               po_req_approved_date      -- �w���˗����F��
,     NVL(xwrp.interface_flag,'N')    vdms_interface_flag       -- ���̋@�Ǘ�S�A�g��
,     DECODE(NVL(xwrp.interface_flag,'N')
            ,'N'
            ,NULL
            ,TO_CHAR(xwrp.last_update_date,'yyyy/mm/dd hh24:mi:ss')
            )                         vdms_interface_datetime   -- ���̋@�Ǘ�S�A�g��
,     ph.segment1                     po_number                 -- �����ԍ�
,     posts2.meaning                  po_status_name            -- �����X�e�[�^�X��
,     ph.approved_date                po_approved_date          -- �������F��
,     prlv.install_code               install_code              -- �ݒu�p����CD
,     prlv.withdraw_install_code      withdraw_install_code     -- ���g�p����CD
,     prlv.abolishment_install_code   abolishment_install_code  -- �p���p����CD
,     prh.creation_date               po_req_creation_date      -- �w���˗��쐬��
,     xev.employee_number             employee_number           -- �쐬��CD
,     xev.full_name                   full_name                 -- �쐬�Җ�
,     (
       CASE
         WHEN   xev.issue_date > to_char(xxcso_util_common_pkg.get_online_sysdate, 'yyyymmdd')
         THEN   xev.work_base_code_old
         ELSE   xev.work_base_code_new
         END
      )                               work_base_code            -- �쐬�ҋ��_CD
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
      )                               work_base_name            -- �쐬�ҋ��_��
,     prh.authorization_status        po_req_h_auth_status      -- �w���˗��X�e�[�^�X
,     ph.authorization_status         po_h_auth_status          -- �����X�e�[�^�X
,     prlv.requisition_line_id        requisition_line_id       -- �w���˗�����ID
,     flvv.attribute1                 category_kind             -- �J�e�S�����
,     xcav.sale_base_code             sale_base_code            -- ����S�����_
,     prlv.po_req_ln_creation_date    po_req_ln_creation_date   -- �w���˗����׍쐬��
,     prlv.category_id                category_id               -- �J�e�S��ID
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
                ) sp_decision_number         --SP�ꌈ�ԍ�
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'INSTALL_AT_CUSTOMER_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) install_at_customer_code   --�ݒu��ڋqCD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_YEAR'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_year             --��Ɗ�]�N
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_MONTH'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_month            --��Ɗ�]��
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'WORK_HOPE_DAY'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) work_hope_day             --��Ɗ�]��
        ,       prl.attribute1 install_code            --�ݒu����CD
        ,       prl.attribute2 withdraw_install_code   --���g����CD
        ,       (SELECT  pti.attribute_value
                 FROM por_template_info pti, por_template_attributes_v  ptav
                 WHERE pti.requisition_line_id = prl.requisition_line_id
                 AND ptav.attribute_name     = 'ABOLISHMENT_INSTALL_CODE'
                 AND ptav.node_display_flag  = 'Y'
                 AND pti.attribute_code      = ptav.attribute_code
                 AND pti.attribute_value  IS NOT NULL
                ) abolishment_install_code   --�p������CD
        ,       prl.creation_date            po_req_ln_creation_date --�쐬��
        FROM    po_requisition_lines prl
      )                         prlv       -- �w���˗����
,     po_requisition_headers prh           -- �w���˗��w�b�_
,     po_req_distributions prd             -- �w���˗�����
,     po_headers ph                        -- �����w�b�_
,     po_distributions pd                  -- ��������
,     xxcso_wk_requisition_proc xwrp       -- ��ƈ˗��^�������A�g�Ώۃe�[�u��
,     mtl_categories_b mcb                 -- �i�ڃJ�e�S��
,     fnd_lookup_values_vl flvv            -- �Q�ƃ^�C�v�i�J�e�S���j
,     fnd_lookup_values_vl posts1          -- �Q�ƃ^�C�v�i�w���˗��X�e�[�^�X�j
,     fnd_lookup_values_vl posts2          -- �Q�ƃ^�C�v�i�����X�e�[�^�X�j
,     xxcso_employees_v    xev             -- �]�ƈ��r���[
,     xxcso_cust_accounts_v xcav           -- �ڋq�}�X�^�r���[
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

COMMENT ON TABLE XXCSO_011A02_HEADERS_V IS 'CSO_011_A02_�w�b�_�r���[';