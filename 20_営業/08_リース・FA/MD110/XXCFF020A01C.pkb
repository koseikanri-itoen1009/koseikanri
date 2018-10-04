CREATE OR REPLACE PACKAGE BODY XXCFF020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCFF020A01C(body)
 * Description      : �o�^�ςݎx���v��̎x�������A�x���񐔂̕ύX
 * MD.050           : MD050_CFF_020_A01_���[�X���ύX�v���O����
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_target_data        �Ώۃf�[�^���o(A-2)
 *  output_csv             �e����CSV�o��(A-3)
 *  create_pay_planning    �V�x���v��f�[�^�쐬(A-4)
 *  ins_backup             �f�[�^�o�b�N�A�b�v(A-5)
 *  replace_pay_planning   �V�x���v��o�^(A-6)
 *  upd_contract_data      �_����X�V(A-7)
 *  ins_adjustment_oif     �C��OIF�쐬(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/10/02    1.0   H.Sasaki         �V�K�쐬(E_�{�ғ�_14830)
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_comm               CONSTANT VARCHAR2(3) := ',';
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
  gn_warn_cnt               NUMBER;                    -- �X�L�b�v����
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  
  conc_error_expt           EXCEPTION;            --  �R���J�����g�N�����̗�O����
  procedure_expt            EXCEPTION;            --  �e�v���V�[�W�����ʂɑ΂����O(SUBMAIN)
  lock_expt                 EXCEPTION;            --  ���b�N�G���[
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(30) :=  'XXCFF020A01C';                 --  �p�b�P�[�W��
  cv_app_kbn_cff                CONSTANT VARCHAR2(5)  :=  'XXCFF';                        --  �A�v���P�[�V�����Z�k��
  cv_app_kbn_ccp                CONSTANT VARCHAR2(5)  :=  'XXCCP';                        --  �A�v���P�[�V�����Z�k��
  --
  cv_msg_cff_00020              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00020';             --  �v���t�@�C���擾�G���[
  cv_msg_cff_00194              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00194';             --  ���[�X���������Ԏ擾�G���[
  cv_msg_cff_00123              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00123';             --  ���݃`�F�b�N�G���[
  cv_msg_cff_00094              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00094';             --  ���ʊ֐��G���[
  cv_msg_cff_00292              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00292';             --  ���[�X���ύX�s�G���[���b�Z�[�W
  cv_msg_cff_00165              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00165';             --  �擾�Ώۃf�[�^����
  cv_msg_cff_00007              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00007';             --  ���b�N�G���[
  cv_msg_cff_00293              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00293';             --  �x���񐔑Ó����`�F�b�N�G���[�i���[�X���ύX�j
  cv_msg_cff_00294              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00294';             --  ���[�X���ύX���{�G���[���b�Z�[�W
  cv_msg_cff_00268              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00268';             --  ���Y�J�e�S�����擾�G���[
  cv_msg_cff_00089              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00089';             --  �������擾�G���[
  cv_msg_cff_00197              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00197';             --  �R���J�����g���s�G���[
  cv_msg_cff_00198              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00198';             --  �R���J�����g�ҋ@�G���[
  cv_msg_cff_00199              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00199';             --  �R���J�����g�����G���[
  cv_msg_cff_00102              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-00102';             --  �o�^�G���[
  --
  cv_msg_cff_50210              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50210';             --  (�Œ蕶����)�R���J�����g�p�����[�^�o�͏���
  cv_msg_cff_50323              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50323';             --  (�Œ蕶����)���[�X���菈��
  cv_msg_cff_50303              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50303';             --  (�Œ蕶����)���Y�J�e�S���`�F�b�N
  cv_msg_cff_50219              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50219';             --  (�Œ蕶����)���[�X�_��w�b�_
  cv_msg_cff_50220              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50220';             --  (�Œ蕶����)���[�X�_�񖾍�
  cv_msg_cff_50088              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50088';             --  (�Œ蕶����)���[�X�x���v��
  cv_msg_cff_50203              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50203';             --  (�Œ蕶����)���[�X�_��f�[�^CSV�o��
  cv_msg_cff_50204              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50204';             --  (�Œ蕶����)���[�X�����f�[�^CSV�o��
  cv_msg_cff_50205              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50205';             --  (�Œ蕶����)���[�X�x���v��f�[�^CSV�o��
  cv_msg_cff_50206              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50206';             --  (�Œ蕶����)���[�X��v����CSV�o��
  cv_msg_cff_50256              CONSTANT VARCHAR2(30) :=  'APP-XXCFF1-50256';             --  (�Œ蕶����)���Y�ڍ׏��
  --
  cv_tok_cff_00020_1            CONSTANT VARCHAR2(30) :=  'PROF_NAME';                    --  (�g�[�N��)APP-XXCFF1-00020
  cv_tok_cff_00194_1            CONSTANT VARCHAR2(30) :=  'BOOK_ID';                      --  (�g�[�N��)APP-XXCFF1-00194
  cv_tok_cff_00123_1            CONSTANT VARCHAR2(30) :=  'COLUMN_DATA ';                 --  (�g�[�N��)APP-XXCFF1-00123
  cv_tok_cff_00094_1            CONSTANT VARCHAR2(30) :=  'FUNC_NAME';                    --  (�g�[�N��)APP-XXCFF1-00094
  cv_tok_cff_00165_1            CONSTANT VARCHAR2(30) :=  'GET_DATA';                     --  (�g�[�N��)APP-XXCFF1-00165
  cv_tok_cff_00007_1            CONSTANT VARCHAR2(30) :=  'TABLE_NAME';                   --  (�g�[�N��)APP-XXCFF1-00007
  cv_tok_cff_00293_1            CONSTANT VARCHAR2(30) :=  'FREQUENCY';                    --  (�g�[�N��)APP-XXCFF1-00293
  cv_tok_cff_00268_1            CONSTANT VARCHAR2(30) :=  'CATEGORY';                     --  (�g�[�N��)APP-XXCFF1-00268
  cv_tok_cff_00268_2            CONSTANT VARCHAR2(30) :=  'BOOK_TYPE_CODE';               --  (�g�[�N��)APP-XXCFF1-00268
  cv_tok_cff_00197_1            CONSTANT VARCHAR2(30) :=  'SYORI';                        --  (�g�[�N��)APP-XXCFF1-00197
  cv_tok_cff_00198_1            CONSTANT VARCHAR2(30) :=  'REQUEST_ID';                   --  (�g�[�N��)APP-XXCFF1-00198
  cv_tok_cff_00199_1            CONSTANT VARCHAR2(30) :=  'REQUEST_ID';                   --  (�g�[�N��)APP-XXCFF1-00199
  cv_tok_cff_00102_1            CONSTANT VARCHAR2(30) :=  'TABLE_NAME';                   --  (�g�[�N��)APP-XXCFF1-00102
  cv_tok_cff_00102_2            CONSTANT VARCHAR2(30) :=  'INFO';                         --  (�g�[�N��)APP-XXCFF1-00102
  --
  cv_prof_ifrs_sob_id           CONSTANT VARCHAR2(30) :=  'XXCFF1_IFRS_SET_OF_BKS_ID';    --  (�v���t�@�C��)XXCFF:IFRS����ID
  cv_prof_ifrs_lease_books      CONSTANT VARCHAR2(30) :=  'XXCFF1_IFRS_LEASE_BOOKS';      --  (�v���t�@�C��)XXCFF:�䒠��_IFRS���[�X�䒠
  cv_prof_conc_interval         CONSTANT VARCHAR2(30) :=  'XXCOS1_INTERVAL';              --  (�v���t�@�C��)XXCOS:�ҋ@�Ԋu
  cv_prof_conc_max_wait         CONSTANT VARCHAR2(30) :=  'XXCOS1_MAX_WAIT';              --  (�v���t�@�C��)XXCOS:�ő�ҋ@����
  --
  cv_prg_contract_csv           CONSTANT VARCHAR2(30) :=  'XXCCP008A01C';                 --  (�R���J�����g)���[�X�_��f�[�^CSV�o��
  cv_prg_object_csv             CONSTANT VARCHAR2(30) :=  'XXCCP008A02C';                 --  (�R���J�����g)���[�X�����f�[�^CSV�o��
  cv_prg_pay_planning_csv       CONSTANT VARCHAR2(30) :=  'XXCCP008A03C';                 --  (�R���J�����g)���[�X�x���v��f�[�^CSV�o��
  cv_prg_accounting_csv         CONSTANT VARCHAR2(30) :=  'XXCCP008A04C';                 --  (�R���J�����g)���[�X��v����CSV�o��
  --
  cv_lease_class_2              CONSTANT VARCHAR2(1)  :=  '2';                            --  ���[�X��ʁF2
  cv_dummy_code                 CONSTANT VARCHAR2(1)  :=  '*';                            --  �_�~�[�R�[�h
  cv_separator                  CONSTANT VARCHAR2(1)  :=  '-';                            --  �Z�p���[�^
  cv_dev_status_error           CONSTANT VARCHAR2(5)  :=  'ERROR';                        --  �X�e�[�^�X�FERROR
  cv_date_format                CONSTANT VARCHAR2(7)  :=  'YYYY-MM';                      --  ���t�t�H�[�}�b�g
  cv_date_format_ymd            CONSTANT VARCHAR2(10) :=  'YYYY/MM/DD';                   --  ���t�t�H�[�}�b�g
  cv_flag_1                     CONSTANT VARCHAR2(1)  :=  '1';                            --  �t���O�Œ�l�F1
  cv_flag_2                     CONSTANT VARCHAR2(1)  :=  '2';                            --  �t���O�Œ�l�F2
  cv_flag_y                     CONSTANT VARCHAR2(1)  :=  'Y';                            --  �t���O�Œ�l�FY
  cv_contract_status_210        CONSTANT VARCHAR2(3)  :=  '210';                          --  �_��X�e�[�^�X�F210(�f�[�^�����e�i���X)
  cv_update_reason              CONSTANT VARCHAR2(20) :=  '���[�X���X�V';                 --  �_�񖾍ח����D�X�V���R
  cv_oif_status_p               CONSTANT VARCHAR2(7)  :=  'PENDING';                      --  �X�VOIF�D�X�e�[�^�X
  cv_oif_amortized_yes          CONSTANT VARCHAR2(3)  :=  'YES';                          --  �X�VOIF�D�C���z���p�t���O
  cv_lang                       CONSTANT VARCHAR2(2)  :=  USERENV('LANG');                --  ����
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_target_rtype IS RECORD(
      object_header_id          xxcff_object_headers.object_header_id%TYPE            --  ��������ID
    , lease_class               xxcff_object_headers.lease_class%TYPE                 --  ���[�X���
    , owner_company             xxcff_object_headers.owner_company%TYPE               --  �{�Ё^�H��
    , contract_header_id        xxcff_contract_headers.contract_header_id%TYPE        --  �_�����ID
    , contract_line_id          xxcff_contract_lines.contract_line_id%TYPE            --  �_�񖾍ד���ID
    , payment_frequency         xxcff_pay_planning.payment_frequency%TYPE             --  ����x����
    , asset_category            xxcff_contract_lines.asset_category%TYPE              --  ���Y�o��
    , contract_number           xxcff_contract_headers.contract_number%TYPE           --  �_��ԍ�
    , lease_company             xxcff_contract_headers.lease_company%TYPE             --  ���[�X���
    , second_payment_date       xxcff_contract_headers.second_payment_date%TYPE       --  2��ڎx����
    , third_payment_date        xxcff_contract_headers.third_payment_date%TYPE        --  3��ڈȍ~�x����
    , lease_deduction           xxcff_pay_planning.lease_deduction%TYPE               --  ���[�X�T���z
    , lease_tax_charge          xxcff_pay_planning.lease_tax_charge%TYPE              --  ���[�X��_�����
    , lease_tax_deduction       xxcff_pay_planning.lease_tax_deduction%TYPE           --  ���[�X�T���z_�����
    , fin_debt_rem              xxcff_pay_planning.fin_debt_rem%TYPE                  --  �e�h�m���[�X���c
    , fin_debt                  xxcff_pay_planning.fin_debt%TYPE                      --  �e�h�m���[�X���z
    , fin_tax_debt              xxcff_pay_planning.fin_tax_debt%TYPE                  --  �e�h�m���[�X���z_�����
    , tax_code                  xxcff_contract_lines.tax_code%TYPE                    --  �ŃR�[�h
    , asset_category_id         NUMBER                                                --  ���Y�J�e�S��CCID
    , deprn_method              fa_category_book_defaults.deprn_method%TYPE           --  ���p���@
    , asset_category_code       VARCHAR2(210)                                         --  ���Y�J�e�S���R�[�h
    , remaining_frequency       xxcff_pay_planning.payment_frequency%TYPE             --  �c��x����
    , discount_rate             xxcff_discount_rate_mst.discount_rate_01%TYPE         --  ������
    , present_value             NUMBER                                                --  ���݉��l
    , sum_old_tax_charge        xxcff_pay_planning.lease_tax_charge%TYPE              --  �ύX�O����Ŋz(���v)
    , sum_new_tax_charge        xxcff_pay_planning.lease_tax_charge%TYPE              --  �ύX�����Ŋz(���v)
  );
  TYPE g_new_pay_plan_ttype IS TABLE OF xxcff_pay_planning%ROWTYPE INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param_object_code          xxcff_object_headers.object_code%TYPE;                    --  (�N���p�����[�^)�����R�[�h
  gt_param_new_frequency        xxcff_contract_headers.payment_frequencY%TYPE;            --  (�N���p�����[�^)�ύX��x����
  gt_param_new_charge           xxcff_contract_lines.second_charge%TYPE;                  --  (�N���p�����[�^)�ύX�ナ�[�X��
  gt_param_new_tax_charge       xxcff_contract_lines.second_tax_charge%TYPE;              --  (�N���p�����[�^)�ύX��Ŋz
  gt_param_new_tax_code         xxcff_contract_lines.tax_code%TYPE;                       --  (�N���p�����[�^)�ύX��ŃR�[�h
  gt_prof_ifrs_sob_id           fnd_profile_option_values.profile_option_value%TYPE;      --  (�v���t�@�C���l)IFRS����ID
  gt_prof_ifrs_lease_books      fnd_profile_option_values.profile_option_value%TYPE;      --  (�v���t�@�C���l)IFRS���[�X�䒠��
  gn_prof_conc_interval         NUMBER;                                                   --  (�v���t�@�C��)�R���J�����g�̑ҋ@�Ԋu
  gn_prof_conc_max_wait         NUMBER;                                                   --  (�v���t�@�C��)�R���J�����g�̍ő�ҋ@����
  gd_ifrs_period_date           DATE;                                                     --  IFRS��v����
  gt_ifrs_period_name           xxcff_pay_planning.period_name%TYPE;                      --  ��v���Ԗ�
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_object_code    IN  VARCHAR2        --  �����R�[�h
    , iv_new_frequency  IN  VARCHAR2        --  �ύX��x����
    , iv_new_charge     IN  VARCHAR2        --  �ύX�ナ�[�X��
    , iv_new_tax_charge IN  VARCHAR2        --  �ύX��Ŋz
    , iv_new_tax_code   IN  VARCHAR2        --  �ύX��ŃR�[�h
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    --  �p�����[�^�ێ�
    -- ===============================
    gt_param_object_code    :=  iv_object_code;                         --  �����R�[�h
    gt_param_new_frequency  :=  TO_NUMBER( iv_new_frequency );          --  �ύX��x����
    gt_param_new_charge     :=  TO_NUMBER( iv_new_charge );             --  �ύX�ナ�[�X��
    gt_param_new_tax_charge :=  TO_NUMBER( iv_new_tax_charge );         --  �ύX��Ŋz
    gt_param_new_tax_code   :=  iv_new_tax_code;                        --  �ύX��ŃR�[�h
    --
    -- ===============================
    --  �v���t�@�C���l�擾
    -- ===============================
    --  IFRS����ID
    gt_prof_ifrs_sob_id       :=  TO_NUMBER( fnd_profile.value( cv_prof_ifrs_sob_id ) );
    IF ( gt_prof_ifrs_sob_id IS NULL ) THEN
      --  �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00020          --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  cv_prof_ifrs_sob_id       --  �g�[�N���l1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --  IFRS���[�X�䒠��
    gt_prof_ifrs_lease_books  :=  fnd_profile.value( cv_prof_ifrs_lease_books );
    IF ( gt_prof_ifrs_lease_books IS NULL ) THEN
      --  �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00020          --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  cv_prof_ifrs_lease_books  --  �g�[�N���l1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
   --  �R���J�����g�̑ҋ@�Ԋu
    gn_prof_conc_interval     :=  TO_NUMBER( fnd_profile.value( cv_prof_conc_interval ) );
    IF ( gn_prof_conc_interval IS NULL ) THEN
      --  �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00020          --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  cv_prof_conc_interval     --  �g�[�N���l1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    --  �R���J�����g�̍ő�ҋ@����
    gn_prof_conc_max_wait     :=  TO_NUMBER( fnd_profile.value( cv_prof_conc_max_wait ) );
    IF ( gn_prof_conc_max_wait IS NULL ) THEN
      --  �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00020          --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00020_1        --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  cv_prof_conc_max_wait     --  �g�[�N���l1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  ��v���Ԏ擾
    -- ===============================
    BEGIN
      --  �擾�����N���̗���1��
      SELECT  ADD_MONTHS( TO_DATE( xlcp.period_name, cv_date_format ), 1 )   ifrs_period_date
      INTO    gd_ifrs_period_date
      FROM    xxcff_lease_closed_periods    xlcp
      WHERE   xlcp.set_of_books_id    =   gt_prof_ifrs_sob_id
      AND     xlcp.period_name IS NOT NULL
      ;
      --  ��v���Ԗ�
      gt_ifrs_period_name :=  TO_CHAR( gd_ifrs_period_date, cv_date_format );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  ��v���Ԃ��擾�ł��Ȃ������ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00194          --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00194_1        --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  gt_prof_ifrs_sob_id       --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    --  �V�X�e���p���O�o�́i�p�����[�^�Ɖ�v���ԁj
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                    , iv_name           =>  cv_msg_cff_50210          --  ���b�Z�[�W�R�[�h
                  )                 ||  cv_msg_part ||
                  iv_object_code    ||  cv_msg_comm ||
                  iv_new_frequency  ||  cv_msg_comm ||
                  iv_new_charge     ||  cv_msg_comm ||
                  iv_new_tax_charge ||  cv_msg_comm ||
                  iv_new_tax_code   ||  cv_msg_comm ||
                  TO_CHAR( gd_ifrs_period_date, cv_date_format_ymd )
                  ;
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
    --  ��s�}��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  ''
    );
    --
  EXCEPTION
    -- *** PROCEDURE���G���[ ***
    WHEN global_process_expt THEN
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
   * Procedure Name   : get_target_data
   * Description      : �Ώۃf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
      or_target_data    OUT g_target_rtype  --  �Ώۃf�[�^
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
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
    lt_ret_dff4                     fnd_lookup_values.attribute4%TYPE;                --  DFF4(���{��A�g)
    lt_ret_dff5                     fnd_lookup_values.attribute5%TYPE;                --  DFF5(IFRS�A�g)
    lt_ret_dff6                     fnd_lookup_values.attribute6%TYPE;                --  DFF6(�d��쐬)
    lt_ret_dff7                     fnd_lookup_values.attribute7%TYPE;                --  DFF7(���[�X���菈��)
    lt_check_payment_frequency      xxcff_contract_headers.payment_frequency%TYPE;    --  �ύX�O�x����
    lt_check_lease_charge           xxcff_pay_planning.lease_charge%TYPE;             --  �ύX�O���[�X��
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
    -- ===============================
    --  �������擾
    -- ===============================
    BEGIN
      SELECT  xoh.object_header_id    object_header_id    --  ����ID
            , xoh.lease_class         lease_class         --  ���[�X���
            , xoh.owner_company       owner_company       --  �{�Ё^�H��
      INTO    or_target_data.object_header_id
            , or_target_data.lease_class
            , or_target_data.owner_company
      FROM    xxcff_object_headers    xoh                 --  ���[�X����
      WHERE   xoh.object_code   =   gt_param_object_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  ������񂪎擾�ł��Ȃ��ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00123          --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00123_1        --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  gt_param_object_code      --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  ���[�X���菈���m�F
    -- ===============================
    xxcff_common2_pkg.get_lease_class_info(
        iv_lease_class  =>  or_target_data.lease_class
      , ov_ret_dff4     =>  lt_ret_dff4           --  DFF4(���{��A�g)
      , ov_ret_dff5     =>  lt_ret_dff5           --  DFF5(IFRS�A�g)
      , ov_ret_dff6     =>  lt_ret_dff6           --  DFF6(�d��쐬)
      , ov_ret_dff7     =>  lt_ret_dff7           --  DFF7(���[�X���菈��)
      , ov_errbuf       =>  lv_errbuf
      , ov_retcode      =>  lv_retcode
      , ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  ���ʊ֐�������I�����Ȃ������ꍇ
      lv_errmsg :=  SUBSTRB(
                      xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00094        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00094_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50323        --  �g�[�N���l1
                      )
                      || cv_msg_part || lv_errmsg                       --  ���ʊ֐�����߂��ꂽ���b�Z�[�W
                      , 1, 5000
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    IF ( NVL( lt_ret_dff7, cv_dummy_code ) <> cv_lease_class_2 ) THEN
      --  ���[�X���菈����2�ȊO�̏ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff            --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00292          --  ���b�Z�[�W�R�[�h
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  �x���v��擾
    -- ===============================
    BEGIN
      SELECT  xch.contract_header_id                    contract_header_id        --  �_�����ID
            , xcl.contract_line_id                      contract_line_id          --  �_�񖾍ד���ID
            , xpp.payment_frequency                     payment_frequency         --  ����x����
            , xcl.asset_category                        asset_category            --  ���Y���
            , xch.contract_number                       contract_number           --  �_��ԍ�
            , xch.lease_company                         lease_company             --  ���[�X���
            , xch.second_payment_date                   second_payment_date       --  2��ڎx����
            , xch.third_payment_date                    third_payment_date        --  3��ڈȍ~�x����
            , xpp.lease_tax_charge                      lease_tax_charge          --  ���[�X��_�����
            , xpp.lease_deduction                       lease_deduction           --  ���[�X�T���z
            , xpp.lease_tax_deduction                   lease_tax_deduction       --  ���[�X�T���z_�����
            , xpp.fin_debt_rem                          fin_debt_rem              --  �e�h�m���[�X���c
            , xpp.fin_debt                              fin_debt                  --  �e�h�m���[�X���z
            , xpp.fin_tax_debt                          fin_tax_debt              --  �e�h�m���[�X���z_�����
            , xcl.tax_code                              tax_code                  --  �ŃR�[�h
            , xch.payment_frequency                     check_payment_frequency   --  �ύX�O�x����
            , xpp.lease_charge                          check_lease_charge        --  �ύX�O���[�X��
      INTO    or_target_data.contract_header_id
            , or_target_data.contract_line_id
            , or_target_data.payment_frequency
            , or_target_data.asset_category
            , or_target_data.contract_number
            , or_target_data.lease_company
            , or_target_data.second_payment_date
            , or_target_data.third_payment_date
            , or_target_data.lease_tax_charge
            , or_target_data.lease_deduction
            , or_target_data.lease_tax_deduction
            , or_target_data.fin_debt_rem
            , or_target_data.fin_debt
            , or_target_data.fin_tax_debt
            , or_target_data.tax_code
            , lt_check_payment_frequency
            , lt_check_lease_charge
      FROM    xxcff_contract_headers      xch                   --  ���[�X�_��
            , xxcff_contract_lines        xcl                   --  ���[�X�_�񖾍�
            , xxcff_pay_planning          xpp                   --  �x���v��
      WHERE   xcl.contract_header_id      =   xch.contract_header_id
      AND     xcl.contract_line_id        =   xpp.contract_line_id
      AND     xcl.object_header_id        =   or_target_data.object_header_id
      AND     xpp.period_name             =   gt_ifrs_period_name
      AND     xpp.payment_frequency       <>  1                 --  �x����1��ڂ͏���
      ;
      --  �ύX�O�̏���ō��v���擾
      SELECT  SUM( xpp.lease_tax_charge )               lease_tax_charge          --  ���[�X��_�����
      INTO    or_target_data.sum_old_tax_charge
      FROM    xxcff_pay_planning          xpp                   --  �x���v��
      WHERE   xpp.contract_line_id    =   or_target_data.contract_line_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00165        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00165_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50088        --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  �x���񐔃`�F�b�N
    -- ===============================
    IF ( gt_param_new_frequency < or_target_data.payment_frequency ) THEN
      --  �ύX��x���񐔂��A����x���񐔂�菬�����ꍇ
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff                                    --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00293                                  --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00293_1                                --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  TO_CHAR( or_target_data.payment_frequency - 1 )   --  �g�[�N���l1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    ELSE
      --  �c��x���񐔁F�ύX��x���� - ����x���� + 1
      or_target_data.remaining_frequency  :=  gt_param_new_frequency - or_target_data.payment_frequency + 1;
    END IF;
    --
    -- ===============================
    --  �ύX���e�`�F�b�N
    -- ===============================
    IF ( gt_param_new_frequency = lt_check_payment_frequency AND gt_param_new_charge = lt_check_lease_charge ) THEN
      --  �x���񐔂ƁA2��ڈȍ~�̃��[�X�����Ƃ��Ɍ��s�x���v��Ƒ���Ȃ��ꍇ�͏����𒆒f
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00294        --  ���b�Z�[�W�R�[�h
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  ���Y�J�e�S���擾
    -- ===============================
    xxcff_common1_pkg.chk_fa_category(
        iv_segment1       =>  or_target_data.asset_category       --  ���Y���
      , iv_segment2       =>  NULL                                --  �\�����p
      , iv_segment3       =>  NULL                                --  ���Y����
      , iv_segment4       =>  NULL                                --  ���p�Ȗ�
      , iv_segment5       =>  CEIL( gt_param_new_frequency / 12 ) --  �ϗp�N��
      , iv_segment6       =>  NULL                                --  ���p���@
      , iv_segment7       =>  or_target_data.lease_class          --  ���[�X���
      , on_category_id    =>  or_target_data.asset_category_id    --  ���Y�J�e�S��CCID
      , ov_errbuf         =>  lv_errbuf                           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode                          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg                           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  ���ʊ֐�������I�����Ȃ������ꍇ
      lv_errmsg :=  SUBSTRB(
                      xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00094        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00094_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50303        --  �g�[�N���l1
                      )
                      || cv_msg_part || lv_errmsg                       --  ���ʊ֐�����߂��ꂽ���b�Z�[�W
                      , 1, 5000
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    BEGIN
      SELECT  fcbd.deprn_method   deprn_method      --  ���p���@
            , fca.segment1 || cv_separator ||
              fca.segment2 || cv_separator ||
              fca.segment3 || cv_separator ||
              fca.segment4 || cv_separator ||
              fca.segment5 || cv_separator ||
              fca.segment6 || cv_separator ||
              fca.segment7        category_code     --  ���Y�J�e�S���R�[�h
      INTO    or_target_data.deprn_method
            , or_target_data.asset_category_code
      FROM    fa_category_book_defaults   fcbd      --  ���Y�J�e�S�����p�
            , fa_categories               fca       --  ���Y�J�e�S��
      WHERE   fcbd.category_id      =   fca.category_id
      AND     fcbd.category_id      =   or_target_data.asset_category_id
      AND     fcbd.book_type_code   =   gt_prof_ifrs_lease_books
      AND     gd_ifrs_period_date BETWEEN fcbd.start_dpis
                                  AND     NVL( fcbd.end_dpis ,gd_ifrs_period_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  ���Y�J�e�S�����擾�ł��Ȃ������ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff                                --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00268                              --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00268_1                            --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  TO_CHAR( or_target_data.asset_category_id )   --  �g�[�N���l1
                        , iv_token_name2    =>  cv_tok_cff_00268_2                            --  �g�[�N���R�[�h2
                        , iv_token_value2   =>  gt_prof_ifrs_lease_books                      --  �g�[�N���l2
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
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
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : �e����CSV�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
      ir_target_data    IN  g_target_rtype  --  �Ώۃf�[�^
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    ln_request_id             NUMBER;           --  �v��ID
    lb_wait_result            BOOLEAN;          --  �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);     --  Phase
    lv_status                 VARCHAR2(50);     --  Status
    lv_dev_phase              VARCHAR2(50);     --  Dev_phase
    lv_dev_status             VARCHAR2(50);     --  Dev_status
    lv_message                VARCHAR2(5000);   --  Message
    lv_token_value            VARCHAR2(30);     --  ���b�Z�[�W�p�g�[�N���ێ��ϐ�
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
    -- ============================================
    --  �R���J�����g�N���F���[�X�_��f�[�^CSV�o��
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_contract_csv             --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.�_��ԍ�
                        , argument2       =>  ir_target_data.lease_company    --   2.���[�X���
                        , argument3       =>  NULL                            --   3.�����R�[�h1
                        , argument4       =>  NULL                            --   4.�����R�[�h2
                        , argument5       =>  NULL                            --   5.�����R�[�h3
                        , argument6       =>  NULL                            --   6.�����R�[�h4
                        , argument7       =>  NULL                            --   7.�����R�[�h5
                        , argument8       =>  NULL                            --   8.�����R�[�h6
                        , argument9       =>  NULL                            --   9.�����R�[�h7
                        , argument10      =>  NULL                            --  10.�����R�[�h8
                        , argument11      =>  NULL                            --  11.�����R�[�h9
                        , argument12      =>  NULL                            --  12.�����R�[�h10
                      );
    --
    --  �N�����s
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50203;
      RAISE conc_error_expt;
    END IF;
    --
    --  �R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    --
    --  �R���J�����g�̏I���ҋ@
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- �R���J�����g�ҋ@���s
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- �R���J�����g�ُ�I��
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  �R���J�����g�N���F���[�X�����f�[�^CSV�o��
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_object_csv               --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.�_��ԍ�
                        , argument2       =>  ir_target_data.lease_company    --   2.���[�X���
                        , argument3       =>  NULL                            --   3.�����R�[�h1
                        , argument4       =>  NULL                            --   4.�����R�[�h2
                        , argument5       =>  NULL                            --   5.�����R�[�h3
                        , argument6       =>  NULL                            --   6.�����R�[�h4
                        , argument7       =>  NULL                            --   7.�����R�[�h5
                        , argument8       =>  NULL                            --   8.�����R�[�h6
                        , argument9       =>  NULL                            --   9.�����R�[�h7
                        , argument10      =>  NULL                            --  10.�����R�[�h8
                        , argument11      =>  NULL                            --  11.�����R�[�h9
                        , argument12      =>  NULL                            --  12.�����R�[�h10
                      );
    --
    --  �N�����s
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50204;
      RAISE conc_error_expt;
    END IF;
    --
    --  �R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    --
    --  �R���J�����g�̏I���ҋ@
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- �R���J�����g�ҋ@���s
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- �R���J�����g�ُ�I��
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  �R���J�����g�N���G���[�X�x���v��f�[�^CSV�o��
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_pay_planning_csv         --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.�_��ԍ�
                        , argument2       =>  ir_target_data.lease_company    --   2.���[�X���
                        , argument3       =>  NULL                            --   3.�����R�[�h1
                        , argument4       =>  NULL                            --   4.�����R�[�h2
                        , argument5       =>  NULL                            --   5.�����R�[�h3
                        , argument6       =>  NULL                            --   6.�����R�[�h4
                        , argument7       =>  NULL                            --   7.�����R�[�h5
                        , argument8       =>  NULL                            --   8.�����R�[�h6
                        , argument9       =>  NULL                            --   9.�����R�[�h7
                        , argument10      =>  NULL                            --  10.�����R�[�h8
                        , argument11      =>  NULL                            --  11.�����R�[�h9
                        , argument12      =>  NULL                            --  12.�����R�[�h10
                      );
    --
    --  �N�����s
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50205;
      RAISE conc_error_expt;
    END IF;
    --
    --  �R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    --
    --  �R���J�����g�̏I���ҋ@
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- �R���J�����g�ҋ@���s
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- �R���J�����g�ُ�I��
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- ============================================
    --  �R���J�����g�N���F���[�X��v����CSV�o��
    -- ============================================
    ln_request_id :=  fnd_request.submit_request(
                          application     =>  cv_app_kbn_ccp                  --  Application
                        , program         =>  cv_prg_accounting_csv           --  Program
                        , description     =>  NULL                            --  Description
                        , start_time      =>  NULL                            --  Start_time
                        , sub_request     =>  FALSE                           --  Sub_request
                        , argument1       =>  ir_target_data.contract_number  --   1.�_��ԍ�
                        , argument2       =>  ir_target_data.lease_company    --   2.���[�X���
                        , argument3       =>  NULL                            --   3.�����R�[�h1
                        , argument4       =>  NULL                            --   4.�����R�[�h2
                        , argument5       =>  NULL                            --   5.�����R�[�h3
                        , argument6       =>  NULL                            --   6.�����R�[�h4
                        , argument7       =>  NULL                            --   7.�����R�[�h5
                        , argument8       =>  NULL                            --   8.�����R�[�h6
                        , argument9       =>  NULL                            --   9.�����R�[�h7
                        , argument10      =>  NULL                            --  10.�����R�[�h8
                        , argument11      =>  NULL                            --  11.�����R�[�h9
                        , argument12      =>  NULL                            --  12.�����R�[�h10
                      );
    --
    --  �N�����s
    IF ( ln_request_id = 0 ) THEN
      lv_token_value  :=  cv_msg_cff_50206;
      RAISE conc_error_expt;
    END IF;
    --
    --  �R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
    --
    --  �R���J�����g�̏I���ҋ@
    lb_wait_result  :=  fnd_concurrent.wait_for_request(
                            request_id    =>  ln_request_id             --  Request_id
                          , interval      =>  gn_prof_conc_interval     --  Interval
                          , max_wait      =>  gn_prof_conc_max_wait     --  Max_wait
                          , phase         =>  lv_phase                  --  Phase
                          , status        =>  lv_status                 --  Status
                          , dev_phase     =>  lv_dev_phase              --  Dev_phase
                          , dev_status    =>  lv_dev_status             --  Dev_status
                          , message       =>  lv_message                --  Message
                        );
    --
    -- �R���J�����g�ҋ@���s
    IF ( lb_wait_result = FALSE ) THEN
      RAISE conc_error_expt;
    END IF;
    --
    -- �R���J�����g�ُ�I��
    IF ( lv_dev_status = cv_dev_status_error ) THEN
      RAISE conc_error_expt;
    END IF;
    --
  EXCEPTION
    -- *** �R���J�����g�N����O�n���h�� ***
    WHEN conc_error_expt THEN
      IF ( ln_request_id = 0 ) THEN
        --  �R���J�����g�̋N���Ɏ��s�����ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00197            --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00197_1          --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  lv_token_value              --  �g�[�N���l1
                      );
      ELSIF ( lb_wait_result = FALSE ) THEN
        --  �R���J�����g�̑ҋ@�Ɏ��s�����ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00198            --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00198_1          --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  TO_CHAR( ln_request_id )    --  �g�[�N���l1
                      );
      ELSIF ( lv_dev_status = cv_dev_status_error ) THEN
        --  �R���J�����g�̌��ʂ��G���[�̏ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00199            --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00199_1          --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  TO_CHAR( ln_request_id )    --  �g�[�N���l1
                      );
      END IF;
      --
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  :=  cv_status_error;
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : create_pay_planning
   * Description      : �V�x���v��f�[�^�쐬(A-4)
   ***********************************************************************************/
  PROCEDURE create_pay_planning(
      ior_target_data   IN OUT  g_target_rtype        --  �Ώۃf�[�^
    , ot_new_pay_plan   OUT     g_new_pay_plan_ttype  --  �V�x���v��
    , ov_errbuf         OUT     VARCHAR2              --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT     VARCHAR2              --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT     VARCHAR2              --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_pay_planning'; -- �v���O������
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
    --  ������
    ot_new_pay_plan.DELETE;
    --
    -- ===============================
    --  �������擾
    -- ===============================
    BEGIN
      --  �c��x���񐔂Ɋ�Â�������
      SELECT  CASE  CEIL( ior_target_data.remaining_frequency / 12 )
                WHEN  1   THEN  xdrm.discount_rate_01
                WHEN  2   THEN  xdrm.discount_rate_02
                WHEN  3   THEN  xdrm.discount_rate_03
                WHEN  4   THEN  xdrm.discount_rate_04
                WHEN  5   THEN  xdrm.discount_rate_05
                WHEN  6   THEN  xdrm.discount_rate_06
                WHEN  7   THEN  xdrm.discount_rate_07
                WHEN  8   THEN  xdrm.discount_rate_08
                WHEN  9   THEN  xdrm.discount_rate_09
                WHEN  10  THEN  xdrm.discount_rate_10
                WHEN  11  THEN  xdrm.discount_rate_11
                WHEN  12  THEN  xdrm.discount_rate_12
                WHEN  13  THEN  xdrm.discount_rate_13
                WHEN  14  THEN  xdrm.discount_rate_14
                WHEN  15  THEN  xdrm.discount_rate_15
                WHEN  16  THEN  xdrm.discount_rate_16
                WHEN  17  THEN  xdrm.discount_rate_17
                WHEN  18  THEN  xdrm.discount_rate_18
                WHEN  19  THEN  xdrm.discount_rate_19
                WHEN  20  THEN  xdrm.discount_rate_20
                WHEN  21  THEN  xdrm.discount_rate_21
                WHEN  22  THEN  xdrm.discount_rate_22
                WHEN  23  THEN  xdrm.discount_rate_23
                WHEN  24  THEN  xdrm.discount_rate_24
                WHEN  25  THEN  xdrm.discount_rate_25
                WHEN  26  THEN  xdrm.discount_rate_26
                WHEN  27  THEN  xdrm.discount_rate_27
                WHEN  28  THEN  xdrm.discount_rate_28
                WHEN  29  THEN  xdrm.discount_rate_29
                WHEN  30  THEN  xdrm.discount_rate_30
                WHEN  31  THEN  xdrm.discount_rate_31
                WHEN  32  THEN  xdrm.discount_rate_32
                WHEN  33  THEN  xdrm.discount_rate_33
                WHEN  34  THEN  xdrm.discount_rate_34
                WHEN  35  THEN  xdrm.discount_rate_35
                WHEN  36  THEN  xdrm.discount_rate_36
                WHEN  37  THEN  xdrm.discount_rate_37
                WHEN  38  THEN  xdrm.discount_rate_38
                WHEN  39  THEN  xdrm.discount_rate_39
                WHEN  40  THEN  xdrm.discount_rate_40
                WHEN  41  THEN  xdrm.discount_rate_41
                WHEN  42  THEN  xdrm.discount_rate_42
                WHEN  43  THEN  xdrm.discount_rate_43
                WHEN  44  THEN  xdrm.discount_rate_44
                WHEN  45  THEN  xdrm.discount_rate_45
                WHEN  46  THEN  xdrm.discount_rate_46
                WHEN  47  THEN  xdrm.discount_rate_47
                WHEN  48  THEN  xdrm.discount_rate_48
                WHEN  49  THEN  xdrm.discount_rate_49
                WHEN  50  THEN  xdrm.discount_rate_50
              END           discount_rate
      INTO    ior_target_data.discount_rate
      FROM    xxcff_discount_rate_mst   xdrm
      WHERE   xdrm.application_date   =   gd_ifrs_period_date
      ;
      IF ( ior_target_data.discount_rate IS NULL ) THEN
        RAISE NO_DATA_FOUND;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff                                --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00089                              --  ���b�Z�[�W�R�[�h
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  ���݉��l�Z�o
    -- ===============================
    ior_target_data.present_value :=  0;
    <<calc_loop>>
    FOR ln_count IN 1 .. ior_target_data.remaining_frequency LOOP
      ior_target_data.present_value :=  ior_target_data.present_value + ( gt_param_new_charge - ior_target_data.lease_deduction ) / POWER( 1 + ( ior_target_data.discount_rate / 100 / 12 ), ln_count );
    END LOOP  calc_loop;
    --  ���ʂ��l�̌ܓ�
    ior_target_data.present_value :=  ROUND( ior_target_data.present_value, 0 );
    --
    -- ===============================
    --  �V�x���v����쐬
    -- ===============================
    <<pay_plan_loop>>     --  �c��x���񐔕����[�v
    FOR ln_count IN 1 .. ior_target_data.remaining_frequency LOOP
      --  1.�_�񖾍ד���ID
      ot_new_pay_plan( ln_count ).contract_line_id        :=  ior_target_data.contract_line_id;
      --
      --  2.�x���񐔁F����x���񐔂���A�c��񐔕�1������
      ot_new_pay_plan( ln_count ).payment_frequency       :=  ior_target_data.payment_frequency + ln_count - 1;
      --
      --  3.�_�����ID
      ot_new_pay_plan( ln_count ).contract_header_id      :=  ior_target_data.contract_header_id;
      --
      --  4.��v���ԁFA-1�Ŏ擾������v���Ԗ�����A�c��񐔕�1��������
      ot_new_pay_plan( ln_count ).period_name             :=  TO_CHAR( ADD_MONTHS( TO_DATE( gt_ifrs_period_name, cv_date_format ), ln_count - 1 ), cv_date_format );
      --
      --  5.�x����
      IF ( ior_target_data.third_payment_date = 31 ) THEN
        --  3��ڈȍ~�x������31�ɂ̏ꍇ�A2��ڎx�����Ɍ����Z���A�e���̍ŏI��
        ot_new_pay_plan( ln_count ).payment_date        :=  LAST_DAY( ADD_MONTHS( ior_target_data.second_payment_date, ior_target_data.payment_frequency + ln_count - 3 ) );
      ELSE
        --  31���ȊO�̏ꍇ�́A2��ڎx�����Ɍ����Z
        ot_new_pay_plan( ln_count ).payment_date        :=  ADD_MONTHS( ior_target_data.second_payment_date, ior_target_data.payment_frequency + ln_count - 3 );
      END IF;
      --
      --  6.���[�X���F�p�����[�^�D�ύX�ナ�[�X��
      ot_new_pay_plan( ln_count ).lease_charge            :=  gt_param_new_charge;
      --
      --  7.���[�X��_����ŁF�p�����[�^�D�ύX��Ŋz
      ot_new_pay_plan( ln_count ).lease_tax_charge        :=  gt_param_new_tax_charge;
      --
      --  8.���[�X�T���z�F�x����2��ڈȍ~�͑S�����l
      ot_new_pay_plan( ln_count ).lease_deduction         :=  ior_target_data.lease_deduction;
      --
      --  9.���[�X�T���z_����ŁF�x����2��ڈȍ~�͑S�����l
      ot_new_pay_plan( ln_count ).lease_tax_deduction     :=  ior_target_data.lease_tax_deduction;
      --
      --  10.�n�o���[�X���F6.���[�X�� - 8.���[�X�T���z
      ot_new_pay_plan( ln_count ).op_charge               :=  ot_new_pay_plan( ln_count ).lease_charge - ot_new_pay_plan( ln_count ).lease_deduction;
      --
      --  11.�n�o���[�X���z_����ŁF7.���[�X��_����� - 9.���[�X�T���z_�����
      ot_new_pay_plan( ln_count ).op_tax_charge           :=  ot_new_pay_plan( ln_count ).lease_tax_charge - ot_new_pay_plan( ln_count ).lease_tax_deduction;
      --
      --  14.�e�h�m���[�X�x������
      IF ( ln_count = 1 ) THEN
        --  ��L�ŎZ�o�������݉��l * ��L�Ŏ擾����������
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ROUND( ior_target_data.present_value * ROUND( ( ior_target_data.discount_rate / 100 / 12 ), 7 ), 0 );
      ELSE
        --  1��O�� 15.FIN���[�X���c * ������
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ROUND( ot_new_pay_plan( ln_count - 1 ).fin_debt_rem * ROUND( ( ior_target_data.discount_rate / 100 / 12 ), 7 ), 0 );
      END IF;
      --
      --  12.�e�h�m���[�X���z�F6.���[�X�� - 8.���[�X�T���z - 14.�e�h�m���[�X�x������
      ot_new_pay_plan( ln_count ).fin_debt                :=  ot_new_pay_plan( ln_count ).lease_charge - ot_new_pay_plan( ln_count ).lease_deduction - ot_new_pay_plan( ln_count ).fin_interest_due;
      --
      --  13.�e�h�m���[�X���z_����ŁF7.���[�X��_����� - 9.���[�X�T���z_�����
      ot_new_pay_plan( ln_count ).fin_tax_debt            :=  ot_new_pay_plan( ln_count ).lease_tax_charge - ot_new_pay_plan( ln_count ).lease_tax_deduction;
      --
      --  15.�e�h�m���[�X���c
      IF ( ln_count = 1 ) THEN
        --  ��L�ŎZ�o�������݉��l - 12.�e�h�m���[�X���z
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  ior_target_data.present_value - ot_new_pay_plan( ln_count ).fin_debt;
      ELSE
        --  1��O�� 15.�e�h�m���[�X���c - 12.�e�h�m���[�X���z
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  ot_new_pay_plan( ln_count - 1 ).fin_debt_rem - ot_new_pay_plan( ln_count ).fin_debt;
      END IF;
      IF ( ot_new_pay_plan( ln_count ).fin_debt_rem < 0 ) THEN
        --  �}�C�i�X�l�ƂȂ����ꍇ��0�ɒu��
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  0;
      END IF;
      IF ( ln_count = ior_target_data.remaining_frequency AND ot_new_pay_plan( ln_count ).fin_debt_rem <> 0 ) THEN
        --  �ŏI�����ŁA15.�e�h�m���[�X����0�ɂȂ��Ă��Ȃ��ꍇ
        --  12.�e�h�m���[�X���z �� 15.�e�h�m���[�X���c�����Z
        ot_new_pay_plan( ln_count ).fin_debt              :=  ot_new_pay_plan( ln_count ).fin_debt + ot_new_pay_plan( ln_count ).fin_debt_rem;
        --  14.�e�h�m���[�X�x������ ���� 15.�e�h�m���[�X���c�����Z
        ot_new_pay_plan( ln_count ).fin_interest_due      :=  ot_new_pay_plan( ln_count ).fin_interest_due - ot_new_pay_plan( ln_count ).fin_debt_rem;
        --  15.�e�h�m���[�X���c��0�ɒu��
        ot_new_pay_plan( ln_count ).fin_debt_rem          :=  0;
      END IF;
      --
      --  16.�e�h�m���[�X���c_�����
      IF ( ln_count = 1 ) THEN
        --  13.�e�h�m���[�X���z_����� * ( �c��x���� - 1 )
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  ot_new_pay_plan( ln_count ).fin_tax_debt * ( ior_target_data.remaining_frequency - 1 );
      ELSE
        --  1��O��FIN���[�X���c_����� - 13.�e�h�m���[�X���z_�����
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  ot_new_pay_plan( ln_count - 1 ).fin_tax_debt_rem - ot_new_pay_plan( ln_count ).fin_tax_debt;
      END IF;
      IF ( ot_new_pay_plan( ln_count ).fin_tax_debt_rem < 0 ) THEN
        --  �}�C�i�X�l�ƂȂ����ꍇ��0�ɒu��
        ot_new_pay_plan( ln_count ).fin_tax_debt_rem      :=  0;
      END IF;
      --
      --  17.��vIF�t���O�F�Œ�l1
      ot_new_pay_plan( ln_count ).accounting_if_flag      :=  cv_flag_1;
      --
      --  18.�ƍ��σt���O�F�Œ�l1
      ot_new_pay_plan( ln_count ).payment_match_flag      :=  cv_flag_1;
      --
      --  19.�쐬��
      ot_new_pay_plan( ln_count ).created_by              :=  cn_created_by;
      --
      --  20.�쐬��
      ot_new_pay_plan( ln_count ).creation_date           :=  cd_creation_date;
      --
      --  21.�ŏI�X�V��
      ot_new_pay_plan( ln_count ).last_updated_by         :=  cn_last_updated_by;
      --
      --  22.�ŏI�X�V��
      ot_new_pay_plan( ln_count ).last_update_date        :=  cd_last_update_date;
      --
      --  23.�ŏI�X�V���O�C��
      ot_new_pay_plan( ln_count ).last_update_login       :=  cn_last_update_login;
      --
      --  24.�v��ID
      ot_new_pay_plan( ln_count ).request_id              :=  cn_request_id;
      --
      --  25.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ot_new_pay_plan( ln_count ).program_application_id  :=  cn_program_application_id;
      --
      --  26.�R���J�����g�E�v���O����ID
      ot_new_pay_plan( ln_count ).program_id              :=  cn_program_id;
      --
      --  27.�v���O�����X�V��
      ot_new_pay_plan( ln_count ).program_update_date     :=  cd_program_update_date;
      --
      --  28.���[�X���z_�ă��[�X
      ot_new_pay_plan( ln_count ).debt_re                 :=  NULL;
      --
      --  29.���[�X�x������_�ă��[�X
      ot_new_pay_plan( ln_count ).interest_due_re         :=  NULL;
      --
      --  30.���[�X���c_�ă��[�X
      ot_new_pay_plan( ln_count ).debt_rem_re             :=  NULL;
    END LOOP  pay_plan_loop;
    --
  EXCEPTION
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
  END create_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : ins_backup
   * Description      : �f�[�^�o�b�N�A�b�v(A-5)
   ***********************************************************************************/
  PROCEDURE ins_backup(
      ir_target_data    IN  g_target_rtype  --  �Ώۃf�[�^
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_backup'; -- �v���O������
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
    ln_run_line_num       NUMBER;           --  ���s�}��
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
    -- ===============================
    --  ���s�}�Ԏ擾
    -- ===============================
    SELECT  NVL( MAX( xchb.run_line_num ), 0 ) + 1    run_line_num      --  ���s�}��(�ő���s�}��+1)
    INTO    ln_run_line_num
    FROM    xxcff_contract_lines_bk       xchb
    WHERE   xchb.run_period_name      =   gt_ifrs_period_name
    AND     xchb.contract_header_id   =   ir_target_data.contract_header_id
    ;
    --
    INSERT INTO xxcff_contract_headers_bk(
        contract_header_id                --   1.�_�����ID
      , contract_number                   --   2.�_��ԍ�
      , lease_class                       --   3.���[�X���
      , lease_type                        --   4.���[�X�敪
      , lease_company                     --   5.���[�X���
      , re_lease_times                    --   6.�ă��[�X��
      , comments                          --   7.����
      , contract_date                     --   8.���[�X�_���
      , payment_frequency                 --   9.�x����
      , payment_type                      --  10.�p�x
      , payment_years                     --  11.�N��
      , lease_start_date                  --  12.���[�X�J�n��
      , lease_end_date                    --  13.���[�X�I����
      , first_payment_date                --  14.����x����
      , second_payment_date               --  15.��ڎx����
      , third_payment_date                --  16.��ڈȍ~�x����
      , start_period_name                 --  17.��p�v��J�n��v����
      , lease_payment_flag                --  18.���[�X�x���v�抮���t���O
      , tax_code                          --  19.�ŋ��R�[�h
      , run_period_name                   --  20.���s��v����
      , run_line_num                      --  21.���s�}��
      , created_by                        --  22.�쐬��
      , creation_date                     --  23.�쐬��
      , last_updated_by                   --  24.�ŏI�X�V��
      , last_update_date                  --  25.�ŏI�X�V��
      , last_update_login                 --  26.�ŏI�X�V���O�C��
      , request_id                        --  27.�v��ID
      , program_application_id            --  28.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                        --  29.�R���J�����g�E�v���O����ID
      , program_update_date               --  30.�v���O�����X�V��
    )
    SELECT
        xch.contract_header_id            --   1.�_�����ID
      , xch.contract_number               --   2.�_��ԍ�
      , xch.lease_class                   --   3.���[�X���
      , xch.lease_type                    --   4.���[�X�敪
      , xch.lease_company                 --   5.���[�X���
      , xch.re_lease_times                --   6.�ă��[�X��
      , xch.comments                      --   7.����
      , xch.contract_date                 --   8.���[�X�_���
      , xch.payment_frequency             --   9.�x����
      , xch.payment_type                  --  10.�p�x
      , xch.payment_years                 --  11.�N��
      , xch.lease_start_date              --  12.���[�X�J�n��
      , xch.lease_end_date                --  13.���[�X�I����
      , xch.first_payment_date            --  14.����x����
      , xch.second_payment_date           --  15.��ڎx����
      , xch.third_payment_date            --  16.��ڈȍ~�x����
      , xch.start_period_name             --  17.��p�v��J�n��v����
      , xch.lease_payment_flag            --  18.���[�X�x���v�抮���t���O
      , xch.tax_code                      --  19.�ŋ��R�[�h
      , gt_ifrs_period_name               --  20.���s��v����
      , ln_run_line_num                   --  21.���s�}��
      , cn_created_by                     --  22.�쐬��
      , cd_creation_date                  --  23.�쐬��
      , cn_last_updated_by                --  24.�ŏI�X�V��
      , cd_last_update_date               --  25.�ŏI�X�V��
      , cn_last_update_login              --  26.�ŏI�X�V���O�C��
      , cn_request_id                     --  27.�v��ID
      , cn_program_application_id         --  28.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                     --  29.�R���J�����g�E�v���O����ID
      , cd_program_update_date            --  30.�v���O�����X�V��
    FROM    xxcff_contract_headers    xch
    WHERE   xch.contract_header_id    =   ir_target_data.contract_header_id
    ;
    --
    INSERT INTO xxcff_contract_lines_bk(
        contract_line_id                  --   1.�_�񖾍ד���ID
      , contract_header_id                --   2.�_�����ID
      , contract_line_num                 --   3.�_��}��
      , contract_status                   --   4.�_��X�e�[�^�X
      , first_charge                      --   5.���񌎊z���[�X��_���[�X��
      , first_tax_charge                  --   6.�������Ŋz_���[�X��
      , first_total_charge                --   7.����v_���[�X��
      , second_charge                     --   8.��ڈȍ~���z���[�X��_���[�X��
      , second_tax_charge                 --   9.��ڈȍ~����Ŋz_���[�X��
      , second_total_charge               --  10.��ڈȍ~�v_���[�X��
      , first_deduction                   --  11.���񌎊z���[�X��_�T���z
      , first_tax_deduction               --  12.���񌎊z����Ŋz_�T���z
      , first_total_deduction             --  13.����v_�T���z
      , second_deduction                  --  14.��ڈȍ~���z���[�X��_�T���z
      , second_tax_deduction              --  15.��ڈȍ~����Ŋz_�T���z
      , second_total_deduction            --  16.��ڈȍ~�v_�T���z
      , gross_charge                      --  17.���z���[�X��_���[�X��
      , gross_tax_charge                  --  18.���z�����_���[�X��
      , gross_total_charge                --  19.���z�v_���[�X��
      , gross_deduction                   --  20.���z���[�X��_�T���z
      , gross_tax_deduction               --  21.���z�����_�T���z
      , gross_total_deduction             --  22.���z�v_�T���z
      , lease_kind                        --  23.���[�X���
      , estimated_cash_price              --  24.���ό����w�����z
      , present_value_discount_rate       --  25.���݉��l������
      , present_value                     --  26.���݉��l
      , life_in_months                    --  27.�@��ϗp�N��
      , original_cost                     --  28.�擾���z
      , calc_interested_rate              --  29.�v�Z���q��
      , object_header_id                  --  30.��������ID
      , asset_category                    --  31.���Y���
      , expiration_date                   --  32.������
      , cancellation_date                 --  33.���r����
      , vd_if_date                        --  34.���[�X�_����A�g��
      , info_sys_if_date                  --  35.���[�X�Ǘ����A�g��
      , first_installation_address        --  36.����ݒu�ꏊ
      , first_installation_place          --  37.����ݒu��
      , run_period_name                   --  38.���s��v����
      , run_line_num                      --  39.���s�}��
      , created_by                        --  40.�쐬��
      , creation_date                     --  41.�쐬��
      , last_updated_by                   --  42.�ŏI�X�V��
      , last_update_date                  --  43.�ŏI�X�V��
      , last_update_login                 --  44.�ŏI�X�V���O�C��
      , request_id                        --  45.�v��ID
      , program_application_id            --  46.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                        --  47.�R���J�����g�E�v���O����ID
      , program_update_date               --  48.�v���O�����X�V��
      , tax_code                          --  49.�ŋ��R�[�h
      , original_cost_type1               --  50.���[�X���z_���_��
      , original_cost_type2               --  51.���[�X���z_�ă��[�X
    )
    SELECT
        xcl.contract_line_id              --   1.�_�񖾍ד���ID
      , xcl.contract_header_id            --   2.�_�����ID
      , xcl.contract_line_num             --   3.�_��}��
      , xcl.contract_status               --   4.�_��X�e�[�^�X
      , xcl.first_charge                  --   5.���񌎊z���[�X��_���[�X��
      , xcl.first_tax_charge              --   6.�������Ŋz_���[�X��
      , xcl.first_total_charge            --   7.����v_���[�X��
      , xcl.second_charge                 --   8.��ڈȍ~���z���[�X��_���[�X��
      , xcl.second_tax_charge             --   9.��ڈȍ~����Ŋz_���[�X��
      , xcl.second_total_charge           --  10.��ڈȍ~�v_���[�X��
      , xcl.first_deduction               --  11.���񌎊z���[�X��_�T���z
      , xcl.first_tax_deduction           --  12.���񌎊z����Ŋz_�T���z
      , xcl.first_total_deduction         --  13.����v_�T���z
      , xcl.second_deduction              --  14.��ڈȍ~���z���[�X��_�T���z
      , xcl.second_tax_deduction          --  15.��ڈȍ~����Ŋz_�T���z
      , xcl.second_total_deduction        --  16.��ڈȍ~�v_�T���z
      , xcl.gross_charge                  --  17.���z���[�X��_���[�X��
      , xcl.gross_tax_charge              --  18.���z�����_���[�X��
      , xcl.gross_total_charge            --  19.���z�v_���[�X��
      , xcl.gross_deduction               --  20.���z���[�X��_�T���z
      , xcl.gross_tax_deduction           --  21.���z�����_�T���z
      , xcl.gross_total_deduction         --  22.���z�v_�T���z
      , xcl.lease_kind                    --  23.���[�X���
      , xcl.estimated_cash_price          --  24.���ό����w�����z
      , xcl.present_value_discount_rate   --  25.���݉��l������
      , xcl.present_value                 --  26.���݉��l
      , xcl.life_in_months                --  27.�@��ϗp�N��
      , xcl.original_cost                 --  28.�擾���z
      , xcl.calc_interested_rate          --  29.�v�Z���q��
      , xcl.object_header_id              --  30.��������ID
      , xcl.asset_category                --  31.���Y���
      , xcl.expiration_date               --  32.������
      , xcl.cancellation_date             --  33.���r����
      , xcl.vd_if_date                    --  34.���[�X�_����A�g��
      , xcl.info_sys_if_date              --  35.���[�X�Ǘ����A�g��
      , xcl.first_installation_address    --  36.����ݒu�ꏊ
      , xcl.first_installation_place      --  37.����ݒu��
      , gt_ifrs_period_name               --  38.���s��v����
      , ln_run_line_num                   --  39.���s�}��
      , cn_created_by                     --  40.�쐬��
      , cd_creation_date                  --  41.�쐬��
      , cn_last_updated_by                --  42.�ŏI�X�V��
      , cd_last_update_date               --  43.�ŏI�X�V��
      , cn_last_update_login              --  44.�ŏI�X�V���O�C��
      , cn_request_id                     --  45.�v��ID
      , cn_program_application_id         --  46.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                     --  47.�R���J�����g�E�v���O����ID
      , cd_program_update_date            --  48.�v���O�����X�V��
      , xcl.tax_code                      --  49.�ŋ��R�[�h
      , xcl.original_cost_type1           --  50.���[�X���z_���_��
      , xcl.original_cost_type2           --  51.���[�X���z_�ă��[�X
    FROM    xxcff_contract_lines      xcl
    WHERE   xcl.contract_line_id    =   ir_target_data.contract_line_id
    ;
    --
    INSERT INTO xxcff_pay_planning_bk(
        contract_line_id                  --   1.�_�񖾍ד���ID
      , payment_frequency                 --   2.�x����
      , contract_header_id                --   3.�_�����ID
      , period_name                       --   4.��v����
      , payment_date                      --   5.�x����
      , lease_charge                      --   6.���[�X��
      , lease_tax_charge                  --   7.���[�X��_�����
      , lease_deduction                   --   8.���[�X�T���z
      , lease_tax_deduction               --   9.���[�X�T���z_�����
      , op_charge                         --  10.�n�o���[�X��
      , op_tax_charge                     --  11.�n�o���[�X���z_�����
      , fin_debt                          --  12.�e�h�m���[�X���z
      , fin_tax_debt                      --  13.�e�h�m���[�X���z_�����
      , fin_interest_due                  --  14.�e�h�m���[�X�x������
      , fin_debt_rem                      --  15.�e�h�m���[�X���c
      , fin_tax_debt_rem                  --  16.�e�h�m���[�X���c_�����
      , accounting_if_flag                --  17.��v�h�e�t���O
      , payment_match_flag                --  18.�ƍ��σt���O
      , run_period_name                   --  19.���s��v����
      , run_line_num                      --  20.���s�}��
      , created_by                        --  21.�쐬��
      , creation_date                     --  22.�쐬��
      , last_updated_by                   --  23.�ŏI�X�V��
      , last_update_date                  --  24.�ŏI�X�V��
      , last_update_login                 --  25.�ŏI�X�V���O�C��
      , request_id                        --  26.�v��ID
      , program_application_id            --  27.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                        --  28.�R���J�����g�E�v���O����ID
      , program_update_date               --  29.�v���O�����X�V��
      , debt_re                           --  30.���[�X���z_�ă��[�X
      , interest_due_re                   --  31.���[�X�x������_�ă��[�X
      , debt_rem_re                       --  32.���[�X���c_�ă��[�X
    )
    SELECT
        xpp.contract_line_id              --   1.�_�񖾍ד���ID
      , xpp.payment_frequency             --   2.�x����
      , xpp.contract_header_id            --   3.�_�����ID
      , xpp.period_name                   --   4.��v����
      , xpp.payment_date                  --   5.�x����
      , xpp.lease_charge                  --   6.���[�X��
      , xpp.lease_tax_charge              --   7.���[�X��_�����
      , xpp.lease_deduction               --   8.���[�X�T���z
      , xpp.lease_tax_deduction           --   9.���[�X�T���z_�����
      , xpp.op_charge                     --  10.�n�o���[�X��
      , xpp.op_tax_charge                 --  11.�n�o���[�X���z_�����
      , xpp.fin_debt                      --  12.�e�h�m���[�X���z
      , xpp.fin_tax_debt                  --  13.�e�h�m���[�X���z_�����
      , xpp.fin_interest_due              --  14.�e�h�m���[�X�x������
      , xpp.fin_debt_rem                  --  15.�e�h�m���[�X���c
      , xpp.fin_tax_debt_rem              --  16.�e�h�m���[�X���c_�����
      , xpp.accounting_if_flag            --  17.��v�h�e�t���O
      , xpp.payment_match_flag            --  18.�ƍ��σt���O
      , gt_ifrs_period_name               --  19.���s��v����
      , ln_run_line_num                   --  20.���s�}��
      , cn_created_by                     --  21.�쐬��
      , cd_creation_date                  --  22.�쐬��
      , cn_last_updated_by                --  23.�ŏI�X�V��
      , cd_last_update_date               --  24.�ŏI�X�V��
      , cn_last_update_login              --  25.�ŏI�X�V���O�C��
      , cn_request_id                     --  26.�v��ID
      , cn_program_application_id         --  27.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                     --  28.�R���J�����g�E�v���O����ID
      , cd_program_update_date            --  29.�v���O�����X�V��
      , xpp.debt_re                       --  30.���[�X���z_�ă��[�X
      , xpp.interest_due_re               --  31.���[�X�x������_�ă��[�X
      , xpp.debt_rem_re                   --  32.���[�X���c_�ă��[�X
    FROM    xxcff_pay_planning        xpp
    WHERE   xpp.contract_line_id      =   ir_target_data.contract_line_id
    ;
  EXCEPTION
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
  END ins_backup;
--
  /**********************************************************************************
   * Procedure Name   : replace_pay_planning
   * Description      : �V�x���v��o�^(A-6)
   ***********************************************************************************/
  PROCEDURE replace_pay_planning(
      ir_target_data    IN  g_target_rtype          --  �Ώۃf�[�^
    , it_new_pay_plan   IN  g_new_pay_plan_ttype    --  �V�x���v��
    , ov_errbuf         OUT VARCHAR2                --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2                --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2                --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_pay_planning'; -- �v���O������
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
    ln_dummy            NUMBER;             --  �_�~�[�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  xpp_lock_cur
    IS
      SELECT  xpp.contract_line_id
      FROM    xxcff_pay_planning  xpp
      WHERE   xpp.contract_line_id    =   ir_target_data.contract_line_id
      FOR UPDATE NOWAIT
      ;
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
    -- ===============================
    --  �Ώۃf�[�^���b�N
    -- ===============================
    BEGIN
      OPEN  xpp_lock_cur;
      CLOSE xpp_lock_cur;
    EXCEPTION
      WHEN lock_expt THEN
        --  ���b�N�̎擾�Ɏ��s�����ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00007        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50088        --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ============================================
    --  �x���v�� ���f�[�^�̍폜
    -- ============================================
    --  �Y���_�񖾍ד���ID�ŁA����x���񐔈ȍ~�̃f�[�^���폜
    DELETE  xxcff_pay_planning    xpp
    WHERE   xpp.contract_line_id    =   ir_target_data.contract_line_id
    AND     xpp.payment_frequency   >=  ir_target_data.payment_frequency
    ;
    --
    -- ============================================
    --  �V�x���v��o�^
    -- ============================================
    BEGIN
      --  A-4�Ő��������x���v���}��
      FORALL ins_cnt IN 1 .. it_new_pay_plan.COUNT
        INSERT INTO xxcff_pay_planning VALUES it_new_pay_plan(ins_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff              --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00102            --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00102_1          --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50088            --  �g�[�N���l1
                        , iv_token_name2    =>  cv_tok_cff_00102_2          --  �g�[�N���R�[�h2
                        , iv_token_value2   =>  SQLERRM                     --  �g�[�N���l2
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( xpp_lock_cur%ISOPEN ) THEN
        CLOSE xpp_lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END replace_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_data
   * Description      : �_����X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_contract_data(
      ior_target_data   IN OUT  g_target_rtype        --  �Ώۃf�[�^
    , ov_errbuf         OUT VARCHAR2                  --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2                  --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2                  --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_data'; -- �v���O������
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
    ln_dummy                        NUMBER;             --  �_�~�[�ϐ�
    ln_sum_lease_charge             NUMBER;             --  ���[�X���i���v�j
    ln_sum_lease_tax_charge         NUMBER;             --  ����Ŋz�i���v�j
    ln_sum_lease_deduction          NUMBER;             --  ���[�X��_�T���z�i���v�j
    ln_sum_lease_tax_deduction      NUMBER;             --  �����_�T���z�i���v�j
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
    -- ===============================
    --  �Ώۃf�[�^���b�N
    -- ===============================
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    xxcff_contract_headers    xch
      WHERE   xch.contract_header_id  =   ior_target_data.contract_header_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        --  ���b�N�̎擾�Ɏ��s�����ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00007        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50219        --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    xxcff_contract_lines      xcl
      WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        --  ���b�N�̎擾�Ɏ��s�����ꍇ
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_cff_00007        --  ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tok_cff_00007_1      --  �g�[�N���R�[�h1
                        , iv_token_value1   =>  cv_msg_cff_50220        --  �g�[�N���l1
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===============================
    --  ���[�X�_��w�b�_�X�V
    -- ===============================
    UPDATE  xxcff_contract_headers  xch
    SET     xch.payment_frequency   =   gt_param_new_frequency                    --  �x����
          , xch.payment_years       =   CEIL( gt_param_new_frequency / 12 )       --  �N��
          , xch.lease_end_date      =   ADD_MONTHS( xch.lease_end_date, gt_param_new_frequency - xch.payment_frequency )
                                                                                  --  ���[�X�I����
          , created_by              =   cn_created_by                             --  �쐬��
          , creation_date           =   cd_creation_date                          --  �쐬��
          , last_updated_by         =   cn_last_updated_by                        --  �ŏI�X�V��
          , last_update_date        =   cd_last_update_date                       --  �ŏI�X�V��
          , last_update_login       =   cn_last_update_login                      --  �ŏI�X�V���O�C��
          , request_id              =   cn_request_id                             --  �v��ID
          , program_application_id  =   cn_program_application_id                 --  �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id              =   cn_program_id                             --  �R���J�����g�E�v���O����ID
          , program_update_date     =   cd_program_update_date                    --  �v���O�����X�V��
    WHERE   xch.contract_header_id  =   ior_target_data.contract_header_id
    ;
    -- ===============================
    --  �ύX��x���v��擾
    -- ===============================
    SELECT  SUM( xpp.lease_charge )           SUM_LEASE_CHARGE              --  ���[�X���i���v�j
          , SUM( xpp.lease_tax_charge )       SUM_LEASE_TAX_CHARGE          --  ����Ŋz�i���v�j
          , SUM( xpp.lease_deduction )        SUM_LEASE_DEDUCTION           --  ���[�X��_�T���z�i���v�j
          , SUM( xpp.lease_tax_deduction )    SUM_LEASE_TAX_DEDUCTION       --  �����_�T���z�i���v�j
    INTO    ln_sum_lease_charge
          , ior_target_data.sum_new_tax_charge
          , ln_sum_lease_deduction
          , ln_sum_lease_tax_deduction
    FROM    xxcff_pay_planning    xpp
    WHERE   xpp.contract_line_id    =   ior_target_data.contract_line_id
    ;
    -- ===============================
    --  ���[�X�_�񖾍׍X�V
    -- ===============================
    UPDATE  xxcff_contract_lines    xcl
    SET
            xcl.second_charge                 =   gt_param_new_charge                                     --  2��ڈȍ~���z���[�X��_���[�X��
          , xcl.second_tax_charge             =   gt_param_new_tax_charge                                 --  2��ڈȍ~����Ŋz_���[�X��
          , xcl.second_total_charge           =   gt_param_new_charge + gt_param_new_tax_charge           --  2��ڈȍ~�v_���[�X��
          , xcl.gross_charge                  =   ln_sum_lease_charge                                     --  ���z���[�X��_���[�X��
          , xcl.gross_tax_charge              =   ior_target_data.sum_new_tax_charge                          --  ���z�����_���[�X��
          , xcl.gross_total_charge            =   ln_sum_lease_charge + ior_target_data.sum_new_tax_charge    --  ���z�v_���[�X��
          , xcl.gross_deduction               =   ln_sum_lease_deduction                                  --  ���z���[�X��_�T���z
          , xcl.gross_tax_deduction           =   ln_sum_lease_tax_deduction                              --  ���z�����_�T���z
          , xcl.gross_total_deduction         =   ln_sum_lease_deduction + ln_sum_lease_tax_deduction     --  ���z�v_�T���z
          , xcl.present_value_discount_rate   =   ior_target_data.discount_rate / 100                     --  ���݉��l������
          , xcl.present_value                 =   xcl.present_value + ior_target_data.present_value - ( ior_target_data.fin_debt_rem + ior_target_data.fin_debt )
                                                                                                          --  ���݉��l
          , xcl.original_cost                 =   xcl.original_cost + ior_target_data.present_value - ( ior_target_data.fin_debt_rem + ior_target_data.fin_debt )
                                                                                                          --  �擾���z
          , xcl.calc_interested_rate          =   ior_target_data.discount_rate / 100                      --  �v�Z���q��
          , xcl.tax_code                      =   gt_param_new_tax_code                                   --  �ŃR�[�h
          , created_by                        =   cn_created_by                                           --  �쐬��
          , creation_date                     =   cd_creation_date                                        --  �쐬��
          , last_updated_by                   =   cn_last_updated_by                                      --  �ŏI�X�V��
          , last_update_date                  =   cd_last_update_date                                     --  �ŏI�X�V��
          , last_update_login                 =   cn_last_update_login                                    --  �ŏI�X�V���O�C��
          , request_id                        =   cn_request_id                                           --  �v��ID
          , program_application_id            =   cn_program_application_id                               --  �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id                        =   cn_program_id                                           --  �R���J�����g�E�v���O����ID
          , program_update_date               =   cd_program_update_date                                  --  �v���O�����X�V��
    WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
    ;
    --
    -- ===============================
    --  ���[�X�_�񖾍ח���o�^
    -- ===============================
    INSERT INTO xxcff_contract_histories(
        contract_header_id                --   1.�_�����ID
      , contract_line_id                  --   2.�_�񖾍ד���ID
      , history_num                       --   3.�ύX����NO
      , contract_status                   --   4.�_��X�e�[�^�X
      , first_charge                      --   5.���񌎊z���[�X��_���[�X��
      , first_tax_charge                  --   6.�������Ŋz_���[�X��
      , first_total_charge                --   7.����v_���[�X��
      , second_charge                     --   8.��ڈȍ~���z���[�X��_���[�X��
      , second_tax_charge                 --   9.��ڈȍ~����Ŋz_���[�X��
      , second_total_charge               --  10.��ڈȍ~�v_���[�X��
      , first_deduction                   --  11.���񌎊z���[�X��_�T���z
      , first_tax_deduction               --  12.���񌎊z����Ŋz_�T���z
      , first_total_deduction             --  13.����v_�T���z
      , second_deduction                  --  14.��ڈȍ~���z���[�X��_�T���z
      , second_tax_deduction              --  15.��ڈȍ~����Ŋz_�T���z
      , second_total_deduction            --  16.��ڈȍ~�v_�T���z
      , gross_charge                      --  17.���z���[�X��_���[�X��
      , gross_tax_charge                  --  18.���z�����_���[�X��
      , gross_total_charge                --  19.���z�v_���[�X��
      , gross_deduction                   --  20.���z���[�X��_�T���z
      , gross_tax_deduction               --  21.���z�����_�T���z
      , gross_total_deduction             --  22.���z�v_�T���z
      , lease_kind                        --  23.���[�X���
      , estimated_cash_price              --  24.���ό����w�����z
      , present_value_discount_rate       --  25.���݉��l������
      , present_value                     --  26.���݉��l
      , life_in_months                    --  27.�@��ϗp�N��
      , original_cost                     --  28.�擾���z
      , calc_interested_rate              --  29.�v�Z���q��
      , object_header_id                  --  30.��������ID
      , asset_category                    --  31.���Y���
      , expiration_date                   --  32.������
      , cancellation_date                 --  33.���r����
      , vd_if_date                        --  34.���[�X�_����A�g��
      , info_sys_if_date                  --  35.���[�X�Ǘ����A�g��
      , first_installation_address        --  36.����ݒu�ꏊ
      , first_installation_place          --  37.����ݒu��
      , accounting_date                   --  38.�v���
      , accounting_if_flag                --  39.��v�h�e�t���O
      , description                       --  40.�E�v
      , created_by                        --  41.�쐬��
      , creation_date                     --  42.�쐬��
      , last_updated_by                   --  43.�ŏI�X�V��
      , last_update_date                  --  44.�ŏI�X�V��
      , last_update_login                 --  45.�ŏI�X�V���O�C��
      , request_id                        --  46.�v��ID
      , program_application_id            --  47.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                        --  48.�R���J�����g�E�v���O����ID
      , program_update_date               --  49.�v���O�����X�V��
      , update_reason                     --  50.�X�V���R
      , period_name                       --  51.��v����
      , tax_code                          --  52.�ŋ��R�[�h
    )
    SELECT
        xcl.contract_header_id                --   2.�_�����ID
      , xcl.contract_line_id                  --   1.�_�񖾍ד���ID
      , xxcff_contract_histories_s1.NEXTVAL   --   3.�ύX����NO
      , cv_contract_status_210                --   4.�_��X�e�[�^�X
      , xcl.first_charge                      --   5.���񌎊z���[�X��_���[�X��
      , xcl.first_tax_charge                  --   6.�������Ŋz_���[�X��
      , xcl.first_total_charge                --   7.����v_���[�X��
      , xcl.second_charge                     --   8.��ڈȍ~���z���[�X��_���[�X��
      , xcl.second_tax_charge                 --   9.��ڈȍ~����Ŋz_���[�X��
      , xcl.second_total_charge               --  10.��ڈȍ~�v_���[�X��
      , xcl.first_deduction                   --  11.���񌎊z���[�X��_�T���z
      , xcl.first_tax_deduction               --  12.���񌎊z����Ŋz_�T���z
      , xcl.first_total_deduction             --  13.����v_�T���z
      , xcl.second_deduction                  --  14.��ڈȍ~���z���[�X��_�T���z
      , xcl.second_tax_deduction              --  15.��ڈȍ~����Ŋz_�T���z
      , xcl.second_total_deduction            --  16.��ڈȍ~�v_�T���z
      , xcl.gross_charge                      --  17.���z���[�X��_���[�X��
      , xcl.gross_tax_charge                  --  18.���z�����_���[�X��
      , xcl.gross_total_charge                --  19.���z�v_���[�X��
      , xcl.gross_deduction                   --  20.���z���[�X��_�T���z
      , xcl.gross_tax_deduction               --  21.���z�����_�T���z
      , xcl.gross_total_deduction             --  22.���z�v_�T���z
      , xcl.lease_kind                        --  23.���[�X���
      , xcl.estimated_cash_price              --  24.���ό����w�����z
      , xcl.present_value_discount_rate       --  25.���݉��l������
      , xcl.present_value                     --  26.���݉��l
      , xcl.life_in_months                    --  27.�@��ϗp�N��
      , xcl.original_cost                     --  28.�擾���z
      , xcl.calc_interested_rate              --  29.�v�Z���q��
      , xcl.object_header_id                  --  30.��������ID
      , xcl.asset_category                    --  31.���Y���
      , xcl.expiration_date                   --  32.������
      , xcl.cancellation_date                 --  33.���r����
      , xcl.vd_if_date                        --  34.���[�X�_����A�g��
      , xcl.info_sys_if_date                  --  35.���[�X�Ǘ����A�g��
      , xcl.first_installation_address        --  36.����ݒu�ꏊ
      , xcl.first_installation_place          --  37.����ݒu��
      , LAST_DAY( gd_ifrs_period_date )       --  38.�v���
      , cv_flag_2                             --  39.��v�h�e�t���O
      , NULL                                  --  40.�E�v
      , cn_created_by                         --  41.�쐬��
      , cd_creation_date                      --  42.�쐬��
      , cn_last_updated_by                    --  43.�ŏI�X�V��
      , cd_last_update_date                   --  44.�ŏI�X�V��
      , cn_last_update_login                  --  45.�ŏI�X�V���O�C��
      , cn_request_id                         --  46.�v��ID
      , cn_program_application_id             --  47.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                         --  48.�R���J�����g�E�v���O����ID
      , cd_program_update_date                --  49.�v���O�����X�V��
      , cv_update_reason                      --  50.�X�V���R
      , gt_ifrs_period_name                   --  51.��v����
      , xcl.tax_code                          --  52.�ŋ��R�[�h
    FROM    xxcff_contract_lines    xcl
    WHERE   xcl.contract_line_id    =   ior_target_data.contract_line_id
    ;
  EXCEPTION
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
  END upd_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_adjustment_oif
   * Description      : �C��OIF�쐬(A-8)
   ***********************************************************************************/
  PROCEDURE ins_adjustment_oif(
      ir_target_data    IN  g_target_rtype  --  �Ώۃf�[�^
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_adjustment_oif'; -- �v���O������
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
    ln_dummy            NUMBER;             --  �_�~�[�ϐ�
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
    -- ===============================
    --  OIF�쐬
    -- ===============================
    INSERT INTO xx01_adjustment_oif(
        adjustment_oif_id                       --   1
      , book_type_code                          --   2
      , asset_number_old                        --   3
      , dpis_old                                --   4
      , category_id_old                         --   5
      , cat_attribute_category_old              --   6
      , created_by                              --   7
      , creation_date                           --   8
      , last_updated_by                         --   9
      , last_update_date                        --  10
      , last_update_login                       --  11
      , request_id                              --  12
      , program_application_id                  --  13
      , program_id                              --  14
      , program_update_date                     --  15
      , posting_flag                            --  16
      , status                                  --  17
      , amortized_flag                          --  18
      , amortization_start_date                 --  19
      , asset_number_new                        --  20
      , description                             --  21
      , tag_number                              --  22
      , category_id_new                         --  23
      , serial_number                           --  24
      , asset_key_ccid                          --  25
      , key_segment1                            --  26
      , key_segment2                            --  27
      , transaction_units                       --  28
      , parent_asset_id                         --  29
      , lease_id                                --  30
      , model_number                            --  31
      , in_use_flag                             --  32
      , inventorial                             --  33
      , owned_leased                            --  34
      , new_used                                --  35
      , cat_attribute1                          --  36
      , cat_attribute2                          --  37
      , cat_attribute3                          --  38
      , cat_attribute4                          --  39
      , cat_attribute5                          --  40
      , cat_attribute6                          --  41
      , cat_attribute7                          --  42
      , cat_attribute8                          --  43
      , cat_attribute9                          --  44
      , cat_attribute10                         --  45
      , cat_attribute11                         --  46
      , cat_attribute12                         --  47
      , cat_attribute13                         --  48
      , cat_attribute14                         --  49
      , cat_attribute15                         --  50
      , cat_attribute16                         --  51
      , cat_attribute17                         --  52
      , cat_attribute18                         --  53
      , cat_attribute19                         --  54
      , cat_attribute20                         --  55
      , cat_attribute21                         --  56
      , cat_attribute22                         --  57
      , cat_attribute23                         --  58
      , cat_attribute24                         --  59
      , cat_attribute25                         --  60
      , cat_attribute26                         --  61
      , cat_attribute27                         --  62
      , cat_attribute28                         --  63
      , cat_attribute29                         --  64
      , cat_attribute30                         --  65
      , cat_attribute_category_new              --  66
      , cost                                    --  67
      , original_cost                           --  68
      , salvage_value                           --  69
      , percent_salvage_value                   --  70
      , allowed_deprn_limit_amount              --  71
      , allowed_deprn_limit                     --  72
      , depreciate_flag                         --  73
      , dpis_new                                --  74
      , deprn_method_code                       --  75
      , basic_rate                              --  76
      , adjusted_rate                           --  77
      , life_years                              --  78
      , life_months                             --  79
      , bonus_rule                              --  80
    )
    SELECT
      --  ���͕ύX���鍀�ځA����ȊO�͌��s�f�[�^�̏����g�p����
      xx01_adjustment_oif_s.NEXTVAL             --   1.�V�[�P���X
    , fb.book_type_code                         --   2.�䒠��
    , fab.asset_number                          --   3.���Y�ԍ�
    , fb.date_placed_in_service                 --   4.���Ƌ��p���i�C���O�j
    , fab.asset_category_id                     --   5.���Y�J�e�S��ID�i�C���O�j
    , fab.attribute_category_code               --   6.���Y�J�e�S���R�[�h�i�C���O�j
    , cn_created_by                             --   7.�쐬��
    , cd_creation_date                          --   8.�쐬��
    , cn_last_updated_by                        --   9.�ŏI�X�V��
    , cd_last_update_date                       --  10.�ŏI�X�V��
    , cn_last_update_login                      --  11.�ŏI�X�V���O�C��ID
    , cn_request_id                             --  12.���N�G�X�gID
    , cn_program_application_id                 --  13.�A�v���P�[�V����ID
    , cn_program_id                             --  14.�v���O����ID
    , cd_program_update_date                    --  15.�v���O�����ŏI�X�V��
    , cv_flag_y                                 --  16.�]�L�`�F�b�N�t���O
    , cv_oif_status_p                           --  17.�X�e�[�^�X
    , cv_oif_amortized_yes                      --  18.���C���z���p�t���O
    , gd_ifrs_period_date                       --  19.�����p�J�n��
    , fab.asset_number                          --  20.���Y�ԍ��i�C����j
    , fat.description                           --  21.�E�v�i�C����j
    , fab.tag_number                            --  22.���i�[�ԍ�
    , ir_target_data.asset_category_id          --  23.�����Y�J�e�S��ID�i�C����j
    , fab.serial_number                         --  24.�V���A���ԍ�
    , fab.asset_key_ccid                        --  25.���Y�L�[CCID
    , fak.segment1                              --  26.���Y�L�[�Z�O�����g1
    , fak.segment2                              --  27.���Y�L�[�Z�O�����g2
    , fab.current_units                         --  28.�P��
    , fab.parent_asset_id                       --  29.�e���YID
    , fab.lease_id                              --  30.���[�XID
    , fab.model_number                          --  31.���f��
    , fab.in_use_flag                           --  32.�g�p��
    , fab.inventorial                           --  33.���n�I���t���O
    , fab.owned_leased                          --  34.���L��
    , fab.new_used                              --  35.�V�i/����
    , fab.attribute1                            --  36.�J�e�S��DFF1
    , fab.attribute2                            --  37.�J�e�S��DFF2
    , fab.attribute3                            --  38.�J�e�S��DFF3
    , fab.attribute4                            --  39.�J�e�S��DFF4
    , fab.attribute5                            --  40.�J�e�S��DFF5
    , fab.attribute6                            --  41.�J�e�S��DFF6
    , fab.attribute7                            --  42.�J�e�S��DFF7
    , fab.attribute8                            --  43.�J�e�S��DFF8
    , fab.attribute9                            --  44.�J�e�S��DFF9
    , fab.attribute10                           --  45.�J�e�S��DFF10
    , fab.attribute11                           --  46.�J�e�S��DFF11
    , fab.attribute12                           --  47.�J�e�S��DFF12
    , fab.attribute13                           --  48.�J�e�S��DFF13
    , fab.attribute14                           --  49.�J�e�S��DFF14
    , fab.attribute15                           --  50.�J�e�S��DFF15
    , fab.attribute16                           --  51.�J�e�S��DFF16
    , fab.attribute17                           --  52.�J�e�S��DFF17
    , fab.attribute18                           --  53.�J�e�S��DFF18
    , fab.attribute19                           --  54.�J�e�S��DFF19
    , fab.attribute20                           --  55.�J�e�S��DFF20
    , fab.attribute21                           --  56.�J�e�S��DFF21
    , fab.attribute22                           --  57.�J�e�S��DFF22
    , fab.attribute23                           --  58.�J�e�S��DFF23
    , fab.attribute24                           --  59.�J�e�S��DFF24
    , fab.attribute25                           --  60.�J�e�S��DFF27
    , fab.attribute26                           --  61.�J�e�S��DFF25
    , fab.attribute27                           --  62.�J�e�S��DFF26
    , fab.attribute28                           --  63.�J�e�S��DFF28
    , fab.attribute29                           --  64.�J�e�S��DFF29
    , fab.attribute30                           --  65.�J�e�S��DFF30
    , ir_target_data.asset_category_code        --  66.�����Y�J�e�S���R�[�h�i�C����j
    , ( SELECT xcl.original_cost FROM xxcff_contract_lines xcl WHERE xcl.contract_line_id = ir_target_data.contract_line_id )
                                                --  67.���擾���z
    , fb.original_cost                          --  68.�����擾���z
    , fb.salvage_value                          --  69.�c�����z
    , fb.percent_salvage_value                  --  70.�c�����z%
    , fb.allowed_deprn_limit_amount             --  71.���p���x�z
    , fb.allowed_deprn_limit                    --  72.���p���x��
    , fb.depreciate_flag                        --  73.���p��v��t���O
    , fb.date_placed_in_service                 --  74.���Ƌ��p���i�C����j
    , ir_target_data.deprn_method               --  75.�����p���@
    , fb.basic_rate                             --  76.���ʏ��p��
    , fb.adjusted_rate                          --  77.�����㏞�p��
    , TRUNC( gt_param_new_frequency / 12 )      --  78.���ϗp�N��
    , gt_param_new_frequency - TRUNC( gt_param_new_frequency / 12 ) * 12
                                                --  79.������
    , fb.bonus_rule                             --  80.�{�[�i�X���[��
    FROM    fa_additions_b            fab       --  ���Y�ڍ׏��
          , fa_additions_tl           fat       --  ���Y�ڍ׏��(TL)
          , fa_asset_keywords         fak       --  ���Y�L�[���[�h
          , fa_books                  fb        --  ���Y�䒠���
    WHERE   fab.asset_id                  =   fat.asset_id
    AND     fat.language                  =   cv_lang
    AND     fab.asset_id                  =   fb.asset_id
    AND     fb.book_type_code             =   gt_prof_ifrs_lease_books
    AND     fb.date_ineffective IS NULL
    AND     fab.asset_key_ccid            =   fak.code_combination_id(+)
    AND     fab.attribute10               =   TO_CHAR( ir_target_data.contract_line_id )
    ;
    --
    IF ( SQL%ROWCOUNT = 0 ) THEN
      --  �X�V�Ώۃf�[�^�����݂��Ȃ��ꍇ�A���b�Z�[�W��\���i�����͐���I���j
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_app_kbn_cff          --  �A�v���P�[�V�����Z�k��
                      , iv_name           =>  cv_msg_cff_00165        --  ���b�Z�[�W�R�[�h
                      , iv_token_name1    =>  cv_tok_cff_00165_1      --  �g�[�N���R�[�h1
                      , iv_token_value1   =>  cv_msg_cff_50256        --  �g�[�N���l1
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
    END IF;
    --
    IF ( ir_target_data.sum_new_tax_charge <> ir_target_data.sum_old_tax_charge ) THEN
      --  �Ŋz���ύX����Ă���ꍇ
      INSERT INTO xxcff_fa_transactions(
          fa_transaction_id             --   1.���[�X�������ID
        , contract_header_id            --   2.�_�����ID
        , contract_line_id              --   3.�_�񖾍ד���ID
        , object_header_id              --   4.��������ID
        , period_name                   --   5.��v����
        , transaction_type              --   6.����^�C�v
        , movement_type                 --   7.�ړ��^�C�v
        , book_type_code                --   8.���Y�䒠��
        , lease_class                   --   9.���[�X���
        , owner_company                 --  10.�{�Ё^�H��
        , gl_if_flag                    --  11.GL�A�g�t���O
        , tax_charge                    --  12.�Ŋz
        , tax_code                      --  13.�ŃR�[�h
        , created_by                    --  14.�쐬��
        , creation_date                 --  15.�쐬��
        , last_updated_by               --  16.�ŏI�X�V��
        , last_update_date              --  17.�ŏI�X�V��
        , last_update_login             --  18.�ŏI�X�V���O�C��
        , request_id                    --  19.�v��ID
        , program_application_id        --  20.�A�v���P�[�V����ID
        , program_id                    --  21.�v���O����ID
        , program_update_date           --  22.�v���O�����X�V��
      )VALUES(
          xxcff_fa_transactions_s1.NEXTVAL                                          --   1
        , ir_target_data.contract_header_id                                         --   2
        , ir_target_data.contract_line_id                                           --   3
        , ir_target_data.object_header_id                                           --   4
        , gt_ifrs_period_name                                                       --   5
        , '4'                                                                       --   6
        , NULL                                                                      --   7
        , gt_prof_ifrs_lease_books                                                  --   8
        , ir_target_data.lease_class                                                --   9
        , ir_target_data.owner_company                                              --  10
        , '1'                                                                       --  11
        , ir_target_data.sum_new_tax_charge - ir_target_data.sum_old_tax_charge     --  12
        , gt_param_new_tax_code                                                     --  13
        , cn_created_by                                                             --  14
        , cd_creation_date                                                          --  15
        , cn_last_updated_by                                                        --  16
        , cd_last_update_date                                                       --  17
        , cn_last_update_login                                                      --  18
        , cn_request_id                                                             --  19
        , cn_program_application_id                                                 --  20
        , cn_program_id                                                             --  21
        , cd_program_update_date                                                    --  22
      );
    END IF;
  EXCEPTION
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
  END ins_adjustment_oif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_object_code    IN  VARCHAR2        --  �����R�[�h
    , iv_new_frequency  IN  VARCHAR2        --  �ύX��x����
    , iv_new_charge     IN  VARCHAR2        --  �ύX�ナ�[�X��
    , iv_new_tax_charge IN  VARCHAR2        --  �ύX��Ŋz
    , iv_new_tax_code   IN  VARCHAR2        --  �ύX��ŃR�[�h
    , ov_errbuf         OUT VARCHAR2        --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2        --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2        --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_target_data        g_target_rtype;                                       --  �Ώۃf�[�^�ێ��p
    lt_new_pay_plan       g_new_pay_plan_ttype;                                 --  �V�K�x���v��
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --  ������
    lr_target_data  :=  NULL;
    lt_new_pay_plan.DELETE;
    -- ===============================
    --  ��������(A-1)
    -- ===============================
    init(
        iv_object_code    =>  iv_object_code      --  �����R�[�h
      , iv_new_frequency  =>  iv_new_frequency    --  �ύX��x����
      , iv_new_charge     =>  iv_new_charge       --  �ύX�ナ�[�X��
      , iv_new_tax_charge =>  iv_new_tax_charge   --  �ύX��Ŋz
      , iv_new_tax_code   =>  iv_new_tax_code     --  �ύX��ŃR�[�h
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �Ώۃf�[�^���o(A-2)
    -- ===============================
    get_target_data(
        or_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �e����CSV�o��(A-3)  �ύX�O�f�[�^
    -- ===============================
    --  COMMIT����Ă��܂����߁A�ŏ��Ɏ��s����
    output_csv(
        ir_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �V�x���v��f�[�^�쐬(A-4)
    -- ===============================
    create_pay_planning(
        ior_target_data   =>  lr_target_data      --  �Ώۃf�[�^
      , ot_new_pay_plan   =>  lt_new_pay_plan     --  �V�x���v��
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �f�[�^�o�b�N�A�b�v(A-5)
    -- ===============================
    ins_backup(
        ir_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �V�x���v��o�^(A-6)
    -- ===============================
    replace_pay_planning(
        ir_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , it_new_pay_plan   =>  lt_new_pay_plan     --  �V�x���v��
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �_����X�V(A-7)
    -- ===============================
    upd_contract_data(
        ior_target_data   =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �C��OIF�쐬(A-8)
    -- ===============================
    ins_adjustment_oif(
        ir_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    -- ===============================
    --  �e����CSV�o��(A-3)  �ύX��f�[�^
    -- ===============================
    --  COMMIT����Ă��܂����߁A�S�������펞�i�Ō�j�Ɏ��s
    output_csv(
        ir_target_data    =>  lr_target_data      --  �Ώۃf�[�^
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE procedure_expt;
    END IF;
    --
  EXCEPTION
    --  �e�v���V�[�W���ł̏������ʂɑ΂����O
    WHEN procedure_expt THEN
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
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
      errbuf            OUT VARCHAR2          --  �G���[���b�Z�[�W #�Œ�#
    , retcode           OUT VARCHAR2          --  �G���[�R�[�h     #�Œ�#
    , iv_object_code    IN  VARCHAR2          --  �����R�[�h
    , iv_new_frequency  IN  VARCHAR2          --  �ύX��x����
    , iv_new_charge     IN  VARCHAR2          --  �ύX�ナ�[�X��
    , iv_new_tax_charge IN  VARCHAR2          --  �ύX��Ŋz
    , iv_new_tax_code   IN  VARCHAR2          --  �ύX��ŃR�[�h
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
        iv_object_code    =>  iv_object_code      --  �����R�[�h
      , iv_new_frequency  =>  iv_new_frequency    --  �ύX��x����
      , iv_new_charge     =>  iv_new_charge       --  �ύX�ナ�[�X��
      , iv_new_tax_charge =>  iv_new_tax_charge   --  �ύX��Ŋz
      , iv_new_tax_code   =>  iv_new_tax_code     --  �ύX��ŃR�[�h
      , ov_errbuf         =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode        =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg         =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --  �{�����͑Ώ�1���̂�
    gn_target_cnt :=  1;
    gn_normal_cnt :=  CASE WHEN lv_retcode = cv_status_normal THEN 1 ELSE 0 END;
    gn_error_cnt  :=  gn_target_cnt - gn_normal_cnt;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
END XXCFF020A01C;
/
