CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A09C(body)
 * Description      : �T���f�[�^���J�o���[(�̔��T��)
 * MD.050           : �T���f�[�^���J�o���[(�̔��T��) MD050_COK_024_A09
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-1.��������
 *  get_condition_data     A-2.�T�����X�V�Ώے��o
 *  sales_deduction_delete A-3.�̔��T���������
 *  get_data               A-4.�T���f�[�^���o
 *  calculation_data       A-5.�T���f�[�^�Z�o
 *  insert_data            A-6.�̔��T���f�[�^�o�^
 *  condition_update       A-7.�T�����X�V
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-8���܂�)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/13    1.0   H.Ishii          �V�K�쐬
 *  2020/12/03    1.1   SCSK Y.Koh       [E_�{�ғ�_16026]
 *  2021/04/06    1.2   SCSK Y.Koh       [E_�{�ғ�_16026]�e��敪�Ή�
 *                                       [E_�{�ғ�_16026]��z�T���������בΉ�
 *  2021/07/26    1.3   SCSK K.Yoshikawa [E_�{�ғ�_17399]
 *  2021/09/17    1.4   SCSK K.Yoshikawa [E_�{�ғ�_17540]�}�X�^�폜���̎x���ύT���f�[�^�̑Ή�
 *  2021/10/21    1.5   SCSK K.Yoshikawa [E_�{�ғ�_17546]�T���}�X�^�폜�A�b�v���[�h�̉��C
 *
 *****************************************************************************************/
--
--########################  �Œ�O���[�o���萔�錾�� START  ########################
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
--##################################  �Œ蕔 END  ##################################
--
--########################  �Œ�O���[�o���ϐ��錾�� START  ########################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_del_target_cnt         NUMBER;                    -- �T���}�X�^�폜�Ώی���
  gn_add_target_cnt         NUMBER;                    -- �T���}�X�^�o�^�Ώی���
  gn_del_cnt                NUMBER;                    -- �T���f�[�^�폜����
  gn_add_cnt                NUMBER;                    -- �T���f�[�^�o�^����
  gn_cal_skip_cnt           NUMBER;                    -- �T���f�[�^�T���z�Z�o�X�L�b�v����
  gn_del_skip_cnt           NUMBER;                    -- �T���f�[�^�폜�x���σX�L�b�v����
-- 2021/09/17 Ver1.4 ADD Start
  gn_del_ins_cnt            NUMBER;                    -- �}�C�i�X�T���f�[�^�o�^����
-- 2021/09/17 Ver1.4 ADD End
  gn_add_skip_cnt           NUMBER;                    -- �T���f�[�^�o�^�x���σX�L�b�v����
  gn_error_cnt              NUMBER;                    -- �G���[����
--
--##################################  �Œ蕔 END  ##################################
--
--###########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--##################################  �Œ蕔 END  ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOK024A09C';                   -- �p�b�P�[�W��
  cv_xxcok_short_name       CONSTANT  VARCHAR2(100) := 'XXCOK';                          -- �̕��̈�Z�k�A�v����
  --���b�Z�[�W
  cv_data_get_msg           CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-00001';               -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-00028';               -- �Ɩ����t�擾�G���[���b�Z�[�W
-- 2020/12/03 Ver1.1 ADD Start
  cv_msg_id_error           CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10592';               -- �O�񏈗�ID�擾�G���[
-- 2020/12/03 Ver1.1 ADD End
  cv_msg_cal_error          CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10593';               -- �T���z�Z�o�G���[
  cv_msg_slip_date_err      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10708';               -- �x�������ΏۊO���b�Z�[�W
-- 2021/09/17 Ver1.4 ADD Start
  cv_msg_slip_date_ins      CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10807';               -- �x�������σ}�C�i�X�T���f�[�^�o�^���b�Z�[�W
-- 2021/09/17 Ver1.4 ADD End
-- 2021/10/21 Ver1.5 ADD Start
  cv_msg_slip_date_discount CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10808';               -- �x�������ΏۊO���b�Z�[�W�������l��
  cv_msg_slip_date_err_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10809';               -- �x�������ΏۊO���b�Z�[�W����
  cv_msg_slip_date_ins_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10810';               -- �x�������σ}�C�i�X�T���f�[�^�o�^���b�Z�[�W����
  cv_msg_slip_date_dis_d    CONSTANT  VARCHAR2(20)  := 'APP-XXCOK1-10811';               -- �x�������ΏۊO���b�Z�[�W�������l������
-- 2021/10/21 Ver1.5 ADD End
  cv_msg_lock_err           CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10632';               -- ���b�N�G���[���b�Z�[�W
  --�g�[�N���l
  cv_tkn_source_line_id     CONSTANT  VARCHAR2(15)  := 'SOURCE_LINE_ID';                 -- �̔����і���ID�̃g�[�N����
  cv_tkn_item_code          CONSTANT  VARCHAR2(15)  := 'ITEM_CODE';                      -- �i�ڃR�[�h�̃g�[�N����
  cv_tkn_sales_uom_code     CONSTANT  VARCHAR2(15)  := 'SALES_UOM_CODE';                 -- �̔��P�ʂ̃g�[�N����
  cv_tkn_condition_no       CONSTANT  VARCHAR2(15)  := 'CONDITION_NO';                   -- �T���ԍ��̃g�[�N����
  cv_tkn_base_code          CONSTANT  VARCHAR2(15)  := 'BASE_CODE';                      -- �S�����_�̃g�[�N����
  cv_tkn_errmsg             CONSTANT  VARCHAR2(15)  := 'ERRMSG';                         -- �G���[���b�Z�[�W�̃g�[�N����
  cv_tkn_recon_slip_num     CONSTANT  VARCHAR2(15)  := 'RECON_SLIP_NUM';                 -- �x���`�[�ԍ��̃g�[�N����
-- 2021/09/17 Ver1.4 ADD Start
  cv_tkn_column_value       CONSTANT  VARCHAR2(15)  := 'COLUMN_VALUE';                   -- �T���ԍ��A���הԍ��̃g�[�N����
  cv_tkn_data_type          CONSTANT  VARCHAR2(15)  := 'DATA_TYPE';                      -- �f�[�^��ނ̃g�[�N����
-- 2021/09/17 Ver1.4 ADD End
-- 2021/10/21 Ver1.5 ADD Start
  cv_tkn_target_date_end    CONSTANT  VARCHAR2(15)  := 'TARGET_DATE_END';                -- �Ώۊ��ԁiTO)�̃g�[�N����
  cv_tkn_due_date           CONSTANT  VARCHAR2(15)  := 'DUE_DATE';                       -- �x���\����̃g�[�N����
  cv_tkn_status             CONSTANT  VARCHAR2(15)  := 'STATUS';                         -- �x���`�[�̃X�e�[�^�X�̃g�[�N����
-- 2021/10/21 Ver1.5 ADD End
  --�t���O�E�敪�萔
  cv_item_category          CONSTANT  VARCHAR2(12)  := '�{�Џ��i�敪';                   -- �萔�F�{�Џ��i�敪
  cv_dummy_flag             CONSTANT  VARCHAR2(5)   := 'DUMMY';                          -- �萔�FDUMMY
  cv_c_flag                 CONSTANT  VARCHAR2(1)   := 'C';                              -- �萔�FC
  cv_d_flag                 CONSTANT  VARCHAR2(1)   := 'D';                              -- �萔�FD
  cv_f_flag                 CONSTANT  VARCHAR2(1)   := 'F';                              -- �萔�FF
  cv_i_flag                 CONSTANT  VARCHAR2(1)   := 'I';                              -- �萔�FI
  cv_n_flag                 CONSTANT  VARCHAR2(1)   := 'N';                              -- �萔�FN
  cv_r_flag                 CONSTANT  VARCHAR2(1)   := 'R';                              -- �萔�FR
  cv_s_flag                 CONSTANT  VARCHAR2(1)   := 'S';                              -- �萔�FS
  cv_t_flag                 CONSTANT  VARCHAR2(1)   := 'T';                              -- �萔�FT
  cv_y_flag                 CONSTANT  VARCHAR2(1)   := 'Y';                              -- �萔�FY
  cv_u_flag                 CONSTANT  VARCHAR2(1)   := 'U';                              -- �萔�FU
  cv_v_flag                 CONSTANT  VARCHAR2(1)   := 'V';                              -- �萔�FV
  cv_0                      CONSTANT  VARCHAR2(1)   := '0';                              -- �萔�F0
  cv_1                      CONSTANT  VARCHAR2(1)   := '1';                              -- �萔�F1
  cn_1                      CONSTANT  NUMBER        := 1;                                -- �萔�F1
  cn_2                      CONSTANT  NUMBER        := 2;                                -- �萔�F2
  cn_3                      CONSTANT  NUMBER        := 3;                                -- �萔�F3
  cn_4                      CONSTANT  NUMBER        := 4;                                -- �萔�F4
  cv_deci_flag              CONSTANT  VARCHAR2(1)   := '1';                              -- �m��
-- 2021/09/17 Ver1.4 ADD Start
  cv_030                    CONSTANT  VARCHAR2(3)   := '030';                            -- �≮�����i��z�j
  cv_040                    CONSTANT  VARCHAR2(3)   := '040';                            -- �≮�����i�ǉ��j
-- 2021/09/17 Ver1.4 ADD Start
--
  --�N�C�b�N�R�[�h
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';     -- �T���f�[�^���
  cv_lookup_chain_code      CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';               -- �`�F�[���R�[�h
  cv_lookup_gyotai_code     CONSTANT  VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';          -- �Ƒԏ�����
  cv_lookup_cls_code        CONSTANT  VARCHAR2(30)  := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  -- �쐬���敪
  cv_lookup_ded_type_code   CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_TYPE';          -- �T���^�C�v
  cv_business_type          CONSTANT  VARCHAR2(20)  := 'XX03_BUSINESS_TYPE';             -- �r�W�l�X�^�C�v
-- 2021/10/21 Ver1.5 ADD Start
  cv_head_erase_status      CONSTANT  VARCHAR2(30)  := 'XXCOK1_HEAD_ERASE_STATUS';       -- �T�������w�b�_�[�X�e�[�^�X
-- 2021/10/21 Ver1.5 ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gn_request_id          NUMBER;                                                         -- ���̓p�����[�^�F�v��ID
  gn_condition_line_id   NUMBER;                                                         -- ���̓p�����[�^�F�T���ڍ�ID
--
  -- �T���������[�N�e�[�u����`
  TYPE gr_condition_work_rec IS RECORD(
    condition_id                xxcok_condition_header.condition_id%TYPE                 -- �T������ID
   ,condition_no                xxcok_condition_header.condition_no%TYPE                 -- �T���ԍ�
   ,enabled_flag_h              xxcok_condition_header.enabled_flag_h%TYPE               -- �w�b�_�L���t���O
   ,corp_code                   xxcok_condition_header.corp_code%TYPE                    -- ��ƃR�[�h
   ,deduction_chain_code        xxcok_condition_header.deduction_chain_code%TYPE         -- �T���p�`�F�[���R�[�h
   ,customer_code               xxcok_condition_header.customer_code%TYPE                -- �ڋq�R�[�h
   ,data_type                   xxcok_condition_header.data_type%TYPE                    -- �f�[�^���
   ,tax_code                    xxcok_condition_header.tax_code%TYPE                     -- �ŃR�[�h
   ,tax_rate                    xxcok_condition_header.tax_rate%TYPE                     -- �ŃR�[�h
   ,start_date_active           xxcok_condition_header.start_date_active%TYPE            -- �J�n��
   ,end_date_active             xxcok_condition_header.end_date_active%TYPE              -- �I����
   ,content                     xxcok_condition_header.content%TYPE                      -- ���e
   ,decision_no                 xxcok_condition_header.decision_no%TYPE                  -- ����No
   ,agreement_no                xxcok_condition_header.agreement_no%TYPE                 -- �_��ԍ�
   ,header_recovery_flag        xxcok_condition_header.header_recovery_flag%TYPE         -- ���J�o���Ώۃt���O
   ,condition_line_id           xxcok_condition_lines.condition_line_id%TYPE             -- �T���ڍ�ID
   ,detail_number               xxcok_condition_lines.detail_number%TYPE                 -- ���הԍ�
   ,enabled_flag_l              xxcok_condition_lines.enabled_flag_l%TYPE                -- ���חL���t���O
   ,target_category             xxcok_condition_lines.target_category%TYPE               -- �Ώۋ敪
   ,product_class               xxcok_condition_lines.product_class%TYPE                 -- ���i�敪
   ,item_code                   xxcok_condition_lines.item_code%TYPE                     -- �i�ڃR�[�h
   ,uom_code                    xxcok_condition_lines.uom_code%TYPE                      -- �P��
   ,line_recovery_flag          xxcok_condition_lines.line_recovery_flag%TYPE            -- ���J�o���Ώۃt���O
   ,shop_pay_1                  xxcok_condition_lines.shop_pay_1%TYPE                    -- �X�[(��)
   ,material_rate_1             xxcok_condition_lines.material_rate_1%TYPE               -- ����(��)
   ,condition_unit_price_en_2   xxcok_condition_lines.condition_unit_price_en_2%TYPE     -- �����P���Q(�~)
   ,demand_en_3                 xxcok_condition_lines.demand_en_3%TYPE                   -- ����(�~)
   ,shop_pay_en_3               xxcok_condition_lines.shop_pay_en_3%TYPE                 -- �X�[(�~)
   ,compensation_en_3           xxcok_condition_lines.compensation_en_3%TYPE             -- ��U(�~)
   ,wholesale_margin_en_3       xxcok_condition_lines.wholesale_margin_en_3%TYPE         -- �≮�}�[�W��(�~)
   ,wholesale_margin_per_3      xxcok_condition_lines.wholesale_margin_per_3%TYPE        -- �≮�}�[�W��(��)
   ,accrued_en_3                xxcok_condition_lines.accrued_en_3%TYPE                  -- �����v�R(�~)
   ,normal_shop_pay_en_4        xxcok_condition_lines.normal_shop_pay_en_4%TYPE          -- �ʏ�X�[(�~)
   ,just_shop_pay_en_4          xxcok_condition_lines.just_shop_pay_en_4%TYPE            -- ����X�[(�~)
   ,just_condition_en_4         xxcok_condition_lines.just_condition_en_4%TYPE           -- �������(�~)
   ,wholesale_adj_margin_en_4   xxcok_condition_lines.wholesale_adj_margin_en_4%TYPE     -- �≮�}�[�W���C��(�~)
   ,wholesale_adj_margin_per_4  xxcok_condition_lines.wholesale_adj_margin_per_4%TYPE    -- �≮�}�[�W���C��(��)
   ,accrued_en_4                xxcok_condition_lines.accrued_en_4%TYPE                  -- �����v�S(�~)
   ,prediction_qty_5            xxcok_condition_lines.prediction_qty_5%TYPE              -- �\�����ʂT(�{)
   ,ratio_per_5                 xxcok_condition_lines.ratio_per_5%TYPE                   -- �䗦(��)
   ,amount_prorated_en_5        xxcok_condition_lines.amount_prorated_en_5%TYPE          -- ���z��(�~)
   ,condition_unit_price_en_5   xxcok_condition_lines.condition_unit_price_en_5%TYPE     -- �����P���T(�~)
   ,support_amount_sum_en_5     xxcok_condition_lines.support_amount_sum_en_5%TYPE       -- ���^�����v(�~)
   ,prediction_qty_6            xxcok_condition_lines.prediction_qty_6%TYPE              -- �\�����ʂU(�{)
   ,condition_unit_price_en_6   xxcok_condition_lines.condition_unit_price_en_6%TYPE     -- �����P���U(�~)
   ,target_rate_6               xxcok_condition_lines.target_rate_6%TYPE                 -- �Ώۗ�(��)
   ,deduction_unit_price_en_6   xxcok_condition_lines.deduction_unit_price_en_6%TYPE     -- �T���P��(�~)
-- 2021/03/22 Ver1.2 MOD Start
--   ,accounting_base             xxcok_condition_lines.accounting_base%TYPE               -- �v�㋒�_
   ,accounting_customer_code    xxcok_condition_lines.accounting_customer_code%TYPE      -- �v��ڋq
   ,sale_base_code              xxcmm_cust_accounts.sale_base_code%TYPE                  -- ���㋒�_
-- 2021/03/22 Ver1.2 MOD End
   ,deduction_amount            xxcok_condition_lines.deduction_amount%TYPE              -- �T���z(�{��)
   ,deduction_tax_amount        xxcok_condition_lines.deduction_tax_amount%TYPE          -- �T���Ŋz
   ,deduction_type              fnd_lookup_values.attribute2%TYPE                        -- �T���^�C�v
    );
--
  -- �̔��T���X�V�p���[�N�e�[�u����`
  TYPE gr_condition_work_1_rec IS RECORD(
    condition_id                xxcok_condition_header.condition_id%TYPE                 -- �T������ID
   ,condition_line_id           xxcok_condition_lines.condition_line_id%TYPE             -- �T���ڍ�ID
   ,end_date_active             xxcok_condition_header.end_date_active%TYPE              -- �I����
    );
--
  -- ���[�N�e�[�u���^��`
  -- �T�������ڍ׏��
  TYPE g_condition_work_ttype  IS TABLE OF gr_condition_work_rec INDEX BY BINARY_INTEGER;
    gt_condition_work_tbl    g_condition_work_ttype;
--
  -- �̔��T���X�V�p���
  TYPE g_condition_work_1_ttype  IS TABLE OF gr_condition_work_1_rec INDEX BY BINARY_INTEGER;
    gt_condition_work_1_tbl    g_condition_work_1_ttype;

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date              DATE;                                             -- �Ɩ����t
  gd_work_date              DATE;                                             -- ���[�N�p
--
  gv_dedu_uom_code          VARCHAR2(3) DEFAULT NULL;                         -- �T���P��
  gn_dedu_unit_price        NUMBER      DEFAULT 0;                            -- �T���P��
  gn_dedu_quantity          NUMBER      DEFAULT 0;                            -- �T������
  gn_dedu_amount            NUMBER      DEFAULT 0;                            -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                         -- ��U
  gn_margin                   NUMBER;                                         -- �≮�}�[�W��
  gn_sales_promotion_expenses NUMBER;                                         -- �g��
  gn_margin_reduction         NUMBER;                                         -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
  gn_dedu_tax_amount        NUMBER      DEFAULT 0;                            -- �T���Ŋz
-- 2020/12/03 Ver1.1 ADD Start
  gn_sales_id_1             NUMBER      DEFAULT 0;                            -- �O�񏈗�ID(�̔����уw�b�_�[ID)
  gn_sales_id_2             NUMBER      DEFAULT 0;                            -- �O�񏈗�ID(������ѐU�֏��ID)
-- 2020/12/03 Ver1.1 ADD End
-- 2020/12/03 Ver1.1 DEL Start
--  gd_prev_date              DATE ;                                            -- �O���Ɩ����t
--  gd_prev_month_date        DATE ;                                            -- �O�������t
-- 2020/12/03 Ver1.1 DEL End
  gv_tax_code               VARCHAR2(4) DEFAULT NULL;                         -- �ŃR�[�h
  gn_tax_rate               NUMBER      DEFAULT 0;                            -- �ŗ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �T���}�X�^���擾
  CURSOR get_condition_data_cur
  IS
    SELECT xch.condition_id                        condition_id                                  -- �T������ID
          ,xch.condition_no                        condition_no                                  -- �T���ԍ�
          ,xch.enabled_flag_h                      enabled_flag_h                                -- �w�b�_�L���t���O
          ,xch.corp_code                           corp_code                                     -- ��ƃR�[�h
          ,xch.deduction_chain_code                deduction_chain_code                          -- �T���p�`�F�[���R�[�h
          ,xch.customer_code                       customer_code                                 -- �ڋq�R�[�h
          ,xch.data_type                           data_type                                     -- �f�[�^���
          ,xch.tax_code                            tax_code                                      -- �ŃR�[�h
          ,xch.tax_rate                            tax_rate                                      -- �ŗ�
          ,xch.start_date_active                   start_date_active                             -- �J�n��
          ,xch.end_date_active                     end_date_active                               -- �I����
          ,xch.content                             content                                       -- ���e
          ,xch.decision_no                         decision_no                                   -- ����No
          ,xch.agreement_no                        agreement_no                                  -- �_��ԍ�
          ,xch.header_recovery_flag                header_recovery_flag                          -- ���J�o���Ώۃt���O
          ,xcl.condition_line_id                   condition_line_id                             -- �T���ڍ�ID
          ,xcl.detail_number                       detail_number                                 -- ���הԍ�
          ,xcl.enabled_flag_l                      enabled_flag_l                                -- ���חL���t���O
          ,xcl.target_category                     target_category                               -- �Ώۋ敪
          ,xcl.product_class                       product_class                                 -- ���i�敪
          ,xcl.item_code                           item_code                                     -- �i�ڃR�[�h
          ,xcl.uom_code                            uom_code                                      -- �P��
          ,xcl.line_recovery_flag                  line_recovery_flag                            -- ���J�o���Ώۃt���O
          ,xcl.shop_pay_1                          shop_pay_1                                    -- �X�[(��)
          ,xcl.material_rate_1                     material_rate_1                               -- ����(��)
          ,xcl.condition_unit_price_en_2           condition_unit_price_en_2                     -- �����P���Q(�~)
          ,xcl.demand_en_3                         demand_en_3                                   -- ����(�~)
          ,xcl.shop_pay_en_3                       shop_pay_en_3                                 -- �X�[(�~)
          ,xcl.compensation_en_3                   compensation_en_3                             -- ��U(�~)
          ,xcl.wholesale_margin_en_3               wholesale_margin_en_3                         -- �≮�}�[�W��(�~)
          ,xcl.wholesale_margin_per_3              wholesale_margin_per_3                        -- �≮�}�[�W��(��)
          ,xcl.accrued_en_3                        accrued_en_3                                  -- �����v�R(�~)
          ,xcl.normal_shop_pay_en_4                normal_shop_pay_en_4                          -- �ʏ�X�[(�~)
          ,xcl.just_shop_pay_en_4                  just_shop_pay_en_4                            -- ����X�[(�~)
          ,xcl.just_condition_en_4                 just_condition_en_4                           -- �������(�~)
          ,xcl.wholesale_adj_margin_en_4           wholesale_adj_margin_en_4                     -- �≮�}�[�W���C��(�~)
          ,xcl.wholesale_adj_margin_per_4          wholesale_adj_margin_per_4                    -- �≮�}�[�W���C��(��)
          ,xcl.accrued_en_4                        accrued_en_4                                  -- �����v�S(�~)
          ,xcl.prediction_qty_5                    prediction_qty_5                              -- �\�����ʂT(�{)
          ,xcl.ratio_per_5                         ratio_per_5                                   -- �䗦(��)
          ,xcl.amount_prorated_en_5                amount_prorated_en_5                          -- ���z��(�~)
          ,xcl.condition_unit_price_en_5           condition_unit_price_en_5                     -- �����P���T(�~)
          ,xcl.support_amount_sum_en_5             support_amount_sum_en_5                       -- ���^�����v(�~)
          ,xcl.prediction_qty_6                    prediction_qty_6                              -- �\�����ʂU(�{)
          ,xcl.condition_unit_price_en_6           condition_unit_price_en_6                     -- �����P���U(�~)
          ,xcl.target_rate_6                       target_rate_6                                 -- �Ώۗ�(��)
          ,xcl.deduction_unit_price_en_6           deduction_unit_price_en_6                     -- �T���P��(�~)
-- 2021/03/22 Ver1.2 MOD Start
--          ,xcl.accounting_base                     accounting_base                               -- �v�㋒�_
          ,xcl.accounting_customer_code            accounting_customer_code                      -- �v��ڋq
          ,xca.sale_base_code                      sale_base_code                                -- ���㋒�_
-- 2021/03/22 Ver1.2 MOD End
          ,xcl.deduction_amount                    deduction_amount                              -- �T���z(�{��)
          ,xcl.deduction_tax_amount                deduction_tax_amount                          -- �T���Ŋz
          ,flv.attribute2                          deduction_type                                -- �T���^�C�v
    FROM   xxcok_condition_header    xch                     -- �T�������e�[�u��
          ,xxcok_condition_lines     xcl                     -- �T���ڍ׃e�[�u��
          ,fnd_lookup_values         flv                     -- �N�C�b�N�R�[�h
-- 2021/03/22 Ver1.2 ADD Start
          ,xxcmm_cust_accounts       xca                     -- �ڋq�ǉ����
-- 2021/03/22 Ver1.2 ADD End
    WHERE  xch.condition_id              = xcl.condition_id     -- �T������ID
    AND    xch.data_type                 = flv.lookup_code      -- �f�[�^���
    AND    flv.lookup_type               = cv_lookup_dedu_code  -- �T���f�[�^���
    AND    flv.enabled_flag              = cv_y_flag            -- �g�p�\�FY
    AND    flv.language                  = USERENV('LANG')      -- ����FUSERENV('LANG')
    AND  ((    xch.header_recovery_flag <> cv_n_flag
           AND xcl.line_recovery_flag   <> cv_n_flag)
        OR(    xch.header_recovery_flag <> cv_n_flag
           AND xcl.line_recovery_flag    = cv_n_flag)
        OR(    xch.header_recovery_flag  = cv_n_flag
           AND xcl.line_recovery_flag   <> cv_n_flag))          -- ���J�o���Ώۃt���O
    AND  (     xch.request_id            = gn_request_id
           OR  xcl.request_id            = gn_request_id)       -- �v��ID
-- 2021/03/22 Ver1.2 ADD Start
      AND xcl.accounting_customer_code   = xca.customer_code(+)          -- �T���ڍ�:�v��ڋq
-- 2021/03/22 Ver1.2 ADD End
    ORDER BY
           DECODE(xcl.line_recovery_flag,cv_d_flag,cn_1
                                        ,cv_i_flag,cn_2
                                        ,cv_u_flag,cn_3
                                        ,cn_4)                  -- ���׃��J�o���Ώۃt���O
          ,xcl.condition_no                                     -- �T���ԍ�
          ,xcl.detail_number                                    -- ���הԍ�
    ;
--
  -- �̔����я��f�[�^���o
  CURSOR g_sales_exp_cur
  IS
    WITH
      flvc1 AS
       (SELECT /*+ MATERIALIZED */ lookup_code
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_ded_type_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute1    = cv_y_flag
       )
     ,flvc2 AS
       (SELECT /*+ MATERIALIZED */ meaning
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_cls_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute4    = cv_y_flag
       )
     ,flvc3 AS
       (SELECT /*+ MATERIALIZED */ lookup_code
        FROM   fnd_lookup_values flvc
        WHERE  flvc.lookup_type   = cv_lookup_gyotai_code
        AND    flvc.language      = USERENV('LANG')
        AND    flvc.enabled_flag  = cv_y_flag
        AND    flvc.attribute2    = cv_y_flag
       )
    -- �@�ڋq
    SELECT /*+ leading(xcrt xseh xsel xca chcd dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- ���㋒�_
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- �ڋq�y�[�i��z
          ,xseh.delivery_date                      delivery_date                -- �[�i��
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- �̔����і���ID
          ,xsel.item_code                          div_item_code                -- ����i�ڃR�[�h
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- �[�i�P��
          ,xsel.dlv_unit_price                     dlv_unit_price               -- �[�i�P��
          ,xsel.dlv_qty                            dlv_qty                      -- �[�i����
          ,xsel.pure_amount                        pure_amount                  -- �{�̋��z
          ,xsel.tax_amount                         tax_amount                   -- ����ŋ��z
          ,xsel.tax_code                           tax_code                     -- �ŋ��R�[�h
          ,xsel.tax_rate                           tax_rate                     -- ����ŗ�
          ,xcrt.condition_id                       condition_id                 -- �T������ID
          ,xcrt.condition_no                       condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                          corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code               deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                      customer_code                -- �ڋq�R�[�h
          ,xcrt.data_type                          data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                       tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                       tax_rate_con                 -- �ŗ�
          ,chcd.attribute3                         chain_base                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                      cust_base                    -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                  condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                      product_class                -- ���i�敪
          ,xcrt.item_code                          item_code                    -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                           uom_code                     -- �P��(����)
          ,xcrt.target_category                    target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                         shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                    material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- �T���P��(�~)
          ,dtyp.attribute2                         attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag               header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   fnd_lookup_values                                          dtyp  -- �f�[�^���
          ,fnd_lookup_values                                          chcd  -- �`�F�[���X
          ,xxcmm_cust_accounts                                        xca   -- �ڋq�ǉ����
          ,xxcok_sales_exp_h                                          xseh  -- �̔����уw�b�_
          ,xxcok_sales_exp_l                                          xsel  -- �̔����і���
          ,xxcok_condition_recovery_temp                              xcrt  -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type(+)               = cv_lookup_chain_code
    AND    chcd.lookup_code(+)               = xca.intro_chain_code2
    AND    chcd.language(+)                  = USERENV('LANG')
    AND    chcd.enabled_flag(+)              = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    xseh.ship_to_customer_code        = xcrt.customer_code
    AND    xcrt.customer_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- �A�T���p�`�F�[��
    SELECT /*+ leading(xcrt xca xseh xsel chcd dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- ���㋒�_
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- �ڋq�y�[�i��z
          ,xseh.delivery_date                      delivery_date                -- �[�i��
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- �̔����і���ID
          ,xsel.item_code                          div_item_code                -- ����i�ڃR�[�h
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- �[�i�P��
          ,xsel.dlv_unit_price                     dlv_unit_price               -- �[�i�P��
          ,xsel.dlv_qty                            dlv_qty                      -- �[�i����
          ,xsel.pure_amount                        pure_amount                  -- �{�̋��z
          ,xsel.tax_amount                         tax_amount                   -- ����ŋ��z
          ,xsel.tax_code                           tax_code                     -- �ŋ��R�[�h
          ,xsel.tax_rate                           tax_rate                     -- ����ŗ�
          ,xcrt.condition_id                       condition_id                 -- �T������ID
          ,xcrt.condition_no                       condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                          corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code               deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                      customer_code                -- �ڋq�R�[�h
          ,xcrt.data_type                          data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                       tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                       tax_rate_con                 -- �ŗ�
          ,chcd.attribute3                         chain_base                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                      cust_base                    -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                  condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                      product_class                -- ���i�敪
          ,xcrt.item_code                          item_code                    -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                           uom_code                     -- �P��(����)
          ,xcrt.target_category                    target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                         shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                    material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- �T���P��(�~)
          ,dtyp.attribute2                         attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag               header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   fnd_lookup_values                                          dtyp  -- �f�[�^���
          ,fnd_lookup_values                                          chcd  -- �`�F�[���X
          ,xxcmm_cust_accounts                                        xca   -- �ڋq�ǉ����
          ,xxcok_sales_exp_h                                          xseh  -- �̔����уw�b�_
          ,xxcok_sales_exp_l                                          xsel  -- �̔����і���
          ,xxcok_condition_recovery_temp                              xcrt  -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type(+)               = cv_lookup_chain_code
    AND    chcd.lookup_code(+)               = xca.intro_chain_code2
    AND    chcd.language(+)                  = USERENV('LANG')
    AND    chcd.enabled_flag(+)              = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    xca.intro_chain_code2             = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code    IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- �B���
    SELECT /*+ leading(xcrt chcd xca xseh xsel dtyp) FULL(xcrt)
               USE_NL(xseh) USE_NL(xsel) USE_NL(xca) USE_NL(chcd) USE_NL(dtyp) */
           xseh.sales_base_code                    sales_base_code              -- ���㋒�_
          ,xseh.ship_to_customer_code              ship_to_customer_code        -- �ڋq�y�[�i��z
          ,xseh.delivery_date                      delivery_date                -- �[�i��
          ,xsel.sales_exp_line_id                  sales_exp_line_id            -- �̔����і���ID
          ,xsel.item_code                          div_item_code                -- ����i�ڃR�[�h
          ,xsel.dlv_uom_code                       dlv_uom_code                 -- �[�i�P��
          ,xsel.dlv_unit_price                     dlv_unit_price               -- �[�i�P��
          ,xsel.dlv_qty                            dlv_qty                      -- �[�i����
          ,xsel.pure_amount                        pure_amount                  -- �{�̋��z
          ,xsel.tax_amount                         tax_amount                   -- ����ŋ��z
          ,xsel.tax_code                           tax_code                     -- �ŋ��R�[�h
          ,xsel.tax_rate                           tax_rate                     -- ����ŗ�
          ,xcrt.condition_id                       condition_id                 -- �T������ID
          ,xcrt.condition_no                       condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                          corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code               deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                      customer_code                -- �ڋq�R�[�h
          ,xcrt.data_type                          data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                       tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                       tax_rate_con                 -- �ŗ�
          ,chcd.attribute3                         chain_base                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                      cust_base                    -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                  condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                      product_class                -- ���i�敪
          ,xcrt.item_code                          item_code                    -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                           uom_code                     -- �P��(����)
          ,xcrt.target_category                    target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                         shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                    material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2          condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                       accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                  compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3              wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                       accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4          wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5          condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6          deduction_unit_price_en_6    -- �T���P��(�~)
          ,dtyp.attribute2                         attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag               header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                 line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   fnd_lookup_values                                          dtyp  -- �f�[�^���
          ,fnd_lookup_values                                          chcd  -- �`�F�[���X
          ,xxcmm_cust_accounts                                        xca   -- �ڋq�ǉ����
          ,xxcok_sales_exp_h                                          xseh  -- �̔����уw�b�_
          ,xxcok_sales_exp_l                                          xsel  -- �̔����і���
          ,xxcok_condition_recovery_temp                              xcrt  -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                                                      d_typ
          ,flvc2                                                      mk_cls
          ,flvc3                                                      gyotai_sho
    WHERE  1=1
    AND    xseh.sales_exp_header_id          = xsel.sales_exp_header_id
    AND    xseh.create_class                 = mk_cls.meaning
    AND    xca.customer_code                 = xseh.ship_to_customer_code
    AND    xca.business_low_type             = gyotai_sho.lookup_code
    AND    chcd.lookup_type                  = cv_lookup_chain_code
    AND    chcd.lookup_code                  = xca.intro_chain_code2
    AND    chcd.language                     = USERENV('LANG')
    AND    chcd.enabled_flag                 = cv_y_flag
    AND    xcrt.enabled_flag_h               = cv_y_flag
    AND    dtyp.lookup_type                  = cv_lookup_dedu_code
    AND    dtyp.lookup_code                  = xcrt.data_type
    AND    dtyp.language                     = USERENV('LANG')
    AND    dtyp.enabled_flag                 = cv_y_flag
    AND    chcd.attribute1                   = xcrt.corp_CODE
    AND    xcrt.corp_code               IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
                                       AND     xcrt.end_date_active
--    AND    xseh.delivery_date          BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l               = cv_y_flag
-- 2021/04/06 Ver1.2 MOD Start
    AND (  xcrt.item_code IN (xsel.item_code, xsel.vessel_group_item_code)
--    AND (  xsel.item_code                    = xcrt.item_code
-- 2021/04/06 Ver1.2 MOD End
    OR     xsel.product_class                = xcrt.product_class)
    AND    dtyp.attribute2                   = d_typ.lookup_code
-- 2020/12/03 Ver1.1 ADD Start
    AND    xseh.sales_exp_header_id         <= gn_sales_id_1
-- 2020/12/03 Ver1.1 ADD End
    ;
--
  -- �J�[�\�����R�[�h�擾�p
  g_sales_exp_rec             g_sales_exp_cur%ROWTYPE;
--
  --���ѐU�֏��(EDI)�f�[�^���o
  CURSOR g_selling_trns_cur
  IS
    WITH
     flvc1 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_ded_type_code  -- �T���^�C�v
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute1   = cv_y_flag            )     -- �̔��T���쐬�Ώ�
     ,flvc3 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_gyotai_code  -- �Ƒ�(������)
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute2   = cv_y_flag            )   -- �̔��T���쐬�ΏۊO
    -- �@�ڋq
    SELECT /*+ leading(xcrt xsi xca flv2 flv) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                             base_code                    -- �U�֐拒�_
          ,xsi.cust_code                             cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date                          selling_date                 -- ����v���
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                             item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                             unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price                   delivery_unit_price          -- �[�i�P��
          ,xsi.qty                                   qty                          -- ����
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                              tax_code                     -- ����ŃR�[�h
          ,xsi.tax_rate                              tax_rate                     -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                         condition_id                 -- �T������ID
          ,xcrt.condition_no                         condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                            corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                        customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                            data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                         tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                         tax_rate_con                 -- �ŗ�
          ,flv.attribute3                            attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                        sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                    condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                        product_class                -- ���i�敪
          ,xcrt.item_code                            item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                             uom_code                     -- �P��(����)
          ,xcrt.target_category                      target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                           shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                      material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                           attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- �T���f�[�^�쐬�pEDI������ѐU��
          ,xxcmm_cust_accounts            xca             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv             -- �`�F�[���X
          ,fnd_lookup_values              flv2            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt            -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xsi.cust_code                 = xcrt.customer_code
    AND    xcrt.customer_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ��
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- �A�T���p�`�F�[��
    SELECT /*+ leading(xcrt xca xsi flv2 flv) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                             base_code                    -- �U�֐拒�_
          ,xsi.cust_code                             cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date                          selling_date                 -- ����v���
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                             item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                             unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price                   delivery_unit_price          -- �[�i�P��
          ,xsi.qty                                   qty                          -- ����
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                              tax_code                     -- ����ŃR�[�h
          ,xsi.tax_rate                              tax_rate                     -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                         condition_id                 -- �T������ID
          ,xcrt.condition_no                         condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                            corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                        customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                            data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                         tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                         tax_rate_con                 -- �ŗ�
          ,flv.attribute3                            attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                        sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                    condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                        product_class                -- ���i�敪
          ,xcrt.item_code                            item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                             uom_code                     -- �P��(����)
          ,xcrt.target_category                      target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                           shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                      material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                           attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- �T���f�[�^�쐬�pEDI������ѐU��
          ,xxcmm_cust_accounts            xca             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv             -- �`�F�[���X
          ,fnd_lookup_values              flv2            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt            -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xca.intro_chain_code2         = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code    IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ��
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    UNION ALL
    -- �B���
    SELECT /*+ leading(xcrt flv xca xsi flv2) full(xcrt)
               use_nl(xsi) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xsi.delivery_base_code                    delivery_base_code           -- �U�֌����_
          ,xsi.selling_from_cust_code                selling_from_cust_code       -- �U�֌��ڋq
          ,xsi.base_code                             base_code                    -- �U�֐拒�_
          ,xsi.cust_code                             cust_code                    -- �U�֐�ڋq
          ,xsi.selling_date                          selling_date                 -- ����v���
          ,xsi.selling_trns_info_id                  selling_trns_info_id         -- ������ѐU�֏��ID
          ,xsi.item_code                             item_code                    -- �i�ڃR�[�h
          ,xsi.unit_type                             unit_type                    -- �[�i�P��
          ,xsi.delivery_unit_price                   delivery_unit_price          -- �[�i�P��
          ,xsi.qty                                   qty                          -- ����
          ,xsi.selling_amt_no_tax                    selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xsi.tax_code                              tax_code                     -- ����ŃR�[�h
          ,xsi.tax_rate                              tax_rate                     -- ����ŗ�
          ,xsi.selling_amt - xsi.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                         condition_id                 -- �T������ID
          ,xcrt.condition_no                         condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                            corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                 deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                        customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                            data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                         tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                         tax_rate_con                 -- �ŗ�
          ,flv.attribute3                            attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                        sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                    condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                        product_class                -- ���i�敪
          ,xcrt.item_code                            item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                             uom_code                     -- �P��(����)
          ,xcrt.target_category                      target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                           shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                      material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2            condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                         accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                    compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                         accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                  just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4            wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5            condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6            deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                           attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                 header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                   line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM   xxcok_dedu_edi_sell_trns       xsi             -- �T���f�[�^�쐬�pEDI������ѐU��
          ,xxcmm_cust_accounts            xca             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv             -- �`�F�[���X
          ,fnd_lookup_values              flv2            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt            -- �T���}�X�^���J�o���p���[�N�e�[�u��
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  1=1
    AND    xsi.report_decision_flag      = cv_1
    AND    xsi.selling_trns_type         = cv_1
    AND    xca.customer_code             = xsi.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    flv.attribute1                = xcrt.corp_CODE
    AND    xcrt.corp_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xsi.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND (  xsi.item_code                 = xcrt.item_code
    OR     xsi.product_class             = xcrt.product_class ) -- ��
-- 2020/12/03 Ver1.1 ADD Start
    AND    xsi.selling_trns_info_id     <= gn_sales_id_2
-- 2020/12/03 Ver1.1 ADD End
    ;
--
  -- �J�[�\�����R�[�h�擾�p
  g_selling_trns_rec          g_selling_trns_cur%ROWTYPE;
--
  -- ���ѐU�֏��i�U�֊����j�擾
  CURSOR g_actual_trns_cur
  IS
    WITH
     flvc1 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_ded_type_code  -- �T���^�C�v
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute1   = cv_y_flag            )     -- �̔��T���쐬�Ώ�
     ,flvc3 AS
        ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
          FROM  fnd_lookup_values flvc
          WHERE flvc.lookup_type  = cv_lookup_gyotai_code  -- �Ƒ�(������)
          AND   flvc.language     = USERENV('LANG')
          AND   flvc.enabled_flag = cv_y_flag
          AND   flvc.attribute2   = cv_y_flag            )   -- �̔��T���쐬�ΏۊO
    -- �@�ڋq
    SELECT /*+ leading(xcrt xdst xca flv2 flv) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                              base_code                    -- �U�֐拒�_
          ,xdst.cust_code                              cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                           selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                              item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                              unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                    delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                    qty                          -- ����
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                               tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                               tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                           condition_id                 -- �T������ID
          ,xcrt.condition_no                           condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                              corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                          customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                              data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                           tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                           tax_rate_con                 -- �ŗ�
          ,flv.attribute3                              attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                          sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                      condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                          product_class                -- ���i�敪
          ,xcrt.item_code                              item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                               uom_code                     -- �P��(����)
          ,xcrt.target_category                        target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                             shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                        material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                             attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts            xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv                             -- �`�F�[���X
          ,fnd_lookup_values              flv2                            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- ���ѐU�֋敪:�U�֊���
    AND    xdst.report_decision_flag     = cv_1    -- ����m��t���O:�m��
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type(+)            = cv_lookup_chain_code
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = USERENV('LANG')
    AND    flv.enabled_flag(+)           = cv_y_flag
    AND    xcrt.enabled_flag_h            = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xdst.cust_code                = xcrt.customer_code
    AND    xcrt.customer_code       IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l           = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ��
    UNION ALL
    -- �A�T���p�`�F�[��
    SELECT /*+ leading(xcrt xca xdst flv2 flv) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                              base_code                    -- �U�֐拒�_
          ,xdst.cust_code                              cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                           selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                              item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                              unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                    delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                    qty                          -- ����
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                               tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                               tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                           condition_id                 -- �T������ID
          ,xcrt.condition_no                           condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                              corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                          customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                              data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                           tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                           tax_rate_con                 -- �ŗ�
          ,flv.attribute3                              attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                          sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                      condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                          product_class                -- ���i�敪
          ,xcrt.item_code                              item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                               uom_code                     -- �P��(����)
          ,xcrt.target_category                        target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                             shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                        material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                             attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts            xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv                             -- �`�F�[���X
          ,fnd_lookup_values              flv2                            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- ���ѐU�֋敪:�U�֊���
    AND    xdst.report_decision_flag     = cv_1    -- ����m��t���O:�m��
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    xca.intro_chain_code2          = xcrt.deduction_chain_code
    AND    xcrt.deduction_chain_code IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date        BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l            = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ��
    UNION ALL
    -- �B���
    SELECT /*+ leading(xcrt flv xca xdst flv2) full(xcrt)
               use_nl(xdst) use_nl(xca) use_nl(flv) use_nl(flv2) */
           xdst.delivery_base_code                     delivery_base_code           -- �U�֌����_
          ,xdst.selling_from_cust_code                 selling_from_cust_code       -- �U�֌��ڋq
          ,xdst.base_code                              base_code                    -- �U�֐拒�_
          ,xdst.cust_code                              cust_code                    -- �U�֐�ڋq
          ,xdst.selling_date                           selling_date                 -- ����v���
          ,xdst.selling_trns_info_id                   selling_trns_info_id         -- ������ѐU�֏��ID
          ,xdst.item_code                              item_code                    -- �i�ڃR�[�h
          ,xdst.unit_type                              unit_type                    -- �[�i�P��
          ,xdst.delivery_unit_price                    delivery_unit_price          -- �[�i�P��
          ,xdst.qty                                    qty                          -- ����
          ,xdst.selling_amt_no_tax                     selling_amt_no_tax           -- �{�̋��z�i�Ŕ����j
          ,xdst.tax_code                               tax_code                     -- ����ŃR�[�h
          ,xdst.tax_rate                               tax_rate                     -- ����ŗ�
          ,xdst.selling_amt - xdst.selling_amt_no_tax  tax_amount                   -- ����Ŋz
          ,xcrt.condition_id                           condition_id                 -- �T������ID
          ,xcrt.condition_no                           condition_no                 -- �T���ԍ�
          ,xcrt.corp_code                              corp_code                    -- ��ƃR�[�h
          ,xcrt.deduction_chain_code                   deduction_chain_code         -- �T���p�`�F�[���R�[�h
          ,xcrt.customer_code                          customer_code                -- �ڋq�R�[�h(����)
          ,xcrt.data_type                              data_type                    -- �f�[�^���
          ,xcrt.tax_code_con                           tax_code_con                 -- �ŃR�[�h
          ,xcrt.tax_rate_con                           tax_rate_con                 -- �ŗ�
          ,flv.attribute3                              attribute3                   -- �{���S�����_(�`�F�[���X)
          ,xca.sale_base_code                          sale_base_code               -- ���㋒�_(�ڋq)
          ,xcrt.condition_line_id                      condition_line_id            -- �T���ڍ�ID
          ,xcrt.product_class                          product_class                -- ���i�敪
          ,xcrt.item_code                              item_code_cond               -- �i�ڃR�[�h(����)
          ,xcrt.uom_code                               uom_code                     -- �P��(����)
          ,xcrt.target_category                        target_category              -- �Ώۋ敪
          ,xcrt.shop_pay_1                             shop_pay_1                   -- �X�[(��)
          ,xcrt.material_rate_1                        material_rate_1              -- ����(��)
          ,xcrt.condition_unit_price_en_2              condition_unit_price_en_2    -- �����P���Q(�~)
          ,xcrt.accrued_en_3                           accrued_en_3                 -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.compensation_en_3                      compensation_en_3            -- ��U(�~)
          ,xcrt.wholesale_margin_en_3                  wholesale_margin_en_3        -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.accrued_en_4                           accrued_en_4                 -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcrt.just_condition_en_4                    just_condition_en_4          -- �������(�~)
          ,xcrt.wholesale_adj_margin_en_4              wholesale_adj_margin_en_4    -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
          ,xcrt.condition_unit_price_en_5              condition_unit_price_en_5    -- �����P���T(�~)
          ,xcrt.deduction_unit_price_en_6              deduction_unit_price_en_6    -- �T���P��(�~)
          ,flv2.attribute2                             attribute2                   -- �T���^�C�v
          ,xcrt.header_recovery_flag                   header_recovery_flag         -- �w�b�_�[���J�o���Ώۃt���O
          ,xcrt.line_recovery_flag                     line_recovery_flag           -- ���׃��J�o���Ώۃt���O
    FROM
           xxcok_dedu_sell_trns_info      xdst                            -- �T���p���ѐU�֏��
          ,xxcmm_cust_accounts            xca                             -- �ڋq�ǉ����
          ,fnd_lookup_values              flv                             -- �`�F�[���X
          ,fnd_lookup_values              flv2                            -- �f�[�^���
          ,xxcok_condition_recovery_temp  xcrt
          ,flvc1                          d_typ
          ,flvc3                          gyotai_sho
    WHERE  xdst.selling_trns_type        = cv_0    -- ���ѐU�֋敪:�U�֊���
    AND    xdst.report_decision_flag     = cv_1    -- ����m��t���O:�m��
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = gyotai_sho.lookup_code
    AND    flv.lookup_type               = cv_lookup_chain_code
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = USERENV('LANG')
    AND    flv.enabled_flag              = cv_y_flag
    AND    xcrt.enabled_flag_h           = cv_y_flag
    AND    flv2.lookup_type              = cv_lookup_dedu_code
    AND    flv2.lookup_code              = xcrt.data_type
    AND    flv2.language                 = USERENV('LANG')
    AND    flv2.enabled_flag             = cv_y_flag
    AND    flv2.attribute2               = d_typ.lookup_code
    AND    flv.attribute1                = xcrt.corp_CODE
    AND    xcrt.corp_code           IS NOT NULL
-- 2020/12/03 Ver1.1 MOD Start
    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
                                       AND xcrt.end_date_active
--    AND    xdst.selling_date       BETWEEN xcrt.start_date_active
--               AND CASE WHEN xcrt.end_date_active < gd_prev_month_date 
--                     THEN xcrt.end_date_active
--                     ELSE gd_prev_month_date
--                   END
-- 2020/12/03 Ver1.1 MOD End
    AND    xcrt.enabled_flag_l            = cv_y_flag
    AND   (xdst.item_code                = xcrt.item_code
    OR     xdst.product_class            = xcrt.product_class) -- ��
  ;
--
  -- �J�[�\�����R�[�h�擾�p
  g_actual_trns_rec          g_actual_trns_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf  OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg  OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#########################  �Œ胍�[�J���ϐ��錾�� START  #########################
--
    lv_errbuf  VARCHAR2(5000)      DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)         DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)      DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--##################################  �Œ蕔 END  ##################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
  BEGIN
--
--#########################  �Œ�X�e�[�^�X�������� START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  �Œ蕔 END  ##################################
--
-- 2020/12/03 Ver1.1 ADD Start
    --========================================
    -- 1.�ő�̔����і���ID(�̔����я��)�擾����
    --========================================
    BEGIN
      SELECT MAX(xsdc.last_processing_id)          -- �O�񏈗�ID(�̔����і���ID)
      INTO   gn_sales_id_1
      FROM   xxcok_sales_deduction_control  xsdc   -- �̔��T���A�g�Ǘ����
      WHERE  xsdc.control_flag  = cv_s_flag        -- �Ǘ����t���O:�̔����я��
      ;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �O�񏈗�ID(�̔����і���ID)���擾�ł��Ȃ������ꍇ
    IF  (gn_sales_id_1 IS NULL) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 2.�ő唄����ѐU�֏��ID(���ѐU�ցiEDI�j)�擾����
    --========================================
    BEGIN
      SELECT MAX(xsdc.last_processing_id)            -- �O�񏈗�ID(������ѐU�֏��ID)
      INTO   gn_sales_id_2
      FROM   xxcok_sales_deduction_control  xsdc     -- �̔��T���A�g�Ǘ����
      WHERE  xsdc.control_flag  = cv_t_flag          -- �Ǘ����t���O:���ѐU��
      ;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �O�񏈗�ID(������ѐU�֏��ID)���擾�ł��Ȃ������ꍇ
    IF  (gn_sales_id_2 IS NULL) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              , cv_msg_id_error
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_api_expt;
    END IF;
-- 2020/12/03 Ver1.1 ADD End
--
    --========================================
    -- 3.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_name
                                              ,iv_name        => cv_msg_proc_date_err
                                              );
--
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2020/12/03 Ver1.1 DEL Start
--    --========================================
--    -- 3.�O�������A�O���̎擾
--    --========================================
--    gd_prev_date       := gd_proc_date - 1 ;
--    gd_prev_month_date := trunc(gd_proc_date,'MM') - 1 ;
-- 2020/12/03 Ver1.1 DEL End
--
  EXCEPTION
--
--############################    �Œ��O������ START  ############################
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
--##################################  �Œ蕔 END  ##################################
--
  END init;
--
--
  /***********************************************************************************
   * Procedure Name   : sales_deduction_delete
   * Description      : A-3.�̔��T���������
   ***********************************************************************************/
  PROCEDURE sales_deduction_delete( in_condition_line_id IN  NUMBER    -- �T���ڍ�ID
                                   ,iv_syori_type        IN  VARCHAR2  -- �����敪
                                   ,ov_errbuf            OUT VARCHAR2  -- �G���[�E���b�Z�[�W           -- # �Œ� #
                                   ,ov_retcode           OUT VARCHAR2  -- ���^�[���E�R�[�h             -- # �Œ� #
                                   ,ov_errmsg            OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
                                   )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'sales_deduction_delete';  -- �v���O������
--
--###############################  �Œ�X�e�[�^�X�������� START  ###############################
--
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--########################################  �Œ蕔 END  ########################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_del_cnt       NUMBER;          -- �G���[�����J�E���g�p
--
  BEGIN
--
    ln_del_cnt := 0;
--
    -- �����敪�p�����[�^��NULL�̏ꍇ
    IF iv_syori_type IS NULL  THEN
--
      SELECT COUNT(*) cnt
      INTO   ln_del_cnt
      FROM   xxcok_sales_deduction  xsd
      WHERE  xsd.recon_slip_num     IS NULL                                -- �x���`�[�ԍ�
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
-- 2020/12/03 Ver1.1 ADD Start
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- �쐬���敪
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.status              = cv_n_flag                           -- �X�e�[�^�X(N�F�V�K)
      AND    xsd.condition_line_id   = in_condition_line_id                -- �T���ڍ�ID
-- 2021/09/17 Ver1.4 ADD Start
      AND    xsd.request_id          <> cn_request_id                       -- �v��ID
-- 2021/09/17 Ver1.4 ADD Start
      ;
--
      gn_del_cnt := gn_del_cnt + ln_del_cnt;
--
      -- �����̍T���f�[�^��_���폜
      UPDATE xxcok_sales_deduction  xsd                                  -- �̔��T�����
      SET    xsd.status                  = cv_c_flag                                -- �X�e�[�^�X
            ,xsd.gl_if_flag              = CASE
                                             WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                               cv_u_flag
                                             ELSE
                                               cv_r_flag
                                           END                                      -- GL�A�g�t���O
            ,xsd.recovery_del_date       = gd_proc_date                             -- ���J�o���[���t
            ,xsd.cancel_flag             = cv_y_flag                                -- �L�����Z���t���O
            ,xsd.recovery_del_request_id = cn_request_id                            -- ���J�o���f�[�^�폜���v��ID
            ,xsd.cancel_user             = cn_created_by                            -- ������[�UID
            ,xsd.last_updated_by         = cn_last_updated_by                       -- �ŏI�X�V��
            ,xsd.last_update_date        = cd_last_update_date                      -- �ŏI�X�V��
            ,xsd.last_update_login       = cn_last_update_login                     -- �ŏI�X�V���O�C��
            ,xsd.request_id              = cn_request_id                            -- �v��ID
            ,xsd.program_application_id  = cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v��ID
            ,xsd.program_id              = cn_program_id                            -- �R���J�����g�E�v���O����ID
            ,xsd.program_update_date     = cd_program_update_date                   -- �v���O�����X�V��
      WHERE  xsd.recon_slip_num     IS NULL                                -- �x���`�[�ԍ�
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- �쐬���敪
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.status              = cv_n_flag                           -- �X�e�[�^�X(N�F�V�K)
      AND    xsd.condition_line_id   = in_condition_line_id                -- �T���ڍ�ID
-- 2021/09/17 Ver1.4 ADD Start
      AND    xsd.request_id          <> cn_request_id                       -- �v��ID
-- 2021/09/17 Ver1.4 ADD Start
      ;
    -- �����敪�p�����[�^��NULL�ȊO�̏ꍇ
    ELSE
--
      SELECT COUNT(*) cnt
      INTO   ln_del_cnt
      FROM   xxcok_sales_deduction  xsd
      WHERE  xsd.recon_slip_num     IS NULL                                -- �x���`�[�ԍ�
      AND    xsd.source_category     = iv_syori_type                       -- �쐬���敪
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
      AND    xsd.status              = cv_n_flag                           -- �X�e�[�^�X(N�F�V�K)
      AND    xsd.condition_line_id   = in_condition_line_id                -- �T���ڍ�ID
      ;
--
      gn_del_cnt := gn_del_cnt + ln_del_cnt;
--
      UPDATE xxcok_sales_deduction  xsd                                  -- �̔��T�����
      SET    xsd.status                  = cv_c_flag                                -- �X�e�[�^�X
            ,xsd.gl_if_flag              = CASE
                                             WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                               cv_u_flag
                                             ELSE
                                               cv_r_flag
                                           END                                      -- GL�A�g�t���O
            ,xsd.recovery_del_date       = gd_proc_date                             -- ���J�o���[���t
            ,xsd.cancel_flag             = cv_y_flag                                -- �L�����Z���t���O
            ,xsd.recovery_del_request_id = cn_request_id                            -- ���J�o���f�[�^�폜���v��ID
            ,xsd.cancel_user             = cn_created_by                            -- ������[�UID
            ,xsd.last_updated_by         = cn_last_updated_by                       -- �ŏI�X�V��
            ,xsd.last_update_date        = cd_last_update_date                      -- �ŏI�X�V��
            ,xsd.last_update_login       = cn_last_update_login                     -- �ŏI�X�V���O�C��
            ,xsd.request_id              = cn_request_id                            -- �v��ID
            ,xsd.program_application_id  = cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v��ID
            ,xsd.program_id              = cn_program_id                            -- �R���J�����g�E�v���O����ID
            ,xsd.program_update_date     = cd_program_update_date                   -- �v���O�����X�V��
      WHERE  xsd.recon_slip_num     IS NULL                                -- �x���`�[�ԍ�
      AND    xsd.source_category     = iv_syori_type                       -- �쐬���敪
-- 2020/12/03 Ver1.1 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- ����m��t���O
-- 2020/12/03 Ver1.1 ADD End
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
      AND    xsd.status              = cv_n_flag                           -- �X�e�[�^�X(N�F�V�K)
      AND    xsd.condition_line_id   = in_condition_line_id                -- �T���ڍ�ID
      ;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  �Œ蕔 END  ##################################
--
  END sales_deduction_delete;
--
  /**********************************************************************************
   * Procedure Name   : calculation_data
   * Description      : A-5.�T���f�[�^�Z�o
   ***********************************************************************************/
  PROCEDURE calculation_data( iv_syori_type  IN   VARCHAR2  -- �����敪
                            , ov_errbuf      OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           -- # �Œ� #
                            , ov_retcode     OUT  VARCHAR2  -- ���^�[���E�R�[�h             -- # �Œ� #
                            , ov_errmsg      OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
                             )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'calculation_data';  -- �v���O������
--
    -- ==============================
    -- ���[�J���ϐ�
    -- ==============================
    lv_base_code    VARCHAR2(4);                            -- �S�����_
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- ���b�Z�[�W�o�͊֐��̖߂�l
--
--###############################  �Œ�X�e�[�^�X�������� START  ###############################
--
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--########################################  �Œ蕔 END  ########################################
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- �̔����т̏ꍇ
    IF ( iv_syori_type = cv_s_flag ) THEN
      -- ============================================================
      -- ���ʊ֐� �T���z�Z�o
      -- ============================================================
      xxcok_common2_pkg.calculate_deduction_amount_p(
         ov_errbuf                     =>  lv_errbuf                                  -- �G���[�o�b�t�@
        ,ov_retcode                    =>  lv_retcode                                 -- ���^�[���R�[�h
        ,ov_errmsg                     =>  lv_errmsg                                  -- �G���[���b�Z�[�W
        ,iv_item_code                  =>  g_sales_exp_rec.div_item_code              -- �i�ڃR�[�h
        ,iv_sales_uom_code             =>  g_sales_exp_rec.dlv_uom_code               -- �̔��P��
        ,in_sales_quantity             =>  g_sales_exp_rec.dlv_qty                    -- �̔�����
        ,in_sale_pure_amount           =>  g_sales_exp_rec.pure_amount                -- ����{�̋��z
        ,iv_tax_code_trn               =>  g_sales_exp_rec.tax_code                   -- �ŃR�[�h(TRN)
        ,in_tax_rate_trn               =>  g_sales_exp_rec.tax_rate                   -- �ŗ�(TRN)
        ,iv_deduction_type             =>  g_sales_exp_rec.attribute2                 -- �T���^�C�v
        ,iv_uom_code                   =>  g_sales_exp_rec.uom_code                   -- �P��(����)
        ,iv_target_category            =>  g_sales_exp_rec.target_category            -- �Ώۋ敪
        ,in_shop_pay_1                 =>  g_sales_exp_rec.shop_pay_1                 -- �X�[(��)
        ,in_material_rate_1            =>  g_sales_exp_rec.material_rate_1            -- ����(��)
        ,in_condition_unit_price_en_2  =>  g_sales_exp_rec.condition_unit_price_en_2  -- �����P���Q(�~)
        ,in_accrued_en_3               =>  g_sales_exp_rec.accrued_en_3               -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_compensation_en_3          =>  g_sales_exp_rec.compensation_en_3          -- ��U(�~)
        ,in_wholesale_margin_en_3      =>  g_sales_exp_rec.wholesale_margin_en_3      -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
        ,in_accrued_en_4               =>  g_sales_exp_rec.accrued_en_4               -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_just_condition_en_4        =>  g_sales_exp_rec.just_condition_en_4        -- �������(�~)
        ,in_wholesale_adj_margin_en_4  =>  g_sales_exp_rec.wholesale_adj_margin_en_4  -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
        ,in_condition_unit_price_en_5  =>  g_sales_exp_rec.condition_unit_price_en_5  -- �����P���T(�~)
        ,in_deduction_unit_price_en_6  =>  g_sales_exp_rec.deduction_unit_price_en_6  -- �T���P��(�~)
        ,iv_tax_code_mst               =>  g_sales_exp_rec.tax_code_con               -- �ŃR�[�h(MST)
        ,in_tax_rate_mst               =>  g_sales_exp_rec.tax_rate_con               -- �ŗ�(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                           -- �T���P��
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                         -- �T���P��
        ,on_deduction_quantity         =>  gn_dedu_quantity                           -- �T������
        ,on_deduction_amount           =>  gn_dedu_amount                             -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                            -- ��U
        ,on_margin                     =>  gn_margin                                  -- �≮�}�[�W��
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                -- �g��
        ,on_margin_reduction           =>  gn_margin_reduction                        -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                         -- �T���Ŋz
        ,ov_tax_code                   =>  gv_tax_code                                -- �ŃR�[�h
        ,on_tax_rate                   =>  gn_tax_rate                                -- �ŗ�
      );
--
      -- ���ʊ֐��ɂăG���[�����������ꍇ
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- ��ƃR�[�h��NULL�ȊO�̏ꍇ
        IF  g_sales_exp_rec.corp_code IS NOT NULL  THEN
--
          -- �{���S�����_(���)���擾
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_sales_exp_rec.corp_code
          ;
--
        -- �T���p�`�F�[���R�[�h��NULL�ȊO�̏ꍇ
        ELSIF g_sales_exp_rec.deduction_chain_code IS  NOT NULL  THEN
          -- �{���S�����_(�`�F�[���X)���擾
          lv_base_code  :=  g_sales_exp_rec.chain_base;
--
        -- �ڋq�R�[�h(����)��NULL�ȊO�̏ꍇ
        ELSIF g_sales_exp_rec.customer_code IS  NOT NULL  THEN
          -- ���㋒�_(�ڋq)���擾
          lv_base_code  :=  g_sales_exp_rec.cust_base;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
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
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
      END IF;
--
    -- ���ѐU��(EDI)�̏ꍇ
    ELSIF ( iv_syori_type = cv_t_flag ) THEN
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
        ,iv_tax_code_mst               =>  g_selling_trns_rec.tax_code_con               -- �ŃR�[�h(MST)
        ,in_tax_rate_mst               =>  g_selling_trns_rec.tax_rate_con               -- �ŗ�(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                              -- �T���P��
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                            -- �T���P��
        ,on_deduction_quantity         =>  gn_dedu_quantity                              -- �T������
        ,on_deduction_amount           =>  gn_dedu_amount                                -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                               -- ��U
        ,on_margin                     =>  gn_margin                                     -- �≮�}�[�W��
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                   -- �g��
        ,on_margin_reduction           =>  gn_margin_reduction                           -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                            -- �T���Ŋz
        ,ov_tax_code                   =>  gv_tax_code                                  -- �ŃR�[�h
        ,on_tax_rate                   =>  gn_tax_rate                                  -- �ŗ�
      );
--
      -- ���ʊ֐��ɂăG���[����������
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- ��ƃR�[�h��NULL�ȊO�̏ꍇ
        IF  g_selling_trns_rec.corp_code IS NOT NULL  THEN
--
          -- �{���S�����_(���)���擾
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_selling_trns_rec.corp_code
          ;
--
        -- �T���p�`�F�[���R�[�h��NULL�ȊO�̏ꍇ
        ELSIF g_selling_trns_rec.deduction_chain_code IS  NOT NULL  THEN
          -- �{���S�����_(�`�F�[���X)���擾
          lv_base_code  :=  g_selling_trns_rec.attribute3;
--
        -- �ڋq�R�[�h(����)��NULL�ȊO�̏ꍇ
        ELSIF g_selling_trns_rec.customer_code IS  NOT NULL  THEN
          -- ���㋒�_(�ڋq)���擾
          lv_base_code  :=  g_selling_trns_rec.sale_base_code;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
                      , cv_tkn_source_line_id
                      , g_selling_trns_rec.selling_trns_info_id
                      , cv_tkn_item_code
                      , g_selling_trns_rec.item_code
                      , cv_tkn_sales_uom_code
                      , g_selling_trns_rec.unit_type
                      , cv_tkn_condition_no
                      , g_selling_trns_rec.condition_no
                      , cv_tkn_base_code
                      , lv_base_code
                      , cv_tkn_errmsg
                      , lv_errmsg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
      END IF;
--
    -- ���ѐU��(�U�֊���)�̏ꍇ
    ELSIF ( iv_syori_type = cv_v_flag ) THEN
      xxcok_common2_pkg.calculate_deduction_amount_p(
         ov_errbuf                     =>  lv_errbuf                                    -- �G���[�o�b�t�@
        ,ov_retcode                    =>  lv_retcode                                   -- ���^�[���R�[�h
        ,ov_errmsg                     =>  lv_errmsg                                    -- �G���[���b�Z�[�W
        ,iv_item_code                  =>  g_actual_trns_rec.item_code                  -- �i�ڃR�[�h
        ,iv_sales_uom_code             =>  g_actual_trns_rec.unit_type                  -- �̔��P��
        ,in_sales_quantity             =>  g_actual_trns_rec.qty                        -- �̔�����
        ,in_sale_pure_amount           =>  g_actual_trns_rec.selling_amt_no_tax         -- ����{�̋��z
        ,iv_tax_code_trn               =>  g_actual_trns_rec.tax_code                   -- �ŃR�[�h(TRN)
        ,in_tax_rate_trn               =>  g_actual_trns_rec.tax_rate                   -- �ŗ�(TRN)
        ,iv_deduction_type             =>  g_actual_trns_rec.attribute2                 -- �T���^�C�v
        ,iv_uom_code                   =>  g_actual_trns_rec.uom_code                   -- �P��(����)
        ,iv_target_category            =>  g_actual_trns_rec.target_category            -- �Ώۋ敪
        ,in_shop_pay_1                 =>  g_actual_trns_rec.shop_pay_1                 -- �X�[(��)
        ,in_material_rate_1            =>  g_actual_trns_rec.material_rate_1            -- ����(��)
        ,in_condition_unit_price_en_2  =>  g_actual_trns_rec.condition_unit_price_en_2  -- �����P���Q(�~)
        ,in_accrued_en_3               =>  g_actual_trns_rec.accrued_en_3               -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_compensation_en_3          =>  g_actual_trns_rec.compensation_en_3          -- ��U(�~)
        ,in_wholesale_margin_en_3      =>  g_actual_trns_rec.wholesale_margin_en_3      -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
        ,in_accrued_en_4               =>  g_actual_trns_rec.accrued_en_4               -- �����v�S(�~)
-- 2020/12/03 Ver1.1 ADD Start
        ,in_just_condition_en_4        =>  g_actual_trns_rec.just_condition_en_4        -- �������(�~)
        ,in_wholesale_adj_margin_en_4  =>  g_actual_trns_rec.wholesale_adj_margin_en_4  -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
        ,in_condition_unit_price_en_5  =>  g_actual_trns_rec.condition_unit_price_en_5  -- �����P���T(�~)
        ,in_deduction_unit_price_en_6  =>  g_actual_trns_rec.deduction_unit_price_en_6  -- �T���P��(�~)
        ,iv_tax_code_mst               =>  g_actual_trns_rec.tax_code_con               -- �ŃR�[�h(MST)
        ,in_tax_rate_mst               =>  g_actual_trns_rec.tax_rate_con               -- �ŗ�(MST)
        ,ov_deduction_uom_code         =>  gv_dedu_uom_code                             -- �T���P��
        ,on_deduction_unit_price       =>  gn_dedu_unit_price                           -- �T���P��
        ,on_deduction_quantity         =>  gn_dedu_quantity                             -- �T������
        ,on_deduction_amount           =>  gn_dedu_amount                               -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
        ,on_compensation               =>  gn_compensation                              -- ��U
        ,on_margin                     =>  gn_margin                                    -- �≮�}�[�W��
        ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                  -- �g��
        ,on_margin_reduction           =>  gn_margin_reduction                          -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
        ,on_deduction_tax_amount       =>  gn_dedu_tax_amount                           -- �T���Ŋz
        ,ov_tax_code                   =>  gv_tax_code                                  -- �ŃR�[�h
        ,on_tax_rate                   =>  gn_tax_rate                                  -- �ŗ�
      );
--
      -- ���ʊ֐��ɂăG���[����������
      IF  lv_retcode  !=  cv_status_normal  THEN
--
        -- ��ƃR�[�h��NULL�ȊO�̏ꍇ
        IF  g_actual_trns_rec.corp_code IS NOT NULL  THEN
--
          -- �{���S�����_(���)���擾
          SELECT MAX(ffv.attribute2)
          INTO   lv_base_code
          FROM   fnd_flex_values     ffv
                ,fnd_flex_value_sets ffvs
          WHERE  ffvs.flex_value_set_name  = cv_business_type
          AND    ffv.flex_value_set_id     = ffvs.flex_value_set_id
          AND    ffv.flex_value            = g_actual_trns_rec.corp_code
          ;
--
        -- �T���p�`�F�[���R�[�h��NULL�ȊO�̏ꍇ
        ELSIF g_actual_trns_rec.deduction_chain_code IS  NOT NULL  THEN
          -- �{���S�����_(�`�F�[���X)���擾
          lv_base_code  :=  g_actual_trns_rec.attribute3;
--
        -- �ڋq�R�[�h(����)��NULL�ȊO�̏ꍇ
        ELSIF g_actual_trns_rec.customer_code IS  NOT NULL  THEN
          -- ���㋒�_(�ڋq)���擾
          lv_base_code  :=  g_actual_trns_rec.sale_base_code;
        END IF;
--
        ov_retcode := cv_status_warn;
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_xxcok_short_name
                      , cv_msg_cal_error
                      , cv_tkn_source_line_id
                      , g_actual_trns_rec.selling_trns_info_id
                      , cv_tkn_item_code
                      , g_actual_trns_rec.item_code
                      , cv_tkn_sales_uom_code
                      , g_actual_trns_rec.unit_type
                      , cv_tkn_condition_no
                      , g_actual_trns_rec.condition_no
                      , cv_tkn_base_code
                      , lv_base_code
                      , cv_tkn_errmsg
                      , lv_errmsg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
      END IF;
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END calculation_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : A-6.�̔��T���f�[�^�o�^
   ***********************************************************************************/
  PROCEDURE insert_data( iv_syori_type  IN     VARCHAR2    -- �����敪
                        ,in_main_idx    IN     NUMBER      -- ���C���C���f�b�N�X
                        ,ov_errbuf      OUT    VARCHAR2    -- �G���[�E���b�Z�[�W           -- # �Œ� #
                        ,ov_retcode     OUT    VARCHAR2    -- ���^�[���E�R�[�h             -- # �Œ� #
                        ,ov_errmsg      OUT    VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
                        )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
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
    -- �̔����т̏ꍇ
    IF ( iv_syori_type = cv_s_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                    -- �̔��T��ID
          ,base_code_from                        -- �U�֌����_
          ,base_code_to                          -- �U�֐拒�_
          ,customer_code_from                    -- �U�֌��ڋq�R�[�h
          ,customer_code_to                      -- �U�֐�ڋq�R�[�h
          ,deduction_chain_code                  -- �T���p�`�F�[���R�[�h
          ,corp_code                             -- ��ƃR�[�h
          ,record_date                           -- �v���
          ,source_category                       -- �쐬���敪
          ,source_line_id                        -- �쐬������ID
          ,condition_id                          -- �T������ID
          ,condition_no                          -- �T���ԍ�
          ,condition_line_id                     -- �T���ڍ�ID
          ,data_type                             -- �f�[�^���
          ,status                                -- �X�e�[�^�X
          ,item_code                             -- �i�ڃR�[�h
          ,sales_uom_code                        -- �̔��P��
          ,sales_unit_price                      -- �̔��P��
          ,sales_quantity                        -- �̔�����
          ,sale_pure_amount                      -- ����{�̋��z
          ,sale_tax_amount                       -- �������Ŋz
          ,deduction_uom_code                    -- �T���P��
          ,deduction_unit_price                  -- �T���P��
          ,deduction_quantity                    -- �T������
          ,deduction_amount                      -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                          -- ��U
          ,margin                                -- �≮�}�[�W��
          ,sales_promotion_expenses              -- �g��
          ,margin_reduction                      -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                              -- �ŃR�[�h
          ,tax_rate                              -- �ŗ�
          ,recon_tax_code                        -- �������ŃR�[�h
          ,recon_tax_rate                        -- �������ŗ�
          ,deduction_tax_amount                  -- �T���Ŋz
          ,remarks                               -- ���l
          ,application_no                        -- �\����No.
          ,gl_if_flag                            -- GL�A�g�t���O
          ,gl_base_code                          -- GL�v�㋒�_
          ,gl_date                               -- GL�L����
          ,recovery_date                         -- ���J�o���f�[�^�ǉ������t
          ,recovery_add_request_id               -- ���J�o���f�[�^�ǉ����v��ID
          ,recovery_del_date                     -- ���J�o���f�[�^�폜�����t
          ,recovery_del_request_id               -- ���J�o���f�[�^�폜���v��ID
          ,cancel_flag                           -- ����t���O
          ,cancel_base_code                      -- ������v�㋒�_
          ,cancel_gl_date                        -- ���GL�L����
          ,cancel_user                           -- ������{���[�U
          ,recon_base_code                       -- �������v�㋒�_
          ,recon_slip_num                        -- �x���`�[�ԍ�
          ,carry_payment_slip_num                -- �J�z���x���`�[�ԍ�
          ,report_decision_flag                  -- ����m��t���O
          ,gl_interface_id                       -- GL�A�gID
          ,cancel_gl_interface_id                -- ���GL�A�gID
          ,created_by                            -- �쐬��
          ,creation_date                         -- �쐬��
          ,last_updated_by                       -- �ŏI�X�V��
          ,last_update_date                      -- �ŏI�X�V��
          ,last_update_login                     -- �ŏI�X�V���O�C��
          ,request_id                            -- �v��ID
          ,program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                            -- �R���J�����g�E�v���O����ID
          ,program_update_date                   -- �v���O�����X�V��
        )VALUES(
           xxcok_sales_deduction_s01.nextval     -- �̔��T��ID
          ,g_sales_exp_rec.sales_base_code       -- �U�֌����_
          ,g_sales_exp_rec.sales_base_code       -- �U�֐拒�_
          ,g_sales_exp_rec.ship_to_customer_code -- �U�֌��ڋq�R�[�h
          ,g_sales_exp_rec.ship_to_customer_code -- �U�֐�ڋq�R�[�h
          ,NULL                                  -- �`�F�[���X�R�[�h
          ,NULL                                  -- ��ƃR�[�h
          ,g_sales_exp_rec.delivery_date         -- �����
          ,cv_s_flag                             -- �쐬���敪
          ,g_sales_exp_rec.sales_exp_line_id     -- �쐬������ID
          ,g_sales_exp_rec.condition_id          -- �T������ID
          ,g_sales_exp_rec.condition_no          -- �T���ԍ�
          ,g_sales_exp_rec.condition_line_id     -- �T���ڍ�ID
          ,g_sales_exp_rec.data_type             -- �f�[�^���
          ,cv_n_flag                             -- �X�e�[�^�X
          ,g_sales_exp_rec.div_item_code         -- �i�ڃR�[�h
          ,g_sales_exp_rec.dlv_uom_code          -- �̔��P��
          ,g_sales_exp_rec.dlv_unit_price        -- �̔��P��
          ,g_sales_exp_rec.dlv_qty               -- �̔�����
          ,g_sales_exp_rec.pure_amount           -- ����{�̋��z
          ,g_sales_exp_rec.tax_amount            -- �������Ŋz
          ,gv_dedu_uom_code                      -- �T���P��
          ,gn_dedu_unit_price                    -- �T���P��
          ,gn_dedu_quantity                      -- �T������
          ,gn_dedu_amount                        -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- ��U
          ,gn_margin                             -- �≮�}�[�W��
          ,gn_sales_promotion_expenses           -- �g��
          ,gn_margin_reduction                   -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                           -- �ŃR�[�h
          ,gn_tax_rate                           -- �ŗ�
          ,NULL                                  -- �������ŃR�[�h
          ,NULL                                  -- �������ŗ�
          ,gn_dedu_tax_amount                    -- �T���Ŋz
          ,NULL                                  -- ���l
          ,NULL                                  -- �\����No.
          ,cv_n_flag                             -- GL�A�g�t���O
          ,NULL                                  -- GL�v�㋒�_
          ,NULL                                  -- GL�L����
          ,gd_proc_date                          -- ���J�o���f�[�^�ǉ������t
          ,cn_request_id                         -- ���J�o���f�[�^�ǉ����v��ID
          ,NULL                                  -- ���J�o���f�[�^�폜�����t
          ,NULL                                  -- ���J�o���f�[�^�폜���v��ID
          ,cv_n_flag                             -- ����t���O
          ,NULL                                  -- ������v�㋒�_
          ,NULL                                  -- ���GL�L����
          ,NULL                                  -- ������{���[�U
          ,NULL                                  -- �������v�㋒�_
          ,NULL                                  -- �x���`�[�ԍ�
          ,NULL                                  -- �J�z���x���`�[�ԍ�
          ,NULL                                  -- ����m��t���O
          ,NULL                                  -- GL�A�gID
          ,NULL                                  -- ���GL�A�gID
          ,cn_created_by                         -- �쐬��
          ,cd_creation_date                      -- �쐬��
          ,cn_last_updated_by                    -- �ŏI�X�V��
          ,cd_last_update_date                   -- �ŏI�X�V��
          ,cn_last_update_login                  -- �ŏI�X�V���O�C��
          ,cn_request_id                         -- �v��ID
          ,cn_program_application_id             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                         -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                -- �v���O�����X�V��
      );
--
    -- ���ѐU��(EDI)�̏ꍇ
    ELSIF ( iv_syori_type = cv_t_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- �̔��T��ID
          ,base_code_from                                           -- �U�֌����_
          ,base_code_to                                             -- �U�֐拒�_
          ,customer_code_from                                       -- �U�֌��ڋq�R�[�h
          ,customer_code_to                                         -- �U�֐�ڋq�R�[�h
          ,deduction_chain_code                                     -- �T���p�`�F�[���R�[�h
          ,corp_code                                                -- ��ƃR�[�h
          ,record_date                                              -- �v���
          ,source_category                                          -- �쐬���敪
          ,source_line_id                                           -- �쐬������ID
          ,condition_id                                             -- �T������ID
          ,condition_no                                             -- �T���ԍ�
          ,condition_line_id                                        -- �T���ڍ�ID
          ,data_type                                                -- �f�[�^���
          ,status                                                   -- �X�e�[�^�X
          ,item_code                                                -- �i�ڃR�[�h
          ,sales_uom_code                                           -- �̔��P��
          ,sales_unit_price                                         -- �̔��P��
          ,sales_quantity                                           -- �̔�����
          ,sale_pure_amount                                         -- ����{�̋��z
          ,sale_tax_amount                                          -- �������Ŋz
          ,deduction_uom_code                                       -- �T���P��
          ,deduction_unit_price                                     -- �T���P��
          ,deduction_quantity                                       -- �T������
          ,deduction_amount                                         -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- ��U
          ,margin                                                   -- �≮�}�[�W��
          ,sales_promotion_expenses                                 -- �g��
          ,margin_reduction                                         -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- �ŃR�[�h
          ,tax_rate                                                 -- �ŗ�
          ,recon_tax_code                                           -- �������ŃR�[�h
          ,recon_tax_rate                                           -- �������ŗ�
          ,deduction_tax_amount                                     -- �T���Ŋz
          ,remarks                                                  -- ���l
          ,application_no                                           -- �\����No.
          ,gl_if_flag                                               -- GL�A�g�t���O
          ,gl_base_code                                             -- GL�v�㋒�_
          ,gl_date                                                  -- GL�L����
          ,recovery_date                                            -- ���J�o���f�[�^�ǉ������t
          ,recovery_add_request_id                                  -- ���J�o���f�[�^�ǉ����v��ID
          ,recovery_del_date                                        -- ���J�o���f�[�^�폜�����t
          ,recovery_del_request_id                                  -- ���J�o���f�[�^�폜���v��ID
          ,cancel_flag                                              -- ����t���O
          ,cancel_base_code                                         -- ������v�㋒�_
          ,cancel_gl_date                                           -- ���GL�L����
          ,cancel_user                                              -- ������{���[�U
          ,recon_base_code                                          -- �������v�㋒�_
          ,recon_slip_num                                           -- �x���`�[�ԍ�
          ,carry_payment_slip_num                                   -- �J�z���x���`�[�ԍ�
          ,report_decision_flag                                     -- ����m��t���O
          ,gl_interface_id                                          -- GL�A�gID
          ,cancel_gl_interface_id                                   -- ���GL�A�gID
          ,created_by                                               -- �쐬��
          ,creation_date                                            -- �쐬��
          ,last_updated_by                                          -- �ŏI�X�V��
          ,last_update_date                                         -- �ŏI�X�V��
          ,last_update_login                                        -- �ŏI�X�V���O�C��
          ,request_id                                               -- �v��ID
          ,program_application_id                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                                               -- �R���J�����g�E�v���O����ID
          ,program_update_date                                      -- �v���O�����X�V��
        )VALUES(
           xxcok_sales_deduction_s01.nextval                        -- �̔��T��ID
          ,g_selling_trns_rec.delivery_base_code                    -- �U�֌����_
          ,g_selling_trns_rec.base_code                             -- �U�֐拒�_
          ,g_selling_trns_rec.selling_from_cust_code                -- �U�֌��ڋq�R�[�h
          ,g_selling_trns_rec.cust_code                             -- �U�֐�ڋq�R�[�h
          ,NULL                                                     -- �`�F�[���X�R�[�h
          ,NULL                                                     -- ��ƃR�[�h
          ,g_selling_trns_rec.selling_date                          -- �����
          ,cv_t_flag                                                -- �쐬���敪
          ,g_selling_trns_rec.selling_trns_info_id                  -- �쐬������ID
          ,g_selling_trns_rec.condition_id                          -- �T������ID
          ,g_selling_trns_rec.condition_no                          -- �T���ԍ�
          ,g_selling_trns_rec.condition_line_id                     -- �T���ڍ�ID
          ,g_selling_trns_rec.data_type                             -- �f�[�^���
          ,cv_n_flag                                                -- �X�e�[�^�X
          ,g_selling_trns_rec.item_code                             -- �i�ڃR�[�h
          ,g_selling_trns_rec.unit_type                             -- �̔��P��
          ,g_selling_trns_rec.delivery_unit_price                   -- �̔��P��
          ,g_selling_trns_rec.qty                                   -- �̔�����
          ,g_selling_trns_rec.selling_amt_no_tax                    -- ����{�̋��z
          ,g_selling_trns_rec.tax_amount                            -- �������Ŋz
          ,gv_dedu_uom_code                                         -- �T���P��
          ,gn_dedu_unit_price                                       -- �T���P��
          ,gn_dedu_quantity                                         -- �T������
          ,gn_dedu_amount                                           -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- ��U
          ,gn_margin                             -- �≮�}�[�W��
          ,gn_sales_promotion_expenses           -- �g��
          ,gn_margin_reduction                   -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                                              -- �ŃR�[�h
          ,gn_tax_rate                                              -- �ŗ�
          ,NULL                                                     -- �������ŃR�[�h
          ,NULL                                                     -- �������ŗ�
          ,gn_dedu_tax_amount                                       -- �T���Ŋz
          ,NULL                                                     -- ���l
          ,NULL                                                     -- �\����No.
          ,cv_n_flag                                                -- GL�A�g�t���O
          ,NULL                                                     -- GL�v�㋒�_
          ,NULL                                                     -- GL�L����
          ,gd_proc_date                                             -- ���J�o���f�[�^�ǉ������t
          ,cn_request_id                                            -- ���J�o���f�[�^�ǉ����v��ID
          ,NULL                                                     -- ���J�o���f�[�^�폜�����t
          ,NULL                                                     -- ���J�o���f�[�^�폜���v��ID
          ,cv_n_flag                                                -- ����t���O
          ,NULL                                                     -- ������v�㋒�_
          ,NULL                                                     -- ���GL�L����
          ,NULL                                                     -- ������{���[�U
          ,NULL                                                     -- �������v�㋒�_
          ,NULL                                                     -- �x���`�[�ԍ�
          ,NULL                                                     -- �J�z���x���`�[�ԍ�
          ,cv_deci_flag                                             -- ����m��t���O
          ,NULL                                                     -- GL�A�gID
          ,NULL                                                     -- ���GL�A�gID
          ,cn_created_by                                            -- �쐬��
          ,cd_creation_date                                         -- �쐬��
          ,cn_last_updated_by                                       -- �ŏI�X�V��
          ,cd_last_update_date                                      -- �ŏI�X�V��
          ,cn_last_update_login                                     -- �ŏI�X�V���O�C��
          ,cn_request_id                                            -- �v��ID
          ,cn_program_application_id                                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                            -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                   -- �v���O�����X�V��
      );
--
    -- ���ѐU��(�U�֊���)�̏ꍇ
    ELSIF ( iv_syori_type = cv_v_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- �̔��T��ID
          ,base_code_from                                           -- �U�֌����_
          ,base_code_to                                             -- �U�֐拒�_
          ,customer_code_from                                       -- �U�֌��ڋq�R�[�h
          ,customer_code_to                                         -- �U�֐�ڋq�R�[�h
          ,deduction_chain_code                                     -- �T���p�`�F�[���R�[�h
          ,corp_code                                                -- ��ƃR�[�h
          ,record_date                                              -- �v���
          ,source_category                                          -- �쐬���敪
          ,source_line_id                                           -- �쐬������ID
          ,condition_id                                             -- �T������ID
          ,condition_no                                             -- �T���ԍ�
          ,condition_line_id                                        -- �T���ڍ�ID
          ,data_type                                                -- �f�[�^���
          ,status                                                   -- �X�e�[�^�X
          ,item_code                                                -- �i�ڃR�[�h
          ,sales_uom_code                                           -- �̔��P��
          ,sales_unit_price                                         -- �̔��P��
          ,sales_quantity                                           -- �̔�����
          ,sale_pure_amount                                         -- ����{�̋��z
          ,sale_tax_amount                                          -- �������Ŋz
          ,deduction_uom_code                                       -- �T���P��
          ,deduction_unit_price                                     -- �T���P��
          ,deduction_quantity                                       -- �T������
          ,deduction_amount                                         -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- ��U
          ,margin                                                   -- �≮�}�[�W��
          ,sales_promotion_expenses                                 -- �g��
          ,margin_reduction                                         -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- �ŃR�[�h
          ,tax_rate                                                 -- �ŗ�
          ,recon_tax_code                                           -- �������ŃR�[�h
          ,recon_tax_rate                                           -- �������ŗ�
          ,deduction_tax_amount                                     -- �T���Ŋz
          ,remarks                                                  -- ���l
          ,application_no                                           -- �\����No.
          ,gl_if_flag                                               -- GL�A�g�t���O
          ,gl_base_code                                             -- GL�v�㋒�_
          ,gl_date                                                  -- GL�L����
          ,recovery_date                                            -- ���J�o���f�[�^�ǉ������t
          ,recovery_add_request_id                                  -- ���J�o���f�[�^�ǉ����v��ID
          ,recovery_del_date                                        -- ���J�o���f�[�^�폜�����t
          ,recovery_del_request_id                                  -- ���J�o���f�[�^�폜���v��ID
          ,cancel_flag                                              -- ����t���O
          ,cancel_base_code                                         -- ������v�㋒�_
          ,cancel_gl_date                                           -- ���GL�L����
          ,cancel_user                                              -- ������{���[�U
          ,recon_base_code                                          -- �������v�㋒�_
          ,recon_slip_num                                           -- �x���`�[�ԍ�
          ,carry_payment_slip_num                                   -- �J�z���x���`�[�ԍ�
          ,report_decision_flag                                     -- ����m��t���O
          ,gl_interface_id                                          -- GL�A�gID
          ,cancel_gl_interface_id                                   -- ���GL�A�gID
          ,created_by                                               -- �쐬��
          ,creation_date                                            -- �쐬��
          ,last_updated_by                                          -- �ŏI�X�V��
          ,last_update_date                                         -- �ŏI�X�V��
          ,last_update_login                                        -- �ŏI�X�V���O�C��
          ,request_id                                               -- �v��ID
          ,program_application_id                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                                               -- �R���J�����g�E�v���O����ID
          ,program_update_date                                      -- �v���O�����X�V��
        )VALUES(
           xxcok_sales_deduction_s01.nextval                        -- �̔��T��ID
          ,g_actual_trns_rec.delivery_base_code                     -- �U�֌����_
          ,g_actual_trns_rec.base_code                              -- �U�֐拒�_
          ,g_actual_trns_rec.selling_from_cust_code                 -- �U�֌��ڋq�R�[�h
          ,g_actual_trns_rec.cust_code                              -- �U�֐�ڋq�R�[�h
          ,NULL                                                     -- �`�F�[���X�R�[�h
          ,NULL                                                     -- ��ƃR�[�h
          ,g_actual_trns_rec.selling_date                           -- �����
          ,cv_v_flag                                                -- �쐬���敪
          ,g_actual_trns_rec.selling_trns_info_id                   -- �쐬������ID
          ,g_actual_trns_rec.condition_id                           -- �T������ID
          ,g_actual_trns_rec.condition_no                           -- �T���ԍ�
          ,g_actual_trns_rec.condition_line_id                      -- �T���ڍ�ID
          ,g_actual_trns_rec.data_type                              -- �f�[�^���
          ,cv_n_flag                                                -- �X�e�[�^�X
          ,g_actual_trns_rec.item_code                              -- �i�ڃR�[�h
          ,g_actual_trns_rec.unit_type                              -- �̔��P��
          ,g_actual_trns_rec.delivery_unit_price                    -- �̔��P��
          ,g_actual_trns_rec.qty                                    -- �̔�����
          ,g_actual_trns_rec.selling_amt_no_tax                     -- ����{�̋��z
          ,g_actual_trns_rec.tax_amount                             -- �������Ŋz
          ,gv_dedu_uom_code                                         -- �T���P��
          ,gn_dedu_unit_price                                       -- �T���P��
          ,gn_dedu_quantity                                         -- �T������
          ,gn_dedu_amount                                           -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,gn_compensation                       -- ��U
          ,gn_margin                             -- �≮�}�[�W��
          ,gn_sales_promotion_expenses           -- �g��
          ,gn_margin_reduction                   -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,gv_tax_code                                              -- �ŃR�[�h
          ,gn_tax_rate                                              -- �ŗ�
          ,NULL                                                     -- �������ŃR�[�h
          ,NULL                                                     -- �������ŗ�
          ,gn_dedu_tax_amount                                       -- �T���Ŋz
          ,NULL                                                     -- ���l
          ,NULL                                                     -- �\����No.
          ,cv_n_flag                                                -- GL�A�g�t���O
          ,NULL                                                     -- GL�v�㋒�_
          ,NULL                                                     -- GL�L����
          ,gd_proc_date                                             -- ���J�o���f�[�^�ǉ������t
          ,cn_request_id                                            -- ���J�o���f�[�^�ǉ����v��ID
          ,NULL                                                     -- ���J�o���f�[�^�폜�����t
          ,NULL                                                     -- ���J�o���f�[�^�폜���v��ID
          ,cv_n_flag                                                -- ����t���O
          ,NULL                                                     -- ������v�㋒�_
          ,NULL                                                     -- ���GL�L����
          ,NULL                                                     -- ������{���[�U
          ,NULL                                                     -- �������v�㋒�_
          ,NULL                                                     -- �x���`�[�ԍ�
          ,NULL                                                     -- �J�z���x���`�[�ԍ�
          ,cv_deci_flag                                             -- ����m��t���O
          ,NULL                                                     -- GL�A�gID
          ,NULL                                                     -- ���GL�A�gID
          ,cn_created_by                                            -- �쐬��
          ,cd_creation_date                                         -- �쐬��
          ,cn_last_updated_by                                       -- �ŏI�X�V��
          ,cd_last_update_date                                      -- �ŏI�X�V��
          ,cn_last_update_login                                     -- �ŏI�X�V���O�C��
          ,cn_request_id                                            -- �v��ID
          ,cn_program_application_id                                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                            -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                   -- �v���O�����X�V��
      );
--
    -- ��z�T���̏ꍇ
    ELSIF ( iv_syori_type = cv_f_flag ) THEN
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                       -- �̔��T��ID
          ,base_code_from                                           -- �U�֌����_
          ,base_code_to                                             -- �U�֐拒�_
          ,customer_code_from                                       -- �U�֌��ڋq�R�[�h
          ,customer_code_to                                         -- �U�֐�ڋq�R�[�h
          ,deduction_chain_code                                     -- �T���p�`�F�[���R�[�h
          ,corp_code                                                -- ��ƃR�[�h
          ,record_date                                              -- �v���
          ,source_category                                          -- �쐬���敪
          ,source_line_id                                           -- �쐬������ID
          ,condition_id                                             -- �T������ID
          ,condition_no                                             -- �T���ԍ�
          ,condition_line_id                                        -- �T���ڍ�ID
          ,data_type                                                -- �f�[�^���
          ,status                                                   -- �X�e�[�^�X
          ,item_code                                                -- �i�ڃR�[�h
          ,sales_uom_code                                           -- �̔��P��
          ,sales_unit_price                                         -- �̔��P��
          ,sales_quantity                                           -- �̔�����
          ,sale_pure_amount                                         -- ����{�̋��z
          ,sale_tax_amount                                          -- �������Ŋz
          ,deduction_uom_code                                       -- �T���P��
          ,deduction_unit_price                                     -- �T���P��
          ,deduction_quantity                                       -- �T������
          ,deduction_amount                                         -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,compensation                                             -- ��U
          ,margin                                                   -- �≮�}�[�W��
          ,sales_promotion_expenses                                 -- �g��
          ,margin_reduction                                         -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,tax_code                                                 -- �ŃR�[�h
          ,tax_rate                                                 -- �ŗ�
          ,recon_tax_code                                           -- �������ŃR�[�h
          ,recon_tax_rate                                           -- �������ŗ�
          ,deduction_tax_amount                                     -- �T���Ŋz
          ,remarks                                                  -- ���l
          ,application_no                                           -- �\����No.
          ,gl_if_flag                                               -- GL�A�g�t���O
          ,gl_base_code                                             -- GL�v�㋒�_
          ,gl_date                                                  -- GL�L����
          ,recovery_date                                            -- ���J�o���f�[�^�ǉ������t
          ,recovery_add_request_id                                  -- ���J�o���f�[�^�ǉ����v��ID
          ,recovery_del_date                                        -- ���J�o���f�[�^�폜�����t
          ,recovery_del_request_id                                  -- ���J�o���f�[�^�폜���v��ID
          ,cancel_flag                                              -- ����t���O
          ,cancel_base_code                                         -- ������v�㋒�_
          ,cancel_gl_date                                           -- ���GL�L����
          ,cancel_user                                              -- ������{���[�U
          ,recon_base_code                                          -- �������v�㋒�_
          ,recon_slip_num                                           -- �x���`�[�ԍ�
          ,carry_payment_slip_num                                   -- �J�z���x���`�[�ԍ�
          ,report_decision_flag                                     -- ����m��t���O
          ,gl_interface_id                                          -- GL�A�gID
          ,cancel_gl_interface_id                                   -- ���GL�A�gID
          ,created_by                                               -- �쐬��
          ,creation_date                                            -- �쐬��
          ,last_updated_by                                          -- �ŏI�X�V��
          ,last_update_date                                         -- �ŏI�X�V��
          ,last_update_login                                        -- �ŏI�X�V���O�C��
          ,request_id                                               -- �v��ID
          ,program_application_id                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                                               -- �R���J�����g�E�v���O����ID
          ,program_update_date                                      -- �v���O�����X�V��
        )VALUES(
           xxcok_sales_deduction_s01.nextval                           -- �̔��T��ID
-- 2021/03/22 Ver1.2 MOD Start
--          ,gt_condition_work_tbl(in_main_idx).accounting_base          -- �U�֌����_
          ,gt_condition_work_tbl(in_main_idx).sale_base_code           -- �U�֌����_
--          ,gt_condition_work_tbl(in_main_idx).accounting_base          -- �U�֐拒�_
          ,gt_condition_work_tbl(in_main_idx).sale_base_code           -- �U�֌����_
--          ,gt_condition_work_tbl(in_main_idx).customer_code            -- �U�֌��ڋq�R�[�h
          ,gt_condition_work_tbl(in_main_idx).accounting_customer_code -- �U�֌��ڋq�R�[�h
--          ,gt_condition_work_tbl(in_main_idx).customer_code            -- �U�֐�ڋq�R�[�h
          ,gt_condition_work_tbl(in_main_idx).accounting_customer_code -- �U�֐�ڋq�R�[�h
--          ,gt_condition_work_tbl(in_main_idx).deduction_chain_code     -- �T���p�`�F�[���R�[�h
          ,NULL                                                        -- �T���p�`�F�[���R�[�h
--          ,gt_condition_work_tbl(in_main_idx).corp_code                -- ��ƃR�[�h
          ,NULL                                                        -- ��ƃR�[�h
-- 2021/03/22 Ver1.2 MOD End
          ,gd_work_date                                                -- �v���
          ,cv_f_flag                                                   -- �쐬���敪
          ,NULL                                                        -- �쐬������ID
          ,gt_condition_work_tbl(in_main_idx).condition_id             -- �T������ID
          ,gt_condition_work_tbl(in_main_idx).condition_no             -- �T���ԍ�
          ,gt_condition_work_tbl(in_main_idx).condition_line_id        -- �T���ڍ�ID
          ,gt_condition_work_tbl(in_main_idx).data_type                -- �f�[�^���
          ,cv_n_flag                                                   -- �X�e�[�^�X
          ,NULL                                                        -- �i�ڃR�[�h
          ,NULL                                                        -- �̔��P��
          ,NULL                                                        -- �̔��P��
          ,NULL                                                        -- �̔�����
          ,NULL                                                        -- ����{�̋��z
          ,NULL                                                        -- �������Ŋz
          ,NULL                                                        -- �T���P��
          ,NULL                                                        -- �T���P��
          ,NULL                                                        -- �T������
          ,gt_condition_work_tbl(in_main_idx).deduction_amount         -- �T���z
-- 2020/12/03 Ver1.1 ADD Start
          ,NULL                                                        -- ��U
          ,NULL                                                        -- �≮�}�[�W��
          ,NULL                                                        -- �g��
          ,NULL                                                        -- �≮�}�[�W�����z
-- 2020/12/03 Ver1.1 ADD End
          ,gt_condition_work_tbl(in_main_idx).tax_code                 -- �ŃR�[�h
          ,NULL                                                        -- �ŗ�
          ,NULL                                                        -- �������ŃR�[�h
          ,NULL                                                        -- �������ŗ�
          ,gt_condition_work_tbl(in_main_idx).deduction_tax_amount     -- �T���Ŋz
          ,NULL                                                        -- ���l
          ,NULL                                                        -- �\����No.
          ,cv_n_flag                                                   -- GL�A�g�t���O
          ,NULL                                                        -- GL�v�㋒�_
          ,NULL                                                        -- GL�L����
          ,gd_proc_date                                                -- ���J�o���f�[�^�ǉ������t
          ,cn_request_id                                               -- ���J�o���f�[�^�ǉ����v��ID
          ,NULL                                                        -- ���J�o���f�[�^�폜�����t
          ,NULL                                                        -- ���J�o���f�[�^�폜���v��ID
          ,cv_n_flag                                                   -- ����t���O
          ,NULL                                                        -- ������v�㋒�_
          ,NULL                                                        -- ���GL�L����
          ,NULL                                                        -- ������{���[�U
          ,NULL                                                        -- �������v�㋒�_
          ,NULL                                                        -- �x���`�[�ԍ�
          ,NULL                                                        -- �J�z���x���`�[�ԍ�
          ,NULL                                                        -- ����m��t���O
          ,NULL                                                        -- GL�A�gID
          ,NULL                                                        -- ���GL�A�gID
          ,cn_created_by                                               -- �쐬��
          ,cd_creation_date                                            -- �쐬��
          ,cn_last_updated_by                                          -- �ŏI�X�V��
          ,cd_last_update_date                                         -- �ŏI�X�V��
          ,cn_last_update_login                                        -- �ŏI�X�V���O�C��
          ,cn_request_id                                               -- �v��ID
          ,cn_program_application_id                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                               -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                      -- �v���O�����X�V��
      );
--
    END IF;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-4.�T���f�[�^���o
   ***********************************************************************************/
--  PROCEDURE get_data( iv_recovery_h_flag  IN     VARCHAR2  -- �T���w�b�_�[���J�o���Ώۃt���O
--                    , iv_recovery_l_flag  IN     VARCHAR2  -- �T�����׃��J�o���Ώۃt���O
  PROCEDURE get_data( ov_errbuf           OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           -- # �Œ� #
                    , ov_retcode          OUT    VARCHAR2  -- ���^�[���E�R�[�h             -- # �Œ� #
                    , ov_errmsg           OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
                        )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_condition_line_id       NUMBER DEFAULT 0;                               -- �T������ID���݊m�F�p
    ln_condition_line_id_1     NUMBER DEFAULT 0;                               -- �T������ID���݊m�F�p
    ln_condition_line_id_2     NUMBER DEFAULT 0;                               -- �T������ID���݊m�F�p
    lv_recon_slip_num          VARCHAR2(30);                                   -- �`�[�ԍ����݊m�F�p
    lv_out_msg                 VARCHAR2(1000)      DEFAULT NULL;               -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode                 BOOLEAN             DEFAULT NULL;               -- ���b�Z�[�W�o�͊֐��̖߂�l
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
  BEGIN
--
--#########################  �Œ�X�e�[�^�X�������� START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  �Œ蕔 END  ##################################
--
    -- �̔����я��J�[�\���I�[�v��
    OPEN g_sales_exp_cur;       --�v��ID
--
    LOOP
      -- �f�[�^�擾
      FETCH g_sales_exp_cur INTO g_sales_exp_rec;
      EXIT WHEN g_sales_exp_cur%NOTFOUND;
--
      -- �T������ID���݊m�F�p�A�`�[�ԍ����݊m�F������
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- �T���ڍ�ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- �x���`�[�ԍ�
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
        WHERE  xsd.condition_id       = g_sales_exp_rec.condition_id       -- �T������ID
        AND    xsd.source_line_id     = g_sales_exp_rec.sales_exp_line_id  -- �쐬������ID
        AND    xsd.source_category    = cv_s_flag                          -- �쐬���敪�F�̔�����
        AND    xsd.status             = cv_n_flag                          -- �X�e�[�^�X�F�V�K
        AND    ROWNUM                 = 1
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- �f�[�^���擾�ł��Ȃ������ꍇ�A�V�K�T��
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type        => cv_s_flag   -- �����敪
                        ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type    => cv_s_flag   -- �����敪
                     ,in_main_idx      => NULL        -- ���C���C���f�b�N�X
                     ,ov_errbuf        => lv_errbuf   -- �G���[�E���b�Z�[�W
                     ,ov_retcode       => lv_retcode  -- ���^�[���E�R�[�h
                     ,ov_errmsg        => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt      :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode        := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- �x���`�[�ԍ����ݒ肳��Ă���ꍇ�i�x���ρj
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- �x���`�[�ԍ�
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
--
        -- �T���f�[�^�o�^�x���σX�L�b�v����
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- �x���`�[�ԍ������ݒ�ł���ꍇ�i�����j
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- �T���w�b�_�̃��J�o���Ώۃt���O���uU:�X�V�v�A�܂���
        -- �T�����ׂ́u���J�o���Ώۃt���O���uU:�X�V�v�̏ꍇ
        IF    ((g_sales_exp_rec.header_recovery_flag = cv_u_flag)
          OR   (g_sales_exp_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- �T������ID���݊m�F�p������
          ln_condition_line_id_1 := 0;
--
          -- �����̑��݊m�F
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- �T���ڍ�ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
            WHERE  xsd.source_line_id     = g_sales_exp_rec.sales_exp_line_id  -- �쐬������ID
            AND    xsd.condition_line_id  = g_sales_exp_rec.condition_line_id  -- �T���ڍ�ID
            AND    xsd.source_category    = cv_s_flag                          -- �쐬���敪�F�̔�����
            AND    xsd.status             = cv_n_flag                          -- �X�e�[�^�X�F�V�K
            AND    xsd.recon_slip_num    IS NULL                               -- �x���`�[�ԍ�
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- �����̍T�������݂����ꍇ
          IF (ln_condition_line_id_1 != 0) THEN
--
            -- �T���ڍ�ID���O�����ƕς���Ă����ꍇ�A�폜���{
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
--
              -- ============================================================
              -- A-3.�̔��T����������̌Ăяo��
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- �T���ڍ�ID
                                      ,iv_syori_type        => cv_s_flag               -- �����敪
                                      ,ov_errbuf            => lv_errbuf               -- �G���[�E���b�Z�[�W
                                      ,ov_retcode           => lv_retcode              -- ���^�[���E�R�[�h
                                      ,ov_errmsg            => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type        => cv_s_flag   -- �����敪
                        ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type    => cv_s_flag   -- �����敪
                     ,in_main_idx      => NULL        -- ���C���C���f�b�N�X
                     ,ov_errbuf        => lv_errbuf   -- �G���[�E���b�Z�[�W
                     ,ov_retcode       => lv_retcode  -- ���^�[���E�R�[�h
                     ,ov_errmsg        => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt   :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode        := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- �J�[�\���N���[�Y
    CLOSE g_sales_exp_cur;
--
    ln_condition_line_id_2 := 0;
--
    -- ���ѐU�֏��(EDI)�J�[�\���I�[�v��
    OPEN g_selling_trns_cur;
--
    LOOP
      -- �f�[�^�擾
      FETCH g_selling_trns_cur INTO g_selling_trns_rec;
      EXIT WHEN g_selling_trns_cur%NOTFOUND;
--
      -- �T������ID���݊m�F�p�A�`�[�ԍ����݊m�F������
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      -- �̔��T���f�[�^���݊m�F
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- �T���ڍ�ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- �x���`�[�ԍ�
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                            -- �̔��T�����
        WHERE  xsd.condition_id       = g_selling_trns_rec.condition_id          -- �T������ID
        AND    xsd.source_line_id     = g_selling_trns_rec.selling_trns_info_id  -- �쐬������ID
        AND    xsd.source_category    = cv_t_flag                                -- �쐬���敪�FEDI
        AND    xsd.status             = cv_n_flag                                -- �X�e�[�^�X�F�V�K
        AND    ROWNUM                 = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- �f�[�^���擾�ł��Ȃ������ꍇ�A�V�K�T��
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type   => cv_t_flag   -- �����敪�FEDI
                        ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type        => cv_t_flag  -- �����敪�FEDI
                     ,in_main_idx          => NULL        -- ���C���C���f�b�N�X
                     ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                     ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                     ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- �x���`�[�ԍ����ݒ肳��Ă���ꍇ�i�x���ρj
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- �x���`�[�ԍ�
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
--
        -- �T���f�[�^�o�^�x���σX�L�b�v����
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- �x���`�[�ԍ������ݒ�ł���ꍇ�i�����j
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- �T���w�b�_�̃��J�o���Ώۃt���O���uU:�X�V�v�A�܂���
        -- �T�����ׂ́u���J�o���Ώۃt���O���uU:�X�V�v�̏ꍇ
        IF    ((g_selling_trns_rec.header_recovery_flag = cv_u_flag)
          OR   (g_selling_trns_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- �T������ID���݊m�F�p������
          ln_condition_line_id_1 := 0;
--
          -- �����̑��݊m�F
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- �T���ڍ�ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
            WHERE  xsd.source_line_id     = g_selling_trns_rec.selling_trns_info_id  -- �쐬������ID
            AND    xsd.condition_line_id  = g_selling_trns_rec.condition_line_id     -- �T���ڍ�ID
            AND    xsd.source_category    = cv_t_flag                                -- �쐬���敪�FEDI
            AND    xsd.status             = cv_n_flag                                -- �X�e�[�^�X�F�V�K
            AND    xsd.recon_slip_num    IS NULL                                     -- �x���`�[�ԍ�
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- �����̍T�������݂����ꍇ�͍폜���{
          IF (ln_condition_line_id_1 != 0) THEN
            -- �T���ڍ�ID���O�����ƕς���Ă����ꍇ�A�폜���{
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
--
              -- ============================================================
              -- A-3.�̔��T����������̌Ăяo��
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- �T���ڍ�ID
                                      ,iv_syori_type        => cv_t_flag               -- �����敪
                                      ,ov_errbuf            => lv_errbuf               -- �G���[�E���b�Z�[�W
                                      ,ov_retcode           => lv_retcode              -- ���^�[���E�R�[�h
                                      ,ov_errmsg            => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type        => cv_t_flag  -- �����敪
                        ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type        => cv_t_flag  -- �����敪�FT
                     ,in_main_idx          => NULL        -- ���C���C���f�b�N�X
                     ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                     ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                     ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- �J�[�\���N���[�Y
    CLOSE g_selling_trns_cur;
--
    ln_condition_line_id_2 := 0;
--
    -- ���ѐU�֏��i�U�֊����j�J�[�\���I�[�v��
    OPEN g_actual_trns_cur;       --�v��ID
--
    LOOP
      -- �f�[�^�擾
      FETCH g_actual_trns_cur INTO g_actual_trns_rec;
      EXIT WHEN g_actual_trns_cur%NOTFOUND;
--
      -- �T������ID���݊m�F�p�A�`�[�ԍ����݊m�F������
      ln_condition_line_id  := 0;
      lv_recon_slip_num     := NULL;
--
      -- �̔��T���f�[�^���݊m�F
      BEGIN
        SELECT NVL(xsd.condition_line_id,0)            -- �T���ڍ�ID
              ,NVL(xsd.recon_slip_num, cv_dummy_flag)  -- �x���`�[�ԍ�
        INTO   ln_condition_line_id
              ,lv_recon_slip_num
        FROM   xxcok_sales_deduction     xsd                            -- �̔��T�����
        WHERE  xsd.condition_id       = g_actual_trns_rec.condition_id          -- �T������ID
        AND    xsd.source_line_id     = g_actual_trns_rec.selling_trns_info_id  -- �쐬������ID
        AND    xsd.source_category    = cv_v_flag                               -- �쐬���敪�F�U�֊���
        AND    xsd.status             = cv_n_flag                               -- �X�e�[�^�X�F�V�K
        AND    ROWNUM                 = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_condition_line_id  := 0;
          lv_recon_slip_num     := cv_dummy_flag;
      END;
--
      -- �f�[�^���擾�ł��Ȃ������ꍇ�A�V�K�T��
      IF (ln_condition_line_id = 0 AND lv_recon_slip_num = cv_dummy_flag )THEN
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type   => cv_v_flag   -- �����敪�F�U�֊���
                        ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type        => cv_v_flag   -- �����敪�F�U�֊���
                     ,in_main_idx          => NULL        -- ���C���C���f�b�N�X
                     ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                     ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                     ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      -- �x���`�[�ԍ����ݒ肳��Ă���ꍇ�i�x���ρj
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num != cv_dummy_flag ) THEN
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_recon_slip_num
                                               ,iv_token_value1 => lv_recon_slip_num        -- �x���`�[�ԍ�
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
--
        -- �T���f�[�^�o�^�x���σX�L�b�v����
        gn_add_skip_cnt := gn_add_skip_cnt + 1;
--
      -- �x���`�[�ԍ������ݒ�ł���ꍇ�i�����j
      ELSIF ( ln_condition_line_id != 0 AND lv_recon_slip_num = cv_dummy_flag ) THEN
--
        -- �T���w�b�_�̃��J�o���Ώۃt���O���uU:�X�V�v�A�܂���
        -- �T�����ׂ́u���J�o���Ώۃt���O���uU:�X�V�v�̏ꍇ
        IF    ((g_actual_trns_rec.header_recovery_flag = cv_u_flag)
          OR   (g_actual_trns_rec.line_recovery_flag = cv_u_flag))THEN
--
          -- �T������ID���݊m�F�p������
          ln_condition_line_id_1 := 0;
--
          -- �����̑��݊m�F
          BEGIN
            SELECT NVL(xsd.condition_line_id,0)  -- �T���ڍ�ID
            INTO   ln_condition_line_id_1
            FROM   xxcok_sales_deduction     xsd                     -- �̔��T�����
            WHERE  xsd.source_line_id     = g_actual_trns_rec.selling_trns_info_id   -- �쐬������ID
            AND    xsd.condition_line_id  = g_actual_trns_rec.condition_line_id      -- �T���ڍ�ID
            AND    xsd.source_category    = cv_v_flag                                -- �쐬���敪�F�U�֊���
            AND    xsd.status             = cv_n_flag                                -- �X�e�[�^�X�F�V�K
            AND    xsd.recon_slip_num    IS NULL                                     -- �x���`�[�ԍ�
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_condition_line_id_1  := 0;
          END;
--
          -- �����̍T�������݂����ꍇ�͍폜���{
          IF (ln_condition_line_id_1 != 0) THEN
--
            -- �T���ڍ�ID���O�����ƕς���Ă����ꍇ�A�폜���{
            IF (ln_condition_line_id_1 != ln_condition_line_id_2) THEN
              -- ============================================================
              -- A-3.�̔��T����������̌Ăяo��
              -- ============================================================
                sales_deduction_delete(in_condition_line_id => ln_condition_line_id_1  -- �T���ڍ�ID
                                      ,iv_syori_type        => cv_v_flag               -- �����敪
                                      ,ov_errbuf            => lv_errbuf               -- �G���[�E���b�Z�[�W
                                      ,ov_retcode           => lv_retcode              -- ���^�[���E�R�[�h
                                      ,ov_errmsg            => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
                                       );
--
            END IF;
--
            ln_condition_line_id_2 := ln_condition_line_id_1;
--
          END IF;
        END IF;
--
        -- ============================================================
        -- A-5.�T���f�[�^�Z�o�̌Ăяo��
        -- ============================================================
        calculation_data(iv_syori_type        => cv_v_flag   -- �����敪
                        ,ov_errbuf            => lv_errbuf   -- �G���[�E���b�Z�[�W
                        ,ov_retcode           => lv_retcode  -- ���^�[���E�R�[�h
                        ,ov_errmsg            => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
                         );
--
        IF lv_retcode  = cv_status_normal  THEN
          -- ============================================================
          -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
          -- ============================================================
          insert_data(iv_syori_type  => cv_v_flag      -- �����敪�FT
                     ,in_main_idx    => NULL           -- ���C���C���f�b�N�X
                     ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W
                     ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h
                     ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
                      );
--
          IF  lv_retcode  = cv_status_normal  THEN
            gn_add_cnt :=  gn_add_cnt + 1;
          ELSE
            RAISE global_process_expt;
          END IF;
        ELSIF lv_retcode  = cv_status_warn  THEN
          ov_retcode    := cv_status_warn;
          gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP;
    -- �J�[�\���N���[�Y
    CLOSE g_actual_trns_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : get_condition_data
   * Description      : A-2.�T�����X�V�Ώے��o
   ***********************************************************************************/
  PROCEDURE get_condition_data(ov_errbuf   OUT  VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,ov_retcode  OUT  VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
                              ,ov_errmsg   OUT  VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_condition_data'; -- �v���O������
--
--#########################  �Œ胍�[�J���ϐ��錾�� START  #########################
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--##################################  �Œ蕔 END  ##################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_main_idx             NUMBER DEFAULT 0;                          -- ���C���J�[�\���C���f�b�N�X�ޔ�p
    ln_work_idx             NUMBER DEFAULT 0;                          -- ���[�N�e�[�u���C���f�b�N�X�ޔ�p
    lv_get_data_flag        VARCHAR2(1)    DEFAULT NULL;               -- �f�[�^�쐬�����t���O
    lv_out_msg              VARCHAR2(1000) DEFAULT NULL;               -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode              BOOLEAN        DEFAULT NULL;               -- ���b�Z�[�W�o�͊֐��̖߂�l
-- 2021/10/21 Ver1.5 ADD Start
    ln_msg_err_cnt          NUMBER DEFAULT 0;                          -- ���b�Z�[�W���o������
    ln_msg_dis_cnt          NUMBER DEFAULT 0;                          -- ���b�Z�[�W���o������
    ln_msg_ins_cnt          NUMBER DEFAULT 0;                          -- ���b�Z�[�W���o������
-- 2021/10/21 Ver1.5 ADD End
--
    -- *** ���[�J����O ***
    no_data_expt              EXCEPTION;               -- �Ώۃf�[�^0���G���[
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���J�o���ΏۊO�폜�����擾�p�J�[�\��
    CURSOR l_del_cnt_cur
    IS
-- 2021/09/17 Ver1.4 MOD Start
--      SELECT xsd.recon_slip_num     recon_slip_num
      SELECT xsd.sales_deduction_id               sales_deduction_id              --�̔��T��ID
             ,xsd.base_code_from                  base_code_from                  --�U�֌����_
             ,xsd.base_code_to                    base_code_to                    --�U�֐拒�_
             ,xsd.customer_code_from              customer_code_from              --�U�֌��ڋq�R�[�h
             ,xsd.customer_code_to                customer_code_to                --�U�֐�ڋq�R�[�h
             ,xsd.deduction_chain_code            deduction_chain_code            --�T���p�`�F�[���R�[�h
             ,xsd.corp_code                       corp_code                       --��ƃR�[�h
             ,xsd.record_date                     record_date                     --�v���
             ,xsd.source_category                 source_category                 --�쐬���敪
             ,xsd.source_line_id                  source_line_id                  --�쐬������ID
             ,xsd.condition_id                    condition_id                    --�T������ID
             ,xsd.condition_no                    condition_no                    --�T���ԍ�
             ,xsd.condition_line_id               condition_line_id               --�T���ڍ�ID
             ,xsd.data_type                       data_type                       --�f�[�^���
             ,xsd.status                          status                          --�X�e�[�^�X
             ,xsd.item_code                       item_code                       --�i�ڃR�[�h
             ,xsd.sales_uom_code                  sales_uom_code                  --�̔��P��
             ,xsd.sales_unit_price                sales_unit_price                --�̔��P��
             ,xsd.sales_quantity                  sales_quantity                  --�̔�����
             ,xsd.sale_pure_amount                sale_pure_amount                --����{�̋��z
             ,xsd.sale_tax_amount                 sale_tax_amount                 --�������Ŋz
             ,xsd.deduction_uom_code              deduction_uom_code              --�T���P��
             ,xsd.deduction_unit_price            deduction_unit_price            --�T���P��
             ,xsd.deduction_quantity              deduction_quantity              --�T������
             ,xsd.deduction_amount                deduction_amount                --�T���z
             ,xsd.compensation                    compensation                    --��U
             ,xsd.margin                          margin                          --�≮�}�[�W��
             ,xsd.sales_promotion_expenses        sales_promotion_expenses        --�g��
             ,xsd.margin_reduction                margin_reduction                --�≮�}�[�W�����z
             ,xsd.tax_code                        tax_code                        --�ŃR�[�h
             ,xsd.tax_rate                        tax_rate                        --�ŗ�
             ,xsd.recon_tax_code                  recon_tax_code                  --�������ŃR�[�h
             ,xsd.recon_tax_rate                  recon_tax_rate                  --�������ŗ�
             ,xsd.deduction_tax_amount            deduction_tax_amount            --�T���Ŋz
             ,xsd.remarks                         remarks                         --���l
             ,xsd.application_no                  application_no                  --�\����No.
             ,xsd.gl_if_flag                      gl_if_flag                      --GL�A�g�t���O
             ,xsd.gl_base_code                    gl_base_code                    --GL�v�㋒�_
             ,xsd.gl_date                         gl_date                         --GL�L����
             ,xsd.recovery_date                   recovery_date                   --���J�o���[���t
             ,xsd.recovery_add_request_id         recovery_add_request_id         --���J�o���f�[�^�ǉ����v��ID
             ,xsd.recovery_del_date               recovery_del_date               --���J�o���f�[�^�폜�����t
             ,xsd.recovery_del_request_id         recovery_del_request_id         --���J�o���f�[�^�폜���v��ID
             ,xsd.cancel_flag                     cancel_flag                     --����t���O
             ,xsd.cancel_base_code                cancel_base_code                --������v�㋒�_
             ,xsd.cancel_gl_date                  cancel_gl_date                  --���GL�L����
             ,xsd.cancel_user                     cancel_user                     --������{���[�U
             ,xsd.recon_base_code                 recon_base_code                 --�������v�㋒�_
             ,xsd.recon_slip_num                  recon_slip_num                  --�x���`�[�ԍ�
             ,xsd.carry_payment_slip_num          carry_payment_slip_num          --�J�z���x���`�[�ԍ�
             ,xsd.report_decision_flag            report_decision_flag            --����m��t���O
             ,xsd.gl_interface_id                 gl_interface_id                 --GL�A�gID
             ,xsd.cancel_gl_interface_id          cancel_gl_interface_id          --���GL�A�gID
             ,flv.attribute2                      dedu_type                       --�T���^�C�v
             ,flv.meaning                         dedu_type_name                  --�T���^�C�v
             ,xcl.detail_number                   detail_number                   --���הԍ�
-- 2021/09/17 Ver1.4 MOD End
      FROM   xxcok_sales_deduction  xsd                                  -- �̔��T�����
-- 2021/09/17 Ver1.4 ADD Start
            ,fnd_lookup_values      flv                                  -- �f�[�^���
            ,xxcok_condition_lines  xcl                                  -- �T���ڍ׏��
-- 2021/09/17 Ver1.4 ADD End
      WHERE  xsd.recon_slip_num     IS NOT NULL                            -- �x���`�[�ԍ�
      AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                        ,cv_v_flag ,cv_f_flag)             -- �쐬���敪
      AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )            -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
      AND    xsd.status              = cv_n_flag                           -- �X�e�[�^�X(N�F�V�K)
      AND    xsd.condition_line_id   = gn_condition_line_id                -- �T���ڍ�ID
-- 2021/09/17 Ver1.4 ADD Start
      AND  ( xsd.report_decision_flag   IS NULL         OR
             xsd.report_decision_flag    = cv_deci_flag )                  -- ����m��t���O
      AND    flv.lookup_type         = cv_lookup_dedu_code
      AND    flv.lookup_code         = xsd.data_type
      AND    flv.language            = USERENV('LANG')
      AND    flv.enabled_flag        = cv_y_flag
      AND    xsd.condition_line_id   = xcl.condition_line_id
      ORDER BY
             xsd.condition_id
            ,xsd.condition_line_id
-- 2021/09/17 Ver1.4 ADD End
      ;
--
    l_del_cnt_rec           l_del_cnt_cur%ROWTYPE;
--
-- 2021/10/21 Ver1.5 ADD Start
    -- *** ���[�J���E�J�[�\�� ***
    -- ���J�o���ΏۊO�폜���b�Z�[�W�o�͗p�J�[�\��
    CURSOR l_del_message_cur
    IS
      SELECT 
            recon.condition_no                   condition_no                           -- �T���ԍ�
           ,recon.deduction_type                 deduction_type                         -- �T���^�C�v
           ,recon.discount_target                discount_target                        -- �������l���Ώ�
           ,recon.recon_slip_num                 recon_slip_num                         -- �x���`�[�ԍ�
           ,recon.recon_status                   recon_status                           -- �����X�e�[�^�X
           ,to_char(recon.max_recon_due_date,'YYYY/MM/DD')             max_recon_due_date                     -- �x���\���
           ,to_char(recon.target_date_end,'YYYY/MM/DD')                target_date_end                        -- �Ώۊ���(to)
      FROM (
           SELECT 
                    xsd.sales_deduction_id               sales_deduction_id             -- �̔��T��ID
                   ,xsd.condition_no                    condition_no                    -- �T���ԍ�
                   ,xsd.condition_line_id               condition_line_id               -- �T���ڍ�ID
                   ,flv.attribute2                      deduction_type                  -- �T���^�C�v
                   ,flv.attribute10                     discount_target                 -- �������l���Ώ�
                   ,xdrh.deduction_recon_head_id        deduction_recon_head_id         -- �T�������w�b�_�[ID
                   ,xdrh.recon_slip_num                 recon_slip_num                  -- �x���`�[�ԍ�
                   ,flv2.meaning                        recon_status                    -- �����X�e�[�^�X
                   ,xdrh.recon_due_date                 recon_due_date                  -- �x���\���
                   ,max(xdrh.recon_due_date) over(partition by  xsd.condition_line_id)  
                                                        max_recon_due_date              -- MAX�x���\���
                   ,xdrh.target_date_end                target_date_end                 -- �Ώۊ���(to)
            FROM   xxcok_sales_deduction      xsd                                       -- �̔��T�����
                  ,fnd_lookup_values          flv                                       -- �f�[�^���
                  ,fnd_lookup_values          flv2                                      -- �T�������w�b�_�[�X�e�[�^�X
                  ,xxcok_deduction_recon_head xdrh                                      -- �T�������w�b�_�[
            WHERE  xsd.recon_slip_num     IS NOT NULL                                   -- �x���`�[�ԍ�
            AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                              ,cv_v_flag ,cv_f_flag)                    -- �쐬���敪
            AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                   -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
            AND    xsd.status              = cv_n_flag                                  -- �X�e�[�^�X(N�F�V�K)
            AND    xsd.condition_line_id  IN (SELECT xcl.condition_line_id     condition_line_id       -- �T���ڍ�ID
                                              FROM   xxcok_condition_header    xch                     -- �T�������e�[�u��
                                                    ,xxcok_condition_lines     xcl                     -- �T���ڍ׃e�[�u��
                                              WHERE  xch.condition_id              = xcl.condition_id  -- �T������ID
                                              AND (  (    xch.header_recovery_flag  = cv_d_flag)
                                                   OR(    xch.header_recovery_flag  = cv_u_flag
                                                      AND xcl.line_recovery_flag    = cv_d_flag)
                                                   OR(    xch.header_recovery_flag  = cv_n_flag
                                                      AND xcl.line_recovery_flag    = cv_d_flag))       -- ���J�o���Ώۃt���O
                                              AND (     xch.request_id            = gn_request_id
                                                    OR  xcl.request_id            = gn_request_id)    -- �v��ID
                                             )
            AND  ( xsd.report_decision_flag   IS NULL         OR
                   xsd.report_decision_flag    = cv_deci_flag )                         -- ����m��t���O
            AND    flv.lookup_type         = cv_lookup_dedu_code
            AND    flv.lookup_code         = xsd.data_type
            AND    flv.language            = USERENV('LANG')
            AND    flv.enabled_flag        = cv_y_flag
            AND    flv.attribute10         = cv_n_flag                                  -- �������l���ȊO
            AND    flv2.lookup_type        = cv_head_erase_status
            AND    flv2.lookup_code        = xdrh.recon_status
            AND    flv2.language           = USERENV('LANG')
            AND    flv2.enabled_flag       = cv_y_flag
            AND    xsd.recon_slip_num      = xdrh.recon_slip_num
            UNION ALL
            SELECT xsd.sales_deduction_id              sales_deduction_id               -- �̔��T��ID
                  ,xsd.condition_no                    condition_no                     -- �T���ԍ�
                  ,xsd.condition_line_id               condition_line_id                -- �T���ڍ�ID
                  ,null                                deduction_type                   -- �T���^�C�v
                  ,flv.attribute10                     discount_target                  -- �������l���Ώ�
                  ,rct.customer_trx_id                 deduction_recon_head_id          -- �T�������w�b�_�[ID
                  ,xsd.recon_slip_num                  recon_slip_num                   -- �x���`�[�ԍ�
                  ,null                                recon_status                     -- �����X�e�[�^�X
                  ,aps.due_date                        due_date                         -- �x���\���
                  ,max(aps.due_date) over(partition by  xsd.condition_line_id)  
                                                              max_recon_due_date        -- MAX�x���\���
                  ,null                                target_date_end                  -- �Ώۊ���(to)
            FROM   xxcok_sales_deduction      xsd                                       -- �̔��T�����
                  ,fnd_lookup_values          flv                                       -- �f�[�^���
                  ,ra_customer_trx_all        rct                                       -- AR����w�b�_�[
                  ,ar_payment_schedules_all   aps                                       -- AR�����\��
            WHERE  xsd.recon_slip_num     IS NOT NULL                                   -- �x���`�[�ԍ�
            AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                              ,cv_v_flag ,cv_f_flag)                    -- �쐬���敪
            AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                   -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
            AND    xsd.status              = cv_n_flag                                  -- �X�e�[�^�X(N�F�V�K)
            AND    xsd.condition_line_id  IN  (SELECT xcl.condition_line_id     condition_line_id       -- �T���ڍ�ID
                                               FROM   xxcok_condition_header    xch                     -- �T�������e�[�u��
                                                     ,xxcok_condition_lines     xcl                     -- �T���ڍ׃e�[�u��
                                               WHERE  xch.condition_id              = xcl.condition_id  -- �T������ID
                                               AND (  (    xch.header_recovery_flag  = cv_d_flag)
                                                    OR(    xch.header_recovery_flag  = cv_u_flag
                                                       AND xcl.line_recovery_flag    = cv_d_flag)
                                                    OR(    xch.header_recovery_flag  = cv_n_flag
                                                       AND xcl.line_recovery_flag    = cv_d_flag))       -- ���J�o���Ώۃt���O
                                                AND  (     xch.request_id            = gn_request_id
                                                       OR  xcl.request_id            = gn_request_id)    -- �v��ID
                                               )
           AND  ( xsd.report_decision_flag   IS NULL         OR
                   xsd.report_decision_flag    = cv_deci_flag )                         -- ����m��t���O
            AND    flv.lookup_type         = cv_lookup_dedu_code
            AND    flv.lookup_code         = xsd.data_type
            AND    flv.language            = USERENV('LANG')
            AND    flv.enabled_flag        = cv_y_flag
            AND    flv.attribute10         = cv_y_flag                                  -- �������l��
            AND    xsd.recon_slip_num      = rct.trx_number
            AND    rct.customer_trx_id     = aps.customer_trx_id
            )recon
      WHERE recon.recon_due_date = recon.max_recon_due_date
      GROUP BY
            recon.condition_no                                                          -- �T���ԍ�
           ,condition_line_id                                                           -- �T���ڍ�ID
           ,recon.deduction_type                                                        -- �f�[�^���
           ,discount_target                                                             -- �������l���Ώ�
           ,recon.recon_slip_num                                                        -- �x���`�[�ԍ�
           ,recon.recon_status                                                          -- �����X�e�[�^�X
           ,recon.max_recon_due_date                                                    -- �x���\���
           ,recon.target_date_end                                                       -- �Ώۊ���(to)
      ORDER BY 
            decode(recon.deduction_type,cv_030,'XXX', 
                   decode(recon.deduction_type,cv_040,'XXX','000'))                     -- �f�[�^���
           ,recon.discount_target                                                       -- �������l���Ώ�
           ,recon.condition_no                                                          -- �T���ԍ�
           ,condition_line_id                                                           -- �T���ڍ�ID
           ,recon.recon_slip_num                                                        -- �x���`�[�ԍ�
      ;
--
    l_del_message_rec           l_del_message_cur%ROWTYPE;
--
-- 2021/10/21 Ver1.5 ADD End
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--#########################  �Œ�X�e�[�^�X�������� START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  �Œ蕔 END  ##################################
--
    -- �J�[�\���I�[�v��
    OPEN get_condition_data_cur;       --�v��ID
    -- �f�[�^�擾
    FETCH get_condition_data_cur BULK COLLECT INTO gt_condition_work_tbl;
    -- �J�[�\���N���[�Y
    CLOSE get_condition_data_cur;
--
    -- �擾�f�[�^���O���̏ꍇ
    IF ( gt_condition_work_tbl.COUNT = 0 ) THEN
--
      -- �Ώۃf�[�^�����G���[
      RAISE no_data_expt;
    END IF;
--
-- 2021/10/21 Ver1.5 ADD Start
    -- ���J�o���ΏۊO���b�Z�[�W�o�͗p�J�[�\���I�[�v��
    OPEN l_del_message_cur;
    LOOP
    -- �f�[�^�擾
    FETCH l_del_message_cur INTO l_del_message_rec;
    EXIT WHEN l_del_message_cur%NOTFOUND;
--
      IF l_del_message_rec.deduction_type IN (cv_030,cv_040)  THEN
        IF ln_msg_ins_cnt = 0 THEN
          --�x���������̍T���𑊎E����T���f�[�^�쐬���b�Z�[�W���o��
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_ins_d
                                                );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                       ,lv_out_msg         -- ���b�Z�[�W
                                                       ,1                  -- ���s
                                                       );
        END IF;
        ln_msg_ins_cnt := ln_msg_ins_cnt + 1;
--
        --�x���������̍T���𑊎E����T���f�[�^�쐬���b�Z�[�W
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_ins
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- �T���ԍ�
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- �x���`�[�ԍ�
                                               ,iv_token_name3  => cv_tkn_target_date_end
                                               ,iv_token_value3 => l_del_message_rec.target_date_end       -- �Ώۊ��ԁiTO)
                                               ,iv_token_name4  => cv_tkn_due_date
                                               ,iv_token_value4 => l_del_message_rec.max_recon_due_date    -- �x���\���
                                               ,iv_token_name5  => cv_tkn_status
                                               ,iv_token_value5 => l_del_message_rec.recon_status          -- �X�e�[�^�X
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
--
      ELSIF l_del_message_rec.discount_target = cv_y_flag  THEN
        IF ln_msg_dis_cnt = 0 THEN
          --�x�������m���(�x���`�[�����F��)�̍T���f�[�^�̍폜�X�L�b�v���b�Z�[�W(�������l��)���o��
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_dis_d
                                                 );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                       ,lv_out_msg         -- ���b�Z�[�W
                                                       ,1                  -- ���s
                                                       );
        END IF;
        ln_msg_dis_cnt := ln_msg_dis_cnt + 1;
--
        --�x�������m���(�x���`�[�����F��)�̍T���f�[�^�̍폜�X�L�b�v���b�Z�[�W(�������l��)
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_discount
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- �T���ԍ�
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- �x���`�[�ԍ�
                                               ,iv_token_name3  => cv_tkn_due_date
                                               ,iv_token_value3 => l_del_message_rec.max_recon_due_date    -- �x������
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
--
      ELSE
        IF ln_msg_err_cnt = 0 THEN
          --�x�������m���(�x���`�[�����F��)�̍T���f�[�^�̍폜�X�L�b�v���b�Z�[�W���o��
          lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                                 ,iv_name         => cv_msg_slip_date_err_d
                                                 );
--
          lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                       ,lv_out_msg         -- ���b�Z�[�W
                                                       ,1                  -- ���s
                                                       );
--
        END IF;
        ln_msg_err_cnt := ln_msg_err_cnt + 1;
--
        --�x�������m���(�x���`�[�����F��)�̍T���f�[�^�̍폜�X�L�b�v���b�Z�[�W
        lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
                                               ,iv_name         => cv_msg_slip_date_err
                                               ,iv_token_name1  => cv_tkn_condition_no
                                               ,iv_token_value1 => l_del_message_rec.condition_no          -- �T���ԍ�
                                               ,iv_token_name2  => cv_tkn_recon_slip_num
                                               ,iv_token_value2 => l_del_message_rec.recon_slip_num        -- �x���`�[�ԍ�
                                               ,iv_token_name3  => cv_tkn_target_date_end
                                               ,iv_token_value3 => l_del_message_rec.target_date_end       -- �Ώۊ��ԁiTO)
                                               ,iv_token_name4  => cv_tkn_due_date
                                               ,iv_token_value4 => l_del_message_rec.max_recon_due_date    -- �x���\���
                                               );
--
        lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
                                                     ,lv_out_msg         -- ���b�Z�[�W
                                                     ,1                  -- ���s
                                                     );
      END IF;
    END LOOP;
    -- �J�[�\���N���[�Y
    CLOSE l_del_message_cur;
   --
-- 2021/10/21 Ver1.5 ADD End
--
    -- �T�������̃��[�v�X�^�[�g
    <<main_data_loop>>
    FOR i IN 1..gt_condition_work_tbl.COUNT LOOP
--
      -- �J�[�\���p�����[�^�p�ɍT���ڍ�ID��ޔ�
      gn_condition_line_id := gt_condition_work_tbl(i).condition_line_id;
--
--      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- �w�b�_�[�̃��J�o���t���O���uD�F�폜�v�܂��́A
      -- �w�b�_�[�̃��J�o���t���O���uU�F�X�V�v�A���ׂ̃��J�o���t���O���uD�F�폜�v�܂��́A
      -- �w�b�_�[�̃��J�o���t���O���uN�F�ΏۊO�v�A���ׂ̃��J�o���t���O���uD�F�폜�v
      IF    ((gt_condition_work_tbl(i).header_recovery_flag  = cv_d_flag)
        OR   (gt_condition_work_tbl(i).header_recovery_flag  = cv_u_flag
        AND   gt_condition_work_tbl(i).line_recovery_flag    = cv_d_flag)
        OR   (gt_condition_work_tbl(i).header_recovery_flag  = cv_n_flag
        AND   gt_condition_work_tbl(i).line_recovery_flag    = cv_d_flag)) THEN
--
        -- �T���}�X�^�폜�Ώی���
        gn_del_target_cnt := gn_del_target_cnt + 1;
--
        -- ���J�o���ΏۊO�폜�����擾�p�J�[�\���I�[�v��
        OPEN l_del_cnt_cur;
--
        LOOP
        -- �f�[�^�擾
        FETCH l_del_cnt_cur INTO l_del_cnt_rec;
        EXIT WHEN l_del_cnt_cur%NOTFOUND;
--
-- 2021/09/17 Ver1.4 ADD Start
          IF l_del_cnt_rec.dedu_type IN (cv_030,cv_040)  THEN
            INSERT INTO xxcok_sales_deduction(
              sales_deduction_id       --�̔��T��ID
             ,base_code_from           --�U�֌����_
             ,base_code_to             --�U�֐拒�_
             ,customer_code_from       --�U�֌��ڋq�R�[�h
             ,customer_code_to         --�U�֐�ڋq�R�[�h
             ,deduction_chain_code     --�T���p�`�F�[���R�[�h
             ,corp_code                --��ƃR�[�h
             ,record_date              --�v���
             ,source_category          --�쐬���敪
             ,source_line_id           --�쐬������ID
             ,condition_id             --�T������ID
             ,condition_no             --�T���ԍ�
             ,condition_line_id        --�T���ڍ�ID
             ,data_type                --�f�[�^���
             ,status                   --�X�e�[�^�X
             ,item_code                --�i�ڃR�[�h
             ,sales_uom_code           --�̔��P��
             ,sales_unit_price         --�̔��P��
             ,sales_quantity           --�̔�����
             ,sale_pure_amount         --����{�̋��z
             ,sale_tax_amount          --�������Ŋz
             ,deduction_uom_code       --�T���P��
             ,deduction_unit_price     --�T���P��
             ,deduction_quantity       --�T������
             ,deduction_amount         --�T���z
             ,compensation             --��U
             ,margin                   --�≮�}�[�W��
             ,sales_promotion_expenses --�g��
             ,margin_reduction         --�≮�}�[�W�����z
             ,tax_code                 --�ŃR�[�h
             ,tax_rate                 --�ŗ�
             ,recon_tax_code           --�������ŃR�[�h
             ,recon_tax_rate           --�������ŗ�
             ,deduction_tax_amount     --�T���Ŋz
             ,remarks                  --���l
             ,application_no           --�\����No.
             ,gl_if_flag               --GL�A�g�t���O
             ,gl_base_code             --GL�v�㋒�_
             ,gl_date                  --GL�L����
             ,recovery_date            --���J�o���[���t
             ,recovery_add_request_id  --���J�o���f�[�^�ǉ����v��ID
             ,recovery_del_date        --���J�o���f�[�^�폜�����t
             ,recovery_del_request_id  --���J�o���f�[�^�폜���v��ID
             ,cancel_flag              --����t���O
             ,cancel_base_code         --������v�㋒�_
             ,cancel_gl_date           --���GL�L����
             ,cancel_user              --������{���[�U
             ,recon_base_code          --�������v�㋒�_
             ,recon_slip_num           --�x���`�[�ԍ�
             ,carry_payment_slip_num   --�J�z���x���`�[�ԍ�
             ,report_decision_flag     --����m��t���O
             ,gl_interface_id          --GL�A�gID
             ,cancel_gl_interface_id   --���GL�A�gID
             ,created_by               --�쐬��
             ,creation_date            --�쐬��
             ,last_updated_by          --�ŏI�X�V��
             ,last_update_date         --�ŏI�X�V��
             ,last_update_login        --�ŏI�X�V���O�C��
             ,request_id               --�v��ID
             ,program_application_id   --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id               --�R���J�����g�E�v���O����ID
             ,program_update_date      --�v���O�����X�V��
              )
            VALUES
             (
              xxcok_sales_deduction_s01.nextval           --�̔��T��ID
             ,l_del_cnt_rec.base_code_from                --�U�֌����_
             ,l_del_cnt_rec.base_code_to                  --�U�֐拒�_
             ,l_del_cnt_rec.customer_code_from            --�U�֌��ڋq�R�[�h
             ,l_del_cnt_rec.customer_code_to              --�U�֐�ڋq�R�[�h
             ,l_del_cnt_rec.deduction_chain_code          --�T���p�`�F�[���R�[�h
             ,l_del_cnt_rec.corp_code                     --��ƃR�[�h
             ,l_del_cnt_rec.record_date                   --�v���
             ,l_del_cnt_rec.source_category               --�쐬���敪
             ,l_del_cnt_rec.source_line_id                --�쐬������ID
             ,l_del_cnt_rec.condition_id                  --�T������ID
             ,l_del_cnt_rec.condition_no                  --�T���ԍ�
             ,l_del_cnt_rec.condition_line_id             --�T���ڍ�ID
             ,l_del_cnt_rec.data_type                     --�f�[�^���
             ,cv_n_flag                                   --�X�e�[�^�X
             ,l_del_cnt_rec.item_code                     --�i�ڃR�[�h
             ,l_del_cnt_rec.sales_uom_code                --�̔��P��
             ,l_del_cnt_rec.sales_unit_price              --�̔��P��
             ,l_del_cnt_rec.sales_quantity * -1           --�̔�����
             ,l_del_cnt_rec.sale_pure_amount * -1         --����{�̋��z
             ,l_del_cnt_rec.sale_tax_amount * -1          --�������Ŋz
             ,l_del_cnt_rec.deduction_uom_code            --�T���P��
             ,l_del_cnt_rec.deduction_unit_price          --�T���P��
             ,l_del_cnt_rec.deduction_quantity * -1       --�T������
             ,l_del_cnt_rec.deduction_amount * -1         --�T���z
             ,l_del_cnt_rec.compensation * -1             --��U
             ,l_del_cnt_rec.margin * -1                   --�≮�}�[�W��
             ,l_del_cnt_rec.sales_promotion_expenses * -1 --�g��
             ,l_del_cnt_rec.margin_reduction * -1         --�≮�}�[�W�����z
             ,l_del_cnt_rec.tax_code                      --�ŃR�[�h
             ,l_del_cnt_rec.tax_rate                      --�ŗ�
             ,NULL                                        --�������ŃR�[�h
             ,NULL                                        --�������ŗ�
             ,l_del_cnt_rec.deduction_tax_amount * -1     --�T���Ŋz
             ,l_del_cnt_rec.sales_deduction_id            --���l
             ,l_del_cnt_rec.application_no                --�\����No.
             ,cv_n_flag                                   --GL�A�g�t���O
             ,NULL                                        --GL�v�㋒�_
             ,NULL                                        --GL�L����
             ,gd_proc_date                                --���J�o���[���t
             ,cn_request_id                               --���J�o���f�[�^�ǉ����v��ID
             ,NULL                                        --���J�o���f�[�^�폜�����t
             ,NULL                                        --���J�o���f�[�^�폜���v��ID
             ,cv_n_flag                                   --����t���O
             ,NULL                                        --������v�㋒�_
             ,NULL                                        --���GL�L����
             ,NULL                                        --������{���[�U
             ,NULL                                        --�������v�㋒�_
             ,NULL                                        --�x���`�[�ԍ�
             ,NULL                                        --�J�z���x���`�[�ԍ�
             ,l_del_cnt_rec.report_decision_flag          --����m��t���O
             ,NULL                                        --GL�A�gID
             ,NULL                                        --���GL�A�gID
             ,cn_created_by                               -- �쐬��
             ,cd_creation_date                            -- �쐬��
             ,cn_last_updated_by                          -- �ŏI�X�V��
             ,cd_last_update_date                         -- �ŏI�X�V��
             ,cn_last_update_login                        -- �ŏI�X�V���O�C��
             ,cn_request_id                               -- �v��ID
             ,cn_program_application_id                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                               -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date                      -- �v���O�����X�V��
             );
--
-- 2021/10/21 Ver1.5 DELL Start
--            lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
--                                                   ,iv_name         => cv_msg_slip_date_ins
--                                                   ,iv_token_name1  => cv_tkn_column_value
--                                                   ,iv_token_value1 => l_del_cnt_rec.condition_no ||',' ||l_del_cnt_rec.detail_number  -- �T���ԍ��A���הԍ�
--                                                   ,iv_token_name2  => cv_tkn_data_type
--                                                   ,iv_token_value2 => l_del_cnt_rec.dedu_type_name                                    -- �f�[�^���
--                                                   ,iv_token_name3  => cv_tkn_recon_slip_num
--                                                   ,iv_token_value3 => l_del_cnt_rec.recon_slip_num                                    -- �x���`�[�ԍ�
--                                                   );
--
--            lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
--                                                         ,lv_out_msg         -- ���b�Z�[�W
--                                                         ,1                  -- ���s
--                                                         );
-- 2021/10/21 Ver1.5 DELL End
--
            gn_del_ins_cnt := gn_del_ins_cnt + 1;
-- 2021/09/17 Ver1.4 ADD End
-- 2021/09/17 Ver1.4 MOD Start
          ELSE
-- 2021/10/21 Ver1.5 DELL Start
--            lv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_name
--                                                   ,iv_name         => cv_msg_slip_date_err
--                                                   ,iv_token_name1  => cv_tkn_recon_slip_num
--                                                   ,iv_token_value1 => l_del_cnt_rec.recon_slip_num        -- �x���`�[�ԍ�
--                                                   );
--
--            lb_retcode := xxcok_common_pkg.put_message_f( FND_FILE.OUTPUT    -- �o�͋敪
--                                                         ,lv_out_msg         -- ���b�Z�[�W
--                                                         ,1                  -- ���s
--                                                         );
-- 2021/10/21 Ver1.5 DELL End
--
            gn_del_skip_cnt := gn_del_skip_cnt + 1;
          END IF;
-- 2021/09/17 Ver1.4 MOD End
        END LOOP;
        -- �J�[�\���N���[�Y
        CLOSE l_del_cnt_cur;
--
        -- ============================================================
        -- A-3.�̔��T����������̌Ăяo��
        -- ============================================================
        sales_deduction_delete(in_condition_line_id => gn_condition_line_id
                              ,iv_syori_type        => NULL                 -- �����敪
                              ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W
                              ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h
                              ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
                               );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- �T���^�C�v���u070�F��z�T���v�ȊO����
      ELSIF  gt_condition_work_tbl(i).deduction_type       <> '070' THEN
--
        -- �w�b�_�[�̃��J�o���t���O���uI�F�ǉ��v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�܂��́A
        -- �w�b�_�[�̃��J�o���t���O���uU�F�X�V�v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�A�uU�F�X�V�v�A�uN�F�ΏۊO�v�܂��́A
        -- �w�b�_�[�̃��J�o���t���O���uN�F�ΏۊO�v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�A�uU�F�X�V�v
        IF    (gt_condition_work_tbl(i).header_recovery_flag = cv_i_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag   = cv_i_flag)
          OR  (gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag,cv_n_flag))
          OR  (gt_condition_work_tbl(i).header_recovery_flag = cv_n_flag
          AND  gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag)) THEN
--
          -- �T���}�X�^�o�^�Ώی���
          gn_add_target_cnt := gn_add_target_cnt + 1;
--
          -- �������t�̍T���f�[�^�������̍폜�����p�Ƀ��[�N�֍T������ID�A�T���ڍ�ID�A�I������ޔ�
          IF  (gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag) THEN
--
            -- �J�E���g�A�b�v
            ln_work_idx := ln_work_idx + 1;
--
            gt_condition_work_1_tbl(ln_work_idx).condition_id       :=gt_condition_work_tbl(i).condition_id;       -- �T������ID
            gt_condition_work_1_tbl(ln_work_idx).condition_line_id  :=gt_condition_work_tbl(i).condition_line_id;  -- �T���ڍ�ID
            gt_condition_work_1_tbl(ln_work_idx).end_date_active    :=gt_condition_work_tbl(i).end_date_active;    -- �I����
          END IF;
--
--
          INSERT INTO xxcok_condition_recovery_temp(
            condition_id                                         -- �T������ID
           ,condition_no                                         -- �T���ԍ�
           ,corp_code                                            -- ��ƃR�[�h
           ,deduction_chain_code                                 -- �T���p�`�F�[���R�[�h
           ,customer_code                                        -- �ڋq�R�[�h
           ,start_date_active                                    -- �J�n��
           ,end_date_active                                      -- �I����
           ,data_type                                            -- �f�[�^���
           ,tax_code_con                                         -- �ŃR�[�h
           ,tax_rate_con                                         -- �ŗ�
           ,enabled_flag_h                                       -- �w�b�_�L���t���O
           ,header_recovery_flag                                 -- �w�b�_�[���J�o���Ώۃt���O
           ,condition_line_id                                    -- �T���ڍ�ID
           ,product_class                                        -- ���i�敪
           ,item_code                                            -- �i�ڃR�[�h
           ,uom_code                                             -- �P��
           ,target_category                                      -- �Ώۋ敪
           ,shop_pay_1                                           -- �X�[(��)
           ,material_rate_1                                      -- ����(��)
           ,condition_unit_price_en_2                            -- �����P���Q(�~)
-- 2020/12/03 Ver1.1 ADD Start
           ,compensation_en_3                                    -- ��U(�~)
           ,wholesale_margin_en_3                                -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
           ,accrued_en_3                                         -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
           ,just_condition_en_4                                  -- �������(�~)
           ,wholesale_adj_margin_en_4                            -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
           ,accrued_en_4                                         -- �����v�S(�~)
           ,condition_unit_price_en_5                            -- �����P���T(�~)
           ,deduction_unit_price_en_6                            -- �T���P��(�~)
           ,enabled_flag_l                                       -- ���חL���t���O
           ,line_recovery_flag                                   -- ���׃��J�o���Ώۃt���O
          )VALUES(
            gt_condition_work_tbl(i).condition_id                -- �T������ID
           ,gt_condition_work_tbl(i).condition_no                -- �T���ԍ�
           ,gt_condition_work_tbl(i).corp_code                   -- ��ƃR�[�h
           ,gt_condition_work_tbl(i).deduction_chain_code        -- �T���p�`�F�[���R�[�h
           ,gt_condition_work_tbl(i).customer_code               -- �ڋq�R�[�h
           ,gt_condition_work_tbl(i).start_date_active           -- �J�n��
           ,gt_condition_work_tbl(i).end_date_active             -- �I����
           ,gt_condition_work_tbl(i).data_type                   -- �f�[�^���
           ,gt_condition_work_tbl(i).tax_code                    -- �ŃR�[�h
           ,gt_condition_work_tbl(i).tax_rate                    -- �ŗ�
           ,gt_condition_work_tbl(i).enabled_flag_h              -- �w�b�_�L���t���O
           ,gt_condition_work_tbl(i).header_recovery_flag        -- �w�b�_�[���J�o���Ώۃt���O
           ,gt_condition_work_tbl(i).condition_line_id           -- �T���ڍ�ID
           ,gt_condition_work_tbl(i).product_class               -- ���i�敪
           ,gt_condition_work_tbl(i).item_code                   -- �i�ڃR�[�h
           ,gt_condition_work_tbl(i).uom_code                    -- �P��
           ,gt_condition_work_tbl(i).target_category             -- �Ώۋ敪
           ,gt_condition_work_tbl(i).shop_pay_1                  -- �X�[(��)
           ,gt_condition_work_tbl(i).material_rate_1             -- ����(��)
           ,gt_condition_work_tbl(i).condition_unit_price_en_2   -- �����P���Q(�~)
-- 2020/12/03 Ver1.1 ADD Start
           ,gt_condition_work_tbl(i).compensation_en_3           -- ��U(�~)
           ,gt_condition_work_tbl(i).wholesale_margin_en_3       -- �≮�}�[�W��(�~)
-- 2020/12/03 Ver1.1 ADD End
           ,gt_condition_work_tbl(i).accrued_en_3                -- �����v�R(�~)
-- 2020/12/03 Ver1.1 ADD Start
           ,gt_condition_work_tbl(i).just_condition_en_4         -- �������(�~)
           ,gt_condition_work_tbl(i).wholesale_adj_margin_en_4   -- �≮�}�[�W���C��(�~)
-- 2020/12/03 Ver1.1 ADD End
           ,gt_condition_work_tbl(i).accrued_en_4                -- �����v�S(�~)
           ,gt_condition_work_tbl(i).condition_unit_price_en_5   -- �����P���T(�~)
           ,gt_condition_work_tbl(i).deduction_unit_price_en_6   -- �T���P��(�~)
           ,gt_condition_work_tbl(i).enabled_flag_l              -- ���חL���t���O
           ,gt_condition_work_tbl(i).line_recovery_flag          -- ���׃��J�o���Ώۃt���O
            )
          ;
--
          lv_get_data_flag := cv_y_flag;
--
        END IF;
      -- �T���^�C�v���u070�F��z�T���v
      ELSIF   gt_condition_work_tbl(i).deduction_type       = '070' THEN
--
        -- �w�b�_�[�̃��J�o���t���O���uI�F�ǉ��v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�܂��́A
        -- �w�b�_�[�̃��J�o���t���O���uU�F�X�V�v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�A�uU�F�X�V�v�A�uN�F�ΏۊO�v�܂��́A
        -- �w�b�_�[�̃��J�o���t���O���uN�F�ΏۊO�v�A���ׂ̃��J�o���t���O���uI�F�ǉ��v�A�uU�F�X�V�v
        IF    ( gt_condition_work_tbl(i).header_recovery_flag = cv_i_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag   = cv_i_flag)
          OR  ( gt_condition_work_tbl(i).header_recovery_flag = cv_u_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag,cv_n_flag))
          OR  ( gt_condition_work_tbl(i).header_recovery_flag = cv_n_flag
          AND   gt_condition_work_tbl(i).line_recovery_flag  IN (cv_i_flag,cv_u_flag)) THEN
--
          -- �T���}�X�^�o�^�Ώی���
          gn_add_target_cnt := gn_add_target_cnt + 1;
--
          -- ���C���J�[�\���̃C���f�b�N�X�ޔ�
          ln_main_idx := i ;
--
          -- �J�n���Ԋm�F
          -- �J�n�����Ɩ����t��薢���̍T���}�X�^�̏ꍇ
-- 2021/07/26 Ver1.3 MOD Start
--          IF gt_condition_work_tbl(i).start_date_active > gd_proc_date THEN
          IF gt_condition_work_tbl(i).start_date_active > gd_proc_date -1 THEN
-- 2021/07/26 Ver1.3 MOD End
             NULL;
          ELSE
--
            -- �I�������Ɩ����t��薢���̏ꍇ
-- 2021/07/26 Ver1.3 MOD Start
--            IF gt_condition_work_tbl(i).end_date_active > gd_proc_date THEN
            IF gt_condition_work_tbl(i).end_date_active > gd_proc_date -1  THEN
-- 2021/07/26 Ver1.3 MOD End
--
              -- ���[�N���t�ɋƖ����t�̓���������ݒ�
-- 2021/07/26 Ver1.3 MOD Start
--              gd_work_date := LAST_DAY(ADD_MONTHS(gd_proc_date,-1)) + cn_1;
              gd_work_date := LAST_DAY(ADD_MONTHS(gd_proc_date -1,-1)) + cn_1;
-- 2021/07/26 Ver1.3 MOD End
--
              -- ���[�N���t(�Ɩ����t)���J�n�������傫���Ԃ͌J�Ԃ����������{
              WHILE gd_work_date >= gt_condition_work_tbl(i).start_date_active  LOOP
--
                -- ============================================================
                -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
                -- ============================================================
                insert_data( iv_syori_type => cv_f_flag              -- �����敪
                            ,in_main_idx   => ln_main_idx            -- ���C���C���f�b�N�X
                            ,ov_errbuf     => lv_errbuf              -- �G���[�E���b�Z�[�W
                            ,ov_retcode    => lv_retcode             -- ���^�[���E�R�[�h
                            ,ov_errmsg     => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
                            );
--
                IF  lv_retcode  = cv_status_normal  THEN
                  gn_add_cnt :=  gn_add_cnt + 1;
                ELSIF lv_retcode  = cv_status_warn  THEN
                  ov_retcode    := cv_status_warn;
                  gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
                ELSE
                  RAISE global_process_expt;
                END IF;
--
                -- ���[�N���t�̌����J�E���g�_�E��
                gd_work_date := ADD_MONTHS(gd_work_date,-1);
--
              END LOOP;
--
            -- �I�������Ɩ����t���ߋ��̏ꍇ
            ELSE
--
              -- ���[�N���t�ɏI�����̓���������ݒ�
              gd_work_date := LAST_DAY(ADD_MONTHS(gt_condition_work_tbl(i).end_date_active,-1)) + cn_1;
--
              -- ���[�N���t���J�n�������傫���Ԃ͌J�Ԃ����������{
              WHILE gd_work_date >= gt_condition_work_tbl(i).start_date_active  LOOP
--
                -- ============================================================
                -- A-6.�̔��T���f�[�^�o�^�̌Ăяo��
                -- ============================================================
                insert_data( iv_syori_type => cv_f_flag              -- �����敪
                            ,in_main_idx   => ln_main_idx            -- ���C���C���f�b�N�X
                            ,ov_errbuf     => lv_errbuf              -- �G���[�E���b�Z�[�W
                            ,ov_retcode    => lv_retcode             -- ���^�[���E�R�[�h
                            ,ov_errmsg     => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
                            );
--
                IF  lv_retcode  = cv_status_normal  THEN
                  gn_add_cnt :=  gn_add_cnt + 1;
                ELSIF lv_retcode  = cv_status_warn  THEN
                  ov_retcode    := cv_status_warn;
                  gn_cal_skip_cnt   :=  gn_cal_skip_cnt   + 1;
                ELSE
                  RAISE global_process_expt;
                END IF;
--
                -- ���[�N���t�̌����J�E���g�_�E��
                gd_work_date := ADD_MONTHS(gd_work_date,-1);
--
              END LOOP;
--
            END IF;
          END IF;
--
        END IF;
      END IF;
    END LOOP main_data_loop;
--
--
    -- ============================================================
    -- A-4.�T���f�[�^���o�̌Ăяo��
    -- ============================================================
    IF ( lv_get_data_flag = cv_y_flag ) THEN
      get_data(ov_errbuf           =>  lv_errbuf                                      -- �G���[�E���b�Z�[�W
              ,ov_retcode          =>  lv_retcode                                     -- ���^�[���E�R�[�h
              ,ov_errmsg           =>  lv_errmsg                                      -- ���[�U�[�E�G���[�E���b�Z�[�W
               );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- �f�[�^�擾�G���[�i�f�[�^0���j ***
    WHEN no_data_expt THEN
      ov_retcode := cv_status_warn;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_name
                   ,iv_name         => cv_data_get_msg
                   );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
      );
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( get_condition_data_cur%ISOPEN ) THEN
        CLOSE get_condition_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--##################################  �Œ蕔 END  ##################################
--
  END get_condition_data;
--
  /**********************************************************************************
   * Procedure Name   : condition_update
   * Description      : A-7.�T�����X�V
   ***********************************************************************************/
  PROCEDURE condition_update( ov_errbuf      OUT    VARCHAR2    -- �G���[�E���b�Z�[�W           -- # �Œ� #
                            , ov_retcode     OUT    VARCHAR2    -- ���^�[���E�R�[�h             -- # �Œ� #
                            , ov_errmsg      OUT    VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
                             )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'condition_update'; -- �v���O������
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �r������폜�p�J�[�\��
    CURSOR l_target_ctl_info_del_cur
    IS
      SELECT  eci.request_id
      FROM    xxcok_exclusive_ctl_info eci
      WHERE   eci.request_id  = gn_request_id
      FOR UPDATE NOWAIT
      ;
    l_target_ctl_info_del_rec    l_target_ctl_info_del_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ���b�N�G���[
    --

--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    -- �I�������������ɔ������Ă���T���f�[�^���폜
    --==============================================================
    -- �����Ώۃf�[�^��0���ȏ�̏ꍇ�X�V���������{����
    IF ( gt_condition_work_1_tbl.COUNT > 0 ) THEN
      BEGIN
        FORALL i IN 1..gt_condition_work_1_tbl.COUNT
          UPDATE xxcok_sales_deduction  xsd                                  -- �̔��T�����
          SET    xsd.status                  = cv_c_flag                                -- �X�e�[�^�X
                ,xsd.gl_if_flag              = CASE
                                                 WHEN xsd.gl_if_flag  = cv_n_flag THEN
                                                   cv_u_flag
                                                 ELSE
                                                   cv_r_flag
                                               END                                      -- GL�A�g�t���O
                ,xsd.recovery_del_date       = gd_proc_date                             -- ���J�o���[���t
                ,xsd.cancel_flag             = cv_y_flag                                -- �L�����Z���t���O
                ,xsd.recovery_del_request_id = cn_request_id                            -- ���J�o���f�[�^�폜���v��ID
                ,xsd.cancel_user             = cn_created_by                            -- ������[�UID
                ,xsd.last_updated_by         = cn_last_updated_by                       -- �ŏI�X�V��
                ,xsd.last_update_date        = cd_last_update_date                      -- �ŏI�X�V��
                ,xsd.last_update_login       = cn_last_update_login                     -- �ŏI�X�V���O�C��
                ,xsd.request_id              = cn_request_id                            -- �v��ID
                ,xsd.program_application_id  = cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v��ID
                ,xsd.program_id              = cn_program_id                            -- �R���J�����g�E�v���O����ID
                ,xsd.program_update_date     = cd_program_update_date                   -- �v���O�����X�V��
          WHERE  xsd.condition_id        = gt_condition_work_1_tbl(i).condition_id       -- �T������ID
          AND    xsd.condition_line_id   = gt_condition_work_1_tbl(i).condition_line_id  -- �T���ڍ�ID
          AND    xsd.record_date         > gt_condition_work_1_tbl(i).end_date_active    -- �����
          AND    xsd.recon_slip_num     IS NULL                                          -- �x���`�[�ԍ�
          AND    xsd.source_category    IN ( cv_s_flag ,cv_t_flag
                                            ,cv_v_flag ,cv_f_flag )                      -- �쐬���敪
          AND    xsd.gl_if_flag         IN ( cv_y_flag ,cv_n_flag )                      -- GL�A�g�t���O(Y:�A�g�ρAN:���A�g)
          AND    xsd.status              = cv_n_flag                                     -- �X�e�[�^�X(N�F�V�K)
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            ov_retcode := cv_status_error;
      END;
    END IF;
--
    --==============================================================
    -- �T�������e�[�u���̃f�[�^�X�V
    --==============================================================
    UPDATE xxcok_condition_header
    SET    header_recovery_flag = cv_n_flag
    WHERE  request_id           = gn_request_id
    ;
--
    --==============================================================
    -- �T���ڍ׃e�[�u���̃f�[�^�X�V
    --==============================================================
    UPDATE xxcok_condition_lines
    SET    line_recovery_flag   = cv_n_flag
    WHERE  request_id           = gn_request_id
    ;

    BEGIN
      -- �r������폜�p�J�[�\���I�[�v��
      OPEN  l_target_ctl_info_del_cur;
      FETCH l_target_ctl_info_del_cur INTO l_target_ctl_info_del_rec;
      CLOSE l_target_ctl_info_del_cur;
--
      --==============================================================
      -- �r������Ǘ��e�[�u���̃f�[�^�폜
      --==============================================================
      DELETE FROM xxcok_exclusive_ctl_info eci
      WHERE  eci.request_id  = gn_request_id
      ;
--
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        -- �J�[�\���N���[�Y
        IF ( l_target_ctl_info_del_cur%ISOPEN ) THEN
          CLOSE l_target_ctl_info_del_cur;
        END IF;
        -- ���b�N�G���[���b�Z�[�W
        ov_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_name
                                              ,cv_msg_lock_err
                                               );
        ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
        ov_retcode := cv_status_error;
      -- *** ���������ʗ�O�n���h�� ***
    END
    ;
--
  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END condition_update;
--
/**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000)      DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)         DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)      DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--#########################  �Œ�X�e�[�^�X�������� START  #########################
--
    ov_retcode := cv_status_normal;
--
--##################################  �Œ蕔 END  ##################################
--
    -- �O���[�o���ϐ��̏�����
    gn_del_target_cnt :=  0;
    gn_add_target_cnt :=  0;
    gn_del_cnt        :=  0;
    gn_add_cnt        :=  0;
    gn_cal_skip_cnt   :=  0;
    gn_del_skip_cnt   :=  0;
-- 2021/09/17 Ver1.4 ADD Start
    gn_del_ins_cnt    :=  0;
-- 2021/09/17 Ver1.4 ADD End
    gn_add_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init( ov_errbuf   =>  lv_errbuf                          -- �G���[�E���b�Z�[�W
         ,ov_retcode  =>  lv_retcode                         -- ���^�[���E�R�[�h
         ,ov_errmsg   =>  lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
         );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �T�����X�V�Ώے��o
    -- ===============================
    get_condition_data( ov_errbuf   =>  lv_errbuf            -- �G���[�E���b�Z�[�W
                       ,ov_retcode  =>  lv_retcode           -- ���^�[���E�R�[�h
                       ,ov_errmsg   =>  lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
                       );
--
    IF  ( lv_retcode  = cv_status_warn)  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-7  �T�����X�V
    -- ===============================
    condition_update( ov_errbuf   =>  lv_errbuf              -- �G���[�E���b�Z�[�W
                     ,ov_retcode  =>  lv_retcode             -- ���^�[���E�R�[�h
                     ,ov_errmsg   =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
                     );
--
    IF  ( lv_retcode  = cv_status_warn)  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--############################    �Œ��O������ START  ############################
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
--##################################  �Œ蕔 END  ##################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-8���܂�)
   **********************************************************************************/
--
  PROCEDURE main( errbuf        OUT    VARCHAR2         -- �G���[�E���b�Z�[�W  --# �Œ� #
                 ,retcode       OUT    VARCHAR2         -- ���^�[���E�R�[�h    --# �Œ� #
                 ,in_request_id IN     NUMBER           -- �v��ID
                 )
--
--#################################  �Œ蕔 START  #################################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(20)  := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';    -- �G���[�������b�Z�[�W
    cv_del_target_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10719';    -- �T���}�X�^�폜�Ώی���
    cv_add_target_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10720';    -- �T���}�X�^�o�^�Ώی���
    cv_del_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10721';    -- �T���f�[�^�폜����
    cv_add_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10722';    -- �T���f�[�^�o�^����
    cv_cal_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10723';    -- �T���f�[�^�T���z�Z�o�X�L�b�v����
    cv_del_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10724';    -- �T���f�[�^�폜�x���σX�L�b�v����
-- 2021/09/17 Ver1.4 ADD Start
    cv_del_ins_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10806';    -- �}�C�i�X�T���f�[�^�o�^����
-- 2021/09/17 Ver1.4 ADD End
    cv_add_skip_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10725';    -- �T���f�[�^�o�^�x���σX�L�b�v����
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';               -- �������b�Z�[�W�p�g�[�N����
    cv_data_no_get_msg CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';    -- �ΏۂȂ����b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';    -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';    -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';    -- �G���[�I���S���[���o�b�N
    cv_msg_cok_10593   CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10593';    -- �T���z�Z�o�G���[
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000)      DEFAULT NULL;    -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)         DEFAULT NULL;    -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)      DEFAULT NULL;    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)       DEFAULT NULL;    -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--#################################  �Œ蕔 START  #################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header( ov_retcode => lv_retcode
                                    ,ov_errbuf  => lv_errbuf
                                    ,ov_errmsg  => lv_errmsg
                                    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--##################################  �Œ蕔 END  ##################################
--
    -- ���̓p�����[�^��ϐ��Ɋi�[
    gn_request_id := in_request_id;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf                 -- �G���[�E���b�Z�[�W
            ,ov_retcode => lv_retcode                -- ���^�[���E�R�[�h
            ,ov_errmsg  => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
--
    -- ===============================
    -- A-8.�I������
    -- ===============================
    -- �G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf      -- �G���[���b�Z�[�W
      );
-- 2021/10/21 Ver1.5 ADD Start �x���σf�[�^�����݂���ꍇ�͌x��
    ELSE
      IF gn_add_skip_cnt > 0 or gn_del_ins_cnt > 0 THEN
         lv_retcode := cv_status_warn;
      END IF;
-- 2021/10/21 Ver1.5 END Start
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �G���[�̏ꍇ�A���������N���A
    IF ( lv_retcode = cv_status_error ) THEN
      gn_del_target_cnt := 0;                    -- �T���}�X�^�폜�Ώی���
      gn_add_target_cnt := 0;                    -- �T���}�X�^�o�^�Ώی���
      gn_del_cnt        := 0;                    -- �T���f�[�^�폜����
      gn_add_cnt        := 0;                    -- �T���f�[�^�o�^����
      gn_cal_skip_cnt   := 0;                    -- �T���f�[�^�T���z�Z�o�X�L�b�v����
      gn_del_skip_cnt   := 0;                    -- �T���f�[�^�폜�x���σX�L�b�v����
-- 2021/09/17 Ver1.4 ADD Start
      gn_del_ins_cnt    := 0;                    -- �T���f�[�^�폜�}�C�i�X�T���f�[�^�o�^����
-- 2021/09/17 Ver1.4 ADD End
      gn_add_skip_cnt   := 0;                    -- �T���f�[�^�o�^�x���σX�L�b�v����
      gn_error_cnt      := 1;                    -- �G���[����
    END IF;
--
    -- �T���}�X�^�폜�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_target_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �T���}�X�^�o�^�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_target_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �T���f�[�^�폜�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_cnt )

                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �T���f�[�^�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �T���f�[�^�T���z�Z�o�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_cal_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_cal_skip_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �T���f�[�^�폜�x���σX�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_skip_cnt )

                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2021/09/17 Ver1.4 ADD Start
    -- �T���f�[�^�폜�}�C�i�X�T���f�[�^�o�^�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_del_ins_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_del_ins_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2021/09/17 Ver1.4 ADD End    -- �T���f�[�^�o�^�x���σX�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcok_short_name
                    ,iv_name         => cv_add_skip_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_add_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_appl_short_name
                                           ,iv_name         => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
--##################################  �Œ蕔 END  ##################################
--
END XXCOK024A09C;
/
