/*************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 * 
 * View Name       : XXCMM_ITEM_CHG_INFO_V
 * Description     : �ύX�\����r���[
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2017/06/22    1.0   S.Niki       E_�{�ғ�_14300 ����쐬
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW apps.xxcmm_item_chg_info_v(
   item_code            -- �i�ڃR�[�h
  ,apply_date           -- �K�p��
  ,item_status          -- �i�ڃX�e�[�^�X
  ,fixed_price          -- �艿
  ,discrete_cost        -- �c�ƌ���
  ,policy_group         -- ����Q
 )
 AS
   SELECT xsibh.item_code        AS item_code
         ,xsibh.apply_date       AS apply_date
         ,xsibh.item_status      AS item_status
         ,xsibh.fixed_price      AS fixed_price
         ,xsibh.discrete_cost    AS discrete_cost
         ,xsibh.policy_group     AS policy_group
     FROM xxcmm_system_items_b_hst xsibh
    WHERE xsibh.apply_flag   = 'N'  -- ���K�p
      AND NOT EXISTS (SELECT 'X'
                        FROM xxcmm_tmp_item_chg_upload wk
                       WHERE wk.item_code   = xsibh.item_code
                         AND wk.apply_date  = xsibh.apply_date
                         AND wk.status      = 'D'     -- �폜
          )
   UNION
   SELECT xticu.item_code        AS item_code
         ,xticu.apply_date       AS apply_date
         ,xticu.new_item_status  AS item_status
         ,NULL                   AS fixed_price
         ,xticu.discrete_cost    AS discrete_cost
         ,xticu.policy_group     AS policy_group
     FROM xxcmm_tmp_item_chg_upload xticu
    WHERE xticu.status       <> 'D'         -- �폜�ȊO
      AND xticu.apply_date   >= xxccp_common_pkg2.get_process_date
/
COMMENT ON TABLE apps.xxcmm_item_chg_info_v IS '�ύX�\����r���['
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.item_code         IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.apply_date        IS '�K�p��'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.item_status       IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.fixed_price       IS '�艿'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.discrete_cost     IS '�c�ƌ���'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.policy_group      IS '����Q'
/
