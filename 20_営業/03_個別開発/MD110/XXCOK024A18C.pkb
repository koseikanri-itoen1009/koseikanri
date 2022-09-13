CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A18C (body)
 * Description      : �T���z�̎x���E�������E�f�[�^�����F���ꂽ�f�[�^��ΏۂɁA�T������������ɁA
 *                    �T����񂩂�����d����𒊏o����GL�d��̍쐬���A��ʉ�vOIF�ɘA�g���鏈��
 * MD.050           : �T���f�[�^���ώd����擾 MD050_COK_024_A18
 * Version          : 1.3
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.��������
 *  get_data               A-2.�̔��T���f�[�^���o
 *  edit_work_data         A-3.��ʉ�vOIF�W�񏈗�
 *  edit_gl_data           A-4.GL��ʉ�vOIF�f�[�^�쐬
 *  insert_gl_data         A-5.GL��ʉ�vOIF�f�[�^�C���T�[�g����
 *  up_ded_recon_data      A-6.�T�������w�b�_�[���X�V����
 *  get_gl_cancel_data     A-7.GL�d��f�[�^���o�i����j
 *  insert_gl_cancel_data  A-8.GL��ʉ�vOIF�f�[�^�C���T�[�g�����i����j
 *  up_recon_cancel_data   A-9.�T�������w�b�_�[���X�V�����i����j
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-10���܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/11/24    1.0   H.Ishii          �V�K�쐬
 *  2021/05/18    1.1   SCSK K.Yoshikawa GROUP_ID�ǉ��Ή�
 *  2022/07/20    1.2   SCSK Y.Koh       E_�{�ғ�_18509 �����ԑ��s�Ή�
 *  2022/09/06    1.3   SCSK Y.Koh       E_�{�ғ�_18172  �T���x���`�[������̍��z
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
  gv_out_msg       VARCHAR2(2000);                       -- �o�̓��b�Z�[�W
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- ���F�ς݂ƂȂ����x���`�[�P�ʂ̌���
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- ��ʉ�vOIF�ɍ쐬�����x���`�[�P�ʂ̌���
  gn_cancel_cnt    NUMBER   DEFAULT 0;                   -- ��ʉ�vOIF�ɍ쐬�����������x���`�[�P�ʂ̌���
  gn_error_cnt     NUMBER   DEFAULT 0;                   -- �G���[����
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A18C';                     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                            -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                 -- �Ɩ����t�擾�G���[
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                 -- ���b�N�G���[���b�Z�[�W�i�̔��T��TB�j
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10586';                 -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10587';                 -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_tkn_deduction_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10588';                 -- �̔��T�����
  cv_tkn_gloif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10589';                 -- ��ʉ�vOIF
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10578';                 -- ��v����ID
  cv_pro_bks_nm             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10579';                 -- ��v���떼��
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10580';                 -- ��ЃR�[�h
  cv_pro_dept_fin_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10624';                 -- ����R�[�h�i�����o�����j
  cv_pro_customer_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10625';                 -- �ڋq�R�[�h_�_�~�[�l
  cv_pro_comp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10626';                 -- ��ƃR�[�h_�_�~�[�l
  cv_pro_preliminary1_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10627';                 -- �\���P_�_�~�[�l
  cv_pro_preliminary2_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10628';                 -- �\���Q_�_�~�[�l
  cv_pro_category_cd_2      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10690';                 -- �d��J�e�S���i�T�������j
  cv_sales_deduction        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10650';                 -- �̔��T�����
  cv_tax_account_error_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10681';                 -- �ŏ��擾�G���[���b�Z�[�W
  cv_pro_org_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10669';                 -- �g�DID
--2021/05/18 add start
  cv_group_id_msg           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00024';                 -- �O���[�vID�擾�G���[
--2021/05/18 add end
--
  -- �g�[�N��
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';                         -- �v���t�@�C��
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';                      -- �e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';                        -- �L�[����
  -- �t���O�E�敪�萔
  cv_recon_status_ad        CONSTANT  VARCHAR2(2)  := 'AD';                              -- ���F��:AD
  cv_recon_status_cd        CONSTANT  VARCHAR2(2)  := 'CD';                              -- �����:CD
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';                               -- �t���O�l:Y
  cv_d_flag                 CONSTANT  VARCHAR2(1)  := 'D';                               -- �t���O�l:D
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';                               -- �t���O�l:N
  cv_o_flag                 CONSTANT  VARCHAR2(1)  := 'O';                               -- �t���O�l:O
  cv_r_flag                 CONSTANT  VARCHAR2(1)  := 'R';                               -- �t���O�l:R
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';                               -- �t���O�l:S
  cv_t_flag                 CONSTANT  VARCHAR2(1)  := 'T';                               -- �t���O�l:T
  cv_u_flag                 CONSTANT  VARCHAR2(1)  := 'U';                               -- �t���O�l:U
  cv_f_flag                 CONSTANT  VARCHAR2(1)  := 'F';                               -- �t���O�l:F
  cv_c_flag                 CONSTANT  VARCHAR2(1)  := 'C';                               -- �t���O�l:C
  cv_syuyaku_flag           CONSTANT  VARCHAR2(1)  := '*';                               -- �t���O�l:*
  cv_date_format_1          CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';                      -- �����t�H�[�}�b�gYYYY/MM/DD
  cv_dummy_date             CONSTANT  VARCHAR2(10) := '9999/12/31';                      -- DUMMY���t
  cv_date_format            CONSTANT  VARCHAR2(6)  := 'YYYYMM';                          -- �����t�H�[�}�b�gYYYYMM
  cv_source_name            CONSTANT  VARCHAR2(10) := '�T���쐬';                        -- �\�[�X��
  -- �N�C�b�N�R�[�h
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';      -- �T���f�[�^���
  cv_lookup_tax_conv_code   CONSTANT  VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';    -- ����ŃR�[�h�ϊ��}�X�^
  cv_period_set_name        CONSTANT  VARCHAR2(30) := 'SALES_CALENDAR';                  -- ��v�J�����_
  cv_lookup_chain_code      CONSTANT  VARCHAR2(20) := 'XXCMM_CHAIN_CODE';                -- �`�F�[���R�[�h�}�X�^
  -- ��ʉ�vOIF�e�[�u���ɐݒ肷��Œ�l
  cv_status                 CONSTANT  VARCHAR2(3)  := 'NEW';                             -- �X�e�[�^�X
  cv_currency_code          CONSTANT  VARCHAR2(3)  := 'JPY';                             -- �ʉ݃R�[�h
  cv_actual_flag            CONSTANT  VARCHAR2(1)  := 'A';                               -- �c���^�C�v
  cv_underbar               CONSTANT  VARCHAR2(1)  := '_';                               -- ���ڋ�؂�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �T������������[�N�e�[�u����`
  TYPE gr_recon_dedu_cancel_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE
     ,recon_slip_num            xxcok_deduction_recon_head.recon_slip_num%TYPE
     ,gl_date                   xxcok_deduction_recon_head.gl_date%TYPE
     ,b_name                    gl_je_batches.name%TYPE
     ,b_description             gl_je_batches.description%TYPE
     ,h_name                    gl_je_headers.name%TYPE
     ,h_description             gl_je_headers.description%TYPE
     ,period_name               gl_je_headers.period_name%TYPE
     ,user_je_source_name       gl_je_sources_tl.user_je_source_name%TYPE
     ,user_je_category_name     gl_je_categories_tl.user_je_category_name%TYPE
     ,segment1                  gl_code_combinations.segment1%TYPE
     ,segment2                  gl_code_combinations.segment2%TYPE
     ,segment3                  gl_code_combinations.segment3%TYPE
     ,segment4                  gl_code_combinations.segment4%TYPE
     ,segment5                  gl_code_combinations.segment5%TYPE
     ,segment6                  gl_code_combinations.segment6%TYPE
     ,segment7                  gl_code_combinations.segment7%TYPE
     ,segment8                  gl_code_combinations.segment8%TYPE
     ,l_description             gl_je_lines.description%TYPE
     ,entered_dr                gl_je_lines.entered_dr%TYPE
     ,entered_cr                gl_je_lines.entered_cr%TYPE
     ,tax_code                  gl_je_lines.attribute1%TYPE
     ,recon_slip_num_1          gl_je_lines.attribute3%TYPE
     ,context                   gl_je_lines.context%TYPE
  );
--
  -- �̔��T��������񃏁[�N�e�[�u����`
  TYPE gr_recon_deductions_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- �T�������w�b�_�[ID
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- �x���`�[�ԍ�
     ,interface_div             xxcok_deduction_recon_head.interface_div%TYPE             -- �A�g��
     ,data_type                 fnd_lookup_values.attribute2%TYPE                         -- �T���^�C�v
     ,gl_date                   xxcok_deduction_recon_head.gl_date%TYPE                   -- GL�L����
     ,period_name               gl_periods.period_name%TYPE                               -- ��v����
     ,recon_base_code           xxcok_sales_deduction.recon_base_code%TYPE                -- �������v�㋒�_
     ,deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- �T���z
     ,tax_code                  fnd_lookup_values.attribute1%TYPE                         -- �ŃR�[�h
     ,tax_rate                  xxcok_sales_deduction.tax_rate%TYPE                       -- �ŗ�
     ,deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- �T���Ŋz
     ,source_category           xxcok_sales_deduction.source_category%TYPE                -- �쐬���敪
     ,meaning                   fnd_lookup_values.meaning%TYPE                            -- ���e�i�f�[�^��ޖ��j
     ,account                   fnd_lookup_values.attribute4%TYPE                         -- ����Ȗ�
     ,sub_account               fnd_lookup_values.attribute5%TYPE                         -- �⏕�Ȗ�
     ,corp_code                 fnd_lookup_values.attribute1%TYPE                         -- ��ƃR�[�h
     ,customer_code             fnd_lookup_values.attribute4%TYPE                         -- �ڋq�R�[�h

  );
--
  -- ���z������񃏁[�N�e�[�u����`
  TYPE gr_recon_dedu_debt_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- �x���`�[�ԍ�
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- �x���`�[�ԍ�
     ,gl_date                   gl_periods.end_date%TYPE                                  -- GL�L����
     ,period_name               gl_periods.period_name%TYPE                               -- ��v����
     ,meaning                   fnd_lookup_values.meaning%TYPE                            -- ���e
     ,debt_account              fnd_lookup_values.attribute6%TYPE                         -- ������Ȗ�
     ,debt_sub_account          fnd_lookup_values.attribute7%TYPE                         -- ���⏕�Ȗ�
     ,interface_div             xxcok_deduction_recon_head.interface_div%TYPE             -- �A�g��
     ,debt_deduction_amount     xxcok_sales_deduction.deduction_amount%TYPE               -- ���z
  );
--
  TYPE gr_recon_work_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- �T�������w�b�_�[ID
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- �x���`�[�ԍ�
     ,period_name               gl_interface.period_name%TYPE                             -- ��v����
     ,accounting_date           gl_interface.accounting_date%TYPE                         -- �L����
     ,category_name             gl_interface.user_je_category_name%TYPE                   -- �J�e�S��
     ,base_code                 gl_interface.segment2%TYPE                                -- ����
     ,account                   fnd_lookup_values.attribute4%TYPE                         -- ����Ȗ�
     ,sub_account               fnd_lookup_values.attribute5%TYPE                         -- �⏕�Ȗ�
     ,corp_code                 gl_interface.segment6%TYPE                                -- ��ƃR�[�h
     ,customer_code             gl_interface.segment5%TYPE                                -- �ڋq�R�[�h
     ,entered_dr                gl_interface.entered_dr%TYPE                              -- �ؕ����z
     ,entered_cr                gl_interface.entered_cr%TYPE                              -- �ݕ����z
     ,tax_code                  gl_interface.attribute1%TYPE                              -- �ŃR�[�h
     ,reference10               gl_interface.reference10%TYPE                             -- �d�󖾍דE�v
  );
--
  -- ���[�N�e�[�u���^��`
  -- �T�������f�[�^
  TYPE g_recon_deductions_ttype     IS TABLE OF gr_recon_deductions_rec INDEX BY BINARY_INTEGER;
    gt_recon_deductions_tbl         g_recon_deductions_ttype;
--
  -- �T���������f�[�^
  TYPE g_recon_dedu_debt_ttype      IS TABLE OF gr_recon_dedu_debt_rec INDEX BY BINARY_INTEGER;
    gt_recon_dedu_debt_tbl        g_recon_dedu_debt_ttype;
--
  -- �T���������[�N�f�[�^
  TYPE g_recon_work_ttype           IS TABLE OF gr_recon_work_rec INDEX BY BINARY_INTEGER;
    gt_recon_work_tbl               g_recon_work_ttype;
--
  -- �T����������f�[�^
  TYPE g_recon_dedu_cancel_ttype    IS TABLE OF gr_recon_dedu_cancel_rec INDEX BY BINARY_INTEGER;
    gt_recon_dedu_cancel_tbl        g_recon_dedu_cancel_ttype;
--
  -- �̔��T���X�V�p���[�N�f�[�^
  TYPE g_deductions_ttype           IS TABLE OF xxcok_sales_deduction%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_deduction_tbl                g_deductions_ttype;
--
-- ��ʉ�vOIF
  TYPE g_gl_oif_ttype               IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_gl_interface_tbl             g_gl_oif_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
  gd_process_date                     DATE;                                         -- �Ɩ����t
  gn_org_id                           NUMBER;                                       -- �g�DID
  gn_set_bks_id                       NUMBER;                                       -- ��v����ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- ��v���떼��
  gv_company_code                     VARCHAR2(30);                                 -- ��ЃR�[�h
  gv_dept_fin_code                    VARCHAR2(30);                                 -- ����R�[�h�i�����o�����j
  gv_account_code                     VARCHAR2(30);                                 -- ����ȖڃR�[�h_���i�������j
  gv_sub_account_code                 VARCHAR2(30);                                 -- �⏕�ȖڃR�[�h_���i�������j
  gv_customer_code                    VARCHAR2(30);                                 -- �ڋq�R�[�h
  gv_comp_code                        VARCHAR2(30);                                 -- ��ƃR�[�h
  gv_preliminary1_code                VARCHAR2(30);                                 -- �\���P
  gv_preliminary2_code                VARCHAR2(30);                                 -- �\���Q
  gv_category_code2                   VARCHAR2(30);                                 -- �d��J�e�S���i�T�������j
  gv_accrued_account                  VARCHAR2(30);                                 -- �o�ߊ���Ȗ�
  gv_accrued_sub_account              VARCHAR2(30);                                 -- �o�ߊ���⏕�Ȗ�
--2021/05/18 add start
  gn_group_id                         NUMBER         DEFAULT NULL;                  -- �O���[�vID
--2021/05/18 add end
--
  -- �̔��T���������
  CURSOR recon_deductions_data_cur
  IS
    SELECT decode(source_category,cv_d_flag,deduction_recon_head_id,1)                                  deduction_recon_head_id  -- �T�������w�b�_�[ID
          ,carry_payment_slip_num                                                                       carry_payment_slip_num   -- �x���`�[�ԍ�
          ,decode(source_category,cv_d_flag,interface_div,cv_syuyaku_flag)                              interface_div            -- �A�g��
          ,decode(source_category,cv_d_flag,data_type,cv_syuyaku_flag)                                  data_type                -- �T���^�C�v
          ,decode(source_category,cv_d_flag,gl_date,TO_DATE(cv_dummy_date,cv_date_format_1))            gl_date                  -- GL�L����
          ,decode(source_category,cv_d_flag,period_name,cv_syuyaku_flag)                                period_name              -- ��v����
          ,decode(source_category,cv_d_flag,recon_base_code,cv_syuyaku_flag)                            recon_base_code          -- �������v�㋒�_
          ,SUM(NVL(deduction_amount,0))                                                                 deduction_amount         -- �T���z
          ,decode(source_category,cv_d_flag,tax_code,cv_syuyaku_flag)                                   tax_code                 -- �ŃR�[�h
          ,decode(source_category,cv_d_flag,tax_rate,1)                                                 tax_rate                 -- �ŗ�
          ,SUM(NVL(deduction_tax_amount,0))                                                             deduction_tax_amount     -- �T���Ŋz
          ,decode(source_category,cv_d_flag,source_category,cv_o_flag,source_category,cv_syuyaku_flag)  source_category          -- �쐬���敪
          ,decode(source_category,cv_d_flag,meaning,cv_syuyaku_flag)                                    meaning                  -- �f�[�^��ޖ�
          ,decode(source_category,cv_d_flag,account,cv_syuyaku_flag)                                    account                  -- ����Ȗ�
          ,decode(source_category,cv_d_flag,sub_account,cv_syuyaku_flag)                                sub_account              -- �⏕�Ȗ�
          ,decode(source_category,cv_d_flag,corp_code,cv_syuyaku_flag)                                  corp_code                -- ��ƃR�[�h
          ,decode(source_category,cv_d_flag,customer_code,cv_syuyaku_flag)                              customer_code            -- �ڋq�R�[�h
    FROM (
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- �T�������w�b�_�[ID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- �x���`�[�ԍ�
                ,drh.interface_div                             interface_div            -- �A�g��
                ,flv1.attribute2                               data_type                -- �f�[�^���
                ,gp.end_date                                   gl_date                  -- GL�L����
                ,gp.period_name                                period_name              -- ��v����
                ,xsd.recon_base_code                           recon_base_code          -- �������v�㋒�_
                ,xsd.deduction_amount                          deduction_amount         -- �T���z
                ,flv2.attribute1                               tax_code                 -- �ŃR�[�h
                ,xsd.tax_rate                                  tax_rate                 -- �ŗ�
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- �T���Ŋz
                ,xsd.source_category                           source_category          -- �쐬���敪
                ,flv1.meaning                                  meaning                  -- �f�[�^��ޖ�
                ,flv1.attribute4                               account                  -- ����Ȗ�
                ,flv1.attribute5                               sub_account              -- �⏕�Ȗ�
                ,NVL(flv3.attribute1,gv_comp_code)             corp_code                -- ��ƃR�[�h
                ,NVL(DECODE(xca.torihiki_form,'2',xsd.customer_code_to,flv3.attribute4),gv_customer_code)
                                                               customer_code            -- �ڋq�R�[�h
          FROM   xxcok_deduction_recon_head drh         -- �T�������w�b�_�[���
                ,xxcok_sales_deduction      xsd         -- �̔��T�����
                ,fnd_lookup_values          flv1        -- �N�C�b�N�R�[�h(�f�[�^���)
                ,xxcmm_cust_accounts        xca         -- �ڋq�ǉ����
                ,fnd_lookup_values          flv2        -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
                ,fnd_lookup_values          flv3        -- �N�C�b�N�R�[�h(�`�F�[���}�X�^)
                ,gl_periods                 gp          -- ��v���ԏ��
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- �����X�e�[�^�X�F���F��
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- �x���`�[�ԍ�
          AND    drh.gl_if_flag                            = cv_n_flag                      -- ����GL�A�g�t���O�FN
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- �T���f�[�^���
          AND    flv1.lookup_code                          = xsd.data_type                  -- �f�[�^���
          AND    flv1.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv1.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    xsd.customer_code_to                      = xca.customer_code              -- �U�֐�ڋq�R�[�h
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv2.lookup_code                          = xsd.tax_code                   -- �ŃR�[�h
          AND    flv2.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv2.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- �L���J�n��
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- �L���I����
          AND    flv3.lookup_type(+)                       = cv_lookup_chain_code           -- �`�F�[���R�[�h
          AND    flv3.lookup_code(+)                       = xca.intro_chain_code2          -- �`�F�[���R�[�h
          AND    flv3.enabled_flag(+)                      = cv_y_flag                      -- �g�p�\�FY
          AND    flv3.language(+)                          = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    NVL(flv3.start_date_active,drh.gl_date)  <= drh.gl_date                    -- �L���J�n��
          AND    NVL(flv3.end_date_active,drh.gl_date)    >= drh.gl_date                    -- �L���I����
          AND    gp.period_set_name                        = cv_period_set_name             -- ��v�J�����_
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- ��v���ԗL���J�n��
                                                         AND gp.end_date                    -- ��v���ԗL���I����
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- �������ԁFN
          AND    xsd.customer_code_to                 IS NOT NULL
          UNION ALL
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- �T�������w�b�_�[ID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- �x���`�[�ԍ�
                ,drh.interface_div                             interface_div            -- �A�g��
                ,flv1.attribute2                               data_type                -- �f�[�^���
                ,gp.end_date                                   gl_date                  -- GL�L����
                ,gp.period_name                                period_name              -- ��v����
                ,xsd.recon_base_code                           recon_base_code          -- �������v�㋒�_
                ,xsd.deduction_amount                          deduction_amount         -- �T���z
                ,flv2.attribute1                               tax_code                 -- �ŃR�[�h
                ,xsd.tax_rate                                  tax_rate                 -- �ŗ�
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- �T���Ŋz
                ,xsd.source_category                           source_category          -- �쐬���敪
                ,flv1.meaning                                  meaning                  -- �f�[�^��ޖ�
                ,flv1.attribute4                               account                  -- ����Ȗ�
                ,flv1.attribute5                               sub_account              -- �⏕�Ȗ�
                ,NVL(flv3.attribute1,gv_comp_code)             corp_code                -- ��ƃR�[�h
                ,NVL(flv3.attribute4,gv_customer_code)         customer_code            -- �ڋq�R�[�h
          FROM   xxcok_deduction_recon_head drh         -- �T�������w�b�_�[���
                ,xxcok_sales_deduction      xsd         -- �̔��T�����
                ,fnd_lookup_values          flv1        -- �N�C�b�N�R�[�h(�f�[�^���)
                ,fnd_lookup_values          flv2        -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
                ,fnd_lookup_values          flv3        -- �N�C�b�N�R�[�h(�`�F�[���}�X�^)
                ,gl_periods                 gp          -- ��v���ԏ��
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- �����X�e�[�^�X�F���F��
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- �x���`�[�ԍ�
          AND    drh.gl_if_flag                            = cv_n_flag                      -- ����GL�A�g�t���O�FN
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- �T���f�[�^���
          AND    flv1.lookup_code                          = xsd.data_type                  -- �f�[�^���
          AND    flv1.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv1.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv2.lookup_code                          = xsd.tax_code                   -- �ŃR�[�h
          AND    flv2.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv2.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- �L���J�n��
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- �L���I����
          AND    flv3.lookup_type                          = cv_lookup_chain_code           -- �`�F�[���R�[�h
          AND    flv3.lookup_code                          = xsd.deduction_chain_code       -- �`�F�[���R�[�h
          AND    flv3.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv3.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    NVL(flv3.start_date_active,drh.gl_date)  <= drh.gl_date                    -- �L���J�n��
          AND    NVL(flv3.end_date_active,drh.gl_date)    >= drh.gl_date                    -- �L���I����
          AND    gp.period_set_name                        = cv_period_set_name             -- ��v�J�����_
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- ��v���ԗL���J�n��
                                                         AND gp.end_date                    -- ��v���ԗL���I����
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- �������ԁFN
-- 2022/07/20 Ver1.2 ADD Start
          AND    xsd.customer_code_to     IS NULL
-- 2022/07/20 Ver1.2 ADD End
          AND    xsd.deduction_chain_code IS NOT NULL
          UNION ALL
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- �T�������w�b�_�[ID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- �x���`�[�ԍ�
                ,drh.interface_div                             interface_div            -- �A�g��
                ,flv1.attribute2                               data_type                -- �f�[�^���
                ,gp.end_date                                   gl_date                  -- GL�L����
                ,gp.period_name                                period_name              -- ��v����
                ,xsd.recon_base_code                           recon_base_code          -- �������v�㋒�_
                ,xsd.deduction_amount                          deduction_amount         -- �T���z
                ,flv2.attribute1                               tax_code                 -- �ŃR�[�h
                ,xsd.tax_rate                                  tax_rate                 -- �ŗ�
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- �T���Ŋz
                ,xsd.source_category                           source_category          -- �쐬���敪
                ,flv1.meaning                                  meaning                  -- �f�[�^��ޖ�
                ,flv1.attribute4                               account                  -- ����Ȗ�
                ,flv1.attribute5                               sub_account              -- �⏕�Ȗ�
                ,xsd.corp_code                                 corp_code                -- ��ƃR�[�h
                ,gv_customer_code                              customer_code            -- �ڋq�R�[�h
          FROM   xxcok_deduction_recon_head drh         -- �T�������w�b�_�[���
                ,xxcok_sales_deduction      xsd         -- �̔��T�����
                ,fnd_lookup_values          flv1        -- �N�C�b�N�R�[�h(�f�[�^���)
                ,fnd_lookup_values          flv2        -- �N�C�b�N�R�[�h(�ŃR�[�h�ϊ�)
                ,gl_periods                 gp          -- ��v���ԏ��
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- �����X�e�[�^�X�F���F��
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- �x���`�[�ԍ�
          AND    drh.gl_if_flag                            = cv_n_flag                      -- ����GL�A�g�t���O�FN
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- �T���f�[�^���
          AND    flv1.lookup_code                          = xsd.data_type                  -- �f�[�^���
          AND    flv1.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv1.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- ����ŃR�[�h�ϊ��}�X�^
          AND    flv2.lookup_code                          = xsd.tax_code                   -- �ŃR�[�h
          AND    flv2.enabled_flag                         = cv_y_flag                      -- �g�p�\�FY
          AND    flv2.language                             = USERENV('LANG')                -- ����FUSERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- �L���J�n��
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- �L���I����
          AND    gp.period_set_name                        = cv_period_set_name             -- ��v�J�����_
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- ��v���ԗL���J�n��
                                                         AND gp.end_date                    -- ��v���ԗL���I����
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- �������ԁFN
-- 2022/07/20 Ver1.2 ADD Start
          AND    xsd.customer_code_to     IS NULL
          AND    xsd.deduction_chain_code IS NULL
-- 2022/07/20 Ver1.2 ADD End
          AND    xsd.corp_code            IS NOT NULL
          )
    GROUP BY
           decode(source_category,cv_d_flag,deduction_recon_head_id,1)                                   -- �T�������w�b�_�[ID
          ,carry_payment_slip_num                                                                        -- �x���`�[�ԍ�
          ,decode(source_category,cv_d_flag,interface_div,cv_syuyaku_flag)                               -- �A�g��
          ,decode(source_category,cv_d_flag,data_type,cv_syuyaku_flag)                                   -- �T���^�C�v
          ,decode(source_category,cv_d_flag,gl_date,TO_DATE(cv_dummy_date,cv_date_format_1))             -- GL�L����
          ,decode(source_category,cv_d_flag,period_name,cv_syuyaku_flag)                                 -- ��v����
          ,decode(source_category,cv_d_flag,recon_base_code,cv_syuyaku_flag)                             -- �������v�㋒�_
          ,decode(source_category,cv_d_flag,tax_code,cv_syuyaku_flag)                                    -- �ŃR�[�h
          ,decode(source_category,cv_d_flag,tax_rate,1)                                                  -- �ŗ�
          ,decode(source_category,cv_d_flag,source_category,cv_o_flag,source_category,cv_syuyaku_flag)   -- �쐬���敪
          ,decode(source_category,cv_d_flag,meaning,cv_syuyaku_flag)                                     -- �f�[�^��ޖ�
          ,decode(source_category,cv_d_flag,account,cv_syuyaku_flag)                                     -- ����Ȗ�
          ,decode(source_category,cv_d_flag,sub_account,cv_syuyaku_flag)                                 -- �⏕�Ȗ�
          ,decode(source_category,cv_d_flag,corp_code,cv_syuyaku_flag)                                   -- ��ƃR�[�h
          ,decode(source_category,cv_d_flag,customer_code,cv_syuyaku_flag)                               -- �ڋq�R�[�h
    ORDER BY
           DECODE(source_category,cv_d_flag,1,2)                -- �쐬���敪
          ,carry_payment_slip_num                               -- �x���`�[�ԍ�
          ,tax_code                                             -- �ŃR�[�h
          ,data_type                                            -- �f�[�^���
          ,recon_base_code                                      -- ���������_�R�[�h
          ,account                                              -- ����Ȗ�
          ,sub_account                                          -- �⏕�Ȗ�
          ,corp_code                                            -- ��ƃR�[�h
          ,customer_code                                        -- �ڋq�R�[�h
    ;
--
  -- ���z�������
  CURSOR recon_dedu_debt_data_cur
  IS
    SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- �T�������w�b�_�[ID
          ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- �x���`�[�ԍ�
          ,gp.end_date                                   gl_date                  -- GL�L����
          ,gp.period_name                                period_name              -- ��v����
          ,flv1.meaning                                  meaning                  -- �f�[�^��ޖ�
          ,flv1.attribute6                               debt_account             -- ������Ȗ�
          ,flv1.attribute7                               debt_sub_account         -- ���⏕�Ȗ�
          ,drh.interface_div                             interface_div            -- �A�g��
          ,SUM(xsd.deduction_amount)                     debt_deducation_amount   -- ���z
    FROM   xxcok_deduction_recon_head drh         -- �T�������w�b�_�[���
          ,xxcok_sales_deduction      xsd         -- �̔��T�����
          ,fnd_lookup_values          flv1        -- �N�C�b�N�R�[�h(�f�[�^���)
          ,gl_periods                 gp          -- ��v���ԏ��
    WHERE  drh.recon_status           = cv_recon_status_ad             -- �����X�^�[�^�X�F���F��
    AND    drh.recon_slip_num         = xsd.carry_payment_slip_num     -- �x���`�[�ԍ�
    AND    drh.gl_if_flag             = cv_n_flag                      -- ����GL�A�g�t���O�FN
    AND    xsd.source_category        = cv_d_flag                            -- �쐬���敪:D(���z����)
    AND    flv1.lookup_type           = cv_lookup_dedu_code            -- �T���f�[�^���
    AND    flv1.lookup_code           = xsd.data_type                  -- �f�[�^���
    AND    flv1.enabled_flag          = cv_y_flag                      -- �g�p�\�FY
    AND    flv1.language              = USERENV('LANG')                -- ����FUSERENV('LANG')
    AND    gp.period_set_name         = cv_period_set_name             -- ��v�J�����_
    AND    drh.gl_date          BETWEEN gp.start_date                  -- ��v���ԗL���J�n��
                                    AND gp.end_date                    -- ��v���ԗL���I����
    AND    gp.adjustment_period_flag  = cv_n_flag                      -- �������ԁFN
    GROUP BY
           drh.deduction_recon_head_id                     -- �T�������w�b�_�[ID
          ,xsd.carry_payment_slip_num                      -- �x���`�[�ԍ�
          ,gp.end_date                                     -- GL�L����
          ,gp.period_name                                  -- ��v����
          ,flv1.attribute6                                 -- ������Ȗ�
          ,flv1.attribute7                                 -- ���⏕�Ȗ�
          ,flv1.meaning                                    -- �f�[�^��ޖ�
          ,drh.interface_div                               -- �A�g��

    ORDER BY
           xsd.carry_payment_slip_num                      -- �x���`�[�ԍ�
          ,flv1.attribute6                                 -- ������Ȗ�
          ,flv1.attribute7                                 -- ���⏕�Ȗ�
          ,flv1.meaning                                    -- �f�[�^��ޖ�
    ;
--
  -- �����d�����p�J�[�\��
  CURSOR recon_dedu_cancel_data_cur
  IS
    SELECT drh.deduction_recon_head_id  deduction_recon_head_id  -- �T�������w�b�_�[ID
          ,drh.recon_slip_num           recon_slip_num           -- �x���`�[�ԍ�
-- 2022/09/06 Ver1.3 MOD Start
          ,DECODE(drh.interface_div,'AP',drh.cancel_gl_date,'WP',drh.gl_date)
                                        gl_date                  -- ���GL�L����
--          ,LAST_DAY(drh.gl_date)        gl_date                  -- GL�L����
-- 2022/09/06 Ver1.3 MOD End
          ,gjb.name                     b_name                   -- �o�b�`��
          ,gjb.description              b_description            -- �o�b�`�E�v
          ,gjh.name                     h_name                   -- �d��
          ,gjh.description              h_description            -- �d��E�v
          ,gjh.period_name              period_name              -- ��v����
          ,gjs.user_je_source_name      user_je_source_name      -- �d��\�[�X��
          ,gjc.user_je_category_name    user_je_category_name    -- �d��J�e�S����
          ,gcc.segment1                 segment1                 -- ��ЃR�[�h
          ,gcc.segment2                 segment2                 -- ����R�[�h
          ,gcc.segment3                 segment3                 -- ����Ȗ�
          ,gcc.segment4                 segment4                 -- �⏕�Ȗ�
          ,gcc.segment5                 segment5                 -- �ڋq�R�[�h
          ,gcc.segment6                 segment6                 -- ��ƃR�[�h
          ,gcc.segment7                 segment7                 -- �\���P
          ,gcc.segment8                 segment8                 -- �\���Q
          ,gjl.description              l_description            -- �d�󖾍דE�v
          ,gjl.entered_dr               entered_dr               -- �ؕ����z
          ,gjl.entered_cr               entered_cr               -- �ݕ����z
          ,gjl.attribute1               tax_code                 -- �ŃR�[�h
          ,gjl.attribute3               recon_slip_num_1         -- �x���`�[�ԍ�
          ,gjl.context                  context                  -- �R���e�L�X�g
    FROM   xxcok_deduction_recon_head drh
          ,gl_je_batches              gjb
          ,gl_je_headers              gjh
          ,gl_je_lines                gjl
          ,gl_code_combinations       gcc
          ,gl_je_sources_tl           gjs
          ,gl_je_categories_tl        gjc
          ,gl_periods                 gp
    WHERE  drh.recon_status             = cv_recon_status_cd              -- �����X�^�[�^�X�F�����
    AND    drh.gl_if_flag              IN (cv_y_flag)                     -- ����GL�A�g�t���O
    AND    gjh.set_of_books_id          = gn_set_bks_id                   -- ��v����ID
    AND    gjl.code_combination_id      = gcc.code_combination_id         -- ����Ȗڑg��ID
    AND    gjh.je_header_id             = gjl.je_header_id                -- �d��w�b�_�[ID
    AND    drh.deduction_recon_head_id  = gjl.attribute8                  -- �T�������w�b�_�[ID
    AND    gjh.je_source                = gjs.je_source_name              -- �\�[�X��
    AND    gjs.language                 = USERENV('LANG')
    AND    gjh.je_category              = gjc.je_category_name
    AND    gjc.language                 = USERENV('LANG')
    AND    gjh.je_batch_id              = gjb.je_batch_id
    AND    gjs.user_je_source_name      = cv_source_name
    AND    gjc.user_je_category_name    = gv_category_code2
    AND    gp.period_set_name           = cv_period_set_name             -- ��v�J�����_
    AND    drh.gl_date            BETWEEN gp.start_date                  -- ��v���ԗL���J�n��
                                      AND gp.end_date                    -- ��v���ԗL���I����
    AND    gp.adjustment_period_flag    = cv_n_flag                      -- �������ԁFN
    AND    gp.period_name               = gjh.period_name                -- ��v����
    FOR UPDATE OF drh.deduction_recon_head_id NOWAIT
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';                     -- �v���O������
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
    cv_pro_bks_id_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
    cv_pro_bks_nm_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_NAME';               -- ��v���떼��
    cv_pro_org_id_1             CONSTANT VARCHAR2(40) := 'ORG_ID';                           -- XXCOK:�g�DID
    cv_pro_company_cd_1         CONSTANT VARCHAR2(40) := 'XXCOK1_AFF1_COMPANY_CODE';         -- XXCOK:��ЃR�[�h
    cv_pro_dept_fin_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF2_DEPT_FIN';             -- XXCOK:����R�[�h_�����o����
    cv_pro_customer_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- XXCOK:�ڋq�R�[�h_�_�~�[�l
    cv_pro_comp_cd_1            CONSTANT VARCHAR2(40) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- XXCOK:��ƃR�[�h_�_�~�[�l
    cv_pro_preliminary1_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- XXCOK:�\���P_�_�~�[�l:0
    cv_pro_preliminary2_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- XXCOK:�\���Q_�_�~�[�l:0
    cv_pro_category_cd_1_2      CONSTANT VARCHAR2(40) := 'XXCOK1_GL_CATEGORY_CONDITION2';    -- XXCOK:�d��J�e�S���i�T�������j
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name                   VARCHAR2(50);                                    -- �v���t�@�C����
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
    --==================================
    -- �P�D�Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ�̓G���[
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            , cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �Q�D�v���t�@�C���擾�F�g�DID
    --==================================
    gn_org_id := FND_PROFILE.VALUE( cv_pro_org_id_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_org_id                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �R�D�v���t�@�C���擾�F��v����ID
    -- ===============================
    gn_set_bks_id := FND_PROFILE.VALUE( cv_pro_bks_id_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_bks_id                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �S�D�v���t�@�C���擾�F��v���떼��
    -- ===============================
    gv_set_bks_nm := FND_PROFILE.VALUE( cv_pro_bks_nm_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_set_bks_nm IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_bks_nm                   -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �T�D�v���t�@�C���擾�F��ЃR�[�h
    --==================================
    gv_company_code := FND_PROFILE.VALUE( cv_pro_company_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_company_cd               -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �U�D�v���t�@�C���擾�F����R�[�h�i�����o�����j
    --==================================
    gv_dept_fin_code := FND_PROFILE.VALUE( cv_pro_dept_fin_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_dept_fin_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_dept_fin_cd              -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �V�D�v���t�@�C���擾�F�ڋq�R�[�h_�_�~�[�l
    --==================================
    gv_customer_code := FND_PROFILE.VALUE( cv_pro_customer_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_customer_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_customer_cd              -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �W�D�v���t�@�C���擾�F��ƃR�[�h_�_�~�[�l
    --==================================
    gv_comp_code := FND_PROFILE.VALUE( cv_pro_comp_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_comp_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_comp_cd                  -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �X�D�v���t�@�C���擾�F�\���P_�_�~�[�l
    --==================================
    gv_preliminary1_code := FND_PROFILE.VALUE( cv_pro_preliminary1_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_preliminary1_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_preliminary1_cd          -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�O�D�v���t�@�C���擾�F�\���Q_�_�~�[�l
    --==================================
    gv_preliminary2_code := FND_PROFILE.VALUE( cv_pro_preliminary2_cd_1 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_preliminary2_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_preliminary2_cd          -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �P�P�D�v���t�@�C���擾�F�d��J�e�S���i�T�������j
    --==================================
    gv_category_code2 := FND_PROFILE.VALUE( cv_pro_category_cd_1_2 );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_category_code2 IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- �A�v���P�[�V�����Z�k��
                                                 , iv_name        => cv_pro_category_cd_2            -- ���b�Z�[�WID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--2021/05/18 add start
    --==============================================================
    --�P�Q�D�O���[�vID���擾
    --==============================================================
    SELECT gjs.attribute1         AS group_id -- �O���[�vID
    INTO   gn_group_id
    FROM   gl_je_sources             gjs      -- �d��\�[�X�}�X�^
    WHERE  gjs.user_je_source_name = cv_source_name;
--
    IF ( gn_group_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_xxcok_short_nm
                                          , cv_group_id_msg
                                           );
      RAISE global_api_expt;
    END IF;

--2021/05/18 add end
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
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
   * Procedure Name   : get_data
   * Description      : A-2.�̔��T���f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
                    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name             VARCHAR2(255);                                  -- �e�[�u����
--
    -- *** ���[�J����O ***
    lock_expt                 EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�G���[
--
    -- *** ���[�J���E�J�[�\�� (�̔��T���f�[�^���o)***
   -- �T���������b�N���
   CURSOR l_recon_dedu_lock_data_cur
   IS
      SELECT drh.deduction_recon_head_id
      FROM   xxcok_deduction_recon_head drh
            ,xxcok_sales_deduction      xsd
      WHERE  drh.recon_status   = cv_recon_status_ad
      AND    drh.gl_if_flag     = cv_n_flag
      AND    drh.recon_slip_num = xsd.carry_payment_slip_num
      FOR UPDATE OF drh.deduction_recon_head_id NOWAIT
      ;
    recon_dedu_lock_data_rec         l_recon_dedu_lock_data_cur%ROWTYPE;

--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �̔��T���������J�[�\���I�[�v��
    OPEN  recon_deductions_data_cur;
    -- �f�[�^�擾
    FETCH recon_deductions_data_cur BULK COLLECT INTO gt_recon_deductions_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_deductions_data_cur;
--
    -- ���z�������J�[�\���I�[�v��
    OPEN  recon_dedu_debt_data_cur;
    -- �f�[�^�擾
    FETCH recon_dedu_debt_data_cur BULK COLLECT INTO gt_recon_dedu_debt_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_dedu_debt_data_cur;
--
    OPEN  l_recon_dedu_lock_data_cur;
    FETCH l_recon_dedu_lock_data_cur INTO recon_dedu_lock_data_rec;
    CLOSE l_recon_dedu_lock_data_cur;
--
  EXCEPTION
 --
    -- ���b�N�G���[
    WHEN lock_expt THEN
      IF ( l_recon_dedu_lock_data_cur%ISOPEN ) THEN
        CLOSE l_recon_dedu_lock_data_cur;
      END IF;
--
      -- ���b�N�G���[���b�Z�[�W
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- �A�v���P�[�V�����Z�k��
                                               , iv_name         => cv_tkn_deduction_msg           -- ���b�Z�[�WID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_table_lock_msg
                                                );
      lv_errbuf       := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_work_data
   * Description      : A-3.��ʉ�vOIF�W�񏈗�
   ***********************************************************************************/
  PROCEDURE edit_work_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           -- # �Œ� #
                          , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             -- # �Œ� #
                          , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_work_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_tax_dr                    CONSTANT VARCHAR2(10) := '����ōs';
    lv_tax_cr                    CONSTANT VARCHAR2(10) := '���ōs';
--
    -- *** ���[�J���ϐ� ***
    ln_deduction_amount_1        NUMBER DEFAULT 0;                               -- ����T��:���ۂ̔���T���z�W�v
    ln_deduction_tax_amount_1    NUMBER DEFAULT 0;                               -- ���������:���ۂ̉�������Ŋz�W�v
--
    ln_loop_index1               NUMBER DEFAULT 0;                               -- ���[�N�e�[�u���̔��T���C���f�b�N�X
    ln_loop_index2               NUMBER DEFAULT 0;                               -- �X�V�p�̔��T���C���f�b�N�X
    lv_account_code1             VARCHAR2(5);                                    -- ���ۂ̐ŃR�[�h����Ȗڗp
    lv_sub_account_code1         VARCHAR2(5);                                    -- ���ۂ̐ŃR�[�h�⏕�Ȗڗp
    lv_debt_account_code1        VARCHAR2(5);                                    -- ���ۂ̐ŃR�[�h������Ȗڗp
    lv_debt_sub_account_code1    VARCHAR2(5);                                    -- ���ۂ̐ŃR�[�h���⏕�Ȗڗp
--
    -- �W�v�L�[
    lt_dedu_recon_head_id        xxcok_deduction_recon_head.deduction_recon_head_id%TYPE;     -- �W�v�L�[�F���_�R�[�h(�����w�b�_�[ID)
    lt_recon_base_code           xxcok_sales_deduction.recon_base_code%TYPE;                  -- �W�v�L�[�F���_�R�[�h(�������v�㋒�_)
    lt_gl_date                   xxcok_deduction_recon_head.gl_date%TYPE;                     -- �W�v�L�[�FGL�L����
    lt_gl_period                 gl_periods.period_name%TYPE;                                 -- �W�v�L�[�F��v����
    lt_account                   fnd_lookup_values.attribute4%TYPE;                           -- �W�v�L�[�F����Ȗ�
    lt_sub_account               fnd_lookup_values.attribute5%TYPE;                           -- �W�v�L�[�F�⏕�Ȗ�
    lt_corp_code                 fnd_lookup_values.attribute1%TYPE;                           -- �W�v�L�[�F��ƃR�[�h
    lt_customer_code             fnd_lookup_values.attribute4%TYPE;                           -- �W�v�L�[�F�ڋq�R�[�h
    lt_tax_code                  xxcok_sales_deduction.tax_code%TYPE;                         -- �W�v�L�[�F�ŃR�[�h
    lt_tax_rate                  xxcok_sales_deduction.tax_rate%TYPE;                         -- �W�v�L�[�F�ŗ�
    lt_interface_div             xxcok_deduction_recon_head.interface_div%TYPE;               -- �W�v�L�[�F�A�g��
    lt_data_type                 fnd_lookup_values.attribute2%TYPE;                           -- �W�v�L�[�F�f�[�^���
    lt_carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE;           -- �W�v�L�[�F�x���`�[�ԍ�
    lt_meaning                   fnd_lookup_values.meaning%TYPE;                              -- �W�v�L�[�F�E�v
    lt_source_category           xxcok_sales_deduction.source_category%TYPE;                  -- �W�v�L�[�F�쐬���敪
--
    -- *** ���[�J����O ***
    edit_gl_expt                 EXCEPTION;                                      -- ��ʉ�v�쐬�G���[
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --=====================================
    -- 1.�d��p�^�[���̎擾
    --=====================================
    -- �u���C�N�p�W��L�[�̏�����
    lt_dedu_recon_head_id      := gt_recon_deductions_tbl(1).deduction_recon_head_id;            -- �����w�b�_�[ID
    lt_recon_base_code         := gt_recon_deductions_tbl(1).recon_base_code;                    -- �������v�㋒�_
    lt_gl_date                 := gt_recon_deductions_tbl(1).gl_date;                            -- GL�L����
    lt_gl_period               := gt_recon_deductions_tbl(1).period_name;                        -- ��v����
    lt_account                 := gt_recon_deductions_tbl(1).account;                            -- ����Ȗ�
    lt_sub_account             := gt_recon_deductions_tbl(1).sub_account;                        -- �⏕�Ȗ�
    lt_corp_code               := gt_recon_deductions_tbl(1).corp_code;                          -- ��ƃR�[�h
    lt_customer_code           := gt_recon_deductions_tbl(1).customer_code;                      -- �ڋq�R�[�h
    lt_tax_code                := gt_recon_deductions_tbl(1).tax_code;                           -- �ŃR�[�h
    lt_tax_rate                := gt_recon_deductions_tbl(1).tax_rate;                           -- �ŗ�
    lt_interface_div           := gt_recon_deductions_tbl(1).interface_div;                      -- �A�g��
    lt_data_type               := gt_recon_deductions_tbl(1).data_type;                          -- �T���^�C�v
    lt_carry_payment_slip_num  := gt_recon_deductions_tbl(1).carry_payment_slip_num;             -- �x���`�[�ԍ�
    lt_meaning                 := gt_recon_deductions_tbl(1).meaning;                            -- �f�[�^��ޖ�
    lt_source_category         := gt_recon_deductions_tbl(1).source_category;                    -- �쐬���敪
--
    -- �����T���f�[�^���[�v�X�^�[�g
    <<main_data_loop>>
    FOR i IN 1..gt_recon_deductions_tbl.COUNT LOOP
--
      -- ���������擾
      IF gn_target_cnt = 0 THEN
        gn_target_cnt     := gn_target_cnt + 1;
      ELSE
        IF  lt_carry_payment_slip_num != gt_recon_deductions_tbl(i).carry_payment_slip_num THEN
          IF  gt_recon_deductions_tbl(i).source_category != cv_syuyaku_flag THEN
            gn_target_cnt   := gn_target_cnt + 1;
          END IF;
        END IF;
      END IF;
--
      IF gt_recon_deductions_tbl(i).source_category = cv_o_flag THEN
        IF ln_loop_index2 = 0 THEN
          ln_loop_index2  := ln_loop_index2 + 1;
          gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num := gt_recon_deductions_tbl(i).carry_payment_slip_num;
        ELSE
          IF (gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num != gt_recon_deductions_tbl(i).carry_payment_slip_num) THEN
            ln_loop_index2  := ln_loop_index2 + 1;
             gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num := gt_recon_deductions_tbl(i).carry_payment_slip_num;
          END IF;
        END IF;
      END IF;
      -- ���z�����f�[�^�ȊO�̏ꍇ
      IF (lt_source_category != cv_d_flag ) THEN
        NULL;
--
      -- ���z�����f�[�^�A�c�������f�[�^(���֕���)�̏ꍇ
      ELSE
        -- ==========================
        --  ���R�[�h�u���C�N����
        -- ==========================
        -- ���������_�R�[�h/����Ȗ�/�⏕�Ȗ�/��ƃR�[�h/�ڋq�R�[�h/�ŃR�[�h/�T���^�C�v/�x���`�[�ԍ��̂����ꂩ���O�����f�[�^�قȂ����ꍇ
        IF ( lt_recon_base_code  <> gt_recon_deductions_tbl(i).recon_base_code )               -- ���������_�R�[�h
          OR  ( lt_account                <> gt_recon_deductions_tbl(i).account )                 -- ����Ȗ�
          OR  ( lt_sub_account            <> gt_recon_deductions_tbl(i).sub_account )             -- �⏕�Ȗ�
          OR  ( lt_corp_code              <> gt_recon_deductions_tbl(i).corp_code )               -- ��ƃR�[�h
          OR  ( lt_customer_code          <> gt_recon_deductions_tbl(i).customer_code )           -- �ڋq�R�[�h
          OR  ( lt_tax_code               <> gt_recon_deductions_tbl(i).tax_code )                -- �ŃR�[�h
          OR  ( lt_data_type              <> gt_recon_deductions_tbl(i).data_type )               -- �T���^�C�v
          OR  ( lt_carry_payment_slip_num <> gt_recon_deductions_tbl(i).carry_payment_slip_num )  -- �x���`�[�ԍ�
          OR  ( lt_source_category        <> gt_recon_deductions_tbl(i).source_category ) THEN    -- �쐬���敪
--
          ln_loop_index1 := ln_loop_index1 + 1;
--
          -- �T�������̍��z�����z�f�[�^�����[�N�e�[�u���ɑޔ�
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := lt_recon_base_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lt_account;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lt_sub_account;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := lt_corp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := lt_customer_code;
          IF ( ln_deduction_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr           := ln_deduction_amount_1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr           := NULL;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr           := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr           := NVL(ln_deduction_amount_1,0) * -1;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lt_recon_base_code || cv_underbar || lt_meaning
                                                                                           || cv_underbar || lt_tax_code;
--
          -- �T�������̍��z�����z�W��l������
          ln_deduction_amount_1 := 0;
--
        END IF;
--
        -- ==========================
        --  �ŃR�[�h�u���C�N����
        -- ==========================
        -- �ŃR�[�h/�x���`�[�ԍ��̂����ꂩ���O�����f�[�^�ƈقȂ�ꍇ
        IF ( lt_tax_code                   <> gt_recon_deductions_tbl(i).tax_code )                -- �ŃR�[�h
          OR  ( lt_carry_payment_slip_num  <> gt_recon_deductions_tbl(i).carry_payment_slip_num )  -- �x���`�[�ԍ�
          OR  ( lt_source_category         <> gt_recon_deductions_tbl(i).source_category ) THEN    -- �쐬���敪
--
          -- �Ŋ���Ȗڂ��擾(���ۂ̐Ŋ���ȖځA�ŕ⏕�Ȗ�)
          BEGIN
            SELECT gcc.segment3            -- �Ŋz_����Ȗ�
                  ,gcc.segment4            -- �Ŋz_�⏕�Ȗ�
                  ,tax.attribute5          -- ���Ŋz_����Ȗ�
                  ,tax.attribute6          -- ���Ŋz_�⏕�Ȗ�
            INTO   lv_account_code1
                  ,lv_sub_account_code1
                  ,lv_debt_account_code1
                  ,lv_debt_sub_account_code1
            FROM   apps.ap_tax_codes_all     tax  -- AP�ŃR�[�h�}�X�^
                  ,apps.gl_code_combinations gcc  -- ����g�����
            WHERE  tax.set_of_books_id     = gn_set_bks_id                  -- SET_OF_BOOKS_ID
            and    tax.org_id              = gn_org_id                      -- ORG_ID
            and    gcc.code_combination_id = tax.tax_code_combination_id    -- ��CCID
            and    tax.name                = lt_tax_code                    -- �ŃR�[�h
            AND    tax.enabled_flag        = cv_y_flag                      -- �L��
            ;
--
          EXCEPTION
            WHEN OTHERS THEN
            -- ����Ȗڂ��擾�o���Ȃ��ꍇ
              lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                    , cv_tax_account_error_msg
                                                     );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
--
          ln_loop_index1 := ln_loop_index1 + 1;
--
          -- �T�������̍��z������������ł����[�N�e�[�u���ɑޔ�
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lv_account_code1;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_sub_account_code1;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
          IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_tax_amount_1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_tax_amount_1,0) * -1;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_dr || cv_underbar || lt_tax_code;
--
          ln_loop_index1 := ln_loop_index1 + 1;

          -- ���z�������̕��i�������j_����ł����[�N�e�[�u���ɑޔ�
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lv_debt_account_code1;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_debt_sub_account_code1;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
          IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := ln_deduction_tax_amount_1;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(ln_deduction_tax_amount_1,0) * -1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_cr || cv_underbar || lt_tax_code;
--
          -- �T�������̍��z������������ŏW��l������
          ln_deduction_tax_amount_1 := 0;
--
        END IF;
--
        -- ���z�����f�[�^�̏ꍇ�A�T�������̍��z�����z�A�T�������̍��z������������ł����Z
        ln_deduction_amount_1      := ln_deduction_amount_1     + gt_recon_deductions_tbl(i).deduction_amount;
        ln_deduction_tax_amount_1  := ln_deduction_tax_amount_1 + gt_recon_deductions_tbl(i).deduction_tax_amount;
--
      END IF;
--
      -- �u���C�N�p�W��L�[�Z�b�g
      lt_dedu_recon_head_id      := gt_recon_deductions_tbl(i).deduction_recon_head_id; -- �T�������w�b�_�[ID
      lt_recon_base_code         := gt_recon_deductions_tbl(i).recon_base_code;         -- �������v�㋒�_
      lt_gl_date                 := gt_recon_deductions_tbl(i).gl_date;                 -- GL�L����
      lt_gl_period               := gt_recon_deductions_tbl(i).period_name;             -- ��v����
      lt_account                 := gt_recon_deductions_tbl(i).account;                 -- ����Ȗ�
      lt_sub_account             := gt_recon_deductions_tbl(i).sub_account;             -- �⏕�Ȗ�
      lt_corp_code               := gt_recon_deductions_tbl(i).corp_code;               -- ��ƃR�[�h
      lt_customer_code           := gt_recon_deductions_tbl(i).customer_code;           -- �ڋq�R�[�h
      lt_tax_code                := gt_recon_deductions_tbl(i).tax_code;                -- �ŃR�[�h
      lt_tax_rate                := gt_recon_deductions_tbl(i).tax_rate;                -- �ŗ�
      lt_data_type               := gt_recon_deductions_tbl(i).data_type;               -- �T���^�C�v
      lt_source_category         := gt_recon_deductions_tbl(i).source_category;         -- �쐬���敪
      lt_meaning                 := gt_recon_deductions_tbl(i).meaning;                 -- �f�[�^��ޖ�
      lt_carry_payment_slip_num  := gt_recon_deductions_tbl(i).carry_payment_slip_num;  -- �x���`�[�ԍ�
      lt_interface_div           := gt_recon_deductions_tbl(i).interface_div;           -- �A�g��
--
    END LOOP main_data_loop;
--
    IF (lt_source_category = cv_d_flag ) THEN
      -- �ŏI�s�o��
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- �T�������̍��z�����z�f�[�^�����[�N�e�[�u���ɑޔ�
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := lt_recon_base_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lt_account;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lt_sub_account;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := lt_corp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := lt_customer_code;
      IF ( ln_deduction_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_amount_1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_amount_1,0) * -1;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lt_recon_base_code || cv_underbar || lt_meaning
                                                                                       || cv_underbar || lt_tax_code;
--
      -- �Ŋ���Ȗڂ��擾(���ۂ̐Ŋ���ȖځA�ŕ⏕�Ȗ�)
      BEGIN
        SELECT gcc.segment3            -- �Ŋz_����Ȗ�
              ,gcc.segment4            -- �Ŋz_�⏕�Ȗ�
              ,tax.attribute5          -- ���Ŋz_����Ȗ�
              ,tax.attribute6          -- ���Ŋz_�⏕�Ȗ�
        INTO   lv_account_code1
              ,lv_sub_account_code1
              ,lv_debt_account_code1
              ,lv_debt_sub_account_code1
        FROM   apps.ap_tax_codes_all     tax  -- AP�ŃR�[�h�}�X�^
              ,apps.gl_code_combinations gcc  -- ����g�����
        WHERE  tax.set_of_books_id     = gn_set_bks_id                  -- SET_OF_BOOKS_ID
        and    tax.org_id              = gn_org_id                      -- ORG_ID
        and    gcc.code_combination_id = tax.tax_code_combination_id    -- ��CCID
        and    tax.name                = lt_tax_code                    -- �ŃR�[�h
        and    tax.enabled_flag        = cv_y_flag                      -- �L��
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
        -- ����Ȗڂ��擾�o���Ȃ��ꍇ
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                , cv_tax_account_error_msg
                                                 );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- �T�������̍��z������������ł����[�N�e�[�u���ɑޔ�
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lv_account_code1;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_sub_account_code1;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_tax_amount_1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_tax_amount_1,0) * -1;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_dr || cv_underbar || lt_tax_code;
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- ���z�������̕��i�������j_����ł����[�N�e�[�u���ɑޔ�
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lv_debt_account_code1;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_debt_sub_account_code1;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := ln_deduction_tax_amount_1;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(ln_deduction_tax_amount_1,0) * -1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_cr || cv_underbar || lt_tax_code;
    END IF;
--
    -- ���z�������̃��[�v�X�^�[�g
    <<recon_dedu_debt_loop>>
    FOR j IN 1..gt_recon_dedu_debt_tbl.COUNT LOOP
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- ���z�������̕���(������)�����[�N�e�[�u���ɑޔ�
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := gt_recon_dedu_debt_tbl(j).deduction_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := gt_recon_dedu_debt_tbl(j).carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := gt_recon_dedu_debt_tbl(j).gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := gt_recon_dedu_debt_tbl(j).period_name;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := gt_recon_dedu_debt_tbl(j).debt_account;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := gt_recon_dedu_debt_tbl(j).debt_sub_account;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( gt_recon_dedu_debt_tbl(j).debt_deduction_amount >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := gt_recon_dedu_debt_tbl(j).debt_deduction_amount;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(gt_recon_dedu_debt_tbl(j).debt_deduction_amount,0) * -1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
      gt_recon_work_tbl(ln_loop_index1).reference10              := gt_recon_dedu_debt_tbl(j).meaning;
--
    END LOOP recon_dedu_debt_loop;
--
  EXCEPTION
    WHEN edit_gl_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
--
  END edit_work_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_gl_data
   * Description      : A-4.��ʉ�vOIF�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE edit_gl_data( ov_errbuf          OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
                        , ov_retcode         OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
                        , ov_errmsg          OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                         )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'edit_gl_data';      -- �v���O������
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCFO';             -- ���ʗ̈�Z�k�A�v����
    cv_ccid_chk_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10052';  -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
    -- CCID
    cv_tkn_pro_date    CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';      -- �g�[�N���F������
    cv_tkn_com_code    CONSTANT VARCHAR2(20)  := 'COM_CODE';          -- �g�[�N���F��ЃR�[�h
    cv_tkn_dept_code   CONSTANT VARCHAR2(20)  := 'DEPT_CODE';         -- �g�[�N���F����R�[�h
    cv_tkn_acc_code    CONSTANT VARCHAR2(20)  := 'ACC_CODE';          -- �g�[�N���F����ȖڃR�[�h
    cv_tkn_ass_code    CONSTANT VARCHAR2(20)  := 'ASS_CODE';          -- �g�[�N���F�⏕�ȖڃR�[�h
    cv_tkn_cust_code   CONSTANT VARCHAR2(20)  := 'CUST_CODE';         -- �g�[�N���F�ڋq�R�[�h
    cv_tkn_ent_code    CONSTANT VARCHAR2(20)  := 'ENT_CODE';          -- �g�[�N���F��ƃR�[�h
    cv_tkn_res1_code   CONSTANT VARCHAR2(20)  := 'RES1_CODE';         -- �g�[�N���F�\���P�R�[�h
    cv_tkn_res2_code   CONSTANT VARCHAR2(20)  := 'RES2_CODE';         -- �g�[�N���F�\���Q�R�[�h
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_ccid_check            NUMBER;
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
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    --  ��ʉ�vOIF�f�[�^�쐬
    --==============================================================
--
    <<insert_data_loop>>
    FOR i IN 1..gt_recon_work_tbl.COUNT LOOP
--
      ln_ccid_check := NULL;
      --==============================================================
      -- CCID���݃`�F�b�N
      --==============================================================
      ln_ccid_check := xxcok_common_pkg.get_code_combination_id_f(
                                 id_proc_date => gd_process_date                       -- ������
                               , iv_segment1  => gv_company_code                       -- ��ЃR�[�h
                               , iv_segment2  => gt_recon_work_tbl(i).base_code        -- ����R�[�h
                               , iv_segment3  => gt_recon_work_tbl(i).account          -- ����ȖڃR�[�h
                               , iv_segment4  => gt_recon_work_tbl(i).sub_account      -- �⏕�ȖڃR�[�h
                               , iv_segment5  => gt_recon_work_tbl(i).customer_code    -- �ڋq�R�[�h
                               , iv_segment6  => gt_recon_work_tbl(i).corp_code        -- ��ƃR�[�h
                               , iv_segment7  => gv_preliminary1_code                  -- �\��1�_�~�[�l
                               , iv_segment8  => gv_preliminary2_code                  -- �\��2�_�~�[�l
                               );
--
      IF ( ln_ccid_check IS NULL ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxccp_appl_name
                        , iv_name         => cv_ccid_chk_msg                       -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_pro_date
                        , iv_token_value1 => gd_process_date                       -- ������
                        , iv_token_name2  => cv_tkn_com_code
                        , iv_token_value2 => gv_company_code                       -- ��ЃR�[�h
                        , iv_token_name3  => cv_tkn_dept_code
                        , iv_token_value3 => gt_recon_work_tbl(i).base_code        -- ����R�[�h
                        , iv_token_name4  => cv_tkn_acc_code
                        , iv_token_value4 => gt_recon_work_tbl(i).account          -- ����ȖڃR�[�h
                        , iv_token_name5  => cv_tkn_ass_code
                        , iv_token_value5 => gt_recon_work_tbl(i).sub_account      -- �⏕�ȖڃR�[�h
                        , iv_token_name6  => cv_tkn_cust_code
                        , iv_token_value6 => gt_recon_work_tbl(i).customer_code    -- �ڋq�R�[�h
                        , iv_token_name7  => cv_tkn_ent_code
                        , iv_token_value7 => gt_recon_work_tbl(i).corp_code        -- ��ƃR�[�h
                        , iv_token_name8  => cv_tkn_res1_code
                        , iv_token_value8 => gv_preliminary1_code                  -- �\��1�_�~�[�l
                        , iv_token_name9  => cv_tkn_res2_code
                        , iv_token_value9 => gv_preliminary2_code                  -- �\��2�_�~�[�l
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ��ʉ�vOIF�̒l�Z�b�g
      gt_gl_interface_tbl(i).status                := cv_status;                                                     -- �X�e�[�^�X
      gt_gl_interface_tbl(i).set_of_books_id       := gn_set_bks_id;                                                 -- ��v����ID
      gt_gl_interface_tbl(i).accounting_date       := gt_recon_work_tbl(i).accounting_date;                          -- �L����
      gt_gl_interface_tbl(i).currency_code         := cv_currency_code;                                              -- �ʉ݃R�[�h
      gt_gl_interface_tbl(i).actual_flag           := cv_actual_flag;                                                -- �c���^�C�v
      gt_gl_interface_tbl(i).user_je_category_name := gt_recon_work_tbl(i).category_name;                            -- �d��J�e�S����
      gt_gl_interface_tbl(i).user_je_source_name   := cv_source_name;                                                -- �d��\�[�X��
      gt_gl_interface_tbl(i).segment1              := gv_company_code;                                               -- (���)
      gt_gl_interface_tbl(i).segment2              := gt_recon_work_tbl(i).base_code;                                -- (����)
      gt_gl_interface_tbl(i).segment3              := gt_recon_work_tbl(i).account;                                  -- (����Ȗ�)
      gt_gl_interface_tbl(i).segment4              := gt_recon_work_tbl(i).sub_account;                              -- (�⏕�Ȗ�)
      gt_gl_interface_tbl(i).segment5              := gt_recon_work_tbl(i).customer_code;                            -- (�ڋq�R�[�h)
      gt_gl_interface_tbl(i).segment6              := gt_recon_work_tbl(i).corp_code;                                -- (��ƃR�[�h)
      gt_gl_interface_tbl(i).segment7              := gv_preliminary1_code;                                          -- (�\���P)
      gt_gl_interface_tbl(i).segment8              := gv_preliminary2_code;                                          -- (�\���Q)
      gt_gl_interface_tbl(i).entered_dr            := gt_recon_work_tbl(i).entered_dr;                               -- �ؕ����z
      gt_gl_interface_tbl(i).entered_cr            := gt_recon_work_tbl(i).entered_cr;                               -- �ݕ����z
      gt_gl_interface_tbl(i).reference1            := cv_source_name                      || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name    || cv_underbar ||
                                                      TO_CHAR(gd_process_date);                                      -- ���t�@�����X1�i�o�b�`���j
      gt_gl_interface_tbl(i).reference2            := cv_source_name                      || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name    || cv_underbar ||
                                                      TO_CHAR(gd_process_date);                                      -- ���t�@�����X2�i�o�b�`�E�v�j
      gt_gl_interface_tbl(i).reference4            := gt_recon_work_tbl(i).carry_payment_slip_num || cv_underbar ||
                                                      gt_recon_work_tbl(i).category_name          || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name;                              -- ���t�@�����X4�i�d�󖼁j
      gt_gl_interface_tbl(i).reference5            := gt_recon_work_tbl(i).carry_payment_slip_num || cv_underbar ||
                                                      gt_recon_work_tbl(i).category_name          || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name;                              -- ���t�@�����X5�i�d�󖼓E�v�j
      gt_gl_interface_tbl(i).reference10           := gt_recon_work_tbl(i).reference10;                              -- ���t�@�����X10�i�d�󖾍דE�v�j
      gt_gl_interface_tbl(i).period_name           := gt_recon_work_tbl(i).period_name;                              -- ��v����
--2021/05/18 add start
      gt_gl_interface_tbl(i).group_id              := gn_group_id;                                                   -- �O���[�vID
--2021/05/18 add end
      gt_gl_interface_tbl(i).attribute1            := gt_recon_work_tbl(i).tax_code;                                 -- ����1�i����ŃR�[�h�j
      gt_gl_interface_tbl(i).attribute3            := gt_recon_work_tbl(i).carry_payment_slip_num;                   -- ����3�i�x���`�[�ԍ��j
      gt_gl_interface_tbl(i).attribute8            := gt_recon_work_tbl(i).deduction_recon_head_id;                  -- ����8�i�T�������w�b�_�[ID�j
      gt_gl_interface_tbl(i).context               := gv_set_bks_nm;                                                 -- �R���e�L�X�g
      gt_gl_interface_tbl(i).created_by            := cn_created_by;                                                 -- �V�K�쐬��
      gt_gl_interface_tbl(i).date_created          := cd_creation_date;                                              -- �V�K�쐬��
      gt_gl_interface_tbl(i).request_id            := cn_request_id;                                                 -- �v��ID
--
   END LOOP insert_data_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
--
--#####################################  �Œ蕔 END  #####################################
--
  END edit_gl_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : A-5.GL��ʉ�vOIF�f�[�^�C���T�[�g����
   ***********************************************************************************/
  PROCEDURE insert_gl_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
                          , ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
                          , ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm           VARCHAR2(255);                -- �e�[�u����
--
    -- *** ���[�J����O ***
    insert_data_expt    EXCEPTION ;                   -- �o�^�����G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_gl_interface_tbl.COUNT
        INSERT INTO
          gl_interface
        VALUES
          gt_gl_interface_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE insert_data_expt;
    END;
--
    -- ��ʉ�vOIF�ɍ쐬�����������擾
    SELECT COUNT(DISTINCT gi.reference4)
    INTO   gn_normal_cnt
    FROM   gl_interface   gi
    WHERE  gi.request_id = cn_request_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm               -- �A�v���Z�k��
                      , iv_name              => cv_tkn_gloif_msg                -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2       => cv_tkn_key_data
                      , iv_token_value2      => NULL
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_gl_data;
--
  /***********************************************************************************
   * Procedure Name   : up_ded_recon_data
   * Description      : A-6.�T�������w�b�_�[���X�V����
   ***********************************************************************************/
  PROCEDURE up_ded_recon_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
                              ,ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(25) := 'up_ded_recon_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt2         NUMBER DEFAULT 0;     -- ���[�v�J�E���g�p�ϐ�
--
    -- *** ���[�J����O ***
    update_data_expt    EXCEPTION ;            -- �X�V�����G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    -- �T�������w�b�_�[���X�V����
    --==============================================================
--
    -- �����Ώۃf�[�^��GL�A�g�t���O���X�V
--
    -- ����f�[�^�X�V
    BEGIN
      UPDATE xxcok_deduction_recon_head     xdrh                                                                -- �T�������w�b�_�[���
      SET    xdrh.gl_if_flag               = cv_y_flag                                                          -- ����GL�A�g�t���O
            ,xdrh.last_updated_by          = cn_last_updated_by                                                 -- �ŏI�X�V��
            ,xdrh.last_update_date         = cd_last_update_date                                                -- �ŏI�X�V��
            ,xdrh.last_update_login        = cn_last_update_login                                               -- �ŏI�X�V���O�C��
            ,xdrh.request_id               = cn_request_id                                                      -- �v��ID
            ,xdrh.program_application_id   = cn_program_application_id                                          -- �R���J�����g�E�v���O�����E�A�v��ID
            ,xdrh.program_id               = cn_program_id                                                      -- �R���J�����g�E�v���O����ID
            ,xdrh.program_update_date      = cd_program_update_date                                             -- �v���O�����X�V��
      WHERE  xdrh.recon_status             = cv_recon_status_ad                                                 -- �����X�e�[�^�X:AD
      AND    xdrh.gl_if_flag               = cv_n_flag                                                          -- ����GL�A�g�t���O:N
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_data_expt;
    END;
--
    -- �̔��T�����̌J�z���x���`�[�ԍ��̍X�V
    BEGIN
      FORALL ln_loop_cnt2 IN 1..gt_deduction_tbl.COUNT
        UPDATE xxcok_sales_deduction xsd                         -- �̔��T�����
        SET    xsd.carry_payment_slip_num  = NULL                                                      -- �J�z���x���`�[�ԍ�
              ,xsd.last_updated_by         = cn_last_updated_by                                        -- �ŏI�X�V��
              ,xsd.last_update_date        = cd_last_update_date                                       -- �ŏI�X�V��
              ,xsd.last_update_login       = cn_last_update_login                                      -- �ŏI�X�V���O�C��
              ,xsd.request_id              = cn_request_id                                             -- �v��ID
              ,xsd.program_application_id  = cn_program_application_id                                 -- �R���J�����g�E�v���O�����E�A�v��ID
              ,xsd.program_id              = cn_program_id                                             -- �R���J�����g�E�v���O����ID
              ,xsd.program_update_date     = cd_program_update_date                                    -- �v���O�����X�V��
        WHERE  xsd.carry_payment_slip_num  = gt_deduction_tbl(ln_loop_cnt2).carry_payment_slip_num     -- �J�z���x���`�[�ԍ�
        AND    xsd.source_category         = cv_o_flag                                                 -- �쐬���敪�F�J�z����
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_data_expt;
    END;
--
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN update_data_expt THEN
      -- �X�V�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => cv_sales_deduction
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => NULL
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END up_ded_recon_data;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_cancel_data
   * Description      : A-7.GL�d��f�[�^���o�i����j
   ***********************************************************************************/
  PROCEDURE get_gl_cancel_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
                              , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
                              , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_gl_cancel_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name             VARCHAR2(255);                                  -- �e�[�u����
--
    -- *** ���[�J����O ***
    lock_expt                 EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ���b�N�G���[

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
    OPEN  recon_dedu_cancel_data_cur;
    -- �f�[�^�擾
    FETCH recon_dedu_cancel_data_cur BULK COLLECT INTO gt_recon_dedu_cancel_tbl;
    -- �J�[�\���N���[�Y
    CLOSE recon_dedu_cancel_data_cur;
--
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- ���b�N�G���[���b�Z�[�W
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- �A�v���P�[�V�����Z�k��
                                               , iv_name         => cv_tkn_deduction_msg           -- ���b�Z�[�WID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_table_lock_msg
                                                );
      lv_errbuf       := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END get_gl_cancel_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_cancel_data
   * Description      : A-8.GL��ʉ�vOIF�f�[�^�C���T�[�g�����i����j
   ***********************************************************************************/
  PROCEDURE insert_gl_cancel_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
                                 , ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
                                 , ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_cancel_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_cancel  CONSTANT VARCHAR2(100) := '���_'; -- ���
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm           VARCHAR2(255);                -- �e�[�u����
    lv_closing_status   VARCHAR2(1) DEFAULT NULL;     -- �N���[�W���O�X�e�[�^�X
    lv_period_name      VARCHAR2(8) DEFAULT NULL;     -- ��v����
    ld_gl_date          DATE;                         -- ��v���t
--
    -- *** ���[�J����O ***
    insert_data_expt    EXCEPTION ;                   -- �o�^�����G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    <<recon_dedu_loop>>
    FOR i IN 1..gt_recon_dedu_cancel_tbl.COUNT LOOP
--
-- 2022/09/06 Ver1.3 MOD Start
      ld_gl_date  :=  gt_recon_dedu_cancel_tbl(i).gl_date;
--
      SELECT gps.period_name
      INTO   lv_period_name
      FROM   gl_period_statuses  gps
      WHERE  gps.set_of_books_id        =   gn_set_bks_id
      AND    gps.start_date             <=  ld_gl_date
      AND    gps.end_date               >=  ld_gl_date
      AND    gps.application_id         =   101
      AND    gps.adjustment_period_flag =   cv_n_flag
      AND    gps.closing_status         =   cv_o_flag
      ;
--
--      -- ��v���Ԃ��N���[�W���O�X�e�[�^�X���擾
--      SELECT gps.closing_status
--      INTO   lv_closing_status
--      FROM   gl_period_statuses  gps
--      WHERE  gps.set_of_books_id        = gn_set_bks_id
--      AND    gps.period_name            = gt_recon_dedu_cancel_tbl(i).period_name
--      AND    gps.application_id         = 101
--      AND    gps.adjustment_period_flag = cv_n_flag
--      ;
----
--      -- �N���[�W���O�X�e�[�^�X���uC:�N���[�Y�v�̏ꍇ
--      IF (lv_closing_status = cv_c_flag) THEN
----
--        -- ���߂̃I�[�v�����Ă����v���ԁA�I�������擾
--        SELECT MIN(gps.period_name)
--              ,MIN(gps.end_date)
--        INTO   lv_period_name
--              ,ld_gl_date
--        FROM   gl_period_statuses  gps
--        WHERE  gps.set_of_books_id        = gn_set_bks_id
--        AND    gps.end_date               > gt_recon_dedu_cancel_tbl(i).gl_date
--        AND    gps.application_id         = 101
--        AND    gps.adjustment_period_flag = cv_n_flag
--        AND    gps.closing_status         = cv_o_flag
--        ;
--      ELSE
--        lv_period_name  := gt_recon_dedu_cancel_tbl(i).period_name;
--        ld_gl_date      := gt_recon_dedu_cancel_tbl(i).gl_date;
--      END IF;
-- 2022/09/06 Ver1.3 MOD End
--
      BEGIN
        INSERT INTO gl_interface(
          status                             -- STATUS
         ,set_of_books_id                    -- SET_OF_BOOKS_ID
         ,accounting_date                    -- ACCOUNTING_DATE
         ,currency_code                      -- CURRENCY_CODE
         ,date_created                       -- DATE_CREATED
         ,created_by                         -- CREATED_BY
         ,actual_flag                        -- ACTUAL_FLAG
         ,user_je_category_name              -- USER_JE_CATEGORY_NAME
         ,user_je_source_name                -- USER_JE_SOURCE_NAME
         ,currency_conversion_date           -- CURRENCY_CONVERSION_DATE
         ,encumbrance_type_id                -- ENCUMBRANCE_TYPE_ID
         ,budget_version_id                  -- BUDGET_VERSION_ID
         ,user_currency_conversion_type      -- USER_CURRENCY_CONVERSION_TYPE
         ,currency_conversion_rate           -- CURRENCY_CONVERSION_RATE
         ,average_journal_flag               -- AVERAGE_JOURNAL_FLAG
         ,originating_bal_seg_value          -- ORIGINATING_BAL_SEG_VALUE
         ,segment1                           -- SEGMENT1
         ,segment2                           -- SEGMENT2
         ,segment3                           -- SEGMENT3
         ,segment4                           -- SEGMENT4
         ,segment5                           -- SEGMENT5
         ,segment6                           -- SEGMENT6
         ,segment7                           -- SEGMENT7
         ,segment8                           -- SEGMENT8
         ,segment9                           -- SEGMENT9
         ,segment10                          -- SEGMENT10
         ,segment11                          -- SEGMENT11
         ,segment12                          -- SEGMENT12
         ,segment13                          -- SEGMENT13
         ,segment14                          -- SEGMENT14
         ,segment15                          -- SEGMENT15
         ,segment16                          -- SEGMENT16
         ,segment17                          -- SEGMENT17
         ,segment18                          -- SEGMENT18
         ,segment19                          -- SEGMENT19
         ,segment20                          -- SEGMENT20
         ,segment21                          -- SEGMENT21
         ,segment22                          -- SEGMENT22
         ,segment23                          -- SEGMENT23
         ,segment24                          -- SEGMENT24
         ,segment25                          -- SEGMENT25
         ,segment26                          -- SEGMENT26
         ,segment27                          -- SEGMENT27
         ,segment28                          -- SEGMENT28
         ,segment29                          -- SEGMENT29
         ,segment30                          -- SEGMENT30
         ,entered_dr                         -- ENTERED_DR
         ,entered_cr                         -- ENTERED_CR
         ,accounted_dr                       -- ACCOUNTED_DR
         ,accounted_cr                       -- ACCOUNTED_CR
         ,transaction_date                   -- TRANSACTION_DATE
         ,reference1                         -- REFERENCE1
         ,reference2                         -- REFERENCE2
         ,reference3                         -- REFERENCE3
         ,reference4                         -- REFERENCE4
         ,reference5                         -- REFERENCE5
         ,reference6                         -- REFERENCE6
         ,reference7                         -- REFERENCE7
         ,reference8                         -- REFERENCE8
         ,reference9                         -- REFERENCE9
         ,reference10                        -- REFERENCE10
         ,reference11                        -- REFERENCE11
         ,reference12                        -- REFERENCE12
         ,reference13                        -- REFERENCE13
         ,reference14                        -- REFERENCE14
         ,reference15                        -- REFERENCE15
         ,reference16                        -- REFERENCE16
         ,reference17                        -- REFERENCE17
         ,reference18                        -- REFERENCE18
         ,reference19                        -- REFERENCE19
         ,reference20                        -- REFERENCE20
         ,reference21                        -- REFERENCE21
         ,reference22                        -- REFERENCE22
         ,reference23                        -- REFERENCE23
         ,reference24                        -- REFERENCE24
         ,reference25                        -- REFERENCE25
         ,reference26                        -- REFERENCE26
         ,reference27                        -- REFERENCE27
         ,reference28                        -- REFERENCE28
         ,reference29                        -- REFERENCE29
         ,reference30                        -- REFERENCE30
         ,je_batch_id                        -- JE_BATCH_ID
         ,period_name                        -- PERIOD_NAME
         ,je_header_id                       -- JE_HEADER_ID
         ,je_line_num                        -- JE_LINE_NUM
         ,chart_of_accounts_id               -- CHART_OF_ACCOUNTS_ID
         ,functional_currency_code           -- FUNCTIONAL_CURRENCY_CODE
         ,code_combination_id                -- CODE_COMBINATION_ID
         ,date_created_in_gl                 -- DATE_CREATED_IN_GL
         ,warning_code                       -- WARNING_CODE
         ,status_description                 -- STATUS_DESCRIPTION
         ,stat_amount                        -- STAT_AMOUNT
         ,group_id                           -- GROUP_ID
         ,request_id                         -- REQUEST_ID
         ,subledger_doc_sequence_id          -- SUBLEDGER_DOC_SEQUENCE_ID
         ,subledger_doc_sequence_value       -- SUBLEDGER_DOC_SEQUENCE_VALUE
         ,attribute1                         -- ATTRIBUTE1
         ,attribute2                         -- ATTRIBUTE2
         ,gl_sl_link_id                      -- GL_SL_LINK_ID
         ,gl_sl_link_table                   -- GL_SL_LINK_TABLE
         ,attribute3                         -- ATTRIBUTE3
         ,attribute4                         -- ATTRIBUTE4
         ,attribute5                         -- ATTRIBUTE5
         ,attribute6                         -- ATTRIBUTE6
         ,attribute7                         -- ATTRIBUTE7
         ,attribute8                         -- ATTRIBUTE8
         ,attribute9                         -- ATTRIBUTE9
         ,attribute10                        -- ATTRIBUTE10
         ,attribute11                        -- ATTRIBUTE11
         ,attribute12                        -- ATTRIBUTE12
         ,attribute13                        -- ATTRIBUTE13
         ,attribute14                        -- ATTRIBUTE14
         ,attribute15                        -- ATTRIBUTE15
         ,attribute16                        -- ATTRIBUTE16
         ,attribute17                        -- ATTRIBUTE17
         ,attribute18                        -- ATTRIBUTE18
         ,attribute19                        -- ATTRIBUTE19
         ,attribute20                        -- ATTRIBUTE20
         ,context                            -- CONTEXT
         ,context2                           -- CONTEXT2
         ,invoice_date                       -- INVOICE_DATE
         ,tax_code                           -- TAX_CODE
         ,invoice_identifier                 -- INVOICE_IDENTIFIER
         ,invoice_amount                     -- INVOICE_AMOUNT
         ,context3                           -- CONTEXT3
         ,ussgl_transaction_code             -- USSGL_TRANSACTION_CODE
         ,descr_flex_error_message           -- DESCR_FLEX_ERROR_MESSAGE
         ,jgzz_recon_ref                     -- JGZZ_RECON_REF
         ,reference_date                     -- REFERENCE_DATE
        )VALUES(
          cv_status                                               -- STATUS
         ,gn_set_bks_id                                           -- SET_OF_BOOKS_ID
         ,ld_gl_date                                              -- ACCOUNTING_DATE
         ,cv_currency_code                                        -- CURRENCY_CODE
         ,cd_creation_date                                        -- DATE_CREATED
         ,cn_created_by                                           -- CREATED_BY
         ,cv_actual_flag                                          -- ACTUAL_FLAG
         ,gt_recon_dedu_cancel_tbl(i).user_je_category_name       -- USER_JE_CATEGORY_NAME
         ,gt_recon_dedu_cancel_tbl(i).user_je_source_name         -- USER_JE_SOURCE_NAME
         ,NULL                                                    -- CURRENCY_CONVERSION_DATE
         ,NULL                                                    -- ENCUMBRANCE_TYPE_ID
         ,NULL                                                    -- BUDGET_VERSION_ID
         ,NULL                                                    -- USER_CURRENCY_CONVERSION_TYPE
         ,NULL                                                    -- CURRENCY_CONVERSION_RATE
         ,NULL                                                    -- AVERAGE_JOURNAL_FLAG
         ,NULL                                                    -- ORIGINATING_BAL_SEG_VALUE
         ,gt_recon_dedu_cancel_tbl(i).segment1                    -- SEGMENT1
         ,gt_recon_dedu_cancel_tbl(i).segment2                    -- SEGMENT2
         ,gt_recon_dedu_cancel_tbl(i).segment3                    -- SEGMENT3
         ,gt_recon_dedu_cancel_tbl(i).segment4                    -- SEGMENT4
         ,gt_recon_dedu_cancel_tbl(i).segment5                    -- SEGMENT5
         ,gt_recon_dedu_cancel_tbl(i).segment6                    -- SEGMENT6
         ,gt_recon_dedu_cancel_tbl(i).segment7                    -- SEGMENT7
         ,gt_recon_dedu_cancel_tbl(i).segment8                    -- SEGMENT8
         ,NULL                                                    -- SEGMENT9
         ,NULL                                                    -- SEGMENT10
         ,NULL                                                    -- SEGMENT11
         ,NULL                                                    -- SEGMENT12
         ,NULL                                                    -- SEGMENT13
         ,NULL                                                    -- SEGMENT14
         ,NULL                                                    -- SEGMENT15
         ,NULL                                                    -- SEGMENT16
         ,NULL                                                    -- SEGMENT17
         ,NULL                                                    -- SEGMENT18
         ,NULL                                                    -- SEGMENT19
         ,NULL                                                    -- SEGMENT20
         ,NULL                                                    -- SEGMENT21
         ,NULL                                                    -- SEGMENT22
         ,NULL                                                    -- SEGMENT23
         ,NULL                                                    -- SEGMENT24
         ,NULL                                                    -- SEGMENT25
         ,NULL                                                    -- SEGMENT26
         ,NULL                                                    -- SEGMENT27
         ,NULL                                                    -- SEGMENT28
         ,NULL                                                    -- SEGMENT29
         ,NULL                                                    -- SEGMENT30
         ,gt_recon_dedu_cancel_tbl(i).entered_cr                  -- ENTERED_DR
         ,gt_recon_dedu_cancel_tbl(i).entered_dr                  -- ENTERED_CR
         ,NULL                                                    -- ACCOUNTED_DR
         ,NULL                                                    -- ACCOUNTED_CR
         ,NULL                                                    -- TRANSACTION_DATE
         ,gt_recon_dedu_cancel_tbl(i).b_description               -- REFERENCE1
         ,gt_recon_dedu_cancel_tbl(i).b_description               -- REFERENCE2
         ,NULL                                                    -- REFERENCE3
         ,lv_cancel ||gt_recon_dedu_cancel_tbl(i).h_description   -- REFERENCE4
         ,lv_cancel ||gt_recon_dedu_cancel_tbl(i).h_description   -- REFERENCE5
         ,NULL                                                    -- REFERENCE6
         ,NULL                                                    -- REFERENCE7
         ,NULL                                                    -- REFERENCE8
         ,NULL                                                    -- REFERENCE9
         ,gt_recon_dedu_cancel_tbl(i).l_description               -- REFERENCE10
         ,NULL                                                    -- REFERENCE11
         ,NULL                                                    -- REFERENCE12
         ,NULL                                                    -- REFERENCE13
         ,NULL                                                    -- REFERENCE14
         ,NULL                                                    -- REFERENCE15
         ,NULL                                                    -- REFERENCE16
         ,NULL                                                    -- REFERENCE17
         ,NULL                                                    -- REFERENCE18
         ,NULL                                                    -- REFERENCE19
         ,NULL                                                    -- REFERENCE20
         ,NULL                                                    -- REFERENCE21
         ,NULL                                                    -- REFERENCE22
         ,NULL                                                    -- REFERENCE23
         ,NULL                                                    -- REFERENCE24
         ,NULL                                                    -- REFERENCE25
         ,NULL                                                    -- REFERENCE26
         ,NULL                                                    -- REFERENCE27
         ,NULL                                                    -- REFERENCE28
         ,NULL                                                    -- REFERENCE29
         ,NULL                                                    -- REFERENCE30
         ,NULL                                                    -- JE_BATCH_ID
         ,lv_period_name                                          -- PERIOD_NAME
         ,NULL                                                    -- JE_HEADER_ID
         ,NULL                                                    -- JE_LINE_NUM
         ,NULL                                                    -- CHART_OF_ACCOUNTS_ID
         ,NULL                                                    -- FUNCTIONAL_CURRENCY_CODE
         ,NULL                                                    -- CODE_COMBINATION_ID
         ,NULL                                                    -- DATE_CREATED_IN_GL
         ,NULL                                                    -- WARNING_CODE
         ,NULL                                                    -- STATUS_DESCRIPTION
         ,NULL                                                    -- STAT_AMOUNT
--2021/05/18 mod start
--         ,NULL                                                    -- GROUP_ID
         ,gn_group_id                                             -- GROUP_ID
--2021/05/18 mod end
         ,cn_request_id                                           -- REQUEST_ID
         ,NULL                                                    -- SUBLEDGER_DOC_SEQUENCE_ID
         ,NULL                                                    -- SUBLEDGER_DOC_SEQUENCE_VALUE
         ,gt_recon_dedu_cancel_tbl(i).tax_code                    -- ATTRIBUTE1
         ,NULL                                                    -- ATTRIBUTE2
         ,NULL                                                    -- GL_SL_LINK_ID
         ,NULL                                                    -- GL_SL_LINK_TABLE
         ,gt_recon_dedu_cancel_tbl(i).recon_slip_num_1            -- ATTRIBUTE3
         ,NULL                                                    -- ATTRIBUTE4
         ,NULL                                                    -- ATTRIBUTE5
         ,NULL                                                    -- ATTRIBUTE6
         ,NULL                                                    -- ATTRIBUTE7
         ,gt_recon_dedu_cancel_tbl(i).deduction_recon_head_id     -- ATTRIBUTE8
         ,NULL                                                    -- ATTRIBUTE9
         ,NULL                                                    -- ATTRIBUTE10
         ,NULL                                                    -- ATTRIBUTE11
         ,NULL                                                    -- ATTRIBUTE12
         ,NULL                                                    -- ATTRIBUTE13
         ,NULL                                                    -- ATTRIBUTE14
         ,NULL                                                    -- ATTRIBUTE15
         ,NULL                                                    -- ATTRIBUTE16
         ,NULL                                                    -- ATTRIBUTE17
         ,NULL                                                    -- ATTRIBUTE18
         ,NULL                                                    -- ATTRIBUTE19
         ,NULL                                                    -- ATTRIBUTE20
         ,gt_recon_dedu_cancel_tbl(i).context                     -- CONTEXT
         ,NULL                                                    -- CONTEXT2
         ,NULL                                                    -- INVOICE_DATE
         ,NULL                                                    -- TAX_CODE
         ,NULL                                                    -- INVOICE_IDENTIFIER
         ,NULL                                                    -- INVOICE_AMOUNT
         ,NULL                                                    -- CONTEXT3
         ,NULL                                                    -- USSGL_TRANSACTION_CODE
         ,NULL                                                    -- DESCR_FLEX_ERROR_MESSAGE
         ,NULL                                                    -- JGZZ_RECON_REF
         ,NULL                                                    -- REFERENCE_DATE
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          RAISE insert_data_expt;
      END;
--
    END LOOP recon_dedu_loop;
--
    -- ��ʉ�vOIF�ɍ쐬�����������擾
    SELECT COUNT(DISTINCT gi.reference4)
    INTO   gn_cancel_cnt
    FROM   gl_interface   gi
    WHERE  gi.request_id                = cn_request_id
    AND    SUBSTR(gi.reference4,1,3)    = lv_cancel
    ;
--
    -- �����Ώۓ`�[�����Ɉ�ʉ�vOIF�ɍ쐬�������������Z
    gn_target_cnt := gn_target_cnt + gn_cancel_cnt;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm               -- �A�v���Z�k��
                      , iv_name              => cv_tkn_gloif_msg                -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_gl_cancel_data;
--
  /***********************************************************************************
   * Procedure Name   : up_recon_cancel_data
   * Description      : �T�������w�b�_�[���X�V�����i����j(A-9)
   ***********************************************************************************/
  PROCEDURE up_recon_cancel_data( ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
                                 ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
                                 ,ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(25) := 'up_recon_cancel_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER DEFAULT 0;      -- ���[�v�J�E���g�p�ϐ�
    ln_recon_head_id    NUMBER DEFAULT 0;      -- ���d�X�V���p
--
    -- *** ���[�J����O ***
    update_data_expt    EXCEPTION ;            -- �X�V�����G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    --==============================================================
    -- �T�������w�b�_�[���X�V����
    --==============================================================
--
    -- �����Ώۃf�[�^��GL�A�g�t���O���ꊇ�X�V����
    IF ( gt_recon_dedu_cancel_tbl.COUNT > 0 ) THEN
      -- ����f�[�^�X�V
--
      <<cancel_data_loop>>
      FOR ln_loop_cnt IN 1..gt_recon_dedu_cancel_tbl.COUNT LOOP
        IF (gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id != nvl(ln_recon_head_id,0)) THEN

          UPDATE xxcok_deduction_recon_head     xdrh                                             -- �T�������w�b�_�[���
          SET    xdrh.gl_if_flag               = CASE
                                                   WHEN xdrh.gl_if_flag = cv_y_flag THEN
                                                     cv_r_flag
                                                   ELSE
                                                     cv_u_flag
                                                 END                                                            -- ����GL�A�g�t���O
                ,xdrh.last_updated_by          = cn_last_updated_by                                             -- �ŏI�X�V��
                ,xdrh.last_update_date         = cd_last_update_date                                            -- �ŏI�X�V��
                ,xdrh.last_update_login        = cn_last_update_login                                           -- �ŏI�X�V���O�C��
                ,xdrh.request_id               = cn_request_id                                                  -- �v��ID
                ,xdrh.program_application_id   = cn_program_application_id                                      -- �R���J�����g�E�v���O�����E�A�v��ID
                ,xdrh.program_id               = cn_program_id                                                  -- �R���J�����g�E�v���O����ID
                ,xdrh.program_update_date      = cd_program_update_date                                         -- �v���O�����X�V��
          WHERE  xdrh.deduction_recon_head_id  = gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id  -- �T�������w�b�_�[ID
          ;
--
          ln_recon_head_id := gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id;
--
        END IF;
--
      END LOOP cancel_data_loop;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �X�V�Ɏ��s�����ꍇ
    WHEN update_data_expt THEN
      -- �G���[�����ݒ�
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => cv_sales_deduction
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END up_recon_cancel_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
                   , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
                   , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_normal_cnt    := 0;                 -- ��������
    gn_target_cnt    := 0;                 -- �o�^�Ώی���
    gn_cancel_cnt    := 0;                 -- �폜�Ώی���
    gn_error_cnt     := 0;                 -- �G���[����
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
        , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
        , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�̔��T���f�[�^���o
    -- ===============================
    get_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
            , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
            , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �f�[�^��1���ȏ゠���A-3�`A-6�����s����
    IF ( gt_recon_deductions_tbl.COUNT != 0 ) THEN
      -- ===============================
      -- A-3.��ʉ�vOIF�W�񏈗�
      -- ===============================
      edit_work_data( ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
                    , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
                    , ov_errmsg  => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-4.GL��ʉ�vOIF�f�[�^�쐬
      -- ===============================
      edit_gl_data( ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
                  , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
                  , ov_errmsg       => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.GL��ʉ�vOIF�f�[�^�C���T�[�g����
      -- ===============================
      insert_gl_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
                    , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
                    , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-6.�T�������w�b�_�[���X�V����
      -- ===============================
      up_ded_recon_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
                       , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
                       , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- A-7.GL�d��f�[�^���o�i����j
    -- ===============================
    get_gl_cancel_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
                      , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
                      , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gt_recon_dedu_cancel_tbl.COUNT != 0) THEN
      -- ===============================
      -- A-8.GL��ʉ�vOIF�f�[�^�C���T�[�g�����i����j
      -- ===============================
      insert_gl_cancel_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
                           , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
                           , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.�T�������w�b�_�[���X�V�����i����j
      -- ===============================
      up_recon_cancel_data( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W
                          , ov_retcode => lv_retcode           -- ���^�[���E�R�[�h
                          , ov_errmsg  => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      ov_retcode := lv_retcode;
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
                
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- ���ʗ̈�Z�k�A�v����
    cv_target_cnt_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10733';  -- �����Ώۓ`�[�������b�Z�[�W
    cv_add_cnt_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10734';  -- �o�^�Ώۓ`�[�������b�Z�[�W
    cv_del_cnt_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10735';  -- ����Ώۓ`�[�������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
           , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
           , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
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
    -- ===============================
    -- A-10.�I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    --�G���[�̏ꍇ�A���������N���A�A�G���[�����ݒ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_cancel_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --�����Ώۓ`�[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_target_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�o�^�Ώۓ`�[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_add_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --����Ώۓ`�[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_del_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_cancel_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_error_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
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
                                          , iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSIF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
  END main;
--
--#####################################  �Œ蕔 END  #####################################
--
END XXCOK024A18C;
/
