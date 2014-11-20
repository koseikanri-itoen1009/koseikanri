CREATE OR REPLACE PACKAGE BODY xxinv990006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990006c(body)
 * Description      : �����\���A�h�I���̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h T_MD050_BPO_990
 * MD.070           : �����\���A�h�I���̃A�b�v���[�h T_MD070_BPO_99G
 * Version          : 1.4
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  set_data_proc           �o�^�f�[�^�ݒ�
 *  init_proc               �֘A�f�[�^�擾 (G-1)
 *  get_upload_data_proc    �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (G-2)
 *  check_proc              �Ó����`�F�b�N (G-3)
 *  insert_sr_lines_if_proc �f�[�^�o�^ (G-4)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/06    1.0   ORACLE �ؗS��   main �V�K�쐬
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/07/08    1.2   Oracle �R�� ��_  I_S_192�Ή�
 *  2009/06/10    1.3   SCS �ۉ�          �{�ԏ�Q1204�A1439�Ή�
 *  2009/06/22    1.4   SCS �ۉ�          �{�ԏ�Q1204�A1439�ǉ��Ή�
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100) := 'xxinv990006c'; -- �p�b�P�[�W��
--
  gv_msg_kbn        CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_ng_profile CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  gv_msg_ng_lock    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ���b�N�G���[
  gv_msg_ng_data    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  gv_msg_ng_format  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
--
  gv_msg_file_name  CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  gv_msg_up_date    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_msg_up_name    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
--
  -- �g�[�N��
  gv_tkn_ng_profile         CONSTANT VARCHAR2(10)   := 'NAME';
  gv_tkn_table              CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_tkn_item               CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_tkn_value              CONSTANT VARCHAR2(15)   := 'VALUE';
  -- �v���t�@�C��
  gv_parge_term_sr_if       CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_006';
  gv_parge_term_name        CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:�����\���A�h�I��';
  -- �N�C�b�N�R�[�h �^�C�v
  gv_lookup_type            CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_format_type            CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';
  -- �Ώ�DB��
  gv_xxinv_mrp_file_ul_name CONSTANT VARCHAR2(100)
                                            := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  gv_file_id_name           CONSTANT VARCHAR2(24)   := 'FILE_ID';
  -- *** �����\���A�h�I���C���^�t�F�[�X���ږ� ***
  gv_item_code_n            CONSTANT VARCHAR2(24)   := '�i�ڃR�[�h';
  gv_base_code_n            CONSTANT VARCHAR2(24)   := '���_�R�[�h';
  gv_ship_to_code_n         CONSTANT VARCHAR2(24)   := '�z����R�[�h';
  gv_start_date_active_n    CONSTANT VARCHAR2(24)   := '�K�p�J�n��';
  gv_end_date_active_n      CONSTANT VARCHAR2(24)   := '�K�p�I����';
  gv_delivery_whse_n        CONSTANT VARCHAR2(24)   := '�o�ɑq�ɃR�[�h';
  gv_move_whse1_n           CONSTANT VARCHAR2(24)   := '�ړ����q�ɃR�[�h1';
  gv_move_whse2_n           CONSTANT VARCHAR2(24)   := '�ړ����q�ɃR�[�h2';
  gv_vender_site1_n         CONSTANT VARCHAR2(24)   := '�d����T�C�g�R�[�h1';
  gv_vender_site2_n         CONSTANT VARCHAR2(24)   := '�d����T�C�g�R�[�h2';
  gv_plan_item_flag_n       CONSTANT VARCHAR2(24)   := '�v�揤�i�t���O';
-- 2009/06/10 ADD START
  gv_sourcing_rules_id_n    CONSTANT VARCHAR2(24)   := '�폜�L�[';
  gv_sourcing_rules         CONSTANT VARCHAR2(24)   := '�����\���A�h�I���}�X�^';
-- 2009/06/10 ADD END
  -- *** �����\���A�h�I���C���^�t�F�[�X���� ***
  gn_item_code_l            CONSTANT NUMBER         := 7; -- �i�ڃR�[�h
  gn_base_code_l            CONSTANT NUMBER         := 4; -- ���_�R�[�h
  gn_ship_to_code_l         CONSTANT NUMBER         := 9; -- �z����R�[�h
  gn_delivery_whse_l        CONSTANT NUMBER         := 4; -- �o�ɑq�ɃR�[�h
  gn_move_whse1_l           CONSTANT NUMBER         := 4; -- �ړ����q�ɃR�[�h1
  gn_move_whse2_l           CONSTANT NUMBER         := 4; -- �ړ����q�ɃR�[�h2
  gn_vender_site1_l         CONSTANT NUMBER         := 4; -- �d����T�C�g�R�[�h1
  gn_vender_site2_l         CONSTANT NUMBER         := 4; -- �d����T�C�g�R�[�h2
  gn_plan_item_flag_l       CONSTANT NUMBER         := 1; -- �v�揤�i�t���O
  gn_plan_item_flag_d       CONSTANT NUMBER         := 0; -- �v�揤�i�t���O(�����_�ȉ�)
--
  gv_comma                  CONSTANT VARCHAR2(1)    := ',';      -- �J���}
  gv_space                  CONSTANT VARCHAR2(1)    := ' ';      -- �X�y�[�X
  gv_err_msg_space          CONSTANT VARCHAR2(6)    := '      '; -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE file_data_rec IS RECORD(
    item_code               VARCHAR2(32767), -- �i�ڃR�[�h
    base_code               VARCHAR2(32767), -- ���_�R�[�h
    ship_to_code            VARCHAR2(32767), -- �z����R�[�h
    start_date_active       VARCHAR2(32767), -- �K�p�J�n��
    end_date_active         VARCHAR2(32767), -- �K�p�I����
    delivery_whse_code      VARCHAR2(32767), -- �o�וۊǑq�ɃR�[�h
    move_from_whse_code1    VARCHAR2(32767), -- �ړ����ۊǑq�ɃR�[�h1
    move_from_whse_code2    VARCHAR2(32767), -- �ړ����ۊǑq�ɃR�[�h2
    vendor_site_code1       VARCHAR2(32767), -- �d����T�C�g�R�[�h1
    vendor_site_code2       VARCHAR2(32767), -- �d����T�C�g�R�[�h2
    plan_item_flag          VARCHAR2(32767), -- �v�揤�i�t���O
-- 2009/06/10 ADD START
    sourcing_rules_id       VARCHAR2(32767), -- �폜�L�[
-- 2009/06/10 ADD END
    line                    VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message             VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^
  TYPE item_code_type            IS TABLE OF
    xxcmn_sr_lines_if.item_code%TYPE            INDEX BY BINARY_INTEGER;  -- �i�ڃR�[�h
  TYPE base_code_type           IS TABLE OF
    xxcmn_sr_lines_if.base_code%TYPE            INDEX BY BINARY_INTEGER;  -- ���_�R�[�h
  TYPE ship_to_code_type         IS TABLE OF
    xxcmn_sr_lines_if.ship_to_code%TYPE         INDEX BY BINARY_INTEGER;  -- �z����R�[�h
  TYPE start_date_active_type    IS TABLE OF
    xxcmn_sr_lines_if.start_date_active%TYPE    INDEX BY BINARY_INTEGER;  -- �K�p�J�n��
  TYPE end_date_active_type      IS TABLE OF
    xxcmn_sr_lines_if.end_date_active%TYPE      INDEX BY BINARY_INTEGER;  -- �K�p�I����
  TYPE delivery_whse_code_type   IS TABLE OF
    xxcmn_sr_lines_if.delivery_whse_code%TYPE   INDEX BY BINARY_INTEGER;  -- �o�וۊǑq��
  TYPE move_from_whse_code1_type IS TABLE OF
    xxcmn_sr_lines_if.move_from_whse_code1%TYPE INDEX BY BINARY_INTEGER;  -- �ړ����ۊǑq�ɃR�[�h1
  TYPE move_from_whse_code2_type IS TABLE OF
    xxcmn_sr_lines_if.move_from_whse_code2%TYPE INDEX BY BINARY_INTEGER;  -- �ړ����ۊǑq�ɃR�[�h2
  TYPE vendor_site_code1_type    IS TABLE OF
    xxcmn_sr_lines_if.vendor_site_code1%TYPE    INDEX BY BINARY_INTEGER;  -- �d����T�C�g�R�[�h1
  TYPE vendor_site_code2_type    IS TABLE OF
    xxcmn_sr_lines_if.vendor_site_code2%TYPE    INDEX BY BINARY_INTEGER;  -- �d����T�C�g�R�[�h2
  TYPE plan_item_flag_type       IS TABLE OF
    xxcmn_sr_lines_if.plan_item_flag%TYPE       INDEX BY BINARY_INTEGER;  -- �v�揤�i�t���O
-- 2009/06/10 ADD START
  TYPE sourcing_rules_id_type       IS TABLE OF
    xxcmn_sr_lines_if.sourcing_rules_id%TYPE    INDEX BY BINARY_INTEGER;  -- �폜�L�[
-- 2009/06/10 ADD END
--
  gt_item_code_tab            item_code_type;             -- �i�ڃR�[�h
  gt_base_code_tab            base_code_type;             -- ���_�R�[�h
  gt_ship_to_code_tab         ship_to_code_type;          -- �z����R�[�h
  gt_start_date_active_tab    start_date_active_type;     -- �K�p�J�n��
  gt_end_date_active_tab      end_date_active_type;       -- �K�p�I����
  gt_delivery_whse_code_tab   delivery_whse_code_type;    -- �o�וۊǑq��
  gt_move_from_whse_code1_tab move_from_whse_code1_type;  -- �ړ����ۊǑq��
  gt_move_from_whse_code2_tab move_from_whse_code2_type;  -- �ړ����ۊǑq��
  gt_vendor_site_code1_tab    vendor_site_code1_type;     -- �d����T�C�g�R�[�h1
  gt_vendor_site_code2_tab    vendor_site_code2_type;     -- �d����T�C�g�R�[�h2
  gt_plan_item_flag_tab       plan_item_flag_type;        -- �v�揤�i�t���O
-- 2009/06/10 ADD START
  gt_sourcing_rules_id_tab    sourcing_rules_id_type;     -- �폜�L�[
-- 2009/06/10 ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate                DATE;          -- �V�X�e�����t
  gn_user_id                NUMBER;        -- ���[�UID
  gn_login_id               NUMBER;        -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;        -- �v��ID
  gn_prog_appl_id           NUMBER;        -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;        -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_parge_term       NUMBER;        -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256); -- �t�@�C����
  gn_created_by             NUMBER(15);    -- �쐬��
  gd_creation_date          DATE;          -- �쐬��
  gv_file_up_name           VARCHAR2(30);  -- �t�@�C���A�b�v���[�h��
  gv_check_proc_retcode     VARCHAR2(1);   -- �Ó����`�F�b�N�X�e�[�^�X
--
  /**********************************************************************************
   * Procedure Name   : insert_sr_lines_if_proc
   * Description      : �f�[�^�o�^ (G-4)
   ***********************************************************************************/
  PROCEDURE insert_sr_lines_if_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sr_lines_if_proc'; -- �v���O������
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
    FORALL item_cnt IN 1 .. gt_item_code_tab.COUNT
      INSERT INTO xxcmn_sr_lines_if
      ( item_code                               -- �i�ڃR�[�h
      , base_code                               -- ���_�R�[�h
      , ship_to_code                            -- �z����R�[�h
      , start_date_active                       -- �K�p�J�n��
      , end_date_active                         -- �K�p�I����
      , delivery_whse_code                      -- �o�וۊǑq�ɃR�[�h
      , move_from_whse_code1                    -- �ړ����ۊǑq�ɃR�[�h1
      , move_from_whse_code2                    -- �ړ����ۊǑq�ɃR�[�h2
      , vendor_site_code1                       -- �d����T�C�g�R�[�h1
      , vendor_site_code2                       -- �d����T�C�g�R�[�h2
      , plan_item_flag                          -- �v�揤�i�t���O
-- 2009/06/10 ADD START
      , sourcing_rules_id                       -- �폜�L�[
-- 2009/06/10 ADD END
      , created_by                              -- �쐬��
      , creation_date                           -- �쐬��
      , last_updated_by                         -- �ŏI�X�V��
      , last_update_date                        -- �ŏI�X�V��
      , last_update_login                       -- �ŏI�X�V���O�C��
      , request_id                              -- �v��ID
      , program_application_id                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                              -- �R���J�����g�E�v���O����ID
      , program_update_date                     -- �v���O�����X�V��
      ) VALUES (
          gt_item_code_tab(item_cnt)            -- �i�ڃR�[�h
        , gt_base_code_tab(item_cnt)            -- ���_�R�[�h
        , gt_ship_to_code_tab(item_cnt)         -- �z����R�[�h
        , gt_start_date_active_tab(item_cnt)    -- �K�p�J�n��
        , gt_end_date_active_tab(item_cnt)      -- �K�p�I����
        , gt_delivery_whse_code_tab(item_cnt)   -- �o�וۊǑq�ɃR�[�h
        , gt_move_from_whse_code1_tab(item_cnt) -- �ړ����ۊǑq�ɃR�[�h1
        , gt_move_from_whse_code2_tab(item_cnt) -- �ړ����ۊǑq�ɃR�[�h2
        , gt_vendor_site_code1_tab(item_cnt)    -- �d����T�C�g�R�[�h1
        , gt_vendor_site_code2_tab(item_cnt)    -- �d����T�C�g�R�[�h2
        , gt_plan_item_flag_tab(item_cnt)       -- �v�揤�i�t���O
-- 2009/06/10 ADD START
        , gt_sourcing_rules_id_tab(item_cnt)    -- �폜�L�[
-- 2009/06/10 ADD END
        , gn_user_id                            -- �쐬��
        , gd_sysdate                            -- �쐬��
        , gn_user_id                            -- �ŏI�X�V��
        , gd_sysdate                            -- �ŏI�X�V��
        , gn_login_id                           -- �ŏI�X�V���O�C��
        , gn_conc_request_id                    -- �v��ID
        , gn_prog_appl_id                       -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                    -- �R���J�����g�E�v���O����ID
        , gd_sysdate                            -- �v���O�����ɂ��X�V��
      );
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END insert_sr_lines_if_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
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
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      gt_item_code_tab(ln_index)
        := fdata_tbl(ln_index).item_code;                                -- �i�ڃR�[�h
      gt_base_code_tab(ln_index)
        := fdata_tbl(ln_index).base_code;                                -- ���_�R�[�h
      gt_ship_to_code_tab(ln_index)
        := fdata_tbl(ln_index).ship_to_code;                             -- �z����R�[�h
      -- �K�p�J�n��
      gt_start_date_active_tab(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).start_date_active, 'RR/MM/DD');
      -- �K�p�I����
      gt_end_date_active_tab(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).end_date_active, 'RR/MM/DD');
      gt_delivery_whse_code_tab(ln_index)
        := fdata_tbl(ln_index).delivery_whse_code;                       -- �o�וۊǑq�ɃR�[�h
      gt_move_from_whse_code1_tab(ln_index)
        := fdata_tbl(ln_index).move_from_whse_code1;                     -- �ړ����ۊǑq�ɃR�[�h1
      gt_move_from_whse_code2_tab(ln_index)
        := fdata_tbl(ln_index).move_from_whse_code2;                     -- �ړ����ۊǑq�ɃR�[�h2
      gt_vendor_site_code1_tab(ln_index)
        := fdata_tbl(ln_index).vendor_site_code1;                        -- �d����T�C�g�R�[�h1
      gt_vendor_site_code2_tab(ln_index)
        := fdata_tbl(ln_index).vendor_site_code2;                        -- �d����T�C�g�R�[�h2
      gt_plan_item_flag_tab(ln_index)
        := TO_NUMBER(fdata_tbl(ln_index).plan_item_flag);                -- �v�揤�i�t���O
-- 2009/06/10 ADD START
      gt_sourcing_rules_id_tab(ln_index)
        := fdata_tbl(ln_index).sourcing_rules_id;                        -- �폜�L�[
-- 2009/06/10 ADD END
--
    END LOOP fdata_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (G-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc'; -- �v���O������
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
    lv_line_feed    VARCHAR2(1); -- ���s�R�[�h
--
    -- �����ڐ�
-- 2009/06/10 MOD START
--    cn_col          CONSTANT NUMBER := 11;
    cn_col          CONSTANT NUMBER := 12;
-- 2009/06/10 MOD END
--
    -- *** ���[�J���ϐ� ***
    lv_log_data     VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
-- 2009/06/10 ADD START
    ln_xsr_cnt      NUMBER;  -- �����\�����݃`�F�b�N�p
-- 2009/06/10 ADD END
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
    gv_check_proc_retcode := gv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
    lv_line_feed := CHR(10);                   -- ���s�R�[�h
--
    -- **************************************************
    -- *** �擾�������R�[�h���ɍ��ڃ`�F�b�N���s���B
    -- **************************************************
    <<check_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- **************************************************
      -- *** ���ڐ��`�F�b�N
      -- **************************************************
      -- �i�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐��j <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line),0) - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma,NULL)),0))
          <> (cn_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_err_msg_space
                                           || gv_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                                       gv_msg_ng_format)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N
        -- **************************************************
        -- ==============================
        --  �i�ڃR�[�h
        -- ==============================
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
        -- ==============================
        --  ���_�R�[�h
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_base_code_n,
                                            fdata_tbl(ln_index).base_code,
                                            gn_base_code_l,
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
        -- ==============================
        --  �z����R�[�h
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_ship_to_code_n,
                                            fdata_tbl(ln_index).ship_to_code,
                                            gn_ship_to_code_l,
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
        -- ==============================
        --  �K�p�J�n��
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_start_date_active_n,
                                            fdata_tbl(ln_index).start_date_active,
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
        -- ==============================
        --  �K�p�I����
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_end_date_active_n,
                                            fdata_tbl(ln_index).end_date_active,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        -- ==============================
        --  �o�ɑq�ɃR�[�h
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_delivery_whse_n,
                                            fdata_tbl(ln_index).delivery_whse_code,
                                            gn_delivery_whse_l,
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
        -- ==============================
        --  �ړ����q�ɃR�[�h1
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_move_whse1_n,
                                            fdata_tbl(ln_index).move_from_whse_code1,
                                            gn_move_whse1_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        -- ==============================
        --  �ړ����q�ɃR�[�h2
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_move_whse2_n,
                                            fdata_tbl(ln_index).move_from_whse_code2,
                                            gn_move_whse2_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        -- ==============================
        --  �d����T�C�g�R�[�h1
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_vender_site1_n,
                                            fdata_tbl(ln_index).vendor_site_code1,
                                            gn_vender_site1_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        -- ==============================
        --  �d����T�C�g�R�[�h2
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_vender_site2_n,
                                            fdata_tbl(ln_index).vendor_site_code2,
                                            gn_vender_site2_l,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        -- ==============================
        --  �v�揤�i�t���O
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_plan_item_flag_n,
                                            fdata_tbl(ln_index).plan_item_flag,
                                            gn_plan_item_flag_l,
                                            gn_plan_item_flag_d,
                                            xxcmn_common3_pkg.gv_null_ok,
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
-- 2009/06/10 ADD START
        -- ==============================
        --  �폜�L�[
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_sourcing_rules_id_n,
                                            fdata_tbl(ln_index).sourcing_rules_id,
                                            NULL,
                                            NULL,
                                            xxcmn_common3_pkg.gv_null_ok,
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
        --�����\���}�X�^���݃`�F�b�N
        IF (lv_retcode = gv_status_normal AND 
            fdata_tbl(ln_index).sourcing_rules_id IS NOT NULL) THEN
          BEGIN
            SELECT COUNT(1)
            INTO   ln_xsr_cnt
            FROM   xxcmn_sourcing_rules xsr
            WHERE  xsr.sourcing_rules_id = fdata_tbl(ln_index).sourcing_rules_id;
          END;
--
          -- �Y���f�[�^�Ȃ��͍��ڃ`�F�b�N�G���[
          IF (ln_xsr_cnt = 0 ) THEN
            lv_retcode := gv_status_warn;
            lv_errmsg  := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10001',
              'TABLE',gv_sourcing_rules,
              'KEY'  ,fdata_tbl(ln_index).sourcing_rules_id);
          END IF;
--
          -- ���ڃ`�F�b�N�G���[
          IF (lv_retcode = gv_status_warn) THEN
            fdata_tbl(ln_index).err_message := fdata_tbl(ln_index).err_message
                                                || gv_err_msg_space
                                                || lv_errmsg
                                                || lv_line_feed;
          -- �v���V�[�W���[�ُ�I��
          ELSIF (lv_retcode = gv_status_error) THEN
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        END IF;
-- 2009/06/10 ADD END
--
      END IF;
--
      -- **************************************************
      -- *** �G���[����
      -- **************************************************
      -- �`�F�b�N�G���[����̏ꍇ
      IF (fdata_tbl(ln_index).err_message IS NOT NULL) THEN
--
        -- **************************************************
        -- *** �f�[�^���o�͏����i�s�� + SPACE + �s�S�̂̃f�[�^�j
        -- **************************************************
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
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (G-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,           --   �t�@�C���h�c
    ov_errbuf     OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data_proc'; -- �v���O������
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
    lv_line       VARCHAR2(32767);    -- ���s�R�[�h���̏��
    ln_col        NUMBER;             -- �J����
    lb_col        BOOLEAN  := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;             -- �����ۊǗp
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;  -- �s�e�[�u���i�[�̈�
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾
    -- �s���b�N����
    SELECT xmf.file_name,    -- �t�@�C����
           xmf.created_by,   -- �쐬��
           xmf.creation_date -- �쐬��
    INTO   gv_file_name,
           gn_created_by,
           gd_creation_date
    FROM   xxinv_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id
    FOR UPDATE OF xmf.file_id NOWAIT;
--
    -- **************************************************
    -- *** �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�f�[�^�擾
    -- **************************************************
    xxcmn_common3_pkg.blob_to_varchar2(
      in_file_id,         -- �t�@�C���h�c
      lt_file_line_data,  -- �ϊ���VARCHAR2�f�[�^
      lv_errbuf,          -- �G���[�E���b�Z�[�W             --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h               --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �^�C�g���s�̂݁A���́A2�s�ڂ����s�݂̂̏ꍇ
    IF (lt_file_line_data.LAST < 2) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_data,
                                            gv_tkn_item,
                                            gv_file_id_name,
                                            gv_tkn_value,
                                            in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
    END IF;
--
    -- **************************************************
    -- *** �擾�����f�[�^���s���̃��[�v�i2�s�ڂ���j
    -- **************************************************
    <<line_loop>>
    FOR ln_index IN 2 .. lt_file_line_data.LAST LOOP
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �s���ɍ�Ɨ̈�Ɋi�[
      lv_line := lt_file_line_data(ln_index);
--
      -- 1�s�̓��e�� line �Ɋi�[
      fdata_tbl(gn_target_cnt).line := lv_line;
--
      -- �J�����ԍ�������
      ln_col := 0;    --�J����
      lb_col := TRUE; --�J�����쐬�p��
--
      -- **************************************************
      -- *** 1�s���J���}���ɕ���
      -- **************************************************
      <<comma_loop>>
      LOOP
        --lv_line�̒�����0�Ȃ�I��
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
/* 2009/06/22 DEL START
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).item_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).base_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).ship_to_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).start_date_active    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).end_date_active      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).delivery_whse_code   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code1 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code2 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code1    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code2    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).plan_item_flag       := SUBSTR(lv_line, 1, ln_length);
-- 2009/06/10 ADD START
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).sourcing_rules_id    := SUBSTR(lv_line, 1, ln_length);
-- 2009/06/10 ADD END
        END IF;
  2009/06/22 DEL END */
-- 2009/06/22 ADD START
        -- CSV�`�������ڂ��ƂɃ��R�[�h�Ɋi�[
        -- ���ڈʒu�ύX
        IF (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).item_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).base_code            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).ship_to_code         := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).start_date_active    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).end_date_active      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).delivery_whse_code   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code1 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).move_from_whse_code2 := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code1    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN
          fdata_tbl(gn_target_cnt).vendor_site_code2    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN
          fdata_tbl(gn_target_cnt).plan_item_flag       := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).sourcing_rules_id    := SUBSTR(lv_line, 1, ln_length);
        END IF;
-- 2009/06/22 ADD END
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
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN check_lock_expt THEN                           --*** ���b�N�擾�G���[ ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_lock,
                                            gv_tkn_table,
                                            gv_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_data,
                                            gv_tkn_item,
                                            gv_file_id_name,
                                            gv_tkn_value,
                                            in_file_id);
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
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (G-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,          -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    lv_parge_term       VARCHAR2(100);    -- �v���t�@�C���i�[�ꏊ
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
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_parge_term_sr_if);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_profile,
                                            gv_tkn_ng_profile,
                                            gv_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�`�F�b�N
    BEGIN
      -- TO_NUMBER�ł��Ȃ���΃G���[
      gn_xxinv_parge_term := TO_NUMBER(lv_parge_term);
    EXCEPTION
      WHEN INVALID_NUMBER OR VALUE_ERROR THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                            gv_msg_ng_profile,
                                            gv_tkn_ng_profile,
                                            gv_parge_term_name);
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
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_ng_data,
                                              gv_tkn_item,
                                              gv_format_type,
                                              gv_tkn_value,
                                              in_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,          --   �t�@�C���h�c
    in_file_format IN  VARCHAR2,        --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_out_rep VARCHAR2(32767);  -- ���|�[�g�o��
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    -- ������
    gv_check_proc_retcode := gv_status_normal; -- �Ó����`�F�b�N�X�e�[�^�X
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (G-1)
    -- ===============================
    init_proc(
      in_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (G-2)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- �t�@�C���h�c
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--#################################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ###################################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_file_name,
                                              gv_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                              gv_msg_up_date,
                                              gv_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_msg_kbn,
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
--
    -- 2008/07/08 Add ��
    ELSIF (lv_retcode = gv_status_warn) THEN
      ov_retcode := lv_retcode;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      RETURN;
    -- 2008/07/08 Add ��
    END IF;
--
    -- ===============================
    -- �Ó����`�F�b�N (G-3)
    -- ===============================
    check_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �f�[�^�o�^ (G-4)
      -- ===============================
      insert_sr_lines_if_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (G-5)
    -- ===============================
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
    errbuf         OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  VARCHAR2,        --   �t�@�C���h�c 2008/04/18 �ύX
    in_file_format IN  VARCHAR2         --   �t�H�[�}�b�g�p�^�[��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
      TO_NUMBER(in_file_id),     -- �t�@�C���h�c 2008/04/18 �ύX
      in_file_format, -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,      -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,     -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END xxinv990006c;
/
