/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_headers_info_v
 * Description     : �[�i�`�[�w�b�_���r���[
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/08    1.0   T.Tyou           �V�K�쐬
 *  2009/04/09    1.1   K.kiriu          [T1_0248]�S�ݓXHHT�敪�ƕS�ݓX��ʎ�ʂ̕s�����C��
 *                                       [T1_0259]�[�i�҂̌����s���Ή�
 *  2009/06/03    1.2   K.Kiriu          [T1_1269]�p�t�H�[�}���X�Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dlv_headers_info_v
(
  order_no_hht,
  digestion_ln_number,
  order_no_ebs,
  base_code,
  performance_by_code,
  source_name,
  dlv_by_code,
  dlv_by_name,
  hht_invoice_no,
  dlv_date,
  inspect_date,
  sales_classification,
  sales_invoice,
  card_sale_class,
  card_sale_name,
  dlv_time,
  customer_number,
  customer_name,
  input_class,
  input_name,
  consumption_tax_class,
  abs_total_amount,
  total_amount,
  abs_sale_discount_amount,
  sale_discount_amount,
  abs_sales_consumption_tax,
  sales_consumption_tax,
  abs_tax_include,
  tax_include,
  keep_in_code,
  department_screen_class,
  department_screen_name,
  red_black_flag,
  customer_status,
  employee_number,
  business_low_type,
  change_out_time_100,
  change_out_time_10,
  stock_forward_flag,
  stock_forward_date,
  results_forward_flag,
  results_forward_date,
  cancel_correct_class,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  request_id,
  program_application_id,
  program_id,
  program_update_date,
  customer_id
  ,party_id
  ,resource_id
)
AS
SELECT
       xdh.order_no_hht order_no_hht,                              --��No.�iHHT)
       xdh.digestion_ln_number digestion_ln_number,                --�}��
       xdh.order_no_ebs order_no_ebs,                              --��No.�iEBS�j
       xdh.base_code base_code,                                    --���_�R�[�h
       xdh.performance_by_code performance_by_code,                --���ю҃R�[�h
       papf.per_information18||' '||papf.per_information19 source_name,                             --���юҖ���
       xdh.dlv_by_code dlv_by_code,                                --�[�i�҃R�[�h
/* 2009/04/09 Ver1.9 Mod Start */
--       xsv.kanji_last || ' ' || xsv.kanji_first dlv_by_name,       --�[�i�Җ���
       papf_dlv.per_information18||' '||papf_dlv.per_information19 dlv_by_name,                     --�[�i�Җ���
/* 2009/04/09 Ver1.9 Mod End   */
       xdh.hht_invoice_no hht_invoice_no,                          --�`�[No.
       xdh.dlv_date dlv_date,                                      --�[�i��
       xdh.inspect_date inspect_date,                              --������
       xdh.sales_classification sales_classification,              --���㕪�ދ敪
       xdh.sales_invoice sales_invoice,                            --����`�[�敪
       xdh.card_sale_class card_sale_class,                        --�J�[�h���敪
       csc.meaning card_sale_name,                                 --�J�[�h���敪�\���p
       xdh.dlv_time dlv_time,                                      --����
       xdh.customer_number customer_number,                        --�ڋq�R�[�h
       xsv.party_name customer_name ,                              --�ڋq����
       xdh.input_class input_class,                                --���͋敪
       ic.meaning input_name,                                      --���͋敪�\���p
       xdh.consumption_tax_class consumption_tax_class,            --����ŋ敪
       abs( xdh.total_amount ) abs_total_amount,                   --���v���z�i��ʗp:��Βl�j
       xdh.total_amount total_amount,                              --���v���z�iDB�l�j
       abs( xdh.sale_discount_amount ) abs_sale_discount_amount,   --����l�����z�i��ʗp:��Βl�j
       xdh.sale_discount_amount sale_discount_amount,              --����l�����z�iDB�l�j
       abs( xdh.sales_consumption_tax ) abs_sales_consumption_tax, --�������Ŋz�i��ʗp:��Βl�j
       xdh.sales_consumption_tax sales_consumption_tax,            --�������Ŋz�iDB�l�j
       abs( xdh.tax_include ) abs_tax_include,                     --�ō����z�i��ʗp:��Βl�j
       xdh.tax_include tax_include,                                --�ō����z�iDB�l�j
       xdh.keep_in_code keep_in_code,                              --�a����R�[�h
       xdh.department_screen_class department_screen_class,        --�S�ݓX��ʎ��
       dsc.meaning department_screen_name,                         --�S�ݓX��ʎ�ʕ\���p
       xdh.red_black_flag red_black_flag,                          --�ԍ��t���O
       hp.duns_number_c customer_status,                           --�ڋq�X�e�[�^�X
       xsv.employee_number employee_number,                        --�c�ƈ��R�[�h
       custadd.business_low_type business_low_type,                --�Ƒԏ�����
       xdh.change_out_time_100 change_out_time_100,                --��K�؂ꎞ��100�~
       xdh.change_out_time_10 change_out_time_10,                  --��K�؂ꎞ��10�~
       xdh.stock_forward_flag stock_forward_flag,                  --���o�ɓ]���σt���O
       xdh.stock_forward_date stock_forward_date,                  --���o�ɓ]���ϓ��t
       xdh.results_forward_flag results_forward_flag,              --�̔����јA�g�σt���O
       xdh.results_forward_date results_forward_date,              --�̔����јA�g�ϓ��t
       xdh.cancel_correct_class cancel_correct_class,              --����E�����敪
       xdh.created_by,
       xdh.creation_date,
       xdh.last_updated_by,
       xdh.last_update_date,
       xdh.last_update_login,
       xdh.request_id,
       xdh.program_application_id,
       xdh.program_id,
       xdh.program_update_date
       ,custadd.customer_id customer_id                            --���ׂ̃R����NO�����̂���
       ,xsv.party_id
       ,xsv.resource_id
FROM
       xxcos_dlv_headers    xdh,                                  --�[�i�w�b�_�e�[�u��
       xxcmm_cust_accounts  custadd,                              --�ڋq�A�h�I��
       xxcos_salesreps_v    xsv,                                  --�S���҉c�ƈ��r���[(�ڋq�֘A)
       hz_parties           hp,                                   --party
       per_all_people_f     papf,                                 --�]�ƈ��}�X�^
/* 2009/04/09 Ver1.9 Add Start */
       per_all_people_f     papf_dlv,                             --�]�ƈ��}�X�^(�[�i��)
/* 2009/04/09 Ver1.9 Add End   */
       (
       --�J�[�h���敪
/* 2009/06/03 Ver1.2 Mod Start */
--       SELECT look_val.lookup_code lookup_code
--             ,look_val.meaning meaning
--       FROM    fnd_lookup_values     look_val,
--               fnd_lookup_types_tl   types_tl,
--               fnd_lookup_types      types,
--               fnd_application_tl    appl,
--               fnd_application       app
--       WHERE   appl.application_id   = types.application_id
--       AND     look_val.language     = 'JA'
--       AND     appl.language         = 'JA'
--       AND     types_tl.lookup_type  = look_val.lookup_type
--       AND     app.application_id    = appl.application_id
--       AND     look_val.lookup_type = 'XXCOS1_CARD_SALE_CLASS'
--       AND     app.application_short_name = 'XXCOS'
--       AND     types.lookup_type = types_tl.lookup_type
--       AND     types.security_group_id = types_tl.security_group_id
--       AND     types.view_application_id = types_tl.view_application_id
--       AND     types_tl.language = userenv('LANG')
--       AND     look_val.attribute1 = 'Y'
--       AND     xxccp_common_pkg2.get_process_date      >= 
--         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--       AND     xxccp_common_pkg2.get_process_date      <= 
--         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       AND     look_val.enabled_flag = 'Y'
--       ORDER BY look_val.lookup_code]
       SELECT  xlvv.lookup_code        lookup_code
              ,xlvv.meaning            meaning
              ,xlvv.start_date_active  start_date_active
              ,xlvv.end_date_active    end_date_active
       FROM    xxcos_lookup_values_v  xlvv
       WHERE   xlvv.lookup_type    = 'XXCOS1_CARD_SALE_CLASS'
       AND     xlvv.attribute1     = 'Y'
/* 2009/06/03 Ver1.2 Mod End   */
       ) csc,
       (
       --���͋敪
/* 2009/06/03 Ver1.2 Mod Start */
--       SELECT look_val.lookup_code lookup_code
--             ,look_val.meaning meaning
--       FROM    fnd_lookup_values     look_val,
--               fnd_lookup_types_tl   types_tl,
--               fnd_lookup_types      types,
--               fnd_application_tl    appl,
--               fnd_application       app
--       WHERE   appl.application_id   = types.application_id
--       AND     look_val.language     = 'JA'
--       AND     appl.language         = 'JA'
--       AND     types_tl.lookup_type  = look_val.lookup_type
--       AND     app.application_id    = appl.application_id
--       AND     look_val.lookup_type = 'XXCOS1_INPUT_CLASS'
--       AND     app.application_short_name = 'XXCOS'
--       AND     types.lookup_type = types_tl.lookup_type
--       AND     types.security_group_id = types_tl.security_group_id
--       AND     types.view_application_id = types_tl.view_application_id
--       AND     types_tl.language = userenv('LANG')
--       AND     look_val.attribute1 = 'Y'
--       AND     xxccp_common_pkg2.get_process_date      >= 
--         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--       AND     xxccp_common_pkg2.get_process_date      <= 
--         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       AND     look_val.enabled_flag = 'Y'
--       ORDER BY look_val.lookup_code
       SELECT  xlvv.lookup_code        lookup_code
              ,xlvv.meaning            meaning
              ,xlvv.start_date_active  start_date_active
              ,xlvv.end_date_active    end_date_active
       FROM    xxcos_lookup_values_v  xlvv
       WHERE   xlvv.lookup_type = 'XXCOS1_INPUT_CLASS'
       AND     xlvv.attribute1  = 'Y'
/* 2009/06/03 Ver1.2 Mod End   */
       ) ic,                                                      
       (
       --�S�ݓX��ʎ��
/* 2009/06/03 Ver1.2 Mod Start */
--       SELECT look_val.lookup_code lookup_code
--             ,look_val.meaning meaning
--       FROM    fnd_lookup_values     look_val,
--               fnd_lookup_types_tl   types_tl,
--               fnd_lookup_types      types,
--               fnd_application_tl    appl,
--               fnd_application       app
--       WHERE   appl.application_id   = types.application_id
--       AND     look_val.language     = 'JA'
--       AND     appl.language         = 'JA'
--       AND     types_tl.lookup_type  = look_val.lookup_type
--       AND     app.application_id    = appl.application_id
--       AND     look_val.lookup_type = 'XXCOS1_DEPARTMENT_SCREEN_CLASS'
--       AND     app.application_short_name = 'XXCOS'
--       AND     types.lookup_type = types_tl.lookup_type
--       AND     types.security_group_id = types_tl.security_group_id
--       AND     types.view_application_id = types_tl.view_application_id
--       AND     types_tl.language = userenv('LANG')
/* 2009/04/09 Ver1.1 Del Start */
--       AND     look_val.attribute2 = 'Y'
/* 2009/04/09 Ver1.1 Del End   */
--       AND     xxccp_common_pkg2.get_process_date      >= 
--         NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--       AND     xxccp_common_pkg2.get_process_date      <= 
--         NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       AND     look_val.enabled_flag = 'Y'
/* 2009/04/09 Ver1.1 Del Start */
--       ORDER BY look_val.lookup_code
/* 2009/04/09 Ver1.1 Del End   */
--       ) dsc
       SELECT  xlvv.lookup_code        lookup_code
              ,xlvv.meaning            meaning
              ,xlvv.start_date_active  start_date_active
              ,xlvv.end_date_active    end_date_active
       FROM    xxcos_lookup_values_v  xlvv
       WHERE   xlvv.lookup_type = 'XXCOS1_DEPARTMENT_SCREEN_CLASS'
       ) dsc,
/* 2009/06/03 Ver1.2 Mod End   */
/* 2009/06/03 Ver1.2 Add Start */
       (
       --�c�Ɠ�
       SELECT xxccp_common_pkg2.get_process_date process_date
       FROM   DUAL
       ) pd
/* 2009/06/03 Ver1.2 Add End   */
WHERE  xdh.customer_number = xsv.account_number
AND    xsv.cust_account_id = custadd.customer_id 
AND    hp.party_id         = xsv.party_id
/* 2009/04/09 Ver1.1 Del Start */
--AND    xdh.dlv_by_code     = xsv.employee_number   --2009/01/09�ǉ�
/* 2009/04/09 Ver1.1 Del End   */
/* 2009/06/03 Ver1.2 Mod Start   */
--AND    (xdh.dlv_date >=  
--  NVL(xsv.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    xdh.dlv_date <=  
--  NVL(xsv.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--OR
--       add_months( xdh.dlv_date, -1 ) >=  
--       NVL(xsv.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    add_months( xdh.dlv_date, -1 ) <=  
--       NVL(xsv.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
--       )
--AND    xdh.card_sale_class = csc.lookup_code(+)
--AND    xdh.input_class IN (
--        ic.lookup_code
--       )
AND    (
         xdh.dlv_date >=
           NVL( xsv.effective_start_date, FND_DATE.STRING_TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
         AND
         xdh.dlv_date <=  
           NVL( xsv.effective_end_date, FND_DATE.STRING_TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
       OR
         add_months( xdh.dlv_date, -1 ) >=  
           NVL( xsv.effective_start_date, FND_DATE.STRING_TO_DATE( '1900/01/01', 'YYYY/MM/DD' ) )
         AND
         add_months( xdh.dlv_date, -1 ) <=  
           NVL( xsv.effective_end_date, FND_DATE.STRING_TO_DATE( '9999/12/31', 'YYYY/MM/DD' ) )
       )
AND    xdh.card_sale_class  = csc.lookup_code
AND    pd.process_date     >= NVL(csc.start_date_active, pd.process_date)
AND    pd.process_date     <= NVL(csc.end_date_active, pd.process_date)
AND    xdh.input_class      = ic.lookup_code
AND    pd.process_date     >= NVL(ic.start_date_active, pd.process_date)
AND    pd.process_date     <= NVL(ic.end_date_active, pd.process_date)
/* 2009/06/03 Ver1.2 Mod End   */
/* 2009/04/09 Ver1.1 Mod Start */
--AND  ( xdh.department_screen_class IS NULL    --2009/02/06�ǉ� �d�l�ύX�̂���
--       OR
--       xdh.department_screen_class IN (
--         dsc.lookup_code
--       )
--     )
AND    xdh.department_screen_class = dsc.lookup_code
/* 2009/04/09 Ver1.1 Mod End   */
/* 2009/06/03 Ver1.2 Add Start */
AND    pd.process_date     >= NVL(dsc.start_date_active, pd.process_date)
AND    pd.process_date     <= NVL(dsc.end_date_active, pd.process_date)
/* 2009/06/03 Ver1.2 Add End   */
/* 2009/04/09 Ver1.1 Add Start */
AND    xdh.dlv_by_code     = papf_dlv.employee_number
/* 2009/06/03 Ver1.2 Mod Start */
--AND    xdh.dlv_date >=
--  NVL(papf_dlv.effective_start_date, FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    xdh.dlv_date <=
--  NVL(papf_dlv.effective_end_date, FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
AND    xdh.dlv_date        >= papf_dlv.effective_start_date
AND    xdh.dlv_date        <= papf_dlv.effective_end_date
/* 2009/06/03 Ver1.2 Mod End   */
/* 2009/04/09 Ver1.1 Add End   */
AND    xdh.performance_by_code = papf.employee_number    --2009/01/09�ύX �[�i�ҁ[�����ю�
/* 2009/06/03 Ver1.2 Mod Start */
--AND    xdh.dlv_date >=
--  NVL(papf.effective_start_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
--AND    xdh.dlv_date <=
--  NVL(papf.effective_end_date,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
AND    xdh.dlv_date            >= papf.effective_start_date
AND    xdh.dlv_date            <= papf.effective_end_date
/* 2009/06/03 Ver1.2 Mod End   */
;
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.order_no_hht                IS  '��No.(HHT)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.digestion_ln_number         IS  '�}��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.order_no_ebs                IS  '��No.(EBS)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.base_code                   IS  '���_�R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.performance_by_code         IS  '���ю҃R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.source_name                 IS  '���юҖ���';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_by_code                 IS  '�[�i�҃R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_by_name                 IS  '�[�i�Җ���';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.hht_invoice_no              IS  '�`�[No.';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_date                    IS  '�[�i��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.inspect_date                IS  '������';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_classification        IS  '���㕪�ދ敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_invoice               IS  '����`�[�敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.card_sale_class             IS  '�J�[�h���敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.card_sale_name              IS  '�J�[�h���敪�\���p';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.dlv_time                    IS  '����';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_number             IS  '�ڋq�R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_name               IS  '�ڋq����';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.input_class                 IS  '���͋敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.input_name                  IS  '���͋敪�\���p';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.consumption_tax_class       IS  '����ŋ敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_total_amount            IS  '���v���z(��ʗp:��Βl)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.total_amount                IS  '���v���z(DB�l)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_sale_discount_amount    IS  '����l�����z(��ʗp:��Βl)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sale_discount_amount        IS  '����l�����z(DB�l)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_sales_consumption_tax   IS  '�������Ŋz(��ʗp:��Βl)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.sales_consumption_tax       IS  '�������Ŋz(DB�l)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.abs_tax_include             IS  '�ō����z(��ʗp:��Βl)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.tax_include                 IS  '�ō����z(DB�l)';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.keep_in_code                IS  '�a����R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.department_screen_class     IS  '�S�ݓX��ʎ��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.department_screen_name      IS  '�S�ݓX��ʎ�ʕ\���p';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.red_black_flag              IS  '�ԍ��t���O';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_status             IS  '�ڋq�X�e�[�^�X';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.employee_number             IS  '�c�ƈ��R�[�h';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.business_low_type           IS  '�Ƒԏ�����';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.change_out_time_100         IS  '��K�؂ꎞ��100�~';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.change_out_time_10          IS  '��K�؂ꎞ��10�~';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.stock_forward_flag          IS  '���o�ɓ]���σt���O';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.stock_forward_date          IS  '���o�ɓ]���ϓ��t';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.results_forward_flag        IS  '�̔����јA�g�σt���O';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.results_forward_date        IS  '�̔����јA�g�ϓ��t';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.cancel_correct_class        IS  '����E�����敪';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.created_by                  IS  '�쐬��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.creation_date               IS  '�쐬��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_updated_by             IS  '�ŏI�X�V��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_update_date            IS  '�ŏI�X�V��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.last_update_login           IS  '�ŏI�X�V���O�C��';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.request_id                  IS  '�v��ID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_application_id      IS  '�R���J�����g�E�v���O�����A�v���P�[�V����ID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_id                  IS  '�R���J�����g�E�v���O����ID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.program_update_date         IS  '�v���O�����X�V��'; 
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.customer_id                 IS  '�ڋqID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.party_id                    IS  '�p�[�e�BID';
COMMENT ON  COLUMN  xxcos_dlv_headers_info_v.resource_id                 IS  '���\�[�XID';
--
COMMENT ON  TABLE   xxcos_dlv_headers_info_v                             IS  '�[�i�`�[�w�b�_���r���[';
