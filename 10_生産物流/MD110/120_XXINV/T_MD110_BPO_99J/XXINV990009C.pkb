CREATE OR REPLACE PACKAGE BODY xxinv990009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990009c(body)
 * Description      : �^���}�X�^�̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h     T_MD050_BPO_990
 * MD.070           : �^���}�X�^�̃A�b�v���[�h T_MD070_BPO_99J
 * Version          : 1.2
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init_proc                 �֘A�f�[�^�擾 (J-1)
 *  get_upload_data_proc      �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (J-2)
 *  check_proc                �Ó����`�F�b�N (J-3)
 *  set_data_proc             �o�^�f�[�^�ݒ�
 *  insert_dv_charges_if_proc �f�[�^�o�^ (J-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/15    1.0   Oracle �ؗS��   ����쐬
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/07/08    1.2   Oracle �R�� ��_  I_S_192�Ή�
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
--
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxinv990009c'; -- �p�b�P�[�W��
--
  gv_c_msg_kbn        CONSTANT VARCHAR2(5)   := 'XXINV';
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_ng_profile CONSTANT VARCHAR2(15)  := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[
  gv_c_msg_ng_lock    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10032'; -- ���b�N�G���[
  gv_c_msg_ng_data    CONSTANT VARCHAR2(15)  := 'APP-XXINV-10008'; -- �Ώۃf�[�^�Ȃ�
  gv_c_msg_ng_format  CONSTANT VARCHAR2(15)  := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
--
  gv_c_msg_file_name  CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  gv_c_msg_up_date    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_c_msg_up_name    CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
--
  -- �g�[�N��
  gv_c_tkn_ng_profile          CONSTANT VARCHAR2(10)   := 'NAME';
  gv_c_tkn_table               CONSTANT VARCHAR2(15)   := 'TABLE';
  gv_c_tkn_item                CONSTANT VARCHAR2(15)   := 'ITEM';
  gv_c_tkn_value               CONSTANT VARCHAR2(15)   := 'VALUE';
  -- �v���t�@�C��
  gv_c_parge_term_008          CONSTANT VARCHAR2(20)   := 'XXINV_PURGE_TERM_008';
  gv_c_parge_term_name         CONSTANT VARCHAR2(36)   := '�p�[�W�Ώۊ���:�^���}�X�^';
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type             CONSTANT VARCHAR2(17)  := 'XXINV_FILE_OBJECT';
  gv_c_format_type             CONSTANT VARCHAR2(20)  := '�t�H�[�}�b�g�p�^�[��';
  -- �Ώ�DB��
  gv_c_xxinv_mrp_file_ul_name  CONSTANT VARCHAR2(100)
                                            := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  -- *** FILE_ID�� ***
  gv_c_file_id_name             CONSTANT VARCHAR2(24)   := 'FILE_ID';
  -- *** ���ږ� ***
  gv_c_p_b_classe_n             CONSTANT VARCHAR2(24)   := '�x�������敪';
  gv_c_goods_classe_n           CONSTANT VARCHAR2(24)   := '���i�敪';
  gv_c_dv_company_code_n        CONSTANT VARCHAR2(24)   := '�^���Ǝ�';
  gv_c_sp_address_classe_n      CONSTANT VARCHAR2(24)   := '�z���敪';
  gv_c_delivery_distance_n      CONSTANT VARCHAR2(24)   := '�^������';
  gv_c_delivery_weight_n        CONSTANT VARCHAR2(24)   := '�d��';
  gv_c_start_date_active_n      CONSTANT VARCHAR2(24)   := '�K�p�J�n��';
  gv_c_shipping_expenses_n      CONSTANT VARCHAR2(24)   := '�^����';
  gv_c_leaf_consolid_add_n      CONSTANT VARCHAR2(24)   := '���[�t���ڊ���';
--
  -- *** ���ڌ��� ***
  gn_c_p_b_classe_l           CONSTANT NUMBER         := 1;   -- �x�������敪
  gn_c_goods_classe_l         CONSTANT NUMBER         := 1;   -- ���i�敪
  gn_c_dv_company_code_l      CONSTANT NUMBER         := 4;   -- �^���Ǝ�
  gn_c_sp_address_classe_l    CONSTANT NUMBER         := 2;   -- �z���敪
  gn_c_delivery_distance_l    CONSTANT NUMBER         := 4;   -- �^������
  gn_c_delivery_distance_d    CONSTANT NUMBER         := 0;   -- �^�������i�����_�ȉ��j
  gn_c_delivery_weight_l      CONSTANT NUMBER         := 6;   -- �d��
  gn_c_delivery_weight_d      CONSTANT NUMBER         := 0;   -- �d�ʁi�����_�ȉ��j
  gn_c_shipping_expenses_l    CONSTANT NUMBER         := 9;   -- �^����
  gn_c_shipping_expenses_d    CONSTANT NUMBER         := 0;   -- �^����i�����_�ȉ��j
  gn_c_leaf_consolid_add_l    CONSTANT NUMBER         := 9;   -- ���[�t���ڊ���
  gn_c_leaf_consolid_add_d    CONSTANT NUMBER         := 0;   -- ���[�t���ڊ����i�����_�ȉ��j
--
  gv_c_period                   CONSTANT VARCHAR2(1)    := '.';           -- �s���I�h
  gv_c_comma                    CONSTANT VARCHAR2(1)    := ',';           -- �J���}
  gv_c_space                    CONSTANT VARCHAR2(1)    := ' ';           -- �X�y�[�X
  gv_c_err_msg_space            CONSTANT VARCHAR2(6)    := '      ';      -- �X�y�[�X�i6byte�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    p_b_classe              VARCHAR2(32767), -- �x�������敪
    goods_classe            VARCHAR2(32767), -- ���i�敪
    dv_company_code         VARCHAR2(32767), -- �^���Ǝ�
    sp_address_classe       VARCHAR2(32767), -- �z���敪
    delivery_distance       VARCHAR2(32767), -- �^������
    delivery_weight         VARCHAR2(32767), -- �d��
    start_date_active       VARCHAR2(32767), -- �K�p�J�n��
    shipping_expenses       VARCHAR2(32767), -- �^����
    leaf_consolid_add       VARCHAR2(32767), -- ���[�t���ڊ���
    line                    VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message             VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^
  -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
  TYPE dv_charges_if_id_type  IS TABLE OF
    xxwip_delivery_charges_if.delivery_charges_if_id%TYPE  INDEX BY BINARY_INTEGER;
  -- �o�א�
  TYPE p_b_classe_type        IS TABLE OF
    xxwip_delivery_charges_if.p_b_classe%TYPE              INDEX BY BINARY_INTEGER;
  -- �ڋq����
  TYPE goods_classe_type      IS TABLE OF
    xxwip_delivery_charges_if.goods_classe%TYPE            INDEX BY BINARY_INTEGER;
  -- �󒍃\�[�X�Q��
  TYPE dv_company_code_type   IS TABLE OF
    xxwip_delivery_charges_if.delivery_company_code%TYPE   INDEX BY BINARY_INTEGER;
  -- �p���b�g�g�p����
  TYPE sp_address_classe_type IS TABLE OF
    xxwip_delivery_charges_if.shipping_address_classe%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g�������
  TYPE delivery_distance_type IS TABLE OF
    xxwip_delivery_charges_if.delivery_distance%TYPE       INDEX BY BINARY_INTEGER;
  -- �o�׌�
  TYPE delivery_weight_type   IS TABLE OF
    xxwip_delivery_charges_if.delivery_weight%TYPE         INDEX BY BINARY_INTEGER;
  -- ���׎���From
  TYPE start_date_active_type IS TABLE OF
    xxwip_delivery_charges_if.start_date_active%TYPE       INDEX BY BINARY_INTEGER;
  -- ���׎���To
  TYPE shipping_expenses_type IS TABLE OF
    xxwip_delivery_charges_if.shipping_expenses%TYPE       INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�
  TYPE leaf_consolid_add_type IS TABLE OF
    xxwip_delivery_charges_if.leaf_consolid_add%TYPE       INDEX BY BINARY_INTEGER;
--
  gt_dv_charges_if_id_tab   dv_charges_if_id_type;  -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
  gt_p_b_classe_tab         p_b_classe_type;        -- �x�������敪
  gt_goods_classe_tab       goods_classe_type;      -- ���i�敪
  gt_dv_company_code_tab    dv_company_code_type;   -- �^���Ǝ�
  gt_sp_address_classe_tab  sp_address_classe_type; -- �z���敪
  gt_delivery_distance_tab  delivery_distance_type; -- �^������
  gt_delivery_weight_tab    delivery_weight_type;   -- �d��
  gt_start_date_active_tab  start_date_active_type; -- �K�p�J�n��
  gt_shipping_expenses_tab  shipping_expenses_type; -- �^����
  gt_leaf_consolid_add_tab  leaf_consolid_add_type; -- ���[�t���ڊ���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate                DATE;          -- �V�X�e�����t
  gn_user_id                NUMBER;        -- ���[�UID
  gn_login_id               NUMBER;        -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;        -- �v��ID
  gn_prog_appl_id           NUMBER;        -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;        -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_parge_term       NUMBER;        -- �p�[�W�Ώۊ���
  gv_file_name              VARCHAR2(256); -- �t�@�C����
  gv_file_up_name           VARCHAR2(256); -- �t�@�C���A�b�v���[�h����
  gn_created_by             NUMBER(15);    -- �쐬��
  gd_creation_date          DATE;          -- �쐬��
  gv_check_proc_retcode     VARCHAR2(1);   -- �Ó����`�F�b�N�X�e�[�^�X
--
   /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾 (J-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    in_file_format  IN  VARCHAR2,        -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_008);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_ng_profile,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_ng_profile,
                                            gv_c_tkn_ng_profile,
                                            gv_c_parge_term_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̎擾
    BEGIN
      SELECT  xlvv.meaning
      INTO    gv_file_up_name
      FROM    xxcmn_lookup_values_v xlvv                -- �N�C�b�N�R�[�hVIEW
      WHERE   xlvv.lookup_type = gv_c_lookup_type       -- �^�C�v
      AND     xlvv.lookup_code = in_file_format         -- �R�[�h
      AND     ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_ng_data,
                                              gv_c_tkn_item,
                                              gv_c_format_type,
                                              gv_c_tkn_value,
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
  /**********************************************************************************
   * Procedure Name   : get_upload_data_proc
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (J-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id    IN  NUMBER,          --   �t�@�C���h�c
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_ng_data,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
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
        ln_length := INSTR(lv_line, gv_c_comma);
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
        IF (ln_col = 1) THEN
          fdata_tbl(gn_target_cnt).p_b_classe        := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 2) THEN
          fdata_tbl(gn_target_cnt).goods_classe      := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 3) THEN
          fdata_tbl(gn_target_cnt).dv_company_code   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 4) THEN
          fdata_tbl(gn_target_cnt).sp_address_classe := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 5) THEN
          fdata_tbl(gn_target_cnt).delivery_distance := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 6) THEN
          fdata_tbl(gn_target_cnt).delivery_weight   := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 7) THEN
          fdata_tbl(gn_target_cnt).start_date_active := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 8) THEN
          fdata_tbl(gn_target_cnt).shipping_expenses := SUBSTR(lv_line, 1, ln_length);
        ELSIF  (ln_col = 9) THEN
          fdata_tbl(gn_target_cnt).leaf_consolid_add := SUBSTR(lv_line, 1, ln_length);
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_ng_lock,
                                            gv_c_tkn_table,
                                            gv_c_xxinv_mrp_file_ul_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN                             --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                            gv_c_msg_ng_data,
                                            gv_c_tkn_item,
                                            gv_c_file_id_name,
                                            gv_c_tkn_value,
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
   * Procedure Name   : check_proc
   * Description      : �Ó����`�F�b�N (J-3)
   ***********************************************************************************/
  PROCEDURE check_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    -- ���s�R�[�h
    lv_line_feed     VARCHAR2(1);
--
    -- �����ڐ�
    ln_c_col         CONSTANT NUMBER := 9;
--
    -- *** ���[�J���ϐ� ***
    lv_log_data      VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
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
      -- �i�s�S�̂̒����|�s����J���}�𔲂����������J���}�̐��j
      --  <> �i�����ȍ��ڐ��|�P�������ȃJ���}�̐��j
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0)
          - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_c_comma,NULL)),0))
          <> (ln_c_col - 1)) THEN
        fdata_tbl(ln_index).err_message := gv_c_err_msg_space
                                           || gv_c_err_msg_space
                                           || xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                                                       gv_c_msg_ng_format)
                                           || lv_line_feed;
      ELSE
        -- **************************************************
        -- *** ���ڃ`�F�b�N
        -- **************************************************
        -- ==============================
        --  �x�������敪
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_p_b_classe_n,
                                            fdata_tbl(ln_index).p_b_classe,
                                            gn_c_p_b_classe_l,
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
        -- ���i�敪
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_goods_classe_n,
                                            fdata_tbl(ln_index).goods_classe,
                                            gn_c_goods_classe_l,
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
        -- �^���Ǝ�
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_dv_company_code_n,
                                            fdata_tbl(ln_index).dv_company_code,
                                            gn_c_dv_company_code_l,
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
        -- �z���敪
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_sp_address_classe_n,
                                            fdata_tbl(ln_index).sp_address_classe,
                                            gn_c_sp_address_classe_l,
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
        -- �^������
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_delivery_distance_n,
                                            fdata_tbl(ln_index).delivery_distance,
                                            gn_c_delivery_distance_l,
                                            gn_c_delivery_distance_d,
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
        -- ==============================
        -- �d��
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_delivery_weight_n,
                                            fdata_tbl(ln_index).delivery_weight,
                                            gn_c_delivery_weight_l,
                                            gn_c_delivery_weight_d,
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
        -- ==============================
        -- �K�p�J�n��
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_start_date_active_n,
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
        -- �^����
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_shipping_expenses_n,
                                            fdata_tbl(ln_index).shipping_expenses,
                                            gn_c_shipping_expenses_l,
                                            gn_c_shipping_expenses_d,
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
        -- ==============================
        -- ���[�t���ڊ���
        -- ==============================
        xxcmn_common3_pkg.upload_item_check(gv_c_leaf_consolid_add_n,
                                            fdata_tbl(ln_index).leaf_consolid_add,
                                            gn_c_leaf_consolid_add_l,
                                            gn_c_leaf_consolid_add_d,
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
        lv_log_data := TO_CHAR(ln_index,'99999') || gv_c_space || fdata_tbl(ln_index).line;
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
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_dv_chargesif_id NUMBER; -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
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
    ln_dv_chargesif_id := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- �^���A�h�I���}�X�^�C���^�t�F�[�XID�̔�
      SELECT xxwip_delivery_charg_if_id_s1.NEXTVAL
      INTO ln_dv_chargesif_id
      FROM dual;
--
      -- ���R�[�h���
      -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
      gt_dv_charges_if_id_tab(ln_index)  := ln_dv_chargesif_id;
      -- �x�������敪
      gt_p_b_classe_tab(ln_index)        := fdata_tbl(ln_index).p_b_classe;
      -- ���i�敪
      gt_goods_classe_tab(ln_index)      := fdata_tbl(ln_index).goods_classe;
      -- �^���Ǝ�
      gt_dv_company_code_tab(ln_index)   := fdata_tbl(ln_index).dv_company_code;
      -- �z���敪
      gt_sp_address_classe_tab(ln_index) := fdata_tbl(ln_index).sp_address_classe;
      -- �^������
      gt_delivery_distance_tab(ln_index) := TO_NUMBER(fdata_tbl(ln_index).delivery_distance);
      -- �d��
      gt_delivery_weight_tab(ln_index)   := TO_NUMBER(fdata_tbl(ln_index).delivery_weight);
      -- �K�p�J�n��
      gt_start_date_active_tab(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).start_date_active, 'RR/MM/DD');
      -- �^����
      gt_shipping_expenses_tab(ln_index) := TO_NUMBER(fdata_tbl(ln_index).shipping_expenses);
      -- ���[�t���ڊ���
      gt_leaf_consolid_add_tab(ln_index) := TO_NUMBER(fdata_tbl(ln_index).leaf_consolid_add);
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
   * Procedure Name   : insert_dv_charges_if_proc
   * Description      : �f�[�^�o�^ (J-4)
   ***********************************************************************************/
  PROCEDURE insert_dv_charges_if_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dv_charges_if_proc'; -- �v���O������
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
    -- *** �^���A�h�I���}�X�^�C���^�t�F�[�X�o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_dv_charges_if_id_tab.COUNT
      INSERT INTO xxwip_delivery_charges_if
      (   delivery_charges_if_id             -- �^���A�h�I���}�X�^�C���^�t�F�[�XID
        , p_b_classe                         -- �x�������敪
        , goods_classe                       -- ���i�敪
        , delivery_company_code              -- �^���Ǝ�
        , shipping_address_classe            -- �z���敪
        , delivery_distance                  -- �^������
        , delivery_weight                    -- �d��
        , start_date_active                  -- �K�p�J�n��
        , shipping_expenses                  -- �^����
        , leaf_consolid_add                  -- ���[�t���ڊ���
        , created_by                         -- �쐬��
        , creation_date                      -- �쐬��
        , last_updated_by                    -- �ŏI�X�V��
        , last_update_date                   -- �ŏI�X�V��
        , last_update_login                  -- �ŏI�X�V���O�C��
        , request_id                         -- �v��ID
        , program_application_id             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                         -- �R���J�����g�E�v���O����ID
        , program_update_date                -- �v���O�����X�V��
      ) VALUES (
          gt_dv_charges_if_id_tab(item_cnt)  -- �^���A�h�I���}�X�^�C��
        , gt_p_b_classe_tab(item_cnt)        -- �x�������敪
        , gt_goods_classe_tab(item_cnt)      -- ���i�敪
        , gt_dv_company_code_tab(item_cnt)   -- �^���Ǝ�
        , gt_sp_address_classe_tab(item_cnt) -- �z���敪
        , gt_delivery_distance_tab(item_cnt) -- �^������
        , gt_delivery_weight_tab(item_cnt)   -- �d��
        , gt_start_date_active_tab(item_cnt) -- �K�p�J�n��
        , gt_shipping_expenses_tab(item_cnt) -- �^����
        , gt_leaf_consolid_add_tab(item_cnt) -- ���[�t���ڊ���
        , gn_user_id                         -- �쐬��
        , gd_sysdate                         -- �쐬��
        , gn_user_id                         -- �ŏI�X�V��
        , gd_sysdate                         -- �ŏI�X�V��
        , gn_login_id                        -- �ŏI�X�V���O�C��
        , gn_conc_request_id                 -- �v��ID
        , gn_prog_appl_id                    -- �ݶ��āE��۸��т̱��ع����ID
        , gn_conc_program_id                 -- �R���J�����g�E�v���O����ID
        , gd_sysdate                         -- �v���O�����ɂ��X�V��
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
  END insert_dv_charges_if_proc;
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
--
    lv_out_rep VARCHAR2(1000);  -- ���|�[�g�o��
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
--
    -- �Ó����`�F�b�N�X�e�[�^�X ������
    gv_check_proc_retcode := gv_status_normal;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �֘A�f�[�^�擾 (J-1)
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾 (J-2,3)
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
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_file_name,
                                              gv_c_tkn_value,
                                              gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_up_date,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,
                                              gv_c_msg_up_name,
                                              gv_c_tkn_value,
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
    -- �Ó����`�F�b�N (J-3)
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
      -- �f�[�^�o�^ (J-4)
      -- ===============================
      insert_dv_charges_if_proc(
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
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜 (J-5)
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
      -- �폜�����G���[����RollBack������ׁA�Ó����`�F�b�N�X�e�[�^�X��������
      gv_check_proc_retcode := gv_status_normal;
      RAISE global_process_expt;
    END IF;
--
    -- �`�F�b�N�����G���[
    IF (gv_check_proc_retcode = gv_status_error) THEN
      -- �Œ�̃G���[���b�Z�[�W�̏o�͂����Ȃ��悤�ɂ���
      lv_errmsg := gv_c_space;
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
END xxinv990009c;
/
