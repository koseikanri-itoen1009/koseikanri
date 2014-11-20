CREATE OR REPLACE PACKAGE BODY xxinv990008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990008c(body)
 * Description      : �z�������}�X�^�̎捞
 * MD.050           : �t�@�C���A�b�v���[�h T_MD050_BPO_990
 * MD.070           : �z�������}�X�^�̎捞 T_MD070_BPO_99I
 * Version          : 1.0
 *
 * Program List
 * ------------------------ ----------------------------------------------------------
 *  Name                     Description
 * ------------------------ ----------------------------------------------------------
 *  init_proc                �֘A�f�[�^�擾                               (I-1)
 *  get_upload_data_proc     �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (I-2)
 *  check_proc               �Ó����`�F�b�N                               (I-3)
 *  set_data_proc            �o�^�f�[�^�ݒ�
 *  insert_stc_inventory_if  �f�[�^�o�^                                   (I-4)
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/27    1.0   R.Matusita        �V�K�쐬
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
  gv_pkg_name             CONSTANT VARCHAR2(15) := 'xxinv990008c';      -- �p�b�P�[�W��
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
  gv_parge_term_if        CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_007';
  gv_parge_term_name      CONSTANT VARCHAR2(30) := '�p�[�W�Ώۊ���:�z�������}�X�^';
--
  -- �N�C�b�N�R�[�h(�Q�ƃ^�C�v)
  gv_lookup_type          CONSTANT VARCHAR2(17) := 'XXINV_FILE_OBJECT';
  gv_format_type          CONSTANT VARCHAR2(20) := '�t�H�[�}�b�g�p�^�[��';
--
  -- �Ώۃe�[�u����
  gv_xxinv_mrp_file_nm    CONSTANT VARCHAR2(100) := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  gv_file_id_name         CONSTANT VARCHAR2(7)   := 'FILE_ID';
--
  -- �z�������C���^�t�F�[�X�F���ږ�
  gv_goods_classe_n           CONSTANT VARCHAR2(50) := '���i�敪';
  gv_delivery_company_code_n  CONSTANT VARCHAR2(50) := '�^���Ǝ҃R�[�h';
  gv_origin_shipment_n        CONSTANT VARCHAR2(50) := '�o�Ɍ�';
  gv_code_division_n          CONSTANT VARCHAR2(50) := '�R�[�h�敪';
  gv_shipping_address_code_n  CONSTANT VARCHAR2(50) := '�z����R�[�h';
  gv_start_date_active_n      CONSTANT VARCHAR2(50) := '�K�p�J�n��';
  gv_post_distance_n          CONSTANT VARCHAR2(50) := '�ԗ�����';
  gv_small_distance_n         CONSTANT VARCHAR2(50) := '��������';
  gv_consolid_add_distance_n  CONSTANT VARCHAR2(50) := '���ڊ�������';
  gv_actual_distance_n        CONSTANT VARCHAR2(50) := '���ۋ���';
  gv_area_a_n                 CONSTANT VARCHAR2(50) := '�G���AA';
  gv_area_b_n                 CONSTANT VARCHAR2(50) := '�G���AB';
  gv_area_c_n                 CONSTANT VARCHAR2(50) := '�G���AC';
--
  -- �z�������C���^�t�F�[�X�F���ڌ���
  gn_goods_classe_l           CONSTANT NUMBER       := 1;                   -- ���i�敪
  gn_delivery_company_code_l  CONSTANT NUMBER       := 4;                   -- �^���Ǝ҃R�[�h
  gn_origin_shipment_l        CONSTANT NUMBER       := 4;                   -- �o�Ɍ�
  gn_code_division_l          CONSTANT NUMBER       := 1;                   -- �R�[�h�敪
  gn_shipping_address_code_l  CONSTANT NUMBER       := 9;                   -- �z����R�[�h
  gn_start_date_active_l      CONSTANT NUMBER       := 10;                   -- �K�p�J�n��
  gn_post_distance_l          CONSTANT NUMBER       := 4;                   -- �ԗ�����
  gn_small_distance_l         CONSTANT NUMBER       := 4;                   -- ��������
  gn_consolid_add_distance_l  CONSTANT NUMBER       := 4;                   -- ���ڊ�������
  gn_actual_distance_l        CONSTANT NUMBER       := 4;                   -- ���ۋ���
  gn_area_a_l                 CONSTANT NUMBER       := 5;                   -- �G���AA
  gn_area_b_l                 CONSTANT NUMBER       := 5;                   -- �G���AB
  gn_area_c_l                 CONSTANT NUMBER       := 5;                   -- �G���AC
--
  gv_comma                    CONSTANT VARCHAR2(1)  := ',';                 -- �J���}
  gv_space                    CONSTANT VARCHAR2(1)  := ' ';                 -- �X�y�[�X
  gv_err_msg_space            CONSTANT VARCHAR2(6)  := '      ';            -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    goods_classe                  VARCHAR2(32767), -- ���i�敪
    delivery_company_code         VARCHAR2(32767), -- �^���Ǝ҃R�[�h
    origin_shipment               VARCHAR2(32767), -- �o�ɑq��
    code_division                 VARCHAR2(32767), -- �R�[�h�敪
    shipping_address_code         VARCHAR2(32767), -- �z����R�[�h
    start_date_active             VARCHAR2(32767), -- �K�p�J�n��
    post_distance                 VARCHAR2(32767), -- �ԗ�����
    small_distance                VARCHAR2(32767), -- ��������
    consolid_add_distance         VARCHAR2(32767), -- �h�����N���ڊ�������
    actual_distance               VARCHAR2(32767), -- ���ۋ���
    area_a                        VARCHAR2(32767), -- �G���AA
    area_b                        VARCHAR2(32767), -- �G���AB
    area_c                        VARCHAR2(32767), -- �G���AC
    line                          VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message                   VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl  IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^
  -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
  TYPE delivery_distance_if_id_type IS
  TABLE OF xxwip_delivery_distance_if.delivery_distance_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE goods_classe_type          IS
  TABLE OF xxwip_delivery_distance_if.goods_classe%TYPE  INDEX BY BINARY_INTEGER;
  -- �^���Ǝ҃R�[�h
  TYPE delivery_company_code_type IS
  TABLE OF xxwip_delivery_distance_if.delivery_company_code%TYPE  INDEX BY BINARY_INTEGER;
  -- �o�Ɍ�
  TYPE origin_shipment_type       IS
  TABLE OF xxwip_delivery_distance_if.origin_shipment%TYPE  INDEX BY BINARY_INTEGER;
  -- �R�[�h�敪
  TYPE code_division_type         IS
  TABLE OF xxwip_delivery_distance_if.code_division%TYPE  INDEX BY BINARY_INTEGER;
  -- �z����R�[�h
  TYPE shipping_address_code_type IS
  TABLE OF xxwip_delivery_distance_if.shipping_address_code%TYPE  INDEX BY BINARY_INTEGER;
  -- �K�p�J�n��
  TYPE start_date_active_type     IS
  TABLE OF xxwip_delivery_distance_if.start_date_active%TYPE  INDEX BY BINARY_INTEGER;
  -- �ԗ�����
  TYPE post_distance_type         IS
  TABLE OF xxwip_delivery_distance_if.post_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- ��������
  TYPE small_distance_type        IS
  TABLE OF xxwip_delivery_distance_if.small_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- ���ڊ�������
  TYPE consolid_add_distance_type IS
  TABLE OF xxwip_delivery_distance_if.consolid_add_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- ���ۋ���
  TYPE actual_distance_type       IS
  TABLE OF xxwip_delivery_distance_if.actual_distance%TYPE  INDEX BY BINARY_INTEGER;
  -- �G���AA
  TYPE area_a_type                IS
  TABLE OF xxwip_delivery_distance_if.area_a%TYPE  INDEX BY BINARY_INTEGER;
  -- �G���AB
  TYPE area_b_type                IS
  TABLE OF xxwip_delivery_distance_if.area_b%TYPE  INDEX BY BINARY_INTEGER;
  -- �G���AC
  TYPE area_c_type                IS
  TABLE OF xxwip_delivery_distance_if.area_c%TYPE  INDEX BY BINARY_INTEGER;
--
  gt_delivery_distance_if_id      delivery_distance_if_id_type;         -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
  gt_goods_classe                 goods_classe_type;                    -- ���i�敪
  gt_delivery_company_code        delivery_company_code_type;           -- �^���Ǝ҃R�[�h
  gt_origin_shipment              origin_shipment_type;                 -- �o�Ɍ�
  gt_code_division                code_division_type;                   -- �R�[�h�敪
  gt_shipping_address_code        shipping_address_code_type;           -- �z����R�[�h
  gt_start_date_active            start_date_active_type;               -- �K�p�J�n��
  gt_post_distance                post_distance_type;                   -- �ԗ�����
  gt_small_distance               small_distance_type;                  -- ��������
  gt_consolid_add_distance        consolid_add_distance_type;           -- ���ڊ�������
  gt_actual_distance              actual_distance_type;                 -- ���ۋ���
  gt_area_a                       area_a_type;                          -- �G���AA
  gt_area_b                       area_b_type;                          -- �G���AB
  gt_area_c                       area_c_type;                          -- �G���AC
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
   * Description      : �֘A�f�[�^�擾 (I-1)
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
    lv_parge_term           VARCHAR2(100);                              -- �v���t�@�C���F�p�[�W�Ώۊ���
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
    gn_user_id          := FND_GLOBAL.USER_ID;                          -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;                         -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;                  -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;                     -- �v���O�����A�v���P�[�V����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;                  -- �v���O����ID
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
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (I-2)
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
        IF (ln_col = 1) THEN                            -- ���i�敪
          fdata_tbl(gn_target_cnt).goods_classe             := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN                        -- �^���Ǝ҃R�[�h
          fdata_tbl(gn_target_cnt).delivery_company_code    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN                        -- �o�Ɍ�
          fdata_tbl(gn_target_cnt).origin_shipment          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN                        -- �R�[�h�敪
          fdata_tbl(gn_target_cnt).code_division            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN                        -- �z����R�[�h
          fdata_tbl(gn_target_cnt).shipping_address_code    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN                        -- �K�p�J�n��
          fdata_tbl(gn_target_cnt).start_date_active        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN                        -- �ԗ�����
          fdata_tbl(gn_target_cnt).post_distance            := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN                        -- ��������
          fdata_tbl(gn_target_cnt).small_distance           := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN                        -- ���ڊ�������
          fdata_tbl(gn_target_cnt).consolid_add_distance    := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 10) THEN                        -- ���ۋ���
          fdata_tbl(gn_target_cnt).actual_distance          := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 11) THEN                        -- �G���AA
          fdata_tbl(gn_target_cnt).area_a                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 12) THEN                        -- �G���AB
          fdata_tbl(gn_target_cnt).area_b                   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 13) THEN                        -- �G���AC
          fdata_tbl(gn_target_cnt).area_c                   := SUBSTR(lv_line, 1, ln_length);
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
   * Description      : �Ó����`�F�b�N (I-3)
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
    cn_col                  CONSTANT NUMBER := 13;                      -- �����ڐ�
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
        -- ���i�敪
        xxcmn_common3_pkg.upload_item_check(gv_goods_classe_n,
                                            fdata_tbl(ln_index).goods_classe,
                                            gn_goods_classe_l,
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
        -- �^���Ǝ҃R�[�h
        xxcmn_common3_pkg.upload_item_check(gv_delivery_company_code_n,
                                            fdata_tbl(ln_index).delivery_company_code,
                                            gn_delivery_company_code_l,
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
        -- �o�Ɍ�
        xxcmn_common3_pkg.upload_item_check(gv_origin_shipment_n,
                                            fdata_tbl(ln_index).origin_shipment,
                                            gn_origin_shipment_l,
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
        -- �R�[�h�敪
        xxcmn_common3_pkg.upload_item_check(gv_code_division_n,
                                            fdata_tbl(ln_index).code_division,
                                            gn_code_division_l,
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
        -- �z����R�[�h
        xxcmn_common3_pkg.upload_item_check(gv_shipping_address_code_n,
                                            fdata_tbl(ln_index).shipping_address_code,
                                            gn_shipping_address_code_l,
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
        -- �K�p�J�n��
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
        -- �ԗ�����
        xxcmn_common3_pkg.upload_item_check(gv_post_distance_n,
                                            fdata_tbl(ln_index).post_distance,
                                            gn_post_distance_l,
                                            0,
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
        -- ��������
        xxcmn_common3_pkg.upload_item_check(gv_small_distance_n,
                                            fdata_tbl(ln_index).small_distance,
                                            gn_small_distance_l,
                                            0,
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
        -- ���ڊ�������
        xxcmn_common3_pkg.upload_item_check(gv_consolid_add_distance_n,
                                            fdata_tbl(ln_index).consolid_add_distance,
                                            gn_consolid_add_distance_l,
                                            0,
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
        -- ���ۋ���
        xxcmn_common3_pkg.upload_item_check(gv_actual_distance_n,
                                            fdata_tbl(ln_index).actual_distance,
                                            gn_actual_distance_l,
                                            0,
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
        -- �G���AA
        xxcmn_common3_pkg.upload_item_check(gv_area_a_n,
                                            fdata_tbl(ln_index).area_a,
                                            gn_area_a_l,
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
        -- �G���AB
        xxcmn_common3_pkg.upload_item_check(gv_area_b_n,
                                            fdata_tbl(ln_index).area_b,
                                            gn_area_b_l,
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
        -- �G���AC
        xxcmn_common3_pkg.upload_item_check(gv_area_c_n,
                                            fdata_tbl(ln_index).area_c,
                                            gn_area_c_l,
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
    ln_delivery_distance_if_id         NUMBER;  -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
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
    ln_delivery_distance_if_id := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID�̔�
      SELECT xxwip_delivery_distance_id_s1.NEXTVAL 
      INTO ln_delivery_distance_if_id 
      FROM dual;
--
      -- �Ώۍ��ڂ̊i�[
      -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
      gt_delivery_distance_if_id(ln_index)     := ln_delivery_distance_if_id;
      -- ���i�敪
      gt_goods_classe(ln_index) := fdata_tbl(ln_index).goods_classe;
      -- �^���Ǝ҃R�[�h
      gt_delivery_company_code(ln_index) := fdata_tbl(ln_index).delivery_company_code;
      -- �o�Ɍ�
      gt_origin_shipment(ln_index) := fdata_tbl(ln_index).origin_shipment;
      -- �R�[�h�敪
      gt_code_division(ln_index) := fdata_tbl(ln_index).code_division;
      -- �z����R�[�h
      gt_shipping_address_code(ln_index) := fdata_tbl(ln_index).shipping_address_code;
      -- �K�p�J�n��
      gt_start_date_active(ln_index) := 
      FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).start_date_active, 'RR/MM/DD');
      -- �ԗ�����
      gt_post_distance(ln_index) := fdata_tbl(ln_index).post_distance;
      -- ��������
      gt_small_distance(ln_index) := fdata_tbl(ln_index).small_distance;
      -- ���ڊ�������
      gt_consolid_add_distance(ln_index) := fdata_tbl(ln_index).consolid_add_distance;
      -- ���ۋ���
      gt_actual_distance(ln_index) := fdata_tbl(ln_index).actual_distance;
      -- �G���AA
      gt_area_a(ln_index) := fdata_tbl(ln_index).area_a;
      -- �G���AB
      gt_area_b(ln_index) := fdata_tbl(ln_index).area_b;
      -- �G���AC
      gt_area_c(ln_index) := fdata_tbl(ln_index).area_c;
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
   * Description      : �f�[�^�o�^ (I-4)
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
    -- *** �z�������A�h�I���}�X�^�C���^�t�F�[�X�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_delivery_distance_if_id.COUNT
      INSERT INTO xxwip_delivery_distance_if
      ( delivery_distance_if_id                         -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
       ,goods_classe                                    -- ���i�敪
       ,delivery_company_code                           -- �^���Ǝ҃R�[�h
       ,origin_shipment                                 -- �o�Ɍ�
       ,code_division                                   -- �R�[�h�敪
       ,shipping_address_code                           -- �z����R�[�h
       ,start_date_active                               -- �K�p�J�n��
       ,post_distance                                   -- �ԗ�����
       ,small_distance                                  -- ��������
       ,consolid_add_distance                           -- ���ڊ�������
       ,actual_distance                                 -- ���ۋ���
       ,area_a                                          -- �G���AA
       ,area_b                                          -- �G���AB
       ,area_c                                          -- �G���AC
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
      ( gt_delivery_distance_if_id(item_cnt)            -- �z�������A�h�I���}�X�^�C���^�t�F�[�XID
       ,gt_goods_classe(item_cnt)                       -- ���i�敪
       ,gt_delivery_company_code(item_cnt)              -- �^���Ǝ҃R�[�h
       ,gt_origin_shipment(item_cnt)                    -- �o�Ɍ�
       ,gt_code_division(item_cnt)                      -- �R�[�h�敪
       ,gt_shipping_address_code(item_cnt)              -- �z����R�[�h
       ,gt_start_date_active(item_cnt)                  -- �K�p�J�n��
       ,gt_post_distance(item_cnt)                      -- �ԗ�����
       ,gt_small_distance(item_cnt)                     -- ��������
       ,gt_consolid_add_distance(item_cnt)              -- ���ڊ�������
       ,gt_actual_distance(item_cnt)                    -- ���ۋ���
       ,gt_area_a(item_cnt)                             -- �G���AA
       ,gt_area_b(item_cnt)                             -- �G���AB
       ,gt_area_c(item_cnt)                             -- �G���AC
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
    -- �֘A�f�[�^�擾 (I-1)
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (I-2)
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
    -- �Ó����`�F�b�N (I-3)
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
      -- �f�[�^�o�^ (I-4)
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (I-5)
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
END xxinv990008c;
/
