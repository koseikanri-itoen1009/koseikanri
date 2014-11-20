/*************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 * 
 * View Name       : XXCSO_RESOURCES_SECURITY_V
 * Description     : ���ʗp�F���\�[�X�Z�L�����e�B�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2013/10/03    1.0   S.Niki       ����쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCES_SECURITY_V
(
  base_code
, base_name
)
AS
SELECT base.base_code         -- ���_�R�[�h
     , base.base_name         -- ���_��
FROM
( SELECT DECODE( FND_PROFILE.VALUE('XXCSO1_RS_SECURITY_LEVEL') --XXCSO:���\�[�X�Z�L�����e�B���x��
               , '1', '1'  --�Z�L�����e�B����
               , '0'       --�Z�L�����e�B�Ȃ�
         )        security_type
  FROM   DUAL
) sec,
(
  --�Z�L�����e�B����i�����_�E�Ǘ����̏ꍇ�͔z���̋��_���j
  SELECT 1                 security_type
       , ffv.flex_value    base_code
       , ffv.attribute4    base_name
  FROM   jtf_rs_defresources_vl r
       , fnd_flex_value_sets    ffvs 
       , fnd_flex_values        ffv
       , fnd_flex_values_tl     ffvt
  WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
  AND    ffv.flex_value_id         = ffvt.flex_value_id
  AND    ffvt.language             = 'JA'
  AND    ffv.enabled_flag          = 'Y'
  AND    ffv.summary_flag          = 'N'
  AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
  AND    r.category                = 'EMPLOYEE'
  AND    r.user_id                 = FND_GLOBAL.USER_ID
  AND  ( xxcso_util_common_pkg.get_rs_base_code(
            r.resource_id
           ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
         )                         = ffv.flex_value
    OR    EXISTS ( SELECT 'X'
                   FROM   hz_cust_accounts    hca
                        , xxcmm_cust_accounts xca
                   WHERE  hca.cust_account_id      = xca.customer_id
                   AND    hca.account_number       = ffv.flex_value
                   AND    hca.customer_class_code  = '1'  -- �ڋq�敪�u1:���_�v
                   AND    xca.management_base_code = xxcso_util_common_pkg.get_rs_base_code(
                                                       r.resource_id
                                                     , TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                                     )
                 )
       )
  --
  UNION ALL
  --
  --�Z�L�����e�B�Ȃ��i�S���_�j
  SELECT 0                 security_type
       , ffv.flex_value    base_code
       , ffv.attribute4    base_name
  FROM   fnd_flex_value_sets    ffvs 
       , fnd_flex_values        ffv
       , fnd_flex_values_tl     ffvt
  WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
  AND    ffv.flex_value_id         = ffvt.flex_value_id
  AND    ffvt.language             = 'JA'
  AND    ffv.enabled_flag          = 'Y'
  AND    ffv.summary_flag          = 'N'
  AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
  AND    EXISTS ( SELECT 'X'
                  FROM   hz_cust_accounts    hca
                       , xxcmm_cust_accounts xca
                  WHERE  hca.cust_account_id      = xca.customer_id
                  AND    hca.account_number       = ffv.flex_value
                  AND    hca.customer_class_code  = '1'  -- �ڋq�敪�u1:���_�v
                )
) base
WHERE sec.security_type            = base.security_type
WITH READ ONLY
;
--
COMMENT ON COLUMN XXCSO_RESOURCES_SECURITY_V.base_code     IS '���_�R�[�h';
COMMENT ON COLUMN XXCSO_RESOURCES_SECURITY_V.base_name     IS '���_��';
--
COMMENT ON TABLE XXCSO_RESOURCES_SECURITY_V                IS '���ʗp�F���\�[�X�Z�L�����e�B�r���[';
