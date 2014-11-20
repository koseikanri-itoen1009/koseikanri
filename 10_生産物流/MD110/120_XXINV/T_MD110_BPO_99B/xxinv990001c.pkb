CREATE OR REPLACE PACKAGE BODY xxinv990001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV990001C(body)
 * Description      : �̔��v��/����v��̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h            T_MD050_BPO_990
 * MD.070           : �̔��v��/����v��̃A�b�v���[�h T_MD070_BPO_99B
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  check_param            �p�����[�^�`�F�b�N(B-1)
 *  init_proc              �֘A�f�[�^�擾(B-2)
 *  get_upload_data_proc   �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾(B-3)
 *  check_proc             �Ó����`�F�b�N (B-4)
 *  set_data_proc          �o�^�f�[�^�Z�b�g
 *  insert_mrp_forecast_if �f�[�^�o�^(B-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/20    1.0  Oracle �a�c ��P  ����쐬
 *  2008/04/18    1.1  Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/04/24    1.2  Oracle ���� ���b  �����R�[�h�擾���ďo���ʊ֐��ύX
 *  2008/04/25    1.3  Oracle �R�� ��_  �ύX�v��No70�Ή�
 *  2008/04/25    1.3  Oracle �R�� ��_  �ύX�v��No73�Ή�
 *  2008/07/08    1.4  Oracle �R�� ��_  I_S_192�Ή�
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
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt              EXCEPTION;     -- ���b�N�擾�G���[
  no_data_if_expt           EXCEPTION;     -- �Ώۃf�[�^�Ȃ�
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxinv990001c'; -- �p�b�P�[�W��
--
  -- �t�H�[�}�b�g�p�^�[�����ʃR�[�h
  gv_format_code_01      CONSTANT VARCHAR2(2) := '01';
  gv_format_code_02      CONSTANT VARCHAR2(2) := '02';
  gv_format_code_03      CONSTANT VARCHAR2(2) := '03';
  gv_format_code_04      CONSTANT VARCHAR2(2) := '04';
  gv_format_code_05      CONSTANT VARCHAR2(2) := '05';
--
  gv_c_msg_kbn           CONSTANT VARCHAR2(5) := 'XXINV'; -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  gv_c_msg_99b_008 CONSTANT VARCHAR2(15) := 'APP-XXINV-10008'; -- �f�[�^�擾�G���[���b�Z�[�W
  gv_c_msg_99b_016 CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- �p�����[�^�G���[���b�Z�[�W
  gv_c_msg_99b_024 CONSTANT VARCHAR2(15) := 'APP-XXINV-10024'; -- �t�H�[�}�b�g�G���[���b�Z�[�W
  gv_c_msg_99b_025 CONSTANT VARCHAR2(15) := 'APP-XXINV-10025'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_c_msg_99b_032 CONSTANT VARCHAR2(15) := 'APP-XXINV-10032'; -- ���b�N�G���[���b�Z�[�W
--
  gv_c_msg_99b_101       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00001'; -- �t�@�C����
  gv_c_msg_99b_103       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00003'; -- �A�b�v���[�h����
  gv_c_msg_99b_104       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00004'; -- �t�@�C���A�b�v���[�h����
  gv_c_msg_99b_106       CONSTANT VARCHAR2(15)  := 'APP-XXINV-00006'; -- �t�H�[�}�b�g�p�^�[��
--
  -- �g�[�N��
  gv_c_tkn_param         CONSTANT VARCHAR2(15) := 'PARAMETER';
  gv_c_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';
  gv_c_tkn_name          CONSTANT VARCHAR2(15) := 'NAME';
  gv_c_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';
  gv_c_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
--
  -- �v���t�@�C��
  gv_c_parge_term_001    CONSTANT VARCHAR2(20) := 'XXINV_PURGE_TERM_001';
  gv_c_parge_term_name   CONSTANT VARCHAR2(40) := '�p�[�W�Ώۊ��ԁF�̔��v�����v��';
--
  -- �N�C�b�N�R�[�h �^�C�v
  gv_c_lookup_type       CONSTANT VARCHAR2(30) := 'XXINV_FILE_OBJECT';
  gv_c_format_type       CONSTANT VARCHAR2(20) := '�t�H�[�}�b�g�p�^�[��';
--
  gv_user_id_name        CONSTANT VARCHAR2(10) := '���[�U�[ID';
  gv_file_id_name        CONSTANT VARCHAR2(24) := 'FILE_ID';
  gv_file_up_if_tbl      CONSTANT VARCHAR2(50) := '�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u��';
--
  gv_period              CONSTANT VARCHAR2(1) := '.';      -- �s���I�h
  gv_comma               CONSTANT VARCHAR2(1) := ',';      -- �J���}
  gv_space               CONSTANT VARCHAR2(1) := ' ';      -- �X�y�[�X
  gv_err_msg_space       CONSTANT VARCHAR2(6) := '      '; -- �X�y�[�X�i6byte�j
--
  -- �̔��v��/����v��C���^�t�F�[�X�e�[�u���F���ږ�
  gv_location_code_n     CONSTANT VARCHAR2(50) := '�o�בq��';
  gv_base_code_n         CONSTANT VARCHAR2(50) := '���_';
  gv_dept_code_n         CONSTANT VARCHAR2(50) := '�捞����';
  gv_item_code_n         CONSTANT VARCHAR2(50) := '�i��';
  gv_forecast_date_n     CONSTANT VARCHAR2(50) := '�J�n���t';
  gv_forecast_end_date_n CONSTANT VARCHAR2(50) := '�I�����t';
  gv_case_quantity_n     CONSTANT VARCHAR2(50) := '�P�[�X����';
  gv_indivi_quantity_n   CONSTANT VARCHAR2(50) := '�o������';
  gv_amount_n            CONSTANT VARCHAR2(50) := '���z';
--
  -- �̔��v��/����v��C���^�t�F�[�X�e�[�u���F���ڌ���
  gv_location_code_l     CONSTANT NUMBER := 4;   -- �o�בq��
  gv_base_code_l         CONSTANT NUMBER := 4;   -- ���_
  gv_dept_code_l         CONSTANT NUMBER := 4;   -- �捞����
  gv_item_code_l         CONSTANT NUMBER := 7;   -- �i��
  gv_case_quantity_l     CONSTANT NUMBER := 38;  -- �P�[�X����(������)
  gv_indivi_quantity_l   CONSTANT NUMBER := 38;  -- �o������
  gv_amount_l            CONSTANT NUMBER := 38;  -- ���z
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- CSV���i�[���郌�R�[�h
  TYPE file_data_rec IS RECORD(
    location_code       VARCHAR2(32767), -- �o�בq��
    base_code           VARCHAR2(32767), -- ���_
    dept_code           VARCHAR2(32767), -- �捞����
    item_code           VARCHAR2(32767), -- �i��
    forecast_date       VARCHAR2(32767), -- �J�n���t
    forecast_end_date   VARCHAR2(32767), -- �I�����t
    case_quantity       VARCHAR2(32767), -- �P�[�X����
    indivi_quantity     VARCHAR2(32767), -- �o������
    amount              VARCHAR2(32767), -- ���z
    line                VARCHAR2(32767), -- �s���e�S�āi��������p�j
    err_message         VARCHAR2(32767)  -- �G���[���b�Z�[�W�i��������p�j
  );
--
  -- CSV���i�[���錋���z��
  TYPE file_data_tbl IS TABLE OF file_data_rec INDEX BY BINARY_INTEGER;
  fdata_tbl   file_data_tbl;
--
  -- �o�^�pPL/SQL�\�^
  -- 1.���ID
  TYPE forecast_if_id_type        IS TABLE OF xxinv_mrp_forecast_interface.forecast_if_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- 2.Forecast����
  TYPE forecast_designator_type   IS TABLE OF xxinv_mrp_forecast_interface.forecast_designator%TYPE
  INDEX BY BINARY_INTEGER; 
  -- 3.�o�בq��
  TYPE location_code_type         IS TABLE OF xxinv_mrp_forecast_interface.location_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 4.���_
  TYPE base_code_type             IS TABLE OF xxinv_mrp_forecast_interface.base_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 5.�捞����
  TYPE dept_code_type             IS TABLE OF xxinv_mrp_forecast_interface.dept_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 6.�i��
  TYPE item_code_type             IS TABLE OF xxinv_mrp_forecast_interface.item_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- 7.�J�n���t
  TYPE forecast_date_type         IS TABLE OF xxinv_mrp_forecast_interface.forecast_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 8.�I�����t
  TYPE forecast_end_date_type     IS TABLE OF xxinv_mrp_forecast_interface.forecast_end_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- 9.�P�[�X����
  TYPE case_quantity_type         IS TABLE OF xxinv_mrp_forecast_interface.case_quantity%TYPE
  INDEX BY BINARY_INTEGER;
  -- 10.�o������
  TYPE indivi_quantity_type       IS TABLE OF xxinv_mrp_forecast_interface.indivi_quantity%TYPE
  INDEX BY BINARY_INTEGER;
  -- 11.���z
  TYPE amount_type                IS TABLE OF xxinv_mrp_forecast_interface.amount%TYPE
  INDEX BY BINARY_INTEGER;
--
  gt_forecast_if_id        forecast_if_id_type;      -- 1.���ID
  gt_forecast_designator   forecast_designator_type; -- 2.Forecast����
  gt_location_code         location_code_type;       -- 3.�o�בq��
  gt_base_code             base_code_type;           -- 4.���_
  gt_dept_code             dept_code_type;           -- 5.�捞����
  gt_item_code             item_code_type;           -- 6.�i��
  gt_forecast_date         forecast_date_type;       -- 7.�J�n���t
  gt_forecast_end_date     forecast_end_date_type;   -- 8.�I�����t
  gt_case_quantity         case_quantity_type;       -- 9.�P�[�X����
  gt_indivi_quantity       indivi_quantity_type;     -- 10.�o������
  gt_amount                amount_type;              -- 11.���z
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate               DATE;            -- �V�X�e�����t
  gn_user_id               NUMBER;          -- ���[�UID
  gn_login_id              NUMBER;          -- �ŏI�X�V���O�C��
  gn_conc_request_id       NUMBER;          -- �v��ID
  gn_prog_appl_id          NUMBER;          -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id       NUMBER;          -- �R���J�����g�E�v���O����ID
--
  gn_xxinv_parge_term      NUMBER;          -- �p�[�W�Ώۊ���
  gv_file_name             VARCHAR2(256);   -- �t�@�C����
  gv_file_up_name          VARCHAR2(256);   -- �t�@�C���A�b�v���[�h����
  gv_file_content_type     VARCHAR2(256);   -- �t�@�C�����������I�u�W�F�N�g�^�C�v�R�[�h
  gn_created_by            NUMBER(15);      -- �쐬��
  gd_creation_date         DATE;            -- �쐬��
  gv_check_proc_retcode    VARCHAR2(1);     -- �Ó����`�F�b�N�X�e�[�^�X
  gv_location_code         VARCHAR2(60);    -- ���Ə��R�[�h
--
  /**********************************************************************************
   * Procedure Name   : check_param
   * Description      : �p�����[�^�`�F�b�N(B-1)
   ***********************************************************************************/
  PROCEDURE check_param(
    iv_file_format IN  VARCHAR2,     --   1.�t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param'; -- �v���O������
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
    ln_param_count   NUMBER;   -- �p�����[�^
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�H�[�}�b�g�p�^�[���`�F�b�N
    SELECT COUNT(xlvv.lookup_code) lookup_code -- �R�[�h
    INTO   ln_param_count
    FROM   xxcmn_lookup_values_v xlvv          -- �N�C�b�N�R�[�hVIEW
    WHERE  xlvv.lookup_type = gv_c_lookup_type
    AND    xlvv.lookup_code = iv_file_format
    AND    ROWNUM           = 1;
--
    -- �t�H�[�}�b�g�p�^�[�����N�C�b�N�R�[�h�ɓo�^����Ă��Ȃ��ꍇ
    IF (ln_param_count < 1) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_016,
                                             gv_c_tkn_param, gv_c_format_type,
                                             gv_c_tkn_value, iv_file_format);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END check_param;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾(B-2)
   ***********************************************************************************/
  PROCEDURE init_proc(
    iv_file_format IN  VARCHAR2,     --   1.�t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_parge_term   VARCHAR2(100);   -- �v���t�@�C���i�[�ꏊ
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
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_term := FND_PROFILE.VALUE(gv_c_parge_term_001);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_term IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,  gv_c_msg_99b_025,
                                            gv_c_tkn_name, gv_c_parge_term_name);
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,  gv_c_msg_99b_025,
                                            gv_c_tkn_name, gv_c_parge_term_name);
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
      AND     xlvv.lookup_code = iv_file_format         -- �R�[�h
      AND     ROWNUM           = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                              gv_c_tkn_item,  gv_c_format_type,
                                              gv_c_tkn_value, iv_file_format);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ���Ə��R�[�h�擾
    -- 2008/4/24 modify start
    -- gv_location_code := xxcmn_common_pkg.get_user_dept(gn_user_id);
    gv_location_code := xxcmn_common_pkg.get_user_dept_code(gn_user_id);
    -- 2008/4/24 modify end
--
    -- ���Ə��R�[�h���擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_location_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_user_id_name,
                                            gv_c_tkn_value, gn_user_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Description      : �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾(B-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data_proc(
    in_file_id          IN  NUMBER,            -- FILE_ID
    iv_file_format      IN  VARCHAR2,          -- �t�H�[�}�b�g�p�^�[��
    ov_errbuf           OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_line       VARCHAR2(32767);   -- ���s�R�[�h���̏��
    ln_col        NUMBER;            -- �J����
    lb_col        BOOLEAN := TRUE;   -- �J�����쐬�p��
    ln_length     NUMBER;            -- �����ۊǗp
--
    lt_file_line_data   xxcmn_common3_pkg.g_file_data_tbl;   -- �s�e�[�u���i�[�̈�
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
    SELECT xmf.file_content_type,  -- �t�@�C�����������I�u�W�F�N�g�^�C�v�R�[�h
           xmf.file_name,          -- �t�@�C����
           xmf.created_by,         -- �쐬��
           xmf.creation_date       -- �쐬��
    INTO   gv_file_content_type,
           gv_file_name,
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_file_id_name,
                                            gv_c_tkn_value, in_file_id);
      lv_errbuf := lv_errmsg;
      RAISE no_data_if_expt;
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
        -- ***************************************
        -- ***             1���ږ�             ***
        -- ***************************************
        IF (ln_col = 1) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�u2�v�u4�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- �o�בq��
            fdata_tbl(gn_target_cnt).location_code     := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u3�v�u5�v�̏ꍇ
          ELSIF ((iv_file_format = gv_format_code_03)
              OR (iv_file_format = gv_format_code_05))
          THEN
            -- ���_
            fdata_tbl(gn_target_cnt).base_code         := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             2���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 2) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�u2�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02))
          THEN
            -- ���_
            fdata_tbl(gn_target_cnt).base_code         := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u3�v�u5�v�̏ꍇ
          ELSIF ((iv_file_format = gv_format_code_03)
                 OR (iv_file_format = gv_format_code_05))
          THEN
            -- �i��
            fdata_tbl(gn_target_cnt).item_code         := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u4�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_04) THEN
            -- �捞����
            fdata_tbl(gn_target_cnt).dept_code           := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             3���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 3) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�u2�v�u4�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- �i��
            fdata_tbl(gn_target_cnt).item_code         := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u3�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_03) THEN
            -- �J�n���t
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u5�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- ���t(�J�n���t�ƏI�����t�̗����ɐݒ�)
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
            fdata_tbl(gn_target_cnt).forecast_end_date   := fdata_tbl(gn_target_cnt).forecast_date;
          END IF;
--
        -- ***************************************
        -- ***             4���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 4) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�̏ꍇ
          IF (iv_file_format = gv_format_code_01) THEN
            -- ���t(�J�n���t�ƏI�����t�̗����ɐݒ�)
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
            fdata_tbl(gn_target_cnt).forecast_end_date   := fdata_tbl(gn_target_cnt).forecast_date;
          -- �t�H�[�}�b�g�p�^�[�����u2�v�u4�v�̏ꍇ
          ELSIF ((iv_file_format = gv_format_code_02)
                 OR (iv_file_format = gv_format_code_04))
          THEN
            -- �J�n���t
            fdata_tbl(gn_target_cnt).forecast_date       := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u3�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_03) THEN
            -- �I�����t
            fdata_tbl(gn_target_cnt).forecast_end_date   := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u5�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- �P�[�X����
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             5���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 5) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�u3�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_03))
          THEN
            -- �P�[�X����
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u2�v�u4�v�̏ꍇ
          ELSIF ((iv_file_format = gv_format_code_02)
                OR (iv_file_format = gv_format_code_04))
          THEN
            -- �I�����t
            fdata_tbl(gn_target_cnt).forecast_end_date   := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u5�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- �o������
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             6���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 6) THEN
          -- �t�H�[�}�b�g�p�^�[�����u1�v�u3�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_01)
              OR (iv_file_format = gv_format_code_03))
          THEN
            -- �o������
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u2�v�u4�v�̏ꍇ
          ELSIF ((iv_file_format = gv_format_code_02)
                 OR (iv_file_format = gv_format_code_04))
          THEN
            -- �P�[�X����
            fdata_tbl(gn_target_cnt).case_quantity     := SUBSTR(lv_line, 1, ln_length);
          -- �t�H�[�}�b�g�p�^�[�����u5�v�̏ꍇ
          ELSIF (iv_file_format = gv_format_code_05) THEN
            -- ���z
            fdata_tbl(gn_target_cnt).amount            := SUBSTR(lv_line, 1, ln_length);
          END IF;
--
        -- ***************************************
        -- ***             7���ږ�             ***
        -- ***************************************
        ELSIF  (ln_col = 7) THEN
          -- �t�H�[�}�b�g�p�^�[�����u2�v�u4�v�̏ꍇ
          IF ((iv_file_format = gv_format_code_02)
              OR (iv_file_format = gv_format_code_04))
          THEN
            -- �o������
            fdata_tbl(gn_target_cnt).indivi_quantity   := SUBSTR(lv_line, 1, ln_length);
          END IF;
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
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := gv_status_warn;
--
    WHEN lock_expt THEN   --*** ���b�N�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_032,
                                            gv_c_tkn_table, gv_file_up_if_tbl);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
    WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_c_msg_kbn,   gv_c_msg_99b_008,
                                            gv_c_tkn_item,  gv_file_id_name,
                                            gv_c_tkn_value, in_file_id);
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
   * Description      : �Ó����`�F�b�N(B-4)
   ***********************************************************************************/
  PROCEDURE check_proc(
    iv_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    lv_line_feed        VARCHAR2(1);                  -- ���s�R�[�h
--
    -- *** ���[�J���ϐ� ***
    ln_c_col   NUMBER; -- �����ڐ�
--
    lv_log_data                                      VARCHAR2(32767);  -- LOG�f�[�^���ޔ�p
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
    -- �����ڐ��̐ݒ�
    -- �t�H�[�}�b�g�p�^�[�����u1�v�u3�v�u5�v�̏ꍇ
    IF ((iv_file_format = gv_format_code_01)
        OR (iv_file_format = gv_format_code_03)
        OR (iv_file_format = gv_format_code_05))
    THEN
      ln_c_col := 6;
    -- �t�H�[�}�b�g�p�^�[�����u2�v�u4�v�̏ꍇ
    ELSIF ((iv_file_format = gv_format_code_02)
           OR (iv_file_format = gv_format_code_04))
    THEN
      ln_c_col := 7;
    END IF;
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
      -- (�s�S�̂̒��� - �s����J���}�𔲂������� = �J���}�̐�)
      --   <> (�����ȍ��ڐ� - 1 = �����ȃJ���}�̐�)
      IF ((NVL(LENGTH(fdata_tbl(ln_index).line) ,0)
        - NVL(LENGTH(REPLACE(fdata_tbl(ln_index).line,gv_comma, NULL)),0))
          <> (ln_c_col - 1))
      THEN
--
        fdata_tbl(ln_index).err_message := gv_err_msg_space || gv_err_msg_space
                                      || xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_024)
                                      || lv_line_feed;
      -- ���ڐ��������ꍇ
      ELSE
        -- ���ڃ`�F�b�N
        -- �t�H�[�}�b�g�p�^�[�����u1�v�u2�v�u4�v�̏ꍇ
        IF ((iv_file_format = gv_format_code_01)
            OR (iv_file_format = gv_format_code_02)
            OR (iv_file_format = gv_format_code_04))
        THEN
          -- **************************************************
          -- *** �o�בq��
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_location_code_n,
                                              fdata_tbl(ln_index).location_code,
                                              gv_location_code_l,
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
        -- �t�H�[�}�b�g�p�^�[�����u1�v�u2�v�u3�v�u5�v�̏ꍇ
        IF ((iv_file_format = gv_format_code_01)
            OR (iv_file_format = gv_format_code_02)
            OR (iv_file_format = gv_format_code_03)
            OR (iv_file_format = gv_format_code_05))
        THEN
          -- **************************************************
          -- *** ���_
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_base_code_n,
                                              fdata_tbl(ln_index).base_code,
                                              gv_base_code_l,
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
        -- **************************************************
        -- *** �i��
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_item_code_n,
                                            fdata_tbl(ln_index).item_code,
                                            gv_item_code_l,
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
        -- **************************************************
        -- *** �P�[�X����
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_case_quantity_n,
                                            fdata_tbl(ln_index).case_quantity,
                                            gv_case_quantity_l,
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
        -- **************************************************
        -- *** �o������
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_indivi_quantity_n,
                                            fdata_tbl(ln_index).indivi_quantity,
                                            gv_indivi_quantity_l,
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
        -- **************************************************
        -- *** �J�n���t
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_forecast_date_n,
                                            fdata_tbl(ln_index).forecast_date,
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
        -- **************************************************
        -- *** �I�����t
        -- **************************************************
        xxcmn_common3_pkg.upload_item_check(gv_forecast_end_date_n,
                                            fdata_tbl(ln_index).forecast_end_date,
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
        -- �t�H�[�}�b�g�p�^�[�����u4�v�̏ꍇ
        IF (iv_file_format = gv_format_code_04) THEN
          -- **************************************************
          -- *** �捞����
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_dept_code_n,
                                              fdata_tbl(ln_index).dept_code,
                                              gv_dept_code_l,
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
        -- �t�H�[�}�b�g�p�^�[�����u5�v�̏ꍇ
        IF (iv_file_format = gv_format_code_05) THEN
          -- **************************************************
          -- *** ���z
          -- **************************************************
          xxcmn_common3_pkg.upload_item_check(gv_amount_n,
                                              fdata_tbl(ln_index).amount,
                                              gv_amount_l,
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
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ�
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_forecast_if_id   NUMBER;   -- ���ID
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
    ln_forecast_if_id := NULL;
--
    -- **************************************************
    -- *** �o�^�pPL/SQL�\�ҏW�i2�s�ڂ���j
    -- **************************************************
    <<fdata_loop>>
    FOR ln_index IN 1 .. fdata_tbl.LAST LOOP
--
      -- ���ID�̔�
      SELECT xxinv_mrp_frcst_if_s1.NEXTVAL
      INTO   ln_forecast_if_id
      FROM   dual;
--
      -- �Ώۍ��ڂ̊i�[
      -- 1.���ID
      gt_forecast_if_id(ln_index)       := ln_forecast_if_id;
      -- 2.Forecast����
      gt_forecast_designator(ln_index)  := gv_file_content_type;
      -- 3.�o�בq��
      gt_location_code(ln_index)        := fdata_tbl(ln_index).location_code;
      -- 4.���_
      gt_base_code(ln_index)            := fdata_tbl(ln_index).base_code;
--
      IF (iv_file_format = gv_format_code_04) THEN
        -- 5.�捞����
        gt_dept_code(ln_index)            := fdata_tbl(ln_index).dept_code;
      ELSE
        gt_dept_code(ln_index)            := gv_location_code;
      END IF;
--
      -- 6.�i��
      gt_item_code(ln_index)            := fdata_tbl(ln_index).item_code;
      -- 7.�J�n���t
      gt_forecast_date(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).forecast_date, 'RR/MM/DD');
      -- 8.�I�����t
      gt_forecast_end_date(ln_index)
        := FND_DATE.STRING_TO_DATE(fdata_tbl(ln_index).forecast_end_date, 'RR/MM/DD');
      -- 9.�P�[�X����
      gt_case_quantity(ln_index)
        := TO_NUMBER(fdata_tbl(ln_index).case_quantity);
      -- 10.�o������
      gt_indivi_quantity(ln_index)      := TO_NUMBER(fdata_tbl(ln_index).indivi_quantity);
      -- 11.���z
      gt_amount(ln_index)               := TO_NUMBER(fdata_tbl(ln_index).amount);
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
   * Procedure Name   : insert_mrp_forecast_if
   * Description      : �f�[�^�o�^ (B-4)
   ***********************************************************************************/
  PROCEDURE insert_mrp_forecast_if(
    ov_errbuf    OUT NOCOPY VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(30) := 'insert_mrp_forecast_if'; -- �v���O������
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
    -- *** �̔��v��/����v��C���^�t�F�[�X�e�[�u���o�^
    -- **************************************************
    FORALL item_cnt IN 1 .. gt_forecast_if_id.COUNT
      INSERT INTO xxinv_mrp_forecast_interface
      ( forecast_if_id                                  -- ���ID
       ,forecast_designator                             -- Forecast����
       ,location_code                                   -- �o�בq��
       ,base_code                                       -- ���_
       ,dept_code                                       -- �捞����
       ,item_code                                       -- �i��
       ,forecast_date                                   -- �J�n���t
       ,forecast_end_date                               -- �I�����t
       ,case_quantity                                   -- �P�[�X����
       ,indivi_quantity                                 -- �o������
       ,amount                                          -- ���z
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
      ( gt_forecast_if_id(item_cnt)                     -- ���ID
       ,gt_forecast_designator(item_cnt)                -- Forecast����
       ,gt_location_code(item_cnt)                      -- �o�בq��
       ,gt_base_code(item_cnt)                          -- ���_
       ,gt_dept_code(item_cnt)                          -- �捞����
       ,gt_item_code(item_cnt)                          -- �i��
       ,gt_forecast_date(item_cnt)                      -- �J�n���t
       ,gt_forecast_end_date(item_cnt)                  -- �I�����t
       ,gt_case_quantity(item_cnt)                      -- �P�[�X����
       ,gt_indivi_quantity(item_cnt)                    -- �o������
       ,gt_amount(item_cnt)                             -- ���z
       ,gn_user_id                                      -- �쐬��
       ,gd_sysdate                                      -- �쐬��
       ,gn_user_id                                      -- �ŏI�X�V��
       ,gd_sysdate                                      -- �ŏI�X�V��
       ,gn_login_id                                     -- �ŏI�X�V���O�C��
       ,gn_conc_request_id                              -- �v��ID
       ,gn_prog_appl_id                                 -- �v���O�����A�v���P�[�V����ID
       ,gn_conc_program_id                              -- �v���O����ID
       ,gd_sysdate                                      -- �v���O�����X�V��
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
  END insert_mrp_forecast_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       --   FILE_ID
    iv_file_format IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �p�����[�^�`�F�b�N(B-1)
    -- ===============================
    check_param(
      iv_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �֘A�f�[�^�擾(B-2)
    -- ===============================
    init_proc(
      iv_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�擾(B-3)
    -- ===============================
    get_upload_data_proc(
      in_file_id,        -- FILE_ID
      iv_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--##############################  �A�b�v���[�h�Œ胁�b�Z�[�W START  ##############################
    --�������ʃ��|�[�g�o�́i�㕔�j
    -- �t�@�C����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_101,
                                              gv_c_tkn_value, gv_file_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_103,
                                              gv_c_tkn_value,
                                              TO_CHAR(gd_creation_date,'YYYY/MM/DD HH24:MI'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�@�C���A�b�v���[�h����
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_104,
                                              gv_c_tkn_value, gv_file_up_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    -- �t�H�[�}�b�g�p�^�[��
    lv_out_rep    := xxcmn_common_pkg.get_msg(gv_c_msg_kbn, gv_c_msg_99b_106,
                                              gv_c_tkn_value, iv_file_format);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_rep);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
--##############################  �A�b�v���[�h�Œ胁�b�Z�[�W END   ##############################
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
    -- �Ó����`�F�b�N(B-4)
    -- ===============================
    check_proc(
      iv_file_format,    -- �t�H�[�}�b�g�p�^�[��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
--
    -- �Ó����`�F�b�N�ŃG���[���Ȃ������ꍇ
    ELSIF (gv_check_proc_retcode = gv_status_normal) THEN
      -- ===============================
      -- �o�^�f�[�^�Z�b�g
      -- ===============================
      set_data_proc(
        iv_file_format,    -- �t�H�[�}�b�g�p�^�[��
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- �f�[�^�o�^(B-5)
      -- ===============================
      insert_mrp_forecast_if(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ==================================================
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜(B-6)
    -- ==================================================
    xxcmn_common3_pkg.delete_fileup_proc(
      iv_file_format,                 -- �t�H�[�}�b�g�p�^�[��
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  VARCHAR2,      --   1.FILE_ID 2008/04/18 �ύX
    iv_file_format IN  VARCHAR2       --   2.�t�H�[�}�b�g�p�^�[��
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
      TO_NUMBER(in_file_id),     -- FILE_ID 2008/04/18 �ύX
      iv_file_format, -- �t�H�[�}�b�g�p�^�[��
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
END xxinv990001c;
/
