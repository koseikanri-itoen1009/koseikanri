CREATE OR REPLACE PACKAGE BODY XXCSO015A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A04C(spec)
 * Description      : ���_�������ɂ��ڋq�}�X�^�̋��_�R�[�h���ύX�ɂȂ��������}�X�^�̏��Ɣp���\���A
 *                    �p�����ق̍�ƈ˗��������̋@�Ǘ��V�X�e���ɘA�g���܂��B
 *                    
 * MD050            : MD050_CSO_015_A04_���̋@-EBS�C���^�t�F�[�X�F�iOUT�j�����}�X�^���
 *                    
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  get_profile_info            �v���t�@�C���l�擾 (A-2)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-3)
 *  chk_str                     �֑������`�F�b�N (A-6,A-10)
 *  update_item_instance        ���_�ύX�����}�X�^���X�V (A-7)
 *  create_csv_rec              CSV�t�@�C���o�� (A-8,A-13)
 *  update_wk_reqst_tbl         ��ƈ˗��^������񏈗����ʃe�[�u���X�V(A-12)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-14)
 *  submain                     ���C�������v���V�[�W��
 *                                �Z�[�u�|�C���g(�t�@�C���N���[�Y���s�p)���s(A-4)
 *                                ���_�ύX�����}�X�^��񒊏o (A-5)
 *                                �p����ƈ˗����f�[�^���o(A-9)
 *                                �Z�[�u�|�C���g(�p����ƈ˗����A�g���s)���s(A-11)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-06    1.0   kyo              �V�K�쐬
 *  2009-03-13    1.1   abe              ���_�ύX�f�[�^�̏�Q���Ή�
 *  2009-03-16    1.2   N.Yabuki         ��ƈ˗��^������񏈗����ʃe�[�u����WHO�J�����X�V�����ǉ�
 *  2009-04-13    1.3   K.Satomura       �V�X�e���e�X�g��Q�Ή�(T1_0409)
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
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
--
  gv_csv_process_kbn        VARCHAR2(100);              -- ���_�ύX�E�p�����CSV�o�͏����敪
  gv_date_value             VARCHAR2(100);              -- �������t
--
--################################  �Œ蕔 END   ##################################
--
    -- ���o���e��(����^�C�v�̎���^�C�vID)
    cv_csi_txn_types          CONSTANT VARCHAR2(100) := '����^�C�v�̎���^�C�vID';

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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO015A04C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- �A�N�e�B�u
  cv_csv_proc_kbn_1      CONSTANT VARCHAR2(1)   := '1';             -- �p�����o�͏���
  cv_csv_proc_kbn_2      CONSTANT VARCHAR2(1)   := '2';             -- ���_�ύX�o�͏���
  cv_language            CONSTANT VARCHAR2(10)  := 'JA';            -- ����
  cv_disposal_sinsei     CONSTANT VARCHAR2(10)  := '60';            -- �p���\��
  cv_disposal_kessai     CONSTANT VARCHAR2(10)  := '70';            -- �p������
  cv_status_app          CONSTANT VARCHAR2(10)  := 'APPROVED';      -- ���F�X�e�[�^�X
  cv_interface_flag_n    CONSTANT VARCHAR2(10)  := 'N';             -- �A�g�σt���O
  cv_interface_flag_y    CONSTANT VARCHAR2(10)  := 'Y';             -- �A�g�σt���O  
  cv_src_transaction_type CONSTANT VARCHAR2(10)  := 'IB_UI';      -- �\�[�X�g�����U�N�V�����^�C�v
  
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00226';  -- �p�����[�^�o��
  cv_tkn_number_02  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00227';
    -- �p�����[�^�s���G���[�i���_�ύX�E�p�����CSV�o�͏����敪�j
  cv_tkn_number_03  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������擾�G���[���b�Z�[�W
  cv_tkn_number_04  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �C���^�[�t�F�[�X�t�@�C����
  cv_tkn_number_05  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_tkn_number_06  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSV�t�@�C���c���G���[���b�Z�[�W
  cv_tkn_number_07  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_tkn_number_08  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_tkn_number_09  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00190';  -- �ǉ������l�Ȃ��x�����b�Z�[�W
  cv_tkn_number_10  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00159';  -- �֑������`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_12  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00194';  -- CSV�t�@�C���o�̓G���[���b�Z�[�W(�����}�X�^���)
  cv_tkn_number_13  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00196';
    -- ���b�N�G���[���b�Z�[�W(��ƈ˗��^������񏈗����ʃe�[�u��)
  cv_tkn_number_14  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00197';  -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_tkn_number_15  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00195';  -- CSV�o�̓G���[���b�Z�[�W(��ƈ˗����)
  cv_tkn_number_16  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00198';  -- �����}�X�^���A�g�ϐ��탁�b�Z�[�W(���_�ύX)
  cv_tkn_number_17  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00199';
    -- ��ƈ˗����A�g�ϐ��탁�b�Z�[�W(�p���\���A�p������)
  cv_tkn_number_18  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSV�t�@�C���N���[�Y�G���[���b�Z�[�W
  cv_tkn_number_19  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00493';  -- �p�����[�^�������t
  cv_tkn_number_20  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- ���t�����G���[
  cv_tkn_number_21  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00525';
    -- ���o�G���[���b�Z�[�W(��ƈ˗��^������񏈗����ʃe�[�u��)
  cv_tkn_number_22  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSV�t�@�C���o��0�����b�Z�[�W
    -- ����^�C�v�G���[
  cv_tkn_number_23        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- ����^�C�vID�擾�G���[
  cv_tkn_number_24        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- ����^�C�vID���o�G���[
  cv_tkn_number_25        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- �f�[�^�o�^�A�X�V���s

  -- �g�[�N���R�[�h
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';                -- �����R�[�h
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';               -- �G���[���b�Z�[�W
  cv_tkn_task_name       CONSTANT VARCHAR2(20) := 'TASK_NAME';             -- ���o���e
  cv_tkn_add_att_name    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';    -- �ǉ�������`��
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';             -- �v���t�@�C���E�I�v�V������
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';          -- CSV�t�@�C���o�͐� 
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';         -- CSV�t�@�C���� 
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';                  -- �`�F�b�N�Ώۍ��ږ�
  cv_tkn_item_value      CONSTANT VARCHAR2(20) := 'ITEM_VALUE';            -- �`�F�b�N�Ώۂ̒l
  cv_tkn_check_range     CONSTANT VARCHAR2(20) := 'CHECK_RANGE';           -- �`�F�b�N�͈�
  cv_tkn_req_line_id     CONSTANT VARCHAR2(50) := 'REQUISITION_LINE_ID';   -- �����˗�����ID
  cv_tkn_req_header_id   CONSTANT VARCHAR2(50) := 'REQUISITION_HEADER_ID'; -- �����˗��w�b�_ID
  cv_tkn_line_num        CONSTANT VARCHAR2(20) := 'LINE_NUM';              -- �����˗����הԍ�
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';                 -- ���o�f�[�^���e
  cv_tkn_csv_proc_kbn    CONSTANT VARCHAR2(20) := 'CSV_PROCESS_KBN'; -- �p�����[�^�l(���_�ύX�E�p�����CSV�o�͏����敪)
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';                 -- ���͒l
  cv_tkn_process         CONSTANT VARCHAR2(20) := 'PROCESS';               -- �v���Z�X
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';                -- ���^�[���X�e�[�^�X(���t�����`�F�b�N����)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';               -- ���b�Z�[�W 
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';

--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< ���̓p�����[�^ >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'gv_csv_process_kbn     = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := 'gv_date_value          = ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_file_dir        = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_file_name       = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����I�[�v�����܂��� >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< CSV�t�@�C�����N���[�Y���܂��� >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< ��O��������CSV�t�@�C�����N���[�Y���܂��� >>';
  cv_debug_msg_location   CONSTANT VARCHAR2(200) := '<<--�u���_�ύX�o�͏����v--';
  cv_debug_msg_dis        CONSTANT VARCHAR2(200) := '<<--�u�p�����o�͏����v--';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<<�J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'select_error_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gb_rollback_upd_flg    BOOLEAN;                                     -- ���[���o�b�N���f
  -- �t�@�C���E�n���h���̐錾
  gf_file_hand    UTL_FILE.FILE_TYPE;
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;        -- ����^�C�vID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���o�o�̓f�[�^
    TYPE g_value_rtype IS RECORD(
      external_reference        csi_item_instances.external_reference%TYPE,      -- �����R�[�h
      old_head_office_code      fnd_flex_values.ATTRIBUTE7%TYPE,                 -- ���{���R�[�h
      row_order                 fnd_flex_values.ATTRIBUTE6%TYPE,                 -- ���_���я�
      sale_base_code            xxcso_cust_accounts_v.sale_base_code%TYPE,       -- ���_(����)�R�[�h
      jotai_kbn3                VARCHAR2(100),                                   -- �@����(�p�����)
      haiki_date                VARCHAR2(100),                                   -- �p�����ٓ�
      requisition_line_id       xxcso_requisition_lines_v.requisition_line_id%TYPE, --�����˗�����ID
      requisition_header_id     xxcso_requisition_lines_v.requisition_header_id%TYPE, -- ���O�p�����˗��w�b�_ID
      line_num                  xxcso_requisition_lines_v.line_num%TYPE          -- ���O�p�����˗����הԍ�
    );
  --*** ���b�N��O ***
  global_lock_expt        EXCEPTION;                                 -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    od_process_date     OUT NOCOPY DATE,      -- �V�X�e�����t
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- �v���O������
--
    cv_false                CONSTANT VARCHAR2(100)   := 'FALSE';             -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ld_process_date      DATE;    -- �V�X�e�����t
    lb_check_date_value  BOOLEAN;          -- ���t�̏������f
    lv_format            VARCHAR2(100);    -- ���t����
    lv_init_msg          VARCHAR2(5000);   -- �G���[���b�Z�[�W���i�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    lv_format := 'YYYY/MM/DD';
    -- �N���p�����[�^���o��
    -- �p�����[�^�o��(���_�ύX�E�p�����CSV�o�͏����敪)
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_01
                    ,iv_token_name1  => cv_tkn_csv_proc_kbn
                    ,iv_token_value1 => gv_csv_process_kbn
                   );
    -- �o�̓t�@�C���ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                  lv_init_msg
    );
    -- �p�����[�^�������t
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_19
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => gv_date_value
                   );
    -- �o�̓t�@�C���ɏo��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_init_msg || CHR(10) ||
                 ''
    );
    -- ���_�ύX�E�p�����CSV�o�͏����敪���u�f1�f�p�����o�͏����v�A
    -- �����́f�u2�f���_�ύX�o�͏����v�ł��邩�̃`�F�b�N
    IF (NVL(gv_csv_process_kbn, ' ') <> cv_csv_proc_kbn_1 
          AND NVL(gv_csv_process_kbn, ' ') <> cv_csv_proc_kbn_2) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
             ,iv_name         => cv_tkn_number_02            -- ���b�Z�[�W�R�[�h
             ,iv_token_name1  => cv_tkn_csv_proc_kbn
             ,iv_token_value1 => gv_csv_process_kbn
      );
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
--
    END IF;      
    -- �p�����[�^�������t���uNULL�v�ł��邩�̃`�F�b�N
    IF (gv_date_value IS NOT NULL) THEN
      -- ���t�����`�F�b�N
      --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
      lb_check_date_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_date_value
                                   ,iv_date_format  => lv_format
      );
      --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
      IF (lb_check_date_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_20          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                        ,iv_token_value1 => gv_date_value             -- �g�[�N���l1�p�����[�^
                        ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                        ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                        ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �Ɩ��������t�擾���� 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg4 || CHR(10) ||
                 cv_debug_msg5 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- �A�v���P�[�V�����Z�k��
             ,iv_name         => cv_tkn_number_03            -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    od_process_date := ld_process_date;
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => 'od_process_date:' || od_process_date || CHR(10) ||
                 ''
    );

    -- ====================
    -- ����^�C�vID�擾���� 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id                                    -- �g�����U�N�V�����^�C�vID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                          -- ����^�C�v
      WHERE  ctt.source_transaction_type  = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l���擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSV�t�@�C���o�͐�
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSV�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- �v���O������
--
      -- �C���^�[�t�F�[�X�t�@�C�����g�[�N����
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_VM_OUT_CSV_DIR';          -- CSV�t�@�C���o�͐�
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_VM_OUT_CSV_BUKKEN_INFO';  -- CSV�t�@�C����

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
    -- *** ���[�J���ϐ� ***
    lv_file_dir       VARCHAR2(2000);             -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(2000);             -- CSV�t�@�C����
    lv_msg_set        VARCHAR2(1000);             -- ���b�Z�[�W�i�[
    lv_value          VARCHAR2(1000);             -- �v���t�@�C���I�v�V�����l
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �v���t�@�C���l���擾
    -- ===============================
--
    -- �ϐ����������� 
    lv_value := NULL;
--    
    -- CSV�t�@�C���o�͐�̒l�擾
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSV�t�@�C�����̒l�擾
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6 || CHR(10) ||
                 cv_debug_msg7 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg8 || lv_file_name   || CHR(10) ||
                 ''
    );
    --�C���^�[�t�F�[�X�t�@�C�������b�Z�[�W�o��
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_04
                    ,iv_token_name1  => cv_tkn_csv_file_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- �߂�l���uNULL�v�ł������ꍇ,��O�������s��
    IF (lv_file_dir IS NULL) THEN
      -- CSV�t�@�C���o�͐�
      lv_value     := cv_file_dir;
    ELSIF (lv_file_name IS NULL) THEN
      -- CSV�t�@�C����
      lv_value     := cv_file_name;
    END IF;
--
    IF (lv_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_05         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prof_name         -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_value                 -- �g�[�N���l1���g���_�R�[�h
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;    
    END IF;
--
    -- �擾�����l��OUT�p�����[�^�ɐݒ�
    ov_file_dir   := lv_file_dir;       -- CSV�t�@�C���o�͐�
    ov_file_name  := lv_file_name;      -- CSV�t�@�C����
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : CSV�t�@�C���I�[�v�� (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- CSV�t�@�C���o�͐�
    iv_file_name            IN  VARCHAR2,               -- CSV�t�@�C����
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- �v���O������
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- ���o�̓��[�h

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
    -- *** ���[�J���ϐ� ***
    lv_file_dir       VARCHAR2(1000);      -- CSV�t�@�C���o�͐�
    lv_file_name      VARCHAR2(1000);      -- CSV�t�@�C����
    lv_exists         BOOLEAN;             -- ���݃`�F�b�N����
    lv_file_length    VARCHAR2(1000);      -- �t�@�C���T�C�Y
    lv_blocksize      VARCHAR2(1000);      -- �u���b�N�T�C�Y
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    lv_file_dir   := iv_file_dir;       -- CSV�t�@�C���o�͐�
    lv_file_name  := iv_file_name;      -- CSV�t�@�C����
    -- ========================
    -- CSV�t�@�C�����݃`�F�b�N 
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSV�t�@�C�������݂����ꍇ
    IF (lv_exists = cb_true) THEN
      -- CSV�t�@�C���c���G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_06         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                        ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                        ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
      );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE file_err_expt;
    END IF;
--    
    -- CSV�t�@�C���I�[�v�� 
    BEGIN
--
      -- �t�@�C��ID���擾
      gf_file_hand := UTL_FILE.FOPEN(
                           location   => lv_file_dir
                          ,filename   => lv_file_name
                          ,open_mode  => cv_open_writer
      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg10    || CHR(10)   ||
                   cv_debug_msg_fnm  || lv_file_name || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- �t�@�C���p�X�s���G���[
           UTL_FILE.INVALID_MODE       OR       -- open_mode�p�����[�^�s���G���[
           UTL_FILE.INVALID_OPERATION  OR       -- �I�[�v���s�\�G���[
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE�l�����G���[
        -- CSV�t�@�C���I�[�v���G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_07         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_location      -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_file_dir              -- �g�[�N���l1CSV�t�@�C���o�͐�
                      ,iv_token_name2  => cv_tkn_csv_file_name     -- �g�[�N���R�[�h1
                      ,iv_token_value2 => lv_file_name             -- �g�[�N���l1CSV�t�@�C����
        );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      -- �擾�����l��OUT�p�����[�^�ɐݒ�
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : chk_str
   * Description      : �֑������`�F�b�N (A-6,A-10)
   ***********************************************************************************/
  PROCEDURE chk_str(
    i_get_rec       IN g_value_rtype,                  -- ���f�[�^
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'chk_str';       -- �v���O������
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
--
    cv_check_range             CONSTANT  VARCHAR2(30)  := 'VENDING_MACHINE_SYSTEM';
    cv_account_master          CONSTANT VARCHAR2(100)  := '�ڋq�}�X�^';
    cv_external_reference      CONSTANT VARCHAR2(100)  := '�����R�[�h';
    cv_old_head_office_code    CONSTANT VARCHAR2(100)  := '���{���R�[�h';
    cv_row_order               CONSTANT VARCHAR2(100)  := '���_���я�';
    cv_sale_base_code          CONSTANT VARCHAR2(100)  := '���_(����)�R�[�h';
    cv_jotai_kbn3              CONSTANT VARCHAR2(100)  := '�@����(�p�����)';
    cv_haiki_date              CONSTANT VARCHAR2(100)  := '�p�����ٓ�';
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lb_str_check_flg         BOOLEAN;         -- �֑������`�F�b�N�t���O
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;            -- ���f�[�^
    -- *** ���[�J����O ***
    select_error_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    l_get_rec := i_get_rec;
    -- �֑������`�F�b�N
    -- �����R�[�h
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.external_reference, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_external_reference          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.external_reference   -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- ���{���R�[�h
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.old_head_office_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_old_head_office_code        -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.old_head_office_code -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- ���_���я�
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.row_order, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_row_order                   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.row_order            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- ���_(����)�R�[�h
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.sale_base_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_sale_base_code              -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.sale_base_code       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- �@����3(�p�����)
    -- �p�����ٓ�
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.jotai_kbn3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_jotai_kbn3                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.jotai_kbn3           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- �p�����ٓ�
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.haiki_date, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_10               -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_haiki_date                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_value              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => l_get_rec.haiki_date           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_check_range             -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_check_range                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN select_error_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_str;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instance
   * Description      : ���_�ύX�����}�X�^���X�V (A-7)
   ***********************************************************************************/
  PROCEDURE update_item_instance(
    in_instance_id           IN  csi_item_instances.instance_id%TYPE,           -- �C���X�^���XID
    in_object_version_number IN csi_item_instances.object_version_number%TYPE,  -- �I�u�W�F�N�g�o�[�W����
    iv_external_reference    IN csi_item_instances.external_reference%TYPE,     -- �����R�[�h
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'update_item_instance';       -- �v���O������
    cn_api_version             CONSTANT NUMBER         := 1.0;
    cv_inst_base_update        CONSTANT VARCHAR2(100)  := '�����}�X�^';
    cv_update_process          CONSTANT VARCHAR2(100)  := '�X�V';
    cv_encoded_f               CONSTANT VARCHAR2(1)    := 'F';  -- FALSE   
--
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_commit                VARCHAR2(1);     -- �R�~�b�g�t���O
    lv_init_msg_list         VARCHAR2(2000);  -- ���b�Z�[�W���X�g
    ln_validation_level        NUMBER;                  -- �o���f�[�V�������[�x��
    -- API�߂�l�i�[�p
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
    lv_io_msg_data             VARCHAR2(5000); 

    -- API���o�̓��R�[�h�l�i�[�p
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
    l_instance_id_lst          csi_datastructures_pub.id_tbl;
--
    -- *** ���[�J����O ***
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
--
--###########################  �Œ蕔 END   ############################
--
    -- �C���X�^���X���R�[�h�쐬
    l_instance_rec.instance_id                := in_instance_id;               -- �C���X�^���XID
    l_instance_rec.object_version_number      := in_object_version_number;     -- �I�u�W�F�N�g�o�[�W�����ԍ�
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
    l_instance_rec.attribute7                 := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    -- ������R�[�h�f�[�^�쐬
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;

    BEGIN
      CSI_ITEM_INSTANCE_PUB.update_item_instance(
         p_api_version           => cn_api_version
        ,p_commit                => lv_commit
        ,p_init_msg_list         => lv_init_msg_list
        ,p_validation_level      => ln_validation_level
        ,p_instance_rec          => l_instance_rec
        ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
        ,p_party_tbl             => l_party_tab
        ,p_account_tbl           => l_account_tab
        ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
        ,p_org_assignments_tbl   => l_org_assignments_tab
        ,p_asset_assignment_tbl  => l_asset_assignment_tab
        ,p_txn_rec               => l_txn_rec
        ,x_instance_id_lst       => l_instance_id_lst
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      -- ����I���łȂ��ꍇ
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        IF (FND_MSG_PUB.Count_Msg > 0) THEN
          FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
            FND_MSG_PUB.Get(
               p_msg_index     => i
              ,p_encoded       => cv_encoded_f
              ,p_data          => lv_io_msg_data
              ,p_msg_index_out => ln_io_msg_count
            );
            lv_msg_data := lv_msg_data || lv_io_msg_data;
          END LOOP;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_inst_base_update           -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_update_process             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_bukken                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => iv_external_reference         -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                       ,iv_token_value4  => lv_msg_data                   -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_item_instance;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSV�t�@�C���o�� (A-8,A-13)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- ���f�[�^
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- �v���O������
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
--
    cv_up_99999             CONSTANT VARCHAR2(50)   := '99999';                -- �X�V�S���҃R�[�h
    cv_up_999999            CONSTANT VARCHAR2(50)   := '999999';               -- �X�V�����R�[�h
    cv_up_pro_id            CONSTANT VARCHAR2(50)   := 'BUKKEN_2UD';           -- �X�V�v���O����ID
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_data          VARCHAR2(5000);                -- �ҏW�f�[�^
    lv_suc_msg       VARCHAR2(5000);                -- �A�g�ϐ��탁�b�Z�[�W
    lt_external_reference  csi_item_instances.external_reference%TYPE;  -- �����R�[�h
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;                  -- ���f�[�^
    -- *** ���[�J����O ***
    file_put_line_expt             EXCEPTION;       -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    l_get_rec             := i_get_rec;               -- �f�[�^���i�[���郌�R�[�h
    lt_external_reference := REPLACE(l_get_rec.external_reference,'-');
--
    BEGIN
--
      --�f�[�^�쐬
      lv_data := cv_sep_wquot || lt_external_reference || cv_sep_wquot             -- �����R�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �@��
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �@��
        || cv_sep_com                                                              -- �@��敪
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���[�J�[
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �N��
        || cv_sep_com                                                              -- �Z����
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ����@�P
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ����@�Q
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ����@�R
        || cv_sep_com                                                              -- ����ݒu��
        || cv_sep_com                                                              -- �J�E���^�[No�D
        || cv_sep_com || cv_sep_wquot || l_get_rec.old_head_office_code
        || l_get_rec.row_order || cv_sep_wquot                                     -- �n��R�[�h
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code || cv_sep_wquot  -- ���_�i����j�R�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ��Ɖ�ЃR�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���Ə��R�[�h
        || cv_sep_com                                                              -- �ŏI��Ɠ`�[No�D
        || cv_sep_com                                                              -- �ŏI��Ƌ敪
        || cv_sep_com                                                              -- �ŏI��Ɛi��
        || cv_sep_com                                                              -- �ŏI��Ɗ����\���
        || cv_sep_com                                                              -- �ŏI��Ɗ�����
        || cv_sep_com                                                              -- �ŏI�������e
        || cv_sep_com                                                              -- �ŏI�ݒu�`�[No�D
        || cv_sep_com                                                              -- �ŏI�ݒu�敪
        || cv_sep_com                                                              -- �ŏI�ݒu�\���
        || cv_sep_com                                                              -- �ŏI�ݒu�i��
        || cv_sep_com                                                              -- �@���ԂP�i�ғ���ԁj
        || cv_sep_com                                                              -- �@���ԂQ�i��ԏڍׁj
        || cv_sep_com || SUBSTR(l_get_rec.jotai_kbn3,1,1)                          -- �@���ԂR�i�p�����j
        || cv_sep_com                                                              -- ���ɓ�
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���g��ЃR�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���g���Ə��R�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu�於
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��S���Җ�
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��TEL�P
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��TEL�Q
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��TEL�R
        || cv_sep_com                                                              -- �ݒu��X�֔ԍ�
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��Z���P
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��Z���Q
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��Z���R
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��Z���S
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �ݒu��Z���T
        || cv_sep_com || l_get_rec.haiki_date                                      -- �p�����ٓ�
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �]���p���Ǝ�
        || cv_sep_com                                                              -- �]���p���`�[No.
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���L��
        || cv_sep_com                                                              -- ���[�X�J�n��
        || cv_sep_com                                                              -- ���[�X��
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���_��ԍ�
        || cv_sep_com                                                              -- ���_��ԍ��|�}��
        || cv_sep_com                                                              -- ���_���
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- ���_��ԍ�
        || cv_sep_com                                                              -- ���_��ԍ��|�}��
        || cv_sep_com                                                              -- �]���p���󋵃t���O
        || cv_sep_com                                                              -- �]�������敪
        || cv_sep_com                                                              -- �폜�t���O
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �쐬�S���҃R�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �쐬�����R�[�h
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- �쐬�v���O����ID
        || cv_sep_com || cv_sep_wquot || cv_up_99999 || cv_sep_wquot               -- �X�V�S���҃R�[�h
        || cv_sep_com || cv_sep_wquot || cv_up_999999 || cv_sep_wquot              -- �X�V�����R�[�h
        || cv_sep_com || cv_sep_wquot || cv_up_pro_id || cv_sep_wquot              -- �X�V�v���O����ID
        || cv_sep_com                                                              -- �쐬���������b
        || cv_sep_com || TO_CHAR(SYSDATE, 'yyyymmddhh24miss')                      -- �X�V���������b
      ;
      -- �f�[�^�o��
      UTL_FILE.PUT_LINE(
         file   => gf_file_hand
        ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- �t�@�C���E�n���h�������G���[
           UTL_FILE.INVALID_OPERATION  OR     -- �I�[�v���s�\�G���[
           UTL_FILE.WRITE_ERROR  THEN         -- �����ݑ��쒆�I�y���[�e�B���O�G���[
        IF (gv_csv_process_kbn = cv_csv_proc_kbn_2) THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_bukken                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => l_get_rec.external_reference    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                         -- �g�[�N���l2
                      );
        ELSE
          -- �G���[���b�Z�[�W�擾
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_15                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_req_line_id                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(l_get_rec.requisition_line_id)   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_req_header_id                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(l_get_rec.requisition_header_id) -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_line_num                          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(l_get_rec.line_num)              -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg                  -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                         -- �g�[�N���l4
                      );
        END IF;
        lv_errbuf := lv_errmsg;
      RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_put_line_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : update_wk_reqst_tbl
   * Description      : ��ƈ˗��^������񏈗����ʃe�[�u���X�V (A-12)
   ***********************************************************************************/
  PROCEDURE update_wk_reqst_tbl(
     i_get_rec         IN g_value_rtype     -- ���o�o�̓f�[�^
    ,id_process_date   IN DATE              -- �Ɩ�������
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W              --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h                --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'update_wk_reqst_tbl';    -- �v���O������
--
    cv_work_ipro_table  CONSTANT VARCHAR2(100) := '��ƈ˗��^������񏈗����ʃe�[�u��';
    cv_process_upd      CONSTANT VARCHAR2(100) := '�X�V';
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
    -- *** ���[�J���ϐ� ***
    ld_process_date  DATE;                                                  -- �Ɩ�������
    lt_req_line_id   xxcso_requisition_lines_v.requisition_line_id%TYPE;    -- �����˗�����ID
    lt_req_header_id       xxcso_requisition_lines_v.requisition_header_id%TYPE; -- ���O�p�����˗��w�b�_ID
    lt_line_num            xxcso_requisition_lines_v.line_num%TYPE;         -- ���O�p�����˗����הԍ�
    -- *** ���[�J���E���R�[�h ***
    l_get_rec       g_value_rtype;                  -- ���f�[�^
    -- *** ���[�J����O ***
    skip_process_expt             EXCEPTION;       -- �f�[�^�o�͏�����O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�����[�J���ϐ��ɑ��
    l_get_rec        := i_get_rec;                       -- �f�[�^���i�[���郌�R�[�h
    ld_process_date  := id_process_date;                 -- �Ɩ�������
    lt_req_line_id   := l_get_rec.requisition_line_id;   -- �����˗�����ID
    lt_req_header_id := l_get_rec.requisition_header_id; -- ���O�p�����˗��w�b�_ID
    lt_line_num      := l_get_rec.line_num;              -- ���O�p�����˗����הԍ�
--
    BEGIN
      SELECT xwrp.requisition_line_id                    -- �����˗�����ID
      INTO lt_req_line_id
      FROM xxcso_wk_requisition_proc xwrp                -- ��ƈ˗��^������񏈗����ʃe�[�u��
      WHERE xwrp.requisition_line_id = lt_req_line_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_work_ipro_table            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_req_line_id            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(lt_req_line_id)       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_req_header_id          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(lt_req_header_id)     -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_line_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(lt_line_num)          -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_21              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_work_ipro_table            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_req_line_id            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(lt_req_line_id)       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_req_header_id          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(lt_req_header_id)     -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_line_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(lt_line_num)          -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_err_msg                -- �g�[�N���R�[�h5
                       ,iv_token_value5 => SQLERRM                       -- �g�[�N���l5
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
    -- ��ƈ˗��^������񏈗����ʃe�[�u���̘A�g�σt���O���X�V
    BEGIN

      UPDATE xxcso_wk_requisition_proc                 -- ��ƈ˗��^������񏈗����ʃe�[�u��
      SET    interface_flag         = cv_interface_flag_y        -- �A�g�σt���O
           , interface_date         = ld_process_date            -- �A�g��
           , last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
           , last_update_date       = cd_last_update_date        -- �ŏI�X�V��
           , last_update_login      = cn_last_update_login       -- �ŏI�X�V���O�C��
           , request_id             = cn_request_id              -- �v��ID
           , program_application_id = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           , program_id             = cn_program_id              -- �R���J�����g�E�v���O����ID
           , program_update_date    = cd_program_update_date     -- �v���O�����X�V��
      WHERE  requisition_line_id = lt_req_line_id
      ;
    EXCEPTION
      -- �X�V�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        gb_rollback_upd_flg := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_14              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_work_ipro_table            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_process_upd                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_req_line_id            -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(lt_req_line_id)       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_req_header_id          -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(lt_req_header_id)     -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(lt_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_err_msg                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                       -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN skip_process_expt THEN
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_wk_reqst_tbl;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSV�t�@�C���N���[�Y���� (A-14)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSV�t�@�C���o�͐�
    ,iv_file_name      IN  VARCHAR2         -- CSV�t�@�C����
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W              --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h                --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd   BOOLEAN;
    -- *** ���[�J����O ***
    file_err_expt   EXCEPTION;  -- �t�@�C��������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
    -- ====================
    -- CSV�t�@�C���N���[�Y 
    -- ====================
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- �I�y���[�e�B���O�V�X�e���G���[
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- �t�@�C���E�n���h�������G���[
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_18             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_csv_location          --�g�[�N���R�[�h1
                      ,iv_token_value1 => iv_file_dir                  --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_csv_file_name         --�g�[�N���R�[�h1
                      ,iv_token_value2 => iv_file_name                 --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err1 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err2 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
---- *** ���[�J���萔 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
--
    cv_false                CONSTANT VARCHAR2(100)   := 'FALSE';            -- FALSE
    cv_jotai_kbn3           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN3';       -- �@����3(�p�����)
    cv_haikikessai_dt       CONSTANT VARCHAR2(100)   := 'HAIKIKESSAI_DT';   -- �p�����ٓ�
    cv_final_format         CONSTANT VARCHAR2(100)   := 'yyyy/mm/dd';       -- ���t����
--
    cv_bukken_data          CONSTANT VARCHAR2(100)   := '�����}�X�^���';
    cv_work_ipro_data       CONSTANT VARCHAR2(100)   := '�p����ƈ˗����';
    cv_add_pro_data         CONSTANT VARCHAR2(100)   := '�ǉ������l';
    cv_bukken_cd            CONSTANT VARCHAR2(100)   := '�����R�[�h:';
    -- *** ���[�J���ϐ� ***
    lv_sub_retcode         VARCHAR2(1);                                 -- �T�[�u���C���p���^�[���E�R�[�h
    lv_sub_msg             VARCHAR2(5000);                              -- �x���p���b�Z�[�W
    lv_sub_buf             VARCHAR2(5000);                              -- �x���p�G���[�E���b�Z�[�W
    ld_process_date        DATE;                                        -- �Ɩ�������
    ld_process_date_t      DATE;                                        -- �Ɩ�������(TRUNC)
    lv_file_dir            VARCHAR2(2000);                              -- CSV�t�@�C���o�͐�
    lv_file_name           VARCHAR2(2000);                              -- CSV�t�@�C����
    lt_instance_id         csi_item_instances.instance_id%TYPE;         -- �C���X�^���XID
    lt_external_reference  csi_item_instances.external_reference%TYPE;  -- �����R�[�h
    lt_attribute1_cd       csi_item_instances.attribute1%TYPE;          -- �@��
    lt_cust_account_id     xxcso_cust_accounts_v.cust_account_id%TYPE;  -- �A�J�E���gID
    lt_sale_base_code      xxcso_cust_accounts_v.sale_base_code%TYPE;   -- ���㋒�_�R�[�h
    lt_past_sale_base_code xxcso_cust_accounts_v.past_sale_base_code%TYPE; -- �O�����㋒�_�R�[�h
    lt_old_head_offi_code  fnd_flex_values.ATTRIBUTE7%TYPE;             -- ���{���R�[�h
    lt_row_order           fnd_flex_values.ATTRIBUTE6%TYPE;             -- ���_���я�
    lt_object_version_number csi_item_instances.object_version_number%TYPE;-- �I�u�W�F�N�g�o�[�W����
    lt_req_line_id         xxcso_requisition_lines_v.requisition_line_id%TYPE;   --�����˗�����ID
    lt_req_header_id       xxcso_requisition_lines_v.requisition_header_id%TYPE; -- ���O�p�����˗��w�b�_ID
    lt_line_num            xxcso_requisition_lines_v.line_num%TYPE;     -- ���O�p�����˗����הԍ�
    lt_jotai_kbn3          VARCHAR2(2000);                              -- �@����3(�p�����)
    lt_haiki_date          VARCHAR2(2000);                              -- �p�����ٓ�
    lv_format              VARCHAR2(100);                               -- ���t����
    lb_check_date_value    BOOLEAN;                                     -- ���t�̏������f
    -- �t�@�C���I�[�v���m�F�߂�l�i�[
    lb_fopn_retcd          BOOLEAN;
    -- ���b�Z�[�W�o�͗p
    lv_msg          VARCHAR2(2000);
    -- *** ���[�J���E�J�[�\�� ***
    -- ���_�ύX�����}�X�^��񒊏o
    CURSOR bukken_info_location_data_cur
    IS
      SELECT cii.instance_id instance_id                      -- �C���X�^���XID
            ,cii.external_reference external_reference        -- �����R�[�h
            ,cii.attribute1 attribute1_cd                     -- �@��
            ,xcav.cust_account_id cust_account_id             -- �A�J�E���gID
            ,xcav.sale_base_code sale_base_code               -- ���㋒�_�R�[�h
            ,xcav.past_sale_base_code past_sale_base_code     -- �O�����㋒�_�R�[�h
            ,xabv.old_head_office_code old_head_office_code   -- ���{���R�[�h
            ,xabv.row_order row_order                         -- ���_���я�
            ,cii.object_version_number object_version_number  -- �I�u�W�F�N�g�o�[�W����
      FROM   csi_item_instances cii                           -- �C���X�g�[���x�[�X�}�X�^
            ,xxcso_cust_accounts_v xcav                       -- �ڋq�}�X�^�r���[
            ,xxcso_aff_base_v xabv                            -- AFF����}�X�^�r���[
      WHERE cii.owner_party_account_id = xcav.cust_account_id
        AND NVL(xcav.sale_base_code, ' ') <> NVL(xcav.past_sale_base_code, ' ')
        AND xcav.sale_base_code = xabv.base_code
        AND NVL(xabv.start_date_active,ld_process_date_t) <= ld_process_date_t
        AND NVL(xabv.end_date_active,ld_process_date_t) >= ld_process_date_t
        AND xcav.account_status = cv_active_status
        AND ((TRUNC(TO_DATE(cii.attribute7, cv_final_format)) = NVL(TRUNC(TO_DATE(gv_date_value, cv_final_format)),
                                                                  TRUNC(TO_DATE(cii.attribute7, cv_final_format)))
             AND gv_date_value IS NOT NULL)
            OR  (gv_date_value IS NULL))
        /* 2009.04.13 K.Satomura T1_0409�Ή� START */
        AND xcav.past_sale_base_code IS NOT NULL
        /* 2009.04.13 K.Satomura T1_0409�Ή� END */
        ;
    -- �p����ƈ˗����f�[�^���o
    CURSOR bukken_info_dis_work_data_cur
    IS
      SELECT xrl.requisition_line_id requisition_line_id              -- �����˗�����ID
            ,xrl.abolishment_install_code abolishment_install_code    -- �����R�[�h
            ,cii.instance_id instance_id                              -- �C���X�^���XID
            ,xabv.old_head_office_code old_head_office_code           -- ���{���R�[�h
            ,xabv.row_order row_order                                 -- ���_���я�
            ,xcav.sale_base_code sale_base_code                       -- ���_(����R�[�h)
            ,xrl.requisition_header_id requisition_header_id          -- ���O�p�����˗��w�b�_ID
            ,xrl.line_num line_num                                    -- ���O�p�����˗����הԍ�
      FROM  xxcso_requisition_lines_v   xrl                           -- �����˗����׏��r���[
           ,po_requisition_headers      prh                           -- �����˗��w�b�_�r���[
           ,xxcso_wk_requisition_proc   xwrp                          -- ��ƈ˗�/������񏈗����ʃe�[�u��
           ,csi_item_instances          cii                           -- �C���X�g�[���x�[�X�}�X�^
           ,xxcso_cust_accounts_v       xcav                          -- �ڋq�}�X�^�r���[
           ,xxcso_aff_base_v            xabv                          -- AFF����}�X�^�r���[
      WHERE  xrl.category_kbn IN (cv_disposal_sinsei,cv_disposal_kessai)
         AND xrl.requisition_header_id = prh.requisition_header_id
         AND prh.authorization_status = cv_status_app
         AND xrl.requisition_line_id = xwrp.requisition_line_id 
         AND (xwrp.interface_flag = cv_interface_flag_n
                OR TRUNC(xwrp.interface_date) = TRUNC(TO_DATE(gv_date_value, cv_final_format)))
         AND cii.external_reference = xrl.abolishment_install_code
         AND cii.owner_party_account_id = xcav.cust_account_id
         AND xcav.account_status = cv_active_status
         AND xcav.sale_base_code = xabv.base_code
         AND  NVL(xabv.start_date_active,ld_process_date_t) <= ld_process_date_t
              AND NVL(xabv.end_date_active,ld_process_date_t) >= ld_process_date_t
         AND    (ld_process_date_t between(NVL(xrl.lookup_start_date, ld_process_date_t)) and
                       TRUNC(nvl(xrl.lookup_end_date, ld_process_date_t)))
         AND    (ld_process_date_t between(NVL(xrl.category_start_date, ld_process_date_t)) and
                       TRUNC(NVL(xrl.category_end_date, ld_process_date_t)));
    -- *** ���[�J���E���R�[�h ***
    l_location_data_cur        bukken_info_location_data_cur%ROWTYPE;       -- ���_�ύX�����}�X�^���
    l_dis_work_data_cur        bukken_info_dis_work_data_cur%ROWTYPE;       -- �p����ƈ˗����f�[�^
    l_get_rec                  g_value_rtype;
    -- *** ���[�J���E��O ***
    select_error_expt   EXCEPTION;
    select_warn_expt    EXCEPTION;
    lv_process_expt     EXCEPTION;
    no_data_expt        EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ���[�J���ϐ�������
    gb_rollback_upd_flg := cb_false;
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
      od_process_date     => ld_process_date,  -- �Ɩ�������
      ov_errbuf           => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    ); 
    ld_process_date_t := TRUNC(ld_process_date);
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.�v���t�@�C���l���擾 
    -- =================================================
    get_profile_info(
       ov_file_dir    => lv_file_dir    -- CSV�t�@�C���o�͐�
      ,ov_file_name   => lv_file_name   -- CSV�t�@�C����
      ,ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSV�t�@�C���I�[�v�� 
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gv_csv_process_kbn = cv_csv_proc_kbn_1) THEN  -- �p�����o�͏���
--
      -- =================================================
      -- A-9.�p����ƈ˗����f�[�^���o
      -- =================================================
--
      -- �J�[�\���I�[�v��
      OPEN bukken_info_dis_work_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn || CHR(10) ||
                   ''
      );
--
      <<get_disposal_data_loop>>
      LOOP
--
        BEGIN
          FETCH bukken_info_dis_work_data_cur INTO l_dis_work_data_cur;
        EXCEPTION
          WHEN OTHERS THEN
            -- �f�[�^���o�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_08          -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_work_ipro_data         -- �g�[�N���l1
                                ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                                ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                );
            lv_errbuf  := lv_errmsg||SQLERRM;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- �f�[�^������
          lv_sub_msg := NULL;
          lv_sub_buf := NULL;
          -- ���R�[�h�ϐ�������
          l_get_rec         := NULL;
          -- �����Ώی����i�[
          gn_target_cnt := bukken_info_dis_work_data_cur%ROWCOUNT;
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN bukken_info_dis_work_data_cur%NOTFOUND
          OR  bukken_info_dis_work_data_cur%ROWCOUNT = 0;
          -- �擾�f�[�^�����[�J���ϐ��Ɋi�[
          lt_req_line_id        := l_dis_work_data_cur.requisition_line_id;      -- �����˗�����ID
          lt_external_reference := l_dis_work_data_cur.abolishment_install_code; -- �����R�[�h
          lt_instance_id        := l_dis_work_data_cur.instance_id;              -- �C���X�^���XID
          lt_old_head_offi_code := l_dis_work_data_cur.old_head_office_code;     -- ���{���R�[�h
          lt_row_order          := l_dis_work_data_cur.row_order;                -- ���_���я�
          lt_sale_base_code     := l_dis_work_data_cur.sale_base_code;           -- ���_(����)�R�[�h
          lt_req_header_id      := l_dis_work_data_cur.requisition_header_id;
            -- ���O�p�����˗��w�b�_ID
          lt_line_num            := l_dis_work_data_cur.line_num;            -- ���O�p�����˗����הԍ�
          -- �@����3(�p�����)�Ɣp�����ٓ��̒ǉ������l�𒊏o
          -- �@����3(�p�����)
          lt_jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- �C���X�^���XID
                             ,iv_attribute_code => cv_jotai_kbn3            -- �����R�[�h
          );
--
          lv_format := 'YYYY/MM/DD';
          -- �p�����ٓ�
          lt_haiki_date := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- �C���X�^���XID
                             ,iv_attribute_code => cv_haikikessai_dt        -- �����R�[�h
          );
          IF (lt_haiki_date IS NOT NULL) THEN
            --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
            lb_check_date_value := xxcso_util_common_pkg.check_date(
                                          iv_date         => lt_haiki_date
                                         ,iv_date_format  => lv_format
            );
            --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
            IF (lb_check_date_value = cb_false) THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_20          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => lt_haiki_date             -- �g�[�N���l1�p�����[�^
                              ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                              ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                              ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                              ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
              );
              lv_sub_msg  := lv_sub_msg||cv_bukken_cd||lt_external_reference;
              lv_sub_buf  := lv_sub_msg;
              RAISE select_warn_expt;
            END IF;
            lt_haiki_date := TO_CHAR(TO_DATE(lt_haiki_date,'yyyy/mm/dd'), 'yyyymmdd');
          END IF;
-- DEBUG
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '�@���ԂR(�p�����)�F' || lt_jotai_kbn3 ||CHR(10) ||
                   '�p�����ٓ��F' || lt_haiki_date ||
                   ''
      );             
-- DEBUG
--
          -- �擾�f�[�^�𒊏o�o�̓f�[�^�Ɋi�[
          l_get_rec.external_reference    := lt_external_reference;      -- �����R�[�h
          l_get_rec.old_head_office_code  := lt_old_head_offi_code;      -- ���{���R�[�h
          l_get_rec.row_order             := lt_row_order;               -- ���_���я�
          l_get_rec.sale_base_code        := lt_sale_base_code;          -- ���_(����)�R�[�h
          l_get_rec.jotai_kbn3            := lt_jotai_kbn3;              -- �@����3(�p�����)
          l_get_rec.haiki_date            := lt_haiki_date;              -- �p�����ٓ�
          l_get_rec.requisition_line_id   := lt_req_line_id;             -- �����˗�����ID
          l_get_rec.requisition_header_id := lt_req_header_id;           -- ���O�p�����˗��w�b�_ID
          l_get_rec.line_num              := lt_line_num;                -- ���O�p�����˗����הԍ�
          
--
          -- ================================================================
          -- A-10 �֑������`�F�b�N
          -- ================================================================
          chk_str(
             i_get_rec        => l_get_rec        -- ���o�o�̓f�[�^
            ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-11 �Z�[�u�|�C���g(�p����ƈ˗����A�g���s)���s
          -- ================================================================
          SAVEPOINT bukken_info_disposal_work;
--
          -- ================================================================
          -- A-12 ��ƈ˗��^������񏈗����ʃe�[�u���X�V
          -- ================================================================
          update_wk_reqst_tbl(
             i_get_rec        => l_get_rec         -- ���o�o�̓f�[�^
            ,id_process_date  => ld_process_date   -- �Ɩ�������
            ,ov_errbuf        => lv_sub_buf        -- �G���[�E���b�Z�[�W          --# �Œ� #
            ,ov_retcode       => lv_sub_retcode    -- ���^�[���E�R�[�h            --# �Œ� #
            ,ov_errmsg        => lv_sub_msg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-13 �p����ƈ˗����f�[�^CSV�o��
          -- ================================================================
--
          create_csv_rec(
             i_get_rec        => l_get_rec        -- ���_�ύX�����}�X�^���
            ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE select_warn_expt;
          END IF;
--
          -- �o�͂ɐ��������ꍇ
          lv_sub_msg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_17              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_req_line_id            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => TO_CHAR(lt_req_line_id)       -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_req_header_id          -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(lt_req_header_id)     -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_line_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(lt_line_num)          -- �g�[�N���l3
                          );
          -- �o�͂ɏo��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg
          );
          -- ���O�ɏo��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_msg 
          );
--          
          --���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** �f�[�^���o���̌x����O�n���h�� ***
          WHEN select_warn_expt THEN
            --�G���[�����J�E���g
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --�x���o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_sub_msg                  --���[�U�[�E�G���[���b�Z�[�W
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
            -- ���[���o�b�N
            IF gb_rollback_upd_flg = TRUE THEN
              ROLLBACK TO SAVEPOINT bukken_info_disposal_work;          -- ROLLBACK
              gb_rollback_upd_flg := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
              );
            END IF;
          -- *** �X�L�b�v��OOTHERS�n���h�� ***
          WHEN OTHERS THEN
            --�G���[�����J�E���g
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf ||SQLERRM
            );
            -- ���[���o�b�N
            IF gb_rollback_upd_flg = TRUE THEN
              ROLLBACK TO SAVEPOINT bukken_info_disposal_work;          -- ROLLBACK
              gb_rollback_upd_flg := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
              );
            END IF;
        END;
      END LOOP get_locaton_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE bukken_info_dis_work_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                   ''
      );
--
    ELSIF (gv_csv_process_kbn = cv_csv_proc_kbn_2) THEN -- ���_�ύX�o�͏���
--
      -- =================================================
      -- A-5.���_�ύX�����}�X�^��񒊏o
      -- =================================================
--
      -- �J�[�\���I�[�v��
      OPEN bukken_info_location_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn || CHR(10) ||
                   ''
      );
--
      <<get_locaton_data_loop>>
      LOOP
--
        BEGIN
          FETCH bukken_info_location_data_cur INTO l_location_data_cur;
        EXCEPTION
          WHEN OTHERS THEN
            -- �f�[�^���o�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_08          -- ���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                                ,iv_token_value1 => cv_bukken_data            -- �g�[�N���l1
                                ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                                ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                );
            lv_errbuf  := lv_errmsg||SQLERRM;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- �f�[�^������
          lv_sub_msg := NULL;
          lv_sub_buf := NULL;
          -- ���R�[�h�ϐ�������
          l_get_rec         := NULL;
          -- �����Ώی����i�[
          gn_target_cnt := bukken_info_location_data_cur%ROWCOUNT;
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN bukken_info_location_data_cur%NOTFOUND
          OR  bukken_info_location_data_cur%ROWCOUNT = 0;
          -- �擾�f�[�^�����[�J���ϐ��Ɋi�[
          lt_instance_id         := l_location_data_cur.instance_id;            -- �C���X�^���XID
          lt_external_reference  := l_location_data_cur.external_reference;     -- �����R�[�h
          lt_attribute1_cd       := l_location_data_cur.attribute1_cd;          -- �@��
          lt_cust_account_id     := l_location_data_cur.cust_account_id;        -- �A�J�E���gID
          lt_sale_base_code      := l_location_data_cur.sale_base_code;         -- ���㋒�_�R�[�h
          lt_past_sale_base_code := l_location_data_cur.past_sale_base_code;    -- �O�����㋒�_�R
          lt_old_head_offi_code  := l_location_data_cur.old_head_office_code;   -- ���{���R�[�h
          lt_row_order           := l_location_data_cur.row_order;              -- ���_���я�
          lt_object_version_number := l_location_data_cur.object_version_number;-- �I�u�W�F�N�g�o�[�W����
          -- �@����3(�p�����)�Ɣp�����ٓ��̒ǉ������l�𒊏o
          -- �@����3(�p�����)
          lt_jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- �C���X�^���XID
                             ,iv_attribute_code => cv_jotai_kbn3            -- �����R�[�h
          );
--
          -- �p�����ٓ�
          lv_format     := 'YYYY/MM/DD';
          lt_haiki_date := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- �C���X�^���XID
                             ,iv_attribute_code => cv_haikikessai_dt        -- �����R�[�h
          );
--          
          IF (lt_haiki_date IS NOT NULL) THEN
            --�擾�����p�����[�^�̏������w�肳�ꂽ���t�̏����iYYYYMMDD�j�ł��邩���m�F
            lb_check_date_value := xxcso_util_common_pkg.check_date(
                                          iv_date         => lt_haiki_date
                                         ,iv_date_format  => lv_format
            );
            --���^�[���X�e�[�^�X���uFALSE�v�̏ꍇ,��O�������s��
            IF (lb_check_date_value = FALSE) THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_20          -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_value              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => lt_haiki_date             -- �g�[�N���l1�p�����[�^
                              ,iv_token_name2  => cv_tkn_status             -- �g�[�N���R�[�h2
                              ,iv_token_value2 => cv_false                  -- �g�[�N���l2���^�[���X�e�[�^�X
                              ,iv_token_name3  => cv_tkn_message            -- �g�[�N���R�[�h3
                              ,iv_token_value3 => NULL                      -- �g�[�N���l3���^�[�����b�Z�[�W
              );
              lv_sub_msg  := lv_sub_msg||cv_bukken_cd||lt_external_reference;
              lv_sub_buf  := lv_sub_msg;
              RAISE select_warn_expt;
            END IF;
            lt_haiki_date := TO_CHAR(TO_DATE(lt_haiki_date,'yyyy/mm/dd'), 'yyyymmdd');
          END IF;
--
          -- �擾�f�[�^�𒊏o�o�̓f�[�^�Ɋi�[
          l_get_rec.external_reference   := lt_external_reference;      -- �����R�[�h
          l_get_rec.old_head_office_code := lt_old_head_offi_code;      -- ���{���R�[�h
          l_get_rec.row_order            := lt_row_order;               -- ���_���я�
          l_get_rec.sale_base_code       := lt_sale_base_code;          -- ���_(����)�R�[�h
          l_get_rec.jotai_kbn3           := lt_jotai_kbn3;              -- �@����(�p�����)
          l_get_rec.haiki_date           := lt_haiki_date;              -- �p�����ٓ�
--
          -- ================================================================
          -- A-6 �֑������`�F�b�N
          -- ================================================================
          chk_str(
             i_get_rec        => l_get_rec        -- ���o�o�̓f�[�^
            ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-7 ���_�ύX�����}�X�^���X�V
          -- ================================================================
          -- �Z�[�u�|�C���g�ݒ�(�X�V���s�p)
          --
          SAVEPOINT item_proc_up;
          update_item_instance(
             in_instance_id           => lt_instance_id            -- �C���X�^���XID
            ,in_object_version_number => lt_object_version_number  -- �I�u�W�F�N�g�o�[�W����
            ,iv_external_reference    => lt_external_reference     -- �����R�[�h
            ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
               ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
            );
            RAISE select_warn_expt;
          END IF;

--
          -- ================================================================
          -- A-8 ���_�ύX�����}�X�^���CSV�o��
          -- ================================================================
--
          create_csv_rec(
             i_get_rec        => l_get_rec        -- ���_�ύX�����}�X�^���
            ,ov_errbuf        => lv_sub_buf       -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg        => lv_sub_msg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- �o�͂ɐ��������ꍇ
          lv_sub_msg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_16              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_bukken                 -- �g�[�N���R�[�h1
                           ,iv_token_value1 => l_get_rec.external_reference  -- �g�[�N���l1
                          );
          -- �o�͂ɏo��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg
          );
          -- ���O�ɏo��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_msg 
          );
--          
          --���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** �f�[�^���o���̌x����O�n���h�� ***
          WHEN select_warn_expt THEN
            --�G���[�����J�E���g
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --�x���o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_sub_msg                  --���[�U�[�E�G���[���b�Z�[�W
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
          -- *** �f�[�^���o���̌x����O�n���h�� ***
          WHEN OTHERS THEN
            --�G���[�����J�E���g
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --�x���o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
        END;
      END LOOP get_locaton_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE bukken_info_location_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                   ''
      );
--
    END IF;
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_22             --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- �G���[���b�Z�[�W
          );
    END IF;
--
    -- ========================================
    -- A-14.CSV�t�@�C���N���[�Y  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSV�t�@�C���o�͐�
      ,iv_file_name  => lv_file_name  -- CSV�t�@�C����
      ,ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE select_error_expt;
    END IF;
--
  EXCEPTION
    -- *** ���[���o�b�N�������O�n���h�� ***
    WHEN select_error_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- �t�@�C���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      -- �p�����o�͏���
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err5 || CHR(10) ||
                     ''
       );
      END IF;
      -- ���_�ύX�o�͏���
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err5 || CHR(10) ||
                     ''
       );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      -- �p�����o�͏���
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
       );
      END IF;
      -- ���_�ύX�o�͏���
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
       );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      -- �p�����o�͏���
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                     ''
        );
      END IF;
      -- ���_�ύX�o�͏���
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- �t�@�C�����N���[�Y����Ă��Ȃ��ꍇ
      IF (lb_fopn_retcd = cb_true) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- �t�@�C���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      -- �p�����o�͏���
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
                     ''
        );
      END IF;
      -- ���_�ύX�o�͏���
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- �J�[�\���N���[�Y�������Ƃ����O�o��
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         -- �G���[�R�[�h     #�Œ�#
   ,iv_csv_process_kbn  IN VARCHAR2                 -- ���_�ύX�E�p�����CSV�o�͏����敪
   ,iv_date_value       IN VARCHAR2                 -- �������t
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I��
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
    -- IN�p�����[�^����
    gv_csv_process_kbn := iv_csv_process_kbn;               -- ���_�ύX�E�p�����CSV�o�͏����敪
    gv_date_value      := iv_date_value     ;               -- �������t
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-10.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO015A04C;
/
