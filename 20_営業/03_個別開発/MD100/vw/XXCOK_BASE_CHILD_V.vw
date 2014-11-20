/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_BASE_CHILD_V
 * Description : �z�����_�r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/29    1.0   K.Yamaguchi      �V�K�쐬
 *  2009/09/09    1.1   S.Moriyama       [��Q0001304]���ߓ��̔�r���Ɩ��������t�֕ύX
 *
 **************************************************************************************/
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOK_BASE_CHILD_V" ("BASE_CODE", "BASE_NAME") AS 
  SELECT  ffvnh.child_flex_value_high AS base_code, -- ���_�R�[�h
          hca.account_name            AS base_name  -- ���_��
  FROM    fnd_flex_value_norm_hierarchy ffvnh,
          fnd_flex_values_vl ffvv,
          hz_cust_accounts hca
  WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                     FROM   fnd_flex_value_sets ffvs,
                                            fnd_flex_value_norm_hierarchy ffvnh
                                     WHERE  ffvs.flex_value_set_name    = 'XX03_DEPARTMENT'
                                     AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                     AND    ffvnh.child_flex_value_high =
-- 2009/09/09 Ver.1.1 [��Q0001304] SCS S.Moriyama UPD START
--                                                         xxcok_common_pkg.get_base_code_f( SYSDATE,fnd_global.user_id )
                                                         xxcok_common_pkg.get_base_code_f( xxccp_common_pkg2.get_process_date,fnd_global.user_id )
-- 2009/09/09 Ver.1.1 [��Q0001304] SCS S.Moriyama UPD END
                                    )
  AND     ffvv.value_category         = 'XX03_DEPARTMENT'
  AND     ffvnh.child_flex_value_high = ffvv.flex_value
  AND     hca.account_number          = ffvv.flex_value
  AND     hca.customer_class_code     = '1'
  ORDER BY ffvnh.child_flex_value_high
;
 