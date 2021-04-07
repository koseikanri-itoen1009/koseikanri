CREATE OR REPLACE PACKAGE BODY XXCOK024A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A03C_pkg(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�̔����сE�̔��T���f�[�^�̍쐬 MD050_COK_024_A03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_sales_exp_p        �̔����уf�[�^���o(A-2)
 *  calc_deduction_p       �̔��T���f�[�^�Z�o(A-3)
 *  ins_deduction_p        �̔��T���f�[�^�o�^(A-4)
 *  upd_control_p          �̔��T���Ǘ����X�V(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/01/15    1.0   Y.Koh            �V�K�쐬
 *  2020/12/03    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
 *  2021/04/06    1.2   SCSK Y.Koh       [E_�{�ғ�_16026]
 *
 *****************************************************************************************/
--
  -- ==============================
  -- �O���[�o���萔
  -- ==============================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A03C';                      -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_sales_deduction_max      CONSTANT VARCHAR2(30)         := 'XXCOK1_SALES_DEDUCTION_MAX';        -- �̔��T���ő又������
  -- �A�v���P�[�V�����Z�k��
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- �A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- �����������b�Z�[�W
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- �G���[�������b�Z�[�W
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- �ΏۂȂ����b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- �v���t�@�C���擾�G���[
  cv_msg_cok_10592            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10592';                  -- �O�񏈗�ID�擾�G���[
  cv_msg_cok_10593            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10593';                  -- �T���z�Z�o�G���[
  -- �g�[�N����
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- �����̃g�[�N����
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- �v���t�@�C�����̃g�[�N����
  cv_tkn_source_line_id       CONSTANT VARCHAR2(15)         := 'SOURCE_LINE_ID';                    -- �̔����і���ID�̃g�[�N����
  cv_tkn_item_code            CONSTANT VARCHAR2(15)         := 'ITEM_CODE';                         -- �i�ڃR�[�h�̃g�[�N����
  cv_tkn_sales_uom_code       CONSTANT VARCHAR2(15)         := 'SALES_UOM_CODE';                    -- �̔��P�ʂ̃g�[�N����
  cv_tkn_condition_no         CONSTANT VARCHAR2(15)         := 'CONDITION_NO';                      -- �T���ԍ��̃g�[�N����
  cv_tkn_base_code            CONSTANT VARCHAR2(15)         := 'BASE_CODE';                         -- �S�����_�̃g�[�N����
  cv_tkn_errmsg               CONSTANT VARCHAR2(15)         := 'ERRMSG';                            -- �G���[���b�Z�[�W�̃g�[�N����
  -- �Q�ƃ^�C�v
  cv_lookup_CHAIN_CODE        CONSTANT VARCHAR2(50)         := 'XXCMM_CHAIN_CODE';                  -- �`�F�[���X�R�[�h
  cv_lookup_DATA_TYPE         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- �T���f�[�^���
  -- �t���O
  cv_flag_s                   CONSTANT VARCHAR2(1)          := 'S';                                 -- �쐬���敪 S
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- �A�g�t���O N
  -- �L��
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  -- ==============================
  -- �O���[�o���ϐ�
  -- ==============================
  gn_target_cnt               NUMBER    DEFAULT 0;                                                  -- �Ώی���
  gn_normal_cnt               NUMBER    DEFAULT 0;                                                  -- ���팏��
  gn_skip_cnt                 NUMBER    DEFAULT 0;                                                  -- �X�L�b�v����
  gn_error_cnt                NUMBER    DEFAULT 0;                                                  -- �G���[����
--
  gn_target_header_id_st      NUMBER;                                                               -- �̔����і���ID (��)
  gn_target_header_id_ed      NUMBER;                                                               -- �̔����і���ID (��)
--
  gv_deduction_uom_code       VARCHAR2(3);                                                          -- �T���P��
  gn_deduction_unit_price     NUMBER;                                                               -- �T���P��
  gn_deduction_quantity       NUMBER;                                                               -- �T������
  gn_deduction_amount         NUMBER;                                                               -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                                               -- ��U
  gn_margin                   NUMBER;                                                               -- �≮�}�[�W��
  gn_sales_promotion_expenses NUMBER;                                                               -- �g��
  gn_margin_reduction         NUMBER;                                                               -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount     NUMBER;                                                               -- �T���Ŋz
  gn_tax_code                 VARCHAR2(4);                                                          -- �ŃR�[�h
  gn_tax_rate                 NUMBER;                                                               -- �ŗ�
--
  -- ==============================
  -- �O���[�o���J�[�\��
  -- ==============================
  CURSOR g_sales_exp_cur
  IS
    WITH 
     FLVC1 AS
      (SELECT /*+ MATERIALIZED */ LOOKUP_CODE
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCOK1_DEDUCTION_TYPE'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE1    = 'Y'
      )
    ,FLVC2 AS
      (SELECT /*+ MATERIALIZED */ MEANING
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCOS1_MK_ORG_CLS_MST_013_A01'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE4    = 'Y'
      )
    ,FLVC3 AS
      (SELECT /*+ MATERIALIZED */ LOOKUP_CODE
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCMM_CUST_GYOTAI_SHO'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE2    = 'Y'
      )
    --�@
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE(+)          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE(+)          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE(+)             = 'JA'
    AND CHCD.ENABLED_FLAG(+)         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND XSEH.SHIP_TO_CUSTOMER_CODE = XCH.CUSTOMER_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE
    UNION ALL
    --�A
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE(+)          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE(+)          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE(+)             = 'JA'
    AND CHCD.ENABLED_FLAG(+)         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND XCA.INTRO_CHAIN_CODE2         = XCH.DEDUCTION_CHAIN_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE
    UNION ALL
    --�B
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE             = 'JA'
    AND CHCD.ENABLED_FLAG         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND CHCD.ATTRIBUTE1               = XCH.CORP_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE;
--
  g_sales_exp_rec             g_sales_exp_cur%ROWTYPE;
--
  -- ==============================
  -- �O���[�o����O
  -- ==============================
  -- *** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �����Ώ۔͈͂̔̔����уw�b�_�[ID�̎擾
    -- ============================================================
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_s;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xseh.sales_exp_header_id)
    INTO    gn_target_header_id_ed
    FROM    xxcok_sales_exp_h xseh
    WHERE   xseh.sales_exp_header_id >= gn_target_header_id_st;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : calc_deduction_p
   * Description      : �̔��T���f�[�^�Z�o(A-3)
   ***********************************************************************************/
  PROCEDURE calc_deduction_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'calc_deduction_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_base_code    VARCHAR2(4);                            -- �S�����_
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- ���ʊ֐� �T���z�Z�o
    -- ============================================================
    xxcok_common2_pkg.calculate_deduction_amount_p(
      ov_errbuf                     =>  lv_errbuf                                 , -- �G���[�o�b�t�@
      ov_retcode                    =>  lv_retcode                                , -- ���^�[���R�[�h
      ov_errmsg                     =>  lv_errmsg                                 , -- �G���[���b�Z�[�W
      iv_item_code                  =>  g_sales_exp_rec.div_item_code             , -- �i�ڃR�[�h
      iv_sales_uom_code             =>  g_sales_exp_rec.dlv_uom_code              , -- �̔��P��
      in_sales_quantity             =>  g_sales_exp_rec.dlv_qty                   , -- �̔�����
      in_sale_pure_amount           =>  g_sales_exp_rec.pure_amount               , -- ����{�̋��z
      iv_tax_code_trn               =>  g_sales_exp_rec.tax_code_trn              , -- �ŃR�[�h(TRN)
      in_tax_rate_trn               =>  g_sales_exp_rec.tax_rate_trn              , -- �ŗ�(TRN)
      iv_deduction_type             =>  g_sales_exp_rec.attribute2                , -- �T���^�C�v
      iv_uom_code                   =>  g_sales_exp_rec.uom_code                  , -- �P��(����)
      iv_target_category            =>  g_sales_exp_rec.target_category           , -- �Ώۋ敪
      in_shop_pay_1                 =>  g_sales_exp_rec.shop_pay_1                , -- �X�[(��)
      in_material_rate_1            =>  g_sales_exp_rec.material_rate_1           , -- ����(��)
      in_condition_unit_price_en_2  =>  g_sales_exp_rec.condition_unit_price_en_2 , -- �����P���Q(�~)
      in_accrued_en_3               =>  g_sales_exp_rec.accrued_en_3              , -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
      in_compensation_en_3          =>  g_sales_exp_rec.compensation_en_3         , -- ��U(�~)
      in_wholesale_margin_en_3      =>  g_sales_exp_rec.wholesale_margin_en_3     , -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
      in_accrued_en_4               =>  g_sales_exp_rec.accrued_en_4              , -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
      in_just_condition_en_4        =>  g_sales_exp_rec.just_condition_en_4       , -- �������(�~)
      in_wholesale_adj_margin_en_4  =>  g_sales_exp_rec.wholesale_adj_margin_en_4 , -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
      in_condition_unit_price_en_5  =>  g_sales_exp_rec.condition_unit_price_en_5 , -- �����P���T(�~)
      in_deduction_unit_price_en_6  =>  g_sales_exp_rec.deduction_unit_price_en_6 , -- �T���P��(�~)
      iv_tax_code_mst               =>  g_sales_exp_rec.tax_code_mst              , -- �ŃR�[�h(MST)
      in_tax_rate_mst               =>  g_sales_exp_rec.tax_rate_mst              , -- �ŗ�(MST)
      ov_deduction_uom_code         =>  gv_deduction_uom_code                     , -- �T���P��
      on_deduction_unit_price       =>  gn_deduction_unit_price                   , -- �T���P��
      on_deduction_quantity         =>  gn_deduction_quantity                     , -- �T������
      on_deduction_amount           =>  gn_deduction_amount                       , -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
      on_compensation               =>  gn_compensation                           , -- ��U
      on_margin                     =>  gn_margin                                 , -- �≮�}�[�W��
      on_sales_promotion_expenses   =>  gn_sales_promotion_expenses               , -- �g��
      on_margin_reduction           =>  gn_margin_reduction                       , -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
      on_deduction_tax_amount       =>  gn_deduction_tax_amount                   , -- �T���Ŋz
      ov_tax_code                   =>  gn_tax_code                               , -- �ŃR�[�h
      on_tax_rate                   =>  gn_tax_rate                                 -- �ŗ�
    );
--
    IF  lv_retcode  !=  cv_status_normal  THEN
      IF  g_sales_exp_rec.corp_code IS  NOT NULL  THEN
        SELECT  MAX(ffv.attribute2)
        INTO    lv_base_code
        FROM    fnd_flex_values     ffv ,
                fnd_flex_value_sets ffvs
        WHERE   ffvs.flex_value_set_name  = 'XX03_BUSINESS_TYPE'
        AND     ffv.flex_value_set_id     = ffvs.flex_value_set_id
        AND     ffv.flex_value            = g_sales_exp_rec.corp_code;
      ELSIF g_sales_exp_rec.deduction_chain_code  IS  NOT NULL  THEN
        lv_base_code  :=  g_sales_exp_rec.chain_base;
      ELSIF g_sales_exp_rec.customer_code IS  NOT NULL  THEN
        lv_base_code  :=  g_sales_exp_rec.cust_base;
      END IF;

      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10593
                    , cv_tkn_source_line_id
                    , g_sales_exp_rec.sales_exp_line_id
                    , cv_tkn_item_code
                    , g_sales_exp_rec.div_item_code
                    , cv_tkn_sales_uom_code
                    , g_sales_exp_rec.dlv_uom_code
                    , cv_tkn_condition_no
                    , g_sales_exp_rec.condition_no
                    , cv_tkn_base_code
                    , lv_base_code
                    , cv_tkn_errmsg
                    , lv_errmsg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END calc_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_deduction_p
   * Description      : �̔��T���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_deduction_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_deduction_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T���f�[�^�o�^
    -- ============================================================
    INSERT  INTO  xxcok_sales_deduction(
      sales_deduction_id                          , -- �̔��T��ID
      base_code_from                              , -- �U�֌����_
      base_code_to                                , -- �U�֐拒�_
      customer_code_from                          , -- �U�֌��ڋq�R�[�h
      customer_code_to                            , -- �U�֐�ڋq�R�[�h
      deduction_chain_code                        , -- �T���p�`�F�[���R�[�h
      corp_code                                   , -- ��ƃR�[�h
      record_date                                 , -- �v���
      source_category                             , -- �쐬���敪
      source_line_id                              , -- �쐬������ID
      condition_id                                , -- �T������ID
      condition_no                                , -- �T���ԍ�
      condition_line_id                           , -- �T���ڍ�ID
      data_type                                   , -- �f�[�^���
      status                                      , -- �X�e�[�^�X
      item_code                                   , -- �i�ڃR�[�h
      sales_uom_code                              , -- �̔��P��
      sales_unit_price                            , -- �̔��P��
      sales_quantity                              , -- �̔�����
      sale_pure_amount                            , -- ����{�̋��z
      sale_tax_amount                             , -- �������Ŋz
      deduction_uom_code                          , -- �T���P��
      deduction_unit_price                        , -- �T���P��
      deduction_quantity                          , -- �T������
      deduction_amount                            , -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
      compensation                                , -- ��U
      margin                                      , -- �≮�}�[�W��
      sales_promotion_expenses                    , -- �g��
      margin_reduction                            , -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
      tax_code                                    , -- �ŃR�[�h
      tax_rate                                    , -- �ŗ�
      recon_tax_code                              , -- �������ŃR�[�h
      recon_tax_rate                              , -- �������ŗ�
      deduction_tax_amount                        , -- �T���Ŋz
      remarks                                     , -- ���l
      application_no                              , -- �\����No.
      gl_if_flag                                  , -- GL�A�g�t���O
      gl_base_code                                , -- GL�v�㋒�_
      gl_date                                     , -- GL�L����
-- 2020/12/03 Ver1.1 MOD Start
      recovery_date                               , -- ���J�o���f�[�^�ǉ������t
      recovery_add_request_id                     , -- ���J�o���f�[�^�ǉ����v��ID
      recovery_del_date                           , -- ���J�o���f�[�^�폜�����t
      recovery_del_request_id                     , -- ���J�o���f�[�^�폜���v��ID
--      recovery_date                               , -- ���J�o���[���t
-- 2020/12/03 Ver1.1 MOD End
      cancel_flag                                 , -- ����t���O
      cancel_base_code                            , -- ������v�㋒�_
      cancel_gl_date                              , -- ���GL�L����
      cancel_user                                 , -- ������{���[�U
      recon_base_code                             , -- �������v�㋒�_
      recon_slip_num                              , -- �x���`�[�ԍ�
      carry_payment_slip_num                      , -- �J�z���x���`�[�ԍ�
      report_decision_flag                        , -- ����m��t���O
      gl_interface_id                             , -- GL�A�gID
      cancel_gl_interface_id                      , -- ���GL�A�gID
      created_by                                  , -- �쐬��
      creation_date                               , -- �쐬��
      last_updated_by                             , -- �ŏI�X�V��
      last_update_date                            , -- �ŏI�X�V��
      last_update_login                           , -- �ŏI�X�V���O�C��
      request_id                                  , -- �v��ID
      program_application_id                      , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      program_id                                  , -- �R���J�����g�E�v���O����ID
      program_update_date                         ) -- �v���O�����X�V��
    values(
      xxcok_sales_deduction_s01.NEXTVAL           , -- �̔��T��ID
      g_sales_exp_rec.sales_base_code             , -- �U�֌����_
      g_sales_exp_rec.sales_base_code             , -- �U�֐拒�_
      g_sales_exp_rec.ship_to_customer_code       , -- �U�֌��ڋq�R�[�h
      g_sales_exp_rec.ship_to_customer_code       , -- �U�֐�ڋq�R�[�h
      NULL                                        , -- �T���p�`�F�[���R�[�h
      NULL                                        , -- ��ƃR�[�h
      g_sales_exp_rec.delivery_date               , -- �v���
      cv_flag_s                                   , -- �쐬���敪
      g_sales_exp_rec.sales_exp_line_id           , -- �쐬������ID
      g_sales_exp_rec.condition_id                , -- �T������ID
      g_sales_exp_rec.condition_no                , -- �T���ԍ�
      g_sales_exp_rec.condition_line_id           , -- �T���ڍ�ID
      g_sales_exp_rec.data_type                   , -- �f�[�^���
      cv_flag_n                                   , -- �X�e�[�^�X
      g_sales_exp_rec.div_item_code               , -- �i�ڃR�[�h
      g_sales_exp_rec.dlv_uom_code                , -- �̔��P��
      g_sales_exp_rec.dlv_unit_price              , -- �̔��P��
      g_sales_exp_rec.dlv_qty                     , -- �̔�����
      g_sales_exp_rec.pure_amount                 , -- ����{�̋��z
      g_sales_exp_rec.tax_amount                  , -- �������Ŋz
      gv_deduction_uom_code                       , -- �T���P��
      gn_deduction_unit_price                     , -- �T���P��
      gn_deduction_quantity                       , -- �T������
      gn_deduction_amount                         , -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
      gn_compensation                             , -- ��U
      gn_margin                                   , -- �≮�}�[�W��
      gn_sales_promotion_expenses                 , -- �g��
      gn_margin_reduction                         , -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
      gn_tax_code                                 , -- �ŃR�[�h
      gn_tax_rate                                 , -- �ŗ�
      NULL                                        , -- �������ŃR�[�h
      NULL                                        , -- �������ŗ�
      gn_deduction_tax_amount                     , -- �T���Ŋz
      NULL                                        , -- ���l
      NULL                                        , -- �\����No.
      cv_flag_n                                   , -- GL�A�g�t���O
      NULL                                        , -- GL�v�㋒�_
      NULL                                        , -- GL�L����
-- 2020/12/03 Ver1.1 MOD Start
      NULL                                        , -- ���J�o���f�[�^�ǉ������t
      NULL                                        , -- ���J�o���f�[�^�ǉ����v��ID
      NULL                                        , -- ���J�o���f�[�^�폜�����t
      NULL                                        , -- ���J�o���f�[�^�폜���v��ID
--      NULL                                        , -- ���J�o���[���t
-- 2020/12/03 Ver1.1 MOD End
      cv_flag_n                                   , -- ����t���O
      NULL                                        , -- ������v�㋒�_
      NULL                                        , -- ���GL�L����
      NULL                                        , -- ������{���[�U
      NULL                                        , -- �������v�㋒�_
      NULL                                        , -- �x���`�[�ԍ�
      NULL                                        , -- �J�z���x���`�[�ԍ�
      NULL                                        , -- ����m��t���O
      NULL                                        , -- GL�A�gID
      NULL                                        , -- ���GL�A�gID
      cn_user_id                                  , -- �쐬��
      SYSDATE                                     , -- �쐬��
      cn_user_id                                  , -- �ŏI�X�V��
      SYSDATE                                     , -- �ŏI�X�V��
      cn_login_id                                 , -- �ŏI�X�V���O�C��
      cn_conc_request_id                          , -- �v��ID
      cn_prog_appl_id                             , -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      cn_conc_program_id                          , -- �R���J�����g�E�v���O����ID
      SYSDATE                                     );-- �v���O�����X�V��
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END ins_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_p
   * Description      : �̔����уf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_sales_exp_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔����уf�[�^���o
    -- ============================================================
    OPEN  g_sales_exp_cur;
    FETCH g_sales_exp_cur INTO  g_sales_exp_rec;
--
    -- 1���ڂ����݂��Ȃ��ꍇ�́A�ΏۂȂ����b�Z�[�W���o��
    IF  g_sales_exp_cur%NOTFOUND  THEN
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_00001
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
      RETURN;
    END IF;
--
    LOOP
      EXIT  WHEN  g_sales_exp_cur%NOTFOUND;
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ============================================================
      -- �̔��T���f�[�^�Z�o(A-3)�̌Ăяo��
      -- ============================================================
      calc_deduction_p(
        ov_errbuf   =>  lv_errbuf                       -- �G���[�E���b�Z�[�W
      , ov_retcode  =>  lv_retcode                      -- ���^�[���E�R�[�h
      , ov_errmsg   =>  lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF  lv_retcode  = cv_status_normal  THEN
--
        -- ============================================================
        -- �̔��T���f�[�^�o�^(A-4)�̌Ăяo��
        -- ============================================================
        ins_deduction_p(
          ov_errbuf   =>  lv_errbuf                     -- �G���[�E���b�Z�[�W
        , ov_retcode  =>  lv_retcode                    -- ���^�[���E�R�[�h
        , ov_errmsg   =>  lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF  lv_retcode  = cv_status_normal  THEN
          gn_normal_cnt :=  gn_normal_cnt + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
      ELSIF lv_retcode  = cv_status_warn  THEN
        ov_retcode := cv_status_warn;
        gn_skip_cnt   :=  gn_skip_cnt   + 1;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      FETCH g_sales_exp_cur INTO  g_sales_exp_rec;
    END LOOP;
    CLOSE g_sales_exp_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_sales_exp_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : �̔��T���Ǘ����X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �̔��T���Ǘ����X�V
    -- ============================================================
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed, last_processing_id) ,
            last_updated_by         = cn_user_id                                    ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_login_id                                   ,
            request_id              = cn_conc_request_id                            ,
            program_application_id  = cn_prog_appl_id                               ,
            program_id              = cn_conc_program_id                            ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_s;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                                 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                                 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- �O���[�o���ϐ��̏�����
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- init�̌Ăяo��
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �̔����уf�[�^���o�̌Ăяo��
    -- ============================================================
    get_sales_exp_p(
      ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_warn  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- �̔��T���Ǘ����X�V�̌Ăяo��
    -- ============================================================
    upd_control_p(
      ov_errbuf   =>  lv_errbuf                             -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode                            -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- �G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2                                    -- ���^�[���E�R�[�h
  )
  IS
--
    -- ==============================
    -- ���[�J���萔
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- �v���O������
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�ϐ�
--
  BEGIN
--
    -- ============================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
--
    -- ============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode                              -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ============================================================
    -- �G���[�o��
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- �o�͋敪
                      , lv_errmsg       -- ���b�Z�[�W
                      , 1               -- ���s
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- �o�͋敪
                      , lv_errbuf       -- ���b�Z�[�W
                      , 0               -- ���s
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- �Ώی����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- ���������o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �X�L�b�v�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- ============================================================
    -- �G���[�����o��
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 1                 -- ���s
                    );
--
    -- ============================================================
    -- �I�����b�Z�[�W
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- �o�͋敪
                    , lv_out_msg        -- ���b�Z�[�W
                    , 0                 -- ���s
                    );
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A03C;
/
