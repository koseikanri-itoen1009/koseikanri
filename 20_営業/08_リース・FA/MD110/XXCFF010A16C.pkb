create or replace
PACKAGE BODY XXCFF010A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF010A16C(body)
 * Description      : ���[�X�d��쐬
 * MD.050           : MD050_CFF_010_A16_���[�X�d��쐬
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                         ��������                               (A-1)
 *  get_profile_values           �v���t�@�C���l�擾                     (A-2)
 *  get_period                   ��v���ԃ`�F�b�N                       (A-3)
 *  chk_je_lease_data_exist      �O��쐬�ς݃��[�X�d�󑶍݃`�F�b�N     (A-4)
 *  upd_target_data              �������f�[�^�X�V                       (A-5)
 *  get_lease_class_aff_info     ���[�X��ʖ���AFF���擾              (A-6)
 *  get_lease_jnl_pattern        ���[�X�d��p�^�[�����擾             (A-7)
 *  get_les_trn_data             �d�󌳃f�[�^(���[�X���)���o           (A-8)
 *  ctrl_jnl_ptn_les_trn         �d��p�^�[������(���[�X���)           (A-9) ? (A-12)
 *  proc_ptn_tax                 �y�d��p�^�[���z�V�K�ǉ�               (A-9)
 *  proc_ptn_move_to_sagara      �y�d��p�^�[���z�U��(�{�ЁˍH��)       (A-10)
 *  proc_ptn_move_to_itoen       �y�d��p�^�[���z�U��(�H��˖{��)       (A-11)
 *  proc_ptn_retire              �y�d��p�^�[���z���                   (A-12)
 *  update_les_trns_gl_if_flag   ���[�X��� �d��A�g�t���O�X�V          (A-13)
 *  get_pay_plan_data            �d�󌳃f�[�^(�x���v��)���o             (A-14)
 *  ctrl_jnl_ptn_pay_plan        �d��p�^�[������(�x���v��)             (A-15) ? (A-17)
 *  proc_ptn_debt_trsf           �y�d��p�^�[���z���[�X���U��         (A-15)
 *  proc_ptn_dept_dist_itoen     �y�d��p�^�[���z���[�X�����啊��(�{��) (A-16)
 *  proc_ptn_dept_dist_sagara    �y�d��p�^�[���z���[�X�����啊��(�H��) (A-17)
 *  update_pay_plan_if_flag      ���[�X�x���v�� �A�g�t���O�X�V          (A-18)
 *  ins_gl_oif_dr                GLOIF�o�^����(�ؕ��f�[�^)              (A-19)
 *  ins_gl_oif_cr                GLOIF�o�^����(�ݕ��f�[�^)              (A-20)
 *  set_lease_class_aff          �y�������ʏ����z���[�X���AFF�l�ݒ�    (A-21)
 *  set_jnl_amount               �y�������ʏ����z���z�ݒ�               (A-22)
 *  ins_xxcff_gl_trn             �y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS�n�ӊw        �V�K�쐬
 *  2008/02/18    1.1   SCS�n�ӊw        [��QCFF_038]�d�󌳃f�[�^(���[�X���)���o�����s��Ή�
 *  2009/04/17    1.2   SCS�E��S��      [��QT1_0356]���[�X�����啊�ێd��̔z���敔��̎擾��ύX�Ή�
 *  2009/05/14    1.3   SCS�E��S��      [��QT1_0874]���Y�d�󎞂̐ݒ���e�ύX�Ή�
 *  2009/05/26    1.4   SCS�����r��      [��QT1_1157]�U�֎��̍T���z�������ŕ����폜
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
  --*** GL��v���ԃ`�F�b�N�G���[
  chk_gl_period_expt           EXCEPTION;
  --*** ���[�X�d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
  chk_cnt_gloif_expt        EXCEPTION;
  --*** ���[�X�d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
  chk_cnt_glhead_expt       EXCEPTION;
  --*** ���[�U���(���O�C�����[�U�A��������)�擾�G���[
  get_login_info_expt       EXCEPTION;
  --*** ��v���떼�擾�G���[
  get_sob_name_expt         EXCEPTION;
-- T1_0356 2009/04/17 ADD START --
  --*** �c�Ɠ����t�擾�G���[
  get_working_day_expt      EXCEPTION;
-- T1_0356 2009/04/17 ADD END   --
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N(�r�W�[)�G���[
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF010A16C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cmn   CONSTANT VARCHAR2(5) := 'XXCMN';
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP';
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_013a20_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --�v���t�@�C���擾�G���[
  cv_msg_013a20_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00038'; --��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; --GL��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00111'; --���[�X�d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
  cv_msg_013a20_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00112'; --���[�X�d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
  cv_msg_013a20_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --���b�N�G���[
  cv_msg_013a20_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --�擾�Ώۃf�[�^����
  cv_msg_013a20_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00113'; --���[�X�d��e�[�u��(�d��=���[�X���)�쐬���b�Z�[�W
  cv_msg_013a20_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00114'; --���[�X�d��e�[�u��(�d��=�x���v��)�쐬���b�Z�[�W
  cv_msg_013a20_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; --��ʉ�vOIF�쐬���b�Z�[�W
  cv_msg_013a20_m_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; --�擾�G���[
-- T1_0356 2009/04/17 ADD START --
  cv_msg_013a20_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00094'; --���ʊ֐��G���[
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_013a20_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:��ЃR�[�h_�{��
  cv_msg_013a20_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50077'; --XXCFF:��ЃR�[�h_�H��
  cv_msg_013a20_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50146'; --XXCFF:�d��\�[�X_���[�X
  cv_msg_013a20_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50112'; --���[�X���
  cv_msg_013a20_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50088'; --���[�X�x���v��
  cv_msg_013a20_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50147'; --���[�X�d��
  cv_msg_013a20_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50095'; --XXCFF: �{�ЍH��敪_�{��
  cv_msg_013a20_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50096'; --XXCFF: �{�ЍH��敪_�H��
  cv_msg_013a20_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; --���O�C��(���[�U��,��������)���
  cv_msg_013a20_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; --XXCFF:�`�[�ԍ�_���[�X
  cv_msg_013a20_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; --��v���떼
  cv_msg_013a20_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50161'; --���[�X�d��(�d��=���[�X���)���
  cv_msg_013a20_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50162'; --���[�X�d��(�d��=�x���v��)���
  cv_msg_013a20_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; --���O�C�����[�UID=
  cv_msg_013a20_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; --��v����ID=
  cv_msg_013a20_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50171'; --���[�X���AFF�l(���[�X��ʃr���[)���
  cv_msg_013a20_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50172'; --���[�X���=
-- T1_0356 2009/04/17 ADD START --
  cv_msg_013a20_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50188'; --XXCFF:�I�����C���I������
  cv_msg_013a20_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50189'; --�c�Ɠ����t
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***�g�[�N����
  cv_tkn_prof     CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type  CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period   CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val  CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_get_data CONSTANT VARCHAR2(20) := 'GET_DATA';
-- T1_0356 2009/04/17 ADD START --
  cv_tkn_func_name CONSTANT VARCHAR2(20) := 'FUNC_NAME';
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***�v���t�@�C��
--
  -- ��ЃR�[�h_�{��
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';
  -- ��ЃR�[�h_�H��
  cv_comp_cd_sagara       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_SAGARA';
  -- �d��\�[�X_���[�X
  cv_je_src_lease         CONSTANT VARCHAR2(30) := 'XXCFF1_JE_SOURCE_LEASE';
  -- �{�ЍH��敪_�{��
  cv_own_comp_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_ITOEN';
  -- �{�ЍH��敪_�H��
  cv_own_comp_sagara      CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_SAGARA';
  -- �`�[�ԍ�_���[�X
  cv_slip_num_lease       CONSTANT VARCHAR2(30) := 'XXCFF1_SLIP_NUM_LEASE';
-- T1_0356 2009/04/17 ADD START --
  -- �I�����C���I������
  cv_prof_online_end_time CONSTANT VARCHAR2(30) := 'XXCFF1_ONLINE_END_TIME';
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***�t�@�C���o��
--
  -- ���b�Z�[�W�o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';
  -- ���O�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';
--
  -- ***�_��X�e�[�^�X
  -- �_��
  cv_ctrt_ctrt           CONSTANT VARCHAR2(3) := '202';
  -- ���ύX
  cv_ctrt_info_change    CONSTANT VARCHAR2(3) := '209';
  -- ����
  cv_ctrt_manryo         CONSTANT VARCHAR2(3) := '204';
  -- ���r���(���ȓs��)
  cv_ctrt_cancel_jiko    CONSTANT VARCHAR2(3) := '206';
  -- ���r���(�ی��Ή�)
  cv_ctrt_cancel_hoken   CONSTANT VARCHAR2(3) := '207';
  -- ���r���(����)
  cv_ctrt_cancel_manryo  CONSTANT VARCHAR2(3) := '208';
--
  -- ***�����X�e�[�^�X
  -- �ړ�
  cv_obj_move        CONSTANT VARCHAR2(3) := '105';
--
  -- ***���[�X���
  cv_lease_kind_fin  CONSTANT VARCHAR2(1) := '0';  -- Fin���[�X
  cv_lease_kind_lfin CONSTANT VARCHAR2(1) := '2';  -- ��Fin���[�X
--
  -- ***��vIF�t���O
  cv_if_yet  CONSTANT VARCHAR2(1) := '1';  -- �����M
  cv_if_aft  CONSTANT VARCHAR2(1) := '2';  -- �A�g��
  -- ***�ƍ��σt���O
  cv_match   CONSTANT VARCHAR2(1) := '1';  -- �ƍ���
--
  -- ***���[�X�敪
  cv_original  CONSTANT VARCHAR2(1) := '1';  -- ���_��
--
-- T1_0356 2009/04/17 ADD START --
  -- ***�����X�e�[�^�X
  cv_object_status_105  CONSTANT VARCHAR2(3) := '105';  -- �ړ�
--
  -- ***�I�����C���I������
  cv_online_end_time  CONSTANT VARCHAR2(8) := '24:00:00';  
-- T1_0356 2009/04/17 ADD END   --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_deprn_run_ttype             IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype        IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fa_transaction_id_ttype     IS TABLE OF xxcff_fa_transactions.fa_transaction_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_fa_transactions.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_fa_transactions.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_fa_transactions.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_period_name_ttype           IS TABLE OF xxcff_fa_transactions.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_type_ttype      IS TABLE OF xxcff_fa_transactions.transaction_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_movement_type_ttype         IS TABLE OF xxcff_fa_transactions.movement_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_fa_transactions.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vdsh_flag_ttype             IS TABLE OF xxcff_lease_class_v.vdsh_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_fa_transactions.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype            IS TABLE OF xxcff_contract_lines.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_frequency_ttype     IS TABLE OF xxcff_pay_planning.payment_frequency%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_temp_pay_tax_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���������
  TYPE g_liab_blc_ttype              IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X���c
  TYPE g_liab_tax_blc_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X���c_�����
  TYPE g_liab_pretax_blc_ttype       IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X���c�i�{�́{�Łj
  TYPE g_pay_interest_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- �x������
  TYPE g_liab_amt_ttype              IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X���z
  TYPE g_liab_tax_amt_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X���z_�����
  TYPE g_deduction_ttype             IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X�T���z
  TYPE g_charge_ttype                IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X��
  TYPE g_charge_tax_ttype            IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- ���[�X��_�����
  TYPE g_tax_code_ttype              IS TABLE OF xxcff_contract_headers.tax_code%TYPE INDEX BY PLS_INTEGER;-- �ŃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_deprn_run_tab                       g_deprn_run_ttype;
  g_book_type_code_tab                  g_book_type_code_ttype;
  g_fa_transaction_id_tab               g_fa_transaction_id_ttype;
  g_contract_header_id_tab              g_contract_header_id_ttype;
  g_contract_line_id_tab                g_contract_line_id_ttype;
  g_object_header_id_tab                g_object_header_id_ttype;
  g_period_name_tab                     g_period_name_ttype;
  g_transaction_type_tab                g_transaction_type_ttype;
  g_movement_type_tab                   g_movement_type_ttype;
  g_lease_class_tab                     g_lease_class_ttype;
  g_lease_type_tab                      g_lease_type_ttype;
  g_vdsh_flag_tab                       g_vdsh_flag_ttype;
  g_owner_company_tab                   g_owner_company_ttype;
  g_lease_kind_tab                      g_lease_kind_ttype;
  g_payment_frequency_tab               g_payment_frequency_ttype;
  g_department_code_tab                 g_department_code_ttype;
  g_customer_code_tab                   g_customer_code_ttype;
  g_temp_pay_tax_tab                    g_temp_pay_tax_ttype;     -- ���������
  g_liab_blc_tab                        g_liab_blc_ttype;         -- ���[�X���c
  g_liab_tax_blc_tab                    g_liab_tax_blc_ttype;     -- ���[�X���c_�����
  g_liab_pretax_blc_tab                 g_liab_pretax_blc_ttype;  -- ���[�X���c�i�{�́{�Łj
  g_pay_interest_tab                    g_pay_interest_ttype;     -- �x������
  g_liab_amt_tab                        g_liab_amt_ttype;         -- ���[�X���z
  g_liab_tax_amt_tab                    g_liab_tax_amt_ttype;     -- ���[�X���z_�����
  g_deduction_tab                       g_deduction_ttype;        -- ���[�X�T���z
  g_charge_tab                          g_charge_ttype;           -- ���[�X��
  g_charge_tax_tab                      g_charge_tax_ttype;       -- ���[�X��_�����
  g_tax_code_tab                        g_tax_code_ttype;
--
  -- ***��������
  -- ���[�X�������̃��[�X�d��e�[�u���o�^�����ɂ����錏��
  gn_les_trn_target_cnt    NUMBER;     -- �Ώی���
  gn_les_trn_normal_cnt    NUMBER;     -- ���팏��
  gn_les_trn_error_cnt     NUMBER;     -- �G���[����
  -- �x���v�悩��̃��[�X�d��e�[�u���o�^�����ɂ����錏��
  gn_pay_plan_target_cnt   NUMBER;     -- �Ώی���
  gn_pay_plan_normal_cnt   NUMBER;     -- ���팏��
  gn_pay_plan_error_cnt    NUMBER;     -- �G���[����
  -- ��ʉ�vOIF�o�^�����ɂ����錏���o��
  gn_gloif_dr_target_cnt   NUMBER;     -- �Ώی���(�ؕ��f�[�^)
  gn_gloif_cr_target_cnt   NUMBER;     -- �Ώی���(�ݕ��f�[�^)
  gn_gloif_normal_cnt      NUMBER;     -- ���팏��
  gn_gloif_error_cnt       NUMBER;     -- �G���[����
--
  -- �����l���
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name VARCHAR2(100);
  -- ���Y�J�e�S��CCID
  gt_category_id  fa_categories.category_id%TYPE;
  -- ���Ə�CCID
  gt_location_id  fa_locations.location_id%TYPE;
-- T1_0356 2009/04/17 ADD START --
  -- ���
  gd_base_date   DATE;
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***���[�v�J�E���^
  gn_main_loop_cnt NUMBER := 0;
  gn_ptn_loop_cnt  NUMBER := 0;
  -- ***���[�X�d��̘A��
  gn_transaction_num NUMBER := 0;
--
  -- ***���[�U���
  -- ���O�C�����[�U
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- �N�[����(��������)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***��v������
  -- ��v���떼
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***�v���t�@�C���l
  -- ��ЃR�[�h_�{��
  gv_comp_cd_itoen         VARCHAR2(100);
  -- ��ЃR�[�h_�H��
  gv_comp_cd_sagara        VARCHAR2(100);
  -- �d��\�[�X_���[�X
  gv_je_src_lease          VARCHAR2(100);
  -- �{�ЍH��敪_�{��
  gv_own_comp_itoen        VARCHAR2(100);
  -- �{�ЍH��敪_�H��
  gv_own_comp_sagara       VARCHAR2(100);
  -- �`�[�ԍ�_���[�X
  gv_slip_num_lease        VARCHAR2(100);
-- T1_0356 2009/04/17 ADD START --
  -- �I�����C���I������
  gv_online_end_time       VARCHAR2(100);
-- T1_0356 2009/04/17 ADD END   --
  -- ***�J�[�\����`
  -- ���[�X��ʖ�AFF���擾�J�[�\��
  CURSOR lease_class_cur
  IS
    SELECT
            les_class.lease_class_code         AS lease_class_code         -- ���[�X��ʃR�[�h
           ,les_class.les_liab_acct            AS les_liab_acct            -- ���[�X��_�Ȗ�
           ,les_class.les_liab_sub_acct_line   AS les_liab_sub_acct_line   -- ���[�X��_�⏕�Ȗ�(�{��)
           ,les_class.les_liab_sub_acct_tax    AS les_liab_sub_acct_tax    -- ���[�X��_�⏕�Ȗ�(��)
           ,les_class.les_chrg_acct            AS les_chrg_acct            -- ���[�X��_�Ȗ�
           ,les_class.les_chrg_sub_acct_orgn   AS les_chrg_sub_acct_orgn   -- ���[�X��_�⏕�Ȗ�(���_��)
           ,les_class.les_chrg_sub_acct_reles  AS les_chrg_sub_acct_reles  -- ���[�X��_�⏕�Ȗ�(�ă��[�X)
           ,les_class.les_chrg_dep             AS les_chrg_dep             -- ���[�X��_�v�㕔��
           ,les_class.pay_int_acct             AS pay_int_acct             -- �x������_�Ȗ�
           ,les_class.pay_int_sub_acct         AS pay_int_sub_acct         -- �x������_�⏕�Ȗ�(�{��)
    FROM
           xxcff_lease_class_v   les_class    -- ���[�X��ʃr���[
    WHERE
          les_class.enabled_flag    = 'Y'
    AND   g_init_rec.process_date  >= NVL(les_class.start_date_active,g_init_rec.process_date)
    AND   g_init_rec.process_date  <= NVL(les_class.end_date_active,g_init_rec.process_date)
    ;
  g_lease_class_rec  lease_class_cur%ROWTYPE;
--
  -- ���[�X�d��p�^�[���擾�J�[�\��
  CURSOR lease_journal_ptn_cur(lt_journal_ptn_grp xxcff_lease_journal_ptn_v.journal_ptn_grp%TYPE)
  IS
    SELECT
            les_jnl_ptn.description         AS description     -- �E�v
           ,les_jnl_ptn.journal_ptn_grp     AS journal_ptn_grp -- �d��쐬�O���[�v
           ,les_jnl_ptn.amount_grp          AS amount_grp      -- ���z�ݒ�O���[�v
           ,les_jnl_ptn.crdr_type           AS crdr_type       -- CRDR�敪
           ,les_jnl_ptn.je_category         AS je_category     -- �d��J�e�S��
           ,les_jnl_ptn.je_source           AS je_source       -- �d��\�[�X
           ,les_jnl_ptn.company             AS company         -- ���
           ,les_jnl_ptn.department          AS department      -- ����
           ,les_jnl_ptn.account             AS account         -- �Ȗ�
           ,les_jnl_ptn.sub_account         AS sub_account     -- �⏕�Ȗ�
           ,les_jnl_ptn.partner             AS partner         -- �ڋq
           ,les_jnl_ptn.business_type       AS business_type   -- ���
           ,les_jnl_ptn.project             AS project         -- �\��1
           ,les_jnl_ptn.future              AS future          -- �\��2
           ,NULL                            AS amount_dr       -- �ؕ����z
           ,NULL                            AS amount_cr       -- �ݕ����z
           ,NULL                            AS tax_code        -- �ŃR�[�h
    FROM
           xxcff_lease_journal_ptn_v   les_jnl_ptn    -- ���[�X�d��p�^�[���r���[
    WHERE
          les_jnl_ptn.journal_ptn_grp = lt_journal_ptn_grp
    AND   les_jnl_ptn.enabled_flag    = 'Y'
    AND   g_init_rec.process_date     >= NVL(les_jnl_ptn.start_date_active,g_init_rec.process_date)
    AND   g_init_rec.process_date     <= NVL(les_jnl_ptn.end_date_active,g_init_rec.process_date)
    ;
  g_lease_journal_ptn_rec  lease_journal_ptn_cur%ROWTYPE;
--
  -- �d�󌳃f�[�^(���[�X���)�擾�J�[�\��
  CURSOR get_les_trn_data_cur
  IS
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- ���[�X�������ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- �_�����ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- �_�񖾍ד���ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- ��������ID
           ,xxcff_fa_trn.period_name            AS period_name        -- ��v���Ԗ�
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- ����^�C�v
           ,xxcff_fa_trn.movement_type          AS movement_type      -- �ړ��^�C�v
           ,xxcff_fa_trn.lease_class            AS lease_class        -- ���[�X���
           ,1                                   AS lease_type         -- ���[�X�敪
           ,xxcff_fa_trn.owner_company          AS owner_company      -- �{�Ё^�H��
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- ��������Ŋz
                                                                      -- (���z�����_���[�X�� - ���z�����_�T���z)
           ,NULL                                AS liab_blc           -- ���[�X���c
           ,NULL                                AS liab_tax_blc       -- ���[�X���c_�����
           ,NULL                                AS liab_pretax_blc    -- ���[�X���c_�{�́{��
                                                                      -- (���[�X���c + ���[�X���c_�����)
           ,ctrct_head.tax_code                 AS tax_code           -- �ŃR�[�h
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- ���[�X���
          ,xxcff_contract_lines    ctrct_line    -- ���[�X�_�񖾍�
          ,xxcff_contract_headers  ctrct_head    -- ���[�X�_��
          ,xxcff_lease_kind_v      xlk           -- ���[�X��ރr���[
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
    AND   xxcff_fa_trn.transaction_type = '1' -- �ǉ�
    AND   xxcff_fa_trn.contract_line_id = ctrct_line.contract_line_id
    AND   ctrct_line.contract_header_id = ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       = cv_if_yet          -- �����M
    AND   xlk.lease_kind_code           = cv_lease_kind_fin  -- FIN���[�X
    AND   xxcff_fa_trn.book_type_code   = xlk.book_type_code
    UNION ALL
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- ���[�X�������ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- �_�����ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- �_�񖾍ד���ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- ��������ID
           ,xxcff_fa_trn.period_name            AS period_name        -- ��v���Ԗ�
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- ����^�C�v
           ,xxcff_fa_trn.movement_type          AS movement_type      -- �ړ��^�C�v
           ,xxcff_fa_trn.lease_class            AS lease_class        -- ���[�X���
           ,1                                   AS lease_type         -- ���[�X�敪
           ,xxcff_fa_trn.owner_company          AS owner_company      -- �{�Ё^�H��
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- ��������Ŋz
                                                                      -- (���z�����_���[�X�� - ���z�����_�T���z)
           ,CASE
              -- �ƍ��ρ˃��[�X���c
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_debt_rem
              -- ���ƍ��˃��[�X���c + ���[�X���z (��������������Ȃ���)
              ELSE
                pay_plan.fin_debt_rem + pay_plan.fin_debt
              END                                                       AS liab_blc  -- ���[�X���c
           ,CASE
              -- �ƍ��ρ˃��[�X���c_�����
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_tax_debt_rem
              -- ���ƍ��˃��[�X���c_����� + ���[�X���z_����� (��������������Ȃ���)
              ELSE
                pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt
              END                                                       AS liab_tax_blc  -- ���[�X���c_�����
           ,CASE
              -- �ƍ��ρ˃��[�X���c + ���[�X���c_�����
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_debt_rem
                  + pay_plan.fin_tax_debt_rem
              -- ���ƍ���(���[�X���c + ���[�X���z) + (���[�X���c_����� + ���[�X���z_�����)
              ELSE
                pay_plan.fin_debt_rem + pay_plan.fin_debt
                  + pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt
              END                                                       AS liab_pretax_blc    -- ���[�X���c_�{�́{��
                                                                      -- (���[�X���c + ���[�X���c_�����)
           ,ctrct_head.tax_code                 AS tax_code           -- �ŃR�[�h
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- ���[�X���
          ,xxcff_contract_lines    ctrct_line    -- ���[�X�_�񖾍�
          ,xxcff_pay_planning      pay_plan      -- ���[�X�x���v��
          ,xxcff_contract_headers  ctrct_head    -- ���[�X�_��
          ,xxcff_lease_kind_v      xlk           -- ���[�X��ރr���[
    WHERE
          xxcff_fa_trn.period_name      =  gv_period_name
-- T1_0874 2009/05/14 MOD START --
--  AND   xxcff_fa_trn.transaction_type IN ('2','3') --�U��(2),���(3)
    AND   xxcff_fa_trn.transaction_type IN ('3') --���(3)
-- T1_0874 2009/05/14 MOD END   --
    AND   xxcff_fa_trn.contract_line_id =  ctrct_line.contract_line_id
    AND   xxcff_fa_trn.contract_line_id =  pay_plan.contract_line_id
    AND   pay_plan.period_name          =  xxcff_fa_trn.period_name
    AND   ctrct_line.contract_header_id =  ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       =  cv_if_yet          --�����M
    AND   xlk.lease_kind_code           =  cv_lease_kind_fin  -- FIN���[�X
    AND   xxcff_fa_trn.book_type_code   =  xlk.book_type_code
-- T1_0874 2009/05/14 ADD START --
    UNION ALL
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- ���[�X�������ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- �_�����ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- �_�񖾍ד���ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- ��������ID
           ,xxcff_fa_trn.period_name            AS period_name        -- ��v���Ԗ�
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- ����^�C�v
           ,xxcff_fa_trn.movement_type          AS movement_type      -- �ړ��^�C�v
           ,xxcff_fa_trn.lease_class            AS lease_class        -- ���[�X���
           ,1                                   AS lease_type         -- ���[�X�敪
           ,xxcff_fa_trn.owner_company          AS owner_company      -- �{�Ё^�H��
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- ��������Ŋz
                                                                      -- (���z�����_���[�X�� - ���z�����_�T���z)
           -- ���ƍ��˃��[�X���c + ���[�X���z (��������������Ȃ���)
           ,pay_plan.fin_debt_rem + pay_plan.fin_debt               AS liab_blc  -- ���[�X���c
           -- ���ƍ��˃��[�X���c_����� + ���[�X���z_����� (��������������Ȃ���)
           ,pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt       AS liab_tax_blc  -- ���[�X���c_�����
           -- ���ƍ���(���[�X���c + ���[�X���z) + (���[�X���c_����� + ���[�X���z_�����)
           ,pay_plan.fin_debt_rem + pay_plan.fin_debt
              + pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt   AS liab_pretax_blc    -- ���[�X���c_�{�́{��
                                                                      -- (���[�X���c + ���[�X���c_�����)
           ,ctrct_head.tax_code                 AS tax_code           -- �ŃR�[�h
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- ���[�X���
          ,xxcff_contract_lines    ctrct_line    -- ���[�X�_�񖾍�
          ,xxcff_pay_planning      pay_plan      -- ���[�X�x���v��
          ,xxcff_contract_headers  ctrct_head    -- ���[�X�_��
          ,xxcff_lease_kind_v      xlk           -- ���[�X��ރr���[
    WHERE
          xxcff_fa_trn.period_name      =  gv_period_name
    AND   xxcff_fa_trn.transaction_type IN ('2') --�U��(2)
    AND   xxcff_fa_trn.contract_line_id =  ctrct_line.contract_line_id
    AND   xxcff_fa_trn.contract_line_id =  pay_plan.contract_line_id
    AND   pay_plan.period_name          =  xxcff_fa_trn.period_name
    AND   ctrct_line.contract_header_id =  ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       =  cv_if_yet          --�����M
    AND   xlk.lease_kind_code           =  cv_lease_kind_fin  -- FIN���[�X
    AND   xxcff_fa_trn.book_type_code   =  xlk.book_type_code
-- T1_0874 2009/05/14 ADD END   --
    ;
  g_get_les_trn_data_rec  get_les_trn_data_cur%ROWTYPE;
--
  -- �d�󌳃f�[�^(�x���v��)�擾�J�[�\��
  CURSOR get_pay_plan_data_cur
  IS
    SELECT
            pay_plan.contract_header_id      AS contract_header_id -- �_�����ID
           ,pay_plan.contract_line_id        AS contract_line_id   -- �_�񖾍ד���ID
           ,ctrct_line.object_header_id      AS object_header_id   -- ��������ID
           ,pay_plan.payment_frequency       AS payment_frequency  -- �x����
           ,pay_plan.period_name             AS period_name        -- ��v����
           ,ctrct_line.lease_kind            AS lease_kind         -- ���[�X���
           ,obj_head.lease_class             AS lease_class        -- ���[�X���
           ,les_class_v.vdsh_flag            AS vdsh_flag          -- ���̋@SH�t���O
           ,ctrct_head.lease_type            AS lease_type         -- ���[�X�敪
           ,obj_head.department_code         AS department_code    -- �Ǘ�����
           ,obj_head.owner_company           AS owner_company      -- �{�ЍH��敪
           ,obj_head.customer_code           AS customer_code      -- �ڋq�R�[�h
           ,pay_plan.fin_interest_due        AS pay_interest       -- �x������(FIN���[�X�x������)
           ,pay_plan.fin_debt                AS liab_amt           -- ���[�X���z
           ,pay_plan.fin_tax_debt            AS liab_tax_amt       -- ���[�X���z_�����
           --T1_1157 2009/05/26 MOD START
           --,pay_plan.lease_deduction
           --   + pay_plan.lease_tax_deduction AS deduction          -- ���[�X�T���z
           ,pay_plan.lease_deduction         AS deduction          -- ���[�X�T���z
           --T1_1157 2009/05/26 MOD END
           ,pay_plan.lease_charge            AS charge             -- ���[�X��
           --T1_1157 2009/05/26 MOD START
           --,pay_plan.lease_tax_charge        AS charge_tax         -- ���[�X��_�����
           ,pay_plan.lease_tax_charge
              - pay_plan.lease_tax_deduction AS charge_tax         -- ���[�X��_�����
           --T1_1157 2009/05/26 MOD END
           ,ctrct_head.tax_code              AS tax_code           -- �ŃR�[�h
    FROM
           xxcff_pay_planning      pay_plan      -- ���[�X�x���v��
          ,xxcff_contract_lines    ctrct_line    -- ���[�X�_�񖾍�
          ,xxcff_object_headers    obj_head      -- ���[�X����
          ,xxcff_lease_class_v     les_class_v   -- ���[�X��ʃr���[
          ,xxcff_contract_headers  ctrct_head    -- ���[�X�_��
    WHERE
          pay_plan.period_name          = gv_period_name
    AND   pay_plan.payment_match_flag   = cv_match --�ƍ���
    AND   pay_plan.accounting_if_flag   = cv_if_yet--�����M
    AND   pay_plan.contract_line_id     = ctrct_line.contract_line_id
    AND   ctrct_line.object_header_id   = obj_head.object_header_id
    AND   ctrct_line.contract_header_id = ctrct_head.contract_header_id
    AND   obj_head.lease_class          = les_class_v.lease_class_code
    ;
  g_get_pay_plan_data_rec  get_pay_plan_data_cur%ROWTYPE;
--
  -- ***���[�X��ʖ�AFF���p(���R�[�h�^)
  TYPE lease_class_aff_rtype    IS RECORD (  les_liab_acct           xxcff_lease_class_v.les_liab_acct%TYPE
                                            ,les_liab_sub_acct_line  xxcff_lease_class_v.les_liab_sub_acct_line%TYPE
                                            ,les_liab_sub_acct_tax   xxcff_lease_class_v.les_liab_sub_acct_tax%TYPE
                                            ,les_chrg_acct           xxcff_lease_class_v.les_chrg_acct%TYPE
                                            ,les_chrg_sub_acct_orgn  xxcff_lease_class_v.les_chrg_sub_acct_orgn%TYPE
                                            ,les_chrg_sub_acct_reles xxcff_lease_class_v.les_chrg_sub_acct_reles%TYPE
                                            ,les_chrg_dep            xxcff_lease_class_v.les_chrg_dep%TYPE
                                            ,pay_int_acct            xxcff_lease_class_v.pay_int_acct%TYPE
                                            ,pay_int_sub_acct        xxcff_lease_class_v.pay_int_sub_acct%TYPE
                                          );
  -- ***���[�X��ʖ�AFF���p(�e�[�u���^)
  TYPE lease_class_aff_ttype    IS TABLE OF lease_class_aff_rtype INDEX BY xxcff_lease_class_v.lease_class_code%TYPE;
  -- ***���[�X�d��p�^�[��(�e�[�u���^)
  TYPE lease_journal_ptn_ttype  IS TABLE OF lease_journal_ptn_cur%ROWTYPE INDEX BY PLS_INTEGER;
  -- ***�d�󌳃f�[�^(���[�X���) (�e�[�u���^)
  TYPE les_trn_data_ttype       IS TABLE OF get_les_trn_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  -- ***���[�X�d�󌳃L�[���(���R�[�h�^)
  TYPE les_jnl_key_rtype    IS RECORD (  fa_transaction_id   xxcff_fa_transactions.fa_transaction_id%TYPE
                                        ,contract_header_id  xxcff_fa_transactions.contract_header_id%TYPE
                                        ,contract_line_id    xxcff_fa_transactions.contract_line_id%TYPE
                                        ,object_header_id    xxcff_fa_transactions.object_header_id%TYPE
                                        ,payment_frequency   xxcff_pay_planning.payment_frequency%TYPE
                                        ,period_name         xxcff_fa_transactions.period_name%TYPE
                                       );
  -- ***���[�X�d����z���(���R�[�h�^)
  TYPE jnl_amount_rtype     IS RECORD (  temp_pay_tax    NUMBER -- ���������
                                        ,liab_blc        NUMBER -- ���[�X���c
                                        ,liab_tax_blc    NUMBER -- ���[�X���c_�����
                                        ,liab_pretax_blc NUMBER -- ���[�X���c�i�{�́{�Łj
                                        ,pay_interest    NUMBER -- �x������
                                        ,liab_amt        NUMBER -- ���[�X���z
                                        ,liab_tax_amt    NUMBER -- ���[�X���z_�����
                                        ,deduction       NUMBER -- ���[�X�T���z
                                        ,charge          NUMBER -- ���[�X��
                                        ,charge_tax      NUMBER -- ���[�X��_�����
                                       );
--
  -- ***�e�[�u���^�z��
  -- ���[�X��ʖ�AFF���
  g_lease_class_aff_tab                 lease_class_aff_ttype;
  -- ���[�X�d��p�^�[��(���������)
  g_ptn_tax_tab                         lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���Y�ړ�(�{�ЁˍH��))
  g_ptn_move_to_sagara_tab              lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���Y�ړ�(�H��˖{��))
  g_ptn_move_to_itoen_tab               lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���)
  g_ptn_retire_tab                      lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���[�X���U��)
  g_ptn_debt_trsf_tab                   lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���[�X�����啊��(�{��))
  g_ptn_dept_dist_itoen_tab             lease_journal_ptn_ttype;
  -- ���[�X�d��p�^�[��(���[�X�����啊��(�H��))
  g_ptn_dept_dist_sagara_tab            lease_journal_ptn_ttype;
  -- �d�󌳃f�[�^(���[�X���)
  g_les_trn_data_tab                    les_trn_data_ttype;
  -- ���[�X�d�󌳃L�[���(���R�[�h�^)
  g_les_jnl_key_rec                     les_jnl_key_rtype;
  -- ���[�X�d����z���(���R�[�h�^)
  g_jnl_amount_rec                      jnl_amount_rtype;
  -- ���[�X�d��AFF���
  g_les_jnl_aff_rec                     lease_journal_ptn_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : �R���N�V�����폜
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�R���N�V���������z��̍폜
    g_fa_transaction_id_tab.DELETE;
    g_contract_header_id_tab.DELETE;
    g_contract_line_id_tab.DELETE;
    g_object_header_id_tab.DELETE;
    g_period_name_tab.DELETE;
    g_transaction_type_tab.DELETE;
    g_movement_type_tab.DELETE;
    g_lease_class_tab.DELETE;
    g_lease_type_tab.DELETE;
    g_owner_company_tab.DELETE;
    g_temp_pay_tax_tab.DELETE;
    g_liab_blc_tab.DELETE;
    g_liab_tax_blc_tab.DELETE;
    g_liab_pretax_blc_tab.DELETE;
    g_tax_code_tab.DELETE;
    g_payment_frequency_tab.DELETE;
    g_lease_kind_tab.DELETE;
    g_department_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_pay_interest_tab.DELETE;
    g_liab_amt_tab.DELETE;
    g_liab_tax_amt_tab.DELETE;
    g_deduction_tab.DELETE;
    g_charge_tab.DELETE;
    g_charge_tax_tab.DELETE;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcff_gl_trn
   * Description      : �y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
   ***********************************************************************************/
  PROCEDURE ins_xxcff_gl_trn(
    it_jnl_key_rec    IN     les_jnl_key_rtype              -- ���[�X�d�󌳃L�[���
   ,it_jnl_aff_rec    IN OUT lease_journal_ptn_cur%ROWTYPE  -- ���[�X�d��AFF���
   ,ov_errbuf         OUT    VARCHAR2                       --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2                       --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcff_gl_trn'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�A�ԃJ�E���g�A�b�v
    gn_transaction_num := gn_transaction_num + 1;
--
    INSERT INTO xxcff_gl_transactions(
       gl_transaction_id       -- ���[�X�d�����ID
      ,fa_transaction_id       -- ���[�X�������ID
      ,contract_header_id      -- �_�����ID
      ,contract_line_id        -- �_�񖾍ד���ID
      ,object_header_id        -- ��������ID
      ,payment_frequency       -- �x����
      ,transaction_num         -- �A��
      ,description             -- �E�v
      ,je_category             -- �d��J�e�S����
      ,je_source               -- �d��\�[�X��
      ,company_code            -- ��ЃR�[�h
      ,department_code         -- �Ǘ�����R�[�h
      ,account_code            -- ����ȖڃR�[�h
      ,sub_account_code        -- �⏕�ȖڃR�[�h
      ,customer_code           -- �ڋq�R�[�h
      ,enterprise_code         -- ��ƃR�[�h
      ,reserve_1               -- �\��1
      ,reserve_2               -- �\��2
      ,accounted_dr            -- �ؕ����z
      ,accounted_cr            -- �ݕ����z
      ,period_name             -- ��v����
      ,tax_code                -- �ŃR�[�h
      ,slip_number             -- �`�[�ԍ�
      ,gl_if_date              -- GL�A�g��
      ,gl_if_flag              -- GL�A�g�t���O
      ,created_by              -- �쐬��
      ,creation_date           -- �쐬��
      ,last_updated_by         -- �ŏI�X�V��
      ,last_update_date        -- �ŏI�X�V��
      ,last_update_login       -- �ŏI�X�V۸޲�
      ,request_id              -- �v��ID
      ,program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
      ,program_id              -- �ݶ��ĥ��۸���ID
      ,program_update_date     -- ��۸��эX�V��
    )
    VALUES (
       xxcff_gl_transactions_s1.NEXTVAL                                                -- ���[�X�d�����ID
      ,it_jnl_key_rec.fa_transaction_id                                                -- ���[�X�������ID
      ,it_jnl_key_rec.contract_header_id                                               -- �_�����ID
      ,it_jnl_key_rec.contract_line_id                                                 -- �_�񖾍ד���ID
      ,it_jnl_key_rec.object_header_id                                                 -- ��������ID
      ,it_jnl_key_rec.payment_frequency                                                -- �x����
      ,gn_transaction_num                                                              -- �A��
      ,it_jnl_aff_rec.description
         ||' '||TO_CHAR(LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')),'DD/MM/YYYY')      -- �E�v
      ,it_jnl_aff_rec.je_category                                                      -- �d��J�e�S����
      ,it_jnl_aff_rec.je_source                                                        -- �d��\�[�X��
      ,it_jnl_aff_rec.company                                                          -- ��ЃR�[�h
      ,it_jnl_aff_rec.department                                                       -- �Ǘ�����R�[�h
      ,it_jnl_aff_rec.account                                                          -- ����ȖڃR�[�h
      ,it_jnl_aff_rec.sub_account                                                      -- �⏕�ȖڃR�[�h
      ,it_jnl_aff_rec.partner                                                          -- �ڋq�R�[�h
      ,it_jnl_aff_rec.business_type                                                    -- ��ƃR�[�h
      ,it_jnl_aff_rec.project                                                          -- �\��1
      ,it_jnl_aff_rec.future                                                           -- �\��2
      ,it_jnl_aff_rec.amount_dr                                                        -- �ؕ����z
      ,it_jnl_aff_rec.amount_cr                                                        -- �ݕ����z
      ,gv_period_name                                                                  -- ��v����
      ,it_jnl_aff_rec.tax_code                                                         -- �ŃR�[�h
      ,gv_slip_num_lease                                                               -- �`�[�ԍ�
      ,g_init_rec.process_date                                                         -- GL�A�g��
      ,cv_if_yet                                                                       -- GL�A�g�t���O
      ,cn_created_by                                                                   -- �쐬��ID
      ,cd_creation_date                                                                -- �쐬��
      ,cn_last_updated_by                                                              -- �ŏI�X�V��
      ,cd_last_update_date                                                             -- �ŏI�X�V��
      ,cn_last_update_login                                                            -- �ŏI�X�V���O�C��ID
      ,cn_request_id                                                                   -- ���N�G�X�gID
      ,cn_program_application_id                                                       -- �A�v���P�[�V����ID
      ,cn_program_id                                                                   -- �v���O����ID
      ,cd_program_update_date                                                          -- �v���O�����ŏI�X�V��
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_xxcff_gl_trn;
--
  /**********************************************************************************
   * Procedure Name   : set_jnl_amount
   * Description      : �y�������ʏ����z���z�ݒ� (A-22)
   ***********************************************************************************/
  PROCEDURE set_jnl_amount(
    it_jnl_amount_rec IN     jnl_amount_rtype               -- ���[�X�d����z���
   ,iot_jnl_aff_rec   IN OUT lease_journal_ptn_cur%ROWTYPE  -- ���[�X�d��AFF���
   ,ov_errbuf         OUT    VARCHAR2                       --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2                       --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)                      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_jnl_amount'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --================================
    --�����z�ݒ�O���[�v�����z���o
    --================================
--
    --==============================================
    --TEMP_PAY_TAX (���������)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'TEMP_PAY_TAX') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.temp_pay_tax;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.temp_pay_tax;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_BLC (���[�X���c)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_BLC') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_blc;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_TAX_BLC (���[�X���c_�����)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_TAX_BLC') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_tax_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_tax_blc;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_PRETAX_BLC (���[�X���c_�����(�{��+��))
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_PRETAX_BLC') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_pretax_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_pretax_blc;
      END IF;
    END IF;
--
    --==============================================
    --PAY_INTEREST (�x������)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'PAY_INTEREST') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.pay_interest;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.pay_interest;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_AMT (���[�X���z)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_AMT') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_amt;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_amt;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_TAX_AMT (���[�X���z_�����)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_TAX_AMT') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_tax_amt;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_tax_amt;
      END IF;
    END IF;
--
    --==============================================
    --DEDUCTION (���[�X�T���z)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'DEDUCTION') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.deduction;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.deduction;
      END IF;
    END IF;
--
    --==============================================
    --CHARGE (���[�X��)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'CHARGE') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.charge;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.charge;
      END IF;
    END IF;
--
    --==============================================
    --CHARGE_TAX (���[�X��_�����)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'CHARGE_TAX') THEN
      --DR(�ؕ�)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.charge_tax;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(�ݕ�)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.charge_tax;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_jnl_amount;
--
  /**********************************************************************************
   * Procedure Name   : set_lease_class_aff
   * Description      : �y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
   ***********************************************************************************/
  PROCEDURE set_lease_class_aff(
    it_lease_type   IN     xxcff_contract_headers.lease_type%TYPE -- ���[�X�敪
   ,it_lease_class  IN     xxcff_fa_transactions.lease_class%TYPE -- ���[�X���
   ,iot_jnl_aff_rec IN OUT lease_journal_ptn_cur%ROWTYPE          -- ���[�X�d��AFF���
   ,ov_errbuf       OUT    VARCHAR2                               --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT    VARCHAR2                               --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT    VARCHAR2)                              --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_lease_class_aff'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --================
    --�����哱�o
    --================
--
    --==============================================
    --AP_ENTRY (AP���͎��̃��[�X���v�㕔��)
    -- �� ���[�X��_�v�㕔��
    --==============================================
    IF (iot_jnl_aff_rec.department = 'AP_ENTRY') THEN
      iot_jnl_aff_rec.department := g_lease_class_aff_tab(it_lease_class).les_chrg_dep;
    END IF;
--
    --================
    --������Ȗړ��o
    --================
--
    --==============================================
    --LIAB (���[�X��)
    -- �� ���[�X��_�Ȗ�
    --==============================================
    IF (iot_jnl_aff_rec.account = 'LIAB') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).les_liab_acct;
    END IF;
--
    --==============================================
    --PAY_INTEREST (�x������)
    -- �� �x������_�Ȗ�
    --==============================================
    IF (iot_jnl_aff_rec.account = 'PAY_INTEREST') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).pay_int_acct;
    END IF;
--
    --==============================================
    --CHARGE (���[�X��)
    -- �� ���[�X��_�Ȗ�
    --==============================================
    IF (iot_jnl_aff_rec.account = 'CHARGE') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).les_chrg_acct;
    END IF;
--
    --================
    --���⏕�Ȗړ��o
    --================
--
    --==============================================
    --LIAB_LINE (���[�X��_�{��)
    -- �� ���[�X��_�⏕�Ȗ�(�{��)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'LIAB_LINE') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_liab_sub_acct_line;
    END IF;
--
    --==============================================
    --LIAB_TAX (���[�X��_��)
    -- �� ���[�X��_�⏕�Ȗ�(��)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'LIAB_TAX') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_liab_sub_acct_tax;
    END IF;
--
    --==============================================
    --PAY_INTEREST (�x������)
    -- �� �x������_�⏕�Ȗ�(�{��)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'PAY_INTEREST') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).pay_int_sub_acct;
    END IF;
--
    --==============================================
    --CHARGE (���[�X��) AND ���[�X�敪=1 (���_��)
    -- �� ���[�X��_�⏕�Ȗ�(���_��)
    --==============================================
    IF   ( (iot_jnl_aff_rec.sub_account = 'CHARGE')
      AND  (it_lease_type  = 1) ) THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_chrg_sub_acct_orgn;
    END IF;
--
    --==============================================
    --CHARGE (���[�X��) AND ���[�X�敪=2 (�ă��[�X)
    -- �� ���[�X��_�⏕�Ȗ�(�ă��[�X)
    --==============================================
    IF   ( (iot_jnl_aff_rec.sub_account = 'CHARGE')
      AND  (it_lease_type  = 2) ) THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_chrg_sub_acct_reles;
    END IF;
--
  EXCEPTION
      WHEN NO_DATA_FOUND THEN -- *** �f�[�^�擾�G���[
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_020  -- �擾�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                       ,cv_msg_013a20_t_025  -- ���[�X���AFF�l(���[�X��ʃr���[)���
                                                       ,cv_tkn_key_name      -- �g�[�N��'KEY_NAME'
                                                       ,cv_msg_013a20_t_026  -- ���[�X���=
                                                       ,cv_tkn_key_val       -- �g�[�N��'KEY_VAL'
                                                       ,it_lease_class)      -- ���[�X���
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_lease_class_aff;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_cr
   * Description      : GLOIF�o�^����(�ݕ��f�[�^) (A-20)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_cr(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_cr'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    INSERT INTO gl_interface(
       status                -- �X�e�[�^�X
      ,set_of_books_id       -- ��v����ID
      ,accounting_date       -- �d��L�����t
      ,currency_code         -- �ʉ݃R�[�h
      ,date_created          -- �V�K�쐬���t
      ,created_by            -- �V�K�쐬��ID
      ,actual_flag           -- �c���^�C�v
      ,user_je_category_name -- �d��J�e�S����
      ,user_je_source_name   -- �d��\�[�X��
      ,segment1              -- ���
      ,segment2              -- ����
      ,segment3              -- �Ȗ�
      ,segment4              -- �⏕�Ȗ�
      ,segment5              -- �ڋq
      ,segment6              -- ���
      ,segment7              -- �\��1
      ,segment8              -- �\��2
      ,entered_dr            -- �ؕ����z
      ,entered_cr            -- �ݕ����z
      ,reference10           -- �d�󖾍דE�v
      ,period_name           -- ��v���Ԗ�
      ,attribute1            -- �ŋ敪
      ,attribute3            -- �`�[�ԍ�
      ,attribute4            -- �N�[����
      ,attribute5            -- �`�[���͎�
      ,context               -- �R���e�L�X�g
    )
    SELECT
       'NEW'                                       AS status                -- �X�e�[�^�X
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- ��v����ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- �d��L�����t
      ,g_init_rec.currency_code                    AS currency_code         -- �ʉ݃R�[�h
      ,cd_creation_date                            AS date_created          -- �V�K�쐬���t
      ,cn_created_by                               AS created_by            -- �V�K�쐬��ID
      ,'A'                                         AS actual_flag           -- �c���^�C�v
      ,xxcff_gl_trn.je_category                    AS user_je_category_name -- �d��J�e�S����
      ,xxcff_gl_trn.je_source                      AS user_je_source_name   -- �d��\�[�X��
      ,xxcff_gl_trn.company_code                   AS segment1              -- ��ЃR�[�h
      ,xxcff_gl_trn.department_code                AS segment2              -- ����R�[�h
      ,xxcff_gl_trn.account_code                   AS segment3              -- �ȖڃR�[�h
      ,xxcff_gl_trn.sub_account_code               AS segment4              -- �⏕�ȖڃR�[�h
      ,xxcff_gl_trn.customer_code                  AS segment5              -- �ڋq�R�[�h
      ,xxcff_gl_trn.enterprise_code                AS segment6              -- ��ƃR�[�h
      ,xxcff_gl_trn.reserve_1                      AS segment7              -- �\��1
      ,xxcff_gl_trn.reserve_2                      AS segment8              -- �\��2
      ,SUM(xxcff_gl_trn.accounted_dr)              AS entered_dr            -- �ؕ����z
      ,SUM(xxcff_gl_trn.accounted_cr)              AS entered_cr            -- �ݕ����z
      ,xxcff_gl_trn.description                    AS reference10           -- �d�󖾍דE�v
      ,xxcff_gl_trn.period_name                    AS period_name           -- ��v���Ԗ�
      ,xxcff_gl_trn.tax_code                       AS attribute1            -- �ŋ敪
      ,xxcff_gl_trn.slip_number                    AS attribute3            -- �`�[�ԍ�
      ,gt_login_dept_code                          AS attribute4            -- �N�[����
      ,gt_login_user_name                          AS attribute5            -- �`�[���͎�
      ,gt_sob_name                                 AS context               -- ��v���떼
    FROM  xxcff_gl_transactions  xxcff_gl_trn
    WHERE xxcff_gl_trn.period_name = gv_period_name
    AND   xxcff_gl_trn.accounted_cr > 0
    GROUP BY
       xxcff_gl_trn.je_category        -- �d��J�e�S����
      ,xxcff_gl_trn.je_source          -- �d��\�[�X��
      ,xxcff_gl_trn.company_code       -- ��ЃR�[�h
      ,xxcff_gl_trn.department_code    -- ����R�[�h
      ,xxcff_gl_trn.account_code       -- �ȖڃR�[�h
      ,xxcff_gl_trn.sub_account_code   -- �⏕�ȖڃR�[�h
      ,xxcff_gl_trn.customer_code      -- �ڋq�R�[�h
      ,xxcff_gl_trn.enterprise_code    -- ��ƃR�[�h
      ,xxcff_gl_trn.reserve_1          -- �\��1
      ,xxcff_gl_trn.reserve_2          -- �\��2
      ,xxcff_gl_trn.description        -- �d�󖾍דE�v
      ,xxcff_gl_trn.period_name        -- ��v���Ԗ�
      ,xxcff_gl_trn.tax_code           -- �ŋ敪
      ,xxcff_gl_trn.slip_number        -- �`�[�ԍ�
    ;
--
    -- �����ݒ�
    gn_gloif_cr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_oif_cr;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_dr
   * Description      : GLOIF�o�^����(�ؕ��f�[�^) (A-19)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_dr(
    ov_errbuf         OUT    VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT    VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_dr'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    INSERT INTO gl_interface(
       status                -- �X�e�[�^�X
      ,set_of_books_id       -- ��v����ID
      ,accounting_date       -- �d��L�����t
      ,currency_code         -- �ʉ݃R�[�h
      ,date_created          -- �V�K�쐬���t
      ,created_by            -- �V�K�쐬��ID
      ,actual_flag           -- �c���^�C�v
      ,user_je_category_name -- �d��J�e�S����
      ,user_je_source_name   -- �d��\�[�X��
      ,segment1              -- ���
      ,segment2              -- ����
      ,segment3              -- �Ȗ�
      ,segment4              -- �⏕�Ȗ�
      ,segment5              -- �ڋq
      ,segment6              -- ���
      ,segment7              -- �\��1
      ,segment8              -- �\��2
      ,entered_dr            -- �ؕ����z
      ,entered_cr            -- �ݕ����z
      ,reference10           -- �d�󖾍דE�v
      ,period_name           -- ��v���Ԗ�
      ,attribute1            -- �ŋ敪
      ,attribute3            -- �`�[�ԍ�
      ,attribute4            -- �N�[����
      ,attribute5            -- �`�[���͎�
      ,context               -- �R���e�L�X�g
    )
    SELECT
       'NEW'                                       AS status                -- �X�e�[�^�X
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- ��v����ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- �d��L�����t
      ,g_init_rec.currency_code                    AS currency_code         -- �ʉ݃R�[�h
      ,cd_creation_date                            AS date_created          -- �V�K�쐬���t
      ,cn_created_by                               AS created_by            -- �V�K�쐬��ID
      ,'A'                                         AS actual_flag           -- �c���^�C�v
      ,xxcff_gl_trn.je_category                    AS user_je_category_name -- �d��J�e�S����
      ,xxcff_gl_trn.je_source                      AS user_je_source_name   -- �d��\�[�X��
      ,xxcff_gl_trn.company_code                   AS segment1              -- ��ЃR�[�h
      ,xxcff_gl_trn.department_code                AS segment2              -- ����R�[�h
      ,xxcff_gl_trn.account_code                   AS segment3              -- �ȖڃR�[�h
      ,xxcff_gl_trn.sub_account_code               AS segment4              -- �⏕�ȖڃR�[�h
      ,xxcff_gl_trn.customer_code                  AS segment5              -- �ڋq�R�[�h
      ,xxcff_gl_trn.enterprise_code                AS segment6              -- ��ƃR�[�h
      ,xxcff_gl_trn.reserve_1                      AS segment7              -- �\��1
      ,xxcff_gl_trn.reserve_2                      AS segment8              -- �\��2
      ,SUM(xxcff_gl_trn.accounted_dr)              AS entered_dr            -- �ؕ����z
      ,SUM(xxcff_gl_trn.accounted_cr)              AS entered_cr            -- �ݕ����z
      ,xxcff_gl_trn.description                    AS reference10           -- �d�󖾍דE�v
      ,xxcff_gl_trn.period_name                    AS period_name           -- ��v���Ԗ�
      ,xxcff_gl_trn.tax_code                       AS attribute1            -- �ŋ敪
      ,xxcff_gl_trn.slip_number                    AS attribute3            -- �`�[�ԍ�
      ,gt_login_dept_code                          AS attribute4            -- �N�[����
      ,gt_login_user_name                          AS attribute5            -- �`�[���͎�
      ,gt_sob_name                                 AS context               -- ��v���떼
    FROM  xxcff_gl_transactions  xxcff_gl_trn
    WHERE xxcff_gl_trn.period_name = gv_period_name
    AND   xxcff_gl_trn.accounted_dr > 0
    GROUP BY
       xxcff_gl_trn.je_category        -- �d��J�e�S����
      ,xxcff_gl_trn.je_source          -- �d��\�[�X��
      ,xxcff_gl_trn.company_code       -- ��ЃR�[�h
      ,xxcff_gl_trn.department_code    -- ����R�[�h
      ,xxcff_gl_trn.account_code       -- �ȖڃR�[�h
      ,xxcff_gl_trn.sub_account_code   -- �⏕�ȖڃR�[�h
      ,xxcff_gl_trn.customer_code      -- �ڋq�R�[�h
      ,xxcff_gl_trn.enterprise_code    -- ��ƃR�[�h
      ,xxcff_gl_trn.reserve_1          -- �\��1
      ,xxcff_gl_trn.reserve_2          -- �\��2
      ,xxcff_gl_trn.description        -- �d�󖾍דE�v
      ,xxcff_gl_trn.period_name        -- ��v���Ԗ�
      ,xxcff_gl_trn.tax_code           -- �ŋ敪
      ,xxcff_gl_trn.slip_number        -- �`�[�ԍ�
    ;
--
    -- �����ݒ�
    gn_gloif_dr_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_gl_oif_dr;
--
  /**********************************************************************************
   * Procedure Name   : update_pay_plan_if_flag
   * Description      : ���[�X�x���v�� �A�g�t���O�X�V (A-18)
   ***********************************************************************************/
  PROCEDURE update_pay_plan_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_pay_plan_if_flag'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_pay_planning
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vIF�t���O 
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             contract_line_id       = g_contract_line_id_tab(ln_loop_cnt)
      AND    payment_frequency      = g_payment_frequency_tab(ln_loop_cnt)
      ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_pay_plan_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_dept_dist_sagara
   * Description      :�y�d��p�^�[���z���[�X�����啊��(�H��) (A-17)
   ***********************************************************************************/
  PROCEDURE proc_ptn_dept_dist_sagara(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_dept_dist_sagara'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_dept_dist_sagara>>
    FOR ln_ptn_loop_cnt IN g_ptn_dept_dist_sagara_tab.FIRST .. g_ptn_dept_dist_sagara_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_dept_dist_sagara_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_dept_dist_sagara;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_dept_dist_sagara;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_dept_dist_itoen
   * Description      :�y�d��p�^�[���z���[�X�����啊��(�{��) (A-16)
   ***********************************************************************************/
  PROCEDURE proc_ptn_dept_dist_itoen(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_dept_dist_itoen'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_dept_dist_itoen>>
    FOR ln_ptn_loop_cnt IN g_ptn_dept_dist_itoen_tab.FIRST .. g_ptn_dept_dist_itoen_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_dept_dist_itoen_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�Ǘ�����,�ڋq�R�[�h�ݒ�
      --==============================================================
      --�ݎ؋敪���uDR�v(�ؕ�)�̏ꍇ
      IF (g_les_jnl_aff_rec.crdr_type = 'DR') THEN
        g_les_jnl_aff_rec.department := g_department_code_tab(gn_main_loop_cnt); -- ����(SEG2)
        --���[�X��ʂ����̋@,SH�֘A�̏ꍇ
        IF (NVL(g_vdsh_flag_tab(gn_main_loop_cnt),'N') = ('Y')) THEN
          g_les_jnl_aff_rec.partner    := g_customer_code_tab(gn_main_loop_cnt); -- �ڋq(SEG5)
        END IF;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_dept_dist_itoen;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_dept_dist_itoen;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_debt_trsf
   * Description      : �y�d��p�^�[���z���[�X���U�� (A-15)
   ***********************************************************************************/
  PROCEDURE proc_ptn_debt_trsf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_debt_trsf'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_debt_trsf>>
    FOR ln_ptn_loop_cnt IN g_ptn_debt_trsf_tab.FIRST .. g_ptn_debt_trsf_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_debt_trsf_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --��ЃR�[�h�ݒ�
      --==============================================================
      --�{�Ђ̏ꍇ�ˉ�ЃR�[�h�u001�v�ݒ�
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --�H��̏ꍇ�ˉ�ЃR�[�h�u999�v�ݒ�
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --�ŃR�[�h�ݒ�
      --==============================================================
      --�ݎ؋敪���uCR�v(�ݕ�)�̏ꍇ�ːŃR�[�h�ݒ�
      IF (g_les_jnl_aff_rec.crdr_type = 'CR') THEN
        g_les_jnl_aff_rec.tax_code := g_tax_code_tab(gn_main_loop_cnt);
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_debt_trsf;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_debt_trsf;
--
  /**********************************************************************************
   * Procedure Name   : ctrl_jnl_ptn_pay_plan
   * Description      : �d��p�^�[������(�x���v��) (A-15) ? (A-17)
   ***********************************************************************************/
  PROCEDURE ctrl_jnl_ptn_pay_plan(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ctrl_jnl_ptn_pay_plan'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_main_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����A
    --==============================================================
    <<ctrl_jnl_ptn_pay_plan>>
    FOR ln_main_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_main_loop_cnt := ln_main_loop_cnt;
--
      --==============================================================
      --�d�󌳃L�[���ݒ�
      --==============================================================
      g_les_jnl_key_rec.fa_transaction_id  := NULL;                                       -- ���[�X�������ID
      g_les_jnl_key_rec.contract_header_id := g_contract_header_id_tab(gn_main_loop_cnt); -- ���[�X�_�����ID
      g_les_jnl_key_rec.contract_line_id   := g_contract_line_id_tab(gn_main_loop_cnt);   -- ���[�X�_�񖾍ד���ID
      g_les_jnl_key_rec.object_header_id   := g_object_header_id_tab(gn_main_loop_cnt);   -- ���[�X��������ID
      g_les_jnl_key_rec.payment_frequency  := g_payment_frequency_tab(gn_main_loop_cnt);  -- �x����
--
      --==============================================================
      --�d����z���ݒ�
      --==============================================================
      g_jnl_amount_rec.temp_pay_tax        := NULL;                                    -- ���������
      g_jnl_amount_rec.liab_blc            := NULL;                                    -- ���[�X���c
      g_jnl_amount_rec.liab_tax_blc        := NULL;                                    -- ���[�X���c_�����
      g_jnl_amount_rec.liab_pretax_blc     := NULL;                                    -- ���[�X���c�i�{�́{�Łj
      g_jnl_amount_rec.pay_interest        := g_pay_interest_tab(gn_main_loop_cnt);    -- �x������
      g_jnl_amount_rec.liab_amt            := g_liab_amt_tab(gn_main_loop_cnt);        -- ���[�X���z
      g_jnl_amount_rec.liab_tax_amt        := g_liab_tax_amt_tab(gn_main_loop_cnt);    -- ���[�X���z_�����
      g_jnl_amount_rec.deduction           := g_deduction_tab(gn_main_loop_cnt);       -- ���[�X�T���z
      g_jnl_amount_rec.charge              := g_charge_tab(gn_main_loop_cnt);          -- ���[�X��
      g_jnl_amount_rec.charge_tax          := g_charge_tax_tab(gn_main_loop_cnt);      -- ���[�X��_�����
--
      --==============================================================
      --���[�X��� = 0 (Fin)
      --���[�X�敪 = 1 (���_��)
      --==============================================================
      IF ( g_lease_kind_tab(gn_main_loop_cnt) = cv_lease_kind_fin
      AND  g_lease_type_tab(gn_main_loop_cnt) = cv_original        ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z���[�X���U�� (A-15)
        --==============================================================
        proc_ptn_debt_trsf(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      --�{�ЍH��敪 = �{��
      --==============================================================
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z���[�X�����啊��(�{��) (A-16)
        --==============================================================
        proc_ptn_dept_dist_itoen(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --�{�ЍH��敪 = �H��
      --==============================================================
      ELSE
--
        --==============================================================
        --�y�d��p�^�[���z���[�X�����啊��(�H��) (A-17)
        --==============================================================
        proc_ptn_dept_dist_sagara(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP ctrl_jnl_ptn_pay_plan;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ctrl_jnl_ptn_pay_plan;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_plan_data
   * Description      : �d�󌳃f�[�^(�x���v��)���o (A-14)
   ***********************************************************************************/
  PROCEDURE get_pay_plan_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pay_plan_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- *** ���[�J���ϐ� ***
-- T1_0356 2009/04/17 ADD START --
    lv_department_code  xxcff_object_histories.department_code%TYPE;  --�Ǘ�����
-- T1_0356 2009/04/17 ADD END   --
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
-- T1_0356 2009/04/17 ADD START --
    --==============================================================
    --�����c�Ɠ��̔���
    --==============================================================
    -- �I�����C���I�������r����B
    IF (gv_online_end_time >= cv_online_end_time) THEN
      --�����c�Ɠ��ɂP�����Z����B
      gd_base_date := gd_base_date + 1;
    END IF;
-- T1_0356 2009/04/17 ADD END   --
--
    --==============================================================
    --�d�󌳃f�[�^(�x���v��)���o
    --==============================================================
    OPEN  get_pay_plan_data_cur;
-- T1_0356 2009/04/17 MOD START --
--  FETCH get_pay_plan_data_cur
--  BULK COLLECT INTO 
--                    g_contract_header_id_tab -- �_�����ID
--                   ,g_contract_line_id_tab   -- �_�񖾍ד���ID
--                   ,g_object_header_id_tab   -- ��������ID
--                   ,g_payment_frequency_tab  -- �x����
--                   ,g_period_name_tab        -- ��v���Ԗ�
--                   ,g_lease_kind_tab         -- ���[�X���
--                   ,g_lease_class_tab        -- ���[�X���
--                   ,g_vdsh_flag_tab          -- ���̋@SH�t���O
--                   ,g_lease_type_tab         -- ���[�X�敪
--                   ,g_department_code_tab    -- �Ǘ�����
--                   ,g_owner_company_tab      -- �{�Ё^�H��
--                   ,g_customer_code_tab      -- �ڋq�R�[�h
--                   ,g_pay_interest_tab       -- �x������
--                   ,g_liab_amt_tab           -- ���[�X���z
--                   ,g_liab_tax_amt_tab       -- ���[�X���z_�����
--                   ,g_deduction_tab          -- ���[�X�T���z
--                   ,g_charge_tab             -- ���[�X��
--                   ,g_charge_tax_tab         -- ���[�X��_�����
--                   ,g_tax_code_tab           -- �ŃR�[�h
--                   ;
--
--  --�Ώی����J�E���g
--  gn_pay_plan_target_cnt := g_contract_header_id_tab.COUNT;
--
    --�Ώی����̏�����
    gn_pay_plan_target_cnt := 0;
--
    LOOP
      FETCH get_pay_plan_data_cur INTO g_get_pay_plan_data_rec;
      EXIT WHEN get_pay_plan_data_cur%NOTFOUND;
      --�Ώی����̃J�E���g
      gn_pay_plan_target_cnt := gn_pay_plan_target_cnt + 1;
--
      g_contract_header_id_tab(gn_pay_plan_target_cnt) := g_get_pay_plan_data_rec.contract_header_id;  -- �_�����ID
      g_contract_line_id_tab(gn_pay_plan_target_cnt)   := g_get_pay_plan_data_rec.contract_line_id;    -- �_�񖾍ד���ID
      g_object_header_id_tab(gn_pay_plan_target_cnt)   := g_get_pay_plan_data_rec.object_header_id;    -- ��������ID
      g_payment_frequency_tab(gn_pay_plan_target_cnt)  := g_get_pay_plan_data_rec.payment_frequency;   -- �x����
      g_period_name_tab(gn_pay_plan_target_cnt)        := g_get_pay_plan_data_rec.period_name;         -- ��v���Ԗ�
      g_lease_kind_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.lease_kind;          -- ���[�X���
      g_lease_class_tab(gn_pay_plan_target_cnt)        := g_get_pay_plan_data_rec.lease_class;         -- ���[�X���
      g_vdsh_flag_tab(gn_pay_plan_target_cnt)          := g_get_pay_plan_data_rec.vdsh_flag;           -- ���̋@SH�t���O
      g_lease_type_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.lease_type;          -- ���[�X�敪
      g_department_code_tab(gn_pay_plan_target_cnt)    := g_get_pay_plan_data_rec.department_code;     -- �Ǘ�����
      g_owner_company_tab(gn_pay_plan_target_cnt)      := g_get_pay_plan_data_rec.owner_company;       -- �{�Ё^�H��
      g_customer_code_tab(gn_pay_plan_target_cnt)      := g_get_pay_plan_data_rec.customer_code;       -- �ڋq�R�[�h
      g_pay_interest_tab(gn_pay_plan_target_cnt)       := g_get_pay_plan_data_rec.pay_interest;        -- �x������
      g_liab_amt_tab(gn_pay_plan_target_cnt)           := g_get_pay_plan_data_rec.liab_amt;            -- ���[�X���z
      g_liab_tax_amt_tab(gn_pay_plan_target_cnt)       := g_get_pay_plan_data_rec.liab_tax_amt;        -- ���[�X���z_�����
      g_deduction_tab(gn_pay_plan_target_cnt)          := g_get_pay_plan_data_rec.deduction;           -- ���[�X�T���z
      g_charge_tab(gn_pay_plan_target_cnt)             := g_get_pay_plan_data_rec.charge;              -- ���[�X��
      g_charge_tax_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.charge_tax;          -- ���[�X��_�����
      g_tax_code_tab(gn_pay_plan_target_cnt)           := g_get_pay_plan_data_rec.tax_code;            -- �ŃR�[�h
--
      --���[�X�����������擾�ł���ꍇ�̓��[�X���������̈ړ����Ǘ������ݒ肷��B
      BEGIN
        SELECT   xoh.m_department_code
        INTO     lv_department_code
        FROM     xxcff_object_histories xoh
        WHERE    xoh.object_header_id =  g_get_pay_plan_data_rec.object_header_id
        AND      xoh.creation_date    >  gd_base_date
        AND      xoh.object_status    =  cv_object_status_105
        AND      rownum = 1
        ORDER BY creation_date ASC;
      --�Y���f�[�^�����݂��Ȃ��ꍇ�̓��[�X�����̊Ǘ������ݒ肷��B
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_department_code := g_get_pay_plan_data_rec.department_code; 
      END;
      g_department_code_tab(gn_pay_plan_target_cnt) := lv_department_code; --�Ǘ�������Đݒ肷��B
    END LOOP;
-- T1_0356 2009/04/17 END  --
--
    CLOSE get_pay_plan_data_cur;
--
    IF ( gn_pay_plan_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_022) -- ���[�X�d��(�d��=�x���v��)���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
-- T1_0356 2009/04/17 ADD START --
      IF (get_pay_plan_data_cur%ISOPEN) THEN
        CLOSE get_pay_plan_data_cur;
      END IF;
-- T1_0356 2009/04/17 ADD END   --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_pay_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : update_les_trns_gl_if_flag
   * Description      : ���[�X��� �d��A�g�t���O�X�V (A-13)
   ***********************************************************************************/
  PROCEDURE update_les_trns_gl_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_les_trns_gl_if_flag'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT
      UPDATE xxcff_fa_transactions
      SET
             gl_if_flag             = cv_if_aft                 -- GL�A�g�t���O 
            ,gl_if_date             = g_init_rec.process_date   -- �v���
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             fa_transaction_id      = g_fa_transaction_id_tab(ln_loop_cnt)
      ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_les_trns_gl_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_retire
   * Description      : �y�d��p�^�[���z��� (A-12)
   ***********************************************************************************/
  PROCEDURE proc_ptn_retire(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_retire'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_retire>>
    FOR ln_ptn_loop_cnt IN g_ptn_retire_tab.FIRST .. g_ptn_retire_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_retire_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --��ЃR�[�h�ݒ�
      --==============================================================
      --�{�Ђ̏ꍇ�ˉ�ЃR�[�h�u001�v�ݒ�
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --�H��̏ꍇ�ˉ�ЃR�[�h�u999�v�ݒ�
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_retire;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_retire;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_move_to_itoen
   * Description      : �y�d��p�^�[���z�U��(�H��˖{��) (A-11)
   ***********************************************************************************/
  PROCEDURE proc_ptn_move_to_itoen(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_move_to_itoen'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_move_to_itoen>>
    FOR ln_ptn_loop_cnt IN g_ptn_move_to_itoen_tab.FIRST .. g_ptn_move_to_itoen_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_move_to_itoen_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_move_to_itoen;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_move_to_itoen;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_move_to_sagara
   * Description      : �y�d��p�^�[���z�U��(�{�ЁˍH��) (A-10)
   ***********************************************************************************/
  PROCEDURE proc_ptn_move_to_sagara(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_move_to_sagara'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_move_to_sagara>>
    FOR ln_ptn_loop_cnt IN g_ptn_move_to_sagara_tab.FIRST .. g_ptn_move_to_sagara_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_move_to_sagara_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_move_to_sagara;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_move_to_sagara;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_tax
   * Description      : �y�d��p�^�[���z�V�K�ǉ� (A-9)
   ***********************************************************************************/
  PROCEDURE proc_ptn_tax(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_tax'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�T�u���[�v����
    --==============================================================
    <<proc_ptn_tax>>
    FOR ln_ptn_loop_cnt IN g_ptn_tax_tab.FIRST .. g_ptn_tax_tab.LAST LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --���[�X�d��AFF���֎d��p�^�[���̃f�t�H���g�l�ݒ�
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_tax_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --�y�������ʏ����z���[�X���AFF�l�ݒ� (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- ���[�X�敪
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- ���[�X���
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- ���[�X�d��AFF���
        ,ov_errbuf       => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode      => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���z�ݒ� (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- ���[�X�d����z���
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --��ЃR�[�h�ݒ�
      --==============================================================
      --�{�Ђ̏ꍇ�ˉ�ЃR�[�h�u001�v�ݒ�
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --�H��̏ꍇ�ˉ�ЃR�[�h�u999�v�ݒ�
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --�ŃR�[�h�ݒ�
      --==============================================================
      --�ݎ؋敪���uDR�v(�ؕ�)�̏ꍇ�ːŃR�[�h�ݒ�
      IF (g_les_jnl_aff_rec.crdr_type = 'DR') THEN
        g_les_jnl_aff_rec.tax_code := g_tax_code_tab(gn_main_loop_cnt);
      END IF;
--
      --==============================================================
      --�y�������ʏ����z���[�X�d��e�[�u���o�^ (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- ���[�X�d�󌳃L�[���
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- ���[�X�d��AFF���
        ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_tax;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ptn_tax;
--
  /**********************************************************************************
   * Procedure Name   : ctrl_jnl_ptn_les_trn
   * Description      : �d��p�^�[������(���[�X���) (A-9) ? (A-12)
   ***********************************************************************************/
  PROCEDURE ctrl_jnl_ptn_les_trn(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ctrl_jnl_ptn_les_trn'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_main_loop_cnt NUMBER := 0;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����@
    --==============================================================
    <<ctrl_jnl_ptn_les_trn>>
    FOR ln_main_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT LOOP
--
      --���[�v�J�E���^�ݒ�
      gn_main_loop_cnt := ln_main_loop_cnt;
--
      --==============================================================
      --�d�󌳃L�[���ݒ�
      --==============================================================
      g_les_jnl_key_rec.fa_transaction_id  := g_fa_transaction_id_tab(gn_main_loop_cnt);  -- ���[�X�������ID
      g_les_jnl_key_rec.contract_header_id := g_contract_header_id_tab(gn_main_loop_cnt); -- ���[�X�_�����ID
      g_les_jnl_key_rec.contract_line_id   := g_contract_line_id_tab(gn_main_loop_cnt);   -- ���[�X�_�񖾍ד���ID
      g_les_jnl_key_rec.object_header_id   := g_object_header_id_tab(gn_main_loop_cnt);   -- ���[�X��������ID
      g_les_jnl_key_rec.payment_frequency  := NULL;                                       -- �x����
--
      --==============================================================
      --�d����z���ݒ�
      --==============================================================
      g_jnl_amount_rec.temp_pay_tax        := g_temp_pay_tax_tab(gn_main_loop_cnt);    -- ���������
      g_jnl_amount_rec.liab_blc            := g_liab_blc_tab(gn_main_loop_cnt);        -- ���[�X���c
      g_jnl_amount_rec.liab_tax_blc        := g_liab_tax_blc_tab(gn_main_loop_cnt);    -- ���[�X���c_�����
      g_jnl_amount_rec.liab_pretax_blc     := g_liab_pretax_blc_tab(gn_main_loop_cnt); -- ���[�X���c�i�{�́{�Łj
      g_jnl_amount_rec.pay_interest        := NULL;                                    -- �x������
      g_jnl_amount_rec.liab_amt            := NULL;                                    -- ���[�X���z
      g_jnl_amount_rec.liab_tax_amt        := NULL;                                    -- ���[�X���z_�����
      g_jnl_amount_rec.deduction           := NULL;                                    -- ���[�X�T���z
      g_jnl_amount_rec.charge              := NULL;                                    -- ���[�X��
      g_jnl_amount_rec.charge_tax          := NULL;                                    -- ���[�X��_�����
--
      --==============================================================
      --����^�C�v = 1 (�ǉ�)
      --==============================================================
      IF ( g_transaction_type_tab(gn_main_loop_cnt) = 1 ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z�V�K�ǉ� (A-9)
        --==============================================================
        proc_ptn_tax(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --����^�C�v = 2 (�U��)
      --�ړ��^�C�v = 1 (�{�ЁˍH��)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 2
        AND   g_movement_type_tab(gn_main_loop_cnt)    = 1 ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z�U��(�{�ЁˍH��) (A-10)
        --==============================================================
        proc_ptn_move_to_sagara(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --����^�C�v = 2 (�U��)
      --�ړ��^�C�v = 2 (�H��˖{��)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 2
        AND   g_movement_type_tab(gn_main_loop_cnt)    = 2 ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z�U��(�H��˖{��) (A-11)
        --==============================================================
        proc_ptn_move_to_itoen(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --����^�C�v = 3 (���)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 3 ) THEN
--
        --==============================================================
        --�y�d��p�^�[���z��� (A-12)
        --==============================================================
        proc_ptn_retire(
           ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP ctrl_jnl_ptn_les_trn;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ctrl_jnl_ptn_les_trn;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_data
   * Description      : �d�󌳃f�[�^(���[�X���)���o (A-8)
   ***********************************************************************************/
  PROCEDURE get_les_trn_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --==============================================================
    --�d�󌳃f�[�^(���[�X���)���o
    --==============================================================
    OPEN  get_les_trn_data_cur;
    FETCH get_les_trn_data_cur
    BULK COLLECT INTO 
                      g_fa_transaction_id_tab  -- ���[�X�������ID
                     ,g_contract_header_id_tab -- �_�����ID
                     ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                     ,g_object_header_id_tab   -- ��������ID
                     ,g_period_name_tab        -- ��v���Ԗ�
                     ,g_transaction_type_tab   -- ����^�C�v
                     ,g_movement_type_tab      -- �ړ��^�C�v
                     ,g_lease_class_tab        -- ���[�X���
                     ,g_lease_type_tab         -- ���[�X�敪
                     ,g_owner_company_tab      -- �{�Ё^�H��
                     ,g_temp_pay_tax_tab       -- ��������Ŋz
                     ,g_liab_blc_tab           -- ���[�X���c
                     ,g_liab_tax_blc_tab       -- ���[�X���c_�����
                     ,g_liab_pretax_blc_tab    -- ���[�X���c_�{�́{��
                     ,g_tax_code_tab           -- �ŃR�[�h
                     ;
    --�Ώی����J�E���g
    gn_les_trn_target_cnt := g_fa_transaction_id_tab.COUNT;
    CLOSE get_les_trn_data_cur;
--
    IF ( gn_les_trn_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_021) -- ���[�X�d��(�d��=���[�X���)���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      IF (get_les_trn_data_cur%ISOPEN) THEN
        CLOSE get_les_trn_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_jnl_pattern
   * Description      : ���[�X�d��p�^�[�����擾 (A-7)
   ***********************************************************************************/
  PROCEDURE get_lease_jnl_pattern(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_jnl_pattern'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���������:1)
    --==============================================================
    OPEN  lease_journal_ptn_cur(1);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_tax_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���Y�ړ�(�{�ЁˍH��):2)
    --==============================================================
    OPEN  lease_journal_ptn_cur(2);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_move_to_sagara_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���Y�ړ�(�H��˖{��):3)
    --==============================================================
    OPEN  lease_journal_ptn_cur(3);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_move_to_itoen_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���:4)
    --==============================================================
    OPEN  lease_journal_ptn_cur(4);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_retire_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���[�X���U��:5)
    --==============================================================
    OPEN  lease_journal_ptn_cur(5);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_debt_trsf_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���[�X�����啊��(�{��):6)
    --==============================================================
    OPEN  lease_journal_ptn_cur(6);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_dept_dist_itoen_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --���[�X�d��p�^�[���擾 (���[�X�����啊��(�H��):7)
    --==============================================================
    OPEN  lease_journal_ptn_cur(7);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_dept_dist_sagara_tab;
    CLOSE lease_journal_ptn_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      IF (lease_journal_ptn_cur%ISOPEN) THEN
        CLOSE lease_journal_ptn_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease_jnl_pattern;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_class_aff_info
   * Description      : ���[�X��ʖ���AFF���擾 (A-6)
   ***********************************************************************************/
  PROCEDURE get_lease_class_aff_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_class_aff_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lt_lease_class  xxcff_lease_class_v.lease_class_code%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN lease_class_cur;
    <<lease_class_cur_loop>>
    LOOP
      -- �J�[�\���t�F�b�`
      FETCH lease_class_cur INTO g_lease_class_rec;
      EXIT WHEN lease_class_cur%NOTFOUND;
      -- �e�[�u���^�z��ݒ�
      lt_lease_class := g_lease_class_rec.lease_class_code;
      g_lease_class_aff_tab(lt_lease_class).les_liab_acct           := g_lease_class_rec.les_liab_acct;           -- ���[�X��_�Ȗ�
      g_lease_class_aff_tab(lt_lease_class).les_liab_sub_acct_line  := g_lease_class_rec.les_liab_sub_acct_line;  -- ���[�X��_�⏕�Ȗ�(�{��)
      g_lease_class_aff_tab(lt_lease_class).les_liab_sub_acct_tax   := g_lease_class_rec.les_liab_sub_acct_tax;   -- ���[�X��_�⏕�Ȗ�(��)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_acct           := g_lease_class_rec.les_chrg_acct;           -- ���[�X��_�Ȗ�
      g_lease_class_aff_tab(lt_lease_class).les_chrg_sub_acct_orgn  := g_lease_class_rec.les_chrg_sub_acct_orgn;  -- ���[�X��_�⏕�Ȗ�(���_��)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_sub_acct_reles := g_lease_class_rec.les_chrg_sub_acct_reles; -- ���[�X��_�⏕�Ȗ�(�ă��[�X)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_dep            := g_lease_class_rec.les_chrg_dep;            -- ���[�X��_�v�㕔��
      g_lease_class_aff_tab(lt_lease_class).pay_int_acct            := g_lease_class_rec.pay_int_acct;            -- �x������_�Ȗ�
      g_lease_class_aff_tab(lt_lease_class).pay_int_sub_acct        := g_lease_class_rec.pay_int_sub_acct;        -- �x������_�⏕�Ȗ�(�{��)
    END LOOP lease_class_cur_loop;
    -- �J�[�\���N���[�Y
    CLOSE lease_class_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      IF (lease_class_cur%ISOPEN) THEN
        CLOSE lease_class_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lease_class_aff_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_target_data
   * Description      : �������f�[�^�X�V (A-5)
   ***********************************************************************************/
  PROCEDURE upd_target_data(
    ov_errbuf           OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode          OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_target_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���b�N�p�J�[�\��(���[�X���)
    CURSOR lock_xxcff_fa_trn
    IS
      SELECT
             xxcff_fa_trn.fa_transaction_id  AS fa_transaction_id  -- ���[�X�������ID
      FROM
             xxcff_fa_transactions  xxcff_fa_trn  -- ���[�X���
            ,xxcff_lease_kind_v     xlk           -- ���[�X��ރr���[
      WHERE
             xxcff_fa_trn.period_name    =   gv_period_name
         AND xxcff_fa_trn.gl_if_flag     IN  (cv_if_yet,cv_if_aft) -- �����M(1),�A�g��(2)
         AND xlk.lease_kind_code         =   cv_lease_kind_fin     -- FIN���[�X
         AND xxcff_fa_trn.book_type_code =   xlk.book_type_code
         FOR UPDATE OF xxcff_fa_trn.fa_transaction_id
         NOWAIT
         ;
--
    -- ���b�N�p�J�[�\��(�x���v��)
    CURSOR lock_pay_plan
    IS
      SELECT
             pay_plan.contract_line_id  AS contract_line_id  -- �_�񖾍ד���ID
      FROM
             xxcff_pay_planning  pay_plan      -- ���[�X�x���v��
      WHERE
             pay_plan.period_name        =   gv_period_name
         AND pay_plan.accounting_if_flag IN  (cv_if_yet,cv_if_aft) -- �����M(1),�A�g��(2)
         AND pay_plan.payment_match_flag =   cv_match              --�ƍ���(1)
         FOR UPDATE NOWAIT
         ;
--
    -- ���b�N�p�J�[�\��(���[�X�d��)
    CURSOR lock_xxcff_gl_trn
    IS
      SELECT
             xxcff_gl_trn.gl_transaction_id  AS gl_transaction_id  -- ���[�X�d�����ID
      FROM
             xxcff_gl_transactions  xxcff_gl_trn  -- ���[�X�d��
      WHERE
             xxcff_gl_trn.period_name = gv_period_name
         FOR UPDATE NOWAIT
         ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�N�����˃��[�X���
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_xxcff_fa_trn;
      -- �J�[�\���N���[�Y
      CLOSE lock_xxcff_fa_trn;
      -- GL�A�gIF�t���O�X�V
      UPDATE xxcff_fa_transactions
      SET
             gl_if_flag             = cv_if_yet                 -- GL�A�g�t���O 
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             period_name            =   gv_period_name
        AND  gl_if_flag             IN  (cv_if_yet,cv_if_aft) -- �����M(1),�A�g��(2)
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_xxcff_fa_trn%ISOPEN) THEN
          CLOSE lock_xxcff_fa_trn;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_013) -- ���[�X���
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�N�����˃��[�X�x���v��
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_pay_plan;
      -- �J�[�\���N���[�Y
      CLOSE lock_pay_plan;
      -- ��vIF�t���O�X�V
      UPDATE xxcff_pay_planning
      SET
             accounting_if_flag     = cv_if_yet                 -- ��vIF�t���O
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             period_name            =   gv_period_name
      AND    accounting_if_flag     IN  (cv_if_yet,cv_if_aft) -- �����M(1),�A�g��(2)
      AND    payment_match_flag     =   cv_match              -- �ƍ���(1)
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_pay_plan%ISOPEN) THEN
          CLOSE lock_pay_plan;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_014) -- ���[�X�x���v��
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�N�����˃��[�X�d��
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_xxcff_gl_trn;
      -- �J�[�\���N���[�Y
      CLOSE lock_xxcff_gl_trn;
      -- ��vIF�t���O�X�V
      DELETE
      FROM   xxcff_gl_transactions
      WHERE  period_name = gv_period_name
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_xxcff_gl_trn%ISOPEN) THEN
          CLOSE lock_xxcff_gl_trn;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_015) -- ���[�X�d��
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      -- �J�[�\���N���[�Y
      IF (lock_xxcff_fa_trn%ISOPEN) THEN
        CLOSE lock_xxcff_fa_trn;
      END IF;
      IF (lock_pay_plan%ISOPEN) THEN
        CLOSE lock_pay_plan;
      END IF;
      IF (lock_xxcff_gl_trn%ISOPEN) THEN
        CLOSE lock_xxcff_gl_trn;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_target_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_je_lease_data_exist
   * Description      : �O��쐬�ς݃��[�X�d�󑶍݃`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_je_lease_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_je_lease_data_exist'; -- �v���O������
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
    -- ����
    ln_cnt_gloif  NUMBER; -- ��ʉ�vOIF
    ln_cnt_glhead NUMBER; -- �d��w�b�_
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --======================================
    -- ��ʉ�vOIF ���݃`�F�b�N
    --======================================
    SELECT
           COUNT(gloif.set_of_books_id)
      INTO
           ln_cnt_gloif
      FROM
           gl_interface    gloif -- ��ʉ�vOIF
     WHERE
           gloif.user_je_source_name = gv_je_src_lease
       AND gloif.period_name         = gv_period_name
       ;
--
    IF ( NVL(ln_cnt_gloif,0) >= 1 ) THEN
      RAISE chk_cnt_gloif_expt;
    END IF;
--
    --======================================
    -- �d��w�b�_ ���݃`�F�b�N
    --======================================
    SELECT
           COUNT(glhead.je_header_id)
      INTO
           ln_cnt_glhead
      FROM
            gl_je_headers     glhead  -- �d��w�b�_
           ,gl_je_sources_tl  glsouce -- �d��\�[�X
     WHERE
           glhead.je_source            = glsouce.je_source_name
       AND glsouce.language            = USERENV('LANG')
       AND glsouce.user_je_source_name = gv_je_src_lease
       AND glhead.period_name  = gv_period_name
       ;
--
    IF ( NVL(ln_cnt_glhead,0) >= 1 ) THEN
      RAISE chk_cnt_glhead_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���[�X�d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[�n���h�� ***
    WHEN chk_cnt_gloif_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_013  -- ���[�X�d�󑶍݃`�F�b�N(��ʉ�vOIF)�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���[�X�d�󑶍݃`�F�b�N(�d��w�b�_)�G���[�n���h�� ***
    WHEN chk_cnt_glhead_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_014  -- ���[�X�d�󑶍݃`�F�b�N(�d��w�b�_)�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_je_lease_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    -- ���Y�䒠��
    lv_book_type_code VARCHAR(100);
    -- ��v���ԃX�e�[�^�X
    lv_closing_status VARCHAR(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_cur
    IS
      SELECT
             fdp.deprn_run        AS deprn_run      -- �������p���s�t���O
            ,fdp.book_type_code   AS book_type_code -- ���Y�䒠��
        FROM
             fa_deprn_periods     fdp   -- �������p����
            ,xxcff_lease_kind_v   xlk   -- ���[�X��ރr���[
       WHERE
             xlk.lease_kind_code IN (cv_lease_kind_fin, cv_lease_kind_lfin)
         AND fdp.book_type_code  =  xlk.book_type_code
         AND fdp.period_name     =  gv_period_name
           ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --======================================
    -- FA��v���ԃ`�F�b�N
    --======================================
    -- �J�[�\���I�[�v��
    OPEN period_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- �������p���s�t���O
                      ,g_book_type_code_tab -- ���Y�䒠��
    ;
    -- �J�[�\���N���[�Y
    CLOSE period_cur;
--
    -- ��v���Ԃ̎擾�������[�����˃G���[
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- �������p�����s����Ă��Ȃ��˃G���[
      IF NVL(g_deprn_run_tab(ln_loop_cnt),'N') <> 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
    --======================================
    -- GL��v���ԃ`�F�b�N
    --======================================
    BEGIN
      -- ��v���ԃX�e�[�^�X�擾
      SELECT
             glperiodst.closing_status
        INTO
             lv_closing_status
        FROM
              fa_book_controls    fbc        -- ���Y�䒠�}�X�^
             ,gl_sets_of_books    gsob       -- ��v����}�X�^
             ,gl_periods          glperiod   -- ��v�J�����_
             ,gl_period_statuses  glperiodst -- ��v�J�����_�X�e�[�^�X
             ,fnd_application     fndappl    -- �A�v���P�[�V����
             ,xxcff_lease_kind_v  les_kind   -- ���[�X��ރr���[
       WHERE
             les_kind.lease_kind_code          = cv_lease_kind_fin -- Fin
         AND les_kind.book_type_code           = fbc.book_type_code
         AND fbc.set_of_books_id               = gsob.set_of_books_id
         AND gsob.period_set_name              = glperiod.period_set_name
         AND glperiod.period_name              = gv_period_name
         AND gsob.set_of_books_id              = glperiodst.set_of_books_id
         AND glperiodst.period_name            = glperiod.period_name
         AND glperiodst.application_id         = fndappl.application_id
         AND fndappl.application_short_name    = 'SQLGL'
         AND glperiodst.adjustment_period_flag = 'N'
         ;
--
      -- ��v���ԃX�e�[�^�X�擾
      IF ( lv_closing_status NOT IN ('O','F') ) THEN
        RAISE chk_gl_period_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE chk_gl_period_expt;
    END;
  EXCEPTION
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type       -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- ���Y�䒠��
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** GL��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_gl_period_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_012  -- GL��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- XXCFF:��ЃR�[�h_�{��
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:��ЃR�[�h_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:��ЃR�[�h_�H��
    gv_comp_cd_sagara := FND_PROFILE.VALUE(cv_comp_cd_sagara);
    IF (gv_comp_cd_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:��ЃR�[�h_�H��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�d��\�[�X_���[�X
    gv_je_src_lease := FND_PROFILE.VALUE(cv_je_src_lease);
    IF (gv_je_src_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:�d��\�[�X_���[�X
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�{��
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_own_comp_itoen);
    IF (gv_own_comp_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:�{�ЍH��敪_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�H��
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_own_comp_sagara);
    IF (gv_own_comp_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:�{�ЍH��敪_�H��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�`�[�ԍ�_���[�X
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_019) -- XXCFF:�`�[�ԍ�_���[�X
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- T1_0356 2009/04/17 ADD START --
--
    -- XXCFF:�I�����C���I������
    gv_online_end_time := FND_PROFILE.VALUE(cv_prof_online_end_time);
    IF (gv_online_end_time IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_027) -- XXCFF:�I�����C���I������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- T1_0356 2009/04/17 ADD END   --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- T1_0356 2009/04/17 ADD START --
    ld_base_date  date;         --���
-- T1_0356 2009/04/17 ADD END   --
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --===========================================
    -- ���[�U���(���O�C�����[�U�A��������)�擾
    --===========================================
    BEGIN
      SELECT
              xuv.user_name   --���O�C�����[�U
             ,ppf.attribute28 --�N�[���� (��������)
      INTO    gt_login_user_name
             ,gt_login_dept_code
      FROM  xx03_users_v xuv
           ,per_people_f ppf
      WHERE xuv.user_id     = cn_created_by
      AND   xuv.employee_id = ppf.person_id
      AND   SYSDATE
            BETWEEN ppf.effective_start_date
                AND ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_login_info_expt;
    END;
--
    --===========================================
    -- ��v���떼�̎擾
    --===========================================
    BEGIN
      SELECT  sob.name   --��v���떼
      INTO    gt_sob_name
      FROM  gl_sets_of_books sob
      WHERE sob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_sob_name_expt;
    END;
--
-- T1_0356 2009/04/17 ADD START --
    --===========================================
    -- ����擾
    --===========================================
    -- ��v�N�x������𐶐�����B
    ld_base_date := TO_DATE(SUBSTR(gv_period_name,1,4) || SUBSTR(gv_period_name,6,2) || '01','YYYY/MM/DD');
--
    -- �c�Ɠ����t�擾�֐����Ăяo�������c�Ɠ����擾����B  
    ld_base_date := ADD_MONTHS(ld_base_date,1);
    -- �c�Ɠ����t�擾�֐��̌Ăяo��  
    gd_base_date := xxccp_common_pkg2.get_working_day(
                      id_date          => ld_base_date
                     ,in_working_day   => -1
                     ,iv_calendar_code => NULL
                    );
    IF (gd_base_date IS NULL) THEN
      RAISE get_working_day_expt;
    END IF;
-- T1_0356 2009/04/17 ADD END   --
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���[�U���(���O�C�����[�U�A��������)�擾�G���[�n���h�� ***
    WHEN get_login_info_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_020  -- �擾�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                     ,cv_msg_013a20_t_018  -- ���O�C��(���[�U��,��������)���
                                                     ,cv_tkn_key_name      -- �g�[�N��'KEY_NAME'
                                                     ,cv_msg_013a20_t_023  -- ���O�C�����[�UID=
                                                     ,cv_tkn_key_val       -- �g�[�N��'KEY_VAL'
                                                     ,cn_created_by)       -- ���O�C�����[�UID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ��v���떼�擾�G���[�n���h�� ***
    WHEN get_sob_name_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_020         -- �擾�G���[
                                                     ,cv_tkn_table                -- �g�[�N��'TABLE_NAME'
                                                     ,cv_msg_013a20_t_020         -- ��v���떼
                                                     ,cv_tkn_key_name             -- �g�[�N��'KEY_NAME'
                                                     ,cv_msg_013a20_t_024         -- ��v����ID=
                                                     ,cv_tkn_key_val              -- �g�[�N��'KEY_VAL'
                                                     ,g_init_rec.set_of_books_id) -- ��v����ID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
-- T1_0356 2009/04/17 ADD START --
    -- *** �c�Ɠ����t�擾�G���[�n���h�� ***
    WHEN get_working_day_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_021         -- ���ʊ֐��G���[
                                                     ,cv_tkn_func_name            -- �g�[�N��'FUNC_NAME'
                                                     ,cv_msg_013a20_t_028)        -- �c�Ɠ����t
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- T1_0356 2009/04/17 ADD END   --
--
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_les_trn_target_cnt    := 0;
    gn_les_trn_normal_cnt    := 0;
    gn_les_trn_error_cnt     := 0;
    gn_pay_plan_target_cnt   := 0;
    gn_pay_plan_normal_cnt   := 0;
    gn_pay_plan_error_cnt    := 0;
    gn_gloif_dr_target_cnt   := 0;
    gn_gloif_cr_target_cnt   := 0;
    gn_gloif_normal_cnt      := 0;
    gn_gloif_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==========================================
    -- �O��쐬�ς݃��[�X�d�󑶍݃`�F�b�N (A-4)
    -- ==========================================
    chk_je_lease_data_exist(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �������f�[�^�X�V (A-5)
    -- ===============================
    upd_target_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�X��ʖ���AFF���擾 (A-6)
    -- ===============================
    get_lease_class_aff_info(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�X�d��p�^�[�����擾 (A-7)
    -- ===============================
    get_lease_jnl_pattern(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �d�󌳃f�[�^(���[�X���)���o (A-8)
    -- ====================================
    get_les_trn_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �d��p�^�[������(���[�X���) (A-9) ? (A-12)
    -- =============================================
    ctrl_jnl_ptn_les_trn(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- ���[�X��� �d��A�g�t���O�X�V (A-13)
    -- ====================================
    update_les_trns_gl_if_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �d�󌳃f�[�^(�x���v��)���o (A-14)
    -- ====================================
    get_pay_plan_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �d��p�^�[������(�x���v��) (A-15) ? (A-17)
    -- =============================================
    ctrl_jnl_ptn_pay_plan(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X�x���v�� �A�g�t���O�X�V (A-18)
    -- =========================================
    update_pay_plan_if_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF�o�^����(�ؕ��f�[�^) (A-19)
    -- ====================================
    ins_gl_oif_dr(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF�o�^����(�ݕ��f�[�^) (A-20)
    -- ====================================
    ins_gl_oif_cr(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       -- 1.��v���Ԗ�
  )
--
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --���펞�̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode = cv_status_normal) THEN
      -- �Ώی����𐬌������ɐݒ肷��
      gn_les_trn_normal_cnt    := gn_les_trn_target_cnt;
      gn_pay_plan_normal_cnt   := gn_pay_plan_target_cnt;
      gn_gloif_normal_cnt      := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    --===============================================================
    --�G���[���̏o�͌����ݒ�
    --===============================================================
    ELSE
      -- �����������[���ɃN���A����
      gn_les_trn_normal_cnt    := 0;
      gn_pay_plan_normal_cnt   := 0;
      gn_gloif_normal_cnt      := 0;
      -- �G���[�����ɑΏی�����ݒ肷��
      gn_les_trn_error_cnt     := gn_les_trn_target_cnt;
      gn_pay_plan_error_cnt    := gn_pay_plan_target_cnt;
      gn_gloif_error_cnt       := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    END IF;
--
    --===============================================================
    --���[�X�������̃��[�X�d��e�[�u���o�^�����ɂ����錏���o��
    --===============================================================
    --���[�X�d��e�[�u��(�d��=���[�X���)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --�x���v�悩��̃��[�X�d��e�[�u���o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X�d��e�[�u��(�d��=�x���v��)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_018
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --��ʉ�vOIF�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X���(���)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_019
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
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
END XXCFF010A16C;
/
