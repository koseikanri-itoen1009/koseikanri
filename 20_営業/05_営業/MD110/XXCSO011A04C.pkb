CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A04C(body)
 * Description      : �������ה�����DFF���X�V���܂��B
 * MD.050           : �����X�V�A�b�v���[�h (MD050_CSO_011A04)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_upload_data        �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
 *  business_data_check    �f�[�^���e�`�F�b�N(A-3)
 *  update_distributions   �������ה���DFF�X�V(A-4)
 *  delete_file_ul_if      �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/05/08    1.0   Kazuyuki Kiriu   �V�K�쐬
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
  global_lock_expt          EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSO011A04C';      -- �p�b�P�[�W��
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  --���b�Z�[�W
  cv_msg_file_id                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00271';  -- �t�@�C��ID
  cv_msg_fmt_ptn                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[��
  cv_msg_param_required             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00325';  -- �p�����[�^�K�{�G���[
  cv_msg_param_nm_file_id           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- �t�@�C��ID(���b�Z�[�W������)
  cv_msg_err_param_valuel           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00252';  -- �p�����[�^�Ó����`�F�b�N�G���[
  cv_msg_param_nm_fmt_ptn           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- �t�H�[�}�b�g�p�^�[��(���b�Z�[�W������)
  cv_msg_err_get_proc_date          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_err_get_org_id             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_msg_err_get_data_ul            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- �t�@�C���A�b�v���[�h���̒��o�G���[
  cv_msg_file_ul_name               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_msg_file_name                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSV�t�@�C����
  cv_msg_err_get_lock               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ���b�N�G���[
  cv_msg_nm_file_ul_if              CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00676';  -- �t�@�C���A�b�v���[�hIF(���b�Z�[�W������)
  cv_msg_err_get_data               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00554';  -- �f�[�^���o�G���[
  cv_msg_err_no_data                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- �Ώی���0�����b�Z�[�W
  cv_msg_err_file_fmt               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00677';  -- CSV���ڐ��G���[
  cv_msg_no_target                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00679';  -- �X�V�ΏۂȂ��G���[
  cv_msg_not_found                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00683';  -- ���݃`�F�b�N�G���[
  cv_msg_dclr_place                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00662';  -- �\���n(���b�Z�[�W������)
  cv_msg_lease_kbn                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00670';  -- ���[�X�敪(���b�Z�[�W������)
  cv_msg_price                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00684';  -- �擾���i�G���[
  cv_msg_update_error               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00337';  -- �X�V�G���[
  cv_msg_po_distributions           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00685';  -- �������ה���(���b�Z�[�W������)
  cv_msg_po_distributions_lock      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00686';  -- ���b�N�G���[�i������������)
  cv_msg_err_del_data               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  --�g�[�N��
  cv_tkn_file_id                    CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkn_fmt_ptn                    CONSTANT VARCHAR2(30)  := 'FORMAT_PATTERN';
  cv_tkn_param_name                 CONSTANT VARCHAR2(30)  := 'PARAM_NAME';
  cv_tkn_prof_name                  CONSTANT VARCHAR2(30)  := 'PROF_NAME';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_file_ul_name               CONSTANT VARCHAR2(30)  := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name                  CONSTANT VARCHAR2(30)  := 'CSV_FILE_NAME';
  cv_tkn_table                      CONSTANT VARCHAR2(30)  := 'TABLE';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(30)  := 'ERR_MSG';
  cv_tkn_index                      CONSTANT VARCHAR2(30)  := 'INDEX';
  cv_tkn_po_num                     CONSTANT VARCHAR2(30)  := 'PO_NUM';
  cv_tkn_po_line_num                CONSTANT VARCHAR2(30)  := 'PO_LINE_NUM';
  cv_tkn_po_rec_num                 CONSTANT VARCHAR2(30)  := 'PO_REQ_NUM';
  cv_tkn_po_rec_line_num            CONSTANT VARCHAR2(30)  := 'PO_REQ_LINE_NUM';
  cv_tkn_action                     CONSTANT VARCHAR2(30)  := 'ACTION';
  cv_tkn_error_msg                  CONSTANT VARCHAR2(30)  := 'ERROR_MESSAGE';
  --�v���t�@�C��
  cv_org_id                         CONSTANT VARCHAR2(30)  := 'ORG_ID';                     --�c�ƒP��
  --�Q�ƃ^�C�v
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';     -- �t�@�C���A�b�v���[�hOBJ
  cv_lkup_lease_kbn                 CONSTANT VARCHAR2(50)  := 'XXCSO1_LEASE_KBN';           -- ���[�X�敪
  -- �l�Z�b�g��
  cv_flex_dclr_place                CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';           -- �\���n
  --CSV�t�@�C���̍��ڈʒu(�g�p���Ȃ����̂��錾)
  cn_col_pos_po_num                 CONSTANT NUMBER        := 1;   -- �����ԍ�
  cn_col_pos_po_line_num            CONSTANT NUMBER        := 2;   -- ��������
  cn_col_pos_req_num                CONSTANT NUMBER        := 3;   -- �w���˗��ԍ�
  cn_col_pos_req_line_num           CONSTANT NUMBER        := 4;   -- �w���˗����הԍ�
  cn_col_pos_machine                CONSTANT NUMBER        := 5;   -- �@��
  cn_col_pos_machine_lease_type     CONSTANT NUMBER        := 6;   -- �@�탊�[�X�敪
  cn_col_pos_machine_lease_nm       CONSTANT NUMBER        := 7;   -- �@�탊�[�X�敪��
  cn_col_pos_usually_price          CONSTANT NUMBER        := 8;   -- �W���擾���i
  cn_col_pos_customer_code          CONSTANT NUMBER        := 9;   -- �ݒu��ڋq
  cn_col_pos_customer_name          CONSTANT NUMBER        := 10;  -- �ݒu��ڋq��
  cn_col_pos_customer_site          CONSTANT NUMBER        := 11;  -- �ݒu��Z��
  cn_col_pos_lease_type             CONSTANT NUMBER        := 12;  -- ���[�X�敪
  cn_col_pos_lease_nm               CONSTANT NUMBER        := 13;  -- ���[�X�敪��
  cn_col_pos_price                  CONSTANT NUMBER        := 14;  -- �擾���i
  cn_col_pos_dclr_place             CONSTANT NUMBER        := 15;  -- �\���n�R�[�h
  cn_col_pos_dclr_place_nm          CONSTANT NUMBER        := 16;  -- �\���n
  --���̑�CSV�֘A
  cn_csv_file_col_num               CONSTANT NUMBER        := 16;  -- CSV�t�@�C�����ڐ�
  cn_header_rec                     CONSTANT NUMBER        := 1;   -- CSV�t�@�C���w�b�_�s
  cv_price_num                      CONSTANT NUMBER        := 10;  -- �擾���i�̌���
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- ���ڋ�ؕ���
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- �����񊇂�
--
  --�ėp�Œ�l
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y';             -- �ėpY
  cv_no                             CONSTANT VARCHAR2(1)   := 'N';             -- �ėpN
  cv_language                       CONSTANT VARCHAR2(2)   := USERENV('LANG'); -- LANGAGE
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �A�b�v���[�h�f�[�^�����擾�p
  TYPE gt_col_data_ttype  IS TABLE OF VARCHAR(2000)     INDEX BY BINARY_INTEGER;                    -- 1�����z��(����)
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;                    -- 2�����z��(��)(����)
  --�������ה����X�V�p
  TYPE g_row_id_ttype     IS TABLE OF ROWID INDEX BY BINARY_INTEGER;                                -- �������ה���ROWID
  TYPE g_lease_kbn_ttype  IS TABLE OF po_distributions_all.attribute1%TYPE INDEX BY BINARY_INTEGER; -- ���[�X�敪
  TYPE g_price_ttype      IS TABLE OF po_distributions_all.attribute2%TYPE INDEX BY BINARY_INTEGER; -- �擾���i
  TYPE g_dclr_place_ttype IS TABLE OF po_distributions_all.attribute3%TYPE INDEX BY BINARY_INTEGER; -- �\���n
--
  gt_row_id_tab     g_row_id_ttype;      -- �������ה���ROWID(BULK�X�V�p)
  gt_lease_kbn_tab  g_lease_kbn_ttype;   -- ���[�X�敪(BULK�X�V�p)
  gt_price_ttype    g_price_ttype;       -- �擾���i(BULK�X�V�p)
  gt_dclr_place     g_dclr_place_ttype;  -- �\���n(BULK�X�V�p)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id        NUMBER;  -- �c�ƒP��
  gd_process_date  DATE;    -- �Ɩ��������t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2     -- 1.�t�@�C����
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.�t�H�[�}�b�g�p�^�[��
    ,on_file_id    OUT NUMBER       -- 3.�t�@�C��ID�i�^�ϊ���j
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
    lv_msg           VARCHAR2(5000);                             --���b�Z�[�W�o�͗p
    lv_msg_tnk       VARCHAR2(5000);                             --���b�Z�[�W�g�[�N���擾�p
    lv_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          --�t�@�C���A�b�v���[�h����
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; --�t�@�C����
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
    --==============================================================
    --�p�����[�^�o��
    --==============================================================
    -- �t�@�C��ID
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_file_id
                ,iv_token_name1  => cv_tkn_file_id
                ,iv_token_value1 => iv_file_id
              );
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_fmt_ptn
                ,iv_token_name1  => cv_tkn_fmt_ptn
                ,iv_token_value1 => iv_fmt_ptn
              );
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    --==============================================================
    --�p�����[�^�`�F�b�N
    --==============================================================
    --�t�@�C��ID�`�F�b�N�G���[���̃g�[�N���擾
    lv_msg_tnk := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_nm_file_id
                  );
    -- �t�@�C��ID�̕K�{���̓`�F�b�N
    IF (iv_file_id IS NULL) THEN
      --�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => lv_msg_tnk
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C��ID�̌^�`�F�b�N(���l�^�ɕϊ��ł��Ȃ��ꍇ�̓G���[
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      --�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => lv_msg_tnk
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    on_file_id := TO_NUMBER(iv_file_id);
--
    --==============================================================
    --�����֘A�f�[�^�擾
    --==============================================================
    --�Ɩ��������t
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�Ɩ��������t�擾�`�F�b�N
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�c�ƒP�ʂ̎擾
    gn_org_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id ));
    --�c�ƒP�ʎ擾�`�F�b�N
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_org_id
                     ,iv_token_name1  => cv_tkn_prof_name
                     ,iv_token_value1 => cv_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�h����
    BEGIN
      SELECT flv.meaning  meaning
      INTO   lv_file_ul_name
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj
      AND    flv.lookup_code  = iv_fmt_ptn
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date  BETWEEN TRUNC(flv.start_date_active)
                              AND     NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
      --�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �t�@�C���A�b�v���[�h����
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_file_ul_name
                ,iv_token_name1  => cv_tkn_file_ul_name
                ,iv_token_value1 => lv_file_ul_name
              );
    -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --�G���[���̃g�[�N���擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_nm_file_ul_if
                    );
      --CSV�t�@�C����
      SELECT xmfui.file_name file_name
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = on_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSV�t�@�C�������b�Z�[�W
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name
                  ,iv_name         => cv_msg_file_name
                  ,iv_token_name1  => cv_tkn_file_name
                  ,iv_token_value1 => lv_file_name
                );
      -- CSV�t�@�C�������b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN
        --���b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --�f�[�^���o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => on_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
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
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
     in_file_id      IN  NUMBER            -- 1.�t�@�C��ID
    ,ov_sep_data_tab OUT gt_rec_data_ttype -- 2.���ڕ�����f�[�^
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    l_sep_data_tab      gt_rec_data_ttype;                  -- �����f�[�^�i�[�p�z��
    lv_msg_tnk          VARCHAR2(5000);                     -- ���b�Z�[�W�g�[�N���p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- �t�@�C��ID
      ,ov_file_data => l_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �g�[�N���擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_nm_file_ul_if
                    );
      --�f�[�^���o�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => lv_msg_tnk
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�f�[�^�`�F�b�N
    --==============================================================
    --�w�b�_�s���������f�[�^��0�s�̏ꍇ
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      --�Ώی���0�����b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      --�Ώی���0�����b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode  := cv_status_warn;
      --�f�[�^�����̂��߈ȉ��̏����͍s��Ȃ��B
      RETURN;
    END IF;
--
    --�Ώی����̎擾
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    --���ڐ��̃`�F�b�N
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --���ڐ��擾(��؂蕶���̐��Ŕ���)
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --���ڐ��`�F�b�N
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        --�ėpCSV�t�H�[�}�b�g�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        --���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode  := cv_status_warn;
      ELSE
        --����ȍs�͍��ڐ��𕪊�����
        <<col_sep_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --���ڕ���(�����񊇂�͍폜)
          l_sep_data_tab(ln_line_cnt)(ln_column_cnt) := REPLACE(xxccp_common_pkg.char_delim_partition(
                                                          iv_char     => l_file_data_tab(ln_line_cnt)
                                                         ,iv_delim    => cv_col_separator
                                                         ,in_part_num => ln_column_cnt
                                                        ), cv_dqu, NULL);
        END LOOP col_sep_loop;
      END IF;
    END LOOP line_data_loop;
--
    ov_sep_data_tab := l_sep_data_tab;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : business_data_check
   * Description      : �f�[�^���e�`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE business_data_check(
     iv_sep_data_tab IN  gt_rec_data_ttype -- 1.���ڕ�����f�[�^
    ,ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'business_data_check'; -- �v���O������
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
    cv_aprv_status    CONSTANT VARCHAR2(8)   := 'APPROVED';  -- ���F��
--
    -- *** ���[�J���ϐ� ***
    ln_data_num                NUMBER;                       --���[�v�J�E���^
    lr_po_dis_row_id           ROWID;
    lv_msg                     VARCHAR2(5000);               --�G���[���b�Z�[�W�擾�p
    lv_msg_tkn                 VARCHAR2(5000);               --�G���[���b�Z�[�W�g�[�N���擾�p
    lv_dummy                   VARCHAR2(1);                  --���݃`�F�b�N�p
    ln_upd_cnt                 NUMBER := 0;                  --�X�V�z��̓Y����
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
    -- �w�b�_�s�������ď�������
    <<chk_loop>>
    FOR ln_data_num IN 2 .. iv_sep_data_tab.COUNT LOOP
      --------------------------------------------
      -- �Ɩ��`�F�b�N
      --------------------------------------------
      --�X�V�Ώۂ̑��݃`�F�b�N
      BEGIN
        SELECT pd.rowid  row_id
        INTO   lr_po_dis_row_id                   -- �X�V�p��ROWID
        FROM   po_headers_all               ph    -- �����w�b�_
              ,po_lines_all                 pl    -- ��������
              ,po_distributions_all         pd    -- ��������
              ,po_requisition_headers_all   prh   -- �w���˗��w�b�_
              ,po_requisition_lines_all     prl   -- �w���˗�����
              ,po_req_distributions_all     prd   -- �w���˗�����
              ,xxcso_wk_requisition_proc    xwrp  -- ��ƈ˗��^�������A�g�Ώۃe�[�u��
        WHERE  ph.po_header_id            = pl.po_header_id
        AND    ph.po_header_id            = pd.po_header_id
        AND    pl.po_line_id              = pd.po_line_id
        AND    pd.req_distribution_id     = prd.distribution_id
        AND    prd.requisition_line_id    = prl.requisition_line_id
        AND    prl.requisition_header_id  = prh.requisition_header_id
        AND    prl.requisition_line_id    = xwrp.requisition_line_id
        AND    ph.segment1                = iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num)       -- �����ԍ�
        AND    pl.line_num                = iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)  -- �������הԍ�
        AND    prh.segment1               = iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)      -- �w���˗��ԍ�
        AND    prl.line_num               = iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num) -- �w���˗����הԍ�
        AND    xwrp.interface_flag        = cv_no                                                 -- ���̋@�V�X�e�����A�g
        AND    (
                   ph.authorization_status IS NULL
                OR ph.authorization_status  <> cv_aprv_status
               )                                                                                  -- ���F�ψȊO
        FOR UPDATE OF
               pd.po_distribution_id
        NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          --���b�N�G���[���b�Z�[�W
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_po_distributions_lock
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
        WHEN NO_DATA_FOUND THEN
          --�G���[���b�Z�[�W
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_no_target
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
      END;
--
      --�X�V�p�̃��[�X�敪��NULL�ȊO�̏ꍇ
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type) IS NOT NULL ) THEN
        --���[�X�敪�̑��݃`�F�b�N
        BEGIN
          SELECT '1' dummy
          INTO   lv_dummy
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lkup_lease_kbn -- ���[�X�敪
          AND    flvv.enabled_flag = cv_yes
          AND    gd_process_date  >= NVL(flvv.start_date_active ,gd_process_date)
          AND    gd_process_date  <= NVL(flvv.end_date_active   ,gd_process_date)
          AND    flvv.lookup_code  = iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type)  --�X�V�p�̃��[�X�敪
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�g�[�N���擾
            lv_msg_tkn := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_lease_kbn
                          );
            --�G���[���b�Z�[�W
            lv_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_not_found
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => lv_msg_tkn
                         ,iv_token_name2  => cv_tkn_po_num
                         ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                         ,iv_token_name3  => cv_tkn_po_line_num
                         ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                         ,iv_token_name4  => cv_tkn_po_rec_num
                         ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                         ,iv_token_name5  => cv_tkn_po_rec_line_num
                         ,iv_token_value5 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                       );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode  := cv_status_warn;
        END;
      END IF;
--
      --�X�V�p�̎擾���i��NULL�ȊO�̏ꍇ
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) IS NOT NULL ) THEN
        --�擾���i�̃`�F�b�N
        IF (
                ( LENGTHB( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) ) > cv_price_num )               --10���ȓ�
             OR ( xxccp_common_pkg.chk_number( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) ) = FALSE )  --���p�p���E�}�C�i�X�l
           )
        THEN
          --�G���[���b�Z�[�W
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_price
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
        END IF;
      END IF;
--
      --�X�V�p�̐\���n��NULL�ȊO�̏ꍇ
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place) IS NOT NULL ) THEN
        --�\���n�̑��݃`�F�b�N
        BEGIN
          SELECT '1' dummy
          INTO   lv_dummy
          FROM   fnd_flex_values      ffv
               , fnd_flex_values_tl   ffvt
               , fnd_flex_value_sets  ffvs
          WHERE  ffv.flex_value_id        = ffvt.flex_value_id
          AND    ffvt.language            = cv_language
          AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
          AND    ffvs.flex_value_set_name = cv_flex_dclr_place  -- �\���n
          AND    ffv.enabled_flag         = cv_yes
          AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
          AND    gd_process_date         <= NVL(ffv.end_date_active   ,gd_process_date)
          AND    ffv.flex_value           = iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place)  --�X�V�p�\���n�R�[�h
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�g�[�N���擾
            lv_msg_tkn := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_dclr_place
                          );
            --�G���[���b�Z�[�W
            lv_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_not_found
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => lv_msg_tkn
                         ,iv_token_name2  => cv_tkn_po_num
                         ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                         ,iv_token_name3  => cv_tkn_po_line_num
                         ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                         ,iv_token_name4  => cv_tkn_po_rec_num
                         ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                         ,iv_token_name5  => cv_tkn_po_rec_line_num
                         ,iv_token_value5 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                       );
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode  := cv_status_warn;
        END;
      END IF;
--
      --�G���[�����݂��Ȃ��ꍇ�A�X�V�p�̔z��Ɋi�[(1���R�[�h�ł��G���[�̏ꍇ�͈ȍ~�`�F�b�N�̂�)
      IF ( ov_retcode = cv_status_normal ) THEN
        ln_upd_cnt                   := ln_upd_cnt + 1;                                      --�Y�����J�E���g
        gt_row_id_tab(ln_upd_cnt)    := lr_po_dis_row_id;                                    --�������ה���ROWID
        gt_lease_kbn_tab(ln_upd_cnt) := iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type); --���[�X�敪
        gt_dclr_place(ln_upd_cnt)    := iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place); --�\���n
        gt_price_ttype(ln_upd_cnt)   := iv_sep_data_tab(ln_data_num)(cn_col_pos_price);      --�擾���i
      END IF;
--
    END LOOP chk_loop;
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
  END business_data_check;
--
  /**********************************************************************************
   * Procedure Name   : update_distributions
   * Description      : �������ה���DFF�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE update_distributions(
     ov_errbuf       OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_distributions'; -- �v���O������
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
    lv_msg_tkn  VARCHAR2(5000);
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
    BEGIN
      FORALL i IN 1..gt_row_id_tab.COUNT
        UPDATE  po_distributions_all pda
        SET     pda.attribute_category     = TO_CHAR(gn_org_id)             --�A�g���r���[�g�J�e�S��(�c��)
               ,pda.attribute1             = gt_lease_kbn_tab(i)            --���[�X�敪
               ,pda.attribute2             = gt_price_ttype(i)              --�擾���i
               ,pda.attribute3             = gt_dclr_place(i)               --�\���n
               ,pda.last_updated_by        = cn_last_updated_by             --�ŏI�X�V��
               ,pda.last_update_date       = cd_last_update_date            --�ŏI�X�V��
               ,pda.last_update_login      = cn_last_update_login           --�ŏI�X�V۸޲�
               ,pda.request_id             = cn_request_id                  --�v��ID
               ,pda.program_application_id = cn_program_application_id      --�ݶ��ĥ��۸��ѥ���ع����ID
               ,pda.program_id             = cn_program_id                  --�ݶ��ĥ��۸���ID
               ,pda.program_update_date    = cd_program_update_date         --��۸��эX�V��
        WHERE   pda.ROWID  =  gt_row_id_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_msg_tkn := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_po_distributions
                      );
        --�G���[���b�Z�[�W
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_update_error
                        ,iv_token_name1  => cv_tkn_action
                        ,iv_token_value1 => lv_msg_tkn
                        ,iv_token_name2  => cv_tkn_error_msg
                        ,iv_token_value2 => SQLERRM
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --���������̎擾
    gn_normal_cnt := gt_row_id_tab.COUNT;
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
  END update_distributions;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg_tnk VARCHAR2(5000);  -- ���b�Z�[�W�g�[�N���擾�p
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
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�G���[���̃g�[�N���擾
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_nm_file_ul_if
                      );
        -- �f�[�^�폜�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => TO_CHAR( in_file_id )
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
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
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_file_id    IN  VARCHAR2     -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.�t�H�[�}�b�g�p�^�[��  )
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
    ln_file_id  NUMBER;
--
    -- *** ���[�J���E�e�[�u�� ***
    lv_sep_data_tab  gt_rec_data_ttype;  --���ڕ����f�[�^�擾�p
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_file_id => iv_file_id   -- 1.�t�@�C��ID
      ,iv_fmt_ptn => iv_fmt_ptn   -- 2.�t�H�[�}�b�g�p�^�[��
      ,on_file_id => ln_file_id   -- 3.�t�@�C��ID�i�^�ϊ���j
      ,ov_errbuf  => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg);  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^���o(A-2)
    -- ===============================
    get_upload_data(
       in_file_id      => ln_file_id
      ,ov_sep_data_tab => lv_sep_data_tab    -- ���ڕ�����f�[�^
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================
      -- �f�[�^���e�`�F�b�N(A-3)
      -- ===============================
      business_data_check(
         iv_sep_data_tab => lv_sep_data_tab
        ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================
      -- �������ה���DFF�X�V(A-4)
      -- ===============================
      update_distributions(
         ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜(A-5)
    -- ===============================
    delete_file_ul_if(
       in_file_id  => ln_file_id
      ,ov_errbuf   =>  lv_errbuf
      ,ov_retcode  =>  lv_retcode
      ,ov_errmsg   =>  lv_errmsg);
--
    IF (lv_retcode = cv_status_error) THEN
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
    ,iv_fmt_ptn    IN  VARCHAR2)     -- 2.�t�H�[�}�b�g�p�^�[��
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
      -- �Ώی���������
      gn_target_cnt := 0;
      -- ��������������
      gn_normal_cnt := 0;
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
END XXCSO011A04C;
/
