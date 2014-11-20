CREATE OR REPLACE PACKAGE BODY xxinv990005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990005c(body)
 * Description      : �I���̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h T_MD050_BPO_990
 * MD.070           : �I���̃A�b�v���[�h   T_MD070_BPO_99F
 * Version          : 1.0
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  init_proc                �֘A�f�[�^�擾                               (F-1)
 *  get_upload_data_proc     �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (F-2)
 *  check_proc               �Ó����`�F�b�N                               (F-3)
 *  set_data_proc            �o�^�f�[�^�ݒ�
 *  insert_stc_inventory_if  �f�[�^�o�^                                   (F-4)
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/19    1.0   ORACLE �⍲�q��  main�V�K�쐬
 *  2008/04/04    1.0   ORACLE �Ŗ����\  �����ύX�v��#34
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/04/25    1.2   Oracle �R�� ��_  �ύX�v��No70�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt              EXCEPTION;               -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  gv_pkg_name             CONSTANT VARCHAR2(15) := 'xxinv990005c';      -- �p�b�P�[�W��
  gv_app_name             CONSTANT VARCHAR2(5)  := 'XXINV';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_ng_profile       CONSTANT VARCHAR2(15) := 'APP-XXINV-10025';   -- �v���t�@�C���擾�G���[
  gv_msg_ng_lock          CONSTANT VARCHAR2(15) := 'APP-XXINV-10032';   -- ���b�N�G���[
  gv_msg_ng_data          CONSTANT VARCHAR2(15) := 'APP-XXINV-10008';   -- �Ώۃf�[�^�Ȃ�
  gv_msg_ng_format        CONSTANT VARCHAR2(15) := 'APP-XXINV-10024';   -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
--
  gv_msg_file_name        CONSTANT VARCHAR2(15) := 'APP-XXINV-00001';   -- �t�@�C����
  gv_msg_up_date          CONSTANT VARCHAR2(15) := 'APP-XXINV-00003';   -- �A�b�v���[�h����
  gv_msg_up_name          CONSTANT VARCHAR2(15) := 'APP-XXINV-00004';   -- �t�@�C���A�b�v���[�h����
--
  -- �g�[�N��
  gv_tkn_ng_profile       CONSTANT VARCHAR2(10) := 'NAME';              -- �g�[�N���F�v���t�@�C����
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';             -- �g�[�N���F�e�[�u����
  gv_tkn_item             CONSTANT VARCHAR2(15) := 'ITEM';              -- �g�[�N���F�Ώۖ�
  gv_tkn_value            CONSTANT VARCHAR2(15) := 'VALUE';             -- �g�[�N���F�l
--
  -- �v���t�@�C��
  gv_parge_term_if        CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_005';
  gv_parge_term_name      CONSTANT VARCHAR2(19) := '�p�[�W�Ώۊ���:�I��';
--
  -- �N�C�b�N�R�[�h(�Q�ƃ^�C�v)
  gv_lookup_type          CONSTANT VARCHAR2(17) := 'XXINV_FILE_OBJECT';
  gv_format_type          CONSTANT VARCHAR2(20) := '�t�H�[�}�b�g�p�^�[��';
--
  -- �Ώۃe�[�u����
  gv_xxinv_mrp_file_nm    CONSTANT VARCHAR2(100) := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  gv_file_id_name         CONSTANT VARCHAR2(7) := 'FILE_ID';
--
  -- �I���C���^�t�F�[�X�F���ږ�
  gv_report_post_code_n   CONSTANT VARCHAR2(50) := '�񍐕���';
  gv_invent_date_n        CONSTANT VARCHAR2(50) := '�I����';
  gv_invent_whse_code_n   CONSTANT VARCHAR2(50) := '�I���q��';
  gv_invent_seq_n         CONSTANT VARCHAR2(50) := '�I���A��';
  gv_item_code_n          CONSTANT VARCHAR2(50) := '�i��';
  gv_lot_no_n             CONSTANT VARCHAR2(50) := '���b�gNo.';
  gv_maker_date_n         CONSTANT VARCHAR2(50) := '������';
  gv_limit_date_n         CONSTANT VARCHAR2(50) := '�ܖ�����';
  gv_proper_mark_n        CONSTANT VARCHAR2(50) := '�ŗL�L��';
  gv_case_amt_n           CONSTANT VARCHAR2(50) := '�I���P�[�X��';
  gv_content_n            CONSTANT VARCHAR2(50) := '����';
  gv_loose_amt_n          CONSTANT VARCHAR2(50) := '�I���o��';
  gv_location_n           CONSTANT VARCHAR2(50) := '���P�[�V����';
  gv_rack_no1_n           CONSTANT VARCHAR2(50) := '���b�NNo�P';
  gv_rack_no2_n           CONSTANT VARCHAR2(50) := '���b�NNo�Q';
  gv_rack_no3_n           CONSTANT VARCHAR2(50) := '���b�NNo�R';
--
  -- �I���C���^�t�F�[�X�F���ڌ���
  gn_report_post_code_l   CONSTANT NUMBER       := 4;                   -- �񍐕���
  gn_invent_whse_code_l   CONSTANT NUMBER       := 3;                   -- �I���q��
  gn_invent_seq_l         CONSTANT NUMBER       := 12;                  -- �I���A��
  gn_item_code_l          CONSTANT NUMBER       := 7;                   -- �i��
  gn_lot_no_l             CONSTANT NUMBER       := 10;                  -- ���b�gNo.
  gn_maker_date_l         CONSTANT NUMBER       := 10;                  -- ������
  gn_limit_date_l         CONSTANT NUMBER       := 10;                  -- �ܖ�����
  gn_proper_mark_l        CONSTANT NUMBER       := 6;                   -- �ŗL�L��
  gn_case_amt_l           CONSTANT NUMBER       := 9;                   -- �I���P�[�X��
  gn_case_amt_d           CONSTANT NUMBER       := 0;                   -- �I���P�[�X��(�����_�ȉ�)
  gn_content_l            CONSTANT NUMBER       := 8;                   -- ����
  gn_content_d            CONSTANT NUMBER       := 3;                   -- ����(�����_�ȉ�)
  gn_loose_amt_l          CONSTANT NUMBER       := 12;                  -- �I���o��
  gn_loose_amt_d          CONSTANT NUMBER       := 3;                   -- �I���o��(�����_�ȉ�)
  gn_location_l           CONSTANT NUMBER       := 10;                  -- ���P�[�V����
  gn_rack_no1_l           CONSTANT NUMBER       := 2;                   -- ���b�NNo�P
  gn_rack_no2_l           CONSTANT NUMBER       := 2;                   -- ���b�NNo�Q
  gn_rack_no3_l           CONSTANT NUMBER       := 2;                   -- ���b�NNo�R
--
  gv_comma                CONSTANT VARCHAR2(1)  := ',';                 -- �J���}
  gv_space                CONSTANT VARCHAR2(1)  := ' ';                 -- �X�y�[�X
  gv_err_msg_space        CONSTANT VARCHAR2(6)  := '      ';            -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    corporation_name              VARCHAR2(32767), -- ��Ж�
    eos_data_type                 VARCHAR2(32767), -- �f�[�^���
    tranceration_number           VARCHAR2(32767), -- �`���p�}��
    report_post_code              VARCHAR2(32767), -- �񍐕���
    invent_date                   VARCHAR2(32767), -- �I����
    invent_whse_code              VARCHAR2(32767), -- �I���q��
    invent_seq                    VARCHAR2(32767), -- �I���A��
    item_code                     VARCHAR2(32767), -- �i��
    lot_no                        VARCHAR2(32767), -- ���b�gNo.
    maker_date                    VARCHAR2(32767), -- ������
    limit_date                    VARCHAR2(32767), -- �ܖ�����
    proper_mark                   VARCHAR2(32767), -- �ŗL�L��
    case_amt                      VARCHAR2(32767), -- �I���P�[�X��
    content                       VARCHAR2(32767), -- ����
    loose_amt                     VARCHAR2(32767), -- �I���o��
    location                      VARCHAR2(32767), -- ���P�[�V����
    rack_no1                      VARCHAR2(32767), -- ���b�NNo�P
    rack_no2                      VARCHAR2(32767), -- ���b�NNo�Q
    rack_no3                      VARCHAR2(32767), -- ���b�NNo�R
    update_date                   VARCHAR2(32767), -- �X�V����
    line                          VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                   VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl  IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^
  -- �I��IF_ID
  TYPE invent_if_id_type     IS TABLE OF xxinv_stc_inventory_interface.invent_if_id%TYPE     INDEX BY BINARY_INTEGER;
  -- �񍐕���
  TYPE report_post_code_type IS TABLE OF xxinv_stc_inventory_interface.report_post_code%TYPE INDEX BY BINARY_INTEGER;
  -- �I����
  TYPE invent_date_type      IS TABLE OF xxinv_stc_inventory_interface.invent_date%TYPE      INDEX BY BINARY_INTEGER;
  -- �I���q��
  TYPE invent_whse_code_type IS TABLE OF xxinv_stc_inventory_interface.invent_whse_code%TYPE INDEX BY BINARY_INTEGER;
  -- �I���A��
  TYPE invent_seq_type       IS TABLE OF xxinv_stc_inventory_interface.invent_seq%TYPE       INDEX BY BINARY_INTEGER;
  -- �i��
  TYPE item_code_type        IS TABLE OF xxinv_stc_inventory_interface.item_code%TYPE        INDEX BY BINARY_INTEGER;
  -- ���b�gNo.
  TYPE lot_no_type           IS TABLE OF xxinv_stc_inventory_interface.lot_no%TYPE           INDEX BY BINARY_INTEGER;
  -- ������
  TYPE maker_date_type       IS TABLE OF xxinv_stc_inventory_interface.maker_date%TYPE       INDEX BY BINARY_INTEGER;
  -- �ܖ�����
  TYPE limit_date_type       IS TABLE OF xxinv_stc_inventory_interface.limit_date%TYPE       INDEX BY BINARY_INTEGER;
  -- �ŗL�L��
  TYPE proper_mark_type      IS TABLE OF xxinv_stc_inventory_interface.proper_mark%TYPE      INDEX BY BINARY_INTEGER;
  -- �I���P�[�X��
  TYPE case_amt_type         IS TABLE OF xxinv_stc_inventory_interface.case_amt%TYPE         INDEX BY BINARY_INTEGER;
  -- ����
  TYPE content_type          IS TABLE OF xxinv_stc_inventory_interface.content%TYPE          INDEX BY BINARY_INTEGER;
  -- �I���o��
  TYPE loose_amt_type        IS TABLE OF xxinv_stc_inventory_interface.loose_amt%TYPE        INDEX BY BINARY_INTEGER;
  -- ���P�[�V����
  TYPE location_type         IS TABLE OF xxinv_stc_inventory_interface.location%TYPE         INDEX BY BINARY_INTEGER;
  -- ���b�NNo�P
  TYPE rack_no1_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no1%TYPE         INDEX BY BINARY_INTEGER;
  -- ���b�NNo�Q
  TYPE rack_no2_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no2%TYPE         INDEX BY BINARY_INTEGER;
  -- ���b�NNo�R
  TYPE rack_no3_type         IS TABLE OF xxinv_stc_inventory_interface.rack_no3%TYPE         INDEX BY BINARY_INTEGER;
--
  gt_invent_if_id           invent_if_id_type;                          -- �I��IF_ID
  gt_report_post_code       report_post_code_type;                      -- �񍐕���
  gt_invent_date            invent_date_type;                           -- �I����
  gt_invent_whse_code       invent_whse_code_type;                      -- �I���q��
  gt_invent_seq             invent_seq_type;                            -- �I���A��
  gt_item_code              item_code_type;                             -- �i��
  gt_lot_no                 lot_no_type;                                -- ���b�gNo.
  gt_maker_date             maker_date_type;                            -- ������
  gt_limit_date             limit_date_type;                            -- �ܖ�����
  gt_proper_mark            proper_mark_type;                           -- �ŗL�L��
  gt_case_amt               case_amt_type;                              -- �I���P�[�X��
  gt_content                content_type;                               -- ����
  gt_loose_amt              loose_amt_type;                             -- �I���o��
  gt_location               location_type;                              -- ���P�[�V����
  gt_rack_no1               rack_no1_type;                              -- ���b�NNo�P
  gt_rack_no2               rack_no2_type;                              -- ���b�NNo�Q
  gt_rack_no3               rack_no3_type;                              -- ���b�NNo�R
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate              DATE;                                         -- �V�X�e�����t
  gn_user_id              NUMBER;                                       -- ���[�UID
  gn_login_id             NUMBER;                                       -- �ŏI�X�V���O�C��
  gn_conc_request_id      NUMBER;                                       -- �v��ID
  gn_prog_appl_id         NUMBER;                                       -- �v���O�����A�v���P�[�V����ID
  gn_conc_program_id      NUMBER;                                       -- �v���O����ID
--
  gn_xxinv_parge_term     NUMBER;                                       -- �p�[�W�Ώۊ���
  gv_file_name            VARCHAR2(256);                                -- �t�@�C����
  gn_created_by           NUMBER(15);                                   -- �쐬��
  gd_creation_date        DATE;                                         -- �쐬��
  gv_file_up_name         VARCHAR2(30);                                 -- �t�@�C���A�b�v���[�h��
  gv_check_proc_retcode   VARCHAR2(1);                                  -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (F-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format      IN  VARCHAR2,                   -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'init_proc';       -- �v���O������
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
    lv_parge_term           VARCHAR2(100);                        -- �v���t�@�C���F�p�[�W�Ώۊ���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �V�X�e�����t�擾         ***
    -- ***************************************
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
--
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;                    -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;                   -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;            -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;               -- �v���O�����A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;            -- �v���O����ID
--
    -- ***************************************
    -- ***         �v���t�@�C���擾        ***
    -- ***************************************
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_parge_term_if);
--
    -- �v���t�@�C���擾�G���[��
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_profile,          -- APP-XXINV-10025�F�v���t�@�C���擾�G���[
                            gv_tkn_ng_profile,          -- �g�[�N���F�v���t�@�C����
                            gv_parge_term_name);        -- �p�[�W�Ώۊ���:�I��
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- ���l�^�ȊO�̏ꍇ�̓G���[
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
--
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN           -- *** �f�[�^�^�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_profile,          -- APP-XXINV-10025�F�v���t�@�C���擾�G���[
                            gv_tkn_ng_profile,          -- �g�[�N���F�v���t�@�C����
                            gv_parge_term_name);        -- �p�[�W�Ώۊ���:�I��
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = gv_lookup_type         -- �^�C�v
      AND     xlvv.lookup_code = in_file_format         -- �R�[�h
      AND     ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                           -- *** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_data,             -- APP-XXINV-10008�F�Ώۃf�[�^�Ȃ�
                            gv_tkn_item,                -- �g�[�N���F�Ώۖ�
                            gv_format_type,             -- �t�H�[�}�b�g�p�^�[��
                            gv_tkn_value,               -- �g�[�N���F�l
                            in_file_format);            -- �t�@�C���t�H�[�}�b�g
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (F-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id          IN  NUMBER,                     -- �t�@�C��ID
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(25) := 'get_upload_data_proc';  -- �v���O������
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
    lv_line                 VARCHAR2(32767);                            -- ���s�R�[�h���̏��
    ln_col                  NUMBER;                                     -- �J����
    lb_col                  BOOLEAN  := TRUE;                           -- �J�����쐬�p��
    ln_length               NUMBER;                                     -- �����ۊǗp
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;              -- �s�e�[�u���i�[�̈�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***     �C���^�t�F�[�X���擾      ***
    -- ***************************************
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_name,                               -- �t�@�C����
           xmf.created_by,                              -- �쐬��
           xmf.creation_date                            -- �쐬��
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- ***************************************
    -- ***    �C���^�t�F�[�X�f�[�^�擾     ***
    -- ***************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,                                       -- �t�@�C��ID
      lt_file_line_data,                                -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                                       -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_data,             -- �Ώۃf�[�^�Ȃ�
                            gv_tkn_item,                -- �g�[�N���F�Ώۖ�
                            gv_file_id_name,            -- �t�H�[�}�b�g�p�^�[��
                            gv_tkn_value,               -- �g�[�N���F�l
                            in_file_id);                -- �t�@�C��ID
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- *********************************************
    -- ***  �擾�f�[�^���s�P�ʂŏ���(2�s�ڈȍ~)  ***
    -- *********************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e��line�Ɋi�[
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;                                      -- �J����
      lb_col := TRUE;                                   -- �J�����쐬�p��
--
      -- ***************************************
      -- ***       1�s���J���}���ɕ���       ***
      -- ***************************************
      <<comma_loop>>
      LOOP
        -- lv_line�̒�����0�Ȃ�I��
        EXIT WHEN ((lb_col = FALSE) OR (lv_line IS NULL));
--
        -- �J�����ԍ����J�E���g
        ln_col := ln_col + 1;
--
        -- �J���}�̈ʒu���擾
        ln_length := INSTR(lv_line, gv_comma);
        -- �J���}���Ȃ�
        IF (ln_length = 0) THEN
          ln_length := LENGTH(lv_line);
          lb_col    := FALSE;
        -- �J���}������
        ELSE
          ln_length := ln_length -1;
          lb_col    := TRUE;
        END IF;
--
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        IF (ln_col = 1) THEN                            -- ��Ж�
          fdata_tbl(gn_target_cnt).corporation_name          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN                        -- �f�[�^���
          fdata_tbl(gn_target_cnt).eos_data_type             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN                        -- �`���p�}��
          fdata_tbl(gn_target_cnt).tranceration_number       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN                        -- �񍐕���
          fdata_tbl(gn_target_cnt).report_post_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN                        -- �I����
          fdata_tbl(gn_target_cnt).invent_date               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN                        -- �I���q��
          fdata_tbl(gn_target_cnt).invent_whse_code          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN                        -- �I���A��
          fdata_tbl(gn_target_cnt).invent_seq                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN                        -- �i��
          fdata_tbl(gn_target_cnt).item_code                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN                        -- ���b�gNo.
          fdata_tbl(gn_target_cnt).lot_no                    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN                       -- ������
          fdata_tbl(gn_target_cnt).maker_date                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN                       -- �ܖ�����
          fdata_tbl(gn_target_cnt).limit_date                := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN                       -- �ŗL�L��
          fdata_tbl(gn_target_cnt).proper_mark               := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN                       -- �I���P�[�X��
          fdata_tbl(gn_target_cnt).case_amt                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 14) THEN                       -- ����
          fdata_tbl(gn_target_cnt).content                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 15) THEN                       -- �I���o��
          fdata_tbl(gn_target_cnt).loose_amt                 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 16) THEN                       -- ���P�[�V����
          fdata_tbl(gn_target_cnt).location                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 17) THEN                       -- ���b�NNo�P
          fdata_tbl(gn_target_cnt).rack_no1                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 18) THEN                       -- ���b�NNo�Q
          fdata_tbl(gn_target_cnt).rack_no2                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 19) THEN                       -- ���b�NNo�R
          fdata_tbl(gn_target_cnt).rack_no3                  := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 20) THEN                       -- �X�V����
          fdata_tbl(gn_target_cnt).update_date               := SUBSTR(lv_line, 1, ln_length);
        END IF;
--
        -- str�͍���擾�����s�������i�J���}�͂̂������߁Aln_length + 2�j
        IF (lb_col = TRUE) THEN
          lv_line := SUBSTR(lv_line, ln_length + 2);
        ELSE
          lv_line := SUBSTR(lv_line, ln_length);
        END IF;
--
      END LOOP comma_loop;
    END LOOP line_loop;
--
  EXCEPTION
--
    WHEN lock_expt THEN                                 --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_lock,             -- APP-XXINV-10032�F���b�N�G���[
                            gv_tkn_table,               -- �g�[�N���F�e�[�u����
                            gv_xxinv_mrp_file_nm);      -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(
                            gv_app_name,                -- �A�v���P�[�V�����Z�k���FXXINV
                            gv_msg_ng_data,             -- �Ώۃf�[�^�Ȃ�
                            gv_tkn_item,                -- �g�[�N���F�Ώۖ�
                            gv_file_id_name,            -- FILE_ID
                            gv_tkn_value,               -- �g�[�N���F�l
                            in_file_id);                -- �t�@�C��ID
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (F-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'check_proc';      -- �v���O������
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
    lv_line_feed            VARCHAR2(1);                                -- ���s�R�[�h
    cn_col                  CONSTANT NUMBER := 20;                      -- �����ڐ�
--
    -- *** ���[�J���ϐ� ***
    lv_log_data             VARCHAR2(32767);                            -- LOG�f�[�^���ޔ�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    gv_check_proc_retcode := gv_status_normal;                          -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                                            -- ���s�R�[�h
--
    -- ******************************************
    -- *** �擾���R�[�h���ɍ��ڃ`�F�b�N�����{ ***
    -- ******************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- ***************************************
      -- ***          ���ڐ��`�F�b�N         ***
      -- ***************************************
      -- (�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐�) <> (�����ȍ��ڐ��|�P�������ȃJ���}�̐�)
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line),0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma,NULL)),0))
          <> (cn_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_err_msg_space
                                           || gv_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_app_name, gv_msg_ng_format)
                                           || lv_line_feed;
      ELSE
        -- ***************************************
        -- ***           ���ڃ`�F�b�N          ***
        -- ***************************************
        -- �񍐕���
        xxcmn_common3_pkg.upload_item_check(gv_report_post_code_n,
                                            fdata_tbl(ln_index).report_post_code,
                                            gn_report_post_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �I����
        xxcmn_common3_pkg.upload_item_check(gv_invent_date_n,
                                            fdata_tbl(ln_index).invent_date,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_dat,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �I���q��
        xxcmn_common3_pkg.upload_item_check(gv_invent_whse_code_n,
                                            fdata_tbl(ln_index).invent_whse_code,
                                            gn_invent_whse_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �I���A��
        xxcmn_common3_pkg.upload_item_check(gv_invent_seq_n,
                                            fdata_tbl(ln_index).invent_seq,
                                            gn_invent_seq_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �i��
        xxcmn_common3_pkg.upload_item_check(gv_item_code_n,
                                            fdata_tbl(ln_index).item_code,
                                            gn_item_code_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���b�gNo.
        xxcmn_common3_pkg.upload_item_check(gv_lot_no_n,
                                            fdata_tbl(ln_index).lot_no,
                                            gn_lot_no_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ������
        xxcmn_common3_pkg.upload_item_check(gv_maker_date_n,
                                            fdata_tbl(ln_index).maker_date,
                                            gn_maker_date_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �ܖ�����
        xxcmn_common3_pkg.upload_item_check(gv_limit_date_n,
                                            fdata_tbl(ln_index).limit_date,
                                            gn_limit_date_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �ŗL�L��
        xxcmn_common3_pkg.upload_item_check(gv_proper_mark_n,
                                            fdata_tbl(ln_index).proper_mark,
                                            gn_proper_mark_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �I���P�[�X��
        xxcmn_common3_pkg.upload_item_check(gv_case_amt_n,
                                            fdata_tbl(ln_index).case_amt,
                                            gn_case_amt_l,
                                            gn_case_amt_d,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ����
        xxcmn_common3_pkg.upload_item_check(gv_content_n,
                                            fdata_tbl(ln_index).content,
                                            gn_content_l,
                                            gn_content_d,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �I���o��
        xxcmn_common3_pkg.upload_item_check(gv_loose_amt_n,
                                            fdata_tbl(ln_index).loose_amt,
                                            gn_loose_amt_l,
                                            gn_loose_amt_d,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_num,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���P�[�V����
        xxcmn_common3_pkg.upload_item_check(gv_location_n,
                                            fdata_tbl(ln_index).location,
                                            gn_location_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���b�NNo�P
        xxcmn_common3_pkg.upload_item_check(gv_rack_no1_n,
                                            fdata_tbl(ln_index).rack_no1,
                                            gn_rack_no1_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���b�NNo�Q
        xxcmn_common3_pkg.upload_item_check(gv_rack_no2_n,
                                            fdata_tbl(ln_index).rack_no2,
                                            gn_rack_no2_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���b�NNo�R
        xxcmn_common3_pkg.upload_item_check(gv_rack_no3_n,
                                            fdata_tbl(ln_index).rack_no3,
                                            gn_rack_no3_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ng,
                                            xxcmn_common3_pkg.gv_attr_vc2,
                                            lv_errbuf,
                                            lv_retcode,
                                            lv_errmsg);
        -- ���ڃ`�F�b�N�G���[
        IF (lv_retcode = gv_status_warn) THEN
          fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                              || lv_errmsg
                                              || lv_line_feed;
        -- �v���V�[�W���[�ُ�I��
        ELSIF (lv_retcode = gv_status_error) THEN
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ***************************************
      -- ***            �G���[����           ***
      -- ***************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- *******************************************************
        -- *** �f�[�^���o�͏���(�s�� + SPACE + �s�S�̂̃f�[�^) ***
        -- *******************************************************
        lv_log_data := NULL;
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_space || fdata_tbl(ln_index).line;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_log_data);
--
        -- �G���[���b�Z�[�W���o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RTRIM(fdata_tbl(ln_index).err_message, lv_line_feed));
        -- �Ó����`�F�b�N�X�e�[�^�X
        gv_check_proc_retcode := gv_status_error;
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
      -- �`�F�b�N�G���[�Ȃ��̏ꍇ
      ELSE
        -- ���������J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP check_loop;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20) := 'set_data_proc';   -- �v���O������
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
    ln_invent_if_id         NUMBER;                                     -- �I��IF_ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ�������
    ln_invent_if_id := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �I��IF_ID�̔�
      SELECT xxinv_stc_invt_if_s1.NEXTVAL 
      INTO ln_invent_if_id 
      FROM dual;
--
      -- �Ώۍ��ڂ̊i�[
      -- �I��IF_ID
      gt_invent_if_id(ln_index)     := ln_invent_if_id;
      -- �񍐕���
      gt_report_post_code(ln_index) := fdata_tbl(ln_index).report_post_code;
      -- �I����
      gt_invent_date(ln_index)      := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).invent_date,'YYYY/MM/DD');
      -- �I���q��
      gt_invent_whse_code(ln_index) := fdata_tbl(ln_index).invent_whse_code;
      -- �I���A��
      gt_invent_seq(ln_index)       := fdata_tbl(ln_index).invent_seq;
      -- �i��
      gt_item_code(ln_index)        := fdata_tbl(ln_index).item_code;
      -- ���b�gNo.
      gt_lot_no(ln_index)           := fdata_tbl(ln_index).lot_no;
      -- ������
      gt_maker_date(ln_index)       := fdata_tbl(ln_index).maker_date;
      -- �ܖ�����
      gt_limit_date(ln_index)       := fdata_tbl(ln_index).limit_date;
      -- �ŗL�L��
      gt_proper_mark(ln_index)      := fdata_tbl(ln_index).proper_mark;
      -- �I���P�[�X��
      gt_case_amt(ln_index)         := fdata_tbl(ln_index).case_amt;
      -- ����
      gt_content(ln_index)          := fdata_tbl(ln_index).content;
      -- �I���o��
      gt_loose_amt(ln_index)        := fdata_tbl(ln_index).loose_amt;
      -- ���P�[�V����
      gt_location(ln_index)         := fdata_tbl(ln_index).location;
      -- ���b�NNo�P
      gt_rack_no1(ln_index)         := fdata_tbl(ln_index).rack_no1;
      -- ���b�NNo�Q
      gt_rack_no2(ln_index)         := fdata_tbl(ln_index).rack_no2;
      -- ���b�NNo�R
      gt_rack_no3(ln_index)         := fdata_tbl(ln_index).rack_no3;
--
    END LOOP fdata_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : insert_stc_inventory_if
   * Description      : �f�[�^�o�^ (F-4)
   ***********************************************************************************/
  PROCEDURE insert_stc_inventory_if(
    ov_errbuf           OUT NOCOPY VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_stc_inventory_if'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- **************************************************
    -- *** �����\���A�h�I���C���^�t�F�[�X�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_invent_if_id.COUNT
      INSERT INTO xxinv_stc_inventory_interface
      ( invent_if_id                                    -- �I��IF_ID
       ,report_post_code                                -- �񍐕���
       ,invent_date                                     -- �I����
       ,invent_whse_code                                -- �I���q��
       ,invent_seq                                      -- �I���A��
       ,item_code                                       -- �i��
       ,lot_no                                          -- ���b�gNo.
       ,maker_date                                      -- ������
       ,limit_date                                      -- �ܖ�����
       ,proper_mark                                     -- �ŗL�L��
       ,case_amt                                        -- �I���P�[�X��
       ,content                                         -- ����
       ,loose_amt                                       -- �I���o��
       ,location                                        -- ���P�[�V����
       ,rack_no1                                        -- ���b�NNo�P
       ,rack_no2                                        -- ���b�NNo�Q
       ,rack_no3                                        -- ���b�NNo�R
       ,created_by                                      -- �쐬��
       ,creation_date                                   -- �쐬��
       ,last_updated_by                                 -- �ŏI�X�V��
       ,last_update_date                                -- �ŏI�X�V��
       ,last_update_login                               -- �ŏI�X�V���O�C��
       ,request_id                                      -- �v��ID
       ,program_application_id                          -- �v���O�����A�v���P�[�V����ID
       ,program_id                                      -- �v���O����ID
       ,program_update_date                             -- �v���O�����X�V��
      ) VALUES
      ( gt_invent_if_id(item_cnt)                       -- �I��IF_ID
       ,gt_report_post_code(item_cnt)                   -- �񍐕���
       ,gt_invent_date(item_cnt)                        -- �I����
       ,gt_invent_whse_code(item_cnt)                   -- �I���q��
       ,gt_invent_seq(item_cnt)                         -- �I���A��
       ,gt_item_code(item_cnt)                          -- �i��
       ,gt_lot_no(item_cnt)                             -- ���b�gNo.
       ,gt_maker_date(item_cnt)                         -- ������
       ,gt_limit_date(item_cnt)                         -- �ܖ�����
       ,gt_proper_mark(item_cnt)                        -- �ŗL�L��
       ,gt_case_amt(item_cnt)                           -- �I���P�[�X��
       ,gt_content(item_cnt)                            -- ����
       ,gt_loose_amt(item_cnt)                          -- �I���o��
       ,gt_location(item_cnt)                           -- ���P�[�V����
       ,gt_rack_no1(item_cnt)                           -- ���b�NNo�P
       ,gt_rack_no2(item_cnt)                           -- ���b�NNo�Q
       ,gt_rack_no3(item_cnt)                           -- ���b�NNo�R
       ,gn_user_id                                      -- �쐬��
       ,gd_sysdate                                      -- �쐬��
       ,gn_user_id                                      -- �ŏI�X�V��
       ,gd_sysdate                                      -- �ŏI�X�V��
       ,gn_login_id                                     -- �ŏI�X�V���O�C��
       ,gn_conc_request_id                              -- �v��ID
       ,gn_prog_appl_id                                 -- �v���O�����A�v���P�[�V����ID
       ,gn_conc_program_id                              -- �v���O����ID
       ,gd_sysdate                                      -- �v���O�����ɂ��X�V��
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_stc_inventory_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id          IN  NUMBER,                     --   �t�@�C���h�c
    in_file_format      IN  VARCHAR2,                   --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf           OUT NOCOPY VARCHAR2,            --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,            --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';       -- �v���O������
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
    lv_out_rep              VARCHAR2(32767);                            -- ���|�[�g�o��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    -- �Ó����`�F�b�N�X�e�[�^�X�̏�����
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (F-1)
    -- ===============================
    init_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (F-2)
    -- ==================================================
    get_upload_data_proc(
      in_file_id,                     -- �t�@�C���h�c
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_msg_file_name,
                                              gv_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_msg_up_date,
                                              gv_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_app_name,
                                              gv_msg_up_name,
                                              gv_tkn_value,
                                              gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ###################################
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ó����`�F�b�N (F-3)
    -- ===============================
    check_proc(
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
--
      -- ===============================
      -- �o�^�f�[�^�Z�b�g
      -- ===============================
      set_data_proc(
        lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �f�[�^�o�^ (F-4)
      -- ===============================
      insert_stc_inventory_if(
        lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ==================================================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (F-5)
    -- ==================================================
    xxcmn_common3_pkg.delete_fileup_proc(
      in_file_format,                 -- �t�H�[�}�b�g�p�^�[��
      gd_sysdate,                     -- �Ώۓ��t
      gn_xxinv_parge_term,            -- �p�[�W�Ώۊ���
      lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      -- main����ROLLBACK�������s���ׁAnormal����
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_space;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf              OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode             OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    in_file_id          IN  VARCHAR2,                   -- 1.�t�@�C���h�c 2008/04/18 �ύX
    in_file_format      IN  VARCHAR2                    -- 2.�t�H�[�}�b�g�p�^�[��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'main';           -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      TO_NUMBER(in_file_id),                       -- 1.�t�@�C���h�c 2008/04/18 �ύX
      in_file_format,                              -- 2.�t�H�[�}�b�g�p�^�[��
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) AND (gv_check_proc_retcode = gv_status_normal) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv990005c;
/
