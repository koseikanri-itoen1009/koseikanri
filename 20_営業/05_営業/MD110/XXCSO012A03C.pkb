CREATE OR REPLACE PACKAGE BODY APPS.XXCSO012A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO012A03C(body)
 * Description      : �t�@�C���A�b�v���[�hIF�Ɏ捞�܂ꂽ�����̔��@�X�V�f�[�^�ɂ�
 *                    �����}�X�^���(IB)���X�V���܂��B
 * MD.050           : �����̔��@�f�[�^�X�V <MD050_CSO_012_A03>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_item_instances     �t�@�C���A�b�v���[�h�f�[�^���o (A-2)
 *  chk_data_layout        ���C�A�E�g�`�F�b�N���� (A-3)
 *  chk_data_exist         ���݃`�F�b�N���� (A-4)
 *  update_item_instances  �����f�[�^�X�V���� (A-5)
 *  rock_file_interface    �t�@�C���f�[�^���b�N���� (A-6)
 *  delete_file_interface  �t�@�C���f�[�^�폜���� (A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/09/16    1.0   Taketo Oda       �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO012A03C';      -- �p�b�P�[�W��
  cv_app_name               CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_32          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- �f�[�^���o0�����b�Z�[�W
  cv_tkn_number_33          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �t�@�C��ID�o��
  cv_tkn_number_34          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[���o��
  cv_tkn_number_61          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- �p�����[�^Null�G���[
  cv_tkn_number_02          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_35          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �A�b�v���[�h�t�@�C�����̎擾�G���[
  cv_tkn_number_36          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �A�b�v���[�h�t�@�C�����̏o��
  cv_tkn_number_10          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- ����^�C�vID�擾�G���[
  cv_tkn_number_11          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- ����^�C�vID���o�G���[
  cv_tkn_number_12          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- �ǉ�����ID���o�G���[
  cv_tkn_number_49          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- �f�[�^���b�N�G���[
  cv_tkn_number_40          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00554';  -- BLOB�ϊ��G���[
  cv_tkn_number_39          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- �A�b�v���[�h�t�@�C�����̏o��
  cv_tkn_number_41          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_45          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- �f�[�^���o�A�o�^�x�����b�Z�[�W
  cv_tkn_number_48          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- �f�[�^�폜�G���[
  cv_tkn_number_51          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00550';  -- CSV�f�[�^�t�H�[�}�b�g�G���[
  cv_tkn_number_53          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- �\���n
  cv_tkn_number_56          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- ���݃G���[
  cv_tkn_number_58          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00681';  -- �l�Z�b�g �F
  cv_tkn_number_59          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00670';  -- ���[�X�敪
  cv_tkn_number_60          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- �����R�[�h
  cv_tkn_number_62          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00051';  -- �������݃`�F�b�N�x�����b�Z�[�W
  cv_tkn_number_63          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00710';  -- �Œ莑�Y�`�F�b�N�G���[
  cv_tkn_number_64          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00711';  -- ����^�C�v�̎���^�C�vID
  cv_tkn_number_65          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00712';  -- �ݒu�@��g��������`���̒ǉ�����ID
  cv_tkn_number_66          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00713';  -- �����̔��@�X�V�f�[�^
  cv_tkn_number_67          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00676';  -- �t�@�C���A�b�v���[�hIF
  cv_tkn_number_68          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00704';  -- ���b�N
  cv_tkn_number_69          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00714';  -- �����}�X�^
  cv_tkn_number_70          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- �X�V
  cv_tkn_number_71          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00715';  -- ���o
  cv_tkn_number_72          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00716';  -- �G���[�F
  cv_target_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_success_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_error_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--
  -- �g�[�N���R�[�h
  cv_tkn_file_id            CONSTANT VARCHAR2(20)  := 'FILE_ID';
  cv_tkn_format             CONSTANT VARCHAR2(20)  := 'FORMAT_PATTERN';
  cv_tkn_prof_nm            CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_upload             CONSTANT VARCHAR2(20)  := 'UPLOAD_FILE_NAME';
  cv_tkn_src_tran_type      CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';
  cv_tkn_task_nm            CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_attribute_name     CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code     CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_value_set_name     CONSTANT VARCHAR2(20)  := 'VALUE_SET_NAME';
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_csv_upload         CONSTANT VARCHAR2(20)  := 'CSV_FILE_NAME';
  cv_tkn_item               CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_base_value         CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_process            CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_bukken             CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
--
  cv_encoded_f              CONSTANT VARCHAR2(1)   := 'F';                 -- FALSE
--
  cv_msg_conm               CONSTANT VARCHAR2(1)   := ',';                 -- �J���}
--
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';                 -- �n�C�t��
  -- �l�Z�b�g
  cv_xxcff_dclr_place       CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';  -- �\���n
  -- �Q�ƃ^�C�v
  cv_xxcso1_lease_kbn       CONSTANT VARCHAR2(30)  := 'XXCSO1_LEASE_KBN';  -- ���[�X�敪
  --
  cv_fixed_assets           CONSTANT VARCHAR2(1)   := '4';                 -- ���[�X�敪�u�Œ莑�Y�v
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';                 -- �L���t���OY
  ct_language               CONSTANT fnd_flex_values_tl.language%TYPE := USERENV('LANG'); -- ����
  -- ���[�X�敪
  cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
  -- �\���n
  cv_dclr_place             CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gt_txn_type_id            csi_txn_types.transaction_type_id%TYPE;        -- ����^�C�vID
  gd_process_date           DATE;                                          -- �Ɩ����t
  gv_file_name              VARCHAR2(1000);                                -- ���̓t�@�C����
  gt_instance_id            csi_item_instances.instance_id%TYPE;           -- ����ID
  gt_object_version_number  csi_item_instances.object_version_number%TYPE; -- �I�u�W�F�N�g�o�[�W�����ԍ�
  gt_lease_kbn              csi_iea_values.attribute_value%TYPE;           -- ���[�X�敪
--
  -- �ǉ�����ID�i�[�p���R�[�h�^��`
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     lease_kbn              NUMBER                  -- ���[�X�敪
    ,dclr_place             NUMBER                  -- �\���n
  );
  -- �ǉ�����ID�i�[�p���R�[�h�ϐ�
  gr_ext_attribs_id_rec     gr_ib_ext_attribs_id_rtype;
--
  --BLOB�f�[�^�i�[�z��
  gr_file_data_tbl          xxccp_common_pkg2.g_file_data_tbl;
--
  --BLOB�f�[�^�����f�[�^�i�[
  TYPE gr_blob_data_rtype IS RECORD(
    object_code             VARCHAR2(10)            -- �����R�[�h
   ,dclr_place              VARCHAR2(5)             -- �\���n
  );
  gr_blob_data gr_blob_data_rtype;
--  
  -- *** ���[�U�[��`�O���[�o����O ***
  global_lock_expt          EXCEPTION;              -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id           IN  NUMBER                -- �t�@�C��ID
    ,iv_format            IN  VARCHAR2              -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf            OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- �t�@�C���A�b�v���[�h����
    cv_xxcso1_file_name       CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';
    -- �\�[�X�g�����U�N�V�����^�C�v
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- �t�@�C���A�b�v���[�h�R�[�h
    cv_xxcso1_file_code       CONSTANT VARCHAR2(30)  := '680';
--
    -- *** ���[�J���ϐ� ***
    -- �Ɩ�������
    ld_process_date           DATE;
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_noprm_msg              VARCHAR2(5000);  
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value              VARCHAR2(1000);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                    VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ============================
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- ============================
    --�t�@�C��ID
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_33           --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id
                       ,iv_token_value1 => in_file_id
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg
    );
--
    --�t�H�[�}�b�g�p�^�[��
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_34             --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_format
                     ,iv_token_value1 => iv_format
                    );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- ==========================
    -- ���̓p�����[�^�K�{�`�F�b�N
    -- ==========================
    --�t�@�C��ID
    IF (in_file_id IS NULL) THEN
      -- =================================
      -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��(�ُ�I�������邱��) 
      -- =================================
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_61    --���b�Z�[�W�R�[�h
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02              --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ld_process_date :=TRUNC(gd_process_date);
--
    -- =================================
    -- �t�@�C���A�b�v���[�h���̎擾���� 
    -- =================================
    BEGIN
      SELECT flvv.meaning    meaning  -- �t�@�C���A�b�v���[�h����
      INTO   gv_file_name
      FROM   fnd_lookup_values_vl  flvv  -- �Q�ƃ^�C�v
      WHERE  flvv.lookup_type      = cv_xxcso1_file_name
      AND    flvv.lookup_code      = cv_xxcso1_file_code
      AND    flvv.enabled_flag     = cv_y
      AND    NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
      AND    NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_35           -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --�擾�����t�@�C���A�b�v���[�h���̂��t�@�C���o��
    lv_noprm_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                 --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_36            --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_upload
                      ,iv_token_value1 => gv_file_name
                     );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- ====================
    -- ����^�C�vID�擾���� 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id    transaction_type_id       -- �g�����U�N�V�����^�C�vID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                    -- ����^�C�v
      WHERE  ctt.source_transaction_type = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_number_64           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type    -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_number_64           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                    -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- �ǉ�����ID�擾���� 
    -- ====================
    -- ������
    gr_ext_attribs_id_rec := NULL;
--
    -- �ǉ�����ID(���[�X�敪)
    gr_ext_attribs_id_rec.lease_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_lease_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.lease_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_number_65             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_number_59             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_lease_kbn                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �ǉ�����ID(�\���n)
    gr_ext_attribs_id_rec.dclr_place := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_dclr_place
                                          ,ld_process_date
                                        );
    IF ( gr_ext_attribs_id_rec.dclr_place IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_number_65             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_tkn_number_53             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_dclr_place                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--    
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_item_instances
   * Description      : �t�@�C���A�b�v���[�h�f�[�^���o (A-2)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     in_file_id              IN     NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_instances'; -- �v���O������
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
    lv_file_name             xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSV�t�@�C����
    lv_msg                   VARCHAR2(5000);
--
    -- *** ���[�J����O ***
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- ***************************************************
    -- 1.CSV�t�@�C�����擾
    -- ***************************************************
    SELECT xciwd.file_name  file_name  -- �t�@�C����
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface    xciwd
    WHERE  xciwd.file_id = in_file_id
    ;
--
    --�擾����CSV�t�@�C���������b�Z�[�W�o��
    lv_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_39             --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_csv_upload
                       ,iv_token_value1 => lv_file_name
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_msg       || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
--
    -- ***************************************************
    -- 2.BLOB�f�[�^�ϊ�
    -- ***************************************************
    --���ʃA�b�v���[�h�f�[�^�ϊ�����
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- �t�@�C���h�c
      ,ov_file_data => gr_file_data_tbl -- �ϊ���VARCHAR2�f�[�^
      ,ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_40,    -- ���b�Z�[�W�F�f�[�^�ϊ��G���[
                     cv_tkn_table,
                     cv_tkn_number_67,
                     cv_tkn_file_id,
                     in_file_id,
                     cv_tkn_errmsg,
                     SQLERRM);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_layout
   * Description      : ���C�A�E�g�`�F�b�N (A-3)
   ***********************************************************************************/
  PROCEDURE chk_data_layout(
     it_blob_data            IN     xxccp_common_pkg2.g_file_data_tbl                  -- blob�f�[�^(�s�P��)
    ,in_data_num             IN     NUMBER                  -- �z��ԍ�
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_layout'; -- �v���O������
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
    cn_format_col_cnt        CONSTANT NUMBER := 2;  -- ���ڐ�
--
    -- *** ���[�J���ϐ� ***
    lb_ret                   BOOLEAN;
    lb_format_flag           BOOLEAN := TRUE;
    lv_tmp                   VARCHAR2(2000);
    ln_pos                   NUMBER;
    ln_cnt                   NUMBER := 1;
    lv_msg                   VARCHAR2(5000);
--
    -- *** ���[�J����O ***
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- ***************************************************
    -- 1.���ڐ��擾
    -- ***************************************************
    IF (it_blob_data(in_data_num) IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := it_blob_data(in_data_num);
      LOOP
        ln_pos := INSTR(lv_tmp, cv_msg_conm);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.���ڐ��`�F�b�N
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_51           -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_number_66           -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_base_value          -- �g�[�N���R�[�h1
                     ,iv_token_value2 => it_blob_data(in_data_num)  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- ***************************************************
    -- 2.blob�f�[�^�����A3.�K�{�`�F�b�N
    -- ***************************************************
    --�����R�[�h
    gr_blob_data.object_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,1);
    IF (gr_blob_data.object_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_tkn_number_60,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�\���n
    gr_blob_data.dclr_place := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,2);
    IF (gr_blob_data.dclr_place IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- �A�v���P�[�V�����Z�k���FXXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_tkn_number_53,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_data_layout;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_exist
   * Description      : ���݃`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_exist(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_exist'; -- �v���O������
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
    ln_cnt                   NUMBER;
    lv_msg                   VARCHAR2(5000);
    lv_msg2                  VARCHAR2(5000);
    lb_ret                   BOOLEAN DEFAULT TRUE;
    lt_dclr_place            fnd_flex_values.flex_value%TYPE;   -- �\���n
--
    -- *** ���[�J����O ***
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- ***************************************************
    -- 1.�����R�[�h���݃`�F�b�N
    -- ***************************************************
    BEGIN
      SELECT cii.instance_id             instance_id            -- �C���X�^���XID
            ,cii.object_version_number   object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
            ,civ.attribute_value         attribute_value        -- ���[�X�敪
      INTO   gt_instance_id
            ,gt_object_version_number
            ,gt_lease_kbn
      FROM   csi_item_instances         cii
            ,csi_i_extended_attribs     ciea
            ,csi_iea_values             civ
      WHERE  cii.external_reference = gr_blob_data.object_code
      AND    cii.instance_id        = civ.instance_id(+)
      AND    ciea.attribute_code    = cv_lease_kbn
      AND    ciea.attribute_id      = civ.attribute_id
      ;
--
    EXCEPTION
      -- �X�V�Ώۂ̕����R�[�h���C���X�g�[���x�[�X�ɑ��݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_62              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_bukken                 -- �g�[�N���R�[�h1
                       ,iv_token_value1  => gr_blob_data.object_code      -- �g�[�N���l1
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_tkn_number_69              -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2  => SQLERRM                       -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_process                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => cv_tkn_number_71              -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place             -- �g�[�N���l4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
      -- �X�V�Ώۂ̕������̃��[�X�敪���Œ莑�Y�łȂ��ꍇ
    IF gt_lease_kbn <> cv_fixed_assets THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_tkn_number_63              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_bukken                 -- �g�[�N���R�[�h1
                    ,iv_token_value1  => gr_blob_data.object_code      -- �g�[�N���l1
                    ,iv_token_name2   => cv_tkn_base_value             -- �g�[�N���R�[�h2
                    ,iv_token_value2  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place             -- �g�[�N���l2
      );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  -- ***************************************************
  -- 2.�\���n�}�X�^���݃`�F�b�N
  -- ***************************************************
    --
    -- �\���n�̃}�X�^�`�F�b�N
    BEGIN
      SELECT ffv.flex_value       flex_value
      INTO   lt_dclr_place
      FROM   fnd_flex_values      ffv
            ,fnd_flex_values_tl   ffvt
            ,fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_xxcff_dclr_place
      AND    gd_process_date BETWEEN NVL(ffv.start_date_active, gd_process_date)
                             AND     NVL(ffv.end_date_active, gd_process_date)
      AND    ffv.enabled_flag         = cv_y
      AND    ffvt.language            = ct_language
      AND    ffv.flex_value           = gr_blob_data.dclr_place
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_53               -- ���b�Z�[�W
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_58               -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_value_set_name          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_xxcff_dclr_place            -- �g�[�N���l1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_56               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table                   -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_msg2                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_base_value              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.dclr_place        -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_58               -- ���b�Z�[�W
                       ,iv_token_name1  => cv_tkn_value_set_name          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_xxcff_dclr_place            -- �g�[�N���l1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_45               -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg2                        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_process                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_tkn_number_71               -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_base_value              -- �g�[�N���R�[�h4
                       ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.dclr_place     -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instances
   * Description      : �����f�[�^�X�V���� (A-5)
   ***********************************************************************************/
  PROCEDURE update_item_instances(
     ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_item_instances'; -- �v���O������
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
    cn_api_version             CONSTANT NUMBER        := 1.0;
--
    -- *** ���[�J���ϐ� ***
    ln_validation_level        NUMBER;                  -- �o���f�[�V�������[�x��
    lv_commit                  VARCHAR2(1);             -- �R�~�b�g�t���O
    lv_init_msg_list           VARCHAR2(2000);          -- ���b�Z�[�W���X�g
--
    -- API�߂�l�i�[�p
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API���o�̓��R�[�h�l�i�[�p
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
    l_ext_attrib_rec           csi_iea_values%ROWTYPE;
    l_instance_id_lst          csi_datastructures_pub.id_tbl;
--
    -- *** ���[�J����O ***
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- �f�[�^�̊i�[
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
--
    -- ================================
    -- 1.�C���X�^���X���R�[�h�쐬
    -- ================================
    l_instance_rec.instance_id              := gt_instance_id;              -- ����ID
    l_instance_rec.object_version_number    := gt_object_version_number;    -- �I�u�W�F�N�g�o�[�W�����ԍ�
--
    -- ==================================
    -- 2.�o�^�p�ݒu�@��g�������l���쐬
    -- ==================================
    -- �\���n
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(gt_instance_id, cv_dclr_place);
    l_ext_attrib_values_tab(0).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
    l_ext_attrib_values_tab(0).attribute_value       := gr_blob_data.dclr_place;
    l_ext_attrib_values_tab(0).instance_id           := gt_instance_id;
    l_ext_attrib_values_tab(0).object_version_number := l_ext_attrib_rec.object_version_number;
--
    -- ===============================
    -- 3.������R�[�h�f�[�^�쐬
    -- ===============================
--
    l_txn_rec.transaction_date              := SYSDATE;
    l_txn_rec.source_transaction_date       := SYSDATE;
    l_txn_rec.transaction_type_id           := gt_txn_type_id;
--
    -- =================================
    -- 4.�W��API���A�����X�V�������s��
    -- =================================
--
    CSI_ITEM_INSTANCE_PUB.update_item_instance(
       p_api_version           => cn_api_version
      ,p_commit                => lv_commit
      ,p_init_msg_list         => lv_init_msg_list
      ,p_validation_level      => ln_validation_level
      ,p_instance_rec          => l_instance_rec
      ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      ,p_party_tbl             => l_party_tab
      ,p_account_tbl           => l_account_tab
      ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
      ,p_org_assignments_tbl   => l_org_assignments_tab
      ,p_asset_assignment_tbl  => l_asset_assignment_tab
      ,p_txn_rec               => l_txn_rec
      ,x_instance_id_lst       => l_instance_id_lst
      ,x_return_status         => lv_return_status
      ,x_msg_count             => ln_msg_count
      ,x_msg_data              => lv_msg_data
    );
--
    -- ����I���łȂ��ꍇ
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (FND_MSG_PUB.Count_Msg > 0) THEN
        FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
          FND_MSG_PUB.Get(
             p_msg_index     => i
            ,p_encoded       => cv_encoded_f
            ,p_data          => lv_io_msg_data
            ,p_msg_index_out => ln_io_msg_count
          );
          lv_msg_data := lv_msg_data || lv_io_msg_data;
        END LOOP;
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name          => cv_tkn_number_45              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1  => cv_tkn_number_69              -- �g�[�N���l1
                     ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                     ,iv_token_value2  => cv_tkn_number_70              -- �g�[�N���l2
                     ,iv_token_name3   => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                     ,iv_token_value3  => lv_msg_data                   -- �g�[�N���l3
                     ,iv_token_name4   => cv_tkn_base_value             -- �g�[�N���R�[�h4
                     ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||
                                          gr_blob_data.dclr_place       -- �g�[�N���l4
                   );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                   XXCCP_COMMON_PKG.GET_MSG(    -- "�G���[�F"
                        IV_APPLICATION   => 'XXCSO'              -- �A�v���P�[�V�����Z�k��
                       ,IV_NAME          => 'APP-XXCSO1-00716')  -- ���b�Z�[�W�R�[�h
                   ||lv_errmsg|| CHR(10) ||
                   ''                           -- ��s�̑}��
      );
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : rock_file_interface
   * Description      : �t�@�C���f�[�^���b�N���� (A-6)
   ***********************************************************************************/
  PROCEDURE rock_file_interface(
     in_file_id              IN  NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_file_interface'; -- �v���O������
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
    -- *** ���[�J���E���R�[�h ***
    CURSOR rock_interface_cur IS
      SELECT xmfui.file_id    file_id
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
    rock_interface_rec rock_interface_cur%ROWTYPE;
--
    -- *** ���[�J����O ***
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �t�@�C���A�b�v���[�hIF���o
    BEGIN
--
      OPEN rock_interface_cur;
      FETCH rock_interface_cur INTO rock_interface_rec;
      CLOSE rock_interface_cur;
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_49              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_number_67              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                       -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_45             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_tkn_number_67             -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process               -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_tkn_number_68             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3  => SQLERRM                      -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_base_value            -- �g�[�N���R�[�h4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place   -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END rock_file_interface;
--
   /**********************************************************************************
   * Procedure Name   : delete_file_interface
   * Description      : �t�@�C���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_file_interface(
     in_file_id              IN  NUMBER                  -- �t�@�C��ID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_interface';  -- �v���O������
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
--
    -- *** ���[�J���E��O ***
    delete_error_expt        EXCEPTION;
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
      -- ==========================================
      -- �t�@�C���f�[�^�폜���� 
      -- ==========================================
      DELETE
      FROM   xxccp_mrp_file_ul_interface  xmfui                  -- �t�@�C���A�b�v���[�hIF
      WHERE  xmfui.file_id = in_file_id
      ;
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_48             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_number_67             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => in_file_id                   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;
--
  EXCEPTION
--
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ������O�n���h�� ***
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
  END delete_file_interface;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2,     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    in_file_id    IN  NUMBER,       --   �t�@�C��ID
    iv_format     IN  VARCHAR2)     --   �t�H�[�}�b�g�p�^�[��
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    skip_process_expt       EXCEPTION;
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
--
    -- ================================
    -- A-1.�������� 
    -- ================================
--
    init(
       in_file_id            => in_file_id          -- �t�@�C��ID
      ,iv_format             => iv_format           -- �t�H�[�}�b�g�p�^�[��
      ,ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�t�@�C���A�b�v���[�h�f�[�^���o����
    -- ========================================
    get_item_instances(
       in_file_id       => in_file_id     -- �t�@�C��ID
      ,ov_errbuf        => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode       => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg        => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����Ώی����i�[
    gn_target_cnt := gr_file_data_tbl.COUNT;
--
    FOR i IN gr_file_data_tbl.FIRST..gr_file_data_tbl.LAST LOOP
      -- ===========================
      -- A-3.���C�A�E�g�`�F�b�N����
      -- ===========================
      chk_data_layout(
        it_blob_data => gr_file_data_tbl
       ,in_data_num  => i
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-4.���݃`�F�b�N����
      -- ===========================
    -- �O���[�o���ϐ��̏�����
      gt_instance_id := NULL;
      gt_object_version_number := NULL;
      gt_lease_kbn  := NULL;
--
      chk_data_exist(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-5.�����f�[�^�X�V����
      -- ========================================
      update_item_instances(
        ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP;
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_32             --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                         -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- �G���[���b�Z�[�W
      );
--     
    ELSE
      -- ========================================
      -- A-6.�t�@�C���f�[�^���b�N����
      -- ========================================
      rock_file_interface(
        in_file_id   => in_file_id     -- �t�@�C��ID
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
  --
      -- ========================================
      -- A-7.�t�@�C���f�[�^�폜����
      -- ========================================
      delete_file_interface(
        in_file_id   => in_file_id     -- �t�@�C��ID
       ,ov_errbuf    => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ,ov_retcode   => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
       ,ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT  NOCOPY  VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id    IN   NUMBER,                --   �t�@�C��ID
    iv_format     IN   VARCHAR2               --   �t�H�[�}�b�g�p�^�[��
  )
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
      ov_errbuf   => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode  => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg   => lv_errmsg,           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      in_file_id  => in_file_id,          -- �t�@�C��ID
      iv_format   => iv_format            -- �t�@�C���t�H�[�}�b�g
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errbuf                  --�G���[���b�Z�[�W
      );
      -- �Ώی���������
      gn_target_cnt := 0;
      -- ��������������
      gn_normal_cnt := 0;
      -- �G���[�����̎擾
      gn_error_cnt  := 1;
    END IF;
--
    -- =======================
    -- A-8.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO012A03C;
/
