-- 2020/10/15 Ver1.1 ADD Start
-- 2020/10/15 Ver1.1 ADD End

CREATE OR REPLACE PACKAGE BODY xxcok_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : xxcok_common2_pkg(body)
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
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal  CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn    CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error   CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_error;  --�ُ�:2
  --�p�b�P�[�W��
  cv_pkg_name       CONSTANT  VARCHAR2(30)  :=  'xxcok_common2_pkg';
  --�Z�p���[�^
  cv_sepa_period    CONSTANT  VARCHAR2(01)  :=  '.';  -- �s���I�h
  cv_sepa_colon     CONSTANT  VARCHAR2(01)  :=  ':';  -- �R����
--

  /**********************************************************************************
   * Procedure Name   : calculate_deduction_amount_p
   * Description      : �T���z�Z�o
   ***********************************************************************************/
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
  )
  IS
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name                 CONSTANT  VARCHAR2(30)  :=  'calculate_deduction_amount_p';         -- �v���O������
    cv_xxcok                    CONSTANT  VARCHAR2(10)  :=  'XXCOK';                                -- �A�v���P�[�V�����Z�k��
    cv_no_item_input_msg1       CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10672';                     -- �̔����э��ږ��ݒ�G���[�y�̔����т� ITEM ���ݒ肳��Ă��܂���B�z
    cv_no_item_input_msg2       CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10673';                     -- �T�������}�X�^���ږ��ݒ�G���[�y�T�������� ITEM ���ݒ肳��Ă��܂���B�z
    cv_invalid_item_msg         CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10674';                     -- �T�������}�X�^�ݒ�s���G���[�y�T�������� ITEM �̒l���s���ł��B�z
    cv_conversion_error_msg     CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10675';                     -- �P�ʊ��Z�G���[�y�P�ʊ��Z�G���[���������܂����B�i�ڂƒP�ʂ̐ݒ���m�F���Ă��������B�z
    cv_message_string_01        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10641';                     -- ���b�Z�[�W�p������y�i�ڃR�[�h�z
    cv_message_string_02        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10653';                     -- ���b�Z�[�W�p������y�̔��P�ʁz
    cv_message_string_03        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10654';                     -- ���b�Z�[�W�p������y�̔����ʁz
    cv_message_string_04        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10655';                     -- ���b�Z�[�W�p������y����{�̋��z�z
    cv_message_string_05        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10656';                     -- ���b�Z�[�W�p������y�ŗ��z
    cv_message_string_06        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10657';                     -- ���b�Z�[�W�p������y�T���^�C�v�z
    cv_message_string_07        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10658';                     -- ���b�Z�[�W�p������y�P��(����)�z
    cv_message_string_08        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10659';                     -- ���b�Z�[�W�p������y�Ώۋ敪�z
    cv_message_string_09        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10660';                     -- ���b�Z�[�W�p������y�X�[(��)�z
    cv_message_string_10        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10661';                     -- ���b�Z�[�W�p������y����(��)�z
    cv_message_string_11        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10662';                     -- ���b�Z�[�W�p������y�����P���Q(�~)�z
    cv_message_string_12        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10663';                     -- ���b�Z�[�W�p������y�����v�R(�~)�z
    cv_message_string_13        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10664';                     -- ���b�Z�[�W�p������y�����v�S(�~)�z
    cv_message_string_14        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10665';                     -- ���b�Z�[�W�p������y�����P���T(�~)�z
    cv_message_string_15        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10666';                     -- ���b�Z�[�W�p������y�T���P��(�~)�z
    cv_message_string_16        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10707';                     -- ���b�Z�[�W�p������y�ŃR�[�h�z
-- 2020/12/04 Ver1.1 ADD Start
    cv_message_string_17        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10772';                     -- ���b�Z�[�W�p������y��U(�~)�z
    cv_message_string_18        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10773';                     -- ���b�Z�[�W�p������y�≮�}�[�W��(�~)�z
    cv_message_string_19        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10774';                     -- ���b�Z�[�W�p������y�������(�~)�z
    cv_message_string_20        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10775';                     -- ���b�Z�[�W�p������y�≮�}�[�W���C��(�~)�z
-- 2020/12/04 Ver1.1 ADD End
    cv_token_name               CONSTANT  VARCHAR2(20)  :=  'ITEM';                                 -- �g�[�N�����yITEM�z
    cv_deduction_type_010       CONSTANT  VARCHAR2(20)  :=  '010';                                  -- �T���^�C�v�y�����z�~����(��)�z
    cv_deduction_type_020       CONSTANT  VARCHAR2(20)  :=  '020';                                  -- �T���^�C�v�y�̔����ʁ~���z�z
    cv_deduction_type_030       CONSTANT  VARCHAR2(20)  :=  '030';                                  -- �T���^�C�v�y�≮����(��z)�z
    cv_deduction_type_040       CONSTANT  VARCHAR2(20)  :=  '040';                                  -- �T���^�C�v�y�≮����(�ǉ�)�z
    cv_deduction_type_050       CONSTANT  VARCHAR2(20)  :=  '050';                                  -- �T���^�C�v�y��z���^���z
    cv_deduction_type_060       CONSTANT  VARCHAR2(20)  :=  '060';                                  -- �T���^�C�v�y�Ώې��ʗ\�����^���z
    cv_target_category_P        CONSTANT  VARCHAR2(20)  :=  'P';                                    -- �Ώۋ敪�yP�z
    cv_target_category_D        CONSTANT  VARCHAR2(20)  :=  'D';                                    -- �Ώۋ敪�yD�z
    cv_uom_hon                  CONSTANT  VARCHAR2(20)  :=  FND_PROFILE.VALUE('XXCOS1_HON_UOM_CODE'); -- �P�ʁy�{�z

    -- ==============================
    --  ���[�J���ϐ�
    -- ==============================
    lv_message_string                   VARCHAR2(20);
    lv_parameter_name                   VARCHAR2(100);
    lv_item_code                        VARCHAR2(1000);
    lv_organization_code                VARCHAR2(1000);
    ln_inventory_item_id                NUMBER;
    ln_organization_id                  NUMBER;
    ln_content                          NUMBER;
    lv_errbuf                           VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
    lv_retcode                          VARCHAR2(1);        -- ���^�[���E�R�[�h
    lv_errmsg                           VARCHAR2(5000);     -- ���[�U�[�E�G���[�E���b�Z�[�W

    -- ==============================
    -- ���[�J����O
    -- ==============================
    no_item_input_expt1                 EXCEPTION;          -- �p�����[�^������
    no_item_input_expt2                 EXCEPTION;          -- �p�����[�^������
    invalid_item_expt                   EXCEPTION;          -- �p�����[�^�s��
    conversion_error_expt               EXCEPTION;          -- �P�ʊ��Z�G���[
--
  BEGIN
    --=======================================
    -- �o�̓p�����[�^�Z�b�g
    --=======================================
    ov_errbuf         := NULL;
    ov_retcode        := gv_status_normal;
    ov_errmsg         := NULL;

    --=======================================
    -- �p�����[�^�R�[�h�`�F�b�N
    --=======================================
    -- �T���^�C�v
    IF  iv_deduction_type IN  (cv_deduction_type_010, cv_deduction_type_020, cv_deduction_type_030, cv_deduction_type_040, cv_deduction_type_050, cv_deduction_type_060)  THEN
      NULL;
    ELSE
      lv_message_string :=  cv_message_string_06;
      IF  iv_deduction_type IS  NULL  THEN
        RAISE no_item_input_expt2;
      ELSE
        RAISE invalid_item_expt;
      END IF;
    END IF;

    -- �Ώۋ敪
    IF  iv_deduction_type = cv_deduction_type_010 THEN
      IF  iv_target_category  IN  (cv_target_category_P, cv_target_category_D)  THEN
        NULL;
      ELSE
        lv_message_string :=  cv_message_string_08;
        IF  iv_target_category  IS  NULL  THEN
          RAISE no_item_input_expt2;
        ELSE
          RAISE invalid_item_expt;
        END IF;
      END IF;
    END IF;

    --=======================================
    -- �p�����[�^�K�{�`�F�b�N
    --=======================================
    -- �y���ʁz
    -- �i�ڃR�[�h
    IF  iv_item_code  IS  NULL  THEN
      lv_message_string :=  cv_message_string_01;
      RAISE no_item_input_expt1;
    END IF;

    -- �̔��P��
    IF  iv_sales_uom_code IS  NULL  THEN
      lv_message_string :=  cv_message_string_02;
      RAISE no_item_input_expt1;
    END IF;

    -- �̔�����
    IF  in_sales_quantity IS  NULL  THEN
      lv_message_string :=  cv_message_string_03;
      RAISE no_item_input_expt1;
    END IF;

    -- �ŃR�[�h
    IF  iv_tax_code_trn IS  NULL  THEN
      lv_message_string :=  cv_message_string_16;
      RAISE no_item_input_expt1;
    END IF;

    -- �ŗ�
    IF  in_tax_rate_trn IS  NULL  THEN
      lv_message_string :=  cv_message_string_05;
      RAISE no_item_input_expt1;
    END IF;

    -- �y�����z�~����(��)�z
    IF  iv_deduction_type = cv_deduction_type_010 THEN
      -- ����{�̋��z
      IF  in_sale_pure_amount IS  NULL  THEN
        lv_message_string :=  cv_message_string_04;
        RAISE no_item_input_expt1;
      END IF;

      -- �X�[(��)
      IF  iv_target_category  = cv_target_category_D  THEN
        IF  in_shop_pay_1 IS  NULL  THEN
          lv_message_string :=  cv_message_string_09;
          RAISE no_item_input_expt2;
        END IF;
      END IF;

      -- ����(��)
      IF  in_material_rate_1  IS  NULL  THEN
        lv_message_string :=  cv_message_string_10;
        RAISE no_item_input_expt2;
      END IF;

    END IF;

    -- �y�̔����ʁ~���z�z
    IF  iv_deduction_type = cv_deduction_type_020 THEN
      -- �����P���Q(�~)
      IF  in_condition_unit_price_en_2  IS  NULL  THEN
        lv_message_string :=  cv_message_string_11;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    -- �y�≮����(��z)�z
    IF  iv_deduction_type = cv_deduction_type_030 THEN
      -- �P��(����)
      IF  iv_uom_code IS  NULL  THEN
        lv_message_string :=  cv_message_string_07;
        RAISE no_item_input_expt2;
      END IF;

      -- �����v�R(�~)
      IF  in_accrued_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_12;
        RAISE no_item_input_expt2;
      END IF;

-- 2020/12/04 Ver1.1 ADD Start
      -- ��U(�~)
      IF  in_compensation_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_17;
        RAISE no_item_input_expt2;
      END IF;

      -- �≮�}�[�W��(�~)
      IF  in_wholesale_margin_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_18;
        RAISE no_item_input_expt2;
      END IF;
-- 2020/12/04 Ver1.1 ADD End
    END IF;

    -- �y�≮����(�ǉ�)�z
    IF  iv_deduction_type = cv_deduction_type_040 THEN
      -- �P��(����)
      IF  iv_uom_code IS  NULL  THEN
        lv_message_string :=  cv_message_string_07;
        RAISE no_item_input_expt2;
      END IF;

      -- �����v�S(�~)
      IF  in_accrued_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_13;
        RAISE no_item_input_expt2;
      END IF;

-- 2020/12/04 Ver1.1 ADD Start
      -- �������(�~)
      IF  in_just_condition_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_19;
        RAISE no_item_input_expt2;
      END IF;

      -- �≮�}�[�W���C��(�~)
      IF  in_wholesale_adj_margin_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_20;
        RAISE no_item_input_expt2;
      END IF;
-- 2020/12/04 Ver1.1 ADD End
    END IF;

    -- �y��z���^���z
    IF  iv_deduction_type = cv_deduction_type_050 THEN
      -- �����P���T(�~)
      IF  in_condition_unit_price_en_5  IS  NULL  THEN
        lv_message_string :=  cv_message_string_14;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    -- �y�Ώې��ʗ\�����^���z
    IF  iv_deduction_type = cv_deduction_type_060 THEN
      -- �T���P��(�~)
      IF  in_deduction_unit_price_en_6  IS  NULL  THEN
        lv_message_string :=  cv_message_string_15;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    IF iv_tax_code_mst IS NOT NULL AND in_tax_rate_mst IS NOT NULL THEN
      ov_tax_code :=  iv_tax_code_mst;
      on_tax_rate :=  in_tax_rate_mst;
    ELSE
      ov_tax_code :=  iv_tax_code_trn;
      on_tax_rate :=  in_tax_rate_trn;
    END IF;

    --=======================================
    -- �P�ʊ��Z
    --=======================================
    IF    iv_deduction_type IN  (cv_deduction_type_010, cv_deduction_type_020)  THEN
      ov_deduction_uom_code :=  NULL;
    ELSIF iv_deduction_type IN  (cv_deduction_type_030, cv_deduction_type_040)  THEN
      ov_deduction_uom_code :=  iv_uom_code;
    ELSIF iv_deduction_type IN  (cv_deduction_type_050, cv_deduction_type_060)  THEN
      ov_deduction_uom_code :=  cv_uom_hon;
    END IF;

    IF  iv_sales_uom_code = ov_deduction_uom_code THEN
      on_deduction_quantity :=  in_sales_quantity;
    ELSE
      lv_item_code          :=  iv_item_code;
      lv_organization_code  :=  NULL;
      ln_inventory_item_id  :=  NULL;
      ln_organization_id    :=  NULL;

      XXCOS_COMMON_PKG.get_uom_cnv(
        iv_before_uom_code    =>  iv_sales_uom_code     ,
        in_before_quantity    =>  in_sales_quantity     ,
        iov_item_code         =>  lv_item_code          ,
        iov_organization_code =>  lv_organization_code  ,
        ion_inventory_item_id =>  ln_inventory_item_id  ,
        ion_organization_id   =>  ln_organization_id    ,
        iov_after_uom_code    =>  ov_deduction_uom_code ,
        on_after_quantity     =>  on_deduction_quantity ,
        on_content            =>  ln_content            ,
        ov_errbuf             =>  lv_errbuf             ,
        ov_retcode            =>  lv_retcode            ,
        ov_errmsg             =>  lv_errmsg
      );

      IF  lv_retcode  = gv_status_normal  THEN
        NULL;
      ELSE
        RAISE conversion_error_expt;
      END IF;
    END IF;

    IF    iv_deduction_type = cv_deduction_type_010 THEN
      IF    iv_target_category  = cv_target_category_P  THEN
        on_deduction_amount     :=  in_sale_pure_amount * in_material_rate_1  / 100;
      ELSIF iv_target_category  = cv_target_category_D  THEN
        on_deduction_amount     :=  in_sale_pure_amount * in_shop_pay_1 * in_material_rate_1 / 10000;
      END IF;
      IF  on_deduction_quantity !=  0 THEN
        on_deduction_unit_price :=  ROUND(on_deduction_amount / on_deduction_quantity,2);
      ELSE
        on_deduction_unit_price :=  0;
      END IF;
    ELSIF iv_deduction_type = cv_deduction_type_020 THEN
      on_deduction_amount     :=  in_condition_unit_price_en_2  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_condition_unit_price_en_2,2);
    ELSIF iv_deduction_type = cv_deduction_type_030 THEN
      on_deduction_amount     :=  in_accrued_en_3 * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_accrued_en_3,2);
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_deduction_amount     :=  in_accrued_en_4 * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_accrued_en_4,2);
    ELSIF iv_deduction_type = cv_deduction_type_050 THEN
      on_deduction_amount     :=  in_condition_unit_price_en_5  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_condition_unit_price_en_5,2);
    ELSIF iv_deduction_type = cv_deduction_type_060 THEN
      on_deduction_amount     :=  in_deduction_unit_price_en_6  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_deduction_unit_price_en_6,2);
    END IF;

    on_deduction_tax_amount :=  ROUND(on_deduction_amount * on_tax_rate / 100);

-- 2020/12/04 Ver1.1 ADD Start
    IF    iv_deduction_type = cv_deduction_type_030 THEN
      on_compensation             :=  ROUND(in_compensation_en_3    * on_deduction_quantity,2);
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_sales_promotion_expenses :=  ROUND(in_just_condition_en_4  * on_deduction_quantity,2);
    END IF;
-- 2020/12/04 Ver1.1 ADD End

    on_deduction_quantity :=  ROUND(on_deduction_quantity,2);
    on_deduction_amount   :=  ROUND(on_deduction_amount);

-- 2020/12/04 Ver1.1 ADD Start
    IF    iv_deduction_type = cv_deduction_type_030 THEN
      on_margin                   :=  on_deduction_amount     - on_compensation;
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_margin_reduction         :=  on_deduction_amount     - on_sales_promotion_expenses;
    END IF;
-- 2020/12/04 Ver1.1 ADD End
--
  EXCEPTION
    WHEN no_item_input_expt1 THEN
      --���b�Z�[�W�擾
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => lv_message_string                -- ���b�Z�[�W�R�[�h
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_no_item_input_msg1                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_token_name                            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_parameter_name                        -- �g�[�N���l1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN no_item_input_expt2 THEN
      --���b�Z�[�W�擾
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => lv_message_string                -- ���b�Z�[�W�R�[�h
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_no_item_input_msg2                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_token_name                            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_parameter_name                        -- �g�[�N���l1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN invalid_item_expt THEN
      --���b�Z�[�W�擾
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => lv_message_string                -- ���b�Z�[�W�R�[�h
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_invalid_item_msg                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_token_name                            -- �g�[�N���R�[�h2
                     ,iv_token_value1 => lv_parameter_name                        -- �g�[�N���l1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN conversion_error_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_conversion_error_msg                  -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END calculate_deduction_amount_p;
--
END xxcok_common2_pkg;
/
