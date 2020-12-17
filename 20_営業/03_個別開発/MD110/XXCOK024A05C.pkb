CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A05C (body)
 * Description      : ���ѐU�ցE�̔��T���f�[�^�̍쐬/�̔��T���f�[�^�̍쐬�i�U�֊����j
 * MD.050           : ���ѐU�ցE�̔��T���f�[�^�̍쐬/�̔��T���f�[�^�̍쐬�i�U�֊����j MD050_COK_024_A05
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(B-1)
 *  reversing_data_create  �U�߃f�[�^�쐬����(�̔��T��)(B-2)
 *  reversing_data_delite  �U�߃f�[�^�폜����(B-3)
 *  transfer_data_get      ���ѐU�փf�[�^���o(B-4)
 *  sell_trns_cul          ���ѐU�֍T���f�[�^�Z�o(B-5)
 *  insert_deduction       �̔��T���f�[�^�o�^(B-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/12    1.0   Y.Nakajima       �V�K�쐬
 *  2020/12/03    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK024A05C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_creation_date                 CONSTANT DATE            := SYSDATE;                     -- CREATION_DATE
  cd_last_update_date              CONSTANT DATE            := SYSDATE;                     -- LAST_UPDATE_DATE
  cd_program_update_date           CONSTANT DATE            := SYSDATE;                     -- PROGRAM_UPDATE_DATE
  -- ����
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_cok_00001                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00001';          -- �ΏۂȂ����b�Z�[�W
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';          -- 
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';          -- �Ɩ����t�擾�G���[
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';          -- ��v���Ԗ��I�[�v���G���[
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';          -- ����ʐݒ�G���[���b�Z�[�W
  cv_msg_cok_10685                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10685';          -- �T���z�Z�o�G���[(���ѐU��)
  cv_msg_cok_10632                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10632';          -- ���b�N�G���[���b�Z�[�W
--
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';          -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';          -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';          -- �G���[����
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';          -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';          -- ����I��
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';          -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_line_id                   CONSTANT VARCHAR2(15)    := 'SOURCE_TRAN_ID';
  cv_tkn_sales_uom_code            CONSTANT VARCHAR2(15)    := 'SALES_UOM_CODE';
  cv_tkn_condition_no              CONSTANT VARCHAR2(20)    := 'CONDITION_NO';
  cv_tkn_base_code                 CONSTANT VARCHAR2(15)    := 'BASE_CODE';
  cv_tkn_errmsg                    CONSTANT VARCHAR2(15)    := 'ERRMSG';
  -- ���̓p�����[�^�E�����
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- ����
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- �m��
  -- ������ѐU�֏��e�[�u���E����m��t���O
  cv_xsti_decision_flag_news       CONSTANT VARCHAR2(1)     := '0';  -- ����
  -- �ڋq�}�X�^�L���X�e�[�^�X
  cv_get_period_inv                CONSTANT VARCHAR2(2)     := '01';   --INV��v���Ԏ擾
  cv_period_status                 CONSTANT VARCHAR2(4)     := 'OPEN'; -- ��v���ԃX�e�[�^�X(�I�[�v��)
  --�Q�ƃ^�C�v�E�L���t���O
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';         -- �L��
  -- ���ѐU�֏��f�[�^���o�Ŏg�p����Œ�l
  cv_cate_set_name          CONSTANT VARCHAR2(20) := '�{�Џ��i�敪';             -- �i�ڃJ�e�S���Z�b�g��
  -- �̔��T�����e�[�u���ɐݒ肷��Œ�l
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'V';                        -- �쐬���敪
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                        -- �X�e�[�^�X
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- GL�A�g�t���O
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- ����t���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gd_target_date_from              DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiFrom�j
  gd_target_date_to                DATE          DEFAULT NULL;   -- �U�֑Ώۊ��ԁiTo�j
  -- ���̓p�����[�^
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- �����
  --
  gv_deduction_uom_code            VARCHAR2(3);                                       -- �T���P��
  gv_tax_code                      VARCHAR2(4);                                       -- �ŃR�[�h
  gn_tax_rate                      NUMBER;                                            -- �ŗ�
  gn_deduction_unit_price          NUMBER;                                            -- �T���P��
  gn_deduction_quantity            NUMBER;                                            -- �T������
  gn_deduction_amount              NUMBER;                                            -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation                  NUMBER;                                            -- ��U
  gn_margin                        NUMBER;                                            -- �≮�}�[�W��
  gn_sales_promotion_expenses      NUMBER;                                            -- �g��
  gn_margin_reduction              NUMBER;                                            -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount          NUMBER;                                            -- �T���Ŋz
--
  --==================================================
  -- �O���[�o����O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  -- ���ѐU�֏��擾
  CURSOR g_actual_trns_cur
  IS
    WITH 
     FLVC1 AS
             (SELECT  /*+ MATERIALIZED */
                      lookup_code
              FROM    fnd_lookup_values flvc
              WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_TYPE'
              AND     flvc.language     = 'JA'
              AND     flvc.enabled_flag = 'Y'
              AND     flvc.attribute1   = 'Y')    -- �̔��T���쐬�Ώ�
    ,FLVC3 AS
             (SELECT  /*+ MATERIALIZED */
                      lookup_code
              FROM    fnd_lookup_values flvc
              WHERE   flvc.lookup_type  = 'XXCMM_CUST_GYOTAI_SHO'
              AND     flvc.language     = 'JA'
              AND     flvc.enabled_flag = 'Y'
              AND     flvc.attribute2   = 'Y')    -- �̔��T���쐬�Ώ�
    SELECT 
           /*+ leading(xdst xca gyotai_sho xch flv2 d_typ xcl flv)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */
           xdst.delivery_base_code                      AS delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                               AS base_code                    -- �U�֐拒�_
          ,xdst.cust_code                               AS cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                            AS selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                               AS item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                               AS unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                     AS qty                          -- ����
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                                AS tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                                AS tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- ����Ŋz
          ,xch.condition_id                             AS condition_id                 -- �T������ID
          ,xch.condition_no                             AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                                AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code                            AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                                AS data_type                    -- �f�[�^���
          ,xch.tax_code                                 AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                               AS attribute3                   -- �{���S�����_(�T���p�`�F�[��)
          ,xca.sale_base_code                           AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id                        AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class                            AS product_class                -- ���i�敪
          ,xcl.item_code                                AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                                 AS uom_code                     -- �P��(����)
          ,xcl.target_category                          AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1                          AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                              AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �T���p�`�F�[��
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,FLVC1                         d_typ
          ,FLVC3                         gyotai_sho
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = cv_lang
    AND    flv.enabled_flag(+)           = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    xdst.cust_code                = xch.customer_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
    UNION ALL
    SELECT 
           /*+ leading(xdst xca gyotai_sho xch flv2 d_typ xcl flv)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */
           xdst.delivery_base_code                      AS delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                               AS base_code                    -- �U�֐拒�_
          ,xdst.cust_code                               AS cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                            AS selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                               AS item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                               AS unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                     AS qty                          -- ����
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                                AS tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                                AS tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- ����Ŋz
          ,xch.condition_id                             AS condition_id                 -- �T������ID
          ,xch.condition_no                             AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                                AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code                            AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                                AS data_type                    -- �f�[�^���
          ,xch.tax_code                                 AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                               AS attribute3                   -- �{���S�����_(�T���p�`�F�[��)
          ,xca.sale_base_code                           AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id                        AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class                            AS product_class                -- ���i�敪
          ,xcl.item_code                                AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                                 AS uom_code                     -- �P��(����)
          ,xcl.target_category                          AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1                          AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                              AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �T���p�`�F�[��
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,FLVC1                         D_TYP
          ,FLVC3                         GYOTAI_SHO
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = cv_lang
    AND    flv.enabled_flag(+)           = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    xca.intro_chain_code2         = xch.deduction_chain_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
    UNION ALL
    SELECT 
           /*+ leading(xdst xca gyotai_sho flv xch flv2 d_typ xcl)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */            
           xdst.delivery_base_code                      AS delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                               AS base_code                    -- �U�֐拒�_
          ,xdst.cust_code                               AS cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                            AS selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                               AS item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                               AS unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                     AS qty                          -- ����
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                                AS tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                                AS tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- ����Ŋz
          ,xch.condition_id                             AS condition_id                 -- �T������ID
          ,xch.condition_no                             AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                                AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code                            AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                                AS data_type                    -- �f�[�^���
          ,xch.tax_code                                 AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                               AS attribute3                   -- �{���S�����_(�T���p�`�F�[��)
          ,xca.sale_base_code                           AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id                        AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class                            AS product_class                -- ���i�敪
          ,xcl.item_code                                AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                                 AS uom_code                     -- �P��(����)
          ,xcl.target_category                          AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1                          AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                              AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �T���p�`�F�[��
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,FLVC1                         D_TYP
          ,FLVC3                         GYOTAI_SHO
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type               = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = cv_lang
    AND    flv.enabled_flag              = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    flv.attribute1                = xch.corp_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
  ;
--
  -- �J�[�\�����R�[�h�擾�p
  g_selling_trns_rec          g_actual_trns_cur%ROWTYPE;
--
  --==================================================
  -- �O���[�o���^�C�v
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : insert_deduction
   * Description      : �̔��T���f�[�^�o�^(B-6)
   ***********************************************************************************/
  PROCEDURE insert_deduction(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deduction';          -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �̔��T���f�[�^��o�^����
    INSERT INTO xxcok_sales_deduction(
         sales_deduction_id                                               -- �̔��T��ID
        ,base_code_from                                                   -- �U�֌����_
        ,base_code_to                                                     -- �U�֐拒�_
        ,customer_code_from                                               -- �U�֌��ڋq�R�[�h
        ,customer_code_to                                                 -- �U�֐�ڋq�R�[�h
-- 2020/12/03 Ver1.1 ADD Start
        ,deduction_chain_code                                             -- �T���p�`�F�[���R�[�h
        ,corp_code                                                        -- ��ƃR�[�h
-- 2020/12/03 Ver1.1 ADD End
        ,record_date                                                      -- �v���
        ,source_category                                                  -- �쐬���敪
        ,source_line_id                                                   -- �쐬������ID
        ,condition_id                                                     -- �T��ID
        ,condition_no                                                     -- �T���ԍ�
        ,condition_line_id                                                -- �T���ڍ�ID
        ,data_type                                                        -- �f�[�^���
        ,status                                                           -- �X�e�[�^�X
        ,item_code                                                        -- �i�ڃR�[�h
        ,sales_uom_code                                                   -- �̔��P��
        ,sales_unit_price                                                 -- �̔��P��
        ,sales_quantity                                                   -- �̔�����
        ,sale_pure_amount                                                 -- ����{�̋��z
        ,sale_tax_amount                                                  -- �������Ŋz
        ,deduction_uom_code                                               -- �T���P��
        ,deduction_unit_price                                             -- �T���P��
        ,deduction_quantity                                               -- �T������
        ,deduction_amount                                                 -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
        ,compensation                                                     -- ��U
        ,margin                                                           -- �≮�}�[�W��
        ,sales_promotion_expenses                                         -- �g��
        ,margin_reduction                                                 -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
        ,tax_code                                                         -- �ŃR�[�h
        ,tax_rate                                                         -- �ŗ�
-- 2020/12/03 Ver1.1 ADD Start
        ,recon_tax_code                                                   -- �������ŃR�[�h
        ,recon_tax_rate                                                   -- �������ŗ�
-- 2020/12/03 Ver1.1 ADD End
        ,deduction_tax_amount                                             -- �T���Ŋz
-- 2020/12/03 Ver1.1 ADD Start
        ,remarks                                                          -- ���l
        ,application_no                                                   -- �\����No.
-- 2020/12/03 Ver1.1 ADD End
        ,gl_if_flag                                                       -- GL�A�g�t���O
-- 2020/12/03 Ver1.1 ADD Start
        ,gl_base_code                                                     -- GL�v�㋒�_
        ,gl_date                                                          -- GL�L����
        ,recovery_date                                                    -- ���J�o���f�[�^�ǉ������t
        ,recovery_add_request_id                                          -- ���J�o���f�[�^�ǉ����v��ID
        ,recovery_del_date                                                -- ���J�o���f�[�^�폜�����t
        ,recovery_del_request_id                                          -- ���J�o���f�[�^�폜���v��ID
-- 2020/12/03 Ver1.1 ADD End
        ,cancel_flag                                                      -- ����t���O
-- 2020/12/03 Ver1.1 ADD Start
        ,cancel_base_code                                                 -- ������v�㋒�_
        ,cancel_gl_date                                                   -- ���GL�L����
        ,cancel_user                                                      -- ������{���[�U
        ,recon_base_code                                                  -- �������v�㋒�_
        ,recon_slip_num                                                   -- �x���`�[�ԍ�
        ,carry_payment_slip_num                                           -- �J�z���x���`�[�ԍ�
-- 2020/12/03 Ver1.1 ADD End
        ,report_decision_flag                                             -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD Start
        ,gl_interface_id                                                  -- GL�A�gID
        ,cancel_gl_interface_id                                           -- ���GL�A�gID
-- 2020/12/03 Ver1.1 ADD End
        ,created_by                                                       -- �쐬��
        ,creation_date                                                    -- �쐬��
        ,last_updated_by                                                  -- �ŏI�X�V��
        ,last_update_date                                                 -- �ŏI�X�V��
        ,last_update_login                                                -- �ŏI�X�V���O�C��
        ,request_id                                                       -- �v��ID
        ,program_application_id                                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                                                       -- �R���J�����g�E�v���O����ID
        ,program_update_date                                              -- �v���O�����X�V��
      )VALUES(
         xxcok_sales_deduction_s01.nextval                                -- �̔��T��ID
        ,g_selling_trns_rec.delivery_base_code                            -- �U�֌����_
        ,g_selling_trns_rec.base_code                                     -- �U�֐拒�_
        ,g_selling_trns_rec.selling_from_cust_code                        -- �U�֌��ڋq�R�[�h
        ,g_selling_trns_rec.cust_code                                     -- �U�֐�ڋq�R�[�h
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- �T���p�`�F�[���R�[�h
        ,NULL                                                             -- ��ƃR�[�h
-- 2020/12/03 Ver1.1 ADD End
        ,g_selling_trns_rec.selling_date                                  -- �v���
        ,cv_created_sec                                                   -- �쐬���敪
        ,g_selling_trns_rec.selling_trns_info_id                          -- �쐬������ID
        ,g_selling_trns_rec.condition_id                                  -- �T��ID
        ,g_selling_trns_rec.condition_no                                  -- �T���ԍ�
        ,g_selling_trns_rec.condition_line_id                             -- �T���ڍ�ID
        ,g_selling_trns_rec.data_type                                     -- �f�[�^���
        ,cv_status                                                        -- �X�e�[�^�X
        ,g_selling_trns_rec.item_code                                     -- �i�ڃR�[�h
        ,g_selling_trns_rec.unit_type                                     -- �̔��P��
        ,g_selling_trns_rec.delivery_unit_price                           -- �̔��P��
        ,g_selling_trns_rec.qty                                           -- �̔�����
        ,g_selling_trns_rec.selling_amt_no_tax                            -- ����{�̋��z
        ,g_selling_trns_rec.tax_amount                                    -- �������Ŋz
        ,gv_deduction_uom_code                                            -- �T���P��
        ,gn_deduction_unit_price                                          -- �T���P��
        ,gn_deduction_quantity                                            -- �T������
        ,gn_deduction_amount                                              -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
        ,gn_compensation                                                  -- ��U
        ,gn_margin                                                        -- �≮�}�[�W��
        ,gn_sales_promotion_expenses                                      -- �g��
        ,gn_margin_reduction                                              -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
        ,gv_tax_code                                                      -- �ŃR�[�h
        ,gn_tax_rate                                                      -- �ŗ�
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- �������ŃR�[�h
        ,NULL                                                             -- �������ŗ�
-- 2020/12/03 Ver1.1 ADD End
        ,gn_deduction_tax_amount                                          -- �T���Ŋz
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- ���l
        ,NULL                                                             -- �\����No.
-- 2020/12/03 Ver1.1 ADD End
-- 2020/12/03 Ver1.1 MOD Start
        ,CASE
           WHEN   TRUNC( g_selling_trns_rec.selling_date, 'MM' )
                = TRUNC( gd_process_date                , 'MM' )
           THEN
             'O'
           ELSE
             DECODE(gv_param_info_class,'1','N','O')
         END                                                              -- GL�A�g�t���O(����f�[�^��GL�A�g�ΏۊO)
--        ,cv_gl_rel_flag                                                   -- GL�A�g�t���O
-- 2020/12/03 Ver1.1 MOD End
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- GL�v�㋒�_
        ,NULL                                                             -- GL�L����
        ,NULL                                                             -- ���J�o���f�[�^�ǉ������t
        ,NULL                                                             -- ���J�o���f�[�^�ǉ����v��ID
        ,NULL                                                             -- ���J�o���f�[�^�폜�����t
        ,NULL                                                             -- ���J�o���f�[�^�폜���v��ID
-- 2020/12/03 Ver1.1 ADD End
        ,cv_cancel_flag                                                   -- ����t���O
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- ������v�㋒�_
        ,NULL                                                             -- ���GL�L����
        ,NULL                                                             -- ������{���[�U
        ,NULL                                                             -- �������v�㋒�_
        ,NULL                                                             -- �x���`�[�ԍ�
        ,NULL                                                             -- �J�z���x���`�[�ԍ�
-- 2020/12/03 Ver1.1 ADD End
        ,CASE
           WHEN   TRUNC( g_selling_trns_rec.selling_date, 'MM' )
                = TRUNC( gd_process_date                , 'MM' )
           THEN
             cv_xsti_decision_flag_news
           ELSE
             gv_param_info_class
         END                                                              -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- GL�A�gID
        ,NULL                                                             -- ���GL�A�gID
-- 2020/12/03 Ver1.1 ADD End
        ,cn_created_by                                                    -- �쐬��
        ,cd_creation_date                                                 -- �쐬��
        ,cn_last_updated_by                                               -- �ŏI�X�V��
        ,cd_last_update_date                                              -- �ŏI�X�V��
        ,cn_last_update_login                                             -- �ŏI�X�V���O�C��
        ,cn_request_id                                                    -- �v��ID
        ,cn_program_application_id                                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                                                    -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date                                           -- �v���O�����X�V��
    );
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END insert_deduction;
--
  /**********************************************************************************
   * Procedure Name   : sell_trns_cul
   * Description      : ���ѐU�֍T���f�[�^�Z�o(B-5)
   ***********************************************************************************/
  PROCEDURE sell_trns_cul(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sell_trns_cul';                                 -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_base_code    VARCHAR2(100);                          -- �T���z�Z�o�G���[���b�Z�[�W�p
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- ============================================================
    -- ���ʊ֐� �T���z�Z�o
    -- ============================================================
    xxcok_common2_pkg.calculate_deduction_amount_p(
      ov_errbuf                     =>  lv_errbuf                                     -- �G���[�o�b�t�@
     ,ov_retcode                    =>  lv_retcode                                    -- ���^�[���R�[�h
     ,ov_errmsg                     =>  lv_errmsg                                     -- �G���[���b�Z�[�W
     ,iv_item_code                  =>  g_selling_trns_rec.item_code                  -- �i�ڃR�[�h
     ,iv_sales_uom_code             =>  g_selling_trns_rec.unit_type                  -- �̔��P��
     ,in_sales_quantity             =>  g_selling_trns_rec.qty                        -- �̔�����
     ,in_sale_pure_amount           =>  g_selling_trns_rec.selling_amt_no_tax         -- ����{�̋��z
     ,iv_tax_code_trn               =>  g_selling_trns_rec.tax_code                   -- �ŃR�[�h(TRN)
     ,in_tax_rate_trn               =>  g_selling_trns_rec.tax_rate                   -- �ŗ�(TRN)
     ,iv_deduction_type             =>  g_selling_trns_rec.attribute2                 -- �T���^�C�v
     ,iv_uom_code                   =>  g_selling_trns_rec.uom_code                   -- �P��(����)
     ,iv_target_category            =>  g_selling_trns_rec.target_category            -- �Ώۋ敪
     ,in_shop_pay_1                 =>  g_selling_trns_rec.shop_pay_1                 -- �X�[(��)
     ,in_material_rate_1            =>  g_selling_trns_rec.material_rate_1            -- ����(��)
     ,in_condition_unit_price_en_2  =>  g_selling_trns_rec.condition_unit_price_en_2  -- �����P���Q(�~)
     ,in_accrued_en_3               =>  g_selling_trns_rec.accrued_en_3               -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
     ,in_compensation_en_3          =>  g_selling_trns_rec.compensation_en_3          -- ��U(�~)
     ,in_wholesale_margin_en_3      =>  g_selling_trns_rec.wholesale_margin_en_3      -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
     ,in_accrued_en_4               =>  g_selling_trns_rec.accrued_en_4               -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
     ,in_just_condition_en_4        =>  g_selling_trns_rec.just_condition_en_4        -- �������(�~)
     ,in_wholesale_adj_margin_en_4  =>  g_selling_trns_rec.wholesale_adj_margin_en_4  -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
     ,in_condition_unit_price_en_5  =>  g_selling_trns_rec.condition_unit_price_en_5  -- �����P���T(�~)
     ,in_deduction_unit_price_en_6  =>  g_selling_trns_rec.deduction_unit_price_en_6  -- �T���P��(�~)
     ,iv_tax_code_mst               =>  g_selling_trns_rec.tax_code_mst               -- �ŃR�[�h(MST)
     ,in_tax_rate_mst               =>  g_selling_trns_rec.tax_rate_mst               -- �ŗ�(MST)
     ,ov_deduction_uom_code         =>  gv_deduction_uom_code                         -- �T���P��
     ,on_deduction_unit_price       =>  gn_deduction_unit_price                       -- �T���P��
     ,on_deduction_quantity         =>  gn_deduction_quantity                         -- �T������
     ,on_deduction_amount           =>  gn_deduction_amount                           -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
     ,on_compensation               =>  gn_compensation                               -- ��U
     ,on_margin                     =>  gn_margin                                     -- �≮�}�[�W��
     ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                   -- �g��
     ,on_margin_reduction           =>  gn_margin_reduction                           -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
     ,on_deduction_tax_amount       =>  gn_deduction_tax_amount                       -- �T���Ŋz
     ,ov_tax_code                   =>  gv_tax_code                                   -- �ŃR�[�h
     ,on_tax_rate                   =>  gn_tax_rate                                   -- �ŗ�
    );
--
    -- �T���z�Z�o������I���łȂ��ꍇ
    IF ( lv_retcode  !=  cv_status_normal ) THEN
      -- ��ƃR�[�h��NULL�ȊO�̏ꍇ
      IF ( g_selling_trns_rec.corp_code IS  NOT NULL ) THEN
        SELECT  MAX(ffv.attribute2) AS base_code                                      -- �{���S�����_(���)
        INTO    lv_base_code
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   ffvs.flex_value_set_name  = 'XX03_BUSINESS_TYPE'
        AND     ffv.flex_value_set_id     = ffvs.flex_value_set_id
        AND     ffv.flex_value            = g_selling_trns_rec.corp_code;
      -- �T���p�`�F�[���R�[�h��NULL�ȊO�̏ꍇ
      ELSIF ( g_selling_trns_rec.deduction_chain_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.attribute3;                              -- �{���S�����_(�T���p�`�F�[��)
      -- �ڋq�R�[�h(����)��NULL�ȊO�̏ꍇ
      ELSIF ( g_selling_trns_rec.customer_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.sale_base_code;                          -- ���㋒�_(�ڋq)
      END IF;
      -- �T���z�Z�o�G���[���b�Z�[�W�̏o��
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name_cok
                     ,cv_msg_cok_10685
                     ,cv_tkn_line_id
                     ,g_selling_trns_rec.selling_trns_info_id
                     ,cv_tkn_item_code
                     ,g_selling_trns_rec.item_code
                     ,cv_tkn_sales_uom_code
                     ,g_selling_trns_rec.unit_type
                     ,cv_tkn_condition_no
                     ,g_selling_trns_rec.condition_no
                     ,cv_tkn_base_code
                     ,lv_base_code
                     ,cv_tkn_errmsg
                     ,lv_errmsg
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
        );
--
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ END  #################################
--
  END sell_trns_cul;
--
  /**********************************************************************************
   * Procedure Name   : transfer_data_get
   * Description      : ���ѐU�փf�[�^���o(B-4)
   ***********************************************************************************/
  PROCEDURE transfer_data_get(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'transfer_data_get';                              -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN  g_actual_trns_cur;
    -- �f�[�^�擾
    FETCH g_actual_trns_cur INTO g_selling_trns_rec;
--
    -- �擾�f�[�^���O���̏ꍇ
    IF ( g_actual_trns_cur%NOTFOUND )  THEN
      -- �x���X�e�[�^�X�̊i�[
      ov_retcode := cv_status_warn;
      -- �ΏۂȂ����b�Z�[�W�̏o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cok
                   ,iv_name         => cv_msg_cok_00001
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    LOOP
      EXIT  WHEN  g_actual_trns_cur%NOTFOUND;
        -- �Ώی������C���N�������g
        gn_target_cnt :=  gn_target_cnt + 1;
        -- ============================================================
        -- �̔��T���f�[�^�Z�o(B-5)
        -- ============================================================
        sell_trns_cul(
          ov_errbuf   =>  lv_errbuf                       -- �G���[�E���b�Z�[�W
         ,ov_retcode  =>  lv_retcode                      -- ���^�[���E�R�[�h
         ,ov_errmsg   =>  lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W
         );
--
        -- �̔��T���f�[�^�Z�o������I�������ꍇ
        IF ( lv_retcode  = cv_status_normal ) THEN
          -- ============================================================
          -- �̔��T���f�[�^�o�^(B-6)
          -- ============================================================
          insert_deduction(
            ov_errbuf   =>  lv_errbuf                     -- �G���[�E���b�Z�[�W
           ,ov_retcode  =>  lv_retcode                    -- ���^�[���E�R�[�h
           ,ov_errmsg   =>  lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
           );
--
          -- �f�[�^�o�^������I�������ꍇ
          IF ( lv_retcode = cv_status_normal ) THEN
            gn_normal_cnt := gn_normal_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        -- �̔��T���f�[�^�Z�o�Ōx��������
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
          gn_skip_cnt := gn_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
        -- ���̃f�[�^���擾
        FETCH g_actual_trns_cur INTO g_selling_trns_rec;
--
    END LOOP;
    -- �J�[�\�����N���[�Y
    CLOSE g_actual_trns_cur;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END transfer_data_get;
--
  /**********************************************************************************
   * Procedure Name   : reversing_data_delite
   * Description      : �U�߃f�[�^�폜����(B-3)
   ***********************************************************************************/
  PROCEDURE reversing_data_delite(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reversing_data_delite';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���J�[�\�� ***
    CURSOR l_sales_dedu_delete_cur
    IS
      SELECT xsd.sales_deduction_id       AS sales_deduction_id
      FROM   xxcok_sales_deduction        xsd
      WHERE  xsd.source_category          = 'V'
      AND    xsd.status                   = 'N'
      AND    xsd.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xsd.report_decision_flag �j
      AND    xsd.record_date             >= gd_target_date_from
      AND    xsd.record_date             <= gd_target_date_to
      FOR UPDATE NOWAIT
    ;
--
    sales_dedu_delete_rec          l_sales_dedu_delete_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    OPEN  l_sales_dedu_delete_cur;
    FETCH l_sales_dedu_delete_cur INTO sales_dedu_delete_rec;
    CLOSE l_sales_dedu_delete_cur;
    -- �U�߃f�[�^�폜
    DELETE
    FROM   xxcok_sales_deduction    xsd
    WHERE  xsd.source_category          = 'V'
    AND    xsd.status                   = 'N'
    AND    xsd.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xsd.report_decision_flag �j
    AND    xsd.record_date             >= gd_target_date_from
    AND    xsd.record_date             <= gd_target_date_to
    ;
--

  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      -- ���b�N�G���[���b�Z�[�W
      ov_errmsg := xxccp_common_pkg.get_msg( cv_appl_short_name_cok
                                            ,cv_msg_cok_10632
                                             );
      ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END reversing_data_delite;
--
  /**********************************************************************************
   * Procedure Name   : reversing_data_create
   * Description      : �U�߃f�[�^�쐬����(B-2)
   ***********************************************************************************/
  PROCEDURE reversing_data_create(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reversing_data_create';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================================
    -- �U�߃f�[�^�쐬����(�̔��T��)
    --==================================================
      --==================================================
      -- �T���U�֐U�߃e�[�u���o�^
      --==================================================
      INSERT INTO xxcok_dedu_trn_rev(
-- 2020/12/03 Ver1.1 MOD Start
        sales_deduction_id                             -- �̔��T��ID
      , base_code_from                                 -- �U�֌����_
--        base_code_from                                 -- �U�֌����_
-- 2020/12/03 Ver1.1 MOD End
      , base_code_to                                   -- �U�֐拒�_
      , customer_code_from                             -- �U�֌��ڋq�R�[�h
      , customer_code_to                               -- �U�֐�ڋq�R�[�h
      , record_date                                    -- �v���
-- 2020/12/03 Ver1.1 ADD Start
      , source_line_id                                 -- �쐬������ID
      , condition_id                                   -- �T������ID
      , condition_no                                   -- �T���ԍ�
      , condition_line_id                              -- �T���ڍ�ID
      , data_type                                      -- �f�[�^���
-- 2020/12/03 Ver1.1 ADD End
      , item_code                                      -- �i�ڃR�[�h
      , sales_quantity                                 -- �̔�����
      , sales_uom_code                                 -- �̔��P��
      , sales_unit_price                               -- �̔��P��
      , sale_pure_amount                               -- ����{�̋��z
      , sale_tax_amount                                -- �������Ŋz
      , deduction_quantity                             -- �T������
      , deduction_uom_code                             -- �T���P��
      , deduction_unit_price                           -- �T���P��
      , deduction_amount                               -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
      , compensation                                   -- ��U
      , margin                                         -- �≮�}�[�W��
      , sales_promotion_expenses                       -- �g��
      , margin_reduction                               -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
      , tax_code                                       -- �ŃR�[�h
      , tax_rate                                       -- �ŗ�
-- 2020/12/03 Ver1.1 DEL Start
--      , recon_tax_code                                 -- �������ŃR�[�h
--      , recon_tax_rate                                 -- �������ŗ�
-- 2020/12/03 Ver1.1 DEL End
      , deduction_tax_amount                           -- �T���Ŋz
      , created_by                                     -- �쐬��
      , creation_date                                  -- �쐬��
      , last_updated_by                                -- �ŏI�X�V��
      , last_update_date                               -- �ŏI�X�V��
      , last_update_login                              -- �ŏI�X�V���O�C��
      , request_id                                     -- �v��ID
      , program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                                     -- �R���J�����g�E�v���O����ID
      , program_update_date                            -- �v���O�����X�V��
      )
      SELECT
-- 2020/12/03 Ver1.1 MOD Start
        xsd.sales_deduction_id                         -- �̔��T��ID
      , xsd.base_code_from                             -- �U�֌����_
--        xsd.base_code_from                             -- �U�֌����_
-- 2020/12/03 Ver1.1 MOD End
      , xsd.base_code_to                               -- �U�֐拒�_
      , xsd.customer_code_from                         -- �U�֌��ڋq�R�[�h
      , xsd.customer_code_to                           -- �U�֐�ڋq�R�[�h
      , xsd.record_date                                -- �v���
-- 2020/12/03 Ver1.1 ADD Start
      , xsd.source_line_id                             -- �쐬������ID
      , xsd.condition_id                               -- �T������ID
      , xsd.condition_no                               -- �T���ԍ�
      , xsd.condition_line_id                          -- �T���ڍ�ID
      , xsd.data_type                                  -- �f�[�^���
-- 2020/12/03 Ver1.1 ADD End
      , xsd.item_code                                  -- �i�ڃR�[�h
      , xsd.sales_quantity * -1                        -- �̔�����
      , xsd.sales_uom_code                             -- �̔��P��
      , xsd.sales_unit_price                           -- �̔��P��
      , xsd.sale_pure_amount * -1                      -- ����{�̋��z
      , xsd.sale_tax_amount  * -1                      -- �������Ŋz
      , xsd.deduction_quantity * -1                    -- �T������
      , xsd.deduction_uom_code                         -- �T���P��
      , xsd.deduction_unit_price                       -- �T���P��
      , xsd.deduction_amount * -1                      -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
      , xsd.compensation * -1                          -- ��U
      , xsd.margin * -1                                -- �≮�}�[�W��
      , xsd.sales_promotion_expenses * -1              -- �g��
      , xsd.margin_reduction * -1                      -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
      , xsd.tax_code                                   -- �ŃR�[�h
      , xsd.tax_rate                                   -- �ŗ�
-- 2020/12/03 Ver1.1 DEL Start
--      , xsd.recon_tax_code                             -- �������ŃR�[�h
--      , xsd.recon_tax_rate                             -- �������ŗ�
-- 2020/12/03 Ver1.1 DEL End
      , xsd.deduction_tax_amount * -1                  -- �T���Ŋz
      , cn_created_by                                  -- �쐬��
      , SYSDATE                                        -- �쐬��
      , cn_last_updated_by                             -- �ŏI�X�V��
      , SYSDATE                                        -- �ŏI�X�V��
      , cn_last_update_login                           -- �ŏI�X�V���O�C��
      , cn_request_id                                  -- �v��ID
      , cn_program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                                  -- �R���J�����g�E�v���O����ID
      , SYSDATE                                        -- �v���O�����X�V��
      FROM    xxcok_sales_deduction    xsd
      WHERE   xsd.source_category       = 'V'
      AND     xsd.report_decision_flag  = '0'
      AND     xsd.record_date          >= gd_target_date_from
      AND     xsd.record_date          <= gd_target_date_to
      ;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END reversing_data_create;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                         -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_period_status               VARCHAR2(10)   DEFAULT NULL;                 -- ��v���ԃX�e�[�^�X�`�F�b�N�p�߂�l
    ld_target_date_from            DATE           DEFAULT NULL;                 -- ��v���Ԋ֐�OUT�擾�p(�_�~�[)
    ld_target_date_to              DATE           DEFAULT NULL;                 -- ��v���Ԋ֐�OUT�擾�p(�_�~�[)
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �����
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00023
                  , iv_token_name1          => cv_tkn_info_class
                  , iv_token_value1         => iv_info_class
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg         -- ���b�Z�[�W
                  , in_new_line             => 0                  -- ���s
                  );
    --==============================================================
    -- 1.����ʃ`�F�b�N
    --==============================================================
    IF( iv_info_class NOT IN ( cv_info_class_news, cv_info_class_decision ) ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10036
                    , iv_token_name1          => cv_tkn_info_class
                    , iv_token_value1         => iv_info_class
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���O�������͍��ڂ��O���[�o���ϐ��֊i�[
    --==================================================
    gv_param_info_class := iv_info_class;
--
    --==============================================================
    -- 2.�Ɩ����t�擾
    --==============================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==============================================================
    -- 3.��v���ԏ�ԃ`�F�b�N
    --==============================================================
    -- ������v���ԃ`�F�b�N
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv       -- IN  VARCHAR2 '01'(��v����INV)
    , id_base_date        => gd_process_date         -- IN  DATE     ������(�Ώۓ�)
    , ov_status           => lv_period_status        -- OUT VARCHAR2 �X�e�[�^�X
    , od_start_date       => ld_target_date_from     -- OUT DATE     ��v����(FROM)
    , od_end_date         => ld_target_date_to       -- OUT DATE     ��v����(TO)
    , ov_errbuf           => lv_errbuf               -- OUT VARCHAR2 �G���[�E���b�Z�[�W�G���[
    , ov_retcode          => lv_retcode              -- OUT VARCHAR2 ���^�[���E�R�[�h
    , ov_errmsg           => lv_errmsg               -- OUT VARCHAR2 ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( gd_process_date, 'MM' );
      gd_target_date_to   := gd_process_date;
    ELSE
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_process_date, 'RRRR/MM' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    -- �O����v���ԃ`�F�b�N
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv                  -- IN  VARCHAR2 '01'(��v����INV)
    , id_base_date        => ADD_MONTHS( gd_process_date, - 1 ) -- IN  DATE     ������(�Ώۓ�)
    , ov_status           => lv_period_status                   -- OUT VARCHAR2 �X�e�[�^�X
    , od_start_date       => ld_target_date_from                -- OUT DATE     ��v����(FROM)
    , od_end_date         => ld_target_date_to                  -- OUT DATE     ��v����(TO)
    , ov_errbuf           => lv_errbuf                          -- OUT VARCHAR2 �G���[�E���b�Z�[�W�G���[
    , ov_retcode          => lv_retcode                         -- OUT VARCHAR2 ���^�[���E�R�[�h
    , ov_errmsg           => lv_errmsg                          -- OUT VARCHAR2 ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(B-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- �U�߃f�[�^�쐬����(B-2)
    --==================================================
    reversing_data_create(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- �U�߃f�[�^�폜����(B-3)
    --==================================================
    reversing_data_delite(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- ���ѐU�փf�[�^���o(B-4)
    --==================================================
    transfer_data_get(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_info_class                  IN  VARCHAR2        -- �����
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message               => NULL               -- ���b�Z�[�W
                  , in_new_line              => 1                  -- ���s
                  );
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_info_class           => iv_info_class         -- �����
    );
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- �o�͋敪
                    , iv_message               => lv_errmsg           -- ���b�Z�[�W
                    , in_new_line              => 1                   -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�L�b�v�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK024A05C;
/
