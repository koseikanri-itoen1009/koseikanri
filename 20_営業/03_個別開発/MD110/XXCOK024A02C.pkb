CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A02C (body)
 * Description      : �T���}�X�^CSV�o��
 * MD.050           : �T���}�X�^CSV�o�� MD050_COK_024_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_order_list_cond    �T���}�X�^���o(A-2)
 *  output_data            �f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/21    1.0   Y.Nakajima       �V�K�쐬
 *  2021/04/06    1.1   K.Yoshikawa      ��z�T���������בΉ�
 
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;  -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �o�͓� ���t�t�]�`�F�b�N��O ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                    -- ��؂蕶��
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                     -- �󕶎�
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                    -- �X�y�[�X
  cv_full_space               CONSTANT  VARCHAR2(4)   := '�@';                   -- �S�p�X�y�[�X
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                    -- 'Y'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                    -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );      -- ����
  -- �v���t�@�C��
  cv_item_div                 CONSTANT  VARCHAR2(30)  := 'XXCOS1_ITEM_DIV_H';    -- �{�Џ��i�敪
  -- ���l
  cn_zero                     CONSTANT  NUMBER        := 0;                      -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                      -- 1
  cv_min_date                 CONSTANT  VARCHAR2(10)  := '1900/01/01';           -- �ŏ����t
  cv_max_date                 CONSTANT  VARCHAR2(10)  := '9999/12/31';           -- �ő���t
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A02C';         -- �p�b�P�[�W��
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                -- �̕��̈�Z�k�A�v����
  -- �����}�X�N
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- ���t����
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- ���t����(����)
  -- �Q�ƃ^�C�v
  cv_type_business_type       CONSTANT  VARCHAR2(30)  := 'XX03_BUSINESS_TYPE';            -- ��ƃR�[�h
  cv_type_chain_code          CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';              -- �T���p�`�F�[���R�[�h
  cv_type_header              CONSTANT  VARCHAR2(30)  := 'XXCOK1_EXCEL_OUTPUT_HEADER_1';  -- �T���}�X�^�o�͗p���o��
  cv_type_dec_pri_base        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- �T���}�X�^�������_
  cv_type_dec_del_dept        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_DEL_PRI_DEPT';       -- �T���}�X�^�폜��������
  cv_type_deduction_data      CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- �T���f�[�^���
  cv_type_deduction_1_kbn     CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_1_KBN';        -- �Ώۋ敪
  --���b�Z�[�W
  cv_msg_para_code_null_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10679';     -- �K�{�p�����[�^���ݒ�G���[�i��ƃR�[�h�A�T���p�`�F�[���R�[�h�A�ڋq�R�[�h�j
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';     -- ���t�t�]�G���[
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10570';     -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_parameter2           CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10571';     -- �p�����[�^�o�̓��b�Z�[�W2
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';     -- ���[�U�[ID�擾�G���[���b�Z�[�W
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';     -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';     -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_date_from         CONSTANT  VARCHAR2(100) := 'DATE_FROM';            -- �J�n��
  cv_tkn_nm_date_to           CONSTANT  VARCHAR2(100) := 'DATE_TO';              -- �I����
  cv_tkn_nm_deduction_no      CONSTANT  VARCHAR2(100) := 'DEDUCTION_NO';         -- �T���ԍ�
  cv_tkn_nm_corp_code         CONSTANT  VARCHAR2(100) := 'CORP_CODE';            -- ��ƃR�[�h
  cv_tkn_nm_intoduction_code  CONSTANT  VARCHAR2(100) := 'CHAIN_CODE';           -- �T���p�`�F�[���R�[�h
  cv_tkn_ship_cust_code       CONSTANT  VARCHAR2(100) := 'CUST_CODE';            -- �ڋq�R�[�h
  cv_tkn_nm_date_type         CONSTANT  VARCHAR2(100) := 'DATE_TYPE';            -- �f�[�^���
  cv_tkn_nm_tax_code          CONSTANT  VARCHAR2(100) := 'TAX_CODE';             -- �ŃR�[�h
  cv_tkn_nm_content           CONSTANT  VARCHAR2(100) := 'CONTENT';              -- ���e
  cv_tkn_nm_decision_no       CONSTANT  VARCHAR2(100) := 'DECISION_NO';          -- ����No
  cv_tkn_nm_agreemen_no       CONSTANT  VARCHAR2(100) := 'AGREEMENT_NO';         -- �_��ԍ�
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';              -- ���[�U�[ID
  cv_tkn_nm_last_update       CONSTANT  VARCHAR2(100) := 'LAST_UPDATE';          -- �ŏI�X�V��
  cv_profile_tok              CONSTANT  VARCHAR2(20)  := 'PROFILE';              -- �v���t�@�C����
  --�g�[�N���l
  -- �T���^�C�v
  cv_condition_type_sale      CONSTANT  VARCHAR2(3)   := '020';                  -- �T���^�C�v(�̔����ʁ~���z)
  cv_condition_type_spons     CONSTANT  VARCHAR2(3)   := '050';                  -- �T���^�C�v(��z���^��)
  cv_condition_type_pre_spons CONSTANT  VARCHAR2(3)   := '060';                  -- �T���^�C�v(�Ώې��ʗ\�����^��)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date              DATE;                                                -- �Ɩ����t
  gn_user_id                NUMBER;                                              -- ���[�U�[ID
  gv_user_base_code         VARCHAR2(150);                                       -- �������_�R�[�h
  gn_privilege_dept         NUMBER;                                              -- �폜�����i0�F�����Ȃ��A1�F��������j
  gn_privilege_base         NUMBER;                                              -- �o�^�E�X�V�����i0�F�����Ȃ��A1�F��������j
  gv_privilege_flag         VARCHAR2(1);                                         -- �������[�U�[���f�t���O
  gv_data_type              VARCHAR2(10);                                        -- �f�[�^���
  gv_item_div_h             VARCHAR2(20);                                        -- �{�Џ��i�敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  CURSOR get_deduction_list_data_cur (
           iv_order_deduction_no           VARCHAR2  -- �T���ԍ�
          ,iv_corp_code                    VARCHAR2  -- ��ƃR�[�h
          ,iv_introduction_code            VARCHAR2  -- �T���p�`�F�[���R�[�h
          ,iv_ship_cust_code               VARCHAR2  -- �ڋq�R�[�h
          ,iv_data_type                    VARCHAR2  -- �f�[�^���
          ,iv_tax_code                     VARCHAR2  -- �ŃR�[�h
          ,iv_order_list_date_from         VARCHAR2  -- �J�n��
          ,iv_order_list_date_to           VARCHAR2  -- �I����
          ,iv_content                      VARCHAR2  -- ���e
          ,iv_decision_no                  VARCHAR2  -- ����No
          ,iv_agreement_no                 VARCHAR2  -- �_��ԍ�
          ,iv_last_update_date             VARCHAR2  -- �ŏI�X�V��
          )
  IS
    SELECT 
            /*+ LEADING(mst@a)
            NO_PUSH_PRED(mst@a)
            USE_NL(mst@a xch)
            INDEX(XCH XXCOK_CONDITION_HEADER_PK) */
           xch.condition_no                             AS condition_no                            -- �T���ԍ�
          ,xch.corp_code                                AS corp_code                               -- ��ƃR�[�h
          ,xch.deduction_chain_code                     AS deduction_chain_code                    -- �T���p�`�F�[���R�[�h
          ,xch.customer_code                            AS customer_code                           -- �ڋq�R�[�h
          ,flvv2.meaning                                AS data_type                               -- �f�[�^���
          ,xch.start_date_active                        AS start_date_active                       -- �J�n��
          ,xch.end_date_active                          AS end_date_active                         -- �I����
          ,xch.content                                  AS content                                 -- ���e
          ,xch.decision_no                              AS decision_no                             -- ����No
          ,xch.agreement_no                             AS agreement_no                            -- �_��ԍ�
          ,xcl.detail_number                            AS detail_number                           -- ���הԍ�
          ,flv.meaning                                  AS target_category                         -- �Ώۋ敪
          ,pro.product_class                            AS product_class                           -- ���i�敪
          ,xcl.item_code                                AS item_code                               -- �i�ڃR�[�h
          ,xcl.uom_code                                 AS uom_code                                -- �P��
          ,xcl.shop_pay_1                               AS shop_pay_1                              -- �X�[(%)
          ,xcl.material_rate_1                          AS material_rate                           -- ����(%)
          ,xcl.demand_en_3                              AS demand_en                               -- ����(�~)
          ,xcl.shop_pay_en_3                            AS shop_pay_en                             -- �X�[(�~)
          ,xcl.dl_wholesale_margin_en                   AS wholesale_margin_en                     -- DL�p�≮�}�[�W��(�~)
          ,xcl.dl_wholesale_margin_per                  AS wholesale_margin_per                    -- DL�p�≮�}�[�W��(��)
          ,xcl.normal_shop_pay_en_4                     AS normal_shop_pay_en                      -- �ʏ�X�[(�~)
          ,xcl.just_shop_pay_en_4                       AS just_shop_pay_en                        -- ����X�[(�~)
          ,xcl.dl_wholesale_adj_margin_en               AS wholesale_adj_margin_en                 -- DL�p�≮�}�[�W���C��(�~)
          ,xcl.dl_wholesale_adj_margin_per              AS wholesale_adj_margin_per                -- DL�p�≮�}�[�W���C��(��)
          ,CASE
             -- �T���^�C�v��'050'�̏ꍇ
             WHEN  flvv2.attribute2 = cv_condition_type_spons THEN
                xcl.prediction_qty_5
             -- �T���^�C�v��'060'�̏ꍇ
             WHEN  flvv2.attribute2 = cv_condition_type_pre_spons THEN
                xcl.prediction_qty_6
             END                                        AS prediction_qty                          -- �\������(�{)
          ,xcl.support_amount_sum_en_5                  AS support_amount_sum_en                   -- ���^�����v(�~)
          ,CASE
             -- �T���^�C�v��'020'�̏ꍇ
             WHEN  flvv2.attribute2 = cv_condition_type_sale THEN
                xcl.condition_unit_price_en_2
             -- �T���^�C�v��'060'�̏ꍇ
             WHEN  flvv2.attribute2 = cv_condition_type_pre_spons THEN
                xcl.condition_unit_price_en_6
             END                                        AS condition_unit_price_en                 -- �����P��(�~)
          
          ,xcl.target_rate_6                            AS target_rate6                            -- �Ώۗ�(��)
          ,xcl.accounting_base                          AS accounting_base                         -- �v�㋒�_
-- 2021/04/06 Ver1.1 ADD Start
          ,xcl.accounting_customer_code                 AS accounting_customer_code                -- �v��ڋq
-- 2021/04/06 Ver1.1 ADD End
          ,xcl.deduction_amount                         AS deduction_amount                        -- �T���z(�{��)
          ,xch.tax_code                                 AS tax_code                                -- �ŃR�[�h
          ,xcl.deduction_tax_amount                     AS deduction_tax_amount                    -- �T���Ŋz
          ,xch.last_update_date                         AS head_last_update_date                   -- �w�b�_�ŏI�X�V��
          ,papf.employee_number                         AS head_employee_number                    -- �w�b�_�ŏI�X�V�ҏ]�ƈ��ԍ�
          ,papf.per_information18                       AS head_last_update_by_last                -- �w�b�_�ŏI�X�V�Ґ�
          ,papf.per_information19                       AS head_last_update_by_first               -- �w�b�_�ŏI�X�V�Җ�
          ,xcl.last_update_date                         AS line_last_update_date                   -- ���׍ŏI�X�V��
          ,papf2.employee_number                        AS line_employee_number                    -- ���׍ŏI�X�V�ҏ]�ƈ��ԍ�
          ,papf2.per_information18                      AS line_last_update_by_last                -- ���׍ŏI�X�V�Ґ�
          ,papf2.per_information19                      AS line_last_update_by_first               -- ���׍ŏI�X�V�Җ�
    FROM xxcok_condition_header       xch                                                          -- �T�������e�[�u��
        ,xxcok_condition_lines        xcl                                                          -- �T���ڍ׃e�[�u��
        ,fnd_flex_values_vl           ffvv                                                         -- ��ƃ}�X�^
        ,fnd_lookup_values_vl         flvv1                                                        -- �`�F�[���}�X�^
        ,xxcmm_cust_accounts          xca                                                          -- �ڋq�}�X�^
-- 2021/04/06 Ver1.1 ADD Start
        ,xxcmm_cust_accounts          xca2                                                         -- �ڋq�}�X�^2
-- 2021/04/06 Ver1.1 ADD End
        ,fnd_lookup_values_vl         flvv2                                                        -- �T���f�[�^���
        ,fnd_user                     fu                                                           -- ���[�U�[�}�X�^
        ,fnd_user                     fu2                                                          -- ���[�U�[�}�X�^2
        ,per_all_people_f             papf                                                         -- �]�ƈ��}�X�^
        ,per_all_people_f             papf2                                                        -- �]�ƈ��}�X�^2
        ,fnd_lookup_values            flv                                                          -- �Ώۋ敪
       ,(SELECT /*+ QB_NAME(a) */
                mst2.CONDITION_ID AS CONDITION_ID
         FROM
         (-- 1.��Ǝw�莞
          SELECT /*+ INDEX(xch1 XXCOK_CONDITION_HEADER_N01) */
                 xch1.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch1
          WHERE  iv_corp_code                     IS NOT NULL
          AND    xch1.corp_code                 = iv_corp_code
          UNION
          -- 2.�`�F�[���w�莞
          SELECT /*+ INDEX(xch2 XXCOK_CONDITION_HEADER_N02) */
                 xch2.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch2
          WHERE  iv_introduction_code             IS NOT NULL
          AND    xch2.deduction_chain_code   = iv_introduction_code
          UNION
          -- 3.�ڋq�w�莞
          SELECT /*+ INDEX(xch3 XXCOK_CONDITION_HEADER_N03) */
                 xch3.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch3
          WHERE  iv_ship_cust_code                IS NOT NULL
          AND    xch3.customer_code             = iv_ship_cust_code
          UNION
          -- 4.�T���ԍ��̂ݎw�莞
          SELECT /*+ INDEX(xch4 XXCOK_CONDITION_HEADER_N04) */
                 xch4.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch4
          WHERE  iv_order_deduction_no IS NOT NULL                  -- �T���ԍ�
          AND    iv_corp_code          IS NULL                      -- ��ƃR�[�h
          AND    iv_introduction_code  IS NULL                      -- �T���p�`�F�[���R�[�h
          AND    iv_ship_cust_code     IS NULL                      -- �ڋq�R�[�h
          AND    iv_last_update_date   IS NULL                      -- �ŏI�X�V��
          AND    xch4.condition_no     = iv_order_deduction_no
          UNION
          -- �u5.�ŏI�X�V���̂݁vor�u6.�ŏI�X�V���ƍT���ԍ��̂݁v�w�莞
          SELECT /*+ INDEX(xch5 XXCOK_CONDITION_HEADER_N05) */
                 xch5.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch5
          WHERE  iv_corp_code          IS NULL                      -- ��ƃR�[�h
          AND    iv_introduction_code  IS NULL                      -- �T���p�`�F�[���R�[�h
          AND    iv_ship_cust_code     IS NULL                      -- �ڋq�R�[�h
          AND    iv_last_update_date   IS NOT NULL                  -- �ŏI�X�V��
          AND    xch5.last_update_date >= TO_DATE(iv_last_update_date,cv_date_format)
          ) mst2
        ) mst                                                          -- �p�����[�^���ʗp�C�����C���r���[
       ,(SELECT mcv.segment1     product_class_code
               ,mcv.description  product_class
         FROM   mtl_categories_vl    mcv
               ,mtl_category_sets_vl mcsv
         WHERE  mcsv.structure_id      = mcv.structure_id
         AND    mcsv.category_set_name = gv_item_div_h
        )                             pro
    WHERE 1 = 1
    AND    mst.condition_id                       = xch.condition_id                               -- �C�����C���r���[.�T������ID �� �T������.�T������ID
    AND    xch.condition_id                       = xcl.condition_id                               -- �T������.�T������ID         �� �T���ڍ�.�T������ID
    AND    xch.enabled_flag_h                     = cv_const_y                                     -- �T������.�L���t���O         �� Y
    AND    xcl.enabled_flag_l                     = cv_const_y                                     -- �T���ڍ�.�L���t���O         �� Y
    -- �T���f�[�^���
    AND    xch.data_type                          = flvv2.lookup_code
    AND    flvv2.lookup_type                      = cv_type_deduction_data
    -- ���
    AND    xch.corp_code                          = ffvv.flex_value(+)                             -- �T������.��ƃR�[�h         �� ��ƃ}�X�^.��ƃR�[�h
    AND    ffvv.value_category(+)                 = cv_type_business_type
    -- �`�F�[��
    AND    xch.deduction_chain_code               = flvv1.lookup_code(+)                           -- �T������.�T���p�`�F�[���R�[�h     �� �`�F�[���}�X�^.�T���p�`�F�[���R�[�h
    AND    flvv1.lookup_type(+)                   = cv_type_chain_code
    -- �ڋq
    AND    xch.customer_code                      = xca.customer_code(+)                           -- �T������.�ڋq�R�[�h         �� �ڋq�}�X�^.�ڋq�R�[�h
    -- �v��ڋq
    AND    xcl.accounting_customer_code           = xca2.customer_code(+)                          -- �T���ڍ�.�v��ڋq�R�[�h     �� �ڋq�}�X�^2.�ڋq�R�[�h
    -- �p�����[�^
    AND    (iv_order_deduction_no     IS NULL                                                                                                -- �p�����[�^.�T���ԍ�         IS NULL
      OR    xch.condition_no          = iv_order_deduction_no)                                                                               -- �T������.�T���ԍ�           �� �p�����[�^.�T���ԍ�
    AND    (iv_data_type              IS NULL                                                                                                -- �p�����[�^.�f�[�^���       IS NULL
      OR    flvv2.meaning             = iv_data_type)                                                                                        -- �T���f�[�^���.���e         �� �p�����[�^.�f�[�^���
    AND    (iv_tax_code               IS NULL                                                                                                -- �p�����[�^.�ŃR�[�h         IS NULL
      OR    xch.tax_code              = iv_tax_code)                                                                                         -- �T������.�ŃR�[�h           �� �p�����[�^.�ŃR�[�h
    AND    xch.end_date_active        >= NVL(TO_DATE(iv_order_list_date_from,cv_date_format),TO_DATE(cv_min_date,cv_date_format))            -- �T������.�I����             >= �p�����[�^.�J�n��
    AND    xch.start_date_active      <= NVL(TO_DATE(iv_order_list_date_to,  cv_date_format),TO_DATE(cv_max_date,cv_date_format))            -- �T������.�J�n��             <= �p�����[�^.�I����
    AND    (iv_content                IS NULL                                                                                                -- �p�����[�^.���e             IS NULL
      OR    xch.content               LIKE cv_perc||iv_content||cv_perc)                                                                     -- �T������.���e             LIKE �p�����[�^.���e
    AND    (iv_decision_no            IS NULL                                                                                                -- �p�����[�^.����No           IS NULL
      OR    xch.decision_no           = iv_decision_no)                                                                                      -- �T������.����No             �� �p�����[�^.����No
    AND    (iv_agreement_no           IS NULL                                                                                                -- �p�����[�^.�_��ԍ�         IS NULL
      OR    xch.agreement_no          = iv_agreement_no)                                                                                     -- �T������.�_��ԍ�           �� �p�����[�^.�_��ԍ�
    AND    (iv_last_update_date       IS NULL                                                                                                -- �p�����[�^.�ŏI�X�V��       IS NULL
      OR    xch.last_update_date      >= TO_DATE(iv_last_update_date,cv_date_format))                                                        -- �T������.�ŏI�X�V��         �� �p�����[�^.�ŏI�X�V��
    -- ���_����
    AND     (gv_privilege_flag         = cv_const_y                                     -- �������[�U�[���f�t���O      �� 'Y'
      OR     ffvv.attribute2           = gv_user_base_code                              -- ��ƃ}�X�^.�{���S�����_     �� �������_�R�[�h
      OR     flvv1.attribute3          = gv_user_base_code                              -- �`�F�[���}�X�^.�{���S�����_ �� �������_�R�[�h
      OR     xca.sale_base_code        = gv_user_base_code                              -- �ڋq.����S�����_           �� �������_�R�[�h
-- 2021/04/06 Ver1.1 MOD Start
--      OR     xcl.accounting_base       = gv_user_base_code                              -- �T���ڍ�.�v�㋒�_           �� �������_�R�[�h
      OR     xca2.sale_base_code       = gv_user_base_code                              -- �T���ڍ�.�v��ڋq           �� �������_�R�[�h
-- 2021/04/06 Ver1.1 MOD End
             )
    -- �w�b�_�]�ƈ����
    AND    fu.user_id                  = xch.last_updated_by
    AND    papf.person_id              = fu.employee_id
    AND    papf.current_employee_flag  = cv_const_y
    AND    papf.effective_start_date   IN (SELECT MAX(papf3.effective_start_date) effective_start_date
                                           FROM   per_all_people_f  papf3
                                           WHERE  papf3.current_employee_flag = cv_const_y
                                           AND    papf3.person_id             = papf.person_id)
    -- ���׏]�ƈ����
    AND    fu2.user_id                 = xcl.last_updated_by
    AND    papf2.person_id             = fu2.employee_id
    AND    papf2.current_employee_flag = cv_const_y
    AND    papf2.effective_start_date  IN (SELECT MAX(papf4.effective_start_date) effective_start_date
                                           FROM   per_all_people_f  papf4
                                           WHERE  papf4.current_employee_flag = cv_const_y
                                           AND    papf4.person_id             = papf2.person_id)
    -- �Ώۋ敪
    AND   flv.language(+)                 = cv_lang
    AND   flv.lookup_type(+)              = cv_type_deduction_1_kbn
    AND   flv.lookup_code(+)              = xcl.target_category
    -- ���i�敪
    AND   xcl.product_class               = pro.product_class_code(+)
    ORDER BY
           xch.corp_code                  -- ��ƃR�[�h
          ,xch.deduction_chain_code       -- �T���p�`�F�[���R�[�h
          ,xch.customer_code              -- �ڋq�R�[�h
          ,xch.data_type                  -- �f�[�^���
          ,xch.condition_no               -- �T���ԍ�
          ,xcl.detail_number              -- ���הԍ�
  ;
--
  -- �擾�f�[�^�i�[�ϐ���` (�S�o��)
  TYPE g_out_file_ttype IS TABLE OF get_deduction_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_deduction_no           IN     VARCHAR2     -- �T���ԍ�
   ,iv_corp_code                    IN     VARCHAR2     -- ��ƃR�[�h
   ,iv_introduction_code            IN     VARCHAR2     -- �T���p�`�F�[���R�[�h
   ,iv_ship_cust_code               IN     VARCHAR2     -- �ڋq�R�[�h
   ,iv_data_type                    IN     VARCHAR2     -- �f�[�^���
   ,iv_tax_code                     IN     VARCHAR2     -- �ŃR�[�h
   ,iv_order_list_date_from         IN     VARCHAR2     -- �J�n��
   ,iv_order_list_date_to           IN     VARCHAR2     -- �I����
   ,iv_content                      IN     VARCHAR2     -- ���e
   ,iv_decision_no                  IN     VARCHAR2     -- ����No
   ,iv_agreement_no                 IN     VARCHAR2     -- �_��ԍ�
   ,iv_last_update_date             IN     VARCHAR2     -- �ŏI�X�V��
   ,ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_para_msg                     VARCHAR2(5000);     -- �p�����[�^�o�̓��b�Z�[�W
    lv_para_msg2                    VARCHAR2(5000);     -- �p�����[�^�o�̓��b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
    gn_privilege_dept := cn_zero;
    gn_privilege_base := cn_zero;
--
--###########################  �Œ蕔 END   ############################
--
    --========================================
    -- 1.�p�����[�^�o�͏���
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- �A�v���Z�k��
                                               ,iv_name               =>  cv_msg_parameter              -- �p�����[�^�o�̓��b�Z�[�W
                                               ,iv_token_name1        =>  cv_tkn_nm_deduction_no        -- �g�[�N���F�T���ԍ�
                                               ,iv_token_value1       =>  iv_order_deduction_no         -- �T���ԍ�
                                               ,iv_token_name2        =>  cv_tkn_nm_corp_code           -- �g�[�N���F��ƃR�[�h
                                               ,iv_token_value2       =>  iv_corp_code                  -- ��ƃR�[�h
                                               ,iv_token_name3        =>  cv_tkn_nm_intoduction_code    -- �g�[�N���F�T���p�`�F�[���R�[�h
                                               ,iv_token_value3       =>  iv_introduction_code          -- �T���p�`�F�[���R�[�h
                                               ,iv_token_name4        =>  cv_tkn_ship_cust_code         -- �g�[�N���F�ڋq�R�[�h
                                               ,iv_token_value4       =>  iv_ship_cust_code             -- �ڋq�R�[�h
                                               ,iv_token_name5        =>  cv_tkn_nm_date_type           -- �g�[�N���F�f�[�^���
                                               ,iv_token_value5       =>  iv_data_type                  -- �f�[�^���
                                               ,iv_token_name6        =>  cv_tkn_nm_tax_code            -- �g�[�N���F�ŃR�[�h
                                               ,iv_token_value6       =>  iv_tax_code                   -- �ŃR�[�h
                                               ,iv_token_name7        =>  cv_tkn_nm_date_from           -- �g�[�N���F�J�n��
                                               ,iv_token_value7       =>  iv_order_list_date_from       -- �J�n��
                                               ,iv_token_name8        =>  cv_tkn_nm_date_to             -- �g�[�N���F�I����
                                               ,iv_token_value8       =>  iv_order_list_date_to         -- �I����
                                               ,iv_token_name9        =>  cv_tkn_nm_content             -- �g�[�N���F���e
                                               ,iv_token_value9       =>  iv_content                    -- ���e
                                               ,iv_token_name10       =>  cv_tkn_nm_decision_no         -- �g�[�N���F����No
                                               ,iv_token_value10      =>  iv_decision_no                -- ����No
                                               );
--
    lv_para_msg2  :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- �A�v���Z�k��
                                               ,iv_name               =>  cv_msg_parameter2             -- �p�����[�^�o�̓��b�Z�[�W
                                               ,iv_token_name1        =>  cv_tkn_nm_agreemen_no         -- �g�[�N���F�_��ԍ�
                                               ,iv_token_value1       =>  iv_agreement_no               -- �_��ԍ�
                                               ,iv_token_name2        =>  cv_tkn_nm_last_update         -- �g�[�N���F�ŏI�X�V��
                                               ,iv_token_value2       =>  iv_last_update_date           -- �ŏI�X�V��
                                               );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg2
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.�K�{�p�����[�^���̓`�F�b�N
    --========================================
    -- �T���ԍ��A��ƃR�[�h�A�T���p�`�F�[���R�[�h�A�ڋq�R�[�h�A�ŏI�X�V���̂���������͂���Ă��Ȃ��ꍇ�G���[
    IF ( iv_order_deduction_no IS NULL AND iv_corp_code IS NULL AND iv_introduction_code IS NULL AND iv_ship_cust_code IS NULL AND iv_last_update_date IS NULL) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_para_code_null_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.���t�t�]�`�F�b�N
    --========================================
    IF ( iv_order_list_date_from > iv_order_list_date_to ) THEN
      RAISE global_date_rever_old_chk_expt;
    END IF;
--
    --========================================
    -- 4.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.���[�U�[ID�擾����
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_id_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.�������_�R�[�h�擾����
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_proc_date,
      in_user_id              =>  gn_user_id
      );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_base_code_err,
        iv_token_name1        =>  cv_tkn_nm_user_id,
        iv_token_value1       =>  gn_user_id
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 7.�������[�U�[�m�F����
    --========================================
    -- 7-1 �폜�����̂��郆�[�U�[���m�F
    BEGIN
      SELECT  COUNT(1)              AS privilege_dept_cnt
      INTO    gn_privilege_dept
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type    = cv_type_dec_del_dept
      AND     flv.lookup_code    = gv_user_base_code
      AND     flv.enabled_flag   = cv_const_y
      AND     flv.language       = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 7-2 �������_�̏������[�U�[���m�F
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    gn_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 7-3 �폜�������[�U�[���������_���[�U�[�̔���
    IF ((gn_privilege_dept >= cn_one) OR (gn_privilege_base >= cn_one)) THEN
      gv_privilege_flag  := cv_const_y;
    END IF;
--
    --==============================================================
    -- 8.�{�Џ��i�敪�̎擾
    --==============================================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div );
    -- �擾�ł��Ȃ��ꍇ
    IF ( gv_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_xxcok_short_name
                     ,iv_name         =>  cv_msg_profile_err
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_item_div   -- �v���t�@�C���F�{�Џ��i�敪
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
  EXCEPTION
--
    -- ***�J�n���I���� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_old_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_date_rever_err
      );  
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : �T���}�X�^�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_order_deduction_no           IN     VARCHAR2     -- �T���ԍ�
   ,iv_corp_code                    IN     VARCHAR2     -- ��ƃR�[�h
   ,iv_introduction_code            IN     VARCHAR2     -- �T���p�`�F�[���R�[�h
   ,iv_ship_cust_code               IN     VARCHAR2     -- �ڋq�R�[�h
   ,iv_data_type                    IN     VARCHAR2     -- �f�[�^���
   ,iv_tax_code                     IN     VARCHAR2     -- �ŃR�[�h
   ,iv_order_list_date_from         IN     VARCHAR2     -- �J�n��
   ,iv_order_list_date_to           IN     VARCHAR2     -- �o�͊��
   ,iv_content                      IN     VARCHAR2     -- ���e
   ,iv_decision_no                  IN     VARCHAR2     -- ����No
   ,iv_agreement_no                 IN     VARCHAR2     -- �_��ԍ�
   ,iv_last_update_date             IN     VARCHAR2     -- �ŏI�X�V��
   ,ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώۃf�[�^�擾
    OPEN get_deduction_list_data_cur (
           iv_order_deduction_no           -- �T���ԍ�
          ,iv_corp_code                    -- ��ƃR�[�h
          ,iv_introduction_code            -- �T���p�`�F�[���R�[�h
          ,iv_ship_cust_code               -- �ڋq�R�[�h
          ,iv_data_type                    -- �f�[�^���
          ,iv_tax_code                     -- �ŃR�[�h
          ,iv_order_list_date_from         -- �J�n��
          ,iv_order_list_date_to           -- �I����
          ,iv_content                      -- ���e
          ,iv_decision_no                  -- ����No
          ,iv_agreement_no                 -- �_��ԍ�
          ,iv_last_update_date             -- �ŏI�X�V��
          );
    FETCH get_deduction_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_deduction_list_data_cur;
    -- ���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- ���o�f�[�^��0���������ꍇ�x��
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF get_deduction_list_data_cur%ISOPEN THEN
        CLOSE get_deduction_list_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_code_eoh_024a02    CONSTANT  VARCHAR2(100)                       := '024A02%';                       -- �N�C�b�N�R�[�h�i�T���}�X�^�o�͗p���o���j
--
    -- *** ���[�J���ϐ� ***
    lv_line_data              VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                             -- �E�v�F�o�͗p���o��
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                     -- ����
      AND     flv.lookup_type     = cv_type_header                              -- �T���}�X�^�o�͗p���o��
      AND     flv.lookup_code  LIKE cv_code_eoh_024a02                          -- �N�C�b�N�R�[�h�i�T���}�X�^�o�͗p���o���j
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_proc_date )  -- �L���J�n��
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_proc_date )  -- �L���I����
      AND     flv.enabled_flag    = cv_const_y                                  -- �g�p�\
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --���o��
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      --�f�[�^��ҏW
      lv_line_data :=     cv_null                                                     -- �����敪
         || cv_delimit || gt_out_file_tab(i).condition_no                             -- �T���ԍ�
         || cv_delimit || gt_out_file_tab(i).corp_code                                -- ��ƃR�[�h
         || cv_delimit || gt_out_file_tab(i).deduction_chain_code                     -- �T���p�`�F�[���R�[�h
         || cv_delimit || gt_out_file_tab(i).customer_code                            -- �ڋq�R�[�h
         || cv_delimit || gt_out_file_tab(i).data_type                                -- �f�[�^���
         || cv_delimit || gt_out_file_tab(i).tax_code                                 -- �ŃR�[�h
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).start_date_active,cv_date_format)  -- �J�n��
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).end_date_active,cv_date_format)    -- �I����
         || cv_delimit || gt_out_file_tab(i).content                                  -- ���e
         || cv_delimit || gt_out_file_tab(i).decision_no                              -- ����No
         || cv_delimit || gt_out_file_tab(i).agreement_no                             -- �_��ԍ�
         || cv_delimit || gt_out_file_tab(i).detail_number                            -- ���הԍ�
         || cv_delimit || gt_out_file_tab(i).target_category                          -- �Ώۋ敪
         || cv_delimit || gt_out_file_tab(i).product_class                            -- ���i�敪
         || cv_delimit || gt_out_file_tab(i).item_code                                -- �i�ڃR�[�h
         || cv_delimit || gt_out_file_tab(i).uom_code                                 -- �P��
         || cv_delimit || gt_out_file_tab(i).shop_pay_1                               -- �X�[(%)
         || cv_delimit || gt_out_file_tab(i).material_rate                            -- ����(%)
         || cv_delimit || gt_out_file_tab(i).demand_en                                -- ����(�~)
         || cv_delimit || gt_out_file_tab(i).shop_pay_en                              -- �X�[(�~)
         || cv_delimit || gt_out_file_tab(i).wholesale_margin_en                      -- �≮�}�[�W��(�~)
         || cv_delimit || gt_out_file_tab(i).wholesale_margin_per                     -- �≮�}�[�W��(��)
         || cv_delimit || gt_out_file_tab(i).normal_shop_pay_en                       -- �ʏ�X�[(�~)
         || cv_delimit || gt_out_file_tab(i).just_shop_pay_en                         -- ����X�[(�~)
         || cv_delimit || gt_out_file_tab(i).wholesale_adj_margin_en                  -- �≮�}�[�W���C��(�~)
         || cv_delimit || gt_out_file_tab(i).wholesale_adj_margin_per                 -- �≮�}�[�W���C��(��)
         || cv_delimit || gt_out_file_tab(i).prediction_qty                           -- �\������(�{)
         || cv_delimit || gt_out_file_tab(i).support_amount_sum_en                    -- ���^�����v(�~)
         || cv_delimit || gt_out_file_tab(i).condition_unit_price_en                  -- �����P��(�~)
         || cv_delimit || gt_out_file_tab(i).target_rate6                             -- �Ώۗ�(��)
-- 2021/04/06 Ver1.1 MOD Start
         --|| cv_delimit || gt_out_file_tab(i).accounting_base                          -- �v�㋒�_
         || cv_delimit || gt_out_file_tab(i).accounting_customer_code                 -- �v��ڋq
-- 2021/04/06 Ver1.1 MOD End
         || cv_delimit || gt_out_file_tab(i).deduction_amount                         -- �T���z(�{��)
         || cv_delimit || gt_out_file_tab(i).deduction_tax_amount                     -- �T���Ŋz
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).head_last_update_date,cv_date_format_time)                          -- �w�b�_�ŏI�X�V��
         || cv_delimit || gt_out_file_tab(i).head_employee_number|| cv_full_space 
         ||gt_out_file_tab(i).head_last_update_by_last || cv_half_space || gt_out_file_tab(i).head_last_update_by_first  -- �w�b�_�ŏI�X�V��
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).line_last_update_date,cv_date_format_time)                          -- ���׍ŏI�X�V��
         || cv_delimit || gt_out_file_tab(i).line_employee_number|| cv_full_space 
         ||gt_out_file_tab(i).line_last_update_by_last || cv_half_space || gt_out_file_tab(i).line_last_update_by_first  -- ���׍ŏI�X�V��
      ;
      -- �f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( iv_order_deduction_no           IN     VARCHAR2  -- �T���ԍ�
                    ,iv_corp_code                    IN     VARCHAR2  -- ��ƃR�[�h
                    ,iv_introduction_code            IN     VARCHAR2  -- �T���p�`�F�[���R�[�h
                    ,iv_ship_cust_code               IN     VARCHAR2  -- �ڋq�R�[�h
                    ,iv_data_type                    IN     VARCHAR2  -- �f�[�^���
                    ,iv_tax_code                     IN     VARCHAR2  -- �ŃR�[�h
                    ,iv_order_list_date_from         IN     VARCHAR2  -- �J�n��
                    ,iv_order_list_date_to           IN     VARCHAR2  -- �I����
                    ,iv_content                      IN     VARCHAR2  -- ���e
                    ,iv_decision_no                  IN     VARCHAR2  -- ����No
                    ,iv_agreement_no                 IN     VARCHAR2  -- �_��ԍ�
                    ,iv_last_update_date             IN     VARCHAR2  -- �ŏI�X�V��
                    ,ov_errbuf                       OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode                      OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init( iv_order_deduction_no          -- �T���ԍ�
         ,iv_corp_code                   -- ��ƃR�[�h
         ,iv_introduction_code           -- �T���p�`�F�[���R�[�h
         ,iv_ship_cust_code              -- �ڋq�R�[�h
         ,iv_data_type                   -- �f�[�^���
         ,iv_tax_code                    -- �ŃR�[�h
         ,iv_order_list_date_from        -- �J�n��
         ,iv_order_list_date_to          -- �I����
         ,iv_content                     -- ���e
         ,iv_decision_no                 -- ����No
         ,iv_agreement_no                -- �_��ԍ�
         ,iv_last_update_date            -- �ŏI�X�V��
         ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �T���}�X�^���o
    -- ===============================
    get_order_list_cond( iv_order_deduction_no        -- �T���ԍ�
                        ,iv_corp_code                 -- ��ƃR�[�h
                        ,iv_introduction_code         -- �T���p�`�F�[���R�[�h
                        ,iv_ship_cust_code            -- �ڋq�R�[�h
                        ,iv_data_type                 -- �f�[�^���
                        ,iv_tax_code                  -- �ŃR�[�h
                        ,iv_order_list_date_from      -- �J�n��
                        ,iv_order_list_date_to        -- �I����
                        ,iv_content                   -- ���e
                        ,iv_decision_no               -- ����No
                        ,iv_agreement_no              -- �_��ԍ�
                        ,iv_last_update_date          -- �ŏI�X�V��
                        ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
                        ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- A-3  �f�[�^�o��
    -- ===============================
    output_data(
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_order_deduction_no           IN     VARCHAR2          -- �T���ԍ�
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_introduction_code            IN     VARCHAR2          -- �T���p�`�F�[���R�[�h
   ,iv_ship_cust_code               IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_data_type                    IN     VARCHAR2          -- �f�[�^���
   ,iv_tax_code                     IN     VARCHAR2          -- �ŃR�[�h
   ,iv_order_list_date_from         IN     VARCHAR2          -- �J�n��
   ,iv_order_list_date_to           IN     VARCHAR2          -- �I����
   ,iv_content                      IN     VARCHAR2          -- ���e
   ,iv_decision_no                  IN     VARCHAR2          -- ����No
   ,iv_agreement_no                 IN     VARCHAR2          -- �_��ԍ�
   ,iv_last_update_date             IN     VARCHAR2          -- �ŏI�X�V��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_order_deduction_no           -- �T���ԍ�
      ,iv_corp_code                    -- ��ƃR�[�h
      ,iv_introduction_code            -- �T���p�`�F�[���R�[�h
      ,iv_ship_cust_code               -- �ڋq�R�[�h
      ,iv_data_type                    -- �f�[�^���
      ,iv_tax_code                     -- �ŃR�[�h
      ,iv_order_list_date_from         -- �J�n��
      ,iv_order_list_date_to           -- �I����
      ,iv_content                      -- ���e
      ,iv_decision_no                  -- ����No
      ,iv_agreement_no                 -- �_��ԍ�
      ,iv_last_update_date             -- �ŏI�X�V��
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- A-4.�I������
    -- ===============================
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�G���[�̏ꍇ���������N���A�A�G���[�����Œ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A02C;
/