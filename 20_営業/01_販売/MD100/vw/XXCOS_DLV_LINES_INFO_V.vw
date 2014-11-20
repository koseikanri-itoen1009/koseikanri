/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_lines_info_v
 * Description     : �[�i�`�[���׏��r���[
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/08    1.0   T.Tyou           �V�K�쐬
 *  2009/02/18    1.1   T.Tyou           ��NO�iEBS�j��ǉ�
 *  2009/05/28    1.2   K.Kiriu          [T1_1119]���הԍ�(EBS)��ǉ�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dlv_lines_info_v (
  order_no_hht
 ,line_no_hht
 ,digestion_ln_number
 ,column_no
 ,h_and_c
 ,h_and_c_name
 ,item_code_self
 ,item_name
 ,abs_case_number
 ,case_number
 ,abs_quantity
 ,quantity
 ,sale_class
 ,sale_name
 ,abs_wholesale_unit_ploce
 ,wholesale_unit_ploce
 ,abs_selling_price
 ,selling_price
 ,abs_replenish_number
 ,replenish_number
 ,abs_cash_and_card
 ,cash_and_card
 ,inventory_quantity
 ,content
 ,baracha_div
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
 ,request_id
 ,program_application_id
 ,program_id
 ,program_update_date
 ,sold_out_class
 ,sold_out_time
 ,inventory_item_id
 ,standard_unit
 ,order_no_ebs
/* 2009/05/28 Ver1.2 Add Start */
 ,line_number_ebs
/* 2009/05/28 Ver1.2 Add End   */
 )
AS
SELECT
       xdl.order_no_hht order_no_hht,                              --��No.�iHHT)
       xdl.line_no_hht line_no_hht,                                --�sNo.
       xdl.digestion_ln_number digestion_ln_number,                --�}��
       xdl.column_no column_no,                                    --�R����No.
       xdl.h_and_c h_and_c,                                        --H/C
       hac.meaning h_and_c_name,                                   --H/C����
       xdl.item_code_self item_code_self,                          --�i���R�[�h
       cmn_mst.item_name,                                          --�i�ځi���́j
       abs( xdl.case_number ) abs_case_number,                     --�P�[�X���i��ʗp:��Βl�j
       xdl.case_number case_number,                                --�P�[�X���iDB�l�j
       abs( xdl.quantity ) abs_quantity,                           --���ʁi��ʗp:��Βl�j
       xdl.quantity quantity,                                      --���ʁiDB�l�j
       xdl.sale_class sale_class,                                  --����敪
       sc.meaning  sale_name,                                      --����敪(����)
       abs( xdl.wholesale_unit_ploce ) abs_wholesale_unit_ploce,   --���P���i��ʗp:��Βl�j
       xdl.wholesale_unit_ploce wholesale_unit_ploce,              --���P���iDB�l�j
       abs( xdl.selling_price ) abs_selling_price,                 --���P���i��ʗp:��Βl�j
       xdl.selling_price selling_price,                            --���P���iDB�l�j
       abs(xdl.replenish_number) abs_replenish_number,             --��[���i��ʗp:��Βl�j
       xdl.replenish_number replenish_number,                      --��[���iDB�l�j
       abs(xdl.cash_and_card) abs_cash_and_card,                   --�����E�J�[�h���p�z�i��ʗp:��Βl�j
       xdl.cash_and_card cash_and_card,                            --�����E�J�[�h���p�z�iDB�l�j
       CASE WHEN xdh.dlv_date < xxccp_common_pkg2.get_process_date THEN
         xmvc.last_month_inventory_quantity
       ELSE
         xmvc.inventory_quantity
       END inventory_quantity,                                     --��݌ɐ�
       xdl.content content,                                        --����
       cmm_item.baracha_div,                                       --�o�����敪
       xdl.created_by,
       xdl.creation_date,
       xdl.last_updated_by,
       xdl.last_update_date,
       xdl.last_update_login,
       xdl.request_id,
       xdl.program_application_id,
       xdl.program_id,
       xdl.program_update_date,
       xdl.sold_out_class,                                         --���؋敪
       xdl.sold_out_time,                                          --���؎���
       xdl.inventory_item_id,                                      --�i��ID
       xdl.standard_unit,                                          --��P��
       xdl.order_no_ebs order_no_ebs,                              --��No.�iEBS�j
/* 2009/05/28 Ver1.2 Add Start */
       xdl.line_number_ebs                                         --���הԍ�(EBS)
/* 2009/05/28 Ver1.2 Add End   */
FROM
       xxcos_dlv_lines       xdl,                             --�[�i���׃e�[�u��
       xxcos_dlv_headers     xdh,                             --�[�i�w�b�_�e�[�u��
       mtl_system_items_b    mtl_item,
       ic_item_mst_b         ic_item,
       xxcmm_system_items_b  cmm_item,
       xxcmn_item_mst_b      cmn_mst,
       (
       --����敪
       SELECT look_val.lookup_code lookup_code
             ,look_val.meaning meaning
       FROM    fnd_lookup_values     look_val,
               fnd_lookup_types_tl   types_tl,
               fnd_lookup_types      types,
               fnd_application_tl    appl,
               fnd_application       app
       WHERE   appl.application_id   = types.application_id
       AND     look_val.language     = 'JA'
       AND     appl.language         = 'JA'
       AND     types_tl.lookup_type  = look_val.lookup_type
       AND     app.application_id    = appl.application_id
       AND     look_val.lookup_type = 'XXCOS1_SALE_CLASS'
       AND     app.application_short_name = 'XXCOS'
       AND     types.lookup_type = types_tl.lookup_type
       AND     types.security_group_id = types_tl.security_group_id
       AND     types.view_application_id = types_tl.view_application_id
       AND     types_tl.language = userenv('LANG')
       AND     xxccp_common_pkg2.get_process_date      >= 
         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
       AND     xxccp_common_pkg2.get_process_date      <= 
         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
       AND     look_val.enabled_flag = 'Y'
       ORDER BY look_val.lookup_code
       ) sc,
       (
       --H/C�敪
       SELECT look_val.lookup_code lookup_code
             ,look_val.meaning meaning
       FROM    fnd_lookup_values     look_val,
               fnd_lookup_types_tl   types_tl,
               fnd_lookup_types      types,
               fnd_application_tl    appl,
               fnd_application       app
       WHERE   appl.application_id   = types.application_id
       AND     look_val.language     = 'JA'
       AND     appl.language         = 'JA'
       AND     types_tl.lookup_type  = look_val.lookup_type
       AND     app.application_id    = appl.application_id
       AND     look_val.lookup_type = 'XXCOS1_HC_CLASS'
       AND     app.application_short_name = 'XXCOS'
       AND     types.lookup_type = types_tl.lookup_type
       AND     types.security_group_id = types_tl.security_group_id
       AND     types.view_application_id = types_tl.view_application_id
       AND     types_tl.language = userenv('LANG')
       AND     look_val.attribute1 = 'Y'
       AND     xxccp_common_pkg2.get_process_date      >= 
         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
       AND     xxccp_common_pkg2.get_process_date      <= 
         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
       AND     look_val.enabled_flag = 'Y'
       ORDER BY look_val.lookup_code
       ) hac,
       xxcoi_mst_vd_column    xmvc
       , hz_cust_accounts     cust                                                                                            
WHERE  xdl.order_no_hht = xdh.order_no_hht
AND    xdl.digestion_ln_number = xdh.digestion_ln_number
AND    xdl.h_and_c = hac.lookup_code(+)
AND    xdl.sale_class IN (
        sc.lookup_code
       )
AND    xdl.item_code_self = ic_item.item_no
AND    mtl_item.organization_id =  
       xxcoi_common_pkg.get_organization_id( FND_PROFILE.VALUE(  'XXCOI1_ORGANIZATION_CODE' ) )
AND    mtl_item.segment1          = ic_item.item_no
AND    ic_item.item_id            = cmn_mst.item_id
AND    mtl_item.segment1 = cmm_item.item_code
AND    ic_item.item_id            = cmm_item.item_id
AND    cmn_mst.start_date_active  <= xxccp_common_pkg2.get_process_date
AND    cmn_mst.end_date_active    >= xxccp_common_pkg2.get_process_date
AND    xdh.customer_number        = cust.account_number  
AND    cust.cust_account_id       = nvl(xmvc.customer_id, cust.cust_account_id)
AND    xdl.column_no              = xmvc.column_no(+)
;
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ORDER_NO_HHT              IS '��No.�iHHT)';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LINE_NO_HHT               IS '�sNo.';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.DIGESTION_LN_NUMBER       IS '�}��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.COLUMN_NO                 IS '�R����No.';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.H_AND_C                   IS 'H/C';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.H_AND_C_NAME              IS 'H/C����';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ITEM_CODE_SELF            IS '�i���R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ITEM_NAME                 IS '�i�ځi���́j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_CASE_NUMBER           IS '�P�[�X���i��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CASE_NUMBER               IS '�P�[�X���iDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_QUANTITY              IS '���ʁi��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.QUANTITY                  IS '���ʁiDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SALE_CLASS                IS '����敪';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SALE_NAME                 IS '����敪(����)';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_WHOLESALE_UNIT_PLOCE  IS '���P���i��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.WHOLESALE_UNIT_PLOCE      IS '���P���iDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_SELLING_PRICE         IS '���P���i��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SELLING_PRICE             IS '���P���iDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_REPLENISH_NUMBER      IS '��[���i��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.REPLENISH_NUMBER          IS '��[���iDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ABS_CASH_AND_CARD         IS '�����E�J�[�h���p�z�i��ʗp:��Βl�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CASH_AND_CARD             IS '�����E�J�[�h���p�z�iDB�l�j';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.INVENTORY_QUANTITY        IS '��݌ɐ�';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CONTENT                   IS '����';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.BARACHA_DIV               IS '�o�����敪';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CREATED_BY                IS '�쐬��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.CREATION_DATE             IS '�쐬��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATED_BY           IS '�ŏI�X�V��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATE_DATE          IS '�ŏI�X�V��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LAST_UPDATE_LOGIN         IS '�ŏI�X�V���O�C��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.REQUEST_ID                IS '�v��ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_APPLICATION_ID    IS '�R���J�����g�E�v���O�����A�v���P�[�V����ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_ID                IS '�R���J�����g�E�v���O����ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.PROGRAM_UPDATE_DATE       IS '�v���O�����X�V��'; 
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SOLD_OUT_CLASS            IS '���؋敪';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.SOLD_OUT_TIME             IS '���؎���';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.INVENTORY_ITEM_ID         IS '�i��ID';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.STANDARD_UNIT             IS '��P��';
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.ORDER_NO_EBS              IS '��No.�iEBS�j';
/* 2009/05/28 Ver1.2 Add Start */
COMMENT ON  COLUMN  xxcos_dlv_lines_info_v.LINE_NUMBER_EBS           IS '���הԍ�(EBS)';
/* 2009/05/28 Ver1.2 Add End   */
--
COMMENT ON  TABLE   xxcos_dlv_lines_info_v                           IS '�[�i�`�[���׏��r���[';
