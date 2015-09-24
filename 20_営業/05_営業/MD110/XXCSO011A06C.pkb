CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A06C(body)
 * Description      : ������p���̏�ԂɍX�V���܂��B
 * MD.050           : �p���\��CSV�A�b�v���[�h (MD050_CSO_011A06)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_upload_if          �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
 *  delete_upload_if       �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-3)
 *  proc_kbn_check         �����敪�`�F�b�N(A-4)
 *  data_validation        �f�[�^�Ó����`�F�b�N(A-5)
 *  upd_install_info       �������X�V(A-6)
 *  ins_bulk_disp_proc     �ꊇ�p���A�g�Ώۃe�[�u���o�^(A-7)
 *  
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/08/20    1.0   S.Yamashita      �V�K�쐬
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
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSO011A06C';      -- �p�b�P�[�W��
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  --���b�Z�[�W
  cv_msg_cso_00496                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00496';  -- �p�����[�^�o��
  cv_msg_cso_00011                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00276                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- �A�b�v���[�h�t�@�C������
  cv_msg_cso_00274                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- �f�[�^���o�G���[�i�A�b�v���[�h�t�@�C�����́j
  cv_msg_cso_00152                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSV�t�@�C����
  cv_msg_cso_00278                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ���b�N�G���[
  cv_msg_cso_00342                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00342';  -- ����^�C�vID�Ȃ��G���[���b�Z�[�W
  cv_msg_cso_00103                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00103';  -- �ǉ�����ID���o�G���[���b�Z�[�W
  cv_msg_cso_00163                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00163';  -- �X�e�[�^�XID�Ȃ��G���[���b�Z�[�W
  cv_msg_cso_00025                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00025';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_cso_00399                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- �Ώی���0�����b�Z�[�W
  cv_msg_cso_00677                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00677';  -- �ėpCSV���ڐ��G���[
  cv_msg_cso_00771                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00771';  -- CSV���ږ��ݒ�G���[
  cv_msg_cso_00772                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00772';  -- �����敪�Ó����G���[
  cv_msg_cso_00351                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00351';  -- �����}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  cv_msg_cso_00358                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00358';  -- ��ƈ˗����t���O_�p���p�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cso_00359                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00359';  -- �@���ԂP�i�ғ���ԁj_�p���p�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cso_00361                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00361';  -- �@���ԂR�i�p�����j_�p�����ϗp�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cso_00365                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00365';  -- ���[�X�����X�e�[�^�X�`�F�b�N�i�p���p�j�G���[���b�Z�[�W
  cv_msg_cso_00784                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00784';  -- �p�����ϐ\���`�F�b�N�G���[
  cv_msg_cso_00014                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cso_00545                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00545';  -- �Q�ƃ^�C�v���e�擾�G���[���b�Z�[�W
  cv_msg_cso_00380                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00380';  -- �p���p�������X�V�G���[���b�Z�[�W
  cv_msg_cso_00241                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00241';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_cso_00773                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00773';  -- �f�[�^�o�^�G���[
  cv_msg_cso_00072                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00072';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cso_00783                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00783';  -- CSV�t�@�C���s�ԍ�
  cv_msg_cso_00785                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00785';  -- �����d���`�F�b�N�G���[
--
  cv_msg_cso_00673                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- �t�@�C��ID(���b�Z�[�W������)
  cv_msg_cso_00674                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- �t�H�[�}�b�g�p�^�[��(���b�Z�[�W������)
  cv_msg_cso_00676                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00676';  -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  cv_msg_cso_00696                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00696';  -- �����R�[�h(���b�Z�[�W������)
  cv_msg_cso_00711                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00711';  -- ����^�C�v�̎���^�C�vID(���b�Z�[�W������)
  cv_msg_cso_00712                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00712';  -- �ݒu�@��g��������`���̒ǉ�����ID(���b�Z�[�W������)
  cv_msg_cso_00714                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00714';  -- �����}�X�^(���b�Z�[�W������)
  cv_msg_cso_00774                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00774';  -- �@���ԂR�i�p�����j(���b�Z�[�W������)
  cv_msg_cso_00775                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00775';  -- �p�����ٓ�(���b�Z�[�W������)
  cv_msg_cso_00776                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00776';  -- �p���t���O(���b�Z�[�W������)
  cv_msg_cso_00777                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00777';  -- �����敪(���b�Z�[�W������)
  cv_msg_cso_00778                  CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00778';  -- �ꊇ�p���A�g�Ώۃe�[�u��(���b�Z�[�W������)
  cv_msg_cso_00786                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00786';  -- �p���葱��(���b�Z�[�W������)
  cv_msg_cso_00787                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00787';  -- �C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID(���b�Z�[�W������)
--
  --�g�[�N��
  cv_tkn_param_name                 CONSTANT VARCHAR2(30)  := 'PARAM_NAME';
  cv_tkn_value                      CONSTANT VARCHAR2(30)  := 'VALUE';
  cv_tkn_upload_file_name           CONSTANT VARCHAR2(30)  := 'UPLOAD_FILE_NAME';
  cv_tkn_csv_file_name              CONSTANT VARCHAR2(30)  := 'CSV_FILE_NAME';
  cv_tkn_task_nm                    CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_src_tran_type              CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';
  cv_tkn_status_name                CONSTANT VARCHAR2(20)  := 'STATUS_NAME';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_add_attr_nm                CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_add_attr_cd                CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_file_id                    CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkn_index                      CONSTANT VARCHAR2(30)  := 'INDEX';
  cv_tkn_bukken                     CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_status1                    CONSTANT VARCHAR2(20)  := 'STATUS1';
  cv_tkn_status3                    CONSTANT VARCHAR2(20)  := 'STATUS3';
  cv_tkn_date                       CONSTANT VARCHAR2(20)  := 'DATE';
  cv_tkn_api_err_msg                CONSTANT VARCHAR2(20)  := 'API_ERR_MSG';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_base_value                 CONSTANT VARCHAR2(30)  := 'BASE_VALUE';
  cv_tkn_prof_name                  CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_lookup_type_name           CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_tkn_err_message                CONSTANT VARCHAR2(20)  := 'ERR_MESSAGE';
--
  -- �Q�ƃ^�C�v
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';  -- �t�@�C���A�b�v���[�hOBJ
  cv_lkup_instance_status           CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';  -- �C���X�^���X�X�e�[�^�XID
--
  -- CSV�֘A
  cn_col_proc_kbn                   CONSTANT NUMBER        := 1;   -- �����敪
  cn_col_install_code               CONSTANT NUMBER        := 2;   -- �����R�[�h
  cn_csv_file_col_num               CONSTANT NUMBER        := 2;   -- CSV�t�@�C�����ڐ�
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- ���ڋ�ؕ���
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- �����񊇂�
--
  -- ���̑�
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y';             -- �ėpY
  cv_no                             CONSTANT VARCHAR2(1)   := 'N';             -- �ėpN
  cv_zero                           CONSTANT VARCHAR2(1)   := '0';             -- �ėp0
  cv_kbn_1                          CONSTANT VARCHAR2(1)   := '1';             -- �敪'1'�i�`�F�b�N�j
  cv_kbn_2                          CONSTANT VARCHAR2(1)   := '2';             -- �敪'2'�i�X�V�j
  cv_instance_status_4              CONSTANT VARCHAR2(1)   := '4';             -- �X�e�[�^�XID�̃R�[�h'4'�i�p���葱���j
  cv_fmt_ptn_check                  CONSTANT VARCHAR2(3)   := '690';           -- �t�H�[�}�b�g�p�^�[��:690�i�`�F�b�N�j
  cv_ib_ui                          CONSTANT VARCHAR2(5)   := 'IB_UI';         -- ����^�C�v:'IB_UI'
  cv_attr_cd_jotai_kbn3             CONSTANT VARCHAR2(30)  := 'JOTAI_KBN3';    -- �����R�[�h:'JOTAI_KBN3'
  cv_attr_cd_haikikessai_dt         CONSTANT VARCHAR2(30)  := 'HAIKIKESSAI_DT';-- �����R�[�h:'HAIKIKESSAI_DT'
  cv_attr_cd_ven_haiki_flg          CONSTANT VARCHAR2(30)  := 'VEN_HAIKI_FLG'; -- �����R�[�h:'VEN_HAIKI_FLG'
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �A�b�v���[�h�f�[�^�����擾�p
  TYPE gt_col_data_rec    IS TABLE OF VARCHAR(2000)   INDEX BY BINARY_INTEGER; -- 1�����z��
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_rec INDEX BY BINARY_INTEGER; -- 2�����z��
  g_sep_data_tab          gt_rec_data_ttype; -- �����f�[�^�i�[�p�z��
  -- �����d���`�F�b�N�p
  TYPE g_instance_ttype   IS TABLE OF csi_item_instances.external_reference%TYPE INDEX BY VARCHAR2(30); -- 1�����z��
  g_chk_instance_tab      g_instance_ttype;  -- �����R�[�h�i�[�p�z��
--
  -- IB�ǉ�����ID
  TYPE g_ib_ext_attr_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- �@����3
     ,abolishment_flag           NUMBER  -- �p���t���O
     ,abolishment_decision_date  NUMBER  -- �p�����ٓ�
  );
  -- IB�ǉ������lID
  TYPE g_ib_ext_attr_val_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- �@����3
     ,abolishment_flag           NUMBER  -- �p���t���O
     ,abolishment_decision_date  NUMBER  -- �p�����ٓ�
  );
  -- IB�ǉ�����ID���
  g_ib_ext_attr_id_rec        g_ib_ext_attr_id_rtype;
  -- IB�ǉ�����ID���
  g_ib_ext_attr_val_id_rec    g_ib_ext_attr_val_id_rtype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date         DATE;    -- �Ɩ��������t
  gv_kbn                  VARCHAR2(1); -- �敪
  gt_transaction_type_id  csi_txn_types.transaction_type_id%TYPE; -- ����^�C�vID
  gt_instance_id          xxcso_install_base_v.instance_id%TYPE;  -- �C���X�^���XID
  gt_instance_status_id   csi_instance_statuses.instance_status_id%TYPE; -- �C���X�^���X�X�e�[�^�XID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2     --   1.�t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2     --   2.�t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lv_msg           VARCHAR2(5000);                             -- ���b�Z�[�W�o�͗p
    lt_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          -- �t�@�C���A�b�v���[�h����
    lt_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; -- �t�@�C����
    lt_status_name   csi_instance_statuses.name%TYPE;            -- �X�e�[�^�X��
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
    lv_msg           := NULL;
    lt_file_ul_name  := NULL;
    lt_file_name     := NULL;
    lt_status_name   := NULL;
--
    --=========================================
    -- ���̓p�����[�^�o��
    --=========================================
    -- �t�@�C��ID
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00496  -- �p�����[�^�o��
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_cso_00673  -- �t�@�C��ID
               ,iv_token_name2  => cv_tkn_value
               ,iv_token_value2 => iv_file_id
              );
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- �t�H�[�}�b�g�p�^�[��
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00496  -- �p�����[�^�o��
               ,iv_token_name1  => cv_tkn_param_name
               ,iv_token_value1 => cv_msg_cso_00674  -- �t�H�[�}�b�g�p�^�[��
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
                    ,iv_name         => cv_msg_cso_00011 --�Ɩ��������t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- �A�b�v���[�h�t�@�C�����̎擾
    --=========================================
    BEGIN
      SELECT flv.meaning  AS meaning -- �A�b�v���[�h�t�@�C������
      INTO   lt_file_ul_name
      FROM   fnd_lookup_values_vl flv -- �N�C�b�N�R�[�h
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
                      ,iv_name         => cv_msg_cso_00274 -- �f�[�^���o�G���[�i�A�b�v���[�h�t�@�C�����́j
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h����
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name
               ,iv_name         => cv_msg_cso_00276 -- �t�@�C���A�b�v���[�h����
               ,iv_token_name1  => cv_tkn_upload_file_name
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
      SELECT xmfui.file_name AS file_name -- �t�@�C����
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF
      WHERE  xmfui.file_id = TO_NUMBER(iv_file_id) -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
      -- CSV�t�@�C�������b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name
                 ,iv_name         => cv_msg_cso_00152 -- CSV�t�@�C����
                 ,iv_token_name1  => cv_tkn_csv_file_name
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
                      ,iv_name         => cv_msg_cso_00278  -- ���b�N�G���[
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00676  -- �t�@�C���A�b�v���[�hIF
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- ����^�C�vID���o
    --=========================================
    BEGIN
      SELECT ctt.transaction_type_id AS transaction_type_id -- ����^�C�vID
      INTO   gt_transaction_type_id
      FROM   csi_txn_types ctt -- ����^�C�v
      WHERE  ctt.source_transaction_type = cv_ib_ui -- �\�[�X�g�����U�N�V�����^�C�v
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00342 -- ����^�C�vID�Ȃ��G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_task_nm
                      ,iv_token_value1 => cv_msg_cso_00711 -- ����^�C�v�̎���^�C�vID
                      ,iv_token_name2  => cv_tkn_src_tran_type
                      ,iv_token_value2 => cv_ib_ui         -- ����^�C�v:'IB_UI'
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
--
    --=========================================
    -- �ݒu�@��g�������̒ǉ�����ID���o
    --=========================================
    -- �@���ԂR�i�p�����j
    g_ib_ext_attr_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         iv_attribute_code => cv_attr_cd_jotai_kbn3
                                        ,id_standard_date  => gd_process_date
                                       );
    -- �擾�ł��Ȃ������ꍇ
    IF ( g_ib_ext_attr_id_rec.jotai_kbn3 IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- �ǉ�����ID���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- �ݒu�@��g��������`���̒ǉ�����ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00774 -- �@���ԂR�i�p�����j
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_jotai_kbn3 -- �����R�[�h:'JOTAI_KBN3'
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �p���t���O
    g_ib_ext_attr_id_rec.abolishment_flag := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               iv_attribute_code => cv_attr_cd_ven_haiki_flg
                                              ,id_standard_date  => gd_process_date
                                             );
--
    -- �擾�ł��Ȃ������ꍇ
    IF ( g_ib_ext_attr_id_rec.abolishment_flag IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- �ǉ�����ID���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- �ݒu�@��g��������`���̒ǉ�����ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00776 -- �p���t���O
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_ven_haiki_flg -- �����R�[�h:'VEN_HAIKI_FLG'
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �p�����ٓ�
    g_ib_ext_attr_id_rec.abolishment_decision_date := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                         iv_attribute_code => cv_attr_cd_haikikessai_dt
                                                        ,id_standard_date  => gd_process_date
                                                      );
--
    -- �擾�ł��Ȃ������ꍇ
    IF ( g_ib_ext_attr_id_rec.abolishment_decision_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00103 -- �ǉ�����ID���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_task_nm
                    ,iv_token_value1 => cv_msg_cso_00712 -- �ݒu�@��g��������`���̒ǉ�����ID
                    ,iv_token_name2  => cv_tkn_add_attr_nm
                    ,iv_token_value2 => cv_msg_cso_00775 -- �p�����ٓ�
                    ,iv_token_name3  => cv_tkn_add_attr_cd
                    ,iv_token_value3 => cv_attr_cd_haikikessai_dt -- �����R�[�h:'HAIKIKESSAI_DT'
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --=========================================
    -- �C���X�^���X�X�e�[�^�XID�̒��o
    --=========================================
    BEGIN
      -- �X�e�[�^�X���̎擾
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                            cv_lkup_instance_status
                          , cv_instance_status_4
                          , gd_process_date
                        );
--
      -- �C���X�^���X�X�e�[�^�XID�̎擾
      SELECT cis.instance_status_id AS instance_status_id -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id
      FROM   csi_instance_statuses cis -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lt_status_name  -- �X�e�[�^�X��
      AND    gd_process_date
               BETWEEN TRUNC( NVL( cis.start_date_active, gd_process_date ) ) -- �L���J�n��
               AND     TRUNC( NVL( cis.end_date_active, gd_process_date ) )   -- �L���I����
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00163   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00787   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00786   -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
     in_file_id      IN  NUMBER            -- 1.�t�@�C��ID
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
                    ,iv_name         => cv_msg_cso_00025 -- �f�[�^���o�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_msg_cso_00676 -- �t�@�C���A�b�v���[�hIF
                    ,iv_token_name2  => cv_tkn_file_id
                    ,iv_token_value2 => TO_CHAR(in_file_id) -- �t�@�C��ID
                    ,iv_token_name3  => cv_tkn_err_msg
                    ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================================
    -- �擾�����f�[�^��1���i�w�b�_�̂݁j�̏ꍇ
    --=========================================
    IF (l_file_data_tab.COUNT - 1 <= 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00399 -- �Ώی���0�����b�Z�[�W
                   );
      -- �Ώی���0�����b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
      -- �ȍ~�̏����͍s��Ȃ�
      RETURN;
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
                      ,iv_name         => cv_msg_cso_00677 -- �ėpCSV���ڐ��G���[
                      ,iv_token_name1  => cv_tkn_index
                      ,iv_token_value1 => TO_CHAR(ln_line_cnt - 1)
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
   * Procedure Name   : delete_upload_if
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE delete_upload_if(
    in_file_id    IN  NUMBER,       -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_if'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg_tkn VARCHAR2(5000);  -- ���b�Z�[�W�g�[�N���擾�p
--
--###########################  �Œ蕔 END   ####################################
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
    -- �t�@�C���A�b�v���[�hIF�폜
    --=========================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF
      WHERE xmfui.file_id = in_file_id -- �t�@�C��ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[�����������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00072 -- �f�[�^�폜�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00676 -- �t�@�C���A�b�v���[�hIF
                      ,iv_token_name2  => cv_tkn_err_message
                      ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** �����G���[��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END delete_upload_if;
--
  /**********************************************************************************
   * Procedure Name   : proc_kbn_check
   * Description      : �����敪�`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE proc_kbn_check(
     iv_proc_kbn     IN  VARCHAR2   -- �����敪
    ,in_loop_cnt     IN  NUMBER     -- ���[�v�J�E���^
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_kbn_check'; -- �v���O������
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
    --=========================================
    -- �����敪�K�{�`�F�b�N
    --=========================================
    IF ( iv_proc_kbn IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00771 -- CSV���ږ��ݒ�G���[
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cso_00777 -- �����敪
                   );
      --���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
    END IF;
--
    --=========================================
    -- �����敪�Ó����`�F�b�N
    --=========================================
    IF ( iv_proc_kbn <> gv_kbn ) THEN 
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00772 -- �����敪�Ó����G���[
                   );
      --���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode  := cv_status_warn;
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
      ov_retcode := cv_status_warn;
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
  END proc_kbn_check;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : �f�[�^�Ó����`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE data_validation(
     iv_install_code IN  VARCHAR2          --   �����R�[�h
    ,in_loop_cnt     IN  NUMBER            --   ���[�v�J�E���^
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���[�X�敪
    cv_lease_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- ���Ѓ��[�X
    cv_lease_kbn_4          CONSTANT VARCHAR2(1)  := '4'; -- �Œ莑�Y
    -- ���[�X�敪�i���[�X�����j
    cv_lease_type_1         CONSTANT VARCHAR2(1)  := '1'; -- ���_��
    cv_lease_type_2         CONSTANT VARCHAR2(1)  := '2'; -- �ă��[�X�_��
    -- �����X�e�[�^�X
    cv_obj_sts_110          CONSTANT VARCHAR2(3)  := '110';  -- ���r���i���ȓs���j
    cv_obj_sts_111          CONSTANT VARCHAR2(3)  := '111';  -- ���r���i�ی��Ή��j
    cv_obj_sts_112          CONSTANT VARCHAR2(3)  := '112';  -- ���r���i�����j
    cv_obj_sts_107          CONSTANT VARCHAR2(3)  := '107';  -- ����
    -- �؏���̃t���O
    cv_bnd_accpt_flg_accptd CONSTANT VARCHAR2(1)  := '1'; -- ��̍�
    -- ��ԋ敪
    cv_jotai_kbn_0          CONSTANT VARCHAR2(1)  := '0'; -- ��ԋ敪:'0'(�\�薳)
    cv_jotai_kbn_1          CONSTANT VARCHAR2(1)  := '1'; -- ��ԋ敪:'1'(�ؗ�)
    cv_jotai_kbn_2          CONSTANT VARCHAR2(1)  := '2'; -- ��ԋ敪:'2'(�p���\��)
    -- �v���t�@�C��
    cv_prof_fa_books        CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS';  -- XXCFF:�䒠��
    cv_lookup_csi_type_code CONSTANT VARCHAR2(30) := 'CSI_INST_TYPE_CODE';         -- �C���X�^���X�E�^�C�v�E�R�[�h
    -- �Q�ƃ^�C�v
    cv_lookup_deprn_year    CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- �Q�ƃ^�C�v�u���p�N���v
--
    -- *** ���[�J���ϐ� ***
    lv_msg_row_num            VARCHAR2(5000); -- �s�ԍ�
    lt_op_request_flag        xxcso_install_base_v.op_request_flag%TYPE;         -- ��ƈ˗����t���O
    lt_jotai_kbn1             xxcso_install_base_v.jotai_kbn1%TYPE;              -- �@���ԂP�i�ғ���ԁj
    lt_jotai_kbn3             xxcso_install_base_v.jotai_kbn3%TYPE;              -- �@���ԂR�i�p�����j
    lt_lease_kbn              xxcso_install_base_v.lease_kbn%TYPE;               -- ���[�X�敪
    lt_instance_type_code     xxcso_install_base_v.lease_kbn%TYPE;               -- �C���X�^���X�E�^�C�v�E�R�[�h
    lt_object_code            xxcff_object_headers.object_code%TYPE;             -- �����R�[�h
    lt_object_status          xxcff_object_headers.object_status%TYPE;           -- �����X�e�[�^�X
    lt_lease_type             xxcff_object_headers.lease_type%TYPE;              -- ���[�X�敪�i���[�X�����j
    lt_bond_acceptance_flag   xxcff_object_headers.bond_acceptance_flag%TYPE;    -- �؏���̃t���O
    lt_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;      -- ���[�X�J�n��
    lt_lease_class            xxcff_contract_headers.lease_class%TYPE;           -- ���[�X���
    ld_deprn_date             DATE;                                              -- ���p��
    lt_fa_book_type_code      fa_books.book_type_code%TYPE;                      -- �䒠��
    lt_date_placed_in_service fa_books.date_placed_in_service%TYPE;              -- ���Ƌ��p��
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
    lv_msg_row_num            := NULL; -- �s�ԍ�
    lt_op_request_flag        := NULL; -- ��ƈ˗����t���O
    lt_jotai_kbn1             := NULL; -- �@���ԂP�i�ғ���ԁj
    lt_jotai_kbn3             := NULL; -- �@���ԂR�i�p�����j
    lt_lease_kbn              := NULL; -- ���[�X�敪
    lt_instance_type_code     := NULL; -- �C���X�^���X�E�^�C�v�E�R�[�h
    lt_object_code            := NULL; -- �����R�[�h
    lt_object_status          := NULL; -- �����X�e�[�^�X
    lt_lease_type             := NULL; -- ���[�X�敪�i���[�X�����j
    lt_bond_acceptance_flag   := NULL; -- �؏���̃t���O
    lt_lease_start_date       := NULL; -- ���[�X�J�n��
    lt_lease_class            := NULL; -- ���[�X���
    ld_deprn_date             := NULL; -- ���p��
    lt_fa_book_type_code      := NULL; -- �䒠��
    lt_date_placed_in_service := NULL; -- ���Ƌ��p��
--
    -- �s�ԍ����b�Z�[�W�擾
    lv_msg_row_num := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00783     -- CSV�t�@�C���s�ԍ�
                    ,iv_token_name1  => cv_tkn_index
                    ,iv_token_value1 => TO_CHAR(in_loop_cnt) -- ���R�[�h�s
                   );
--
    --=========================================
    -- �����R�[�h�K�{�`�F�b�N
    --=========================================
    IF ( iv_install_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_msg_cso_00771 -- CSV���ږ��ݒ�G���[
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_msg_cso_00696 -- �����R�[�h
                   ) || lv_msg_row_num;
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
      -- �������݃`�F�b�N
      --=========================================
      BEGIN
        SELECT xibv.op_request_flag              AS op_request_flag         -- ��ƈ˗����t���O
              ,xibv.jotai_kbn1                   AS jotai_kbn1              -- �@���ԂP�i�ғ���ԁj
              ,xibv.jotai_kbn3                   AS jotai_kbn3              -- �@���ԂR�i�p�����j
              ,xibv.lease_kbn                    AS lease_kbn               -- ���[�X�敪
              ,xibv.instance_type_code           AS instance_type_code      -- �C���X�^���X�E�^�C�v�E�R�[�h
        INTO  lt_op_request_flag
             ,lt_jotai_kbn1
             ,lt_jotai_kbn3
             ,lt_lease_kbn
             ,lt_instance_type_code
        FROM  xxcso_install_base_v xibv -- �����}�X�^�r���[
        WHERE xibv.install_code = iv_install_code -- �����R�[�h
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �擾�ł��Ȃ������ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_cso_00351 -- �����}�X�^���݃`�F�b�N�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_bukken
                        ,iv_token_value1 => iv_install_code  -- �����R�[�h
                       ) || lv_msg_row_num;
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- �X�e�[�^�X���x���ɐݒ�
          ov_retcode := cv_status_warn;
      END;
    END IF;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( ov_retcode <> cv_status_warn ) THEN
      --=========================================
      -- �����X�e�[�^�X�`�F�b�N
      --=========================================
      -- ��ƈ˗����t���O��'Y'�̏ꍇ
      IF ( lt_op_request_flag = cv_yes ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00358 -- ��ƈ˗����t���O_�p���p�`�F�b�N�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- �����R�[�h
                     ) || lv_msg_row_num;
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �@���ԂP�i�ғ���ԁj��'2'�i�ؗ��j�ȊO�̏ꍇ
      IF ( lt_jotai_kbn1 <> cv_jotai_kbn_2 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00359 -- �@���ԂP�i�ғ���ԁj_�p���p�`�F�b�N�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- �����R�[�h
                      ,iv_token_name2  => cv_tkn_status1
                      ,iv_token_value2 => lt_jotai_kbn1    -- �@���ԂP�i�ғ���ԁj
                     ) || lv_msg_row_num;
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      END IF;
--
      -- �u�@���ԂR�i�p�����j��'0'(�\�薳)�A��������'1'(�p���\��)�v�ȊO�̏ꍇ
      IF ( ( lt_jotai_kbn3 <> cv_jotai_kbn_0 ) AND ( lt_jotai_kbn3 <> cv_jotai_kbn_1 ) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00361 -- �@���ԂR�i�p�����j_�p�����ϗp�`�F�b�N�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code  -- �����R�[�h
                      ,iv_token_name2  => cv_tkn_status3
                      ,iv_token_value2 => lt_jotai_kbn3    -- �@���ԂR�i�p�����j
                     ) || lv_msg_row_num;
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �X�e�[�^�X���x���ɐݒ�
        ov_retcode := cv_status_warn;
      END IF;
--
      --=========================================
      -- ���[�X��ԃ`�F�b�N
      --=========================================
      -- ���[�X�敪���u1:���Ѓ��[�X�v�̏ꍇ
      IF ( lt_lease_kbn = cv_lease_kbn_1 ) THEN
        BEGIN
          SELECT xoh.object_code           AS object_code          -- �����R�[�h
                ,xoh.object_status         AS object_status        -- �����X�e�[�^�X
                ,xoh.lease_type            AS lease_type           -- ���[�X�敪�i���[�X�����j
                ,xoh.bond_acceptance_flag  AS bond_acceptance_flag -- �؏���̃t���O
          INTO   lt_object_code
                ,lt_object_status
                ,lt_lease_type
                ,lt_bond_acceptance_flag
          FROM   xxcff_object_headers  xoh -- ���[�X�����e�[�u��
          WHERE  xoh.object_code = iv_install_code -- �����R�[�h
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- �f�[�^���擾�ł����ꍇ
        IF ( lt_object_code IS NOT NULL ) THEN
          -- �X�e�[�^�X�`�F�b�N
          IF ( NOT(
                -- �����X�e�[�^�X���u�����v�܂��́u���r���i�����j�v
                -- ���[�X�敪�i���[�X�����j���u���_��v�������X�e�[�^�X���u���r���(���ȓs��)�v���؏���̃t���O���u��̍ρv
                -- ���[�X�敪�i���[�X�����j���u���_��v�������X�e�[�^�X���u���r���(�ی��Ή�)�v���؏���̃t���O���u��̍ρv
                -- ���[�X�敪�i���[�X�����j���u�ă��[�X�_��v
                ( (lt_object_status = cv_obj_sts_107) OR (lt_object_status = cv_obj_sts_112) )
                OR ( (lt_lease_type = cv_lease_type_1) AND (lt_object_status = cv_obj_sts_110) AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
                OR ( (lt_lease_type = cv_lease_type_1) AND (lt_object_status = cv_obj_sts_111) AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
                OR ( lt_lease_type = cv_lease_type_2)
               ))
          THEN
            -- �X�e�[�^�X�`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name
                          ,iv_name         => cv_msg_cso_00365 -- ���[�X�����X�e�[�^�X�`�F�b�N�i�p���p�j�G���[���b�Z�[�W
                          ,iv_token_name1  => cv_tkn_bukken
                          ,iv_token_value1 => iv_install_code  -- �����R�[�h
                         ) || lv_msg_row_num;
            -- �x�����b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            -- �X�e�[�^�X���x���ɐݒ�
            ov_retcode := cv_status_warn;
          END IF;
--
          -- �X�e�[�^�X���u���r���(���ȓs��)�v�܂��́u���r���(�ی��Ή�)�v���A�؏���̃t���O���u��̍ρv�̏ꍇ
          IF ( (lt_object_status = cv_obj_sts_110 OR lt_object_status = cv_obj_sts_111)
                   AND (lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd) )
          THEN
            -- ���[�X���擾
            BEGIN
              SELECT /*+ USE_NL(xxoh xxcl xxch) INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
                     xxch.lease_start_date AS lease_start_date -- ���[�X�J�n��
                    ,xxch.lease_class      AS lease_class      -- ���[�X���
              INTO   lt_lease_start_date
                    ,lt_lease_class
              FROM   xxcff_object_headers    xxoh  --���[�X����
                    ,xxcff_contract_lines    xxcl  --���[�X�_�񖾍�
                    ,xxcff_contract_headers  xxch  --���[�X�_��w�b�_
              WHERE  xxoh.object_code      = iv_install_code            -- �����R�[�h
              AND    xxoh.object_header_id = xxcl.object_header_id      -- ��������ID
              AND    xxcl.lease_kind       = cv_zero                    -- ���[�X���(Fin)
              AND    xxch.contract_header_id = xxcl.contract_header_id  -- �_�����ID
              ;
            EXCEPTION
              -- �Y���f�[�^�����݂��Ȃ��ꍇ
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
--
            -- ��L�Ńf�[�^���擾�ł����ꍇ
            IF ( lt_lease_start_date IS NOT NULL ) THEN
              -- ���p�����擾
              BEGIN
                SELECT ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) AS deprn_date  -- ���p��
                INTO   ld_deprn_date
                FROM   fnd_lookup_values_vl flvv -- �N�C�b�N�R�[�h
                WHERE  flvv.lookup_type  = cv_lookup_deprn_year -- �^�C�v
                AND    flvv.enabled_flag = cv_yes          -- �L���t���O
                AND    flvv.attribute2   = lt_lease_class       -- ���[�X���
                AND    flvv.start_date_active <= lt_lease_start_date  -- �L���J�n��
                AND    flvv.end_date_active   >= lt_lease_start_date  -- �L���I����
                ;
              EXCEPTION
                -- �Y���f�[�^�����݂��Ȃ��ꍇ
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
--
              -- ���p�����擾�ł����ꍇ
              IF ( ld_deprn_date IS NOT NULL ) THEN
                -- ���p���Ԓ��`�F�b�N
                IF ( (lt_lease_start_date <= gd_process_date)
                  AND ( gd_process_date < ld_deprn_date ) )
                THEN
                  -- �p�����ϐ\���`�F�b�N�G���[
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name
                                ,iv_name         => cv_msg_cso_00784 -- �p�����ϐ\���`�F�b�N�G���[
                                ,iv_token_name1  => cv_tkn_bukken
                                ,iv_token_value1 => iv_install_code  -- �����R�[�h
                                ,iv_token_name2  => cv_tkn_date
                                ,iv_token_value2 => TO_CHAR(ld_deprn_date-1,'YYYY/MM/DD') -- ���p���ԏI����
                               ) || lv_msg_row_num;
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
          END IF;
        END IF;
      END IF;
--
      --=========================================
      -- ���p���ԃ`�F�b�N�i�Œ莑�Y�j
      --=========================================
      -- ���[�X�敪���u4:�Œ莑�Y�v�̏ꍇ
      IF ( lt_lease_kbn = cv_lease_kbn_4 ) THEN
        -- �v���t�@�C���I�v�V�����l�̎擾
        FND_PROFILE.GET( cv_prof_fa_books ,lt_fa_book_type_code );
        -- �擾�ł��Ȃ������ꍇ
        IF ( lt_fa_book_type_code IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00014      -- �v���t�@�C���擾�G���[���b�Z�[�W
                         ,iv_token_name1  => cv_tkn_prof_name      -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_prof_fa_books      -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���[�X��ʎ擾
        lt_lease_class := xxcso_util_common_pkg.get_lookup_attribute(
                            cv_lookup_csi_type_code  -- �^�C�v
                           ,lt_instance_type_code    -- �R�[�h
                           ,1                        -- DFF�ԍ�
                           ,gd_process_date          -- ���
                          );
        -- �擾�ł��Ȃ������ꍇ
        IF ( lt_lease_class IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_cso_00545         -- �Q�ƃ^�C�v���e�擾�G���[���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_task_nm
                        ,iv_token_value1 => lt_instance_type_code    -- �C���X�^���X�E�^�C�v�E�R�[�h
                        ,iv_token_name2  => cv_tkn_lookup_type_name
                        ,iv_token_value2 => cv_lookup_csi_type_code  -- �Q�ƃ^�C�v:'CSI_INST_TYPE_CODE'
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- ���Ƌ��p���擾
        BEGIN
          SELECT fb.date_placed_in_service AS date_placed_in_service -- ���Ƌ��p��
          INTO   lt_date_placed_in_service
          FROM   fa_additions_b            fab -- ���Y�ڍ׏��
                ,fa_books                  fb  -- ���Y�䒠���
          WHERE  fab.asset_id      = fb.asset_id          -- ���YID
          AND    fb.date_ineffective IS NULL              -- ������
          AND    fb.book_type_code = lt_fa_book_type_code -- ���Y�䒠��
          AND    fab.tag_number    = iv_install_code      -- �����R�[�h
          ;
        EXCEPTION
          -- �Y���f�[�^�����݂��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- ���Ƌ��p�����擾�ł����ꍇ
        IF ( lt_date_placed_in_service IS NOT NULL ) THEN
          -- ���p�����擾
          BEGIN
            SELECT ADD_MONTHS( lt_date_placed_in_service , flvv.attribute1 * 12 ) AS deprn_date -- ���p��
            INTO   ld_deprn_date
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type        = cv_lookup_deprn_year -- �^�C�v
            AND    flvv.enabled_flag       = cv_yes               -- �L���t���O
            AND    flvv.attribute2         = lt_lease_class       -- ���[�X���
            AND    flvv.start_date_active <= lt_date_placed_in_service  -- �L���J�n��
            AND    flvv.end_date_active   >= lt_date_placed_in_service  -- �L���I����
            ;
          EXCEPTION
            -- �Y���f�[�^�����݂��Ȃ��ꍇ
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          -- ���p�����擾�ł����ꍇ
          IF ( ld_deprn_date IS NOT NULL ) THEN
            -- ���p���Ԓ��`�F�b�N
            IF ( lt_date_placed_in_service <= gd_process_date )
              AND ( gd_process_date < ld_deprn_date )
            THEN
              -- �p�����ϐ\���`�F�b�N�G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_cso_00784 -- �p�����ϐ\���`�F�b�N�G���[
                            ,iv_token_name1  => cv_tkn_bukken
                            ,iv_token_value1 => iv_install_code  -- �����R�[�h
                            ,iv_token_name2  => cv_tkn_date
                            ,iv_token_value2 => TO_CHAR(ld_deprn_date-1,'YYYY/MM/DD') -- ���p���ԏI����
                           ) || lv_msg_row_num;
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
      END IF;
--
      --=========================================
      -- �����d���`�F�b�N
      --=========================================
      IF ( g_chk_instance_tab.EXISTS(iv_install_code) = FALSE ) THEN
        g_chk_instance_tab(iv_install_code) := iv_install_code;
      ELSE
        -- �����d���`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00785 -- �����d���`�F�b�N�G���[
                      ,iv_token_name1  => cv_tkn_bukken
                      ,iv_token_value1 => iv_install_code -- �����R�[�h
                     )
                     || lv_msg_row_num;
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
   * Procedure Name   : upd_install_info
   * Description      : �������X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_install_info(
     iv_install_code IN  VARCHAR2          --   �����R�[�h
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_install_info'; -- �v���O������
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
    -- �����X�VAPI����
    cn_api_version           CONSTANT NUMBER         := 1.0;
    cv_commit_false          CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true    CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false         CONSTANT VARCHAR2(1)    := 'F';
    -- �����l
    cv_jotai_kbn3_ablsh_desc CONSTANT VARCHAR2(1)    := '3';  -- �@���ԂR�i�p�����j�u�p�����ٍρv
    cv_ablsh_flg_ablsh_desc  CONSTANT VARCHAR2(1)    := '9';  -- �p���t���O�u�p�����ٍρv
--
    -- *** ���[�J���ϐ� ***
    lt_object_version_number xxcso_install_base_v.object_version_number%TYPE;   -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- API���͒l�i�[�p
    ln_validation_level      NUMBER;
    -- API���o�̓��R�[�h�l�i�[�p
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    -- �߂�l�i�[�p
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_iea_val_rec            csi_iea_values%ROWTYPE;
--
    -- *** ���[�J���E�e�[�u�� ***
    TYPE l_iea_val_ttype     IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    l_iea_val_tab            l_iea_val_ttype;
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
    -- �������b�N�擾
    --=========================================
    BEGIN
      SELECT cii.instance_id              AS  instance_id            -- �C���X�^���XID
           , cii.object_version_number    AS  object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   gt_instance_id
           , lt_object_version_number
      FROM   csi_item_instances  cii -- �����}�X�^
      WHERE  cii.external_reference = iv_install_code -- �����R�[�h
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN global_lock_expt THEN
        -- ���b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_cso_00241  -- ���b�N�G���[
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00714  -- '�����}�X�^'
                      ,iv_token_name2  => cv_tkn_item
                      ,iv_token_value2 => cv_msg_cso_00696  -- '�����R�[�h'
                      ,iv_token_name3  => cv_tkn_base_value
                      ,iv_token_value3 => iv_install_code   -- �����R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --=========================================
    -- �ǉ������l���擾
    --=========================================
    -- �@���ԂR�i�p�����j
    l_iea_val_tab(1) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- �C���X�^���XID
                         ,iv_attribute_code => cv_attr_cd_jotai_kbn3     -- ������`
                        );
--
    -- �p���t���O
    l_iea_val_tab(2) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- �C���X�^���XID
                         ,iv_attribute_code => cv_attr_cd_ven_haiki_flg  -- ������`
                        );
--
    -- �p�����ٓ�
    l_iea_val_tab(3) := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                          in_instance_id    => gt_instance_id            -- �C���X�^���XID
                         ,iv_attribute_code => cv_attr_cd_haikikessai_dt -- ������`
                        );
--
    --=========================================
    -- �ݒu�@��g�������l���e�[�u���ҏW
    --=========================================
    -- �@���ԂR�i�p�����j
    l_ext_attrib_values_tab(1).attribute_value_id      := l_iea_val_tab(1).attribute_value_id;
    l_ext_attrib_values_tab(1).attribute_value         := cv_jotai_kbn3_ablsh_desc;
    l_ext_attrib_values_tab(1).object_version_number   := l_iea_val_tab(1).object_version_number;
--
    -- �p���t���O
    IF ( l_iea_val_tab(2).attribute_value_id IS NOT NULL ) THEN
      l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
      l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
      l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
    ELSE
      l_ext_attrib_values_tab(2).attribute_id          := g_ib_ext_attr_id_rec.abolishment_flag;
      l_ext_attrib_values_tab(2).instance_id           := gt_instance_id;
      l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
    END IF;
--
    -- �p�����ٓ�
    IF ( l_iea_val_tab(3).attribute_value_id IS NOT NULL ) THEN
      l_ext_attrib_values_tab(3).attribute_value_id    := l_iea_val_tab(3).attribute_value_id;
      l_ext_attrib_values_tab(3).attribute_value       := TO_CHAR(TRUNC( gd_process_date ),'YYYY/MM/DD');
      l_ext_attrib_values_tab(3).object_version_number := l_iea_val_tab(3).object_version_number;
    ELSE
      l_ext_attrib_values_tab(3).attribute_id          := g_ib_ext_attr_id_rec.abolishment_decision_date;
      l_ext_attrib_values_tab(3).instance_id           := gt_instance_id;
      l_ext_attrib_values_tab(3).attribute_value       := TO_CHAR(TRUNC( gd_process_date ),'YYYY/MM/DD');
    END IF;
--
    --=========================================
    -- �C���X�^���X���R�[�h�ҏW
    --=========================================
    l_instance_rec.instance_id            := gt_instance_id;
    l_instance_rec.object_version_number  := lt_object_version_number;
    l_instance_rec.request_id             := fnd_global.conc_request_id;
    l_instance_rec.program_application_id := fnd_global.prog_appl_id;
    l_instance_rec.program_id             := fnd_global.conc_program_id;
    l_instance_rec.program_update_date    := SYSDATE;
    l_instance_rec.instance_status_id     := gt_instance_status_id;
--
    --=========================================
    -- ������R�[�h�ҏW
    --=========================================
    l_txn_rec.transaction_date        := SYSDATE;
    l_txn_rec.source_transaction_date := SYSDATE;
    l_txn_rec.transaction_type_id     := gt_transaction_type_id;
--
    --=========================================
    -- �������X�V
    --=========================================
    -- IB�X�V�p�W��API
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
      p_api_version           => cn_api_version
     ,p_commit                => cv_commit_false
     ,p_init_msg_list         => cv_init_msg_list_true
     ,p_validation_level      => ln_validation_level
     ,p_instance_rec          => l_instance_rec
     ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
     ,p_party_tbl             => l_party_tab
     ,p_account_tbl           => l_account_tab
     ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
     ,p_org_assignments_tbl   => l_org_assignments_tab
     ,p_asset_assignment_tbl  => l_asset_assignment_tab
     ,p_txn_rec               => l_txn_rec
     ,x_instance_id_lst       => l_instance_id_tab
     ,x_return_status         => lv_return_status
     ,x_msg_count             => ln_msg_count
     ,x_msg_data              => lv_msg_data
    );
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cso_00380      -- �v���t�@�C���擾�G���[���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_bukken         -- �g�[�N���R�[�h1
                    ,iv_token_value1 => iv_install_code       -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_err_msg    -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_msg_data           -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
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
  END upd_install_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_bulk_disp_proc
   * Description      : �ꊇ�p���A�g�Ώۃe�[�u���o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bulk_disp_proc(
     iv_install_code IN  VARCHAR2          --   �����R�[�h
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bulk_disp_proc'; -- �v���O������
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
    --=========================================
    -- �ꊇ�p���A�g�Ώۃe�[�u���o�^
    --=========================================
    BEGIN
      INSERT INTO xxcso_wk_bulk_disposal_proc (
        instance_id            -- ����ID
       ,interface_flag         -- �A�g�σt���O
       ,interface_date         -- �A�g��
       ,created_by             -- �쐬��
       ,creation_date          -- �쐬��
       ,last_updated_by        -- �ŏI�X�V��
       ,last_update_date       -- �ŏI�X�V��
       ,last_update_login      -- �ŏI�X�V���O�C��
       ,request_id             -- �v��ID
       ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id             -- �R���J�����g�E�v���O����ID
       ,program_update_date    -- �v���O�����X�V��
      ) VALUES (
        gt_instance_id            -- ����ID
       ,cv_no                     -- �A�g�σt���O
       ,NULL                      -- �A�g��
       ,cn_created_by             -- �쐬��
       ,cd_creation_date          -- �쐬��
       ,cn_last_updated_by        -- �ŏI�X�V��
       ,cd_last_update_date       -- �ŏI�X�V��
       ,cn_last_update_login      -- �ŏI�X�V���O�C��
       ,cn_request_id             -- �v��ID
       ,cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id             -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date    -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_cso_00773      -- �v���t�@�C���擾�G���[���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_msg_cso_00778      -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_item           -- �g�[�N���R�[�h2
                      ,iv_token_value2 => cv_msg_cso_00696      -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_value          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => iv_install_code       -- �g�[�N���l3
                      ,iv_token_name4  => cv_tkn_err_msg        -- �g�[�N���R�[�h4
                      ,iv_token_value4 => SQLERRM               -- �g�[�N���l4
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
  END ins_bulk_disp_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_file_id    IN  VARCHAR2     -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.�t�H�[�}�b�g�p�^�[��
    ,ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gv_kbn                 := NULL; -- �敪
    gt_transaction_type_id := NULL; -- ����^�C�vID
    gt_instance_id         := NULL; -- �C���X�^���XID
    gt_instance_status_id  := NULL; -- �C���X�^���X�X�e�[�^�XID
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �敪�̔���
    IF ( iv_fmt_ptn = cv_fmt_ptn_check ) THEN
      -- �`�F�b�N
      gv_kbn := cv_kbn_1;
    ELSE
      -- �X�V
      gv_kbn := cv_kbn_2;
    END IF;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_file_id => iv_file_id   -- �t�@�C��ID
      ,iv_fmt_ptn => iv_fmt_ptn   -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
    -- ===============================
    get_upload_if(
       in_file_id      => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      -- �I���X�e�[�^�X�F�x��
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-3)
    -- ===============================
    delete_upload_if(
       in_file_id  =>  TO_NUMBER(iv_file_id) -- �t�@�C��ID
      ,ov_errbuf   =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSE
      -- �폜�����������ꍇ�̓R�~�b�g
      COMMIT;
    END IF;
--
    -- �G���[���������Ă��Ȃ��ꍇ
    IF ( ov_retcode = cv_status_normal ) THEN
      -- �����敪�`�F�b�N���[�v
      <<proc_kbn_check_loop>>
      FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
        -- ===============================
        -- �����敪�`�F�b�N(A-4)
        -- ===============================
        proc_kbn_check(
           iv_proc_kbn     => g_sep_data_tab(ln_loop_cnt)(cn_col_proc_kbn) -- �����敪
          ,in_loop_cnt     => ln_loop_cnt  -- ���[�v�J�E���^
          ,ov_errbuf       => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          -- �����ݒ�
          gn_target_cnt := 0;
          gn_warn_cnt   := gn_warn_cnt + 1;
          -- �I���X�e�[�^�X�F�x��
          ov_retcode := lv_retcode;
          -- ���[�v�I��
          EXIT;
        END IF;
--
      END LOOP proc_kbn_check_loop;
--
      -- �G���[���������Ă��Ȃ��ꍇ
      IF ( ov_retcode = cv_status_normal ) THEN
        -- �Ó����`�F�b�N���[�v
        <<validation_loop>>
        FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
          -- ===============================
          -- �f�[�^�Ó����`�F�b�N(A-5)
          -- ===============================
          data_validation(
             iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- �����R�[�h
            ,in_loop_cnt     => ln_loop_cnt    -- ���[�v�J�E���^
            ,ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
          -- �敪��'2'�i�X�V�j�̏ꍇ�͕��������X�V
          IF ( gv_kbn = cv_kbn_2 ) THEN
            -- �����X�V���[�v
            <<upd_install_info_loop>>
            FOR ln_loop_cnt IN g_sep_data_tab.FIRST .. g_sep_data_tab.LAST LOOP
--
              -- ===============================
              -- �������X�V(A-6)
              -- ===============================
              upd_install_info(
                 iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- �����R�[�h
                ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ===============================
              -- �ꊇ�p���A�g�Ώۃe�[�u���o�^(A-7)
              -- ===============================
              ins_bulk_disp_proc(
                 iv_install_code => g_sep_data_tab(ln_loop_cnt)(cn_col_install_code) -- �����R�[�h
                ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg       => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ���������ݒ�i�X�V�p�j
              IF ( gv_kbn = cv_kbn_2 ) THEN
                gn_normal_cnt := gn_normal_cnt + 1;
              END IF;
--
            END LOOP upd_install_info_loop;
--
          END IF;
        END IF;
--
      -- ���������ݒ�i�`�F�b�N�p�j
      IF ( gv_kbn = cv_kbn_1 ) THEN
        gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
      END IF;
--
      END IF;
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
     errbuf        OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_file_id    IN  VARCHAR2      -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2)      -- 2.�t�H�[�}�b�g�p�^�[��
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
       iv_file_id => iv_file_id   -- 1.�t�@�C��ID
      ,iv_fmt_ptn => iv_fmt_ptn   -- 2.�t�H�[�}�b�g�p�^�[��
      ,ov_errbuf  => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END XXCSO011A06C;
/
