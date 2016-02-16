create or replace
PACKAGE BODY XXCFF016A37C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFF016A37C(body)
 * Description      : �ă��[�X�҃����e�i���X�A�b�v���[�h
 * MD.050           : MD050_CFF_016_A37_�ă��[�X�҃����e�i���X�A�b�v���[�h
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  update_pay_planning          �x���v��̍X�V                            (A-9)
 *  insert_contract_histories    ���[�X�_�񖾍ח����̍쐬                  (A-8)
 *  update_contract_lines        ���[�X�_�񖾍ׂ̍X�V                      (A-7)
 *  insert_object_histories      ���[�X���������̍쐬                      (A-6)
 *  update_object                ���[�X�����̍X�V                          (A-5)
 *  get_contract_lines           ���[�X�_�񖾍ׂ̃`�F�b�N����              (A-4)
 *  chk_param                    �����R�[�h�`�F�b�N����                    (A-3)
 *  get_upload_data              �t�@�C���A�b�v���[�hIF�f�[�^�擾����      (A-2)
 *  init                         ��������                                  (A-1)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/01/14    1.0   SCSK ���H        �V�K�쐬
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCFF016A37C';      -- �p�b�P�[�W��
--
  -- �o�̓^�C�v
  cv_file_type_out        CONSTANT VARCHAR2(10)  := 'OUTPUT';            -- �o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log        CONSTANT VARCHAR2(10)  := 'LOG';               -- ���O(�V�X�e���Ǘ��җp�o�͐�)
  -- �A�v���P�[�V�����Z�k��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCFF';             -- �A�h�I���F��v�E���[�X�EFA�̈�
  -- ���t�`��
  cv_format_yyyy_mm       CONSTANT VARCHAR2(7)   := 'YYYY-MM';           -- ���t�`���FYYYY-MM
  cv_format_yyyymmdd      CONSTANT VARCHAR2(8)   := 'YYYYMMDD';           -- ���t�`���FYYYYMMDD
  -- �X�V�p
  cv_description          CONSTANT VARCHAR2(23)  := '�ă��[�X�҃����e�i���X ';   -- �E�v
  -- ���b�Z�[�W��(�{��)
  cv_msg_xxcff00007       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007';  -- ���b�N�G���[
  cv_msg_xxcff00094       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_xxcff00102       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';  -- �o�^�G���[
  cv_msg_xxcff00104       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104';  -- �폜�G���[
  cv_msg_xxcff00123       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123';  -- ���݃`�F�b�N�G���[
  cv_msg_xxcff00165       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00165';  -- �擾�Ώۃf�[�^����
  cv_msg_xxcff00167       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';  -- �A�b�v���[�h�����o�̓��b�Z�[�W
  cv_msg_xxcff00186       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00186';  -- ��v���Ԏ擾�G���[
  cv_msg_xxcff00195       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00195';  -- �X�V�G���[
  cv_msg_xxcff00237       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00237';  -- ���[�X�������o��
  cv_msg_xxcff00238       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00238';  -- ���[�X�����X�e�[�^�X�`�F�b�N�G���[
  cv_msg_xxcff00239       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00239';  -- ���[�X�_��X�e�[�^�X�o��
  cv_msg_xxcff00240       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00240';  -- ���[�X�_��X�e�[�^�X�G���[
  cv_msg_xxcff00241       CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00241';  -- ���[�X�x���v��X�V���Ԑ��o��
  -- �g�[�N��
  cv_tkn_file_name        CONSTANT VARCHAR2(15)  := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_csv_name         CONSTANT VARCHAR2(15)  := 'CSV_NAME';          -- CSV�t�@�C����
  cv_tkn_func_name        CONSTANT VARCHAR2(15)  := 'FUNC_NAME';         -- �֐���
  cv_tkn_object_code      CONSTANT VARCHAR2(15)  := 'OBJECT_CODE';       -- �����R�[�h
  cv_tkn_object_status    CONSTANT VARCHAR2(15)  := 'OBJECT_STATUS';     -- �����X�e�[�^�X
  cv_tkn_re_lease_times   CONSTANT VARCHAR2(15)  := 'RE_LEASE_TIMES';    -- �ă��[�X��
  cv_tkn_contract_status  CONSTANT VARCHAR2(15)  := 'CONTRACT_STATUS';   -- �_��X�e�[�^�X
  cv_tkn_column           CONSTANT VARCHAR2(15)  := 'COLUMN_DATA';       -- ���[�X�������
  cv_tkn_get              CONSTANT VARCHAR2(15)  := 'GET_DATA';          -- ���[�X�_�񖾍׏��
  cv_tkn_table            CONSTANT VARCHAR2(15)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_info             CONSTANT VARCHAR2(15)  := 'INFO';              -- SQLERRM
  cv_tkn_count            CONSTANT VARCHAR2(15)  := 'COUNT';             -- ���[�X�x���v��X�V���Ԑ�
  -- �g�[�N���l
  cv_msg_cff_50014        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014';  -- ���[�X�����e�[�u��
  cv_msg_cff_50023        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50023';  -- ���[�X���������e�[�u��
  cv_msg_cff_50030        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030';  -- ���[�X�_�񖾍׃e�[�u��
  cv_msg_cff_50070        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50070';  -- ���[�X�_�񖾍ח����e�[�u��
  cv_msg_cff_50131        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131';  -- BLOB�f�[�^�ϊ��p�֐�
  cv_msg_cff_50175        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175';  -- �t�@�C���A�b�v���[�hI/F�e�[�u��
  cv_msg_cff_50210        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50210';  -- �R���J�����g�p�����[�^�o�͏���
  cv_msg_cff_50220        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50220';  -- ���[�X�_�񖾍�
  cv_msg_cff_50283        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50283';  -- ���[�X�x���v��e�[�u��
  cv_msg_cff_50284        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50284';  -- �ă��[�X�҃����e�i���X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �t�@�C���A�b�v���[�hIF�f�[�^
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  -- �e�[�u���擾�p��`
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;           -- ��������ID
  TYPE g_re_lease_times_ttype        IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;             -- �ă��[�X��
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_lines.contract_header_id%TYPE INDEX BY PLS_INTEGER;         -- �_�����ID
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;           -- �_�񖾍ד���ID
  TYPE g_contract_status_ttype       IS TABLE OF xxcff_contract_lines.contract_status%TYPE INDEX BY PLS_INTEGER;            -- �_��X�e�[�^�X
  TYPE g_contract_status_name_ttype  IS TABLE OF xxcff_contract_status_v.contract_status_name%TYPE INDEX BY PLS_INTEGER;    -- �_��X�e�[�^�X��
--
  g_object_header_id_tab           g_object_header_id_ttype;                     -- ��������ID
  g_re_lease_times_tab             g_re_lease_times_ttype;                       -- �ă��[�X��
  g_contract_header_id_tab         g_contract_header_id_ttype;                   -- �_�����ID
  g_contract_line_id_tab           g_contract_line_id_ttype;                     -- �_�񖾍ד���ID
  g_contract_status_tab            g_contract_status_ttype;                      -- �_��X�e�[�^�X
  g_contract_status_name_tab       g_contract_status_name_ttype;                 -- �_��X�e�[�^�X��
--
  gt_period_name                   fa_deprn_periods.period_name%TYPE;            -- ��v����(���[�X�䒠�ŏI�N���[�Y����)
--
  /**********************************************************************************
   * Procedure Name   : update_pay_planning
   * Description      : �x���v��̍X�V(A-9)
   ***********************************************************************************/
  PROCEDURE update_pay_planning(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
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
    cv_accounting_if_flag_1    CONSTANT VARCHAR2(1) := '1';                -- �����M
    cv_accounting_if_flag_3    CONSTANT VARCHAR2(1) := '3';                -- �ƍ��s��
--
    -- *** ���[�J���ϐ� ***
    ln_upd_cnt                 NUMBER;         -- ���[�v�J�E���^
    TYPE l_rowid_ttype         IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_pay_rowid               l_rowid_ttype;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR pay_data_cur
    IS
      SELECT xpp.rowid  AS row_id   -- �X�V�p�sID
      FROM   xxcff_pay_planning  xpp
      WHERE  xpp.contract_header_id = g_contract_header_id_tab(in_loop_cnt)
      AND    xpp.contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
      AND    xpp.accounting_if_flag = cv_accounting_if_flag_1
      FOR UPDATE NOWAIT;
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
    -- ***       �x���v��̍X�V            ***
    -- ***************************************
--
    -- =====================================
    -- 1.���[�X�x���v��̃��b�N���擾
    -- =====================================
    BEGIN
      -- �J�[�\���̃I�[�v��
      OPEN   pay_data_cur;
      -- �X�V�Ώۃf�[�^�擾
      FETCH  pay_data_cur BULK COLLECT INTO lt_pay_rowid;
      -- �J�[�\���̃N���[�Y
      CLOSE pay_data_cur;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50283
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �X�V�Ώۂ����݂���ꍇ
    IF ( lt_pay_rowid.COUNT > 0 ) THEN
      BEGIN
        FORALL ln_upd_cnt IN lt_pay_rowid.FIRST..lt_pay_rowid.LAST
        -- ��vIF�t���O�X�V
          UPDATE xxcff_pay_planning xpp
          SET    xpp.accounting_if_flag     = cv_accounting_if_flag_3         -- ��vIF�t���O('3':�ƍ��s��)
                ,xpp.last_updated_by        = cn_last_updated_by              -- �ŏI�X�V��
                ,xpp.last_update_date       = cd_last_update_date             -- �ŏI�X�V��
                ,xpp.last_update_login      = cn_last_update_login            -- �ŏI�X�V���O�C��
                ,xpp.request_id             = cn_request_id                   -- �v��ID
                ,xpp.program_application_id = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,xpp.program_id             = cn_program_id                   -- �R���J�����g�E�v���O����ID
                ,xpp.program_update_date    = cd_program_update_date          -- �v���O�����X�V��
          WHERE  xpp.ROWID = lt_pay_rowid(ln_upd_cnt)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_xxcff00195
                         ,iv_token_name1  => cv_tkn_table
                         ,iv_token_value1 => cv_msg_cff_50283
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- ���[�X�x���v��X�V���Ԑ��o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_xxcff00241
                      ,iv_token_name1  => cv_tkn_object_code
                      ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_NUMBER(lt_pay_rowid.COUNT)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
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
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( pay_data_cur%ISOPEN ) THEN
        CLOSE   pay_data_cur;
      END IF;
--
  END update_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : ���[�X�_�񖾍ח����̍쐬(A-8)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
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
    cv_if_flag_sent       CONSTANT VARCHAR2(1)   := '2';                       -- ���M��
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
        ,tax_code                              -- �ŋ��R�[�h
        ,accounting_date                       -- �v���
        ,accounting_if_flag                    -- ��v�h�e�t���O
        ,description                           -- �E�v
        ,update_reason                         -- �X�V���R
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
         xcl.contract_header_id                                 contract_header_id             -- �_�����ID
        ,xcl.contract_line_id                                   contract_line_id               -- �_�񖾍ד���ID
        ,xxcff_contract_histories_s1.NEXTVAL                    history_num                    -- �_�񖾍ח����V�[�P���X(�ύX����NO)
        ,xcl.contract_status                                    contract_status                -- �_��X�e�[�^�X
        ,xcl.first_charge                                       first_charge                   -- ���񌎊z���[�X��_���[�X��
        ,xcl.first_tax_charge                                   first_tax_charge               -- �������Ŋz_���[�X��
        ,xcl.first_total_charge                                 first_total_charge             -- ����v_���[�X��
        ,xcl.second_charge                                      second_charge                  -- 2��ڈȍ~���z���[�X��_���[�X��
        ,xcl.second_tax_charge                                  second_tax_charge              -- 2��ڈȍ~����Ŋz_���[�X��
        ,xcl.second_total_charge                                second_total_charge            -- 2��ڈȍ~�v_���[�X��
        ,xcl.first_deduction                                    first_deduction                -- ���񌎊z���[�X��_�T���z
        ,xcl.first_tax_deduction                                first_tax_deduction            -- ���񌎊z����Ŋz_�T���z
        ,xcl.first_total_deduction                              first_total_deduction          -- ����v_�T���z
        ,xcl.second_deduction                                   second_deduction               -- 2��ڈȍ~���z���[�X��_�T���z
        ,xcl.second_tax_deduction                               second_tax_deduction           -- 2��ڈȍ~����Ŋz_�T���z
        ,xcl.second_total_deduction                             second_total_deduction         -- 2��ڈȍ~�v_�T���z
        ,xcl.gross_charge                                       gross_charge                   -- ���z���[�X��_���[�X��
        ,xcl.gross_tax_charge                                   gross_tax_charge               -- ���z�����_���[�X��
        ,xcl.gross_total_charge                                 gross_total_charge             -- ���z�v_���[�X��
        ,xcl.gross_deduction                                    gross_deduction                -- ���z���[�X��_�T���z
        ,xcl.gross_tax_deduction                                gross_tax_deduction            -- ���z�����_�T���z
        ,xcl.gross_total_deduction                              gross_total_deduction          -- ���z�v_�T���z
        ,xcl.lease_kind                                         lease_kind                     -- ���[�X���
        ,xcl.estimated_cash_price                               estimated_cash_price           -- ���ό����w�����z
        ,xcl.present_value_discount_rate                        present_value_discount_rate    -- ���݉��l������
        ,xcl.present_value                                      present_value                  -- ���݉��l
        ,xcl.life_in_months                                     life_in_months                 -- �@��ϗp�N��
        ,xcl.original_cost                                      original_cost                  -- �擾���z
        ,xcl.calc_interested_rate                               calc_interested_rate           -- �v�Z���q��
        ,xcl.object_header_id                                   object_header_id               -- ��������ID
        ,xcl.asset_category                                     asset_category                 -- ���Y���
        ,xcl.expiration_date                                    expiration_date                -- ������
        ,xcl.cancellation_date                                  cancellation_date              -- ���r����
        ,xcl.vd_if_date                                         vd_if_date                     -- ���[�X�_����A�g��
        ,xcl.info_sys_if_date                                   info_sys_if_date               -- ���[�X�Ǘ����A�g��
        ,xcl.first_installation_address                         first_installation_address     -- ����ݒu�ꏊ
        ,xcl.first_installation_place                           first_installation_place       -- ����ݒu��
        ,xcl.tax_code                                           tax_code                       -- �ŋ��R�[�h
        ,LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   accounting_date                -- �v���
        ,cv_if_flag_sent                                        accounting_if_flag             -- ��v�h�e�t���O('2':���M��)
        ,cv_description || TO_CHAR(SYSDATE, cv_format_yyyymmdd) description                    -- �E�v
        ,NULL                                                   update_reason                  -- �X�V���R
        ,cn_created_by                                          created_by                     -- �쐬��
        ,cd_creation_date                                       creation_date                  -- �쐬��
        ,cn_last_updated_by                                     last_updated_by                -- �ŏI�X�V��
        ,cd_last_update_date                                    last_update_date               -- �ŏI�X�V��
        ,cn_last_update_login                                   last_update_login              -- �ŏI�X�V���O�C��
        ,cn_request_id                                          request_id                     -- �v��ID
        ,cn_program_application_id                              program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                                          program_id                     -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date                                 program_update_date            -- �v���O�����X�V��
      FROM   xxcff_contract_lines xcl          -- ���[�X�_�񖾍�
      WHERE  xcl.contract_header_id = g_contract_header_id_tab(in_loop_cnt)
      AND    xcl.contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
      ;
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
   * Procedure Name   : update_contract_lines
   * Description      : ���[�X�_�񖾍ׂ̍X�V(A-7)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
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
    cv_contract_status_204    CONSTANT VARCHAR2(3)   := '204';       -- ����
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
    -- ***    ���[�X�_�񖾍ׂ̍X�V         ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�_�񖾍׃e�[�u���̍X�V
    -- =====================================
    BEGIN
      UPDATE  xxcff_contract_lines xcl
      SET     xcl.contract_status         = cv_contract_status_204                                 -- �_��X�e�[�^�X
             ,xcl.expiration_date         = LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   -- ������
             ,xcl.last_updated_by         = cn_last_updated_by                                     -- �ŏI�X�V��
             ,xcl.last_update_date        = cd_last_update_date                                    -- �ŏI�X�V��
             ,xcl.last_update_login       = cn_last_update_login                                   -- �ŏI�X�V���O�C��
             ,xcl.request_id              = cn_request_id                                          -- �v��ID
             ,xcl.program_application_id  = cn_program_application_id                              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,xcl.program_id              = cn_program_id                                          -- �R���J�����g�E�v���O����ID
             ,xcl.program_update_date     = cd_program_update_date                                 -- �v���O�����X�V��
      WHERE   xcl.contract_header_id  = g_contract_header_id_tab(in_loop_cnt)           -- �_�����ID
      AND     xcl.contract_line_id    = g_contract_line_id_tab(in_loop_cnt)             -- �_�񖾍ד���ID
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
   * Procedure Name   : insert_object_histories
   * Description      : ���[�X���������̍쐬(A-6)
   ***********************************************************************************/
  PROCEDURE insert_object_histories(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_histories'; -- �v���O������
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
    accounting_if_flag_2    CONSTANT VARCHAR2(1)   := '2';                        -- ��v�h�e�t���O�F���M��
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
    -- ***    ���[�X���������̍쐬         ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X���������̍쐬
    -- =====================================
    BEGIN
      INSERT INTO xxcff_object_histories(
         object_header_id         -- ��������ID
        ,history_num              -- �ύX����NO
        ,object_code              -- �����R�[�h
        ,lease_class              -- ���[�X���
        ,lease_type               -- ���[�X�敪
        ,re_lease_times           -- �ă��[�X��
        ,po_number                -- �����ԍ�
        ,registration_number      -- �o�^�ԍ�
        ,age_type                 -- �N��
        ,model                    -- �@��
        ,serial_number            -- �@��
        ,quantity                 -- ����
        ,manufacturer_name        -- ���[�J�[��
        ,department_code          -- �Ǘ�����R�[�h
        ,owner_company            -- �{�Ё^�H��
        ,installation_address     -- ���ݒu�ꏊ
        ,installation_place       -- ���ݒu��
        ,chassis_number           -- �ԑ�ԍ�
        ,re_lease_flag            -- �ă��[�X�v�t���O
        ,cancellation_type        -- ���敪
        ,cancellation_date        -- ���r����
        ,dissolution_date         -- ���r���L�����Z����
        ,bond_acceptance_flag     -- �؏���̃t���O
        ,bond_acceptance_date     -- �؏���̓�
        ,expiration_date          -- ������
        ,object_status            -- �����X�e�[�^�X
        ,active_flag              -- �����L���t���O
        ,info_sys_if_date         -- ���[�X�Ǘ����A�g��
        ,generation_date          -- ������
        ,customer_code            -- �ڋq�R�[�h
        ,accounting_date          -- �v���
        ,accounting_if_flag       -- ��v�h�e�t���O
        ,description              -- �E�v
        ,created_by               -- �쐬��
        ,creation_date            -- �쐬��
        ,last_updated_by          -- �ŏI�X�V��
        ,last_update_date         -- �ŏI�X�V��
        ,last_update_login        -- �ŏI�X�V۸޲�
        ,request_id               -- �v��ID
        ,program_application_id   -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,program_id               -- �ݶ��ĥ��۸���ID
        ,program_update_date      -- ��۸��эX�V��
        )
      SELECT xoh.object_header_id                                   object_header_id        -- ��������ID
            ,apps.xxcff_object_histories_s1.NEXTVAL                 history_num             -- �ύX����NO
            ,xoh.object_code                                        object_code             -- �����R�[�h
            ,xoh.lease_class                                        lease_class             -- ���[�X���
            ,xoh.lease_type                                         lease_type              -- ���[�X�敪
            ,xoh.re_lease_times                                     re_lease_times          -- �ă��[�X��
            ,xoh.po_number                                          po_number               -- �����ԍ�
            ,xoh.registration_number                                registration_number     -- �o�^�ԍ�
            ,xoh.age_type                                           age_type                -- �N��
            ,xoh.model                                              model                   -- �@��
            ,xoh.serial_number                                      serial_number           -- �@��
            ,xoh.quantity                                           quantity                -- ����
            ,xoh.manufacturer_name                                  manufacturer_name       -- ���[�J�[��
            ,xoh.department_code                                    department_code         -- �Ǘ�����R�[�h
            ,xoh.owner_company                                      owner_company           -- �{�Ё^�H��
            ,xoh.installation_address                               installation_address    -- ���ݒu�ꏊ
            ,xoh.installation_place                                 installation_place      -- ���ݒu��
            ,xoh.chassis_number                                     chassis_number          -- �ԑ�ԍ�
            ,xoh.re_lease_flag                                      re_lease_flag           -- �ă��[�X�v�t���O
            ,xoh.cancellation_type                                  cancellation_type       -- ���敪
            ,xoh.cancellation_date                                  cancellation_date       -- ���r����
            ,xoh.dissolution_date                                   dissolution_date        -- ���r���L�����Z����
            ,xoh.bond_acceptance_flag                               bond_acceptance_flag    -- �؏���̃t���O
            ,xoh.bond_acceptance_date                               bond_acceptance_date    -- �؏���̓�
            ,xoh.expiration_date                                    expiration_date         -- ������
            ,xoh.object_status                                      object_status           -- �����X�e�[�^�X
            ,xoh.active_flag                                        active_flag             -- �����L���t���O
            ,xoh.info_sys_if_date                                   info_sys_if_date        -- ���[�X�Ǘ����A�g��
            ,xoh.generation_date                                    generation_date         -- ������
            ,xoh.customer_code                                      customer_code           -- �ڋq�R�[�h
            ,LAST_DAY(TO_DATE(gt_period_name, cv_format_yyyy_mm))   accounting_date         -- �v���
            ,accounting_if_flag_2                                   accounting_if_flag      -- ��v�h�e�t���O
            ,cv_description || TO_CHAR(SYSDATE, cv_format_yyyymmdd) description             -- �E�v
            ,cn_created_by                                          created_by              -- �쐬��
            ,cd_creation_date                                       creation_date           -- �쐬��
            ,cn_last_updated_by                                     last_updated_by         -- �ŏI�X�V��
            ,cd_last_update_date                                    last_update_date        -- �ŏI�X�V��
            ,cn_last_update_login                                   last_update_login       -- �ŏI�X�V۸޲�
            ,cn_request_id                                          request_id              -- �v��ID
            ,cn_program_application_id                              program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
            ,cn_program_id                                          program_id              -- �ݶ��ĥ��۸���ID
            ,cd_program_update_date                                 program_update_date     -- ��۸��эX�V��
      FROM   xxcff_object_headers xoh
      WHERE  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ���[�X�����������쐬�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00102
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50023
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
  END insert_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_object
   * Description      : ���[�X�����̍X�V(A-5)
   ***********************************************************************************/
  PROCEDURE update_object(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_object'; -- �v���O������
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
    cv_object_status_103    CONSTANT VARCHAR2(3)   := '103';                 -- �ă��[�X�҂�
    cv_lease_type_2         CONSTANT VARCHAR2(1)   := '2';                   -- �ă��[�X
    cv_re_lease_flag_0      CONSTANT VARCHAR2(1)   := '0';                   -- �ă��[�X�v
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
    -- ***      ���[�X�����̍X�V           ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�����̍X�V
    -- =====================================
    BEGIN
      UPDATE xxcff_object_headers xoh   -- ���[�X����
      SET    xoh.object_status          = cv_object_status_103                   -- �����X�e�[�^�X
            ,xoh.lease_type             = cv_lease_type_2                        -- ���[�X�敪 2�F�ă��[�X
            ,xoh.re_lease_flag          = cv_re_lease_flag_0                     -- �ă��[�X�t���O 0:�v
            ,xoh.re_lease_times         = g_re_lease_times_tab(in_loop_cnt) + 1  -- �ă��[�X��
            ,xoh.expiration_date        = NULL                                   -- ������
            ,xoh.cancellation_type      = NULL                                   -- ���敪
            ,xoh.cancellation_date      = NULL                                   -- ���r����
            ,xoh.last_updated_by        = cn_last_updated_by                     -- �ŏI�X�V��
            ,xoh.last_update_date       = cd_last_update_date                    -- �ŏI�X�V��
            ,xoh.last_update_login      = cn_last_update_login                   -- �ŏI�X�V���O�C��
            ,xoh.request_id             = cn_request_id                          -- �v��ID
            ,xoh.program_application_id = cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xoh.program_id             = cn_program_id                          -- �R���J�����g�E�v���O����ID
            ,xoh.program_update_date    = cd_program_update_date                 -- �v���O�����X�V��
      WHERE  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ���[�X������񂪍X�V�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00195
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50014
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
  END update_object;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_lines
   * Description      : ���[�X�_�񖾍ׂ̃`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_lines(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
    ov_errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_lines'; -- �v���O������
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
    cv_contract_status_201    CONSTANT VARCHAR2(3)   := '201';       -- �o�^��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_contract_header_id          xxcff_contract_lines.contract_header_id%TYPE;       -- �_�����ID
    lt_contract_line_id            xxcff_contract_lines.contract_line_id%TYPE;         -- �_�񖾍ד���ID
    lt_contract_status             xxcff_contract_lines.contract_status%TYPE;          -- �_��X�e�[�^�X
    lt_contract_status_name        xxcff_contract_status_v.contract_status_name%TYPE;  -- �_��X�e�[�^�X��
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
    -- ***   ���[�X�_�񖾍ׂ̃`�F�b�N����  ***
    -- ***************************************
--
    -- =====================================
    -- ���[�X�_�񖾍ׂ̎擾
    -- =====================================
    BEGIN
      SELECT xcl.contract_header_id AS contract_header_id    -- �_�����ID
            ,xcl.contract_line_id   AS contract_header_id    -- �_�񖾍ד���ID
            ,xcl.contract_status    AS contract_status       -- �_��X�e�[�^�X
            ,( SELECT xcs.contract_status_name
               FROM   xxcff_contract_status_v xcs   -- �_��X�e�[�^�X�r���[
               WHERE  xcs.contract_status_code = xcl.contract_status
             )                      AS contract_status_name  -- �_��X�e�[�^�X��
      INTO   lt_contract_header_id
            ,lt_contract_line_id
            ,lt_contract_status
            ,lt_contract_status_name
      FROM   xxcff_contract_lines xcl                -- ���[�X�_�񖾍�
      WHERE  EXISTS (
                     SELECT 1
                     FROM   xxcff_contract_headers xch      -- ���[�X�_�񖾍�
                     WHERE  xch.contract_header_id = xcl.contract_header_id
                     AND    xcl.object_header_id   = g_object_header_id_tab(in_loop_cnt)      -- ��������ID
                     AND    xch.re_lease_times     = g_re_lease_times_tab(in_loop_cnt)        -- �ă��[�X��
                    )
      FOR UPDATE NOWAIT
      ;
--
      -- �_��X�e�[�^�X��201�̏ꍇ�͌x��
      IF ( lt_contract_status = cv_contract_status_201 ) THEN
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00240
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �擾�����_�����ID�A�_�񖾍ד���ID�A�_��X�e�[�^�X���Z�b�g
      g_contract_header_id_tab(in_loop_cnt)   := lt_contract_header_id;
      g_contract_line_id_tab(in_loop_cnt)     := lt_contract_line_id;
      g_contract_status_tab(in_loop_cnt)      := lt_contract_status;
      g_contract_status_name_tab(in_loop_cnt) := lt_contract_status_name;
--
    EXCEPTION
      WHEN lock_expt THEN
        -- ���[�X�_�񖾍׃e�[�u�������b�N�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50030
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        -- ���[�X�_�񖾍׏�񂪎擾�ł��Ȃ��ꍇ�͌x��
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00165
                        ,iv_token_name1  => cv_tkn_get
                        ,iv_token_value1 => cv_msg_cff_50220
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
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
  END get_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �����R�[�h�`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE chk_param(
    in_loop_cnt              IN  NUMBER,        --   ���[�v�J�E���^
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
    cv_object_status_102    CONSTANT VARCHAR2(3)   := '102';                 -- �_���
    cv_object_status_104    CONSTANT VARCHAR2(3)   := '104';                 -- �ă��[�X�_���
    cv_object_status_107    CONSTANT VARCHAR2(3)   := '107';                 -- ����
    cv_object_status_110    CONSTANT VARCHAR2(3)   := '110';                 -- ���r���i���ȓs���j
    cv_object_status_111    CONSTANT VARCHAR2(3)   := '111';                 -- ���r���i�ی��Ή��j
    cv_object_status_112    CONSTANT VARCHAR2(3)   := '112';                 -- ���r���i�����j
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_object_header_id     xxcff_object_headers.object_header_id%TYPE;      -- ��������ID
    lt_object_status        xxcff_object_headers.object_status%TYPE;         -- �����X�e�[�^�X
    lt_object_status_name   xxcff_object_status_v.object_status_name%TYPE;   -- �����X�e�[�^�X
    lt_re_lease_times       xxcff_object_headers.re_lease_times%TYPE;        -- �ă��[�X��
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
    -- �f�[�^�̑��݃`�F�b�N
    -- =====================================
    -- 1.���[�X�������̎擾
    BEGIN
      SELECT xoh.object_header_id AS object_header_id    -- ��������ID
            ,xoh.object_status    AS object_status       -- �����X�e�[�^�X
            ,( SELECT xos.object_status_name
               FROM   xxcff_object_status_v xos     -- �����X�e�[�^�X�r���[
               WHERE  xos.object_status_code = xoh.object_status
             )                    AS object_status_name  -- �����X�e�[�^�X��
            ,xoh.re_lease_times   AS re_lease_times      -- �ă��[�X��
      INTO   lt_object_header_id
            ,lt_object_status
            ,lt_object_status_name
            ,lt_re_lease_times
      FROM   xxcff_object_headers xoh                -- ���[�X����
      WHERE  xoh.object_code = g_file_upload_if_data_tab(in_loop_cnt)
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN lock_expt THEN
        -- ���[�X�����e�[�u�������b�N�ł��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_xxcff00007
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_msg_cff_50014
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN NO_DATA_FOUND THEN
        -- ���[�X������񂪎擾�ł��Ȃ��ꍇ�͌x��
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00123
                        ,iv_token_name1  => cv_tkn_column
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ���[�X������񂪎擾�ł����ꍇ
    IF ( ov_retcode = cv_status_normal ) THEN
      -- 2.�����X�e�[�^�X�̃`�F�b�N
      -- 2-1.�����X�e�[�^�X���u102�F�_��ρv�u104�F�ă��[�X�_��ρv�u107�F�����v�u110�F���r���(���ȓs��)�v
      -- �u111�F���r���(�ی��Ή�)�v�u112�F���r���(����)�v�̂����ꂩ�̏ꍇ
      IF ( lt_object_status IN ( cv_object_status_102         -- �_���
                                ,cv_object_status_104         -- �ă��[�X�_���
                                ,cv_object_status_107         -- ����
                                ,cv_object_status_110         -- ���r���i���ȓs���j
                                ,cv_object_status_111         -- ���r���i�ی��Ή��j
                                ,cv_object_status_112) ) THEN -- ���r���i�����j
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00237
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                        ,iv_token_name2  => cv_tkn_object_status
                        ,iv_token_value2 => lt_object_status_name
                        ,iv_token_name3  => cv_tkn_re_lease_times
                        ,iv_token_value3 => lt_re_lease_times
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
--
        -- �擾������������ID�ƍă��[�X�񐔂��Z�b�g
        g_object_header_id_tab(in_loop_cnt) := lt_object_header_id;
        g_re_lease_times_tab(in_loop_cnt)   := lt_re_lease_times;
--
      -- 2-2.�����X�e�[�^�X��2-1�ȊO�̏ꍇ
      ELSE
        -- �x��
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_xxcff00238
                        ,iv_token_name1  => cv_tkn_object_code
                        ,iv_token_value1 => g_file_upload_if_data_tab(in_loop_cnt)
                        ,iv_token_name2  => cv_tkn_object_status
                        ,iv_token_value2 => lt_object_status_name
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
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
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    --�t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- �t�@�C��ID
     ,ov_file_data => g_file_upload_if_data_tab  -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_app_name                       -- XXCFF
                                                    ,cv_msg_xxcff00094                    -- ���ʊ֐��G���[
                                                    ,cv_tkn_func_name                     -- �g�[�N��'FUNC_NAME'
                                                    ,cv_msg_cff_50131 )                   -- BLOB�f�[�^�ϊ��p�֐�
                                                    || cv_msg_part
                                                    || lv_errmsg                          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000)
      ;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       --   1.�t�@�C��ID
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
    -- ���[�X���
    cv_les_kind_fin        CONSTANT VARCHAR2(1)   := '0';                 -- Fin���[�X
--
    -- *** ���[�J���ϐ� ***
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- �擾�t�@�C����
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
      --�A�b�v���[�hCSV�t�@�C�����擾
      SELECT xfu.file_name    AS file_name
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface  xfu
      WHERE  xfu.file_id = in_file_id
      ;
--
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG      --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
       ,buff   => xxccp_common_pkg.get_msg(cv_app_name,   cv_msg_xxcff00167
                                          ,cv_tkn_file_name, cv_msg_cff_50284
                                          ,cv_tkn_csv_name,  lv_file_name)
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => xxccp_common_pkg.get_msg(cv_app_name, cv_msg_xxcff00167
                                          ,cv_tkn_file_name, cv_msg_cff_50284
                                          ,cv_tkn_csv_name,  lv_file_name)
      );
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ���[�X�䒠�ŏI�N���[�Y���Ԏ擾
    -- ============================================
    BEGIN
      SELECT  MAX(fdp.period_name)     AS  period_name        -- ���Ԗ���
      INTO    gt_period_name                                  -- ���[�X�䒠�I�[�v������
      FROM    fa_deprn_periods      fdp                       -- �������p����
             ,xxcff_lease_kind_v    xlkv                      -- ���[�X��ރr���[
      WHERE   fdp.book_type_code    = xlkv.book_type_code     -- ���Y�䒠�R�[�h
      AND     xlkv.lease_kind_code  = cv_les_kind_fin         -- ���[�X��ރR�[�h�iFin���[�X�j
      AND     fdp.period_close_date IS NOT NULL               -- �N���[�Y���ꂽ��v����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_app_name         -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_xxcff00186   -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
    in_file_id                IN    NUMBER,          --   1.�t�@�C��ID
    iv_file_format            IN    VARCHAR2,        --   2.�t�@�C���t�H�[�}�b�g
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
    cv_contract_status_204    CONSTANT VARCHAR2(3)   := '204';       -- ����
    cv_contract_status_206    CONSTANT VARCHAR2(3)   := '206';       -- ���r���(���ȓs��)
    cv_contract_status_207    CONSTANT VARCHAR2(3)   := '207';       -- ���r���(�ی��Ή�)
    cv_contract_status_208    CONSTANT VARCHAR2(3)   := '208';       -- ���r���(����)
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt               NUMBER;                                -- ���[�v���̃J�E���g
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
    ln_loop_cnt                 := 0;
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
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D�t�@�C���A�b�v���[�hIF�f�[�^�擾����
    -- ============================================
--
    get_upload_data(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���C�����[�v1
    <<MAIN_LOOP_1>>
    FOR ln_loop_cnt IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP
--
      --�P�s�ڂ̏ꍇ�J�����s�̏����ƂȂ�ׁA�X�L�b�v���ĂQ�s�ڂ̏����ɑJ�ڂ���
      IF ( ln_loop_cnt <> 1 ) THEN
--
        -- �Ώی����̎擾
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ============================================
        -- A-3�D�����R�[�h�`�F�b�N����
        -- ============================================
--
        chk_param(
           ln_loop_cnt               --   ���[�v�J�E���^
          ,lv_errbuf                 --   �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                --   ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg                 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSE
          -- ============================================
          -- A-4�D���[�X�_�񖾍ׂ̃`�F�b�N����
          -- ============================================
--
          get_contract_lines(
             ln_loop_cnt       -- ���[�v�J�E���^
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
          END IF;
        END IF;
      END IF;
    END LOOP MAIN_LOOP_1;
--
    -- �Ώی�����0�̏ꍇ�A�G���[
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_xxcff00165
                     ,iv_token_name1  => cv_tkn_get
                     ,iv_token_value1 => cv_msg_cff_50175
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����1���ȏ゠��A�X�L�b�v������0�̎�
    IF (  gn_target_cnt > 0 
      AND gn_warn_cnt   = 0 ) THEN
      -- ���C�����[�v2
      <<MAIN_LOOP_2>>
      FOR ln_loop_cnt IN 2 .. g_object_header_id_tab.LAST LOOP
        -- ============================================
        -- A-5�D���[�X�����̍X�V
        -- ============================================
--
        update_object(
           ln_loop_cnt       -- ���[�v�J�E���^
          ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ============================================
        -- A-6�D���[�X���������̍쐬
        -- ============================================
--
        insert_object_histories(
           ln_loop_cnt       -- ���[�v�J�E���^
          ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �_�񖾍ׂ̃X�e�[�^�X�`�F�b�N
        -- 1.�X�e�[�^�X���u204�F�����v�u206�F���r���(���ȓs��)�v�A�u207�F���r���(�ی��Ή�)�v�u208�F���r���(����)�v�̏ꍇ
        IF ( g_contract_status_tab(ln_loop_cnt) IN ( cv_contract_status_204          -- ����
                                                    ,cv_contract_status_206          -- ���r���(���ȓs��)
                                                    ,cv_contract_status_207          -- ���r���(�ی��Ή�)
                                                    ,cv_contract_status_208 ) ) THEN -- ���r���(����)
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_xxcff00239
                          ,iv_token_name1  => cv_tkn_object_code
                          ,iv_token_value1 => g_file_upload_if_data_tab(ln_loop_cnt)
                          ,iv_token_name2  => cv_tkn_contract_status
                          ,iv_token_value2 => g_contract_status_name_tab(ln_loop_cnt)
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
        -- 2.�X�e�[�^�X��1�ȊO�i�u202�F�_��v�u203�F�ă��[�X�v�j�̏ꍇ
        ELSE
          -- ============================================
          -- A-7�D���[�X�_�񖾍ׂ̍X�V
          -- ============================================
--
          update_contract_lines(
             ln_loop_cnt       -- ���[�v�J�E���^
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-8�D���[�X�_�񖾍ח����̍쐬
          -- ============================================
--
          insert_contract_histories(
             ln_loop_cnt       -- ���[�v�J�E���^
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-9�D�x���v��̍X�V
          -- ============================================
--
          update_pay_planning(
             ln_loop_cnt       -- ���[�v�J�E���^
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP MAIN_LOOP_2;
    END IF;
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
    in_file_id                IN    NUMBER,          --   1.�t�@�C��ID(�K�{)
    iv_file_format            IN    VARCHAR2         --   2.�t�@�C���t�H�[�}�b�g(�K�{)
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
       in_file_id                 --   1.�t�@�C��ID
      ,iv_file_format             --   2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf                  --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                 --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ============================================
    -- A-10�D�I������
    -- ============================================
    BEGIN
      -- �t�@�C���A�b�v���[�hI/F�e�[�u�����폜
      DELETE 
      FROM   xxccp_mrp_file_ul_interface  xmfui    --�t�@�C���A�b�v���[�hI/F�e�[�u��
      WHERE  xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_app_name               -- 'XXCFF'
                                                       ,cv_msg_xxcff00104         -- �폜�G���[
                                                       ,cv_tkn_table              -- �g�[�N��'TABLE_NAME'
                                                       ,cv_msg_cff_50175          -- �t�@�C���A�b�v���[�hI/F�e�[�u��
                                                       ,cv_tkn_info               -- �g�[�N��'INFO'
                                                       ,SUBSTRB(SQLERRM,1,2000) ) -- ���b�Z�[�W
                                                       ,1
                                                       ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
        errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        RAISE global_api_others_expt;
    END;
--
    -- �X�L�b�v�Ώۂ̕��������݂����ꍇ
    IF ( gn_warn_cnt > 0 ) THEN
      -- �X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    END IF;
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
END XXCFF016A37C;
/
