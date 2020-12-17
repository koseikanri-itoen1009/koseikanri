CREATE OR REPLACE PACKAGE xxcok_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : xxcok_common2_pkg(spec)
 * Description      : �ʊJ���̈�E���ʊ֐�
 * MD.070           : MD070_IPO_COK_���ʊ֐�
 * Version          : 1.1
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  calculate_deduction_amount_p �T���z�Z�o
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/01/08    1.0   SCSK Y.Koh       [E_�{�ғ�_16026] ���v�F�� (�V�K�쐬)
 *  2020/12/04    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
 *  
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���^
  -- ===============================

  --���ʊ֐��v���V�[�W���E�T���z�Z�o
  PROCEDURE calculate_deduction_amount_p(
    ov_errbuf                           OUT VARCHAR2        -- �G���[�o�b�t�@
  , ov_retcode                          OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errmsg                           OUT VARCHAR2        -- �G���[���b�Z�[�W
  , iv_item_code                        IN  VARCHAR2        -- �i�ڃR�[�h
  , iv_sales_uom_code                   IN  VARCHAR2        -- �̔��P��
  , in_sales_quantity                   IN  NUMBER          -- �̔�����
  , in_sale_pure_amount                 IN  NUMBER          -- ����{�̋��z
  , iv_tax_code_trn                     IN  VARCHAR2        -- �ŃR�[�h(TRN)
  , in_tax_rate_trn                     IN  NUMBER          -- �ŗ�(TRN)
  , iv_deduction_type                   IN  VARCHAR2        -- �T���^�C�v
  , iv_uom_code                         IN  VARCHAR2        -- �P��(����)
  , iv_target_category                  IN  VARCHAR2        -- �Ώۋ敪
  , in_shop_pay_1                       IN  NUMBER          -- �X�[(��)
  , in_material_rate_1                  IN  NUMBER          -- ����(��)
  , in_condition_unit_price_en_2        IN  NUMBER          -- �����P���Q(�~)
  , in_accrued_en_3                     IN  NUMBER          -- �����v�R(�~)
-- 2020/12/04 Ver1.1 ADD Start
  , in_compensation_en_3                IN  NUMBER          -- ��U(�~)
  , in_wholesale_margin_en_3            IN  NUMBER          -- �≮�}�[�W��(�~)
-- 2020/12/04 Ver1.1 ADD End
  , in_accrued_en_4                     IN  NUMBER          -- �����v�S(�~)
-- 2020/12/04 Ver1.1 ADD Start
  , in_just_condition_en_4              IN  NUMBER          -- �������(�~)
  , in_wholesale_adj_margin_en_4        IN  NUMBER          -- �≮�}�[�W���C��(�~)
-- 2020/12/04 Ver1.1 ADD End
  , in_condition_unit_price_en_5        IN  NUMBER          -- �����P���T(�~)
  , in_deduction_unit_price_en_6        IN  NUMBER          -- �T���P��(�~)
  , iv_tax_code_mst                     IN  VARCHAR2        -- �ŃR�[�h(MST)
  , in_tax_rate_mst                     IN  NUMBER          -- �ŗ�(MST)
  , ov_deduction_uom_code               OUT VARCHAR2        -- �T���P��
  , on_deduction_unit_price             OUT NUMBER          -- �T���P��
  , on_deduction_quantity               OUT NUMBER          -- �T������
  , on_deduction_amount                 OUT NUMBER          -- �T���z
  , on_deduction_tax_amount             OUT NUMBER          -- �T���Ŋz
-- 2020/12/04 Ver1.1 ADD Start
  , on_compensation                     OUT NUMBER          -- ��U
  , on_margin                           OUT NUMBER          -- �≮�}�[�W��
  , on_sales_promotion_expenses         OUT NUMBER          -- �g��
  , on_margin_reduction                 OUT NUMBER          -- �≮�}�[�W�����z
-- 2020/12/04 Ver1.1 ADD End
  , ov_tax_code                         OUT VARCHAR2        -- �ŃR�[�h
  , on_tax_rate                         OUT NUMBER          -- �ŗ�
  );

--
END xxcok_common2_pkg;
/
