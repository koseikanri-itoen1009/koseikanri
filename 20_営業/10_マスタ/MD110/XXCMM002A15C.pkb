CREATE OR REPLACE PACKAGE BODY APPS.XXCMM002A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCMM002A15C(body)
 * Description      : �]�ƈ��̊Ǘ��ҁA���F�Ҕ͈͂��X�V���܂��B
 * MD.050           : �Ǘ��ҁ^���F�Ҕ͈̓A�b�v���[�h (MD050_CMM_002_A15)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_upload_if          �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
 *  data_validation        �f�[�^�Ó����`�F�b�N(A-3)
 *  upd_person_info        �]�ƈ����X�V(A-4)
 *  
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2024/09/11    1.0   M.Akachi         �V�K�쐬�iE_�{�ғ�_20141�Ή��j
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  global_lock_expt          EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCMM002A15C';      -- �p�b�P�[�W��
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCMM';             -- �A�v���P�[�V�����Z�k��
--
  --���b�Z�[�W
  cv_msg_cmm_00038                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00038';  -- �p�����[�^�o��
  cv_msg_cmm_00018                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00018';  -- �Ɩ��������t�擾�G���[
  cv_msg_cmm_00021                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00021';  -- �A�b�v���[�h�t�@�C������
  cv_msg_cmm_00230                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00230';  -- �f�[�^���o�G���[�i�A�b�v���[�h�t�@�C�����́j
  cv_msg_cmm_00022                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00022';  -- CSV�t�@�C����
  cv_msg_cmm_00402                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00402';  -- ���b�N�G���[
  cv_msg_cmm_00052                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00052';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_cmm_00418                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00418';  -- �f�[�^�폜�G���[
  cv_msg_cmm_00001                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00001';  -- �Ώی���0�����b�Z�[�W
  cv_msg_cmm_00231                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00231';  -- �f�[�^���ڐ��G���[
  cv_msg_cmm_00232                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00232';  -- �t�@�C�����ڕK�{�`�F�b�N�G���[
  cv_msg_cmm_00233                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00233';  -- �t�@�C�����ڑ��݃`�F�b�N�G���[
  cv_msg_cmm_00234                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00234';  -- �ސE�҃`�F�b�N�G���[
  cv_msg_cmm_00235                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00235';  -- �]�ƈ��d���`�F�b�N
  cv_msg_cmm_00236                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00236';  -- �]�ƈ��}�X�^���b�N�G���[���b�Z�[�W
  cv_msg_cmm_10435                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-10435';  -- �X�V�G���[
  cv_msg_cmm_00244                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00244';  -- �ސE�҃`�F�b�N�i�Ǘ��ҁj�G���[
  --�m�[�g
  cv_msg_cmm_00237                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00237';  -- �t�@�C��ID
  cv_msg_cmm_00238                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00238';  -- �]�ƈ��ԍ�
  cv_msg_cmm_00239                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00239';  -- �Ǘ���
  cv_msg_cmm_00240                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00240';  -- ���F�Ҕ͈�
  cv_msg_cmm_00241                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00241';  -- �]�ƈ��}�X�^
  cv_msg_cmm_00242                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00242';  -- �A�T�C�����g�}�X�^
  cv_msg_cmm_00243                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00243';  -- AFF����}�X�^
  cv_msg_cmm_30400                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-30400';  -- �t�H�[�}�b�g�p�^�[��
  cv_msg_cmm_30404                  CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-30404';  -- �t�@�C���A�b�v���[�hIF
  --�g�[�N��
  cv_tkn_param                      CONSTANT VARCHAR2(30)  := 'PARAM';
  cv_tkn_value                      CONSTANT VARCHAR2(30)  := 'VALUE';
  cv_tkn_upload_name                CONSTANT VARCHAR2(30)  := 'UPLOAD_NAME';
  cv_tkn_file_name                  CONSTANT VARCHAR2(30)  := 'FILE_NAME';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20)  := 'ERRMSG';
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_count                      CONSTANT VARCHAR2(30)  := 'COUNT';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_item_val                   CONSTANT VARCHAR2(30)  := 'ITEM_VAL';
  cv_tkn_input_line_no              CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';
  cv_tkn_key_data                   CONSTANT VARCHAR2(20)  := 'KEY_DATA';
--
  -- �Q�ƃ^�C�v
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';  -- �t�@�C���A�b�v���[�hOBJ
--
  -- CSV�֘A
  cn_col_employee_number            CONSTANT NUMBER        := 1;   -- �]�ƈ��ԍ�
  cn_col_supervisor_num             CONSTANT NUMBER        := 2;   -- �Ǘ��Ҕԍ�
  cn_col_location_code              CONSTANT NUMBER        := 3;   -- ���F�Ҕ͈�
  cn_csv_file_col_num               CONSTANT NUMBER        := 3;   -- CSV�t�@�C�����ڐ�
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- ���ڋ�ؕ���
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- �����񊇂�
--
  -- ���̑�
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y'; -- �ėpY
  cv_no                             CONSTANT VARCHAR2(1)   := 'N'; -- �ėpN
  cv_dept_status_2                  CONSTANT VARCHAR2(1)   := '2'; -- ����K�w�ꎞ���[�N�̏����敪 '2'�i����j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �A�b�v���[�h�f�[�^�����擾�p
  TYPE gt_col_data_rec    IS TABLE OF VARCHAR(2000)   INDEX BY BINARY_INTEGER; -- 1�����z��
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_rec INDEX BY BINARY_INTEGER; -- 2�����z��
  g_sep_data_tab          gt_rec_data_ttype; -- �����f�[�^�i�[�p�z��
  -- �]�ƈ��ԍ��d���`�F�b�N�p
  TYPE g_employee_number_ttype   IS TABLE OF per_all_people_f.employee_number%TYPE INDEX BY VARCHAR2(30); -- 1�����z��
  g_chk_employee_number_tab      g_employee_number_ttype;  -- �]�ƈ��ԍ��i�[�p�z��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date         DATE;    -- �Ɩ��������t
  gt_person_type_id       per_person_types.person_type_id%TYPE; -- �p�[�\���^�C�vID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id    IN  NUMBER       -- �t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2     -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_user_person_type_ex       CONSTANT VARCHAR2(10) := '�ސE��';
--
    -- *** ���[�J���ϐ� ***
    lv_msg           VARCHAR2(5000);                             -- ���b�Z�[�W�o�͗p
    lt_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          -- �t�@�C���A�b�v���[�h����
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; -- �t�@�C����
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
    -- ���[�J���ϐ�������
    lv_msg          := NULL;
    lt_file_ul_name := NULL;
    lt_file_name    := NULL;
--
    --=========================================
    -- ���̓p�����[�^�o��
    --=========================================
    -- �t�@�C��ID
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00038  -- �p�����[�^�o��
               ,iv_token_name1  => cv_tkn_param
               ,iv_token_value1 => cv_msg_cmm_00237  -- �t�@�C��ID
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => TO_CHAR(in_file_id)
              );
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- �t�H�[�}�b�g�p�^�[��
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00038  -- �p�����[�^�o��
               ,iv_token_name1  => cv_tkn_param
               ,iv_token_value1 => cv_msg_cmm_30400  -- �t�H�[�}�b�g�p�^�[��
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => iv_fmt_ptn
              );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --=========================================
    -- �Ɩ��������t�擾
    --=========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ������ꍇ
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00018 --�Ɩ��������t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- �A�b�v���[�h�t�@�C�����̎擾
    --=========================================
    BEGIN
      SELECT flv.meaning  AS meaning                -- �A�b�v���[�h�t�@�C������
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values_vl flv               -- �N�C�b�N�R�[�h
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj -- �^�C�v
      AND    flv.lookup_code  = iv_fmt_ptn          -- �R�[�h
      AND    flv.enabled_flag = cv_yes              -- �L���t���O
      AND    gd_process_date  BETWEEN TRUNC(flv.start_date_active)
                              AND     NVL(flv.end_date_active, gd_process_date) -- �L�����t
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^���o�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00230
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => iv_fmt_ptn
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h���̃m�[�g
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cmm_00021
               ,iv_token_name1  => cv_tkn_upload_name
               ,iv_token_value1 => lt_file_ul_name
              );
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    --=========================================
    -- �t�@�C�����擾
    --=========================================
    BEGIN
      SELECT xmfui.file_name AS file_name          -- �t�@�C����
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui     -- �t�@�C���A�b�v���[�hIF
      WHERE  xmfui.file_id = in_file_id            -- �t�@�C��ID
      FOR UPDATE NOWAIT ;
      -- CSV�t�@�C�������b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name
                 ,iv_name         => cv_msg_cmm_00022 -- CSV�t�@�C����
                 ,iv_token_name1  => cv_tkn_file_name
                 ,iv_token_value1 => lt_file_name
                );
      -- CSV�t�@�C�������b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ���b�N�G���[��
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00402  -- ���b�N�G���[
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- �p�[�\���^�C�v�擾
    --=========================================
    BEGIN
      SELECT ppt.person_type_id AS person_type_id
      INTO   gt_person_type_id
      FROM   per_person_types ppt     -- �p�[�\���^�C�v�}�X�^
      WHERE  ppt.user_person_type = lv_user_person_type_ex -- �ސE��
      AND    ROWNUM = 1;
    EXCEPTION
      -- �f�[�^�Ȃ��̏ꍇ���p��
      WHEN NO_DATA_FOUND THEN
        gt_person_type_id    := NULL;
      --
      WHEN OTHERS THEN
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- ����K�w�ꎞ���[�N�o�^
    --=========================================
    INSERT INTO xxcmm_wk_hiera_dept(
      cur_dpt_cd
     ,dpt1_cd
     ,dpt2_cd
     ,dpt3_cd
     ,dpt4_cd
     ,dpt5_cd
     ,dpt6_cd
     ,process_kbn
    )
      SELECT  xhd.cur_dpt_cd,        -- �ŉ��w����R�[�h
              NULL,                  -- �P�K�w�ڕ���R�[�h
              NULL,                  -- �Q�K�w�ڕ���R�[�h
              NULL,                  -- �R�K�w�ڕ���R�[�h
              NULL,                  -- �S�K�w�ڕ���R�[�h
              NULL,                  -- �T�K�w�ڕ���R�[�h
              NULL,                  -- �U�K�w�ڕ���R�[�h
              cv_dept_status_2       -- �����敪(1�F�S����A2�F����)
      FROM    xxcmm_hierarchy_dept_v xhd
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** �����G���[��O ***
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_if
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_if(
     in_file_id      IN  NUMBER            -- �t�@�C��ID
    ,ov_errbuf       OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_if'; -- �v���O������
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
    ln_line_cnt          NUMBER;
    ln_col_num           NUMBER;
    ln_column_cnt        NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    l_file_data_tab     xxccp_common_pkg2.g_file_data_tbl;  -- �s�P�ʃf�[�^�i�[�p�z��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=========================================
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    --=========================================
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- ���^�[���R�[�h���G���[�̏ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00052 -- �f�[�^���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_msg_cmm_30404 -- �t�@�C���A�b�v���[�hIF
                    ,iv_token_name2  => cv_tkn_err_msg
                    ,iv_token_value2 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================================
    -- �t�@�C���A�b�v���[�hIF�폜
    --=========================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF
      WHERE xmfui.file_id = in_file_id              -- �t�@�C��ID
      ;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00418 -- �f�[�^�폜�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cmm_30404 -- �t�@�C���A�b�v���[�hIF
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- �擾�����f�[�^��1���i�w�b�_�̂݁j�̏ꍇ
    --=========================================
    IF (l_file_data_tab.COUNT - 1 <= 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00001 -- �Ώی���0�����b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�Ώی����̎擾
    gn_target_cnt := l_file_data_tab.COUNT - 1;
--
    --=========================================
    -- ���ڐ��̃`�F�b�N
    --=========================================
    <<line_data_loop>>
    FOR ln_line_cnt IN 2 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾(��؂蕶���̐��Ŕ���)
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        -- ���ڐ����قȂ�ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00231 -- �f�[�^���ڐ��G���[
                      ,iv_token_name1  => cv_tkn_input_line_no
                      ,iv_token_value1 => TO_CHAR(ln_line_cnt - 1)
                      ,iv_token_name2  => cv_tkn_count
                      ,iv_token_value2 => TO_CHAR(ln_col_num)
                     );
        --���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      ELSE
        -- ���ڕ����i�w�b�_�s�͏����j
        <<col_sep_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          g_sep_data_tab(ln_line_cnt - 1)(ln_column_cnt) := REPLACE(xxccp_common_pkg.char_delim_partition(
                                                          iv_char     => l_file_data_tab(ln_line_cnt)
                                                         ,iv_delim    => cv_col_separator
                                                         ,in_part_num => ln_column_cnt
                                                        ), cv_dqu, NULL);
        END LOOP col_sep_loop;
      END IF;
    END LOOP line_data_loop;
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
  END get_upload_if;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : �f�[�^�Ó����`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE data_validation(
     iv_employee_number IN  VARCHAR2       -- �]�ƈ��ԍ�
    ,iv_supervisor_num  IN  VARCHAR2       -- �Ǘ��Ҕԍ�
    ,iv_location_code   IN  VARCHAR2       -- ���F�Ҕ͈�
    ,in_loop_cnt        IN  NUMBER         -- ���[�v�J�E���^
    ,ov_errbuf          OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- �v���O������
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
    ln_cnt                    NUMBER;                                 -- �J�E���g�p
    lt_person_type_id         per_all_people_f.person_type_id%TYPE;   -- �p�[�\���^�C�v�i�]�ƈ��j
    lt_person_type_id_sup     per_all_people_f.person_type_id%TYPE;   -- �p�[�\���^�C�v�i�Ǘ��ҁj

--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ�������
    ln_cnt                    := 0;
    lt_person_type_id         := NULL; -- �p�[�\���^�C�v�i�]�ƈ��j
    lt_person_type_id_sup     := NULL; -- �p�[�\���^�C�v�i�Ǘ��ҁj
--
    --=========================================
    -- �]�ƈ��ԍ��K�{�`�F�b�N
    --=========================================
    IF ( iv_employee_number IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cmm_00232     -- �t�@�C�����ڕK�{�`�F�b�N�G���[
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cmm_00238     -- �]�ƈ��ԍ�
                    ,iv_token_name2  => cv_tkn_input_line_no
                    ,iv_token_value2 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                   );
      -- �x�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- �X�e�[�^�X���x���ɐݒ�
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ��L�ŃG���[���������Ă��Ȃ��ꍇ
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- �]�ƈ����݃`�F�b�N
      --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   per_all_people_f papf  -- �]�ƈ��}�X�^
      WHERE  papf.employee_number = iv_employee_number -- �]�ƈ��ԍ�
      AND    papf.current_emp_or_apl_flag = cv_yes     --  �����t���O
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- �t�@�C�����ڑ��݃`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00238     -- �]�ƈ��ԍ�
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_employee_number   -- �]�ƈ��ԍ�
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00241     -- �]�ƈ��}�X�^
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                     );
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- �ސE�҃`�F�b�N
      --=========================================
      BEGIN
        SELECT papf.person_type_id AS person_type_id
        INTO   lt_person_type_id
        FROM   per_all_people_f papf  -- �]�ƈ��}�X�^
              ,( SELECT  papf2.person_id                 AS person_id
                        ,MAX(papf2.effective_start_date) AS effective_start_date
                 FROM    per_all_people_f  papf2
                 WHERE   papf2.employee_number = iv_employee_number
                 GROUP BY papf2.person_id
               ) sub
        WHERE  sub.person_id            = papf.person_id
        AND    sub.effective_start_date = papf.effective_start_date
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �擾�ł��Ȃ������ꍇ
          lt_person_type_id := NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      -- �ސE�҂̏ꍇ�G���[
      IF ( lt_person_type_id = gt_person_type_id ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_00234     -- �ސE�҃`�F�b�N�G���[
                        ,iv_token_name1  => cv_tkn_input_line_no
                        ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                        ,iv_token_name2  => cv_tkn_item_val
                        ,iv_token_value2 => iv_employee_number   -- �]�ƈ��ԍ�
                       );
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- �X�e�[�^�X���x���ɐݒ�
          ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- �Ǘ��҂��ݒ肳��Ă���ꍇ
    IF ( iv_supervisor_num IS NOT NULL ) THEN
    --=========================================
    -- �Ǘ��ґ��݃`�F�b�N
    --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   per_all_people_f papf  -- �]�ƈ��}�X�^
      WHERE  papf.employee_number = iv_supervisor_num  -- �Ǘ��Ҕԍ�
      AND    papf.current_emp_or_apl_flag = cv_yes     -- �����t���O
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- �t�@�C�����ڑ��݃`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00239     -- �Ǘ��Ҕԍ�
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_supervisor_num    -- �Ǘ��Ҕԍ�
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00241     -- �]�ƈ��}�X�^
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                     );
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      ELSE
        --=========================================
        -- �ސE�҃`�F�b�N�i�Ǘ��ҁj
        --=========================================
        BEGIN
          SELECT papf.person_type_id AS person_type_id
          INTO   lt_person_type_id_sup
          FROM   per_all_people_f papf  -- �]�ƈ��}�X�^
                ,( SELECT  papf2.person_id                 AS person_id
                          ,MAX(papf2.effective_start_date) AS effective_start_date
                   FROM    per_all_people_f  papf2
                   WHERE   papf2.employee_number = iv_supervisor_num
                   GROUP BY papf2.person_id
                 ) sub
          WHERE  sub.person_id            = papf.person_id
          AND    sub.effective_start_date = papf.effective_start_date
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �擾�ł��Ȃ������ꍇ
            lt_person_type_id_sup := NULL;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        -- �ސE�҂̏ꍇ�G���[
        IF ( lt_person_type_id_sup = gt_person_type_id ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_cmm_00244     -- �ސE�҃`�F�b�N�i�Ǘ��ҁj�G���[
                          ,iv_token_name1  => cv_tkn_input_line_no
                          ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                          ,iv_token_name2  => cv_tkn_item_val
                          ,iv_token_value2 => iv_supervisor_num    -- �Ǘ��Ҕԍ�
                         );
            -- �x�����b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- �X�e�[�^�X���x���ɐݒ�
            ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END IF;
--
    -- ���F�Ҕ͈͂��ݒ肳��Ă���ꍇ
    IF ( iv_location_code IS NOT NULL ) THEN
    --=========================================
    -- ���F�Ҕ͈͑��݃`�F�b�N
    --=========================================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   xxcmm_wk_hiera_dept xwhd
      WHERE  xwhd.cur_dpt_cd  = iv_location_code  -- �ŉ��w����R�[�h
      AND    xwhd.process_kbn = cv_dept_status_2  -- �����敪(2�F����)
      AND    ROWNUM = 1;
--
      IF ( ln_cnt = 0 ) THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00233     -- �t�@�C�����ڑ��݃`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_item
                      ,iv_token_value1 => cv_msg_cmm_00240     -- ���F�Ҕ͈�
                      ,iv_token_name2  => cv_tkn_item_val
                      ,iv_token_value2 => iv_location_code     -- ���F�Ҕ͈�
                      ,iv_token_name3  => cv_tkn_table
                      ,iv_token_value3 => cv_msg_cmm_00243     -- AFF����}�X�^
                      ,iv_token_name4  => cv_tkn_input_line_no
                      ,iv_token_value4 => TO_CHAR(in_loop_cnt) -- �s�ԍ�
                     );
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --=========================================
    -- �]�ƈ��d���`�F�b�N
    --=========================================
    IF ( iv_employee_number IS NOT NULL ) THEN
      IF ( g_chk_employee_number_tab.EXISTS(iv_employee_number) = FALSE ) THEN
        g_chk_employee_number_tab(iv_employee_number) := iv_employee_number;
      ELSE
        -- �]�ƈ��d���`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00235   -- �]�ƈ��d���`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_item_val
                      ,iv_token_value1 => iv_employee_number -- �]�ƈ��ԍ�
                     );
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
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
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : upd_person_info
   * Description      : �]�ƈ����X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_person_info(
     iv_employee_number IN  VARCHAR2       -- �]�ƈ��ԍ�
    ,iv_supervisor_num  IN  VARCHAR2       -- �Ǘ��Ҕԍ�
    ,iv_location_code   IN  VARCHAR2       -- ���F�Ҕ͈�
    ,ov_errbuf          OUT VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_person_info'; -- �v���O������
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
    lv_date_time_format      CONSTANT VARCHAR2(30)   := 'YYYY/MM/DD HH24:MI:SS'; 
    -- *** ���[�J���ϐ� ***
    lt_person_id             per_all_people_f.person_id%TYPE;             -- �]�ƈ�ID
    lt_effective_start_date  per_all_people_f.effective_start_date%TYPE;  -- �o�^�N����
    lt_effective_end_date    per_all_people_f.effective_end_date%TYPE;    -- �o�^�����N����
    lt_assignment_id         per_all_assignments_f.assignment_id%TYPE;    -- �A�T�C�������gID
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=========================================
    -- �]�ƈ����b�N�擾
    --=========================================
    BEGIN
      SELECT papf.person_id              AS  person_id             -- �p�[�\��ID
            ,papf.effective_start_date   AS  effective_start_date  -- �o�^�N����
            ,papf.effective_end_date     AS  effective_end_date    -- �o�^�����N����
            ,paaf.assignment_id          AS  assignment_id         -- �A�T�C�������gID
      INTO   lt_person_id
            ,lt_effective_start_date
            ,lt_effective_end_date
            ,lt_assignment_id
      FROM   per_all_people_f       papf                           -- �]�ƈ��}�X�^
            ,per_all_assignments_f  paaf                           -- �A�T�C�������g�}�X�^
            ,( SELECT papf2.person_id                 AS person_id
                     ,MAX(papf2.effective_start_date) AS effective_start_date
               FROM   per_all_people_f  papf2
               WHERE  papf2.current_emp_or_apl_flag = cv_yes
               AND    papf2.employee_number = iv_employee_number
               GROUP BY papf2.person_id
             ) sub
      WHERE  sub.person_id = papf.person_id
      AND    sub.effective_start_date  = papf.effective_start_date
      AND    papf.person_id            = paaf.person_id
      AND    papf.effective_start_date = paaf.effective_start_date
      FOR UPDATE OF papf.person_id
                   ,paaf.assignment_id NOWAIT
      ;
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ���b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cmm_00236    -- �]�ƈ��}�X�^���b�N�G���[
                      ,iv_token_name1  => cv_tkn_item_val
                      ,iv_token_value1 => iv_employee_number  -- �]�ƈ��ԍ�
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- �Ǘ��ҍX�V
    --=========================================
    IF ( iv_supervisor_num IS NOT NULL ) THEN
      BEGIN
        UPDATE per_all_assignments_f
        SET    supervisor_id        = ( SELECT papf.person_id
                                        FROM   per_all_people_f  papf
                                        WHERE  papf.employee_number = iv_supervisor_num
                                        AND    ROWNUM = 1 )
              ,ass_attribute19      = TO_CHAR(cd_last_update_date, lv_date_time_format)
        WHERE  assignment_id        = lt_assignment_id         -- �A�T�C�������gID
        AND    effective_start_date = lt_effective_start_date  -- �o�^�N����
        AND    effective_end_date   = lt_effective_end_date    -- �o�^�����N����
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_10435  -- �X�V�G���[
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_00242  -- �A�T�C�������g�}�X�^
                        ,iv_token_name2  => cv_tkn_errmsg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END;
    END IF;
