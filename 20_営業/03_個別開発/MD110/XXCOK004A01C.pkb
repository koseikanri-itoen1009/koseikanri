CREATE OR REPLACE PACKAGE BODY XXCOK004A01C
AS
 /*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK004A01C(body)
 * Description      : �ڋq�ڍs���Ɍڋq�}�X�^�̒ޑK���z�Ɋ�Â��d������쐬���܂��B
 * MD.050           : VD�ޑK�̐U�֎d��쐬 (MD050_COK_004_A01)
 * Version          : 1.4
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  init                    ��������                        (A-1)
 *  get_cust_shift_info     �ڋq�ڍs���擾                (A-2)
 *  lock_cust_shift_info    �ڋq�ڍs��񃍃b�N�擾          (A-3)
 *  distinct_target_cust_f  �U�֎d��쐬�Ώیڋq����        (A-4)
 *  chk_acctg_target        ��v���ԃ`�F�b�N                (A-5)
 *  get_gl_data_info        GL�A�g�f�[�^�t�����̎擾      (A-6)
 *  ins_gl_oif              ��ʉ�vOIF�o�^                 (A-7)
 *  upd_cust_shift_info     �ڋq�ڍs���X�V                (A-8)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   K.Motohashi      �V�K�쐬
 *  2009/02/02    1.1   K.Suenaga        [��QCOK_002]��o�b�`�Ή�/����擾
 *  2009/06/09    1.2   K.Yamaguchi      [��QT1_1335]�ݎ؋t�C��
 *  2009/10/06    1.3   S.Moriyama       [��QE_T3_00632]�`�[���͎ґΉ�
 *  2024/02/09    1.4   Y.Sato           [E_�{�ғ�_19496]�O���[�v��Г����Ή�
 * 
 *****************************************************************************************/
