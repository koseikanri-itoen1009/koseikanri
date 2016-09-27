create or replace
PACKAGE BODY XXCFF016A36C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A36C(body)
 * Description      : ���[�X�_�񖾍׃����e�i���X
 * MD.050           : MD050_CFF_016_A36_���[�X�_�񖾍׃����e�i���X.
 * Version          : 1.4
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  out_csv_data                 �X�V��f�[�^�o�͂̎��s                    (A-9)
 *  insert_contract_histories    ���[�X�_�񖾍ׂ̗����̍쐬                (A-8)
 *  update_pay_planning          �x���v��č쐬�y�уt���O�X�V              (A-7)
 *  get_judge_lease              ���[�X���菈��                            (A-6)
 *  update_contract_lines        �f�[�^�p�b�`����                          (A-5)
 *  get_backup_data              �f�[�^�o�b�N�A�b�v�̎��s                  (A-4)
 *  out_csv_data                 �X�V�O�f�[�^�o�͂̎��s                    (A-3)
 *  chk_param                    ���̓p�����[�^�`�F�b�N����                (A-2)
 *  init                         ��������                                  (A-1)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   SCSK �ÎR         �V�K�쐬
 *  2013/07/11    1.1   SCSK ����         E_�{�ғ�_10871 ����őΉ�
 *  2014/01/31    1.2   SCSK ����         E_�{�ғ�_11242 ���[�X�_�񖾍׍X�V�̕s��Ή�
 *  2014/05/19    1.3   SCSK ����         E_�{�ғ�_11852 �T���z�X�V�s��Ή�
 *  2016/08/22    1.4   SCSK�s            E_�{�ғ�_13658 ���̋@�ϗp�N���ύX�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCFF016A36C';      -- �p�b�P�[�W��
--
  -- �o�̓^�C�v
  cv_file_type_out       CONSTANT VARCHAR2(10)  := 'OUTPUT';            -- �o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log       CONSTANT VARCHAR2(10)  := 'LOG';               -- ���O(�V�X�e���Ǘ��җp�o�͐�)
  -- �A�v���P�[�V�����Z�k��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCFF';             -- �A�h�I���F��v�E���[�X�EFA�̈�
  --
  cv_format_m            CONSTANT VARCHAR2(100) := 'MM';                -- TRUNC����
  -- ���b�Z�[�W��(�{��)
  cv_msg_xxcff00123      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- ���݃`�F�b�N�G���[
  cv_msg_xxcff00208      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00208';  -- ���݃`�F�b�N�G���[
  cv_msg_xxcff00186      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00186';  -- ��v���Ԏ擾�G���[
  cv_msg_xxcff00157      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00157';  -- �p�����[�^�K�{�G���[
  cv_msg_xxcff00195      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00195';  -- �i���j�X�V�G���[
  cv_msg_xxcff00101      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00101';  -- �擾�G���[
  cv_msg_xxcff00102      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';  -- �o�^�G���[
  cv_msg_xxcff00197      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00197';  -- �i���j�R���J�����g���s�G���[
  cv_msg_xxcff00198      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00198';  -- �i���j�R���J�����g�ҋ@�G���[
  cv_msg_xxcff00199      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00199';  -- �i���j�R���J�����g�����G���[
  cv_msg_xxcff00200      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00200';  -- �i���j�p�����[�^�^�E�����G���[
  cv_msg_xxcff00094      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_xxcff00007      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ���b�N�G���[
  cv_msg_xxcff00020      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00020';  -- �v���t�@�C���擾�G���[
  cv_msg_xxcff00207      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00207';  -- �����e�i���X���ڒl�����̓G���[
  -- �g�[�N��
  cv_tkn_func_name       CONSTANT VARCHAR2(100) := 'FUNC_NAME';         -- �֐���
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';           -- �G���[���b�Z�[�W
  cv_tkn_input           CONSTANT VARCHAR2(30)  := 'INPUT';
  cv_tkn_column          CONSTANT VARCHAR2(30)  := 'COLUMN_DATA';
  cv_tkn_get             CONSTANT VARCHAR2(30)  := 'GET_DATA';
  cv_tkn_table           CONSTANT VARCHAR2(15)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_info            CONSTANT VARCHAR2(15)  := 'INFO';
  cv_tkn_prof_name       CONSTANT VARCHAR2(100) := 'PROF_NAME';         -- �v���t�@�C����
  cv_tkn_syori           CONSTANT VARCHAR2(100) := 'SYORI';             -- ������
  cv_tkn_request_id      CONSTANT VARCHAR2(100) := 'REQUEST_ID';        -- �v��ID
  cv_tkn_prm_name        CONSTANT VARCHAR2(100) := 'PARAM_NAME';        -- �p�����[�^
  -- �g�[�N���l
  cv_msg_cff_50210       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50210';  -- �R���J�����g�p�����[�^�o�͏���
  cv_msg_cff_50010       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50010';  -- �����R�[�h
  cv_msg_cff_50028       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50028';  -- �_�񖾍ד���ID
  cv_msg_cff_50030       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030';  -- ���[�X�_�񖾍׃e�[�u��
  cv_msg_cff_50040       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50040';  -- �_��ԍ�
  cv_msg_cff_50070       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50070';  -- ���[�X�_�񖾍ח����e�[�u��
  cv_msg_cff_50088       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50088';  -- ���[�X�x���v��
  cv_msg_cff_50199       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50199';  -- (��)�X�V���R
  cv_msg_cff_50223       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50223';  -- (��)���񌎊z���[�X��
  cv_msg_cff_50224       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50224';  -- (��)�Q��ڈȍ~���z���[�X��
  cv_msg_cff_50225       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50225';  -- (��)���񌎊z����Ŋz
  cv_msg_cff_50226       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50226';  -- (��)�Q��ڈȍ~����Ŋz
  cv_msg_cff_50110       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50110';  -- ���ό����w�����z
  cv_msg_cff_50200       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50200';  -- (��)���[�X�_�񖾍�BK
  cv_msg_cff_50201       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50201';  -- (��)���[�X�x���v��BK
  cv_msg_cff_50202       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50202';  -- (��)���s�}��
  cv_msg_cff_50203       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50203';  -- (��)���[�X�_��f�[�^CSV�o��
  cv_msg_cff_50204       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50204';  -- (��)���[�X�����f�[�^CSV�o��
  cv_msg_cff_50205       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50205';  -- (��)���[�X�x���v��f�[�^CSV�o��
  cv_msg_cff_50206       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50206';  -- (��)���[�X��v����CSV�o��
  cv_msg_cff_50207       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50207';  -- (��)���[�X��ޔ���
  cv_msg_cff_50208       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50208';  -- (��)��v����
  cv_msg_cff_50209       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50209';  -- (��)�x���v��쐬
  cv_msg_cff_50222       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50222';  -- (��)�ƍ��σt���O
-- Add 2013/07/11 Ver.1.1 Start
  cv_msg_cff_50148       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50148';  -- �ŋ��R�[�h
-- Add 2013/07/11 Ver.1.1 Start
  -- �v���t�@�C��
  cv_prof_interval       CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';   -- XXCOS:�ҋ@�Ԋu
  cv_prof_max_wait       CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';   -- XXCOS:�ő�ҋ@����
  -- ���[�X���
  cv_les_kind_fin        CONSTANT VARCHAR2(1)   := '0';                 -- Fin���[�X
  -- �_��X�e�[�^�X
  cv_ctrct_st_ctrct      CONSTANT VARCHAR2(3)   := '202';               -- �_��
  cv_ctrct_st_reles      CONSTANT VARCHAR2(3)   := '203';               -- �ă��[�X
  cv_ctrct_st_mntnnc     CONSTANT VARCHAR2(3)   := '210';               -- �_��f�[�^�����e�i���X
  -- ��vIF�t���O
  cv_acct_if_flag_unsent CONSTANT VARCHAR2(1)   := '1';                 -- �����M
  cv_acct_if_flag_sent   CONSTANT VARCHAR2(1)   := '2';                 -- ���M��
  -- �ƍ��ς݃t���O
  cv_paymtch_flag_admin  CONSTANT VARCHAR2(1)   := '1';                 -- �ƍ���
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
  cv_payment_match_flag_9 CONSTANT VARCHAR2(1)  := '9';                 -- �ΏۊO
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE gr_param_rec  IS RECORD(
      object_code           xxcff_object_headers.object_code%TYPE          -- 1 : �����R�[�h          (�K�{)
     ,contract_number       xxcff_contract_headers.contract_number%TYPE    -- 2 : �_��ԍ�            (�K�{)
     ,update_reason         xxcff_contract_histories.update_reason%TYPE    -- 3 : �X�V���R            (�K�{)
     ,first_charge          xxcff_contract_lines.first_charge%TYPE         -- 4 : ���񃊁[�X��        (�C��)
     ,second_charge         xxcff_contract_lines.second_charge%TYPE        -- 5 : 2��ڈȍ~�̃��[�X�� (�C��)
     ,first_tax_charge      xxcff_contract_lines.first_tax_charge%TYPE     -- 6 : ��������          (�C��)
     ,second_tax_charge     xxcff_contract_lines.second_tax_charge%TYPE    -- 7 : 2��ڈȍ~�̏����   (�C��)
     ,estimated_cash_price  xxcff_contract_lines.estimated_cash_price%TYPE -- 8 : ���ό����w�����z    (�C��)
-- Add 2013/07/11 Ver.1.1 Start
     ,tax_code              xxcff_contract_lines.tax_code%TYPE             -- 9 : �ŋ��R�[�h          (�C��)
-- ADd 2013/07/11 Ver.1.1 End
    );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_period_name          fa_deprn_periods.period_name%TYPE;               -- ��v����(���[�X�䒠�I�[�v������)
  gd_period_close_date    fa_deprn_periods.calendar_period_close_date%TYPE;-- ���[�X�䒠�I�[�v�����Ԃ̃J�����_�I����
  gn_interval             NUMBER;                                          -- �R���J�����g�ҋ@�Ԋu
  gn_max_wait             NUMBER;                                          -- �R���J�����g�ő�ҋ@����
--
  gt_object_header_id     xxcff_object_headers.object_code%TYPE;           -- ��������ID
  gt_contract_line_id     xxcff_contract_lines.contract_line_id%TYPE;      -- �_�񖾍ד���ID
  gt_first_charge         xxcff_contract_lines.first_charge%TYPE;          -- ���񌎊z���[�X��_���[�X��
  gt_first_tax_charge     xxcff_contract_lines.first_tax_charge%TYPE;      -- �������Ŋz_���[�X��
  gt_second_charge        xxcff_contract_lines.second_charge%TYPE;         -- 2��ڈȍ~���z���[�X��_���[�X��
  gt_second_tax_charge    xxcff_contract_lines.second_tax_charge%TYPE;     -- 2��ڈȍ~����Ŋz_���[�X��
  gt_first_deduction      xxcff_contract_lines.first_deduction%TYPE;       -- ���񌎊z���[�X��_�T���z
  gt_second_deduction     xxcff_contract_lines.second_deduction%TYPE;      -- 2��ڈȍ~���z���[�X��_�T���z
-- Add 2014/05/19 Ver.1.3 Start
  gt_first_tax_deduction  xxcff_contract_lines.first_tax_deduction%TYPE;   -- ���񌎊z����Ŋz_�T���z
  gt_second_tax_deduction xxcff_contract_lines.second_tax_deduction%TYPE;  -- 2��ڈȍ~����Ŋz_�T���z
-- Add 2014/05/19 Ver.1.3 End
  gt_estimated_cash_price xxcff_contract_lines.estimated_cash_price%TYPE;  -- ���ό����w�����z
  gt_life_in_months       xxcff_contract_lines.life_in_months%TYPE;        -- �@��ϗp�N��
  gt_contract_header_id   xxcff_contract_headers.contract_header_id%TYPE;  -- �_�����ID
  gt_contract_date        xxcff_contract_headers.contract_date%TYPE;       -- TO_DATE(TO_CHAR(���[�X�_���,'YYYY/MM')||'/01','YYYY/MM/DD')
  gt_lease_type           xxcff_contract_headers.lease_type%TYPE;          -- ���[�X�敪
  gt_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;   -- �x����
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
  gt_lease_class          xxcff_contract_headers.lease_class%TYPE;         -- ���[�X���
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
--
  gr_param               gr_param_rec;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : ���[�X�_�񖾍ׂ̗����̍쐬(A-8)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_contract_histories'; -- �v���O������
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
    -- ***   ���[�X�_�񖾍ׂ̗����̍쐬    ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�_�񖾍ׂ̗����̍쐬
    -- =====================================
    BEGIN
      INSERT INTO xxcff_contract_histories(
         contract_header_id                    -- �_�����ID
        ,contract_line_id                      -- �_�񖾍ד���ID
        ,history_num                           -- �ύX����NO
        ,contract_status                       -- �_��X�e�[�^�X
        ,first_charge                          -- ���񌎊z���[�X��_���[�X��
        ,first_tax_charge                      -- �������Ŋz_���[�X��
        ,first_total_charge                    -- ����v_���[�X��
        ,second_charge                         -- 2��ڈȍ~���z���[�X��_���[�X��
        ,second_tax_charge                     -- 2��ڈȍ~����Ŋz_���[�X��
        ,second_total_charge                   -- 2��ڈȍ~�v_���[�X��
        ,first_deduction                       -- ���񌎊z���[�X��_�T���z
        ,first_tax_deduction                   -- ���񌎊z����Ŋz_�T���z
        ,first_total_deduction                 -- ����v_�T���z
        ,second_deduction                      -- 2��ڈȍ~���z���[�X��_�T���z
        ,second_tax_deduction                  -- 2��ڈȍ~����Ŋz_�T���z
        ,second_total_deduction                -- 2��ڈȍ~�v_�T���z
        ,gross_charge                          -- ���z���[�X��_���[�X��
        ,gross_tax_charge                      -- ���z�����_���[�X��
        ,gross_total_charge                    -- ���z�v_���[�X��
        ,gross_deduction                       -- ���z���[�X��_�T���z
        ,gross_tax_deduction                   -- ���z�����_�T���z
        ,gross_total_deduction                 -- ���z�v_�T���z
        ,lease_kind                            -- ���[�X���
        ,estimated_cash_price                  -- ���ό����w�����z
        ,present_value_discount_rate           -- ���݉��l������
        ,present_value                         -- ���݉��l
        ,life_in_months                        -- �@��ϗp�N��
        ,original_cost                         -- �擾���z
        ,calc_interested_rate                  -- �v�Z���q��
        ,object_header_id                      -- ��������ID
        ,asset_category                        -- ���Y���
        ,expiration_date                       -- ������
        ,cancellation_date                     -- ���r����
        ,vd_if_date                            -- ���[�X�_����A�g��
        ,info_sys_if_date                      -- ���[�X�Ǘ����A�g��
        ,first_installation_address            -- ����ݒu�ꏊ
        ,first_installation_place              -- ����ݒu��
-- Add 2013/07/11 Ver.1.1 Start
        ,tax_code                              -- �ŋ��R�[�h
-- Add 2013/07/11 Ver.1.1 End
        ,accounting_date                       -- �v���
        ,accounting_if_flag                    -- ��v�h�e�t���O
        ,description                           -- �E�v
        ,update_reason                         -- �X�V���R
        ,period_name                           -- ��v����
        ,created_by                            -- �쐬��
        ,creation_date                         -- �쐬��
        ,last_updated_by                       -- �ŏI�X�V��
        ,last_update_date                      -- �ŏI�X�V��
        ,last_update_login                     -- �ŏI�X�V���O�C��
        ,request_id                            -- �v��ID
        ,program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                            -- �R���J�����g�E�v���O����ID
        ,program_update_date                   -- �v���O�����X�V��
        )
      SELECT
         xcl.contract_header_id                -- �_�����ID
        ,xcl.contract_line_id                  -- �_�񖾍ד���ID
        ,xxcff_contract_histories_s1.NEXTVAL   -- �_�񖾍ח����V�[�P���X
        ,cv_ctrct_st_mntnnc                    -- �_��X�e�[�^�X
        ,xcl.first_charge                      -- ���񌎊z���[�X��_���[�X��
        ,xcl.first_tax_charge                  -- �������Ŋz_���[�X��
        ,xcl.first_total_charge                -- ����v_���[�X��
        ,xcl.second_charge                     -- 2��ڈȍ~���z���[�X��_���[�X��
        ,xcl.second_tax_charge                 -- 2��ڈȍ~����Ŋz_���[�X��
        ,xcl.second_total_charge               -- 2��ڈȍ~�v_���[�X��
        ,xcl.first_deduction                   -- ���񌎊z���[�X��_�T���z
        ,xcl.first_tax_deduction               -- ���񌎊z����Ŋz_�T���z
        ,xcl.first_total_deduction             -- ����v_�T���z
        ,xcl.second_deduction                  -- 2��ڈȍ~���z���[�X��_�T���z
        ,xcl.second_tax_deduction              -- 2��ڈȍ~����Ŋz_�T���z
        ,xcl.second_total_deduction            -- 2��ڈȍ~�v_�T���z
        ,xcl.gross_charge                      -- ���z���[�X��_���[�X��
        ,xcl.gross_tax_charge                  -- ���z�����_���[�X��
        ,xcl.gross_total_charge                -- ���z�v_���[�X��
        ,xcl.gross_deduction                   -- ���z���[�X��_�T���z
        ,xcl.gross_tax_deduction               -- ���z�����_�T���z
        ,xcl.gross_total_deduction             -- ���z�v_�T���z
        ,xcl.lease_kind                        -- ���[�X���
        ,xcl.estimated_cash_price              -- ���ό����w�����z
        ,xcl.present_value_discount_rate       -- ���݉��l������
        ,xcl.present_value                     -- ���݉��l
        ,xcl.life_in_months                    -- �@��ϗp�N��
        ,xcl.original_cost                     -- �擾���z
        ,xcl.calc_interested_rate              -- �v�Z���q��
        ,xcl.object_header_id                  -- ��������ID
        ,xcl.asset_category                    -- ���Y���
        ,xcl.expiration_date                   -- ������
        ,xcl.cancellation_date                 -- ���r����
        ,xcl.vd_if_date                        -- ���[�X�_����A�g��
        ,xcl.info_sys_if_date                  -- ���[�X�Ǘ����A�g��
        ,xcl.first_installation_address        -- ����ݒu�ꏊ
        ,xcl.first_installation_place          -- ����ݒu��
-- Add 2013/07/11 Ver.1.1 Start
        ,xcl.tax_code                          -- �ŋ��R�[�h
-- Add 2013/07/11 Ver.1.1 End
        ,gd_period_close_date                  -- �v���
        ,cv_acct_if_flag_sent                  -- ��v�h�e�t���O('2':���M��)
        ,NULL                                  -- �E�v
        ,gr_param.update_reason                -- �X�V���R
        ,gt_period_name                        -- ��v����
        ,xcl.created_by                        -- �쐬��
        ,xcl.creation_date                     -- �쐬��
        ,xcl.last_updated_by                   -- �ŏI�X�V��
        ,xcl.last_update_date                  -- �ŏI�X�V��
        ,xcl.last_update_login                 -- �ŏI�X�V���O�C��
        ,xcl.request_id                        -- �v��ID
        ,xcl.program_application_id            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xcl.program_id                        -- �R���J�����g�E�v���O����ID
        ,xcl.program_update_date               -- �v���O�����X�V��
      FROM   xxcff_contract_lines xcl          -- ���[�X�_�񖾍�
      WHERE  xcl.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00102
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50070
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => SQLERRM
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END insert_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_pay_planning
   * Description      : �x���v��č쐬�y�уt���O�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE update_pay_planning(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_pay_planning'; -- �v���O������
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
    cv_shori_type_1      CONSTANT VARCHAR2(1) := '1'; -- ��o�^�
--
    -- *** ���[�J���ϐ� ***
    lt_payment_match_flag  xxcff_pay_planning.payment_match_flag%TYPE;  -- �ƍ��σt���O
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
    -- ***   �x���v��č쐬�y�уt���O�X�V  ***
    -- ***************************************
--
    -- =====================================
    -- �ƍ��σt���O�̑ޔ�
    -- =====================================
    BEGIN
      SELECT
        xpp.payment_match_flag AS payment_match_flag   -- �ƍ��σt���O
      INTO
        lt_payment_match_flag
      FROM
        xxcff_pay_planning xpp
      WHERE  xpp.CONTRACT_LINE_ID = gt_contract_line_id
      AND    xpp.PERIOD_NAME      = gt_period_name
      AND    rownum               = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50222
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- �x���v��č쐬�y�уt���O�X�V
    -- =====================================
    -- �֐��̌Ăяo��(�x���v��쐬)
    xxcff003a05c.main(
      iv_shori_type         => cv_shori_type_1                      -- 1.�����敪
     ,in_contract_line_id   => gt_contract_line_id                  -- 2.�_�񖾍ד���ID
     ,ov_retcode            => lv_retcode
     ,ov_errbuf             => lv_errbuf
     ,ov_errmsg             => lv_errmsg
    );
    -- �G���[����
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_xxcff00094          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_func_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_msg_cff_50209           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �x���v��t���O�X�V(��v����=�I�[�v������)
    BEGIN
      UPDATE xxcff_pay_planning xpp
      SET  xpp.accounting_if_flag     = cv_acct_if_flag_unsent          -- ��vIF�t���O('1':�����M)
          ,xpp.payment_match_flag     = lt_payment_match_flag           -- �ƍ��t���O
          ,xpp.last_updated_by        = cn_last_updated_by              -- �ŏI�X�V��
          ,xpp.last_update_date       = cd_last_update_date             -- �ŏI�X�V��
          ,xpp.last_update_login      = cn_last_update_login            -- �ŏI�X�V���O�C��
          ,xpp.request_id             = cn_request_id                   -- �v��ID
          ,xpp.program_application_id = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xpp.program_id             = cn_program_id                   -- �R���J�����g�E�v���O����ID
          ,xpp.program_update_date    = cd_program_update_date          -- �v���O�����X�V��
      WHERE xpp.contract_line_id      = gt_contract_line_id
      AND   xpp.period_name           = gt_period_name
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
      AND   xpp.payment_match_flag    != cv_payment_match_flag_9        -- �ƍ��σt���O�i�ΏۊO�j
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50088
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �x���v��t���O�X�V(��v����<�I�[�v������)
    BEGIN
      UPDATE xxcff_pay_planning xpp
      SET  xpp.accounting_if_flag     = cv_acct_if_flag_sent            -- ��vIF�t���O('2':���M��)
          ,xpp.payment_match_flag     = cv_paymtch_flag_admin           -- �ƍ��t���O('1':�ƍ���)
          ,xpp.last_updated_by        = cn_last_updated_by              -- �ŏI�X�V��
          ,xpp.last_update_date       = cd_last_update_date             -- �ŏI�X�V��
          ,xpp.last_update_login      = cn_last_update_login            -- �ŏI�X�V���O�C��
          ,xpp.request_id             = cn_request_id                   -- �v��ID
          ,xpp.program_application_id = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xpp.program_id             = cn_program_id                   -- �R���J�����g�E�v���O����ID
          ,xpp.program_update_date    = cd_program_update_date          -- �v���O�����X�V��
      WHERE xpp.contract_line_id      = gt_contract_line_id
      AND   xpp.period_name           < gt_period_name
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
      AND   xpp.payment_match_flag    != cv_payment_match_flag_9        -- �ƍ��σt���O�i�ΏۊO�j
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50088
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END update_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : get_judge_lease
   * Description      : ���[�X���菈��(A-6)
   ***********************************************************************************/
  PROCEDURE get_judge_lease(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_judge_lease'; -- �v���O������
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
    lt_first_after_charge           xxcff_contract_lines.first_charge%TYPE;                  -- ���񌎊z���[�X��(�T����)
    lt_second_after_charge          xxcff_contract_lines.second_charge%TYPE;                 -- 2��ڈȍ~���z���[�X��(�T����)
    lt_estimated_cash_price         xxcff_contract_lines.estimated_cash_price%TYPE;          -- ���ό����w�����z
    lt_lease_kind                   xxcff_contract_lines.lease_kind%TYPE;                    -- ���[�X���
    lt_present_value_discount_rate  xxcff_contract_lines.present_value_discount_rate %TYPE;  -- ���݉��l������
    lt_present_value                xxcff_contract_lines.present_value%TYPE;                 -- ���݉��l
    lt_original_cost                xxcff_contract_lines.original_cost%TYPE;                 -- �擾���z
    lt_calc_interested_rate         xxcff_contract_lines.calc_interested_rate%TYPE;          -- �v�Z���q��
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
    lt_original_cost_type1          xxcff_contract_lines.original_cost_type1%TYPE;           -- ���[�X���z_���_��
    lt_original_cost_type2          xxcff_contract_lines.original_cost_type2%TYPE;           -- ���[�X���z_�ă��[�X
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
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
    -- ***       ���[�X���菈��            ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X��ʔ���
    -- =====================================
    --�T���ナ�[�X���Z�o
    lt_first_after_charge   := NVL(gr_param.first_charge,gt_first_charge) - NVL(gt_first_deduction,0);
    lt_second_after_charge  := NVL(gr_param.second_charge,gt_second_charge) - NVL(gt_second_deduction,0);
    lt_estimated_cash_price := NVL(gr_param.estimated_cash_price,gt_estimated_cash_price);
--
    -- �֐��̌Ăяo��(���[�X��ʔ���)
    XXCFF003A03C.main(
      iv_lease_type                  => gt_lease_type                    -- 1.���[�X�敪
     ,in_payment_frequency           => gt_payment_frequency             -- 2.�x����
     ,in_first_charge                => lt_first_after_charge            -- 3.���񌎊z���[�X��(�T����)
     ,in_second_charge               => lt_second_after_charge           -- 4.�Q��ڈȍ~���z���[�X���i�T����j
     ,in_estimated_cash_price        => lt_estimated_cash_price          -- 5.���ό����w�����z
     ,in_life_in_months              => gt_life_in_months                -- 6.�@��ϗp�N��
     ,id_contract_ym                 => gt_contract_date                 -- 7.�_��N��
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
     ,iv_lease_class                 => gt_lease_class                   -- 8.���[�X���
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
     ,ov_lease_kind                  => lt_lease_kind                    -- 9.���[�X���
     ,on_present_value_discount_rate => lt_present_value_discount_rate   -- 10.���݉��l������
     ,on_present_value               => lt_present_value                 -- 11.���݉��l
     ,on_original_cost               => lt_original_cost                 -- 12.�擾���z
     ,on_calc_interested_rate        => lt_calc_interested_rate          -- 13.�v�Z���q��
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
     ,on_original_cost_type1         => lt_original_cost_type1           -- 14.���[�X���z_���_��
     ,on_original_cost_type2         => lt_original_cost_type2           -- 15.���[�X���z_�ă��[�X
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
     ,ov_errbuf                      => lv_errbuf
     ,ov_retcode                     => lv_retcode
     ,ov_errmsg                      => lv_errmsg
    );
    -- �G���[����
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_xxcff00094          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_func_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_msg_cff_50207           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- ���[�X�_�񖾍ׂɌ��ʔ��f
    -- =====================================
    BEGIN
      UPDATE xxcff_contract_lines xcl
      SET  xcl.present_value               = lt_present_value                -- ���݉��l
          ,xcl.original_cost               = lt_original_cost                -- �擾���z
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
          ,xcl.original_cost_type1         = lt_original_cost_type1          -- ���[�X���z_���_��
          ,xcl.original_cost_type2         = lt_original_cost_type2          -- ���[�X���z_�ă��[�X
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
          ,xcl.calc_interested_rate        = lt_calc_interested_rate         -- �v�Z���q��
          ,xcl.present_value_discount_rate = lt_present_value_discount_rate  -- ���݉��l������
-- Del 2014/01/31 Ver.1.2 Start
--          ,xcl.lease_kind                  = lt_lease_kind                   -- ���[�X���
-- Del 2014/01/31 Ver.1.2 End
          ,xcl.last_updated_by             = cn_last_updated_by              -- �ŏI�X�V��
          ,xcl.last_update_date            = cd_last_update_date             -- �ŏI�X�V��
          ,xcl.last_update_login           = cn_last_update_login            -- �ŏI�X�V���O�C��
          ,xcl.request_id                  = cn_request_id                   -- �v��ID
          ,xcl.program_application_id      = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,xcl.program_id                  = cn_program_id                   -- �R���J�����g�E�v���O����ID
          ,xcl.program_update_date         = cd_program_update_date          -- �v���O�����X�V��
      WHERE xcl.contract_line_id           = gt_contract_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END get_judge_lease;
--
  /**********************************************************************************
   * Procedure Name   : update_contract_lines
   * Description      : �f�[�^�p�b�`����(A-5)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_contract_lines'; -- �v���O������
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
    lv_contract_line_id     xxcff_contract_lines.contract_line_id%TYPE;     -- �_�񖾍ד���ID
    ln_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;  -- �x����
    ln_first_charge         xxcff_contract_lines.first_charge%TYPE;         -- ���񌎊z���[�X��_���[�X��
    ln_first_tax_charge     xxcff_contract_lines.first_tax_charge%TYPE;     -- �������Ŋz_���[�X��
    ln_first_total_charge   xxcff_contract_lines.first_total_charge%TYPE;   -- ����v_���[�X��
    ln_second_charge        xxcff_contract_lines.second_charge%TYPE;        -- 2��ڈȍ~���z���[�X��_���[�X��
    ln_second_tax_charge    xxcff_contract_lines.second_tax_charge%TYPE;    -- 2��ڈȍ~����Ŋz_���[�X��
    ln_second_total_charge  xxcff_contract_lines.second_total_charge%TYPE;  -- 2��ڈȍ~�v_���[�X��
    ln_gross_charge         xxcff_contract_lines.gross_charge%TYPE;         -- ���z���[�X��_���[�X��
    ln_gross_tax_charge     xxcff_contract_lines.gross_tax_charge%TYPE;     -- ���z�����_���[�X��
    ln_gross_total_charge   xxcff_contract_lines.gross_total_charge%TYPE;   -- ���z�v_���[�X��
    ln_estimated_cash_price xxcff_contract_lines.estimated_cash_price%TYPE; -- ���ό����w�����z
-- Add 2014/05/19 Ver.1.3 Start
    ln_gross_deduction       xxcff_contract_lines.gross_deduction%TYPE;       -- ���z���[�X��_�T���z
    ln_gross_tax_deduction   xxcff_contract_lines.gross_tax_deduction%TYPE;   -- ���z�����_�T���z
    ln_gross_total_deduction xxcff_contract_lines.gross_total_deduction%TYPE; -- ���z�v_�T���z
-- Add 2014/05/19 Ver.1.3 End
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
    -- ***      �f�[�^�p�b�`����           ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�_�񖾍׍X�V�p�f�[�^�쐬
    -- =====================================
    -- ���[�X��-1
    ln_payment_frequency   := gt_payment_frequency -1;
    -- ���񌎊z���[�X��_���[�X��
    ln_first_charge        := NVL(gr_param.first_charge,gt_first_charge);
    -- �������Ŋz_���[�X��
    ln_first_tax_charge    := NVL(gr_param.first_tax_charge,gt_first_tax_charge);
    -- ����v_���[�X��
    ln_first_total_charge  := ln_first_charge + ln_first_tax_charge;
    -- 2��ڈȍ~���z���[�X��_���[�X��
    ln_second_charge       := NVL(gr_param.second_charge,gt_second_charge);
    -- 2��ڈȍ~����Ŋz_���[�X��
    ln_second_tax_charge   := NVL(gr_param.second_tax_charge,gt_second_tax_charge);
    -- 2��ڈȍ~�v_���[�X��
    ln_second_total_charge := ln_second_charge + ln_second_tax_charge;
    -- ���z���[�X��_���[�X��
    ln_gross_charge        := ln_first_charge + (ln_second_charge * ln_payment_frequency);
    -- ���z�����_���[�X��
    ln_gross_tax_charge    := ln_first_tax_charge + (ln_second_tax_charge * ln_payment_frequency);
    -- ���z�v_���[�X��
    ln_gross_total_charge  := ln_first_total_charge + (ln_second_total_charge * ln_payment_frequency);
    -- ���ό����w�����z
    ln_estimated_cash_price := NVL(gr_param.estimated_cash_price,gt_estimated_cash_price);
-- Add 2014/05/19 Ver.1.3 Start
    -- ���z���[�X��_�T���z
    ln_gross_deduction       := gt_first_deduction + (gt_second_deduction * ln_payment_frequency);
    -- ���z�����_�T���z
    ln_gross_tax_deduction   := gt_first_tax_deduction + (gt_second_tax_deduction * ln_payment_frequency);
    -- ���z�v_�T���z
    ln_gross_total_deduction := ln_gross_deduction + ln_gross_tax_deduction;
-- Add 2014/05/19 Ver.1.3 End
--
    -- =====================================
    -- ���[�X�_�񖾍ׂ̃��b�N���擾
    -- =====================================
    BEGIN
      SELECT
        xcl.contract_line_id AS contract_line_id  -- �_�񖾍ד���ID
      INTO
        lv_contract_line_id
      FROM
        xxcff_contract_lines xcl
      WHERE  xcl.contract_line_id  =  gt_contract_line_id
      FOR UPDATE OF xcl.contract_line_id NOWAIT;
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- =====================================
    -- ���[�X�_�񖾍׃e�[�u���̍X�V
    -- =====================================
    BEGIN
      UPDATE  xxcff_contract_lines xcl
      SET     xcl.first_charge            = ln_first_charge                 -- ���񌎊z���[�X��_���[�X��
             ,xcl.first_tax_charge        = ln_first_tax_charge             -- �������Ŋz_���[�X��
             ,xcl.first_total_charge      = ln_first_total_charge           -- ����v_���[�X��
             ,xcl.second_charge           = ln_second_charge                -- 2��ڈȍ~���z���[�X��_���[�X��
             ,xcl.second_tax_charge       = ln_second_tax_charge            -- 2��ڈȍ~����Ŋz_���[�X��
             ,xcl.second_total_charge     = ln_second_total_charge          -- 2��ڈȍ~�v_���[�X��
             ,xcl.gross_charge            = ln_gross_charge                 -- ���z���[�X��_���[�X��
             ,xcl.gross_tax_charge        = ln_gross_tax_charge             -- ���z�����_���[�X��
             ,xcl.gross_total_charge      = ln_gross_total_charge           -- ���z�v_���[�X��
-- Add 2014/05/19 Ver.1.3 Start
             ,xcl.gross_deduction         = ln_gross_deduction              -- ���z���[�X��_�T���z
             ,xcl.gross_tax_deduction     = ln_gross_tax_deduction          -- ���z�����_�T���z
             ,xcl.gross_total_deduction   = ln_gross_total_deduction        -- ���z�v_�T���z
-- Add 2014/05/19 Ver.1.3 End
             ,xcl.estimated_cash_price    = ln_estimated_cash_price         -- ���ό����w�����z
-- Add 2013/07/11 Ver.1.1 Start
             ,xcl.tax_code                = NVL(gr_param.tax_code, xcl.tax_code) -- �ŋ��R�[�h
-- Add 2013/07/11 Ver.1.1 End
             ,xcl.last_updated_by         = cn_last_updated_by              -- �ŏI�X�V��
             ,xcl.last_update_date        = cd_last_update_date             -- �ŏI�X�V��
             ,xcl.last_update_login       = cn_last_update_login            -- �ŏI�X�V���O�C��
             ,xcl.request_id              = cn_request_id                   -- �v��ID
             ,xcl.program_application_id  = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xcl.program_id              = cn_program_id                   -- �R���J�����g�E�v���O����ID
             ,xcl.program_update_date     = cd_program_update_date          -- �v���O�����X�V��
      WHERE   xcl.contract_line_id        = gt_contract_line_id             -- �_�񖾍ד���ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END update_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_backup_data
   * Description      : �f�[�^�o�b�N�A�b�v�̎��s(A-4)
   ***********************************************************************************/
  PROCEDURE get_backup_data(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_backup_data'; -- �v���O������
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
    lv_run_line_num  xxcff_contract_lines_bk.run_line_num%TYPE;  -- ���s�}��
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
    -- ***  �f�[�^�o�b�N�A�b�v�̎��s�̎��s ***
    -- ***************************************
--
    -- =====================================
    -- ���s�}�Ԃ��擾
    -- =====================================
--
    --���s��v���Ԃ��Ƃ̍ő���s�}�ԁ{�P���擾
    BEGIN
      SELECT
         NVL(MAX(xclb.run_line_num), 0) + 1 AS run_line_num -- �ő���s�}�ԁ{�P
      INTO
         lv_run_line_num
      FROM
         xxcff_contract_lines_bk    xclb    -- ���[�X�_�񖾍�BK
      WHERE  xclb.run_period_name    = gt_period_name
      AND    xclb.contract_header_id = gt_contract_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50202
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- ���[�X�_�񖾍׃o�b�N�A�b�v����
    -- =====================================
    --���[�X�_�񖾍ׂ̍X�V�Ώۃf�[�^�̃o�b�N�A�b�v���擾
    BEGIN
      INSERT INTO xxcff_contract_lines_bk(
         contract_line_id                           -- �_�񖾍ד���ID
        ,contract_header_id                         -- �_�����ID
        ,contract_line_num                          -- �_��}��
        ,contract_status                            -- �_��X�e�[�^�X
        ,first_charge                               -- ���񌎊z���[�X��_���[�X��
        ,first_tax_charge                           -- �������Ŋz_���[�X��
        ,first_total_charge                         -- ����v_���[�X��
        ,second_charge                              -- 2��ڈȍ~���z���[�X��_���[�X��
        ,second_tax_charge                          -- 2��ڈȍ~����Ŋz_���[�X��
        ,second_total_charge                        -- 2��ڈȍ~�v_���[�X��
        ,first_deduction                            -- ���񌎊z���[�X��_�T���z
        ,first_tax_deduction                        -- ���񌎊z����Ŋz_�T���z
        ,first_total_deduction                      -- ����v_�T���z
        ,second_deduction                           -- 2��ڈȍ~���z���[�X��_�T���z
        ,second_tax_deduction                       -- 2��ڈȍ~����Ŋz_�T���z
        ,second_total_deduction                     -- 2��ڈȍ~�v_�T���z
        ,gross_charge                               -- ���z���[�X��_���[�X��
        ,gross_tax_charge                           -- ���z�����_���[�X��
        ,gross_total_charge                         -- ���z�v_���[�X��
        ,gross_deduction                            -- ���z���[�X��_�T���z
        ,gross_tax_deduction                        -- ���z�����_�T���z
        ,gross_total_deduction                      -- ���z�v_�T���z
        ,lease_kind                                 -- ���[�X���
        ,estimated_cash_price                       -- ���ό����w�����z
        ,present_value_discount_rate                -- ���݉��l������
        ,present_value                              -- ���݉��l
        ,life_in_months                             -- �@��ϗp�N��
        ,original_cost                              -- �擾���z
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,original_cost_type1                        -- ���[�X���z_���_��
        ,original_cost_type2                        -- ���[�X���z_�ă��[�X
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
        ,calc_interested_rate                       -- �v�Z���q��
        ,object_header_id                           -- ��������ID
        ,asset_category                             -- ���Y���
        ,expiration_date                            -- ������
        ,cancellation_date                          -- ���r����
        ,vd_if_date                                 -- ���[�X�_����A�g��
        ,info_sys_if_date                           -- ���[�X�Ǘ����A�g��
        ,first_installation_address                 -- ����ݒu�ꏊ
        ,first_installation_place                   -- ����ݒu��
-- Add 2013/07/11 Ver.1.1 Start
        ,tax_code                                   -- �ŋ��R�[�h
-- Add 2013/07/11 Ver.1.1 End
        ,run_period_name                            -- ���s��v����
        ,run_line_num                               -- ���s�}��
        ,created_by                                 -- �쐬��
        ,creation_date                              -- �쐬��
        ,last_updated_by                            -- �ŏI�X�V��
        ,last_update_date                           -- �ŏI�X�V��
        ,last_update_login                          -- �ŏI�X�V���O�C��
        ,request_id                                 -- �v��ID
        ,program_application_id                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                                 -- �R���J�����g�E�v���O����ID
        ,program_update_date)                       -- �v���O�����X�V��
      SELECT
         xcl.contract_line_id
        ,xcl.contract_header_id
        ,xcl.contract_line_num
        ,xcl.contract_status
        ,xcl.first_charge
        ,xcl.first_tax_charge
        ,xcl.first_total_charge
        ,xcl.second_charge
        ,xcl.second_tax_charge
        ,xcl.second_total_charge
        ,xcl.first_deduction
        ,xcl.first_tax_deduction
        ,xcl.first_total_deduction
        ,xcl.second_deduction
        ,xcl.second_tax_deduction
        ,xcl.second_total_deduction
        ,xcl.gross_charge
        ,xcl.gross_tax_charge
        ,xcl.gross_total_charge
        ,xcl.gross_deduction
        ,xcl.gross_tax_deduction
        ,xcl.gross_total_deduction
        ,xcl.lease_kind
        ,xcl.estimated_cash_price
        ,xcl.present_value_discount_rate
        ,xcl.present_value
        ,xcl.life_in_months
        ,xcl.original_cost
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,xcl.original_cost_type1
        ,xcl.original_cost_type2
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
        ,xcl.calc_interested_rate
        ,xcl.object_header_id
        ,xcl.asset_category
        ,xcl.expiration_date
        ,xcl.cancellation_date
        ,xcl.vd_if_date
        ,xcl.info_sys_if_date
        ,xcl.first_installation_address
        ,xcl.first_installation_place
-- Add 2013/07/11 Ver.1.1 Start
        ,xcl.tax_code
-- Add 2013/07/11 Ver.1.1 End
        ,gt_period_name
        ,lv_run_line_num
        ,xcl.created_by
        ,xcl.creation_date
        ,xcl.last_updated_by
        ,xcl.last_update_date
        ,xcl.last_update_login
        ,xcl.request_id
        ,xcl.program_application_id
        ,xcl.program_id
        ,xcl.program_update_date
      FROM   xxcff_contract_lines xcl                    --���[�X�_�񖾍�
      WHERE  xcl.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50200
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =====================================
    -- ���[�X�x���v��o�b�N�A�b�v����
    -- =====================================
    --���[�X�x���v��̍X�V�Ώۃf�[�^�̃o�b�N�A�b�v���擾
    BEGIN
      INSERT INTO xxcff_pay_planning_bk(
         contract_line_id           -- �_�񖾍ד���ID
        ,payment_frequency          -- �x����
        ,contract_header_id         -- �_�����ID
        ,period_name                -- ��v����
        ,payment_date               -- �x����
        ,lease_charge               -- ���[�X��
        ,lease_tax_charge           -- ���[�X��_�����
        ,lease_deduction            -- ���[�X�T���z
        ,lease_tax_deduction        -- ���[�X�T���z_�����
        ,op_charge                  -- �n�o���[�X��
        ,op_tax_charge              -- �n�o���[�X���z_�����
        ,fin_debt                   -- �e�h�m���[�X���z
        ,fin_tax_debt               -- �e�h�m���[�X���z_�����
        ,fin_interest_due           -- �e�h�m���[�X�x������
        ,fin_debt_rem               -- �e�h�m���[�X���c
        ,fin_tax_debt_rem           -- �e�h�m���[�X���c_�����
        ,accounting_if_flag         -- ��v�h�e�t���O
        ,payment_match_flag         -- �ƍ��σt���O
        ,run_period_name            -- ���s��v����
        ,run_line_num               -- ���s�}��
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,debt_re                    -- ���[�X���z_�ă��[�X
        ,interest_due_re            -- ���[�X�x������_�ă��[�X
        ,debt_rem_re                -- ���[�X���c_�ă��[�X
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
        ,created_by                 -- �쐬��
        ,creation_date              -- �쐬��
        ,last_updated_by            -- �ŏI�X�V��
        ,last_update_date           -- �ŏI�X�V��
        ,last_update_login          -- �ŏI�X�V���O�C��
        ,request_id                 -- �v��ID
        ,program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                 -- �R���J�����g�E�v���O����ID
        ,program_update_date)       -- �v���O�����X�V��
      SELECT
         xpp.contract_line_id
        ,xpp.payment_frequency
        ,xpp.contract_header_id
        ,xpp.period_name
        ,xpp.payment_date
        ,xpp.lease_charge
        ,xpp.lease_tax_charge
        ,xpp.lease_deduction
        ,xpp.lease_tax_deduction
        ,xpp.op_charge
        ,xpp.op_tax_charge 
        ,xpp.fin_debt 
        ,xpp.fin_tax_debt
        ,xpp.fin_interest_due 
        ,xpp.fin_debt_rem 
        ,xpp.fin_tax_debt_rem 
        ,xpp.accounting_if_flag
        ,xpp.payment_match_flag
        ,gt_period_name
        ,lv_run_line_num
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,xpp.debt_re
        ,xpp.interest_due_re
        ,xpp.debt_rem_re
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
        ,xpp.created_by
        ,xpp.creation_date
        ,xpp.last_updated_by
        ,xpp.last_update_date
        ,xpp.last_update_login
        ,xpp.request_id
        ,xpp.program_application_id
        ,xpp.program_id
        ,xpp.program_update_date
      FROM   xxcff_pay_planning xpp     --���[�X�x���v��
      WHERE  xpp.contract_line_id = gt_contract_line_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00101
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50201
                       ,iv_token_name2  => cv_tkn_info
                       ,iv_token_value2 => NULL
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END get_backup_data;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : �f�[�^�o�͂̎��s(A-3,A-9)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- �v���O������
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
    cv_application  CONSTANT VARCHAR2(10) := 'XXCCP';
    cv_out_csv_01   CONSTANT VARCHAR2(20) := 'XXCCP008A01C';
    cv_out_csv_02   CONSTANT VARCHAR2(20) := 'XXCCP008A02C';
    cv_out_csv_03   CONSTANT VARCHAR2(20) := 'XXCCP008A03C';
    cv_out_csv_04   CONSTANT VARCHAR2(20) := 'XXCCP008A04C';
    cv_status_err   CONSTANT VARCHAR2(20) := 'ERROR';
--
    -- *** ���[�J���ϐ� ***
    ln_request_id NUMBER;
    lb_return     BOOLEAN;
    lv_phase      VARCHAR2(5000);
    lv_status     VARCHAR2(5000);
    lv_dev_phase  VARCHAR2(5000);
    lv_dev_status VARCHAR2(5000);
    lv_message    VARCHAR2(5000);
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
    -- ***     �X�V�O�f�[�^�o�͂̎��s      ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�_��f�[�^CSV�o��
    -- =====================================
    --�R���J�����g���s
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_01
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- �_��ԍ�
                       ,argument2   => NULL                      -- ���[�X���
                       ,argument3   => gr_param.object_code      -- �����R�[�h1
                       ,argument4   => NULL                      -- �����R�[�h2
                       ,argument5   => NULL                      -- �����R�[�h3
                       ,argument6   => NULL                      -- �����R�[�h4
                       ,argument7   => NULL                      -- �����R�[�h5
                       ,argument8   => NULL                      -- �����R�[�h6
                       ,argument9   => NULL                      -- �����R�[�h7
                       ,argument10  => NULL                      -- �����R�[�h8
                       ,argument11  => NULL                      -- �����R�[�h9
                       ,argument12  => NULL                      -- �����R�[�h10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �R���J�����g���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00197        -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_syori             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cff_50203         -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�ҋ@
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- �R���J�����g�ҋ@�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00198         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- �R���J�����g�����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00199         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- ���[�X�����f�[�^CSV�o��
    -- =====================================
    --�R���J�����g���s
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_02
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- �_��ԍ�
                       ,argument2   => NULL                      -- ���[�X���
                       ,argument3   => gr_param.object_code      -- �����R�[�h1
                       ,argument4   => NULL                      -- �����R�[�h2
                       ,argument5   => NULL                      -- �����R�[�h3
                       ,argument6   => NULL                      -- �����R�[�h4
                       ,argument7   => NULL                      -- �����R�[�h5
                       ,argument8   => NULL                      -- �����R�[�h6
                       ,argument9   => NULL                      -- �����R�[�h7
                       ,argument10  => NULL                      -- �����R�[�h8
                       ,argument11  => NULL                      -- �����R�[�h9
                       ,argument12  => NULL                      -- �����R�[�h10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �R���J�����g���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00197        -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_syori             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cff_50204         -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�ҋ@
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- �R���J�����g�ҋ@�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00198         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- �R���J�����g�����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00199         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- ���[�X�x���v��f�[�^CSV�o��
    -- =====================================
    --�R���J�����g���s
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_03
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- �_��ԍ�
                       ,argument2   => NULL                      -- ���[�X���
                       ,argument3   => gr_param.object_code      -- �����R�[�h1
                       ,argument4   => NULL                      -- �����R�[�h2
                       ,argument5   => NULL                      -- �����R�[�h3
                       ,argument6   => NULL                      -- �����R�[�h4
                       ,argument7   => NULL                      -- �����R�[�h5
                       ,argument8   => NULL                      -- �����R�[�h6
                       ,argument9   => NULL                      -- �����R�[�h7
                       ,argument10  => NULL                      -- �����R�[�h8
                       ,argument11  => NULL                      -- �����R�[�h9
                       ,argument12  => NULL                      -- �����R�[�h10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �R���J�����g���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00197        -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_syori             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cff_50205         -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�ҋ@
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- �R���J�����g�ҋ@�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00198         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- �R���J�����g�����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00199         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- =====================================
    -- ���[�X��v����f�[�^CSV�o��
    -- =====================================
    --�R���J�����g���s
    ln_request_id := fnd_request.submit_request(
                        application => cv_application
                       ,program     => cv_out_csv_04
                       ,description => NULL
                       ,start_time  => NULL
                       ,sub_request => FALSE
                       ,argument1   => gr_param.contract_number  -- �_��ԍ�
                       ,argument2   => NULL                      -- ���[�X���
                       ,argument3   => gr_param.object_code      -- �����R�[�h1
                       ,argument4   => NULL                      -- �����R�[�h2
                       ,argument5   => NULL                      -- �����R�[�h3
                       ,argument6   => NULL                      -- �����R�[�h4
                       ,argument7   => NULL                      -- �����R�[�h5
                       ,argument8   => NULL                      -- �����R�[�h6
                       ,argument9   => NULL                      -- �����R�[�h7
                       ,argument10  => NULL                      -- �����R�[�h8
                       ,argument11  => NULL                      -- �����R�[�h9
                       ,argument12  => NULL                      -- �����R�[�h10
                     );
    --
    IF (ln_request_id = 0) THEN
      -- �R���J�����g���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00197        -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_syori             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cff_50206         -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�ҋ@
    lb_return := fnd_concurrent.wait_for_request(
                    request_id => ln_request_id
                   ,interval   => gn_interval
                   ,max_wait   => gn_max_wait
                   ,phase      => lv_phase
                   ,status     => lv_status
                   ,dev_phase  => lv_dev_phase
                   ,dev_status => lv_dev_status
                   ,message    => lv_message
                 );
    --
    IF (lb_return  = FALSE) THEN
      -- �R���J�����g�ҋ@�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00198         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
    --
    IF lv_status = cv_status_err THEN
      -- �R���J�����g�����G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcff00199         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_request_id         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => ln_request_id             -- �g�[�N���l1
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
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
  END out_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : ���̓p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_object_code           IN  VARCHAR2,      --   1.�����R�[�h
    iv_contract_number       IN  VARCHAR2,      --   2.�_��ԍ�
    iv_update_reason         IN  VARCHAR2,      --   3.�X�V���R
    iv_first_charge          IN  VARCHAR2,      --   4.���񃊁[�X��
    iv_second_charge         IN  VARCHAR2,      --   5.2��ڈȍ~�̃��[�X��
    iv_first_tax_charge      IN  VARCHAR2,      --   6.��������
    iv_second_tax_charge     IN  VARCHAR2,      --   7.2��ڈȍ~�̏����
    iv_estimated_cash_price  IN  VARCHAR2,      --   8.���ό����w�����z
-- Add 2013/07/11 Ver.1.1 Start
    iv_tax_code              IN  VARCHAR2,      --   9.�ŋ��R�[�h
-- ADd 2013/07/11 Ver.1.1 End
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
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
    ln_upd_cnt       NUMBER;                                     -- �X�V����
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
    -- ***    �p�����[�^�`�F�b�N����       ***
    -- ***************************************
--
    -- =====================================
    -- �K�{�p�����[�^�`�F�b�N
    -- =====================================
--
    -- 1 : �����R�[�h(�K�{)
    IF iv_object_code IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50010
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2 : �_��ԍ�(�K�{)
    IF iv_contract_number IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50040
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3 : �X�V���R(�K�{)
    IF iv_update_reason IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00157
                     ,iv_token_name1  => cv_tkn_input
                     ,iv_token_value1 => cv_msg_cff_50199
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- �����e�i���X���ڃ`�F�b�N
    -- =====================================
    IF (iv_first_charge IS NULL) AND 
       (iv_second_charge IS NULL) AND 
       (iv_first_tax_charge IS NULL) AND 
       (iv_second_tax_charge IS NULL) AND 
-- Mod 2013/07/11 Ver.1.1 Start
--       (iv_estimated_cash_price IS NULL) THEN
       (iv_estimated_cash_price IS NULL) AND
       (iv_tax_code IS NULL) THEN
-- Mod 2013/07/11 Ver.1.1 End
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00207
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- �p�����[�^�^�E�����`�F�b�N
    -- (�p�����[�^�l�̊i�[)
    -- =====================================
--
    -- 1 : �����R�[�h(�K�{)
    BEGIN
      gr_param.object_code := iv_object_code;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50010
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 2 : �_��ԍ�(�K�{)
    BEGIN
      gr_param.contract_number := iv_contract_number;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50040
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 3 : �X�V���R(�K�{)
    BEGIN
      gr_param.update_reason := iv_update_reason;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00200
                       ,iv_token_name1  => cv_tkn_input
                       ,iv_token_value1 => cv_msg_cff_50199
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 4 : ���񃊁[�X��(�C��)
    IF iv_first_charge IS NOT NULL THEN
      BEGIN
        gr_param.first_charge := TO_NUMBER(iv_first_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50223
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.first_charge := NULL;
    END IF;
--
    -- 5 : 2��ڈȍ~�̃��[�X��(�C��)
    IF iv_second_charge IS NOT NULL THEN
      BEGIN
        gr_param.second_charge := TO_NUMBER(iv_second_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50224
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.second_charge := NULL;
    END IF;
--
    -- 6 : ��������(�C��)
    IF iv_first_tax_charge IS NOT NULL THEN
      BEGIN
        gr_param.first_tax_charge := TO_NUMBER(iv_first_tax_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50225
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.first_tax_charge := NULL;
    END IF;
--
    -- 7 : 2��ڈȍ~�̏����(�C��)
    IF iv_second_tax_charge IS NOT NULL THEN
      BEGIN
        gr_param.second_tax_charge := TO_NUMBER(iv_second_tax_charge);
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50226
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.second_tax_charge := NULL;
    END IF;
--
    -- 8 : ���ό����w�����z(�C��)
    IF iv_estimated_cash_price IS NOT NULL THEN
      BEGIN
        gr_param.estimated_cash_price := TO_NUMBER(iv_estimated_cash_price);
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50110
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.estimated_cash_price := NULL;
    END IF;
--
-- Add 2013/07/11 Ver.1.1 Start
    -- 9 : �ŋ��R�[�h(�C��)
    IF iv_tax_code IS NOT NULL THEN
      BEGIN
        gr_param.tax_code := iv_tax_code;
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00200
                         ,iv_token_name1  => cv_tkn_input
                         ,iv_token_value1 => cv_msg_cff_50148
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    ELSE
      gr_param.tax_code := NULL;
    END IF;
-- ADd 2013/07/11 Ver.1.1 End
--
    -- =====================================
    -- �f�[�^�̑��݃`�F�b�N
    -- =====================================
    --���[�X����
    BEGIN
      SELECT
        xoh.object_header_id AS object_header_id -- ��������ID
      INTO
        gt_object_header_id
      FROM
         xxcff_object_headers xoh                -- ���[�X����
      WHERE  xoh.object_code = gr_param.object_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ��������ID���擾�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00123
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => gr_param.object_code
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --���[�X�_�񖾍�
    BEGIN
      SELECT
         xcl.contract_line_id                  AS contract_line_id
        ,xcl.first_charge                      AS first_charge
        ,xcl.first_tax_charge                  AS first_tax_charge
        ,xcl.second_charge                     AS second_charge
        ,xcl.second_tax_charge                 AS second_tax_charge
        ,xcl.first_deduction                   AS first_deduction
        ,xcl.second_deduction                  AS second_deduction
-- Add 2014/05/19 Ver.1.3 Start
        ,xcl.first_tax_deduction               AS first_tax_deduction
        ,xcl.second_tax_deduction              AS second_tax_deduction
-- Add 2014/05/19 Ver.1.3 End
        ,xcl.estimated_cash_price              AS estimated_cash_price
        ,xcl.life_in_months                    AS life_in_months
        ,xch.contract_header_id                AS contract_header_id
        ,TRUNC(xch.contract_date, cv_format_m) AS contract_date
        ,xch.lease_type                        AS lease_type
        ,xch.payment_frequency                 AS payment_frequency
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,xch.lease_class                       AS lease_class
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
      INTO
         gt_contract_line_id           -- �_�񖾍ד���ID
        ,gt_first_charge               -- ���񌎊z���[�X��_���[�X��
        ,gt_first_tax_charge           -- �������Ŋz_���[�X��
        ,gt_second_charge              -- 2��ڈȍ~���z���[�X��_���[�X��
        ,gt_second_tax_charge          -- 2��ڈȍ~����Ŋz_���[�X��
        ,gt_first_deduction            -- ���񌎊z���[�X��_�T���z
        ,gt_second_deduction           -- 2��ڈȍ~���z���[�X��_�T���z
-- Add 2014/05/19 Ver.1.3 Start
        ,gt_first_tax_deduction        -- ���񌎊z����Ŋz_�T���z
        ,gt_second_tax_deduction       -- 2��ڈȍ~����Ŋz_�T���z
-- Add 2014/05/19 Ver.1.3 End
        ,gt_estimated_cash_price       -- ���ό����w�����z
        ,gt_life_in_months             -- �@��ϗp�N��
        ,gt_contract_header_id         -- �_�����ID
        ,gt_contract_date              -- ���[�X�_���
        ,gt_lease_type                 -- ���[�X�敪
        ,gt_payment_frequency          -- �x����
-- 2016/08/22 Ver.1.4 Y.Koh ADD Start
        ,gt_lease_class                -- ���[�X���
-- 2016/08/22 Ver.1.4 Y.Koh ADD End
      FROM
         xxcff_contract_lines    xcl   -- ���[�X�_�񖾍�
        ,xxcff_contract_headers  xch   -- ���[�X�_��w�b�_
        ,xxcff_object_headers    xoh   -- ���[�X����
      WHERE  xcl.object_header_id   = xoh.object_header_id
      AND    xch.contract_number    = gr_param.contract_number
      AND    xoh.object_code        = gr_param.object_code
      AND    xcl.contract_header_id = xch.contract_header_id
      AND    xcl.contract_status   IN (cv_ctrct_st_ctrct,cv_ctrct_st_reles)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �_�񖾍׏�񂪎擾�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00208
                       ,iv_token_name1  => cv_tkn_prm_name
                       ,iv_token_value1 => cv_msg_cff_50040
                       ,iv_token_name2  => cv_tkn_column
                       ,iv_token_value2 => gr_param.contract_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �Ώی���
    ln_upd_cnt    := SQL%ROWCOUNT;
    gn_target_cnt := ln_upd_cnt;    -- �Ώی���
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END chk_param;
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
    xxcff_common1_pkg.put_log_param(
       iv_which    => cv_file_type_log     -- �o�͋敪
      ,ov_retcode  => lv_retcode           -- ���^�[���R�[�h
      ,ov_errbuf   => lv_errbuf            -- �G���[���b�Z�[�W
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_xxcff00094          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_func_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_msg_cff_50210           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- =====================================
    -- ���[�X�䒠�I�[�v�����Ԏ擾
    -- =====================================
    BEGIN
      SELECT
         fdp.period_name                AS period_name
        ,fdp.calendar_period_close_date AS calendar_period_close_date
      INTO
         gt_period_name
        ,gd_period_close_date
      FROM
         fa_deprn_periods    fdp   -- �������p����
        ,xxcff_lease_kind_v  xlkv  -- ���[�X��ރr���[
      WHERE   fdp.book_type_code    = xlkv.book_type_code
      AND     xlkv.lease_kind_code  = cv_les_kind_fin        --'0':Fin���[�X
      AND     fdp.period_close_date IS NULL                  -- �I�[�v������
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00186
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- �v���t�@�C���l�̎擾
    -- ============================================
    -- XXCOS:�ҋ@�Ԋu
    gn_interval := TO_NUMBER(fnd_profile.value(cv_prof_interval));
    --
    IF (gn_interval IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_xxcff00020          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_prof_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_prof_interval           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- XXCOS:�ő�ҋ@����
    gn_max_wait := TO_NUMBER(fnd_profile.value(cv_prof_max_wait));
    --
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_xxcff00020          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_prof_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_prof_max_wait           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_object_code            IN    VARCHAR2,        --   1.�����R�[�h
    iv_contract_number        IN    VARCHAR2,        --   2.�_��ԍ�
    iv_update_reason          IN    VARCHAR2,        --   3.�X�V���R
    iv_first_charge           IN    VARCHAR2,        --   4.���񃊁[�X��
    iv_second_charge          IN    VARCHAR2,        --   5.2��ڈȍ~�̃��[�X��
    iv_first_tax_charge       IN    VARCHAR2,        --   6.��������
    iv_second_tax_charge      IN    VARCHAR2,        --   7.2��ڈȍ~�̏����
    iv_estimated_cash_price   IN    VARCHAR2,        --   8.���ό����w�����z
-- Add 2013/07/11 Ver.1.1 Start
    iv_tax_code               IN    VARCHAR2,        --   9.�ŋ��R�[�h
-- ADd 2013/07/11 Ver.1.1 End
    ov_errbuf                 OUT   VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT   VARCHAR2,        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT   VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
--
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D���̓p�����[�^�`�F�b�N����
    -- ============================================
--
    chk_param(
       iv_object_code            --   1.�����R�[�h
      ,iv_contract_number        --   2.�_��ԍ�
      ,iv_update_reason          --   3.�X�V���R
      ,iv_first_charge           --   4.���񃊁[�X��
      ,iv_second_charge          --   5.2��ڈȍ~�̃��[�X��
      ,iv_first_tax_charge       --   6.��������
      ,iv_second_tax_charge      --   7.2��ڈȍ~�̏����
      ,iv_estimated_cash_price   --   8.���ό����w�����z
-- Add 2013/07/11 Ver.1.1 Start
      ,iv_tax_code               --   9.�ŋ��R�[�h
-- ADd 2013/07/11 Ver.1.1 End
      ,lv_errbuf                 --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D�X�V�O�f�[�^�o�͂̎��s
    -- ============================================
--
    out_csv_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D�f�[�^�o�b�N�A�b�v�̎��s
    -- ============================================
--
    get_backup_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5�D�f�[�^�p�b�`����
    -- ============================================
--
    update_contract_lines(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6�D���[�X���菈��
    -- ============================================
--
    get_judge_lease(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7�D�x���v��č쐬�y�уt���O�X�V
    -- ============================================
--
    update_pay_planning(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-8�D���[�X�_�񖾍ׂ̗����̍쐬
    -- ============================================
--
    insert_contract_histories(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-9�D�X�V��f�[�^�o�͂̎��s
    -- ============================================
--
    out_csv_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����I������
    gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ***
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt  :=  gn_error_cnt + 1;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_object_code            IN    VARCHAR2,        --   1.�����R�[�h
    iv_contract_number        IN    VARCHAR2,        --   2.�_��ԍ�
    iv_update_reason          IN    VARCHAR2,        --   3.�X�V���R
    iv_first_charge           IN    VARCHAR2,        --   4.���񃊁[�X��
    iv_second_charge          IN    VARCHAR2,        --   5.2��ڈȍ~�̃��[�X��
    iv_first_tax_charge       IN    VARCHAR2,        --   6.��������
    iv_second_tax_charge      IN    VARCHAR2,        --   7.2��ڈȍ~�̏����
-- Mod 2013/07/11 Ver.1.1 Start
--    iv_estimated_cash_price   IN    VARCHAR2         --   8.���ό����w�����z
    iv_estimated_cash_price   IN    VARCHAR2,        --   8.���ό����w�����z
    iv_tax_code               IN    VARCHAR2         --   9.�ŋ��R�[�h
-- Mod 2013/07/11 Ver.1.1 End
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
      ,iv_which   => cv_file_type_out
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
       iv_object_code             --   1.�����R�[�h
      ,iv_contract_number         --   2.�_��ԍ�
      ,iv_update_reason           --   3.�X�V���R
      ,iv_first_charge            --   4.���񃊁[�X��
      ,iv_second_charge           --   5.2��ڈȍ~�̃��[�X��
      ,iv_first_tax_charge        --   6.��������
      ,iv_second_tax_charge       --   7.2��ڈȍ~�̏����
      ,iv_estimated_cash_price    --   8.���ό����w�����z
-- Add 2013/07/11 Ver.1.1 Start
      ,iv_tax_code                --   9.�ŋ��R�[�h
-- ADd 2013/07/11 Ver.1.1 End
      ,lv_errbuf                  --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                 --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCFF016A36C;
/
