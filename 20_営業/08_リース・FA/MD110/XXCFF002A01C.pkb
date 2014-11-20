CREATE OR REPLACE PACKAGE BODY XXCFF002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF002A01C(body)
 * Description      : ���̋@�ESH�������A�g
 * MD.050           : MD050_CFF_002_A01_���̋@�ESH�������A�g
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  select_vd_ogject_if    ���̋@�ESH�������IF���o���� (A-2)
 *  validate_record        �f�[�^�Ó����`�F�b�N���� (A-3)
 *  ins_upd_lease_object   ���[�X�������o�^�^�X�V (A-6)
 *  delete_vd_ogject_if    ���̋@�ESH�������IF�폜���� (A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   SCS ���q �G�K    �V�K�쐬
 *  2009-02-09    1.1   SCS ���q �G�K    [��QCFF_005] ���O�o�͐�s��Ή�
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  record_lock_expt    EXCEPTION;    -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(record_lock_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF002A01C';  -- �p�b�P�[�W��
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cff_00007    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';  -- ���b�N�G���[
  cv_msg_cff_00062    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00062';  -- �Ώۃf�[�^�Ȃ�
  cv_msg_cff_00093    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00093';  -- �L�[���t�G���[���b�Z�[�W
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- ���ʊ֐��G���[
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- ���ʊ֐����b�Z�[�W
  cv_msg_cff_00097    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00097';  -- �������`�F�b�N�G���[
  cv_msg_cff_00098    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00098';  -- ���[�X��ʓ���`�F�b�N�G���[
  cv_msg_cff_00099    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00099';  -- �����̖����X�e�[�^�X�A�g
  cv_msg_cff_00100    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00100';  -- �捞�Ώۃf�[�^�X�L�b�v
--
  -- �g�[�N��
  cv_tkn_cff_00007    CONSTANT VARCHAR2(15) := 'TABLE_NAME';     -- �e�[�u����
  cv_tkn_cff_00093_01 CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- �G���[���b�Z�[�W
  cv_tkn_cff_00093_02 CONSTANT VARCHAR2(15) := 'KEY_INFO';       -- �L�[���
  cv_tkn_cff_00094    CONSTANT VARCHAR2(15) := 'FUNC_NAME';      -- ���ʊ֐���
  cv_tkn_cff_00095    CONSTANT VARCHAR2(15) := 'ERR_MSG';        -- �G���[���b�Z�[�W
  cv_tkn_cff_00097    CONSTANT VARCHAR2(15) := 'TRX_DATE';       -- �捞�σf�[�^�̔�����
  cv_tkn_cff_00098    CONSTANT VARCHAR2(15) := 'LEASE_CLASS';    -- �捞�σf�[�^�̃��[�X���
  cv_tkn_cff_00100    CONSTANT VARCHAR2(15) := 'BKN_STATUS';     -- �����X�e�[�^�X
--
  -- �g�[�N���l
  cv_msg_cff_50130    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- ��������
  cv_msg_cff_50135    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50135';  -- ���̋@�ESH�������C���^�t�F�[�X�e�[�u��
  cv_msg_cff_50137    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50137';  -- �����R�[�h�F
  cv_msg_cff_50138    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50138';  -- ���[�X�������o�^
  cv_msg_cff_50141    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50141';  -- ���Ə��}�X�^�`�F�b�N
--
  -- �t���O
  gv_flag_on          CONSTANT VARCHAR2(1)   := 'Y';           -- �uY�v
  gv_flag_off         CONSTANT VARCHAR2(1)   := 'N';           -- �uN�v
--
  -- �捞�X�e�[�^�X
  cv_import_status_0  CONSTANT VARCHAR2(1)   := '0';           -- ���捞
  cv_import_status_9  CONSTANT VARCHAR2(1)   := '9';           -- �捞�G���[
--
  -- �����X�e�[�^�X
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';         -- ���_��
  cv_obj_status_107   CONSTANT VARCHAR2(3)   := '107';         -- ����
  cv_obj_status_110   CONSTANT VARCHAR2(3)   := '110';         -- ���r���i���ȓs���j
  cv_obj_status_111   CONSTANT VARCHAR2(3)   := '111';         -- ���r���i�ی��Ή��j
  cv_obj_status_112   CONSTANT VARCHAR2(3)   := '112';         -- ���r���i�����j
--
  -- �����}�X�N
  cv_date_format      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- ���t����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̋@SH����IF�捞�Ώۃf�[�^���R�[�h�^
  TYPE g_vd_ogject_rtype IS RECORD(
    object_code          xxcff_vd_object_if.object_code%TYPE,
    generation_date      xxcff_vd_object_if.generation_date%TYPE,
    lease_class          xxcff_vd_object_if.lease_class%TYPE,
    po_number            xxcff_vd_object_if.po_number%TYPE,
    manufacturer_name    xxcff_vd_object_if.manufacturer_name%TYPE,
    age_type             xxcff_vd_object_if.age_type%TYPE,
    model                xxcff_vd_object_if.model%TYPE,
    serial_number        xxcff_vd_object_if.serial_number%TYPE,
    quantity             xxcff_vd_object_if.quantity%TYPE,
    department_code      xxcff_vd_object_if.department_code%TYPE,
    owner_company        xxcff_vd_object_if.owner_company%TYPE,
    installation_place   xxcff_vd_object_if.installation_place%TYPE,
    installation_address xxcff_vd_object_if.installation_address%TYPE,
    customer_code        xxcff_vd_object_if.customer_code%TYPE,
    active_flag          xxcff_vd_object_if.active_flag%TYPE,
    import_status        xxcff_vd_object_if.import_status%TYPE,
    xoh_object_header_id xxcff_object_headers.object_header_id%TYPE,
    xoh_generation_date  xxcff_object_headers.generation_date%TYPE,
    xoh_object_status    xxcff_object_headers.object_status%TYPE,
    xoh_lease_class      xxcff_object_headers.lease_class%TYPE
  );
--
  -- ���̋@SH����IF�捞�Ώۃf�[�^���R�[�h�z��
  TYPE g_vd_ogject_ttype IS TABLE OF g_vd_ogject_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_vd_ogject_tab  g_vd_ogject_ttype;  -- ���̋@SH����IF�捞�Ώۃf�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
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
    lv_which_out VARCHAR2(10) := 'OUTPUT';
    lv_which_log VARCHAR2(10) := 'LOG';
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
    -- �R���J�����g�p�����[�^�̒l��\�����郁�b�Z�[�W�̃��O�o��
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_out,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_log,  -- �o�͋敪
      ov_retcode => lv_retcode,    -- ���^�[���R�[�h
      ov_errbuf  => lv_errbuf,     -- �G���[���b�Z�[�W
      ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : select_vd_ogject_if
   * Description      : ���̋@�ESH�������IF���o���� (A-2)
   ***********************************************************************************/
  PROCEDURE select_vd_ogject_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_vd_ogject_if'; -- �v���O������
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
    -- ���̋@SH����IF���R�[�h���b�N�J�[�\��
    CURSOR lock_row_cur
    IS
      SELECT xvoi.object_code object_code
      FROM   xxcff_vd_object_if xvoi
      WHERE  xvoi.import_status = cv_import_status_0
      FOR UPDATE NOWAIT;
    -- ���̋@SH����IF�捞�Ώۃf�[�^�擾
    CURSOR get_vd_ogject_if_cur
    IS
      SELECT xvoi.object_code object_code,                    -- �����R�[�h
             xvoi.generation_date generation_date,            -- ������
             xvoi.lease_class lease_class,                    -- ���[�X���
             xvoi.po_number po_number,                        -- �����ԍ�
             xvoi.manufacturer_name manufacturer_name,        -- ���[�J�[
             xvoi.age_type age_type,                          -- �N��
             xvoi.model model,                                -- �@��
             xvoi.serial_number serial_number,                -- �@��
             xvoi.quantity quantity,                          -- ����
             xvoi.department_code department_code,            -- �Ǘ�����R�[�h
             xvoi.owner_company owner_company,                -- �{�ЍH��敪
             xvoi.installation_place installation_place,      -- ���ݒu��
             xvoi.installation_address installation_address,  -- ���ݒu�ꏊ
             xvoi.customer_code customer_code,                -- �ڋq�R�[�h
             xvoi.active_flag active_flag,                    -- �����L���t���O
             xvoi.import_status import_status,                -- �捞�X�e�[�^�X
             xoh.object_header_id xoh_object_header_id,       -- ��������ID
             xoh.generation_date xoh_generation_date,         -- �捞�σf�[�^�̔�����
             xoh.object_status xoh_object_status,             -- �����X�e�[�^�X
             xoh.lease_class xoh_lease_class                  -- �捞�σf�[�^�̃��[�X���
      FROM   xxcff_vd_object_if xvoi,  -- ���̋@SH�����C���^�t�F�[�X
             xxcff_object_headers xoh  -- ���[�X����
      WHERE  xvoi.object_code = xoh.object_code(+)
        AND  xvoi.extract_flag = gv_flag_on
      FOR UPDATE NOWAIT;
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
    BEGIN
      -- �捞�Ώۃf�[�^�̃��b�N
      OPEN  lock_row_cur;
      CLOSE lock_row_cur;
--
      -- �捞�Ώۃf�[�^�̍X�V
      UPDATE xxcff_vd_object_if
      SET    extract_flag = gv_flag_on
      WHERE  import_status = cv_import_status_0;
--
      -- �捞�Ώۃf�[�^�̒��o(���[�X�������܂߂��ă��b�N)
      OPEN  get_vd_ogject_if_cur;
      FETCH get_vd_ogject_if_cur BULK COLLECT INTO g_vd_ogject_tab;
      CLOSE get_vd_ogject_if_cur;
--
    EXCEPTION
      -- �Ώۃf�[�^�����b�N���̏ꍇ�A�G���[
      WHEN record_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_app_kbn_cff,     -- �A�v���P�[�V�����Z�k��
                       iv_name        => cv_msg_cff_00007,   -- ���b�Z�[�W�R�[�h
                       iv_token_name1  => cv_tkn_cff_00007,  -- �g�[�N���R�[�h1
                       iv_token_value1 => cv_msg_cff_50135   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �Ώۃf�[�^��0���̏ꍇ�A���b�Z�[�W�o��(����I��)
    IF (g_vd_ogject_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                     iv_name        => cv_msg_cff_00062  -- ���b�Z�[�W�R�[�h
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      IF (get_vd_ogject_if_cur%ISOPEN) THEN
        CLOSE get_vd_ogject_if_cur;
      END IF;
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      IF (get_vd_ogject_if_cur%ISOPEN) THEN
        CLOSE get_vd_ogject_if_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END select_vd_ogject_if;
--
  /**********************************************************************************
   * Procedure Name   : validate_record
   * Description      : �f�[�^�Ó����`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE validate_record(
    in_rec_no     IN  NUMBER,       --   �`�F�b�N�Ώۃ��R�[�h�ԍ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_record'; -- �v���O������
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
    ln_location_id NUMBER;         -- ���Ə�ID
    lv_token_value VARCHAR2(100);  -- ���b�Z�[�W�o�͎��̃g�[�N�����`�p
    lb_chk_err_flg BOOLEAN;        -- �������`�F�b�N�G���[�t���O
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
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �t���O�̏�����
    lb_chk_err_flg := FALSE;
--
    -- �y�}�X�^�`�F�b�N�z
    -- ���ʊ֐�(���Ə��}�X�^�`�F�b�N)�̌Ăяo��
    xxcff_common1_pkg.chk_fa_location(
      iv_segment2    => g_vd_ogject_tab(in_rec_no).department_code,  -- �Ǘ�����
      iv_segment5    => g_vd_ogject_tab(in_rec_no).owner_company,    -- �{�Ё^�H��敪
      on_location_id => ln_location_id,  -- ���Ə�ID
      ov_retcode     => lv_retcode,      -- ���^�[���R�[�h
      ov_errbuf      => lv_errbuf,       -- �G���[���b�Z�[�W
      ov_errmsg      => lv_errmsg        -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00094,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00094,  -- �g�[�N���R�[�h1
                     iv_token_value1 => cv_msg_cff_50141   -- �g�[�N���l1
                   );
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00095,  -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00095,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errbuf          -- �g�[�N���l1
                   );
      lv_errmsg := lv_errmsg || lv_errbuf;
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �y�f�[�^�������`�F�b�N�z
    -- �u�捞�σf�[�^�̔������v���u�������v�̊֌W�łȂ��ꍇ�A���b�Z�[�W�o��
    IF (g_vd_ogject_tab(in_rec_no).xoh_generation_date >= g_vd_ogject_tab(in_rec_no).generation_date) THEN
      -- �u�捞�σf�[�^�̔������v�𕶎���^�ɕϊ����A�g�[�N���l�ɐݒ�
      lv_token_value := TO_CHAR(g_vd_ogject_tab(in_rec_no).xoh_generation_date, cv_date_format);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00097,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00097,     -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_token_value        -- �g�[�N���l1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      lb_chk_err_flg := TRUE;
    END IF;
--
    -- �u�����X�e�[�^�X�v�� '101'(���_��)�ȊO�̏ꍇ�ŁA
    -- �u�捞�σf�[�^�̃��[�X��ʁv�Ɓu���[�X��ʁv���قȂ�ꍇ�A���b�Z�[�W�o��
    IF (  (g_vd_ogject_tab(in_rec_no).xoh_object_status != cv_obj_status_101)
      AND (g_vd_ogject_tab(in_rec_no).xoh_lease_class != g_vd_ogject_tab(in_rec_no).lease_class)  )
    THEN
      -- �u�捞�σf�[�^�̃��[�X��ʁv���g�[�N���l�ɐݒ�
      lv_token_value := g_vd_ogject_tab(in_rec_no).xoh_lease_class;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00098,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00098,     -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_token_value        -- �g�[�N���l1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      lb_chk_err_flg := TRUE;
    END IF;
--
    -- �������`�F�b�N�ŃG���[�̏ꍇ�A�X�e�[�^�X��'1'(�x��)��ݒ�
    IF (lb_chk_err_flg) THEN
      ov_retcode := cv_status_warn;
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
  END validate_record;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lease_object
   * Description      : ���[�X�������o�^�^�X�V (A-6)
   ***********************************************************************************/
  PROCEDURE ins_upd_lease_object(
    in_rec_no     IN  NUMBER,       --   �`�F�b�N�Ώۃ��R�[�h�ԍ�
    ob_skip_flg   OUT BOOLEAN,      --   �o�^�^�X�V�X�L�b�v�t���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_lease_object'; -- �v���O������
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
    lr_object_data_rec  xxcff_common3_pkg.object_data_rtype;  -- �������
    lv_token_value      VARCHAR2(100);                        -- ���b�Z�[�W�o�͎��̃g�[�N�����`�p
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �t���O�̏�����
    ob_skip_flg := FALSE;
--
    -- �捞�Ώۃf�[�^�̉��^�������� (A-5)
    -- �u�����X�e�[�^�X�v�����^�����ɊY������R�[�h�̏ꍇ�A���b�Z�[�W�o��
    -- (���[�X�������o�^�^�X�V�����̓X�L�b�v)
    IF (g_vd_ogject_tab(in_rec_no).xoh_object_status
      IN(cv_obj_status_107, cv_obj_status_110, cv_obj_status_111, cv_obj_status_112))
    THEN
      -- �u�捞�σf�[�^�̕����X�e�[�^�X�v���g�[�N���l�ɐݒ�
      lv_token_value := g_vd_ogject_tab(in_rec_no).xoh_object_status;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00100,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00100,     -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_token_value        -- �g�[�N���l1
                   );
      lv_token_value := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                   );
      -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
      lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                     iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                     iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                     iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                     iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                     iv_token_value2 => lv_token_value        -- �g�[�N���l2
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg
      );
      ob_skip_flg := TRUE;
    ELSE
      -- ���ʊ֐��p�����[�^�u���[�X�������v�ւ̒l�̐ݒ�
      lr_object_data_rec.object_header_id       := g_vd_ogject_tab(in_rec_no).xoh_object_header_id;  -- ��������ID
      lr_object_data_rec.object_code            := g_vd_ogject_tab(in_rec_no).object_code;           -- �����R�[�h
      lr_object_data_rec.generation_date        := g_vd_ogject_tab(in_rec_no).generation_date;       -- ������
      lr_object_data_rec.lease_class            := g_vd_ogject_tab(in_rec_no).lease_class;           -- ���[�X���
      lr_object_data_rec.po_number              := g_vd_ogject_tab(in_rec_no).po_number;             -- �����ԍ�
      lr_object_data_rec.manufacturer_name      := g_vd_ogject_tab(in_rec_no).manufacturer_name;     -- ���[�J�[
      lr_object_data_rec.age_type               := g_vd_ogject_tab(in_rec_no).age_type;              -- �N��
      lr_object_data_rec.model                  := g_vd_ogject_tab(in_rec_no).model;                 -- �@��
      lr_object_data_rec.serial_number          := g_vd_ogject_tab(in_rec_no).serial_number;         -- �@��
      lr_object_data_rec.quantity               := g_vd_ogject_tab(in_rec_no).quantity;              -- ����
      lr_object_data_rec.department_code        := g_vd_ogject_tab(in_rec_no).department_code;       -- �Ǘ�����R�[�h
      lr_object_data_rec.owner_company          := g_vd_ogject_tab(in_rec_no).owner_company;         -- �{�Ё^�H��敪
      lr_object_data_rec.installation_place     := g_vd_ogject_tab(in_rec_no).installation_place;    -- ���ݒu��
      lr_object_data_rec.installation_address   := g_vd_ogject_tab(in_rec_no).installation_address;  -- ���ݒu�ꏊ
      lr_object_data_rec.customer_code          := g_vd_ogject_tab(in_rec_no).customer_code;         -- �ڋq�R�[�h
      lr_object_data_rec.active_flag            := g_vd_ogject_tab(in_rec_no).active_flag;           -- �����L���t���O
      lr_object_data_rec.created_by             := cn_created_by;                -- �쐬��
      lr_object_data_rec.creation_date          := cd_creation_date;             -- �쐬��
      lr_object_data_rec.last_updated_by        := cn_last_updated_by;           -- �ŏI�X�V��
      lr_object_data_rec.last_update_date       := cd_last_update_date;          -- �ŏI�X�V��
      lr_object_data_rec.last_update_login      := cn_last_update_login;         -- �ŏI�X�V۸޲�
      lr_object_data_rec.request_id             := cn_request_id;                -- �v��ID
      lr_object_data_rec.program_application_id := cn_program_application_id;    -- �ݶ��ĥ��۸��ѥ���ع����ID
      lr_object_data_rec.program_id             := cn_program_id;                -- �ݶ��ĥ��۸���ID
      lr_object_data_rec.program_update_date    := cd_program_update_date;       -- ��۸��эX�V��
--
      -- ���ʊ֐�(���[�X�������쐬�i�o�b�`�j)�̌Ăяo��
      xxcff_common3_pkg.create_ob_bat(
        io_object_data_rec => lr_object_data_rec,  -- �����擾���
        ov_retcode         => lv_retcode,          -- ���^�[���R�[�h
        ov_errbuf          => lv_errbuf,           -- �G���[���b�Z�[�W
        ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[���b�Z�[�W
      );
      IF (lv_retcode != cv_status_normal) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_00094,     -- ���b�Z�[�W�R�[�h
                       iv_token_name1  => cv_tkn_cff_00094,     -- �g�[�N���R�[�h1
                       iv_token_value1 => cv_msg_cff_50138      -- �g�[�N���l1
                     );
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_00095,     -- ���b�Z�[�W�R�[�h
                       iv_token_name1  => cv_tkn_cff_00095,     -- �g�[�N���R�[�h1
                       iv_token_value1 => lv_errbuf             -- �g�[�N���l1
                     );
        lv_errmsg := lv_errmsg || lv_errbuf;
        lv_token_value := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                     );
        -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
        lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                       iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                       iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                       iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                       iv_token_value2 => lv_token_value        -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �u�����L���t���O�v��'N'(����)�̏ꍇ�A���b�Z�[�W�o�͂��A�X�e�[�^�X��'1'(�x��)��ݒ�
      IF (g_vd_ogject_tab(in_rec_no).active_flag = gv_flag_off) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,   -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_00099  -- ���b�Z�[�W�R�[�h
                     );
        lv_token_value := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_50137      -- ���b�Z�[�W�R�[�h
                     );
        -- �u�����R�[�h�v���g�[�N���l�ɐݒ�
        lv_token_value := lv_token_value || g_vd_ogject_tab(in_rec_no).object_code;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_kbn_cff,       -- �A�v���P�[�V�����Z�k��
                       iv_name         => cv_msg_cff_00093,     -- ���b�Z�[�W�R�[�h
                       iv_token_name1  => cv_tkn_cff_00093_01,  -- �g�[�N���R�[�h1
                       iv_token_value1 => lv_errmsg,            -- �g�[�N���l1
                       iv_token_name2  => cv_tkn_cff_00093_02,  -- �g�[�N���R�[�h2
                       iv_token_value2 => lv_token_value        -- �g�[�N���l2
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
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
  END ins_upd_lease_object;
--
  /**********************************************************************************
   * Procedure Name   : delete_vd_ogject_if
   * Description      : ���̋@�ESH�������IF�폜���� (A-7)
   ***********************************************************************************/
  PROCEDURE delete_vd_ogject_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_vd_ogject_if'; -- �v���O������
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
    -- �捞�Ώۃf�[�^�̍폜
    DELETE FROM xxcff_vd_object_if
    WHERE extract_flag = gv_flag_on;
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
  END delete_vd_ogject_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_err_cnt   NUMBER;   -- �Ó����`�F�b�N���̃G���[�����J�E���g�p
    ln_skip_cnt  NUMBER;   -- ���[�X�������o�^�^�X�V�X�L�b�v�����J�E���g�p
    lb_skip_flg  BOOLEAN;  -- ���[�X�������o�^�^�X�V�X�L�b�v�t���O
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ���[�J���ϐ��̏�����
    ln_err_cnt    := 0;
    ln_skip_cnt   := 0;
    lb_skip_flg   := FALSE;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- =====================================================
    --  �������� (A-1)
    -- =====================================================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���̋@�ESH�������IF���o���� (A-2)
    -- =====================================================
    select_vd_ogject_if(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����Ώی����̐ݒ�
    gn_target_cnt := g_vd_ogject_tab.COUNT;
    -- �G���[���������̏����ݒ�
    gn_error_cnt := gn_target_cnt;
--
    -- =====================================================
    --  �f�[�^�Ó����`�F�b�N���� (A-3)
    -- =====================================================
    -- �捞�Ώۃf�[�^�̃��R�[�h�P�ʂ̃`�F�b�N
    <<validate_rec_loop>>
    FOR i IN 1..g_vd_ogject_tab.COUNT LOOP
      validate_record(
        i,                 -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ln_err_cnt := ln_err_cnt + 1;
        ov_retcode := cv_status_warn;
      END IF;
    END LOOP validate_rec_loop;
--
    -- =====================================================
    --  ���[�X�������o�^�^�X�V (A-6)
    -- =====================================================
    -- �G���[�������� (A-4)
    -- �Ó����`�F�b�N�ŃG���[�f�[�^�����݂����ꍇ�́A�ȉ��̏������s��Ȃ�
    IF (ln_err_cnt = 0) THEN
      <<ins_upd_lease_obj_loop>>
      FOR i IN 1..g_vd_ogject_tab.COUNT LOOP
        ins_upd_lease_object(
          i,                 -- �`�F�b�N�Ώۃ��R�[�h�ԍ�
          lb_skip_flg,       -- �o�^�^�X�V�X�L�b�v�t���O
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode  := cv_status_warn;
        END IF;
        IF (lb_skip_flg) THEN
          ln_skip_cnt := ln_skip_cnt + 1;
        END IF;
      END LOOP validate_rec_loop;
    END IF;
--
    -- =====================================================
    --  ���̋@�ESH�������IF�폜���� (A-7)
    -- =====================================================
    delete_vd_ogject_if(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����I���̏ꍇ�̃O���[�o���ϐ��̐ݒ�
    IF (ln_err_cnt = 0) THEN
      gn_error_cnt  := 0;
      gn_warn_cnt   := ln_skip_cnt;
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCFF002A01C;
/