-- ====================
-- �O���[�o���萔�錾��
-- ====================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK004A01C';                      -- �p�b�P�[�W��
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warning           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- �ُ�:2
--
  --WHO�J����
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                  -- �쐬�҂̃��[�U�[ID
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                  -- �ŏI�X�V�҂̃��[�U�[ID
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                 -- �ŏI�X�V�҂̃��O�C��ID
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;          -- �v��ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;             -- �R���J�����g�A�v��ID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;          -- �R���J�����gID
--
  -- *** �萔(���b�Z�[�W) ***
  cv_msg_ccp1_90000           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';                  -- �Ώی����o��
  cv_msg_ccp1_90001           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';                  -- ���������o��
  cv_msg_ccp1_90002           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';                  -- �G���[�����o��
  cv_msg_ccp1_90004           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_ccp1_90005           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';                  -- �x���I�����b�Z�[�W
  cv_msg_ccp1_90006           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';                  -- �G���[�I�����b�Z�[�W
  cv_msg_cok1_00003           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';                  -- �v���t�@�C���l�擾�s��
  cv_msg_cok1_00008           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00008';                  -- ��v������擾�s�G���[
  cv_msg_cok1_00011           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';                  -- ��v�J�����_�擾�s��
  cv_msg_cok1_00024           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';                  -- �O���[�vID�擾�G���[
  cv_msg_cok1_00025           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';                  -- �`�[�ԍ��擾�G���[
  cv_msg_cok1_00028           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';                  -- �Ɩ��������t�擾�G���[
  cv_msg_cok1_00049           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00049';                  -- ���b�N�擾�G���[
  cv_msg_cok1_10208           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10208';                  -- ��v���ԃN���[�Y�G���[
  cv_msg_cok1_10386           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10386';                  -- �ޑK�d��쐬�ΏۊO�����o��
  cv_msg_cok1_00078           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00078';                  -- �V�X�e���ғ����擾�G���[
  cv_msg_cok1_00076           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00076';                  -- �N���敪�o�͗p���b�Z�[�W
--
  -- *** �萔(�v���t�@�C��) ***
  cv_prof_company_code        CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';          -- ��ЃR�[�h
  cv_prof_aff3_change         CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_CHANGE';                -- ����Ȗ�_�������i�ޑK)
  cv_prof_subacct_dummy       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- �⏕�Ȗ�_�_�~�[�l
  cv_prof_company_dummy       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- ��ƃR�[�h_�_�~�[�l
  cv_prof_preliminary1_dummy  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- �\���R�[�h�P_�_�~�[�l
  cv_prof_preliminary2_dummy  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- �\���R�[�h2_�_�~�[�l
  cv_prof_gl_category_change  CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_CHANGE';         -- �d��J�e�S��_�ޑK�U��
  cv_prof_gl_source_cok       CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_SOURCE_COK';              -- �d��\�[�X_�ʊJ��
  cv_prof_aff2_dept_fin       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_FIN';              -- ����R�[�h_�����o����
--
  -- *** �萔(�A�v���P�[�V�����Z�k��) ***
  cv_appl_name_sqlgl          CONSTANT VARCHAR2(5)   := 'SQLGL';                             -- SQLGL
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                             -- XXCCP
  cv_appl_name_xxcok          CONSTANT VARCHAR2(10)  := 'XXCOK';                             -- XXCOK
--
  -- *** �萔(�g�[�N��) ***
  cv_tkn_output               CONSTANT VARCHAR2(10)  := 'OUTPUT';                            -- OUTPUT
  cv_tkn_cust_code            CONSTANT VARCHAR2(10)  := 'CUST_CODE';                         -- CUST_CODE
  cv_tkn_period               CONSTANT VARCHAR2(10)  := 'PERIOD';                            -- PERIOD
  cv_tkn_profile              CONSTANT VARCHAR2(10)  := 'PROFILE';                           -- PROFILE
  cv_tkn_errmsg               CONSTANT VARCHAR2(10)  := 'ERRMSG';                            -- ERRMSG
  cv_tkn_count                CONSTANT VARCHAR2(10)  := 'COUNT';                             -- COUNT
  cv_tkn_proc_date            CONSTANT VARCHAR2(10)  := 'PROC_DATE';                         -- PROC_DATE
  cv_tkn_process_flag         CONSTANT VARCHAR2(12)  := 'PROCESS_FLAG';                      -- PROCESS_FLAG
--
  -- *** �萔(�Z�p���[�^) ***
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                               -- �R����
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                 -- �h�b�g
--
  -- *** �萔(���l) ***
  cn_number_0                 CONSTANT NUMBER        := 0;                                   -- 0
  cn_number_1                 CONSTANT NUMBER        := 1;                                   -- 1
--
  -- *** �萔(�擾���R�[�h��) ***
  cn_rownum_0                 CONSTANT NUMBER        := 0;                                   -- 0
  cn_rownum_1                 CONSTANT NUMBER        := 1;                                   -- 1
--
  -- *** �萔(�������ԃt���O) ***
  cv_adjust_flag_n            CONSTANT VARCHAR2(1)   := 'N';                                 -- N
--
  -- *** �萔(��ʉ�vOIF�o�^�l) ***
  cv_glif_status              CONSTANT VARCHAR2(3)   := 'NEW';                               -- �X�e�[�^�X
  cv_glif_actual_flag         CONSTANT VARCHAR2(1)   := 'A';                                 -- �c���^�C�v
--
  -- *** �萔(�ޑK�d��쐬�t���O) ***
  cv_chg_je_flag_yet          CONSTANT VARCHAR2(1)   := '0';                                 -- ���쐬
  cv_chg_je_flag_finish       CONSTANT VARCHAR2(1)   := '1';                                 -- �쐬��
  cv_chg_je_flag_out          CONSTANT VARCHAR2(1)   := '2';                                 -- �ΏۊO
--
  -- *** �萔(�ڋq�ڍs���̃X�e�[�^�X) ***
  cv_xcsi_status_desist       CONSTANT VARCHAR2(1)   := 'A';                                 -- �m��
--
  -- *** �萔(��v���Ԃ̃X�e�[�^�X) ***
  cv_closing_status_o         CONSTANT VARCHAR2(1)   := 'O';                                 -- O
--
  -- *** �萔(�Q�ƃ^�C�v) ***
  cv_lt_glif_chng_vd          CONSTANT VARCHAR2(30)  := 'XXCOK1_GLIF_CHANGE_VD';             -- �ޑK�U�֎d��Ώیڋq
  cv_lt_glif_chng_status      CONSTANT VARCHAR2(30)  := 'XXCOK1_GLIF_CHANGE_STATUS';         -- �ޑK�U�֎d��ΏۃX�e�[�^�X
  cv_lt_enabled_flag_y        CONSTANT VARCHAR2(1)   := 'Y';                                 -- �L���t���O'Y'
--
  -- *** �萔(�u�[���^�̒l) ***
  cb_bool_true                CONSTANT BOOLEAN       := TRUE;                                -- TRUE
  cb_bool_false               CONSTANT BOOLEAN       := FALSE;                               -- FALSE
--
  -- *** �萔(�N���敪)  ***
  cv_normal_type              CONSTANT VARCHAR2(1)   := '1';                                 -- �N���敪(�ʏ�N��)
  --*** �ғ����擾�֐� ***
  cn_cal_type_one             CONSTANT NUMBER        := 1;   -- �J�����_�[�敪(�V�X�e���ғ����J�����_�[)
  cn_aft                      CONSTANT NUMBER        := 2;   -- �����敪(2)
  cn_plus_days                CONSTANT NUMBER        := 1;   -- ����
-- ==============
-- ���ʗ�O�錾��
-- ==============
  --*** ���������ʗ�O ***
  global_process_expt        EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt            EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
  --*** ���b�N�擾��O ***
  global_resouce_busy_expt   EXCEPTION;
--
  -- ========
  -- �v���O�}
  -- ========
  --*** ���ʊ֐���O ***
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�擾��O ***
  PRAGMA EXCEPTION_INIT( global_resouce_busy_expt, -54 );
--
  -- ==============
  -- �O���[�o���ϐ�
  -- ==============
  gn_target_cnt               NUMBER         DEFAULT NULL;  -- �Ώی���
  gn_normal_cnt               NUMBER         DEFAULT NULL;  -- ���팏��
  gn_warning_cnt              NUMBER         DEFAULT NULL;  -- �x������
  gn_error_cnt                NUMBER         DEFAULT NULL;  -- �G���[����
  gn_off_chg_je_cnt           NUMBER         DEFAULT NULL;  -- �ޑK�d��쐬�ΏۊO����
--
  gv_prof_company_code        VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F��ЃR�[�h
  gv_prof_aff3_change         VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�������i�ޑK�j����Ȗ�
  gv_prof_subacct_dummy       VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�⏕�Ȗڂ̃_�~�[�l
  gv_prof_company_dummy       VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F��ƃR�[�h�̃_�~�[�l
  gv_prof_preliminary1_dummy  VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�\���P�̃_�~�[�l
  gv_prof_preliminary2_dummy  VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�\��2�̃_�~�[�l
  gv_prof_category_change     VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�ޑK�U�ւ̎d��J�e�S��
  gv_prof_source_cok          VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�ʊJ���̎d��\�[�X
  gv_prof_aff2_dept_fin       VARCHAR2(50)   DEFAULT NULL;  -- �v���t�@�C���F�����o�����̕���R�[�h
--
  gd_process_date             DATE           DEFAULT NULL;  -- �Ɩ��������t
  gn_set_of_books_id          NUMBER         DEFAULT NULL;  -- ��v����ID
  gv_set_of_books_name        VARCHAR2(15)   DEFAULT NULL;  -- ��v���떼
  gn_chart_acct_id            NUMBER(15)     DEFAULT NULL;  -- ����̌nID
  gv_period_set_name          VARCHAR2(15)   DEFAULT NULL;  -- �J�����_��
  gn_aff_segment_cnt          NUMBER         DEFAULT NULL;  -- AFF�Z�O�����g��`��
  gv_currency_code            VARCHAR2(15)   DEFAULT NULL;  -- �@�\�ʉ݃R�[�h
  gv_batch_name               VARCHAR2(100)  DEFAULT NULL;  -- �o�b�`��
  gv_group_id                 VARCHAR2(150)  DEFAULT NULL;  -- �O���[�vID
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- �ڋq�ڍs���擾�J�[�\��(A-2)
  -- ==============================
  CURSOR get_cust_info_cur(
    id_process_date  IN DATE )
  IS
    SELECT xcsi.cust_shift_id     AS xcsi_cust_shift_id         -- �ڋq�ڍs���ID
         , xcsi.prev_base_code    AS xcsi_prev_base_code        -- ���S�����_
         , xcsi.new_base_code     AS xcsi_new_base_code         -- �V�S�����_
         , xcsi.cust_code         AS xcsi_cust_code             -- �ڋq�R�[�h
         , xcsi.cust_shift_date   AS xcsi_cust_shift_date       -- �ڋq�ڍs��
         , xca.change_amount      AS xca_change_amount          -- �ޑK
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD START
         , xcsi.emp_code          AS xcsi_emp_code              -- �ڋq�ڍs�o�^�]�ƈ�
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama ADD END
-- Ver.1.4 Add Start
         , NVL(xbdcivp.company_code_bd, gv_prof_company_code) AS xbdcivp_company_code_bd
                                                                -- ���S�����_��ЃR�[�h
         , NVL(xbdcivn.company_code_bd, gv_prof_company_code) AS xbdcivn_company_code_bd
                                                                -- �V�S�����_��ЃR�[�h
-- Ver.1.4 Add End
      FROM xxcok_cust_shift_info  xcsi                          -- �ڋq�ڍs���e�[�u��
         , hz_cust_accounts       hca                           -- �ڋq�}�X�^
         , xxcmm_cust_accounts    xca                           -- �ڋq�}�X�^�A�h�I��
-- Ver.1.4 Add Start
         , xxcfr_bd_dept_comp_info_v xbdcivp                    -- ���S�����_��Џ��r���[
         , xxcfr_bd_dept_comp_info_v xbdcivn                    -- �V�S�����_��Џ��r���[
-- Ver.1.4 Add End
     WHERE xcsi.status             =  cv_xcsi_status_desist     -- �X�e�[�^�X='A'
       AND xcsi.cust_shift_date    <= TRUNC( id_process_date )  -- �ڋq�ڍs��=�Ɩ��������t
       AND xcsi.create_chg_je_flag =  cv_chg_je_flag_yet        -- �ޑK�d��쐬�t���O=���쐬
       AND xcsi.cust_code          =  hca.account_number        -- �ڋq�R�[�h
-- Ver.1.4 Mod Start
--       AND hca.cust_account_id     =  xca.customer_id;          -- �ڋqID
       AND hca.cust_account_id     =  xca.customer_id           -- �ڋqID
       AND xbdcivp.set_of_books_id =  gn_set_of_books_id        -- ��:��v����ID
       AND xcsi.prev_base_code     =  xbdcivp.dept_code         -- ��:�S�����_
       AND xcsi.cust_shift_date    >= xbdcivp.comp_start_date   -- ��:��ЊJ�n��<=�ڋq�ڍs��
       AND xcsi.cust_shift_date    <= NVL(xbdcivp.comp_end_date, xcsi.cust_shift_date)
                                                                -- ��:�ڋq�ڍs��<=��ЏI����
       AND xbdcivn.set_of_books_id =  gn_set_of_books_id        -- �V:��v����ID
       AND xcsi.new_base_code      =  xbdcivn.dept_code         -- �V:�S�����_
       AND xcsi.cust_shift_date    >= xbdcivn.comp_start_date   -- �V:��ЊJ�n��<=�ڋq�ڍs��
       AND xcsi.cust_shift_date    <= NVL(xbdcivn.comp_end_date, xcsi.cust_shift_date);
                                                                -- �V:�ڋq�ڍs��<=��ЏI����
-- Ver.1.4 Mod End
--
  -- =============================
  -- �O���[�o���e�[�u��
  -- �ڋq�ڍs���擾�J�[�\��(A-2)
  -- =============================
  TYPE t_A2_ttype IS TABLE OF get_cust_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  g_cust_info_tab t_A2_ttype;
--
--
  /**********************************************************************************
  * Procedure Name   : upd_cust_shift_info
  * Description      : �ڋq�ڍs���X�V�iA-8�j
  ***********************************************************************************/
  PROCEDURE upd_cust_shift_info(
    ov_errbuf              OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode             OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg              OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_slip_number         IN  VARCHAR2        -- �`�[�ԍ�
  , in_idx                 IN  BINARY_INTEGER  -- �R���N�V�����̃C���f�b�N�X
  , iv_create_chg_je_flag  IN  VARCHAR2 )      -- �ޑK�U�֎d��쐬�t���O
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'upd_cust_shift_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ================
    -- �ڋq�ڍs���X�V
    -- ================
    UPDATE xxcok_cust_shift_info xcsi
       SET xcsi.create_chg_je_flag     = iv_create_chg_je_flag                 -- �ޑK�U�֎d��쐬�t���O
         , xcsi.org_slip_number        = iv_slip_number                        -- �`�[�ԍ�
         , xcsi.last_updated_by        = cn_last_updated_by                    -- ���[�UID
         , xcsi.last_update_date       = SYSDATE                               -- �V�X�e�����t
         , xcsi.last_update_login      = cn_last_update_login                  -- ���O�C��ID
         , xcsi.request_id             = cn_request_id                         -- �v��ID
         , xcsi.program_application_id = cn_program_application_id             -- �v���O�����E�A�v���P�[�V����ID
         , xcsi.program_id             = cn_program_id                         -- �v���O����ID
         , xcsi.program_update_date    = SYSDATE                               -- �v���O�����X�V��
     WHERE xcsi.cust_shift_id = g_cust_info_tab( in_idx ).xcsi_cust_shift_id;  -- �ڋq�ڍs���ID
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END upd_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : ins_gl_oif
  * Description      : ��ʉ�vOIF�o�^�iA-7�j
  ***********************************************************************************/
  PROCEDURE ins_gl_oif(
    ov_errbuf       OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode      OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_idx          IN  BINARY_INTEGER  -- �R���N�V�����̃C���f�b�N�X
  , iv_slip_number  IN  VARCHAR2        -- �`�[�ԍ�
  , iv_period_name  IN  VARCHAR2 )      -- ��v���Ԗ�
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'ins_gl_oif';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =======================
    -- ��ʉ�vOIF(�ؕ�)�̓o�^
    -- =======================
    INSERT ALL INTO gl_interface(
      status                                          -- �X�e�[�^�X
    , set_of_books_id                                 -- ��v����ID
    , accounting_date                                 -- �d��L�����t
    , currency_code                                   -- �ʉ݃R�[�h
    , date_created                                    -- �V�K�쐬���t
    , created_by                                      -- �V�K�쐬��ID
    , actual_flag                                     -- �c���^�C�v
    , user_je_category_name                           -- �d��J�e�S����
    , user_je_source_name                             -- �d��\�[�X��
    , segment1                                        -- ���
    , segment2                                        -- ����
    , segment3                                        -- ����Ȗ�
    , segment4                                        -- �⏕�Ȗ�
    , segment5                                        -- �ڋq�R�[�h
    , segment6                                        -- ��ƃR�[�h
    , segment7                                        -- �\��1
    , segment8                                        -- �\��2
    , entered_cr                                      -- �ݕ����z
    , entered_dr                                      -- �ؕ����z
    , reference1                                      -- �o�b�`��
    , reference4                                      -- �d��
    , period_name                                     -- ��v���Ԗ�
    , group_id                                        -- �O���[�vID
    , attribute1                                      -- �ŋ敪
    , attribute3                                      -- �`�[�ԍ�
    , attribute4                                      -- �N�[����
    , attribute5                                      -- �`�[���͎�
    , context )                                       -- DFF�R���e�L�X�g
    VALUES(
      cv_glif_status                                  -- NEW
    , gn_set_of_books_id                              -- ��v����ID
    , g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- �ڋq�ڍs��
    , gv_currency_code                                -- �@�\�ʉ݃R�[�h
    , SYSDATE                                         -- �V�X�e�����t
    , cn_created_by                                   -- ���O�C�����̃��[�UID
    , cv_glif_actual_flag                             -- 'A'
    , gv_prof_category_change                         -- �ޑK�U�ւ̎d��J�e�S��
    , gv_prof_source_cok                              -- �ʊJ���̎d��\�[�X
-- Ver.1.4 Mod Start
--    , gv_prof_company_code                            -- ��ЃR�[�h
    , g_cust_info_tab( in_idx ).xbdcivn_company_code_bd -- �V�S�����_��ЃR�[�h
-- Ver.1.4 Mod End
-- 2009/06/09 Ver.1.2 [��QT1_1335] SCS K.Yamaguchi REPAIR START
--    , g_cust_info_tab( in_idx ).xcsi_prev_base_code   -- ���S�����_
    , g_cust_info_tab( in_idx ).xcsi_new_base_code    -- �V�S�����_
-- 2009/06/09 Ver.1.2 [��QT1_1335] SCS K.Yamaguchi REPAIR END
    , gv_prof_aff3_change                             -- �������i�ޑK�j����Ȗ�
    , gv_prof_subacct_dummy                           -- �⏕�Ȗڂ̃_�~�[�l
    , g_cust_info_tab( in_idx ).xcsi_cust_code        -- �ڋq�R�[�h
    , gv_prof_company_dummy                           -- ��ƃR�[�h�̃_�~�[�l
    , gv_prof_preliminary1_dummy                      -- �\���P�̃_�~�[�l
    , gv_prof_preliminary2_dummy                      -- �\���Q�̃_�~�[�l
    , NULL                                            -- NULL
    , g_cust_info_tab( in_idx ).xca_change_amount     -- �ޑK
    , gv_batch_name                                   -- �o�b�`��
    , iv_slip_number                                  -- �`�[�ԍ�
    , iv_period_name                                  -- ��v���Ԗ�
    , TO_NUMBER( gv_group_id )                        -- �O���[�vID
    , NULL                                            -- �ŋ敪
    , iv_slip_number                                  -- �`�[�ԍ�
    , gv_prof_aff2_dept_fin                           -- �����o�����̕���R�[�h
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD START
--    , TO_CHAR( cn_last_updated_by )                   -- ���O�C�����̃��[�UID
    , g_cust_info_tab( in_idx ).xcsi_emp_code         -- �ڋq�ڍs�o�^�]�ƈ�
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD START
    , gv_set_of_books_name )                          -- ��v���떼
    -- =======================
    -- ��ʉ�vOIF(�ݕ�)�̓o�^
    -- =======================
    INTO gl_interface(
      status                                          -- �X�e�[�^�X
    , set_of_books_id                                 -- ��v����ID
    , accounting_date                                 -- �d��L�����t
    , currency_code                                   -- �ʉ݃R�[�h
    , date_created                                    -- �V�K�쐬���t
    , created_by                                      -- �V�K�쐬��ID
    , actual_flag                                     -- �c���^�C�v
    , user_je_category_name                           -- �d��J�e�S����
    , user_je_source_name                             -- �d��\�[�X��
    , segment1                                        -- ���
    , segment2                                        -- ����
    , segment3                                        -- ����Ȗ�
    , segment4                                        -- �⏕�Ȗ�
    , segment5                                        -- �ڋq�R�[�h
    , segment6                                        -- ��ƃR�[�h
    , segment7                                        -- �\��1
    , segment8                                        -- �\��2
    , entered_cr                                      -- �ݕ����z
    , entered_dr                                      -- �ؕ����z
    , reference1                                      -- �o�b�`��
    , reference4                                      -- �d��
    , period_name                                     -- ��v���Ԗ�
    , group_id                                        -- �O���[�vID
    , attribute1                                      -- �ŋ敪
    , attribute3                                      -- �`�[�ԍ�
    , attribute4                                      -- �N�[����
    , attribute5                                      -- �`�[���͎�
    , context )                                       -- DFF�R���e�L�X�g
    VALUES(
      cv_glif_status                                  -- NEW
    , gn_set_of_books_id                              -- ��v����ID
    , g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- �ڋq�ڍs��
    , gv_currency_code                                -- �@�\�ʉ݃R�[�h
    , SYSDATE                                         -- �V�X�e�����t
    , cn_created_by                                   -- ���O�C�����̃��[�UID
    , cv_glif_actual_flag                             -- 'A'
    , gv_prof_category_change                         -- �ޑK�U�ւ̎d��J�e�S��
    , gv_prof_source_cok                              -- �ʊJ���̎d��\�[�X
-- Ver.1.4 Mod Start
--    , gv_prof_company_code                            -- ��ЃR�[�h
    , g_cust_info_tab( in_idx ).xbdcivp_company_code_bd -- ���S�����_��ЃR�[�h
-- Ver.1.4 Mod End
-- 2009/06/09 Ver.1.2 [��QT1_1335] SCS K.Yamaguchi REPAIR START
--    , g_cust_info_tab( in_idx ).xcsi_new_base_code    -- �V�S�����_
    , g_cust_info_tab( in_idx ).xcsi_prev_base_code   -- ���S�����_
-- 2009/06/09 Ver.1.2 [��QT1_1335] SCS K.Yamaguchi REPAIR START
    , gv_prof_aff3_change                             -- �������i�ޑK�j����Ȗ�
    , gv_prof_subacct_dummy                           -- �⏕�Ȗڂ̃_�~�[�l
    , g_cust_info_tab( in_idx ).xcsi_cust_code        -- �ڋq�R�[�h
    , gv_prof_company_dummy                           -- ��ƃR�[�h�̃_�~�[�l
    , gv_prof_preliminary1_dummy                      -- �\���P�̃_�~�[�l
    , gv_prof_preliminary2_dummy                      -- �\���Q�̃_�~�[�l
    , g_cust_info_tab( in_idx ).xca_change_amount     -- �ޑK
    , NULL                                            -- NULL
    , gv_batch_name                                   -- �o�b�`��
    , iv_slip_number                                  -- �`�[�ԍ�
    , iv_period_name                                  -- ��v���Ԗ�
    , TO_NUMBER( gv_group_id )                        -- �O���[�vID
    , NULL                                            -- �ŋ敪
    , iv_slip_number                                  -- �`�[�ԍ�
    , gv_prof_aff2_dept_fin                           -- �����o�����̕���R�[�h
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD START
--    , TO_CHAR( cn_last_updated_by )                   -- ���O�C�����̃��[�UID
    , g_cust_info_tab( in_idx ).xcsi_emp_code         -- �ڋq�ڍs�o�^�]�ƈ�
-- 2009/10/06 Ver.1.3 [��QE_T3_00632] SCS S.Moriyama UPD START
    , gv_set_of_books_name )                          -- ��v���떼
    SELECT 'X' FROM DUAL;
--
      -- ====================
      -- �o�̓p�����[�^�̐ݒ�
      -- ====================
      ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END ins_gl_oif;
--
--
  /**********************************************************************************
  * Procedure Name   : get_gl_data_info
  * Description      : GL�A�g�f�[�^�t�����̎擾�iA-6�j
  ***********************************************************************************/
  PROCEDURE get_gl_data_info(
    ov_errbuf       OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode      OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_idx          IN  BINARY_INTEGER  -- �R���N�V�����̃C���f�b�N�X
  , ov_slip_number  OUT VARCHAR2 )      -- �`�[�ԍ�
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_gl_data_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
    -- ============
    -- ���[�J����O
    -- ============
    get_gl_data_expt            EXCEPTION;     -- �t�����擾��O
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =================================
    -- �`�[�ԍ��擾API���`�[�ԍ����擾
    -- =================================
    ov_slip_number := xxcok_common_pkg.get_slip_number_f(
                        iv_package_name  =>  cv_pkg_name
                      );
--
    IF( ov_slip_number IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00025
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE get_gl_data_expt;
    END IF;
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** �t�����擾��O�n���h�� ***
    WHEN get_gl_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_gl_data_info;
--
--
  /**********************************************************************************
  * Procedure Name   : chk_acctg_target
  * Description      : ��v���ԃ`�F�b�N�iA-5�j
  ***********************************************************************************/
  PROCEDURE chk_acctg_target(
    ov_errbuf       OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode      OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg       OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_idx          IN  BINARY_INTEGER  -- �R���N�V�����̃C���f�b�N�X
  , ov_period_name  OUT VARCHAR2 )      -- ��v���Ԗ�
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'chk_acctg_target';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode         BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    ln_period_year     NUMBER(15)      DEFAULT NULL;  -- ��v�N�x
    lv_closing_status  VARCHAR2(1)     DEFAULT NULL;  -- �X�e�[�^�X
--
    -- ============
    -- ���[�J����O
    -- ============
    closing_status_expt EXCEPTION;  -- ��v���ԃN���[�Y
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ====================
    -- ��v�J�����_���擾
    -- ====================
    xxcok_common_pkg.get_acctg_calendar_p(
      ov_errbuf                  =>  lv_errbuf                                       -- �G���[�o�b�t�@
    , ov_retcode                 =>  lv_retcode                                      -- ���^�[���R�[�h
    , ov_errmsg                  =>  lv_errmsg                                       -- �G���[���b�Z�[�W
    , in_set_of_books_id         =>  gn_set_of_books_id                              -- ��v����ID
    , iv_application_short_name  =>  cv_appl_name_sqlgl                              -- �A�v���Z�k��:SQLGL
    , id_object_date             =>  g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- �Ώۓ�(�ڋq�ڍs��)
    , iv_adjustment_period_flag  =>  cv_adjust_flag_n                                -- �����t���O(DEFAULT'N')
    , on_period_year             =>  ln_period_year                                  -- ��v�N�x
    , ov_period_name             =>  ov_period_name                                  -- ��v���Ԗ�
    , ov_closing_status          =>  lv_closing_status                               -- �X�e�[�^�X
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00011
                    , iv_token_name1   =>  cv_tkn_proc_date
                    , iv_token_value1  =>  g_cust_info_tab( in_idx ).xcsi_cust_shift_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- �擾�����X�e�[�^�X��'O'�i����j�ȊO�̏ꍇ�A
    -- ��v���ԃN���[�Y�G���[(�x���I��)
    -- ===========================================
    IF( lv_closing_status <> cv_closing_status_o ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_10208
                    , iv_token_name1   =>  cv_tkn_period
                    , iv_token_value1  =>  ov_period_name
                    , iv_token_name2   =>  cv_tkn_cust_code
                    , iv_token_value2  =>  g_cust_info_tab( in_idx ).xcsi_cust_code  -- �ڋq�R�[�h
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE closing_status_expt;
    END IF;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ��v���ԃN���[�Y��O�n���h�� ***
    WHEN closing_status_expt THEN
      ov_retcode := cv_status_warning;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END chk_acctg_target;
--
--
  /**********************************************************************************
  * Function Name   : distinct_target_cust_f
  * Description     : �U�֎d��쐬�Ώیڋq���ʁiA-4�j
  ***********************************************************************************/
  FUNCTION distinct_target_cust_f(
    in_idx  BINARY_INTEGER )  -- �R���N�V�����̃C���f�b�N�X
  RETURN BOOLEAN              -- �߂�l(TRUE=�U�֎d��쐬�Ώ�/FALSE=�쐬�ΏۊO)
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'distinct_target_cust_f';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf           VARCHAR2(5000)                              DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1)                                 DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000)                              DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg          VARCHAR2(2000)                              DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode          BOOLEAN                                     DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lb_A4_flag          BOOLEAN                                     DEFAULT TRUE;  -- �U�֎d��쐬�Ώ۔��ʃt���O
    ln_target_cust_cnt  NUMBER                                      DEFAULT NULL;  -- �`�F�b�N����
    lt_cust_shift_date  xxcok_cust_shift_info.cust_shift_date%TYPE  DEFAULT NULL;  -- �ڋq�ڍs��
    lt_cust_code        xxcok_cust_shift_info.cust_code%TYPE        DEFAULT NULL;  -- �ڋq�R�[�h
--
  BEGIN
    lt_cust_shift_date := g_cust_info_tab( in_idx ).xcsi_cust_shift_date;  -- �ڋq�ڍs��
    lt_cust_code       := g_cust_info_tab( in_idx ).xcsi_cust_code;        -- �ڋq�R�[�h
--
    -- ============
    -- ���݃`�F�b�N
    -- ============
    SELECT COUNT( 'X' )         AS dummy
      INTO ln_target_cust_cnt
      FROM hz_cust_accounts     hca                                         -- �ڋq�}�X�^
         , xxcmm_cust_accounts  xca                                         -- �ڋq�}�X�^�A�h�I��
         , hz_parties           hp
     WHERE hca.account_number  = lt_cust_code                               -- �ڋq�R�[�h
       AND hca.cust_account_id = xca.customer_id                            -- �ڋqID
       AND hca.party_id        = hp.party_id                                -- �p�[�e�BID
       AND EXISTS ( SELECT 'X'                AS dummy
                      FROM fnd_lookup_values  flv                           -- �N�B�b�N�R�[�h
                     WHERE flv.lookup_type       =  cv_lt_glif_chng_vd      -- �Q�ƃ^�C�v
                       AND flv.lookup_code       =  xca.business_low_type   -- �Q�ƃR�[�h=�Ƒԁi�����ށj
                       AND flv.start_date_active <= lt_cust_shift_date      -- �L����(��)=�ڋq�ڍs��
                       AND ( flv.end_date_active >= lt_cust_shift_date      -- �L����(��)=�ڋq�ڍs��
                             OR
                             flv.end_date_active IS NULL )                  -- �L����(��)=NULL
                       AND flv.enabled_flag = cv_lt_enabled_flag_y )        -- �L���t���O='Y'
       AND EXISTS ( SELECT 'X'                AS dummy
                      FROM fnd_lookup_values  flv                           -- �N�B�b�N�R�[�h
                     WHERE flv.lookup_type       =  cv_lt_glif_chng_status  -- �Q�ƃ^�C�v
                       AND flv.lookup_code       =  hp.duns_number_c        -- �Q�ƃR�[�h=�ڋq�X�e�[�^�X
                       AND flv.start_date_active <= lt_cust_shift_date      -- �L����(��)<=�ڋq�ڍs��
                       AND ( flv.end_date_active >= lt_cust_shift_date      -- �L����(��)>=�ڋq�ڍs��
                             OR
                             flv.end_date_active IS NULL )                  -- �L����(��)=NULL
                       AND flv.enabled_flag = cv_lt_enabled_flag_y )        -- �L���t���O='Y'
       AND ROWNUM = cn_rownum_1;                                            -- �擾���R�[�h��=1���R�[�h
--
    -- ==========================
    -- �U�֎d��쐬�Ώیڋq�̔���
    -- ==========================
    IF( ln_target_cust_cnt = cn_rownum_0 ) THEN
      lb_A4_flag := cb_bool_false;
    ELSIF( ln_target_cust_cnt = cn_rownum_1 ) THEN
      lb_A4_flag := cb_bool_true;
    END IF;
--
    RETURN( lb_A4_flag );
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      RAISE_APPLICATION_ERROR (
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
--
  END distinct_target_cust_f;
--
--
  /**********************************************************************************
  * Procedure Name   : lock_cust_shift_info
  * Description      : �ڋq�ڍs��񃍃b�N�擾(A-3)
  ***********************************************************************************/
  PROCEDURE lock_cust_shift_info(
    ov_errbuf   OUT VARCHAR2          -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2          -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_idx      IN  BINARY_INTEGER )  -- �R���N�V�����̃C���f�b�N�X
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'lock_cust_shift_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    -- ====================
    -- ���b�N�擾�p�J�[�\��
    -- ====================
    CURSOR lock_cust_info_cur(
      it_cust_shift_id  IN xxcok_cust_shift_info.cust_shift_id%TYPE )
    IS
      SELECT 'X'                    AS dummy
        FROM xxcok_cust_shift_info  xcsi            -- �ڋq�ڍs���e�[�u��
       WHERE xcsi.cust_shift_id = it_cust_shift_id  -- �ڋq�ڍs���ID
         FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ========================
    -- �ڋq�ڍs��񃍃b�N�̎擾
    -- ========================
    OPEN  lock_cust_info_cur( g_cust_info_tab( in_idx ).xcsi_cust_shift_id );  -- �ڋq�ڍs���ID
    CLOSE lock_cust_info_cur;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[��O�n���h�� ***
    WHEN global_resouce_busy_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00049
                    , iv_token_name1   =>  cv_tkn_cust_code
                    , iv_token_value1  =>  TO_CHAR( g_cust_info_tab( in_idx ).xcsi_cust_code )  -- �ڋq�R�[�h
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_warning;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END lock_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : get_cust_shift_info
  * Description      : �ڋq�ڍs���擾(A-2)
  ***********************************************************************************/
  PROCEDURE get_cust_shift_info(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_cust_shift_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg              VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode              BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lb_A4_flag              BOOLEAN         DEFAULT TRUE;  -- �U�֎d��쐬�Ώ۔��ʃt���O(TRUE=�쐬�Ώ�/FALSE=�쐬�ΏۊO)
    lv_end_retcode          VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_slip_number          VARCHAR2(30)    DEFAULT NULL;  -- �`�[�ԍ�
    lv_period_name          VARCHAR2(15)    DEFAULT NULL;  -- ��v���Ԗ�
    lv_create_chg_je_flag   VARCHAR2(1)     DEFAULT NULL;  -- �ޑK�U�֎d��쐬�t���O
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    gn_target_cnt     := cn_number_0;
    gn_normal_cnt     := cn_number_0;
    gn_warning_cnt    := cn_number_0;
    gn_error_cnt      := cn_number_0;
    gn_off_chg_je_cnt := cn_number_0;
    lv_retcode        := cv_status_normal;
    lv_end_retcode    := cv_status_normal;
--
    -- ==================
    -- �ڋq�ڍs���̎擾
    -- ==================
    OPEN  get_cust_info_cur( gd_process_date );
    FETCH get_cust_info_cur BULK COLLECT INTO g_cust_info_tab;
    CLOSE get_cust_info_cur;
--
    -- ==================
    -- �Ώی����̃J�E���g
    -- ==================
    gn_target_cnt := g_cust_info_tab.COUNT;
--
    -- ======================
    -- �ڋq�ڍs���擾���[�v
    -- ======================
    <<get_cust_info_loop>>
    FOR ln_idx IN cn_rownum_1 .. g_cust_info_tab.COUNT LOOP
--
      -- ==============
      -- �l�X�g�u���b�N
      -- ==============
      DECLARE
        warning_expt  EXCEPTION;  -- �x����O
--
      BEGIN
        -- ==============
        -- �Z�[�u�|�C���g
        -- ==============
        SAVEPOINT loop_save;
--
        -- ==========================
        -- A-3:�ڋq�ڍs��񃍃b�N�擾
        -- ==========================
        lock_cust_shift_info(
          ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
        , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
        , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        , in_idx      =>  ln_idx      -- �R���N�V�����̃C���f�b�N�X
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warning ) THEN
          RAISE warning_expt;
        END IF;
--
        -- ============================
        -- A-4:�U�֎d��쐬�Ώیڋq����
        -- ============================
        lb_A4_flag := distinct_target_cust_f(
                        in_idx  =>  ln_idx  -- �R���N�V�����̃C���f�b�N�X
                      );
--
        IF( lb_A4_flag = cb_bool_true ) THEN
          -- ====================
          -- A-5:��v���ԃ`�F�b�N
          -- ====================
          chk_acctg_target(
            ov_errbuf       =>  lv_errbuf       -- �G���[�E���b�Z�[�W
          , ov_retcode      =>  lv_retcode      -- ���^�[���E�R�[�h
          , ov_errmsg       =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
          , in_idx          =>  ln_idx          -- �R���N�V�����̃C���f�b�N�X
          , ov_period_name  =>  lv_period_name  -- ��v���Ԗ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warning ) THEN
            RAISE warning_expt;
          END IF;
--
          -- ==============================
          -- A-6:GL�A�g�f�[�^�t�����̎擾
          -- ==============================
          get_gl_data_info(
            ov_errbuf       =>  lv_errbuf       -- �G���[�E���b�Z�[�W
          , ov_retcode      =>  lv_retcode      -- ���^�[���E�R�[�h
          , ov_errmsg       =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
          , in_idx          =>  ln_idx          -- �R���N�V�����̃C���f�b�N�X
          , ov_slip_number  =>  lv_slip_number  -- �`�[�ԍ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===================
          -- A-7:��ʉ�vOIF�o�^
          -- ===================
          ins_gl_oif(
            ov_errbuf       =>  lv_errbuf       -- �G���[�E���b�Z�[�W
          , ov_retcode      =>  lv_retcode      -- ���^�[���E�R�[�h
          , ov_errmsg       =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
          , in_idx          =>  ln_idx          -- �R���N�V�����̃C���f�b�N�X
          , iv_slip_number  =>  lv_slip_number  -- �`�[�ԍ�
          , iv_period_name  =>  lv_period_name  -- ��v���Ԗ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================================
          -- �U�֎d����쐬�����ꍇ�A�ޑK�U�֎d��쐬�t���O���쐬�ςɐݒ�
          -- ============================================================
          lv_create_chg_je_flag  := cv_chg_je_flag_finish;
          gn_normal_cnt          := gn_normal_cnt + cn_number_1;
--
        ELSE
          -- ==============================================================
          -- �U�֎d��쐬�ΏۊO�̏ꍇ�A�ޑK�U�֎d��쐬�t���O��ΏۊO�ɐݒ�
          -- ==============================================================
          lv_create_chg_je_flag  := cv_chg_je_flag_out;
          gn_off_chg_je_cnt      := gn_off_chg_je_cnt + 1;
          lv_slip_number         := NULL;
--
        END IF;
--
        -- ====================
        -- A-8:�ڋq�ڍs���X�V
        -- ====================
        upd_cust_shift_info(
          ov_errbuf              =>  lv_errbuf              -- �G���[�E���b�Z�[�W
        , ov_retcode             =>  lv_retcode             -- ���^�[���E�R�[�h
        , ov_errmsg              =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_slip_number         =>  lv_slip_number         -- �`�[�ԍ�
        , in_idx                 =>  ln_idx                 -- �R���N�V�����̃C���f�b�N�X
        , iv_create_chg_je_flag  =>  lv_create_chg_je_flag  -- �ޑK�U�֎d��쐬�t���O
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      EXCEPTION
      -- *** �x���I����O�n���h�� ***
        WHEN warning_expt THEN
          gn_warning_cnt := gn_warning_cnt + cn_number_1;
          lv_end_retcode := cv_status_warning;
          ROLLBACK TO SAVEPOINT loop_save;
      END;
--
    END LOOP get_cust_info_loop;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �@�\���v���V�[�W���G���[��O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : init
  * Description      : ��������(A-1)
  ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_flag IN VARCHAR2   -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
--
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'init';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf    VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg   VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode   BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lv_err_prof  VARCHAR2(50)    DEFAULT NULL;  -- �擾�ł��Ȃ������v���t�@�C���I�v�V�����l
--
    -- ============
    -- ���[�J����O
    -- ============
    get_profile_expt       EXCEPTION;  -- �v���t�@�C���l�擾�G���[
    get_process_date_expt  EXCEPTION;  -- �Ɩ��������t�擾�G���[
    get_group_id_expt      EXCEPTION;  -- �O���[�vID�擾�G���[
    get_operation_date_expt EXCEPTION; -- �V�X�e���ғ����擾�G���[
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --���̓p�����[�^�̋N���敪�̍��ڂ����b�Z�[�W�o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appl_name_xxcok
                  , cv_msg_cok1_00076
                  , cv_tkn_process_flag
                  , iv_process_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    -- ==================
    -- �Ɩ��������t���擾
    -- ==================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE get_process_date_expt;
    END IF;
    --==============================================================
    --�N���敪���ʏ�N���̏ꍇ�A�V�X�e���ғ����擾���Ɩ��������t�Ƃ���
    --==============================================================
    IF( iv_process_flag = cv_normal_type ) THEN
      gd_process_date := xxcok_common_pkg.get_operating_day_f(
                           gd_process_date  -- ��L�Ŏ擾�����Ɩ��������t
                         , cn_plus_days     -- ����
                         , cn_aft           -- �����敪(2)
                         , cn_cal_type_one  -- �J�����_�[�敪(�V�X�e���ғ����J�����_�[)
                         );
    END IF;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_operation_date_expt;
    END IF;
--
    -- ======================
    -- �P�F�v���t�@�C���̎擾
    -- ======================
    gv_prof_company_code := FND_PROFILE.VALUE( cv_prof_company_code );              -- ��ЃR�[�h
--
    IF( gv_prof_company_code IS NULL ) THEN
      lv_err_prof := cv_prof_company_code;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_aff3_change := FND_PROFILE.VALUE( cv_prof_aff3_change );                -- �������i�ޑK�j����Ȗځj
--
    IF( gv_prof_aff3_change IS NULL ) THEN
      lv_err_prof := cv_prof_aff3_change;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_subacct_dummy := FND_PROFILE.VALUE( cv_prof_subacct_dummy );            -- �⏕�Ȗڂ̃_�~�[�l
--
    IF( gv_prof_subacct_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_subacct_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_company_dummy := FND_PROFILE.VALUE( cv_prof_company_dummy );            -- ��ƃR�[�h�̃_�~�[�l
--
    IF( gv_prof_company_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_company_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_preliminary1_dummy := FND_PROFILE.VALUE( cv_prof_preliminary1_dummy );  -- �\���P�̃_�~�[�l
--
    IF( gv_prof_preliminary1_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_preliminary1_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_preliminary2_dummy := FND_PROFILE.VALUE( cv_prof_preliminary2_dummy );  -- �\��2�̃_�~�[�l
--
    IF( gv_prof_preliminary2_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_preliminary2_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_category_change := FND_PROFILE.VALUE( cv_prof_gl_category_change );     -- �ޑK�U�ւ̎d��J�e�S��
--
    IF( gv_prof_category_change IS NULL ) THEN
      lv_err_prof := cv_prof_gl_category_change;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_source_cok := FND_PROFILE.VALUE( cv_prof_gl_source_cok );               -- �ʊJ���̎d��\�[�X
--
    IF( gv_prof_source_cok IS NULL ) THEN
      lv_err_prof := cv_prof_gl_source_cok;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_aff2_dept_fin := FND_PROFILE.VALUE( cv_prof_aff2_dept_fin );            -- �����o�����̕���R�[�h
--
    IF( gv_prof_aff2_dept_fin IS NULL ) THEN
      lv_err_prof := cv_prof_aff2_dept_fin;
      RAISE get_profile_expt;
    END IF;
--
    -- ===============================================
    -- �Q�F��v������擾API���A��v��������擾
    -- ===============================================
    xxcok_common_pkg.get_set_of_books_info_p(
      ov_errbuf             =>  lv_errbuf             -- �G���[�o�b�t�@
    , ov_retcode            =>  lv_retcode            -- ���^�[���R�[�h
    , ov_errmsg             =>  lv_errmsg             -- �G���[���b�Z�[�W
    , on_set_of_books_id    =>  gn_set_of_books_id    -- ��v����ID
    , ov_set_of_books_name  =>  gv_set_of_books_name  -- ��v���떼
    , on_chart_acct_id      =>  gn_chart_acct_id      -- ����̌nID
    , ov_period_set_name    =>  gv_period_set_name    -- �J�����_��
    , on_aff_segment_cnt    =>  gn_aff_segment_cnt    -- AFF�Z�O�����g��`��
    , ov_currency_code      =>  gv_currency_code      -- �@�\�ʉ݃R�[�h
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00008
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE global_api_expt;
    END IF;
--
    -- ==================
    -- �R�F�o�b�`���̎擾
    -- ==================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f(
                       iv_category_name  =>  gv_prof_category_change
                     );
--
    -- ================
    -- �l�X�g�u���b�N
    -- �O���[�vID���擾
    -- ================
    BEGIN
      SELECT gjst.attribute1  AS gjst_group_id               -- �O���[�vID
        INTO gv_group_id
        FROM gl_je_sources_tl gjst                           -- �d��\�[�X�}�X�^
       WHERE gjst.user_je_source_name = gv_prof_source_cok   -- �d��\�[�X��=�d��\�[�X
         AND gjst.language = USERENV( 'LANG' );              -- ����
--
    EXCEPTION
      -- *** �O���[�vID�擾�G���[ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_name_xxcok
                      , iv_name         =>  cv_msg_cok1_00024
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which     =>  FND_FILE.OUTPUT
                      , iv_message   =>  lv_out_msg
                      , in_new_line  =>  cn_number_1
                      );
        RAISE get_group_id_expt;
--
    END;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** �v���t�@�C���l�擾�s�G���[ ***
    WHEN get_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00003
                    , iv_token_name1   =>  cv_tkn_profile
                    , iv_token_value1  =>  lv_err_prof
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ��������t�擾�G���[��O�n���h�� ***
    WHEN get_process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �V�X�e���ғ����擾�G���[��O�n���h�� ***
    WHEN get_operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appl_name_xxcok
                    , cv_msg_cok1_00078
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �O���[�vID�擾�G���[��O�n���h�� ***
    WHEN get_group_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
--
  /**********************************************************************************
  * Procedure Name   : submain
  * Description      : ���C�������v���V�[�W��
  **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_process_flag IN VARCHAR2 -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =============
    -- ��������(A-1)
    -- =============
    init(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_flag => iv_process_flag -- ���͍��ڂ̋N���敪�p�����[�^
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================
    -- �ڋq�ڍs���擾(A-2)
    -- =====================
    get_cust_shift_info(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
    -- *** �@�\���v���V�[�W���G���[��O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
--
   /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , iv_process_flag IN VARCHAR2 -- ���͍��ڂ̋N���敪�p�����[�^
  )
  IS
--
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'main';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf        VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode       BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lv_message_code  VARCHAR2(5000)  DEFAULT NULL;  -- �����I�����b�Z�[�W
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode  := cv_status_normal;
--
    -- ==============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ==============================================
    xxccp_common_pkg.put_log_header(
      iv_which    =>  cv_tkn_output
    , ov_retcode  =>  lv_retcode
    , ov_errbuf   =>  lv_errbuf
    , ov_errmsg   =>  lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ==============================================
    submain(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_process_flag => iv_process_flag -- ���͍��ڂ̋N���敪�p�����[�^
    );
--
    -- ==========
    -- �G���[�o��
    -- ==========
    IF (lv_retcode <> cv_status_normal) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_errmsg
                    , in_new_line  =>  cn_number_1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.LOG
                    , iv_message   =>  lv_errbuf
                    , in_new_line  =>  cn_number_1
                    );
    END IF;
--
    -- ====================================
    -- ���^�[���R�[�h����ʃG���[�����̐ݒ�
    -- ====================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_error_cnt      := cn_number_1;
      gn_target_cnt     := cn_number_0;
      gn_normal_cnt     := cn_number_0;
      gn_off_chg_je_cnt := cn_number_0;
    ELSIF( lv_retcode = cv_status_normal ) THEN
      gn_error_cnt := cn_number_0;
    ELSIF( lv_retcode = cv_status_warning ) THEN
      gn_error_cnt := gn_warning_cnt;
    END IF;
--
    -- ============
    -- �Ώی����o��
    -- ============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90000
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ============
    -- ���������o��
    -- ============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90001
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ==============
    -- �G���[�����o��
    -- ==============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90002
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ==========================
    -- �ޑK�d��쐬�ΏۊO�����o��
    -- ==========================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcok
                  , iv_name          =>  cv_msg_cok1_10386
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_off_chg_je_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ====================
    -- �I�����b�Z�[�W�̕\��
    -- ====================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp1_90004;
    ELSIF( lv_retcode = cv_status_warning ) THEN
      lv_message_code := cv_msg_ccp1_90005;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp1_90006;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appl_name_xxccp
                  , iv_name         =>  lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ======================================
    -- �X�e�[�^�X�Z�b�g
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK
    -- ======================================
    retcode := lv_retcode;
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
  END main;
--
END XXCOK004A01C;
/
