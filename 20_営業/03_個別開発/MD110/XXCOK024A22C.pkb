CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A22C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A22C (body)
 * Description      : ������ѐU�֏��ƍT���}�X�^���Ɍڋq�A���i�A�T���������Ƃ�
 *                  : �T���f�[�^�̍T�����z���Z�o���A�̔��T�����֓o�^���܂��B
 * MD.050           : ���ѐU�ցE�̔��T���f�[�^�̍쐬�iEDI�j MD050_COK_024_A22
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.��������
 *  get_data               A-2.���ѐU�փf�[�^���o
 *  sell_trns_cul          A-3.���ѐU�֍T���f�[�^�Z�o
 *  insert_deduction       A-4.�̔��T���f�[�^�o�^
 *  update_sls_dedu_ctrl   A-5.�̔��T���Ǘ����X�V
 *  submain                ���C�������v���V�[�W��
 *  main                   �̔��T���f�[�^�쐬�v���V�[�W��(A-6.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/04/14    1.0   M.Sato           �V�K�쐬
 *  2020/12/03    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
 *
 *****************************************************************************************/
--
--###########################  �Œ�O���[�o���萔�錾�� START  ###########################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  �Œ�O���[�o���萔�錾�� END  ############################
--
--###########################  �Œ�O���[�o���ϐ��錾�� START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--############################  �Œ�O���[�o���ϐ��錾�� END  ############################
--
--##############################  �Œ苤�ʗ�O�錾�� START  ##############################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A22C';             -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                    -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                    -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';         -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';         -- �Ɩ����t�擾�G���[
  cv_last_process_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';         -- �O�񏈗�ID�擾�G���[
  cv_dedc_calc_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10685';         -- �T���z�Z�o�G���[
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';         -- ���b�N�G���[���b�Z�[�W
  cv_target_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';         -- �Ώی������b�Z�[�W
  cv_success_rec_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';         -- �����������b�Z�[�W
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';         -- �G���[�������b�Z�[�W
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';         -- �X�L�b�v�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';         -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';         -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_tkn_condition_no       CONSTANT VARCHAR2(20) := 'CONDITION_NO';             -- �T���ԍ�
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                    -- �������b�Z�[�W�p�g�[�N����
  cv_tkn_line_id            CONSTANT VARCHAR2(15) := 'SOURCE_TRAN_ID';           -- ������ѐU�֏��ID�̃g�[�N����
  cv_tkn_item_code          CONSTANT VARCHAR2(15) := 'ITEM_CODE';                -- �i�ڃR�[�h�̃g�[�N����
  cv_tkn_sales_uom_code     CONSTANT VARCHAR2(15) := 'SALES_UOM_CODE';           -- �̔��P�ʂ̃g�[�N����
  cv_tkn_base_code          CONSTANT VARCHAR2(15) := 'BASE_CODE';                -- �S�����_�̃g�[�N����
  cv_tkn_errmsg             CONSTANT VARCHAR2(15) := 'ERRMSG';                   -- �G���[���b�Z�[�W�̃g�[�N����
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT VARCHAR2(1) := 'Y';                         -- �t���O�l:Y
  -- �̔��T���A�g�Ǘ����Ɏg�p����Œ�l
  cv_control_flag           CONSTANT VARCHAR2(1) := 'T';                         -- �Ǘ����t���O
  -- ���ѐU�֏��f�[�^���o�Ŏg�p����Œ�l
  cv_cate_set_name          CONSTANT VARCHAR2(20) := '�{�Џ��i�敪';             -- �i�ڃJ�e�S���Z�b�g��
  cv_sls_dedc_tgt           CONSTANT VARCHAR2(1) := 'Y';                         -- �̔��T���쐬�Ώ�
  cv_rep_deci_flag          CONSTANT VARCHAR2(1) := '1';                         -- ����m��t���O
  cv_sell_trns_type         CONSTANT VARCHAR2(1) := '1';                         -- ���ѐU�֋敪
  cv_ded_type_010           CONSTANT VARCHAR2(3) := '010';                       -- �T���^�C�v
  -- �̔��T�����e�[�u���ɐݒ肷��Œ�l
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'T';                        -- �쐬���敪
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                        -- �X�e�[�^�X
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- GL�A�g�t���O
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- ����t���O
  cv_ins_rep_deci_flag      CONSTANT  VARCHAR2(1) := '1';                        -- ����m��t���O
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �����擾
  gn_last_process_id          NUMBER;                                            -- �O�񔄏���ѐU�֏��ID
  --
  gn_max_selling_trns_info_id NUMBER;                                            -- ������ѐU�֏��ID�̍ő�l                                                                                    -- �O�񔄏���ѐU�֏��ID�ő�l
  -- 
  gv_deduction_uom_code       VARCHAR2(3);                                       -- �T���P��
  gn_deduction_unit_price     NUMBER;                                            -- �T���P��
  gn_deduction_quantity       NUMBER;                                            -- �T������
  gn_deduction_amount         NUMBER;                                            -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                            -- ��U
  gn_margin                   NUMBER;                                            -- �≮�}�[�W��
  gn_sales_promotion_expenses NUMBER;                                            -- �g��
  gn_margin_reduction         NUMBER;                                            -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount     NUMBER;                                            -- �T���Ŋz
  gv_tax_code                 VARCHAR2(4);                                       -- �ŃR�[�h
  gn_tax_rate                 NUMBER;                                            -- �ŗ�
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\�� (���ѐU�֏��f�[�^���o)
  -- ===============================
  CURSOR g_selling_trns_cur
  IS
  WITH
   flvc1 AS
      ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
        FROM   fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_TYPE'  -- �T���^�C�v
        AND   flvc.language     = 'JA'
        AND   flvc.enabled_flag = cv_y_flag
        AND   flvc.attribute1   = cv_y_flag            )   -- �̔��T���쐬�Ώ�
   ,flvc3 AS
      ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
        FROM   fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCMM_CUST_GYOTAI_SHO'  -- �Ƒ�(������)
        AND   flvc.language     = 'JA'
        AND   flvc.enabled_flag = cv_y_flag
        AND   flvc.attribute2   = cv_sls_dedc_tgt      )   -- �̔��T���쐬�ΏۊO
    SELECT /*+ leading(xsi)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                 AS base_code                    -- �U�֐拒�_
          ,xsi.cust_code                 AS cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date              AS selling_date                 -- ����v���
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                 AS item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                 AS unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- �[�i�P��
          ,xsi.qty                       AS qty                          -- ����
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                  AS tax_code_trn                 -- ����ŃR�[�h
          ,xsi.tax_rate                  AS tax_rate_trn                 -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- ����Ŋz
          ,xch.condition_id              AS condition_id                 -- �T������ID
          ,xch.condition_no              AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                 AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code      AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code             AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                 AS data_type                    -- �f�[�^���
          ,xch.tax_code                  AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                  AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                AS attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code            AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id         AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class             AS product_class                -- ���i�敪
          ,xcl.item_code                 AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                  AS uom_code                     -- �P��(����)
          ,xcl.target_category           AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1           AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2               AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- ������ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �`�F�[���X
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code(+)            = xca.intro_chain_code2
           AND   flv.language(+)               = 'JA'
           AND   flv.enabled_flag(+)           = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   xsi.cust_code                 = xch.customer_code
           AND   xch.customer_code        IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    UNION ALL
    SELECT /*+ leading(xsi)
           use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                 AS base_code                    -- �U�֐拒�_
          ,xsi.cust_code                 AS cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date              AS selling_date                 -- ����v���
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                 AS item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                 AS unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- �[�i�P��
          ,xsi.qty                       AS qty                          -- ����
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                  AS tax_code_trn                 -- ����ŃR�[�h
          ,xsi.tax_rate                  AS tax_rate_trn                 -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- ����Ŋz
          ,xch.condition_id              AS condition_id                 -- �T������ID
          ,xch.condition_no              AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                 AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code      AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code             AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                 AS data_type                    -- �f�[�^���
          ,xch.tax_code                  AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                  AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                AS attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code            AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id         AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class             AS product_class                -- ���i�敪
          ,xcl.item_code                 AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                  AS uom_code                     -- �P��(����)
          ,xcl.target_category           AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1           AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2               AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- ������ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �`�F�[���X
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code(+)            = xca.intro_chain_code2
           AND   flv.language(+)               = 'JA'
           AND   flv.enabled_flag(+)           = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   xca.intro_chain_code2         = xch.deduction_chain_code
           AND   xch.deduction_chain_code IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    UNION ALL
    SELECT /*+ leading(xsi)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                 AS base_code                    -- �U�֐拒�_
          ,xsi.cust_code                 AS cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date              AS selling_date                 -- ����v���
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                 AS item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                 AS unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- �[�i�P��
          ,xsi.qty                       AS qty                          -- ����
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                  AS tax_code_trn                 -- ����ŃR�[�h
          ,xsi.tax_rate                  AS tax_rate_trn                 -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- ����Ŋz
          ,xch.condition_id              AS condition_id                 -- �T������ID
          ,xch.condition_no              AS condition_no                 -- �T���ԍ�
          ,xch.corp_code                 AS corp_code                    -- ��ƃR�[�h
          ,xch.deduction_chain_code      AS deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xch.customer_code             AS customer_code                -- �ڋq�R�[�h(����)
          ,xch.data_type                 AS data_type                    -- �f�[�^���
          ,xch.tax_code                  AS tax_code_mst                 -- �ŃR�[�h(�}�X�^)
          ,xch.tax_rate                  AS tax_rate_mst                 -- �ŗ�(�}�X�^)
          ,flv.attribute3                AS attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code            AS sale_base_code               -- ���㋒�_(�ڋq)
          ,xcl.condition_line_id         AS condition_line_id            -- �T���ڍ�ID
          ,xcl.product_class             AS product_class                -- ���i�敪
          ,xcl.item_code                 AS item_code_cond               -- �i�ڃR�[�h(����)
          ,xcl.uom_code                  AS uom_code                     -- �P��(����)
          ,xcl.target_category           AS target_category              -- �Ώۋ敪
          ,xcl.shop_pay_1                AS shop_pay_1                   -- �X�[(��)
          ,xcl.material_rate_1           AS material_rate_1              -- ����(��)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- ��U(�~)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- �����P���T(�~)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2               AS attribute2                   -- �T���^�C�v
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- ������ѐU�֏��
          ,xxcmm_cust_accounts           xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values             flv                             -- �`�F�[���X
          ,xxcok_condition_header        xch                             -- �T������
          ,xxcok_condition_lines         xcl                             -- �T���ڍ�
          ,fnd_lookup_values             flv2                            -- �f�[�^���
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type               = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code               = xca.intro_chain_code2
           AND   flv.language                  = 'JA'
           AND   flv.enabled_flag              = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   flv.attribute1                = xch.corp_code
           AND   xch.corp_code            IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    ;
    -- �J�[�\�����R�[�h�擾�p
    g_selling_trns_rec          g_selling_trns_cur%ROWTYPE;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                      -- �v���O������
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
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
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
    --==================================
    -- ������ѐU�֏��ID�擾
    --==================================
    --
    BEGIN
      -- �O�񏈗��ς݂̔�����ѐU�֏��ID���擾
      SELECT xsds.last_processing_id          AS last_processing_id
      INTO   gn_last_process_id
      FROM
             xxcok_sales_deduction_control    xsds
      WHERE  xsds.control_flag                = cv_control_flag
      FOR UPDATE OF xsds.last_processing_id NOWAIT
      ;
--
      SELECT MAX(xsti.selling_trns_info_id) AS max_selling_trns_info_id
      INTO   gn_max_selling_trns_info_id
      FROM   xxcok_dedu_edi_sell_trns  xsti
      WHERE  xsti.selling_trns_info_id  > gn_last_process_id
      ;
--
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        -- ���b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                              ,cv_table_lock_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      --
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_last_process_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : sell_trns_cul
   * Description      : A-3.���ѐU�֍T���f�[�^�Z�o
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
     ,iv_tax_code_trn               =>  g_selling_trns_rec.tax_code_trn               -- �ŃR�[�h(TRN)
     ,in_tax_rate_trn               =>  g_selling_trns_rec.tax_rate_trn               -- �ŗ�(TRN)
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
        lv_base_code  :=  g_selling_trns_rec.attribute3;                              -- �{���S�����_(�`�F�[���X)
      -- �ڋq�R�[�h(����)��NULL�ȊO�̏ꍇ
      ELSIF ( g_selling_trns_rec.customer_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.sale_base_code;                          -- ���㋒�_(�ڋq)
      END IF;
      -- �T���z�Z�o�G���[���b�Z�[�W�̏o��
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_dedc_calc_msg
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
   * Procedure Name   : insert_deduction
   * Description      : A-4.�̔��T���f�[�^�o�^
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
        ,condition_id                                                     -- �T������ID
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
        ,recon_tax_code                                                   -- �������ŃR�[�h
        ,recon_tax_rate                                                   -- �������ŗ�
        ,deduction_tax_amount                                             -- �T���Ŋz
        ,remarks                                                          -- ���l
        ,application_no                                                   -- �\����No.
        ,gl_if_flag                                                       -- GL�A�g�t���O
        ,gl_base_code                                                     -- GL�v�㋒�_
        ,gl_date                                                          -- GL�L����
-- 2020/12/03 Ver1.1 MOD Start
        ,recovery_date                                                    -- ���J�o���f�[�^�ǉ������t
        ,recovery_add_request_id                                          -- ���J�o���f�[�^�ǉ����v��ID
        ,recovery_del_date                                                -- ���J�o���f�[�^�폜�����t
        ,recovery_del_request_id                                          -- ���J�o���f�[�^�폜���v��ID
--        ,recovery_date                                                    -- ���J�o���[���t
-- 2020/12/03 Ver1.1 MOD End
        ,cancel_flag                                                      -- ����t���O
        ,cancel_base_code                                                 -- ������v�㋒�_
        ,cancel_gl_date                                                   -- ���GL�L����
        ,cancel_user                                                      -- ������{���[�U
        ,recon_base_code                                                  -- �������v�㋒�_
        ,recon_slip_num                                                   -- �x���`�[�ԍ�
        ,carry_payment_slip_num                                           -- �J�z���x���`�[�ԍ�
        ,report_decision_flag                                             -- ����m��t���O
        ,gl_interface_id                                                  -- GL�A�gID
        ,cancel_gl_interface_id                                           -- ���GL�A�gID
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
        ,g_selling_trns_rec.condition_id                                  -- �T������ID
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
        ,NULL                                                             -- �������ŃR�[�h
        ,NULL                                                             -- �������ŗ�
        ,gn_deduction_tax_amount                                          -- �T���Ŋz
        ,NULL                                                             -- ���l
        ,NULL                                                             -- �\����No.
        ,cv_gl_rel_flag                                                   -- GL�A�g�t���O
        ,NULL                                                             -- GL�v�㋒�_
        ,NULL                                                             -- GL�L����
-- 2020/12/03 Ver1.1 MOD Start
        ,NULL                                                             -- ���J�o���f�[�^�ǉ������t
        ,NULL                                                             -- ���J�o���f�[�^�ǉ����v��ID
        ,NULL                                                             -- ���J�o���f�[�^�폜�����t
        ,NULL                                                             -- ���J�o���f�[�^�폜���v��ID
--        ,NULL                                                             -- ���J�o���[���t
-- 2020/12/03 Ver1.1 MOD End
        ,cv_cancel_flag                                                   -- ����t���O
        ,NULL                                                             -- ������v�㋒�_
        ,NULL                                                             -- ���GL�L����
        ,NULL                                                             -- ������{���[�U
        ,NULL                                                             -- �������v�㋒�_
        ,NULL                                                             -- �x���`�[�ԍ�
        ,NULL                                                             -- �J�z���x���`�[�ԍ�
        ,cv_ins_rep_deci_flag                                             -- ����m��t���O
        ,NULL                                                             -- GL�A�gID
        ,NULL                                                             -- ���GL�A�gID
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
   * Procedure Name   : get_data
   * Description      : A-2.���ѐU�փf�[�^���o
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data';                  -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\��***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �J�[�\���I�[�v��
    OPEN  g_selling_trns_cur;
    -- �f�[�^�擾
    FETCH g_selling_trns_cur INTO g_selling_trns_rec;
--
    -- �擾�f�[�^���O���̏ꍇ
    IF ( g_selling_trns_cur%NOTFOUND )  THEN
      -- �x���X�e�[�^�X�̊i�[
      ov_retcode := cv_status_warn;
      -- �ΏۂȂ����b�Z�[�W�̏o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    LOOP
      EXIT  WHEN  g_selling_trns_cur%NOTFOUND;
      --
      lv_retcode  :=  cv_status_normal;                   -- �X�e�[�^�X��������
      -- �Ώی������C���N�������g
      gn_target_cnt :=  gn_target_cnt + 1;
      -- ============================================================
      -- A-3.�̔��T���f�[�^�Z�o�̌Ăяo��
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
        -- A-4.�̔��T���f�[�^�o�^�̌Ăяo��
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
        gn_warn_cnt := gn_warn_cnt   + 1;
      ELSE
        RAISE global_process_expt;
      END IF;
      -- ���̃f�[�^���擾
      FETCH g_selling_trns_cur INTO g_selling_trns_rec;
    --
    END LOOP;
    -- �J�[�\�����N���[�Y
    CLOSE g_selling_trns_cur;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : update_sls_dedu_ctrl
   * Description      : A-5.�̔��T���Ǘ����X�V
   ***********************************************************************************/
  PROCEDURE update_sls_dedu_ctrl(
                  ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sls_dedu_ctrl';      -- �v���O������
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
    -- �̔��T���A�g�Ǘ������X�V
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = gn_max_selling_trns_info_id         -- �O�񏈗�ID
           ,last_updated_by         = cn_last_updated_by                  -- �ŏI�X�V��
           ,last_update_date        = cd_last_update_date                 -- �ŏI�X�V��
           ,last_update_login       = cn_last_update_login                -- �ŏI�X�V���O�C��
           ,request_id              = cn_request_id                       -- �v��ID
           ,program_application_id  = cn_program_application_id           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id              = cn_program_id                       -- �R���J�����g�E�v���O����ID
           ,program_update_date     = cd_program_update_date              -- �v���O�����X�V��
    WHERE   control_flag  = cv_control_flag
    ;
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
  END update_sls_dedu_ctrl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt                 := 0;      -- �Ώی���
    gn_normal_cnt                 := 0;      -- ���팏��
    gn_error_cnt                  := 0;      -- �G���[����
    gn_warn_cnt                   := 0;      -- �X�L�b�v����
    gn_max_selling_trns_info_id   := NULL;   -- ������ѐU�֏��ID�̍ő�l
    gv_deduction_uom_code         := NULL;   -- �T���P��
    gn_deduction_unit_price       := NULL;   -- �T���P��
    gn_deduction_quantity         := NULL;   -- �T������
    gn_deduction_amount           := NULL;   -- �T���z
    gv_tax_code                   := NULL;   -- �ŃR�[�h
    gn_tax_rate                   := NULL;   -- �ŗ�
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.���ѐU�փf�[�^���o
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode  = cv_status_warn ) THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ������ѐU�֏��ID�̍ő�l���擾�ł��Ă����ꍇ
    IF ( gn_max_selling_trns_info_id IS NOT NULL ) THEN
      -- ===============================
      -- A-5.�̔��T���Ǘ����X�V
      -- ===============================
      update_sls_dedu_ctrl(
          ov_errbuf  => lv_errbuf          -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode         -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �̔��T���f�[�^�̍쐬�v���V�[�W��(A-6.�I���������܂�)
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                 ,retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--####################################  �Œ蕔 START  ####################################--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
       ,ov_errbuf  => lv_errbuf
       ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
    -- ===============================
    -- A-6.�I������
    -- ===============================
--
    -- �G���[�������̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_warn_cnt     := 0;
      gn_error_cnt    := 1;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^���������o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_success_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_skip_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
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
--
--#####################################  �Œ蕔 END  #####################################
--
  END main;
--
END XXCOK024A22C;
/