--
    --=========================================
    -- ���F�Ҕ͈͍X�V
    --=========================================
    IF ( iv_location_code IS NOT NULL ) THEN
      BEGIN
        UPDATE per_all_people_f
        SET    attribute30          = iv_location_code
              ,attribute23          = TO_CHAR(cd_last_update_date, lv_date_time_format)
        WHERE  person_id            = lt_person_id             --�]�ƈ�ID
        AND    effective_start_date = lt_effective_start_date  --�o�^�N����
        AND    effective_end_date   = lt_effective_end_date    --�o�^�����N����
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_10435  -- �X�V�G���[
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_00241  -- �]�ƈ��}�X�^
                        ,iv_token_name2  => cv_tkn_errmsg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END;
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
  END upd_person_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     in_file_id    IN  NUMBER       -- �t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2     -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���E�e�[�u�� ***
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       in_file_id => in_file_id     -- �t�@�C��ID
      ,iv_fmt_ptn => iv_fmt_ptn     -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf  => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --==================================
      -- �t�@�C���A�b�v���[�hIF�f�[�^�폜����
      --==================================
      BEGIN
        DELETE FROM xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF
        WHERE xmfui.file_id = in_file_id          -- �t�@�C��ID
        ;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          -- �G���[�����������ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cmm_00418 -- �f�[�^�폜�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_cmm_30404 -- �t�@�C���A�b�v���[�hIF
                        ,iv_token_name2  => cv_tkn_err_msg
                        ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      RAISE global_process_expt;
    END IF;
--
    -- =====================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
    -- =====================================
    get_upload_if(
       in_file_id      => in_file_id        -- �t�@�C��ID
      ,ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- �I���X�e�[�^�X�F�x��
      ov_retcode := lv_retcode;
    END IF;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( ov_retcode = cv_status_normal ) THEN
        -- �Ó����`�F�b�N���[�v
        <<validation_loop>>
        FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
          -- ===============================
          -- �f�[�^�Ó����`�F�b�N(A-3)
          -- ===============================
          data_validation(
             iv_employee_number => g_sep_data_tab(ln_loop_cnt)(cn_col_employee_number) -- �]�ƈ��ԍ�
            ,iv_supervisor_num  => g_sep_data_tab(ln_loop_cnt)(cn_col_supervisor_num)  -- �Ǘ��Ҕԍ�
            ,iv_location_code   => g_sep_data_tab(ln_loop_cnt)(cn_col_location_code)   -- ���F�Ҕ͈�
            ,in_loop_cnt        => ln_loop_cnt    -- ���[�v�J�E���^
            ,ov_errbuf          => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            -- �x�������J�E���g
            gn_warn_cnt := gn_warn_cnt + 1;
            -- �I���X�e�[�^�X�F�x��
            ov_retcode := lv_retcode;
          END IF;
--
        END LOOP validation_loop;
--
        -- �G���[���������Ă��Ȃ��ꍇ
        IF ( ov_retcode = cv_status_normal ) THEN
          -- �]�ƈ��X�V���[�v
          <<upd_person_info_loop>>
          FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
            -- ===============================
            -- �]�ƈ����X�V(A-4)
            -- ===============================
            upd_person_info(
               iv_employee_number => g_sep_data_tab(ln_loop_cnt)(cn_col_employee_number) -- �]�ƈ��ԍ�
              ,iv_supervisor_num  => g_sep_data_tab(ln_loop_cnt)(cn_col_supervisor_num)  -- �Ǘ��Ҕԍ�
              ,iv_location_code   => g_sep_data_tab(ln_loop_cnt)(cn_col_location_code)   -- ���F�Ҕ͈�
              ,ov_errbuf          => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode         => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg          => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ���������ݒ�
            gn_normal_cnt := gn_normal_cnt + 1;
--
          END LOOP upd_person_info_loop;
--
        END IF;
--
    END IF;
--
  EXCEPTION
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
     errbuf            OUT VARCHAR2      -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode           OUT VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
    ,in_get_file_id    IN  NUMBER        -- �t�@�C��ID
    ,iv_get_format_pat IN  VARCHAR2)     -- �t�H�[�}�b�g�p�^�[��
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
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
       in_file_id => in_get_file_id    -- �t�@�C��ID
      ,iv_fmt_ptn => iv_get_format_pat -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�I���̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ����������
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      -- �G���[�����̎擾
      gn_error_cnt  := 1;
    END IF;
--
    --��s�}��
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --�I���X�e�[�^�X������̏ꍇ��COMMIT�A����ȊO��ROLLBACK
    IF (retcode = cv_status_normal) THEN
      COMMIT;
    ELSE
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
END XXCMM002A15C;
/
