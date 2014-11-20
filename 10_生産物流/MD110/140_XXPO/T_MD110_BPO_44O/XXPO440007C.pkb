CREATE OR REPLACE PACKAGE BODY xxpo440007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440007c(body)
 * Description      : �x�����i�ύX����
 * MD.050           : �L���x��            T_MD050_BPO_440
 * MD.070           : �x�����i�ύX����    T_MD070_BPO_44O
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  tbl_lock               �󒍖��׃A�h�I���̃��b�N
 *  init_proc              �O����                                          (O-1)
 *  parameter_check        �p�����[�^�`�F�b�N                              (O-2)
 *  get_data               �x���f�[�^�擾                                  (O-3)
 *  upd_lines              �󒍖��׍X�V                                    (O-6)
 *  disp_report            �������ʏ��o��                                (O-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/15    1.0   Oracle �R�� ��_ ����쐬
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  get_data_expt             EXCEPTION;     -- �x���f�[�^�擾�G���[
  lock_expt                 EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo440007c';    -- �p�b�P�[�W��
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';           -- �A�v���P�[�V�����Z�k��
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';          -- �A�v���P�[�V�����Z�k��
--
  gv_tkn_ng_profile     CONSTANT VARCHAR2(20) := 'NG_PROFILE';
  gv_tkn_data           CONSTANT VARCHAR2(20) := 'DATA';
  gv_tkn_param          CONSTANT VARCHAR2(20) := 'PARAM';
  gv_tkn_param_name     CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  gv_tkn_param_value    CONSTANT VARCHAR2(20) := 'PARAM_VALUE';
  gv_tkn_format         CONSTANT VARCHAR2(20) := 'FORMAT';
  gv_tkn_entry          CONSTANT VARCHAR2(20) := 'ENTRY';
  gv_tkn_cnt_all        CONSTANT VARCHAR2(20) := 'CNT_ALL';
  gv_tkn_cnt_out        CONSTANT VARCHAR2(20) := 'CNT_OUT';
  gv_tkn_cnt_in         CONSTANT VARCHAR2(20) := 'CNT_IN';
  gv_tkn_i_no           CONSTANT VARCHAR2(20) := 'I_NO';
  gv_tkn_vendor_cd      CONSTANT VARCHAR2(20) := 'VENDOR_CD';
  gv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  gv_tkn_item_no        CONSTANT VARCHAR2(20) := 'ITEM_NO';
  gv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
--
  gv_tkn_name_dept_code   CONSTANT VARCHAR2(100) := '�S�������R�[�h';
  gv_tkn_name_from_date   CONSTANT VARCHAR2(100) := '���ɓ�_FROM';
  gv_tkn_name_to_date     CONSTANT VARCHAR2(100) := '���ɓ�_TO';
  gv_tkn_name_prod_class  CONSTANT VARCHAR2(100) := '���i�敪';
  gv_tkn_name_item_class  CONSTANT VARCHAR2(100) := '�i�ڋ敪';
  gv_tkn_name_vendor_code CONSTANT VARCHAR2(100) := '�����R�[�h';
  gv_tkn_name_item_code   CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
  gv_tkn_name_request_no  CONSTANT VARCHAR2(100) := '�˗�No';
--
  gn_exec_flg_on          CONSTANT NUMBER := 1;
  gn_exec_flg_off         CONSTANT NUMBER := 0;
--
  gv_flg_on               CONSTANT VARCHAR2(1) := 'Y';
  gv_flg_off              CONSTANT VARCHAR2(1) := 'N';
  gv_fix_class_on         CONSTANT VARCHAR2(1) := '1';
  gv_fix_class_off        CONSTANT VARCHAR2(1) := '0';
  gv_req_status_on        CONSTANT VARCHAR2(2) := '00';
  gv_req_status_off       CONSTANT VARCHAR2(2) := '99';
  gv_category_code_rtn    CONSTANT VARCHAR2(9) := 'RETURN';
  gv_shikyu_class         CONSTANT VARCHAR2(1) := '2';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- �Ώۃf�[�^
  TYPE masters_rec IS RECORD(
    order_header_id    xxwsh_order_headers_all.order_header_id%TYPE,  -- �󒍃w�b�_�A�h�I��ID
    spare2             xxcmn_vendors_v.spare2%TYPE,                   -- �����ʉ��i�\ID
    arrival_date       xxwsh_order_headers_all.arrival_date%TYPE,     -- ���ד�
    item_class_code    xxcmn_item_categories3_v.item_class_code%TYPE, -- �i�ڋ敪
    item_no            xxcmn_item_mst_v.item_no%TYPE,                 -- OPM�i�ڃR�[�h
--
    request_no         xxwsh_order_headers_all.request_no%TYPE,       -- �˗�No
    vendor_code        xxwsh_order_headers_all.vendor_code%TYPE,      -- �����
--
    exec_flg           NUMBER                                         -- �����t���O
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;  -- �e�}�X�^�֓o�^����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_xxpo_price_list_id       VARCHAR2(20);               -- XXPO:��\���i�\
  gv_org_id                   VARCHAR2(20);               -- MO:�c�ƒP��
  gv_close_date               VARCHAR2(6);                -- CLOSE�N����
--
  gd_from_date                DATE;
  gd_to_date                  DATE;
--
  -- �萔
  gn_created_by               NUMBER;                     -- �쐬��
  gd_creation_date            DATE;                       -- �쐬��
  gd_last_update_date         DATE;                       -- �ŏI�X�V��
  gn_last_update_by           NUMBER;                     -- �ŏI�X�V��
  gn_last_update_login        NUMBER;                     -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER;                     -- �v��ID
  gn_program_application_id   NUMBER;                     -- �v���O�����A�v���P�[�V����ID
  gn_program_id               NUMBER;                     -- �v���O����ID
  gd_program_update_date      DATE;                       -- �v���O�����X�V��
--
  gn_keep_cnt                 NUMBER;                     -- �ێ�����
  gn_other_cnt                NUMBER;                     -- ���̑�����
--
  /***********************************************************************************
   * Procedure Name   : tbl_lock
   * Description      : �󒍖��׃A�h�I���̃��b�N
   ***********************************************************************************/
  PROCEDURE tbl_lock(
    ir_mst_rec      IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'tbl_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_tbl_name     CONSTANT VARCHAR2(100) := '�󒍖��׃A�h�I��';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT xola.order_line_id
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_header_id = ir_mst_rec.order_header_id   -- �󒍃w�b�_�A�h�I��ID
      AND    NVL(xola.delete_flag,gv_flg_off) = gv_flg_off       -- �폜�t���O
      AND    xola.shipping_item_code = ir_mst_rec.item_no        -- �o�וi�ڃR�[�h
      FOR UPDATE OF xola.order_line_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �󒍖��׃A�h�I���̃��b�N
    OPEN lock_cur;
--
  EXCEPTION
    -- *** ���b�N�l�����s�n���h�� ***
    WHEN lock_expt THEN
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10027',
                                            gv_tkn_table,
                                            lv_tbl_name);
      ov_errbuf  := ov_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||ov_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �O����(O-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_dept_code   IN            VARCHAR2,     -- 1.�S�������R�[�h(�K�{)
    iv_from_date   IN            VARCHAR2,     -- 2.���ɓ�(FROM)(�C��)
    iv_to_date     IN            VARCHAR2,     -- 3.���ɓ�(TO)(�C��)
    iv_prod_class  IN            VARCHAR2,     -- 4.���i�敪(�K�{)
    iv_item_class  IN            VARCHAR2,     -- 5.�i�ڋ敪(�C��)
    iv_vendor_code IN            VARCHAR2,     -- 6.�����R�[�h(�C��)
    iv_item_code   IN            VARCHAR2,     -- 7.�i�ڃR�[�h(�C��)
    iv_request_no  IN            VARCHAR2,     -- 8.�˗�No(�C��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- XXPO:��\���i�\
    gv_xxpo_price_list_id := FND_PROFILE.VALUE('XXPO_PRICE_LIST_ID');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_xxpo_price_list_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10113');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- MO:�c�ƒP��
    gv_org_id := FND_PROFILE.VALUE('ORG_ID');
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10005');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- WHO�J�����̎擾
    gn_created_by             := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date          := SYSDATE;                      -- �쐬��
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_update_date       := SYSDATE;                      -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_program_update_date    := SYSDATE;                      -- �v���O�����X�V��
--
    gv_close_date             := xxcmn_common_pkg.get_opminv_close_period;  -- CLOSE�N����
--
    -- �p�����[�^�o��:�S�������R�[�h
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_dept_code,
                                          gv_tkn_data,
                                          iv_dept_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:���ɓ�_FROM
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_from_date,
                                          gv_tkn_data,
                                          iv_from_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:���ɓ�_TO
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_to_date,
                                          gv_tkn_data,
                                          iv_to_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:���i�敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_prod_class,
                                          gv_tkn_data,
                                          iv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:�i�ڋ敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_item_class,
                                          gv_tkn_data,
                                          iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:�����R�[�h
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_vendor_code,
                                          gv_tkn_data,
                                          iv_vendor_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:�i�ڃR�[�h
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_item_code,
                                          gv_tkn_data,
                                          iv_item_code);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �p�����[�^�o��:�˗�No
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30022',
                                          gv_tkn_param,
                                          gv_tkn_name_request_no,
                                          gv_tkn_data,
                                          iv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^�`�F�b�N(O-2)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_dept_code   IN            VARCHAR2,     -- 1.�S�������R�[�h(�K�{)
    iv_from_date   IN            VARCHAR2,     -- 2.���ɓ�(FROM)(�C��)
    iv_to_date     IN            VARCHAR2,     -- 3.���ɓ�(TO)(�C��)
    iv_prod_class  IN            VARCHAR2,     -- 4.���i�敪(�K�{)
    iv_item_class  IN            VARCHAR2,     -- 5.�i�ڋ敪(�C��)
    iv_vendor_code IN            VARCHAR2,     -- 6.�����R�[�h(�C��)
    iv_item_code   IN            VARCHAR2,     -- 7.�i�ڃR�[�h(�C��)
    iv_request_no  IN            VARCHAR2,     -- 8.�˗�No(�C��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt               NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �S�������ɐݒ肪���邩�ǂ����K�{�`�F�b�N
    IF (iv_dept_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10096',
                                            gv_tkn_entry,
                                            gv_tkn_name_dept_code);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���i�敪�ɐݒ肪���邩�ǂ����K�{�`�F�b�N
    IF (iv_prod_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10096',
                                            gv_tkn_entry,
                                            gv_tkn_name_prod_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���i�敪��XXPO�J�e�S�����VIEW�ɒ�`����Ă��邩�`�F�b�N
    SELECT COUNT(xcv.category_set_id)
    INTO   ln_cnt
    FROM   xxpo_categories_v xcv
    WHERE  xcv.category_set_name = gv_tkn_name_prod_class             -- ���i�敪
    AND    xcv.enable_flag       = gv_flg_on                          -- Y
    AND    xcv.category_code     = iv_prod_class
    AND    ROWNUM                = 1;
--
    -- ���݂��Ȃ�
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10103',
                                            gv_tkn_param_name,
                                            gv_tkn_name_prod_class,
                                            gv_tkn_param_value,
                                            iv_prod_class);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���ɓ�(FROM)�̓��͂���
    IF (iv_from_date IS NOT NULL) THEN
--
      -- ���t�ɕϊ�
      gd_from_date := FND_DATE.STRING_TO_DATE(iv_from_date,'YYYY/MM/DD');
--
      -- ���t�Ƃ��đÓ��łȂ�
      IF (gd_from_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10034',
                                              gv_tkn_param,
                                              gv_tkn_name_from_date,
                                              gv_tkn_format,
                                              'YYYY/MM/DD');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���ɓ�(TO)�̓��͂���
    IF (iv_to_date IS NOT NULL) THEN
--
      -- ���t�ɕϊ�
      gd_to_date := FND_DATE.STRING_TO_DATE(iv_to_date,'YYYY/MM/DD');
--
      -- ���t�Ƃ��đÓ��łȂ�
      IF (gd_to_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10034',
                                              gv_tkn_param,
                                              gv_tkn_name_to_date,
                                              gv_tkn_format,
                                              'YYYY/MM/DD');
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���ɓ����͂���
    IF ((iv_from_date IS NOT NULL) AND (iv_to_date IS NOT NULL)) THEN
--
      -- ���ɓ��iFROM�j�Ɠ��ɓ��iTO�j���t�]���Ă��Ȃ����召��r�`�F�b�N
      IF (gd_from_date > gd_to_date) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                              'APP-XXPO-10139',
                                              gv_tkn_param,
                                              gv_tkn_name_to_date);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END parameter_check;
--
  /***********************************************************************************
   * Procedure Name   : get_data
   * Description      : �x���f�[�^�擾(O-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_dept_code   IN            VARCHAR2,     -- 1.�S�������R�[�h(�K�{)
    iv_from_date   IN            VARCHAR2,     -- 2.���ɓ�(FROM)(�C��)
    iv_to_date     IN            VARCHAR2,     -- 3.���ɓ�(TO)(�C��)
    iv_prod_class  IN            VARCHAR2,     -- 4.���i�敪(�K�{)
    iv_item_class  IN            VARCHAR2,     -- 5.�i�ڋ敪(�C��)
    iv_vendor_code IN            VARCHAR2,     -- 6.�����R�[�h(�C��)
    iv_item_code   IN            VARCHAR2,     -- 7.�i�ڃR�[�h(�C��)
    iv_request_no  IN            VARCHAR2,     -- 8.�˗�No(�C��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_tbl_name     CONSTANT VARCHAR2(100) := '�󒍖��׃A�h�I��';
--
    -- *** ���[�J���ϐ� ***
    ln_cnt              NUMBER;
    ln_order_line_id    xxwsh_order_lines_all.order_line_id%TYPE;
    mst_rec             masters_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mst_data_cur
    IS
      SELECT xoha.order_header_id                       -- �󒍃w�b�_�A�h�I��ID
            ,xoha.arrival_date                          -- ���ד�
            ,xoha.schedule_arrival_date                 -- ���ח\���
            ,xoha.request_no                            -- �˗�No
            ,xoha.vendor_code                           -- �����
            ,xvv.spare2                                 -- �����ʉ��i�\ID
            ,xicv.item_class_code                       -- �i�ڋ敪
            ,ximv.item_no                               -- OPM�i�ڃR�[�h
      FROM   xxwsh_order_headers_all      xoha   -- �󒍃w�b�_�A�h�I��
            ,oe_transaction_types_all     ota    -- �󒍃^�C�v
            ,xxcmn_item_mst_v             ximv   -- OPM�i�ڏ��VIEW
            ,xxcmn_item_categories3_v     xicv   -- OPM�i�ڃJ�e�S���������VIEW3
            ,xxcmn_vendors_v              xvv    -- �d������VIEW
            ,xxwsh_oe_transaction_types_v xotv   -- �󒍃^�C�v���VIEW
      WHERE  ota.transaction_type_id  = xoha.order_type_id
      AND    ximv.item_id             = xicv.item_id
      AND    xoha.vendor_id           = xvv.vendor_id
      AND    ota.transaction_type_id  = xotv.transaction_type_id
      AND    NVL(xoha.latest_external_flag,gv_flg_off) = gv_flg_on            -- �ŐV
      AND    NVL(xoha.amount_fix_class,gv_fix_class_off) <> gv_fix_class_on   -- �m��ȊO
      AND    NVL(xoha.req_status,gv_req_status_on) <> gv_req_status_off       -- ����ȊO
      AND    xotv.shipping_shikyu_class = gv_shikyu_class                     -- �x���˗�
      AND    xotv.order_category_code <> gv_category_code_rtn                 -- �ԕi�ȊO
      AND    EXISTS (
        SELECT xola.order_header_id
        FROM   xxwsh_order_lines_all xola        -- �󒍖��׃A�h�I��
        WHERE  xola.order_header_id            = xoha.order_header_id
        AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
        AND    NVL(xola.delete_flag,gv_flg_off) = gv_flg_off                  -- ���폜
        AND    ((iv_item_code IS NULL) OR (xola.shipping_item_code = iv_item_code)))
      AND    TO_CHAR(xoha.shipped_date,'YYYYMM') > gv_close_date
      AND    ota.org_id = gv_org_id
      AND    xoha.performance_management_dept = iv_dept_code
      AND    ((xicv.prod_class_code IS NOT NULL)
      AND     (xicv.prod_class_code = iv_prod_class))
      AND    ((iv_from_date IS NULL)
      OR      (NVL(xoha.arrival_date,xoha.schedule_arrival_date) >= iv_from_date))
      AND    ((iv_to_date IS NULL)
      OR      (NVL(xoha.arrival_date,xoha.schedule_arrival_date) <= iv_to_date))
      AND   ((iv_item_class IS NULL)
      OR     ((xicv.item_class_code IS NOT NULL)
      AND     (xicv.item_class_code = iv_item_class)))
      AND   ((iv_vendor_code IS NULL) OR (xoha.vendor_code = iv_vendor_code))
      AND   ((iv_request_no IS NULL)  OR (xoha.request_no  = iv_request_no))
      ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    ln_cnt := 0;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
      mst_rec.order_header_id := lr_mst_data_rec.order_header_id;
      mst_rec.spare2          := lr_mst_data_rec.spare2;
      mst_rec.arrival_date    := lr_mst_data_rec.arrival_date;
      mst_rec.item_class_code := lr_mst_data_rec.item_class_code;
      mst_rec.item_no         := lr_mst_data_rec.item_no;
      mst_rec.request_no      := lr_mst_data_rec.request_no;
      mst_rec.vendor_code     := lr_mst_data_rec.vendor_code;
--
      -- ���ד���NULL�Ȃ璅�ח\�����ݒ�
      IF (mst_rec.arrival_date IS NULL) THEN
        mst_rec.arrival_date := lr_mst_data_rec.schedule_arrival_date;
      END IF;
--
      gt_master_tbl(ln_cnt)   := mst_rec;
--
      -- �󒍖��׃A�h�I���̃��b�N
      IF (mst_rec.order_header_id IS NOT NULL) THEN
--
        -- �e�[�u���̃��b�N
        tbl_lock(mst_rec,
                 lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                 lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                 lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            'APP-XXPO-10026',
                                            'TABLE',
                                            lv_tbl_name);
      lv_errbuf := lv_errmsg;
      RAISE get_data_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN get_data_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_lines
   * Description      : �󒍖��׍X�V(O-6)
   ***********************************************************************************/
  PROCEDURE upd_lines(
    ir_mst_rec      IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lines'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg_num         VARCHAR2(20);
    lv_date            VARCHAR2(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �󒍖��׃A�h�I���P���X�V����
    xxpo_common2_pkg.update_order_unit_price(
      in_order_header_id    => ir_mst_rec.order_header_id     -- �󒍃w�b�_�A�h�I��ID
     ,iv_list_id_vendor     => ir_mst_rec.spare2              -- �����ʉ��i�\ID
     ,iv_list_id_represent  => gv_xxpo_price_list_id          -- ��\���i�\ID
     ,id_arrival_date       => ir_mst_rec.arrival_date        -- �K�p��(���ɓ�)
     ,iv_return_flag        => 'N'                            -- �ԕi�t���O
     ,iv_item_class_code    => ir_mst_rec.item_class_code     -- �i�ڋ敪
     ,iv_item_no            => ir_mst_rec.item_no             -- OPM�i�ڃR�[�h
     ,ov_retcode            => lv_retcode                     -- �G���[�R�[�h
     ,ov_errmsg             => lv_errbuf                      -- �G���[���b�Z�[�W
     ,ov_system_msg         => lv_errmsg                      -- �V�X�e�����b�Z�[�W
    );
--
    -- ��������
    IF (lv_retcode = gv_status_normal) THEN
--
      -- �X�V�Ώ�
      IF (lv_errbuf IS NULL) THEN
        lv_msg_num := 'APP-XXPO-30048';
        gn_keep_cnt := gn_keep_cnt + 1;
--
      -- �X�V�ΏۊO
      ELSE
        lv_msg_num := 'APP-XXPO-30049';
        gn_other_cnt := gn_other_cnt + 1;
      END IF;
--
    -- �P���擾�G���[
    ELSIF (lv_retcode = gv_status_warn) THEN
      lv_msg_num := 'APP-XXPO-30049';
      gn_other_cnt := gn_other_cnt + 1;
--
    -- �������s
    ELSE
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    lv_date := TO_CHAR(ir_mst_rec.arrival_date,'YYYY/MM/DD');
--
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          lv_msg_num,
                                          gv_tkn_i_no,
                                          ir_mst_rec.request_no,
                                          gv_tkn_vendor_cd,
                                          ir_mst_rec.vendor_code,
                                          gv_tkn_date,
                                          lv_date,
                                          gv_tkn_item_no,
                                          ir_mst_rec.item_no);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END upd_lines;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : �������ʏ��o��(O-7)
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �x���f�[�^���o����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30044',
                                          gv_tkn_cnt_all,
                                          gt_master_tbl.COUNT);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �P���X�V�ΏۊO����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30045',
                                          gv_tkn_cnt_out,
                                          gn_other_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �P���X�V�Ώی���
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          'APP-XXPO-30046',
                                          gv_tkn_cnt_in,
                                          gn_keep_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_dept_code   IN            VARCHAR2,     -- 1.�S�������R�[�h
    iv_from_date   IN            VARCHAR2,     -- 2.���ɓ�(FROM)
    iv_to_date     IN            VARCHAR2,     -- 3.���ɓ�(TO)
    iv_prod_class  IN            VARCHAR2,     -- 4.���i�敪
    iv_item_class  IN            VARCHAR2,     -- 5.�i�ڋ敪
    iv_vendor_code IN            VARCHAR2,     -- 6.�����R�[�h
    iv_item_code   IN            VARCHAR2,     -- 7.�i�ڃR�[�h
    iv_request_no  IN            VARCHAR2,     -- 8.�˗�No
    ov_errbuf         OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_mst_rec         masters_rec;
    ld_from_date       DATE;
    ld_to_date         DATE;
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
    gn_keep_cnt   := 0;
    gn_other_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ================================
    -- O-1.�O����
    -- ================================
    init_proc(
      iv_dept_code,       -- 1.�S�������R�[�h
      iv_from_date,       -- 2.���ɓ�(FROM)
      iv_to_date,         -- 3.���ɓ�(TO)
      iv_prod_class,      -- 4.���i�敪
      iv_item_class,      -- 5.�i�ڋ敪
      iv_vendor_code,     -- 6.�����R�[�h
      iv_item_code,       -- 7.�i�ڃR�[�h
      iv_request_no,      -- 8.�˗�No
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- O-2.�p�����[�^�`�F�b�N
    -- ================================
    parameter_check(
      iv_dept_code,       -- 1.�S�������R�[�h
      iv_from_date,       -- 2.���ɓ�(FROM)
      iv_to_date,         -- 3.���ɓ�(TO)
      iv_prod_class,      -- 4.���i�敪
      iv_item_class,      -- 5.�i�ڋ敪
      iv_vendor_code,     -- 6.�����R�[�h
      iv_item_code,       -- 7.�i�ڃR�[�h
      iv_request_no,      -- 8.�˗�No
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    -- O-3.�x���f�[�^�擾
    -- ================================
    get_data(
      iv_dept_code,       -- 1.�S�������R�[�h
      gd_from_date,       -- 2.���ɓ�(FROM)
      gd_to_date,         -- 3.���ɓ�(TO)
      iv_prod_class,      -- 4.���i�敪
      iv_item_class,      -- 5.�i�ڋ敪
      iv_vendor_code,     -- 6.�����R�[�h
      iv_item_code,       -- 7.�i�ڃR�[�h
      iv_request_no,      -- 8.�˗�No
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
    -- �Ώۃf�[�^����
    IF (gt_master_tbl.COUNT > 0) THEN
--
      <<upd_loop>>
      FOR i IN 0..gt_master_tbl.COUNT-1 LOOP
        lr_mst_rec := gt_master_tbl(i);
--
        -- ================================
        -- O-6.�󒍖��׍X�V
        -- ================================
        upd_lines(
          lr_mst_rec,         -- �Ώۃf�[�^
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP upd_loop;
    END IF;
--
    -- ================================
    -- O-7.�������ʏ��o��
    -- ================================
    disp_report(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
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
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_dept_code   IN            VARCHAR2,      -- 1.�S�������R�[�h
    iv_from_date   IN            VARCHAR2,      -- 2.���ɓ�(FROM)
    iv_to_date     IN            VARCHAR2,      -- 3.���ɓ�(TO)
    iv_prod_class  IN            VARCHAR2,      -- 4.���i�敪
    iv_item_class  IN            VARCHAR2,      -- 5.�i�ڋ敪
    iv_vendor_code IN            VARCHAR2,      -- 6.�����R�[�h
    iv_item_code   IN            VARCHAR2,      -- 7.�i�ڃR�[�h
    iv_request_no  IN            VARCHAR2)      -- 8.�˗�No
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
      iv_dept_code,    -- 1.�S�������R�[�h
      iv_from_date,    -- 2.���ɓ�(FROM)
      iv_to_date,      -- 3.���ɓ�(TO)
      iv_prod_class,   -- 4.���i�敪
      iv_item_class,   -- 5.�i�ڋ敪
      iv_vendor_code,  -- 6.�����R�[�h
      iv_item_code,    -- 7.�i�ڃR�[�h
      iv_request_no,   -- 8.�˗�No
      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo440007c;
/
