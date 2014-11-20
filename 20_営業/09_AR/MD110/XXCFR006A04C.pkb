create or replace PACKAGE BODY XXCFR006A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A04C(body)
 * Description      : �����ꊇ�����A�b�v���[�h
 * MD.050           : MD050_CFR_006_A04_�����ꊇ�����A�b�v���[�h
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              p ��������                                (A-1)
 *  get_if_data            p �t�@�C���A�b�v���[�hIF�f�[�^�擾����    (A-2)
 *  devide_item            p �f���~�^�������ڕ���                    (A-3)
 *  insert_work            p ���[�N�e�[�u���o�^                      (A-4)
 *  check_data             p �Ó����`�F�b�N                          (A-5)
 *  get_cust_trx_data      p ������ݒ�                            (A-6)
 *  get_cash_rec_data      p �������ݒ�                            (A-7)
 *  ecxec_apply_api        p ��������API�N������                     (A-8)
 *  proc_end               p �I������                                (A-9)
 *  check_data_lock        p �������r���`�F�b�N                    (A-10)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/05/26    1.0   SCS ���� ����    �V�K�쐬
 *  2010/09/02    1.1   SCS �n�� �w      E_�{�ғ�_00390 �ǉ��Ή�
 *  2011/08/11    1.2   SCS ���� �Ďj    E_�{�ғ�_07667 �ǉ��Ή�
 *  2014/02/13    1.3   SCSK ���� �O��   E_�{�ғ�_11286 �ǉ��Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  #######################
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
--################################  �Œ蕔 END  ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START  #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;    -- �Ώی���
  gn_normal_cnt    NUMBER;    -- ���팏��
  gn_error_cnt     NUMBER;    -- �G���[����
  gn_warn_cnt      NUMBER;    -- �X�L�b�v����
--
--################################  �Œ蕔 END  ##################################
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
--################################  �Œ蕔 END  ##################################
---- ===============================
  -- ���[�U�[��`��O
  -- ===============================
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCFR006A04C';     -- �p�b�P�[�W��
  cv_log               CONSTANT VARCHAR2(100) := 'LOG';              -- �R���J�����g���O�o�͐�--
  cv_out               CONSTANT VARCHAR2(100) := 'OUTPUT';           -- �R���J�����g�o�͐�--
  cv_yyyy_mm_dd        CONSTANT VARCHAR2(10)  := 'YYYY-MM-DD';       -- �t�H�[�}�b�g
--
  cv_set_of_bks_id     CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID'; -- ��v����ID
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_upl_limit_of_count  CONSTANT VARCHAR2(30) := 'XXCFR1_UPL_LIMIT_OF_COUNT'; -- �A�b�v���[�h�p�Ώی���臒l
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  cv_appl_name_cfr     CONSTANT VARCHAR2(10)  := 'XXCFR';            -- �A�h�I���FAR
  cv_appl_name_cmn     CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
  cv_appl_name_ar      CONSTANT VARCHAR2(10)  := 'AR';               -- �W���FAR
--
  cv_closing_status_o  CONSTANT VARCHAR2(1)   := 'O';                -- ��v���ԃX�e�[�^�X(�I�[�v��)
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
  -- �����X�e�[�^�X
  cv_status_unapp      CONSTANT VARCHAR2(5)   := 'UNAPP';            -- ������
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
  -- ���b�Z�[�W
  cv_msg_006a04_001    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00094'; -- �A�b�v���[�h�����o�̓��b�Z�[�W
  cv_msg_006a04_002    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_006a04_003    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00095'; -- �t�H�[�}�b�g�G���[
  cv_msg_006a04_004    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00096'; -- �����f�[�^�Ȃ��G���[
  cv_msg_006a04_005    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00097'; -- �����f�[�^�d���G���[
  cv_msg_006a04_006    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00098'; -- �����X�e�[�^�X�G���[
  cv_msg_006a04_007    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00099'; -- �����c���G���[
  cv_msg_006a04_008    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00100'; -- �x�����@�Z�L�����e�B�G���[
  cv_msg_006a04_009    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00101'; -- �����ԍ��d���G���[
  cv_msg_006a04_010    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00102'; -- �����ԍ����݂Ȃ��G���[
  cv_msg_006a04_011    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00103'; -- �������z�G���[
  cv_msg_006a04_012    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00104'; -- API�G���[���b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_msg_006a04_013    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00138'; -- �����ςݕ����ԍ��G���[
  cv_msg_006a04_014    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00139'; -- �t�@�C���t�H�[�}�b�g�G���[
  cv_msg_006a04_015    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00140'; -- ��臒l�`�F�b�N�G���[(���)
  cv_msg_006a04_016    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00141'; -- ��臒l�`�F�b�N�G���[(����)
  cv_msg_006a04_017    CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- �e�[�u�����b�N�G���[
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  -- ���{�ꎫ���Q�ƃR�[�h
  cv_dict_cfr_00604001  CONSTANT VARCHAR2(20) := 'CFR006A04001'; -- �����e�[�u��
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  -- �g�[�N��
  cv_tkn_006a04_001_1  CONSTANT VARCHAR2(30) := 'FILE_NAME';             -- �A�b�v���[�h�t�@�C����
  cv_tkn_006a04_001_2  CONSTANT VARCHAR2(30) := 'CSV_NAME';              -- CSV�t�@�C����
  cv_tkn_006a04_002_1  CONSTANT VARCHAR2(30) := 'PROF_NAME';             -- �v���t�@�C����
  cv_tkn_006a04_003_1  CONSTANT VARCHAR2(30) := 'ROW_COUNT';             -- �s��
  cv_tkn_006a04_003_2  CONSTANT VARCHAR2(30) := 'DATA_INFO';             -- �l
  cv_tkn_006a04_003_3  CONSTANT VARCHAR2(30) := 'INFO';                  -- �G���[���b�Z�[�W
  cv_tkn_006a04_004_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_004_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- �ڋq�R�[�h
  cv_tkn_006a04_004_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- ������
  cv_tkn_006a04_005_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_005_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- �ڋq�R�[�h
  cv_tkn_006a04_005_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- ������
  cv_tkn_006a04_006_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_006_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- �ڋq�R�[�h
  cv_tkn_006a04_006_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- ������
  cv_tkn_006a04_006_4  CONSTANT VARCHAR2(30) := 'STATUS';                -- �X�e�[�^�X
  cv_tkn_006a04_007_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_007_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- �ڋq�R�[�h
  cv_tkn_006a04_007_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- ������
  cv_tkn_006a04_007_4  CONSTANT VARCHAR2(30) := 'CASH_AMOUNT';           -- �����c�z
  cv_tkn_006a04_007_5  CONSTANT VARCHAR2(30) := 'TRX_AMOUNT_ALL';        -- �������z���v
  cv_tkn_006a04_008_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_008_2  CONSTANT VARCHAR2(30) := 'ACCOUNT_NUMBER';        -- �ڋq�R�[�h
  cv_tkn_006a04_008_3  CONSTANT VARCHAR2(30) := 'RECEIPT_DATE';          -- ������
  cv_tkn_006a04_009_1  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- �����ԍ�
  cv_tkn_006a04_010_1  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- �����ԍ�
  cv_tkn_006a04_011_1  CONSTANT VARCHAR2(30) := 'TRX_NUMBER';            -- ����ԍ�
  cv_tkn_006a04_011_2  CONSTANT VARCHAR2(30) := 'AMOUNT_DUE_REMAINING';  -- ������c��
  cv_tkn_006a04_011_3  CONSTANT VARCHAR2(30) := 'TRX_AMOUNT';            -- �������z
  cv_tkn_006a04_012_1  CONSTANT VARCHAR2(30) := 'TRX_NUMBER';            -- ����ԍ�
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  cv_tkn_006a04_012_2  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_013_1  CONSTANT VARCHAR2(30) := 'RECEIPT_NUMBER';        -- �����ԍ�
  cv_tkn_006a04_013_2  CONSTANT VARCHAR2(30) := 'DOC_SEQUENCE_VALUE';    -- �����ԍ�
  cv_tkn_006a04_014_1  CONSTANT VARCHAR2(30) := 'FILE_FORMAT';           -- �t�@�C���t�H�[�}�b�g
  cv_tkn_006a04_017_1  CONSTANT VARCHAR2(30) := 'TABLE';                 -- �e�[�u����
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  cv_tkn_val_006a04_001_1  CONSTANT VARCHAR2(30) := 'APP_XXCFR1_30001';  -- �A�b�v���[�h�t�@�C����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE ttype_work_table         IS TABLE OF xxcfr_apply_upload_work%ROWTYPE
                                   INDEX BY PLS_INTEGER;
--
  TYPE ttype_receipt_number     IS TABLE OF xxcfr_apply_upload_work.receipt_number%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_account_number     IS TABLE OF xxcfr_apply_upload_work.account_number%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_receipt_date       IS TABLE OF xxcfr_apply_upload_work.receipt_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_apply_date         IS TABLE OF xxcfr_apply_upload_work.apply_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_apply_gl_date      IS TABLE OF xxcfr_apply_upload_work.apply_gl_date%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_doc_sequence_value IS TABLE OF xxcfr_apply_upload_work.doc_sequence_value%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_trx_amount         IS TABLE OF xxcfr_apply_upload_work.trx_amount%TYPE
                                   INDEX BY PLS_INTEGER;
  TYPE ttype_comments           IS TABLE OF xxcfr_apply_upload_work.comments%TYPE
                                   INDEX BY PLS_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gn_set_of_bks_id    gl_sets_of_books.set_of_books_id%TYPE;         -- ��v����ID
  gn_file_id          xxccp_mrp_file_ul_interface.file_id%TYPE;      -- �t�@�C��ID
  gn_trx_amount_sum   xxcfr_apply_upload_work.trx_amount%TYPE;       -- �A�b�v���[�h������c�����z
  gn_cash_receipt_id  xxcfr_apply_upload_work.cash_receipt_id%TYPE;  -- ��������ID
  gv_receipt_number   xxcfr_apply_upload_work.receipt_number%TYPE;   -- �����ԍ�
  gv_account_number   xxcfr_apply_upload_work.account_number%TYPE;   -- �ڋq�R�[�h
  gd_receipt_date     xxcfr_apply_upload_work.receipt_date%TYPE;     -- ������
  gv_receipt_date     VARCHAR2(10);                                  -- ������(����)
  gd_receipt_gl_date  ar_cash_receipt_history_all.gl_date%TYPE;      -- ����GL�L����
  gd_min_open_date    gl_period_statuses.start_date%TYPE;            -- �ŏ��I�[�v����
  gb_flag             BOOLEAN := FALSE;  -- �Ɩ��`�F�b�N�p�t���O(�`�F�b�N�ɊY�������TRUE�ƂȂ�G���[�I��)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  gn_normal_trx_amount_sum  xxcfr_apply_upload_work.trx_amount%TYPE;  -- �����ϋ��z���z
  gn_error_trx_amount_sum   xxcfr_apply_upload_work.trx_amount%TYPE;  -- ���������z���z
  gv_threshold_type         fnd_lookup_values.attribute1%TYPE;        -- 臒l�敪
  gn_upl_limit_of_count     NUMBER;                                   -- �A�b�v���[�h�p�Ώی���臒l
  gb_warn_flag              BOOLEAN := FALSE;                         -- �x���I���t���O
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_format IN         VARCHAR2     -- 2.�t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_lookup_ulobj CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ'; -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
    cv_lookup_ulfmt CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_UPLOAD_FORMAT'; -- ���������A�b�v���[�h�E�t�@�C���t�H�[�}�b�g
--
    cv_y            CONSTANT VARCHAR2(1)                        := 'Y';
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- *** ���[�J���ϐ� ***
    lv_file_name  xxccp_mrp_file_ul_interface.file_name%TYPE;  -- �G���[�E���b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    lv_format_name  fnd_lookup_values.meaning%TYPE;            -- �t�@�C���t�H�[�}�b�g��
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END  ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_log               -- ���O�o��
      ,iv_conc_param1  => TO_CHAR(gn_file_id)  -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_file_format       -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_out               -- OUT�t�@�C���o��
      ,iv_conc_param1  => TO_CHAR(gn_file_id)  -- �R���J�����g�p�����[�^�P
      ,iv_conc_param2  => iv_file_format       -- �R���J�����g�p�����[�^�Q
      ,ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --CSV�t�@�C�����̎擾
    --==============================================================
    -- �A�b�v���[�hCSV�t�@�C�����擾
    SELECT file_name                          -- CSV�t�@�C����
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmfui  -- ���ʃe�[�u��
    WHERE  xmfui.file_id = gn_file_id         -- �t�@�C��ID
    ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --==============================================================
    --�t�@�C���t�H�[�}�b�g���̎擾
    --==============================================================
    BEGIN
      -- �A�b�v���[�h�t�@�C���t�H�[�}�b�g���擾
      SELECT flv1.meaning     AS meaning                 -- �t�@�C���t�H�[�}�b�g��
            ,flv2.attribute1  AS attribute1              -- 臒l�敪
      INTO   lv_format_name
            ,gv_threshold_type
      FROM   fnd_lookup_values flv1                      -- �Q�ƃ^�C�v�}�X�^1
            ,fnd_lookup_values flv2                      -- �Q�ƃ^�C�v�}�X�^2
      WHERE  flv1.lookup_type  = cv_lookup_ulobj         -- �Q�ƃ^�C�v(�t�@�C���A�b�v���[�h�I�u�W�F�N�g)
      AND    flv1.lookup_code  = iv_file_format          -- �Q�ƃR�[�h(�t�@�C���t�H�[�}�b�g)
      AND    flv1.enabled_flag = cv_y                    -- �L���t���O
      AND    flv1.language     = USERENV('LANG')         -- ����(JA)
      AND    ( flv1.start_date_active <= TRUNC(SYSDATE)  -- �E�v�J�n��
            OR flv1.start_date_active IS NULL
             )
      AND    ( flv1.end_date_active   >= TRUNC(SYSDATE)  -- �E�v�I����
            OR flv1.end_date_active   IS NULL
             )
      AND    flv2.lookup_type  = cv_lookup_ulfmt         -- �Q�ƃ^�C�v(���������A�b�v���[�h�E�t�@�C���t�H�[�}�b�g)
      AND    flv2.lookup_code  = flv1.lookup_code        -- �Q�ƃR�[�h
      AND    flv2.enabled_flag = cv_y                    -- �L���t���O
      AND    flv2.language     = USERENV('LANG')         -- ����(JA)
      AND    ( flv2.start_date_active <= TRUNC(SYSDATE)  -- �E�v�J�n��
            OR flv2.start_date_active IS NULL
             )
      AND    ( flv2.end_date_active   >= TRUNC(SYSDATE)  -- �E�v�I����
            OR flv2.end_date_active   IS NULL
             )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                      ,iv_name         => cv_msg_006a04_014    -- �t�@�C���t�H�[�}�b�g�G���[
                                                      ,iv_token_name1  => cv_tkn_006a04_014_1  -- �g�[�N��'�t�@�C���t�H�[�}�b�g'
                                                      ,iv_token_value1 => iv_file_format
                             )
                            ,1
                            ,5000
        );
        RAISE global_api_expt;
    END;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- �A�b�v���[�hCSV�t�@�C�����o��(�o�̓t�@�C��)
    FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                     ,buff  => xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                 ,iv_name         => cv_msg_006a04_001        -- �A�b�v���[�h�����o�̓��b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                                 ,iv_token_name1  => cv_tkn_006a04_001_2      --�uCSV_NAME�v
--                                 ,iv_token_value1 => lv_file_name             -- CSV�t�@�C����
                                 ,iv_token_name1  => cv_tkn_006a04_001_1      --�uFILE_NAME�v
                                 ,iv_token_value1 => lv_format_name           -- �A�b�v���[�h�t�@�C����
                                 ,iv_token_name2  => cv_tkn_006a04_001_2      --�uCSV_NAME�v
                                 ,iv_token_value2 => lv_file_name             -- CSV�t�@�C����
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                                )
    );
    -- �A�b�v���[�hCSV�t�@�C�����o��(���O�t�@�C��)
    FND_FILE.PUT_LINE(which => FND_FILE.LOG
                     ,buff  => xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                 ,iv_name         => cv_msg_006a04_001        -- �A�b�v���[�h�����o�̓��b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                                 ,iv_token_name1  => cv_tkn_006a04_001_2      --�uCSV_NAME�v
--                                 ,iv_token_value1 => lv_file_name             -- CSV�t�@�C����
                                 ,iv_token_name1  => cv_tkn_006a04_001_1      --�uFILE_NAME�v
                                 ,iv_token_value1 => lv_format_name           -- �A�b�v���[�h�t�@�C����
                                 ,iv_token_name2  => cv_tkn_006a04_001_2      --�uCSV_NAME�v
                                 ,iv_token_value2 => lv_file_name             -- CSV�t�@�C����
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                               )
    );
--
    --==============================================================
    --��v����ID�̎擾
    --==============================================================
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                    ,iv_name         => cv_msg_006a04_002    -- �v���t�@�C���擾�G���[
                                                    ,iv_token_name1  => cv_tkn_006a04_002_1  -- �g�[�N��'PROF_NAME'
                                                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id)
                           )
                          ,1
                          ,5000
      );
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�J�����_�I�[�v�����t�̍ŏ��l�̎擾
    --==============================================================
    SELECT MIN(gps.start_date)                                -- �ŏ��I�[�v����
    INTO   gd_min_open_date
    FROM   gl_period_statuses         gps                     -- ��v���ԃX�e�[�^�X�e�[�u��
          ,fnd_application            fap                     -- �A�v���P�[�V�����Ǘ��}�X�^
    WHERE  gps.application_id         = fap.application_id    -- �A�v���P�[�V����ID
    AND    gps.set_of_books_id        = gn_set_of_bks_id      -- ��v����ID
    AND    fap.application_short_name = cv_appl_name_ar       -- �A�v���P�[�V�����Z�k��('AR')
    AND    gps.closing_status         = cv_closing_status_o   -- �X�e�[�^�X(�I�[�v��)
    ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --==============================================================
    --�A�b�v���[�h�p�Ώی���臒l�̎擾
    --==============================================================
    -- �v���t�@�C������A�b�v���[�h�p�Ώی���臒l�擾
    gn_upl_limit_of_count := TO_NUMBER(FND_PROFILE.VALUE(cv_upl_limit_of_count));
    -- �擾�G���[��
    IF (gn_upl_limit_of_count IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                    ,iv_name         => cv_msg_006a04_002    -- �v���t�@�C���擾�G���[
                                                    ,iv_token_name1  => cv_tkn_006a04_002_1  -- �g�[�N��'PROF_NAME'
                                                    ,iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_upl_limit_of_count)
                           )
                          ,1
                          ,5000
      );
      RAISE global_api_expt;
    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END proc_init;
--
  /***********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ot_file_data_tbl OUT NOCOPY xxccp_common_pkg2.g_file_data_tbl  -- �t�@�C���A�b�v���[�h�f�[�^�i�[�z��
   ,ov_errbuf        OUT NOCOPY VARCHAR2                           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT NOCOPY VARCHAR2                           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT NOCOPY VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    ot_file_data_tbl.DELETE;
--
--###########################  �Œ蕔 END  ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --���ʃA�b�v���[�h�f�[�^�ϊ�����
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gn_file_id        -- �t�@�C��ID
      ,ov_file_data => ot_file_data_tbl  -- �ϊ���VARCHAR2�f�[�^
      ,ov_retcode   => lv_retcode        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errbuf    => lv_errbuf         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
--#####################################  �Œ蕔 END  ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : devide_item
   * Description      : �f���~�^�������ڕ���(A-3)
   ***********************************************************************************/
  PROCEDURE devide_item(
    iv_file_data  IN         VARCHAR2          -- �t�@�C���f�[�^
   ,in_count      IN         PLS_INTEGER       -- �J�E���^(�s��)
   ,ov_flag       OUT NOCOPY VARCHAR2          -- �f�[�^�敪
   ,or_work_table OUT NOCOPY xxcfr_apply_upload_work%ROWTYPE  -- �����������[�N���R�[�h
   ,ov_errbuf     OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'devide_item'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_look_type   CONSTANT VARCHAR2(100)  := 'XXCFR1_APPLY_UPLOAD';  -- LOOKUP TYPE
    cv_csv_delim   CONSTANT VARCHAR2(1)    := ',';                    -- CSV��؂蕶��
    cv_duble_quo   CONSTANT VARCHAR2(1)    := '"';                    -- �_�u���N�I�e�[�V����
    cv_1           CONSTANT VARCHAR2(1)    := '1';  -- �A�b�v���[�h�Ώ�
    cv_2           CONSTANT VARCHAR2(1)    := '2';  -- �A�b�v���[�h�ΏۊO(�_�~�[�l)
--
    -- *** ���[�J���ϐ� ***
    lv_item        VARCHAR2(5000);   -- ���ڈꎞ�i�[�p
    lb_warn_flag   BOOLEAN;          -- �t���O
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR item_check_cur
    IS
    SELECT flv.lookup_code           AS lookup_code  -- �Q�ƃ^�C�v�R�[�h
          ,TO_NUMBER(flv.meaning)    AS index_num    -- �C���f�b�N�X(����)
          ,flv.description           AS item_name    -- ���ږ���
          ,TO_NUMBER(flv.attribute1) AS item_len     -- ���ڒ�
          ,TO_NUMBER(flv.attribute2) AS item_dec     -- ���ڒ�(�����_�ȉ�)
          ,flv.attribute3            AS item_null    -- NULL��
          ,flv.attribute4            AS item_type    -- ���ڑ���
    FROM   fnd_lookup_values_vl flv                  -- �Q�ƃ^�C�v�r���[
    WHERE  lookup_type = cv_look_type                -- �Q�ƃ^�C�v
    ORDER BY flv.lookup_code                         -- �Q�ƃR�[�h��
    ;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE ttype_item_check IS TABLE OF item_check_cur%ROWTYPE
                             INDEX BY PLS_INTEGER;
--
    lt_item_check   ttype_item_check;
    lr_work_table   xxcfr_apply_upload_work%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    ov_flag       := NULL;
    or_work_table := NULL;
--
    lr_work_table := NULL;
--
--###########################  �Œ蕔 END  ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN item_check_cur;
    FETCH item_check_cur BULK COLLECT INTO lt_item_check;
    CLOSE item_check_cur;
--
    <<item_check_loop>>
    FOR ln_count IN 1..lt_item_check.COUNT LOOP
--
      -- �f���~�^���������֐�
      lv_item := xxccp_common_pkg.char_delim_partition(
                    iv_char     => iv_file_data                       -- �t�@�C���f�[�^��
                   ,iv_delim    => cv_csv_delim                       -- �J���}
                   ,in_part_num => lt_item_check(ln_count).index_num  -- ����
                 );
--
--
      -- �͂ݕ����̃_�u���N�I�e�[�V�������폜����
      lv_item := LTRIM(lv_item,cv_duble_quo);  -- ����
      lv_item := RTRIM(lv_item,cv_duble_quo);  -- �E��
--
      -- �����t���O(���ԂP)�̏ꍇ�̓`�F�b�N���s��Ȃ�
      IF ( lt_item_check(ln_count).index_num <> 1 ) THEN
        -- =====================================================
        --  ���ڒ��A�K�{�A�f�[�^�^�G���[�`�F�b�N
        -- =====================================================
        xxccp_common_pkg2.upload_item_check(
           iv_item_name    => lt_item_check(ln_count).item_name -- ���ږ��́i���ڂ̓��{�ꖼ�j  -- �K�{
          ,iv_item_value   => lv_item                           -- ���ڂ̒l                    -- �C��
          ,in_item_len     => lt_item_check(ln_count).item_len  -- ���ڂ̒���                  -- �K�{
          ,in_item_decimal => lt_item_check(ln_count).item_dec  -- ���ڂ̒����i�����_�ȉ��j    -- �����t�K�{
          ,iv_item_nullflg => lt_item_check(ln_count).item_null -- �K�{�t���O�i��L�萔��ݒ�j-- �K�{
          ,iv_item_attr    => lt_item_check(ln_count).item_type -- ���ڑ����i��L�萔��ݒ�j  -- �K�{
          ,ov_errbuf       => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode      => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg       => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ); 
--
        IF    ( lv_retcode = cv_status_error ) THEN  -- �G���[
          RAISE global_api_expt;
        ELSIF ( lv_retcode = cv_status_warn  ) THEN  -- �x�����̓��b�Z�[�W�o��
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                                             ,iv_name         => cv_msg_006a04_003    -- �t�H�[�}�b�g�G���[
                                                             ,iv_token_name1  => cv_tkn_006a04_003_1  --�uROW_COUNT�v
                                                             ,iv_token_value1 => in_count             -- �s��
                                                             ,iv_token_name2  => cv_tkn_006a04_003_2  --�uDATA_INFO�v
                                                             ,iv_token_value2 => lv_item              -- ���ڂ̒l
                                                             ,iv_token_name3  => cv_tkn_006a04_003_3  --�uINFO�v
                                                             ,iv_token_value3 => lv_errmsg            -- ���ʊ֐��G���[���b�Z�[�W
                                     )
          );
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
      -- �`�F�b�N�ς݂̒l���i�[
      CASE lt_item_check(ln_count).lookup_code
        WHEN 1 THEN  -- �����t���O
--
          -- �R�����g�s
          IF ( NVL( lv_item , cv_2 ) <> cv_1 ) THEN
            ov_retcode := cv_status_warn;  -- �A�b�v���[�h�ΏۂƂ��Ȃ�
            ov_flag := TRIM(lv_item);
            EXIT;  -- �v���V�[�W���𔲂���
          END IF;
--
          ov_flag := TRIM(lv_item);
--
      ELSE
--
        NULL;
--
      END CASE;
--
      -- �`�F�b�N���ʂ�����ł���ꍇ
      IF NOT ( gb_flag ) THEN
--
        -- �`�F�b�N�ς݂̒l���i�[
        CASE lt_item_check(ln_count).lookup_code
          WHEN 2 THEN  -- ������
            lr_work_table.receipt_date       := TO_DATE(lv_item,cv_yyyy_mm_dd);
          WHEN 3 THEN  -- �����ԍ�
            lr_work_table.receipt_number     := lv_item;
          WHEN 4 THEN  -- �ڋq�R�[�h
            lr_work_table.account_number     := lv_item;
          WHEN 5 THEN  -- ��������
            lr_work_table.comments           := lv_item;
          WHEN 6 THEN  -- �����ԍ�
            lr_work_table.doc_sequence_value := lv_item;
          WHEN 7 THEN  -- �������z
            lr_work_table.trx_amount         := TO_NUMBER(lv_item);
            -- �������z���v
            IF ( gn_trx_amount_sum IS NULL ) THEN
              gn_trx_amount_sum              := lr_work_table.trx_amount;
            ELSE
              gn_trx_amount_sum              := gn_trx_amount_sum + lr_work_table.trx_amount;  
            END IF;
--
        ELSE
--
          NULL;
--
        END CASE;
--
      END IF;
--
    END LOOP item_check_loop;
--
    -- �A�E�g�p�����[�^�ɐݒ�
    or_work_table := lr_work_table;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
--
      IF ( item_check_cur%ISOPEN ) THEN
        CLOSE item_check_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END devide_item;
--
  /***********************************************************************************
   * Procedure Name   : insert_work
   * Description      : ���[�N�e�[�u���o�^����(A-4)
   ***********************************************************************************/
  PROCEDURE insert_work(
    it_receipt_number      IN        ttype_receipt_number      -- �����ԍ�
   ,it_account_number      IN        ttype_account_number      -- �ڋq�R�[�h
   ,it_receipt_date        IN        ttype_receipt_date        -- ������
   ,it_doc_sequence_value  IN        ttype_doc_sequence_value  -- �����ԍ�
   ,it_trx_amount          IN        ttype_trx_amount          -- �������z
   ,it_comments            IN        ttype_comments            -- ����
   ,ov_errbuf             OUT NOCOPY VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT NOCOPY VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT NOCOPY VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count   PLS_INTEGER;  -- �J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END  ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
     -- ���[�N�e�[�u���Ɉꊇ�o�^
     FORALL ln_count IN 1..it_receipt_number.COUNT
       INSERT INTO xxcfr_apply_upload_work(
                      file_id                 -- �t�@�C��ID
                     ,receipt_number          -- �����ԍ�
                     ,account_number          -- �ڋq�R�[�h
                     ,receipt_date            -- ������
                     ,doc_sequence_value      -- �����ԍ�
                     ,trx_amount              -- ������c��
                     ,comments                -- ����
                     ,apply_date              -- ������
                     ,apply_gl_date           -- ����GL�L����
                     ,cash_receipt_id         -- ��������ID
                     ,customer_trx_id         -- �������ID
                     ,trx_number              -- ����ԍ�
                     ,created_by              -- �쐬��
                     ,creation_date           -- �쐬��
                     ,last_updated_by         -- �ŏI�X�V��
                     ,last_update_date        -- �ŏI�X�V��
                     ,last_update_login       -- �ŏI�X�V���O�C��
                     ,request_id              -- �v��ID
                     ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                     ,program_id              -- �R���J�����g�E�v���O����ID
                     ,program_update_date     -- �v���O�����X�V��
                   )
            VALUES (gn_file_id                       -- �t�@�C��ID
                   ,it_receipt_number(ln_count)      -- �����ԍ�
                   ,it_account_number(ln_count)      -- �ڋq�R�[�h
                   ,it_receipt_date(ln_count)        -- ������
                   ,it_doc_sequence_value(ln_count)  -- �����ԍ�
                   ,it_trx_amount(ln_count)          -- ������c��
                   ,it_comments(ln_count)            -- ����
                   ,NULL                             -- ������
                   ,NULL                             -- ����GL�L����
                   ,NULL                             -- ��������ID
                   ,NULL                             -- �������ID
                   ,NULL                             -- ����ԍ�
                   ,cn_created_by                    -- �쐬��
                   ,cd_creation_date                 -- �쐬��
                   ,cn_last_updated_by               -- �ŏI�X�V��
                   ,cd_last_update_date              -- �ŏI�X�V��
                   ,cn_last_update_login             -- �ŏI�X�V���O�C��
                   ,cn_request_id                    -- �v��ID
                   ,cn_program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                   ,cn_program_id                    -- �R���J�����g�E�v���O����ID
                   ,cd_program_update_date           -- �v���O�����X�V��
                   )
       ;
--
    -- �Ώی������擾
    gn_target_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
--#####################################  �Œ蕔 END  ##########################################
--
  END insert_work;
--
  /***********************************************************************************
   * Procedure Name   : check_data
   * Description      : �Ó����`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf         OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- �v���O������
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
--
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_class_pmt      CONSTANT ar_payment_schedules_all.class%TYPE    := 'PMT';                      -- �N���X�F����
    cv_status_unapp   CONSTANT ar_cash_receipts_all.status%TYPE       := 'UNAPP';                    -- �X�e�[�^�X�F������
    cv_lookup_secu    CONSTANT fnd_lookup_values.lookup_type%TYPE     := 'XXCFR1_RECEIPT_SECURITY';  -- ALL��������
    cv_lookup_cash    CONSTANT fnd_lookup_values.lookup_type%TYPE     := 'CHECK_STATUS';             -- �����X�e�[�^�X
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_threshold_type_large  CONSTANT fnd_lookup_values.attribute1%TYPE := '1';                     -- 臒l�敪(���)
    cv_threshold_type_small  CONSTANT fnd_lookup_values.attribute1%TYPE := '0';                     -- 臒l�敪(����)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    cv_y              CONSTANT VARCHAR2(1)                            := 'Y';
--
    -- *** ���[�J���ϐ� ***
--
    ln_count         PLS_INTEGER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �������̈�Ӑ��`�F�b�N(�Ó����`�F�b�N)
    CURSOR  cash_unique_cur
    IS
      SELECT acr.cash_receipt_id           AS cash_receipt_id       -- ��������ID
            ,acrh.gl_date                  AS cash_gl_date          -- ����GL�L����
            ,acr.receipt_method_id         AS receipt_method_id     -- �x�����@����ID
            ,aps.amount_due_remaining * -1 AS cash_amount_remaining -- �����c�z
            ,acr.status                    AS cash_status           -- �X�e�[�^�X
            ,(SELECT flv.meaning  AS meaning
              FROM   fnd_lookup_values flv              -- �Q�ƃ^�C�v�}�X�^
              WHERE  flv.lookup_type = cv_lookup_cash   -- �Q�ƃ^�C�v(�����X�e�[�^�X)
              AND    flv.language    = USERENV('LANG')  -- ����
              AND    flv.lookup_code = acr.status       -- �Q�ƃR�[�h(�X�e�[�^�X)
             )                             AS cash_status_desc      -- �X�e�[�^�X�E�v
        FROM ar_cash_receipts          acr   -- ����
            ,ar_payment_schedules      aps   -- �x���v��
            ,hz_cust_accounts          hca   -- �ڋq�}�X�^
            ,ar_cash_receipt_history   acrh  -- ��������
       WHERE acr.cash_receipt_id = aps.cash_receipt_id     -- ��������ID
         AND acr.cash_receipt_id = acrh.cash_receipt_id    -- ��������ID
         AND hca.cust_account_id = acr.pay_from_customer   -- �ڋq����ID
         AND acr.receipt_number  = gv_receipt_number       -- �����ԍ�
         AND acr.receipt_date    = gd_receipt_date         -- ������
         AND hca.account_number  = gv_account_number       -- �ڋq�R�[�h
         AND aps.class           = cv_class_pmt            -- ����
         AND acrh.current_record_flag = cv_y               -- ���ݍs�t���O
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
         AND acr.status               = cv_status_unapp    -- �����X�e�[�^�X(UNAPP ������)
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
      ;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
    -- �������ȊO�̓������擾
    CURSOR  cash_not_unapp_data_cur
    IS
      SELECT acr.cash_receipt_id           AS cash_receipt_id       -- ��������ID
            ,acrh.gl_date                  AS cash_gl_date          -- ����GL�L����
            ,acr.receipt_method_id         AS receipt_method_id     -- �x�����@����ID
            ,aps.amount_due_remaining * -1 AS cash_amount_remaining -- �����c�z
            ,acr.status                    AS cash_status           -- �X�e�[�^�X
            ,(SELECT flv.meaning  AS meaning
              FROM   fnd_lookup_values flv              -- �Q�ƃ^�C�v�}�X�^
              WHERE  flv.lookup_type = cv_lookup_cash   -- �Q�ƃ^�C�v(�����X�e�[�^�X)
              AND    flv.language    = USERENV('LANG')  -- ����
              AND    flv.lookup_code = acr.status       -- �Q�ƃR�[�h(�X�e�[�^�X)
             )                             AS cash_status_desc      -- �X�e�[�^�X�E�v
        FROM ar_cash_receipts          acr   -- ����
            ,ar_payment_schedules      aps   -- �x���v��
            ,hz_cust_accounts          hca   -- �ڋq�}�X�^
            ,ar_cash_receipt_history   acrh  -- ��������
       WHERE acr.cash_receipt_id       =  aps.cash_receipt_id     -- ��������ID
         AND acr.cash_receipt_id       =  acrh.cash_receipt_id    -- ��������ID
         AND hca.cust_account_id       =  acr.pay_from_customer   -- �ڋq����ID
         AND acr.receipt_number        =  gv_receipt_number       -- �����ԍ�
         AND acr.receipt_date          =  gd_receipt_date         -- ������
         AND hca.account_number        =  gv_account_number       -- �ڋq�R�[�h
         AND aps.class                 =  cv_class_pmt            -- ����
         AND acrh.current_record_flag  =  cv_y                    -- ���ݍs�t���O
         AND acr.status               <>  cv_status_unapp         -- �����X�e�[�^�X(UNAPP ������ �ȊO)
      ;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
    -- �Z�L�����e�B�`�F�b�N
    CURSOR  receipt_method_cur(
              in_receipt_method_id  ar_receipt_methods.receipt_method_id%TYPE  -- �x�����@����ID
            )
    IS
      SELECT COUNT(ROWNUM)       AS cnt  -- �J�E���^
      FROM   xxcfr_dept_relate_v xdrv    -- �������_�y�ъǗ������_�r���[
      WHERE  ( EXISTS( SELECT NULL
                       FROM   ar_receipt_methods  arm                       -- �x�����@
                       WHERE  arm.receipt_method_id = in_receipt_method_id  -- �x�����@����ID
                       AND    arm.attribute1        = xdrv.dept_code        -- �x�����@���_ = �������_ or �Ǘ������_
               )
            OR EXISTS( SELECT NULL
                       FROM   fnd_lookup_values        flv                  -- �Q�ƃ^�C�v
                       WHERE  flv.lookup_type          = cv_lookup_secu     -- �Z�L�����e�B
                       AND    flv.enabled_flag         = cv_y 
                       AND    flv.language             = USERENV('LANG')    -- JA
                       AND    ( flv.start_date_active <= TRUNC(SYSDATE)     -- �J�n��
                             OR flv.start_date_active IS NULL
                              )
                       AND    ( flv.end_date_active   >= TRUNC(SYSDATE)     -- �I����
                             OR flv.end_date_active   IS NULL
                              )
                       AND    flv.lookup_code = xdrv.dept_code              -- �X�[�p�[���[�U�[ = �������_ or �Ǘ������_
               )
             )
      ;
--
    -- ������̈�Ӑ��`�F�b�N
    CURSOR  trx_unique_cur
    IS
      SELECT xauw.doc_sequence_value AS doc_sequence_value     -- �����ԍ�
        FROM xxcfr_apply_upload_work  xauw                     -- ���������A�b�v���[�h���[�N
       WHERE xauw.file_id    = gn_file_id                      -- �t�@�C��ID
         AND xauw.request_id = cn_request_id                   -- �v��ID
      GROUP BY xauw.doc_sequence_value
      HAVING   COUNT(ROWNUM) > 1                               -- �����ԍ�����ӂłȂ�����
      ;
--
    -- ������̑��݃`�F�b�N
    CURSOR check_trx_exist_cur
    IS
      SELECT  xauw.doc_sequence_value AS doc_sequence_value    -- �����ԍ�
      FROM    xxcfr_apply_upload_work xauw                     -- ���������A�b�v���[�h���[�N
      WHERE   xauw.file_id    = gn_file_id                     -- �t�@�C��ID
        AND   xauw.request_id = cn_request_id                  -- �v��ID
        AND   NOT EXISTS(SELECT NULL
                         FROM   ra_customer_trx  rct           -- ����e�[�u��
                         WHERE  xauw.doc_sequence_value = rct.doc_sequence_value  -- �����ԍ�
              )
     ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    -- �����ςݎ�����̑��݃`�F�b�N
    CURSOR  check_apply_trx_cur(
              in_cash_receipt_id  ar_cash_receipts.cash_receipt_id%TYPE  -- ����ID
            )
    IS
      SELECT  xauw.doc_sequence_value AS doc_sequence_value          -- �����ԍ�
      FROM    xxcfr_apply_upload_work        xauw                    -- ���������A�b�v���[�h���[�N
             ,ra_customer_trx                rct                     -- ����e�[�u��
             ,ar_receivable_applications_all araa                    -- �����e�[�u��
      WHERE   xauw.file_id                 = gn_file_id              -- �t�@�C��ID
        AND   xauw.request_id              = cn_request_id           -- �v��ID
        AND   xauw.doc_sequence_value      = rct.doc_sequence_value  -- �����ԍ�
        AND   araa.applied_customer_trx_id = rct.customer_trx_id     -- ���ID
        AND   araa.display                 = cv_y                    -- �\���t���O
        AND   araa.cash_receipt_id         = in_cash_receipt_id      -- ����ID
     ;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- *** ���[�J���E���R�[�h ***
--
    TYPE ttype_cash_unique     IS TABLE OF cash_unique_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_cash_unique             ttype_cash_unique;
--
    TYPE ttype_receipt_method  IS TABLE OF receipt_method_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_receipt_method          ttype_receipt_method;
--
    TYPE ttype_trx_unique      IS TABLE OF trx_unique_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_trx_unique              ttype_trx_unique;
--
    TYPE ttype_check_trx_exist  IS TABLE OF check_trx_exist_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_check_trx_exist          ttype_check_trx_exist;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--
    TYPE ttype_cash_not_unapp   IS TABLE OF cash_not_unapp_data_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_cash_not_unapp           ttype_cash_not_unapp;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
--
    TYPE ttype_check_apply_trx  IS TABLE OF check_apply_trx_cur%ROWTYPE
                                  INDEX BY PLS_INTEGER;
    lt_check_apply_trx          ttype_check_apply_trx;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
------------
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����ԍ����`�F�b�N����(DB��A�����ԍ��A�ڋq�A�������ň�ӂƂȂ邩)
    BEGIN
--
-- ************ 2010/09/02 1.1 M.Watanabe DEL START ************ --
--      OPEN cash_unique_cur;
--      FETCH cash_unique_cur BULK COLLECT INTO lt_cash_unique;
--      CLOSE cash_unique_cur;
----
--      IF ( lt_cash_unique.COUNT < 1 ) THEN -- �Ώۂ̓��������݂��Ȃ��ꍇ(�G���[)
----
--        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                         ,buff  => xxccp_common_pkg.get_msg(
--                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                    ,iv_name         => cv_msg_006a04_004    -- �����f�[�^�Ȃ��G���[
--                                    ,iv_token_name1  => cv_tkn_006a04_004_1  --�uRECEIPT_NUMBER�v
--                                    ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
--                                    ,iv_token_name2  => cv_tkn_006a04_004_2  --�uACCOUNT_NUMBER�v
--                                    ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
--                                    ,iv_token_name3  => cv_tkn_006a04_004_3  --�uRECEIPT_DATE�v
--                                    ,iv_token_value3 => gv_receipt_date      -- ������
--                                    )
--        );
----
--        gb_flag := TRUE;
----
--      ELSIF( lt_cash_unique.COUNT > 1 ) THEN  -- �Ώۂ̓������������݂���ꍇ(�G���[)
----
--        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                         ,buff  => xxccp_common_pkg.get_msg(
--                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                    ,iv_name         => cv_msg_006a04_005    -- �����f�[�^�d���G���[
--                                    ,iv_token_name1  => cv_tkn_006a04_005_1  --�uRECEIPT_NUMBER�v
--                                    ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
--                                    ,iv_token_name2  => cv_tkn_006a04_005_2  --�uACCOUNT_NUMBER�v
--                                    ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
--                                    ,iv_token_name3  => cv_tkn_006a04_005_3  --�uRECEIPT_DATE�v
--                                    ,iv_token_value3 => gv_receipt_date      -- ������
--                                    )
--        );
----
--        gb_flag := TRUE;
----
--      ELSE
----
--        -- �����X�e�[�^�X���������ȊO�̏ꍇ�̓G���[
--        IF ( lt_cash_unique(1).cash_status = cv_status_unapp ) THEN
----
--          -- �A�b�v���[�h������c���̑��z�ȏ�ɓ����c�z���Ȃ��ꍇ�̓G���[
--          IF ( lt_cash_unique(1).cash_amount_remaining >= gn_trx_amount_sum ) THEN
----
--            gn_cash_receipt_id := lt_cash_unique(1).cash_receipt_id;  -- ��������ID���O���[�o����
--            gd_receipt_gl_date := lt_cash_unique(1).cash_gl_date;     -- ����GL�L�������O���[�o����
----
--          ELSE
----
--            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                             ,buff  => xxccp_common_pkg.get_msg(
--                                         iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                        ,iv_name         => cv_msg_006a04_007    -- �����c���G���[
--                                        ,iv_token_name1  => cv_tkn_006a04_007_1  --�uRECEIPT_NUMBER�v
--                                        ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
--                                        ,iv_token_name2  => cv_tkn_006a04_007_2  --�uACCOUNT_NUMBER�v
--                                        ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
--                                        ,iv_token_name3  => cv_tkn_006a04_007_3  --�uRECEIPT_DATE�v
--                                        ,iv_token_value3 => gv_receipt_date      -- ������
--                                        ,iv_token_name4  => cv_tkn_006a04_007_4  --�uCASH_AMOUNT�v
--                                        ,iv_token_value4 => lt_cash_unique(1).cash_amount_remaining  -- �����c�z
--                                        ,iv_token_name5  => cv_tkn_006a04_007_5  --�uTRX_AMOUNT_ALL�v
--                                        ,iv_token_value5 => gn_trx_amount_sum    -- �������z���v
--                                        )
--            );
--            gb_flag := TRUE;
----
--          END IF;
----
--        ELSE
----
--          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
--                           ,buff  => xxccp_common_pkg.get_msg(
--                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
--                                      ,iv_name         => cv_msg_006a04_006    -- �����X�e�[�^�X�G���[
--                                      ,iv_token_name1  => cv_tkn_006a04_006_1  -- RECEIPT_NUMBER�v
--                                      ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
--                                      ,iv_token_name2  => cv_tkn_006a04_006_2  --�uACCOUNT_NUMBER�v
--                                      ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
--                                      ,iv_token_name3  => cv_tkn_006a04_006_3  --�uRECEIPT_DATE�v
--                                      ,iv_token_value3 => gv_receipt_date      -- ������
--                                      ,iv_token_name4  => cv_tkn_006a04_006_4  --�uSTATUS�v
--                                      ,iv_token_value4 => lt_cash_unique(1).cash_status_desc  -- �X�e�[�^�X�E�v
--                                     )
--          );
----
--          gb_flag := TRUE;
----
--        END IF;
----
--      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe DEL END   ************ --
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--
      -- �����X�e�[�^�X�� UNAPP(������) �̓��������擾����
      OPEN cash_unique_cur;
      FETCH cash_unique_cur BULK COLLECT INTO lt_cash_unique;
      CLOSE cash_unique_cur;
--
      --===================================================================
      -- �����X�e�[�^�X�� UNAPP(������) �̓������ 2���ȏ� ���݂���ꍇ
      --===================================================================
      IF ( lt_cash_unique.COUNT > 1 ) THEN
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_005    -- �����f�[�^�d���G���[
                                    ,iv_token_name1  => cv_tkn_006a04_005_1  --�uRECEIPT_NUMBER�v
                                    ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                                    ,iv_token_name2  => cv_tkn_006a04_005_2  --�uACCOUNT_NUMBER�v
                                    ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
                                    ,iv_token_name3  => cv_tkn_006a04_005_3  --�uRECEIPT_DATE�v
                                    ,iv_token_value3 => gv_receipt_date      -- ������
                                    )
        );
--
        gb_flag := TRUE;
--
      END IF;
--
      --===================================================================
      -- �����X�e�[�^�X�� UNAPP(������) �̓������ �[���� �̏ꍇ
      --===================================================================
      IF ( lt_cash_unique.COUNT = 0 ) THEN
--
        -- �����X�e�[�^�X�� UNAPP(������) �ȊO �̓��������擾����
        OPEN cash_not_unapp_data_cur;
        FETCH cash_not_unapp_data_cur BULK COLLECT INTO lt_cash_not_unapp;
        CLOSE cash_not_unapp_data_cur;
--
        --========================================================================
        -- �����X�e�[�^�X�� UNAPP(������) �ȊO �̓������ �[���� �̏ꍇ
        --========================================================================
        IF ( lt_cash_not_unapp.COUNT = 0 ) THEN
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_004    -- �����f�[�^�Ȃ��G���[
                                      ,iv_token_name1  => cv_tkn_006a04_004_1  --�uRECEIPT_NUMBER�v
                                      ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                                      ,iv_token_name2  => cv_tkn_006a04_004_2  --�uACCOUNT_NUMBER�v
                                      ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
                                      ,iv_token_name3  => cv_tkn_006a04_004_3  --�uRECEIPT_DATE�v
                                      ,iv_token_value3 => gv_receipt_date      -- ������
                                      )
          );
--
          gb_flag := TRUE;
        --========================================================================
        -- �����X�e�[�^�X�� UNAPP(������) �ȊO �̓������ 1���ȏ� ���݂���ꍇ
        --========================================================================
        ELSE
--
          <<cash_err_msg_loop>>
          FOR ln_cnt  IN  1 .. lt_cash_not_unapp.COUNT LOOP
--
            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                             ,buff  => xxccp_common_pkg.get_msg(
                                         iv_application  => cv_appl_name_cfr                            -- 'XXCFR'
                                        ,iv_name         => cv_msg_006a04_006                           -- �����X�e�[�^�X�G���[
                                        ,iv_token_name1  => cv_tkn_006a04_006_1                         -- RECEIPT_NUMBER�v
                                        ,iv_token_value1 => gv_receipt_number                           -- �����ԍ�
                                        ,iv_token_name2  => cv_tkn_006a04_006_2                         --�uACCOUNT_NUMBER�v
                                        ,iv_token_value2 => gv_account_number                           -- �ڋq�R�[�h
                                        ,iv_token_name3  => cv_tkn_006a04_006_3                         --�uRECEIPT_DATE�v
                                        ,iv_token_value3 => gv_receipt_date                             -- ������
                                        ,iv_token_name4  => cv_tkn_006a04_006_4                         --�uSTATUS�v
                                        ,iv_token_value4 => lt_cash_not_unapp(ln_cnt).cash_status_desc  -- �X�e�[�^�X�E�v
                                       )
            );
--
          END LOOP cash_err_msg_loop;
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
      --===================================================================
      -- �����X�e�[�^�X�� UNAPP(������) �̓������ 1�� �̏ꍇ
      --===================================================================
      IF ( lt_cash_unique.COUNT = 1 ) THEN
--
        --===================================================================
        -- �����̖������c���Ə������z�̍��v�`�F�b�N
        -- �����̖������c�� < �������z���v �̏ꍇ�� �����c���G���[
        --===================================================================
        IF ( lt_cash_unique(1).cash_amount_remaining >= gn_trx_amount_sum ) THEN
--
          gn_cash_receipt_id := lt_cash_unique(1).cash_receipt_id;  -- ��������ID���O���[�o����
          gd_receipt_gl_date := lt_cash_unique(1).cash_gl_date;     -- ����GL�L�������O���[�o����
--
        ELSE
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_007    -- �����c���G���[
                                      ,iv_token_name1  => cv_tkn_006a04_007_1  --�uRECEIPT_NUMBER�v
                                      ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                                      ,iv_token_name2  => cv_tkn_006a04_007_2  --�uACCOUNT_NUMBER�v
                                      ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
                                      ,iv_token_name3  => cv_tkn_006a04_007_3  --�uRECEIPT_DATE�v
                                      ,iv_token_value3 => gv_receipt_date      -- ������
                                      ,iv_token_name4  => cv_tkn_006a04_007_4  --�uCASH_AMOUNT�v
                                      ,iv_token_value4 => lt_cash_unique(1).cash_amount_remaining  -- �����c�z
                                      ,iv_token_name5  => cv_tkn_006a04_007_5  --�uTRX_AMOUNT_ALL�v
                                      ,iv_token_value5 => gn_trx_amount_sum    -- �������z���v
                                      )
          );
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- �x�����@���`�F�b�N����(�Z�L�����e�B)
    BEGIN
--
      OPEN receipt_method_cur(
             lt_cash_unique(1).receipt_method_id  -- �x�����@����ID
           );
      FETCH receipt_method_cur BULK COLLECT INTO lt_receipt_method;
      CLOSE receipt_method_cur;
--
      IF ( lt_receipt_method(1).cnt < 1 ) THEN
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_008    -- �x�����@�Z�L�����e�B�G���[
                                    ,iv_token_name1  => cv_tkn_006a04_008_1  --�uRECEIPT_NUMBER�v
                                    ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                                    ,iv_token_name2  => cv_tkn_006a04_008_2  --�uACCOUNT_NUMBER�v
                                    ,iv_token_value2 => gv_account_number    -- �ڋq�R�[�h
                                    ,iv_token_name3  => cv_tkn_006a04_008_3  --�uRECEIPT_DATE�v
                                    ,iv_token_value3 => gv_receipt_date      -- ������
                                   )
        );
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- ����ԍ����`�F�b�N����(�t�@�C�����ŏd�����Ă��Ȃ���)
    BEGIN
--
      OPEN trx_unique_cur;
      FETCH trx_unique_cur BULK COLLECT INTO lt_trx_unique;
      CLOSE trx_unique_cur;
--
      IF   ( lt_trx_unique.COUNT > 0 ) THEN
--
        <<err_msg_loop>>
        FOR ln_count IN 1..lt_trx_unique.COUNT LOOP
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_009    -- �����ԍ��d���G���[
                                      ,iv_token_name1  => cv_tkn_006a04_009_1  --�uDOC_SEQUENCE_VALUE�v
                                      ,iv_token_value1 => lt_trx_unique(ln_count).doc_sequence_value  -- �����ԍ�
                                     )
          );
--
        END LOOP err_msg_loop;
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
--  �A�b�v���[�h�Ώۂ̕����ԍ�������Ƃ��đ��݂��Ă��邩���`�F�b�N����B
    BEGIN
--
      OPEN check_trx_exist_cur;
      FETCH check_trx_exist_cur BULK COLLECT INTO lt_check_trx_exist;
      CLOSE check_trx_exist_cur;
--
      -- ����ɑ��݂��Ȃ������ԍ��̏ꍇ�G���[
      IF ( lt_check_trx_exist.COUNT > 0 ) THEN
--
        <<error_msg_loop>>
        FOR ln_count IN 1..lt_check_trx_exist.COUNT LOOP
--
          FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                           ,buff  => xxccp_common_pkg.get_msg(
                                       iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                      ,iv_name         => cv_msg_006a04_010    -- �����ԍ����݂Ȃ��G���[
                                      ,iv_token_name1  => cv_tkn_006a04_010_1  --�uDOC_SEQUENCE_VALUE�v
                                      ,iv_token_value1 => lt_check_trx_exist(ln_count).doc_sequence_value --�����ԍ�
                                     )
          );
--
        END LOOP err_msg_loop;
--
        gb_flag := TRUE;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    -- �����ςݎ�����̑��݂��`�F�b�N����
    BEGIN
--
      IF ( lt_cash_unique.COUNT > 0 ) THEN
--
        OPEN check_apply_trx_cur(
               lt_cash_unique(1).cash_receipt_id  -- ����ID
             );
        FETCH check_apply_trx_cur BULK COLLECT INTO lt_check_apply_trx;
        CLOSE check_apply_trx_cur;
--
        -- �����ςݎ�������݂��镶���ԍ��̏ꍇ�G���[
        IF ( lt_check_apply_trx.COUNT > 0 ) THEN
--
          <<error_msg_loop>>
          FOR ln_count IN 1..lt_check_apply_trx.COUNT LOOP
--
            FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                             ,buff  => xxccp_common_pkg.get_msg(
                                         iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                        ,iv_name         => cv_msg_006a04_013    -- �����ςݕ����ԍ��G���[
                                        ,iv_token_name1  => cv_tkn_006a04_013_1  --�uRECEIPT_NUMBER�v
                                        ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                                        ,iv_token_name2  => cv_tkn_006a04_013_2  --�uDOC_SEQUENCE_VALUE�v
                                        ,iv_token_value2 => lt_check_apply_trx(ln_count).doc_sequence_value -- �����ԍ�
                                       )
            );
--
          END LOOP err_msg_loop;
--
          gb_flag := TRUE;
--
        END IF;
--
      END IF;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        gb_flag := TRUE;
--
    END;
--
    -- ����̏ꍇ�̏����Ώی����ƃA�b�v���[�h�p�Ώی���臒l���r����
    IF (  ( gv_threshold_type = cv_threshold_type_large )  -- 臒l�敪�����
      AND ( gn_target_cnt < gn_upl_limit_of_count ) )      -- �����Ώی��� �� �A�b�v���[�h�p�Ώی���臒l
      THEN
      FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                       ,buff  => xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                  ,iv_name         => cv_msg_006a04_015    -- ��臒l�`�F�b�N�G���[(���)
                                  )
      );
--
      gb_flag := TRUE;
--
    END IF;
--
    -- �����̏ꍇ�̏����Ώی����ƃA�b�v���[�h�p�Ώی���臒l���r����
    IF (  ( gv_threshold_type = cv_threshold_type_small )  -- 臒l�敪������
      AND ( gn_target_cnt >= gn_upl_limit_of_count ) )     -- �����Ώی��� �� �A�b�v���[�h�p�Ώی���臒l
      THEN
      FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                       ,buff  => xxccp_common_pkg.get_msg(
                                   iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                  ,iv_name         => cv_msg_006a04_016    -- ��臒l�`�F�b�N�G���[(����)
                                  )
      );
--
      gb_flag := TRUE;
--
    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
      IF ( cash_unique_cur%ISOPEN ) THEN
        CLOSE cash_unique_cur;
      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
      IF ( cash_not_unapp_data_cur%ISOPEN ) THEN
        CLOSE cash_not_unapp_data_cur;
      END IF;
-- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
      IF ( receipt_method_cur%ISOPEN ) THEN
        CLOSE receipt_method_cur;
      END IF;
      IF ( trx_unique_cur%ISOPEN ) THEN
        CLOSE trx_unique_cur;
      END IF;
      IF ( check_trx_exist_cur%ISOPEN ) THEN
        CLOSE check_trx_exist_cur;
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
      IF ( check_apply_trx_cur%ISOPEN ) THEN
        CLOSE check_apply_trx_cur;
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_trx_data
   * Description      : ������擾(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_trx_data(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx_data'; -- �v���O������
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
    cv_status_o          gl_period_statuses.closing_status%TYPE          := 'O';    -- �X�e�[�^�X(�I�[�v��)
    cv_class_inv         ar_payment_schedules_all.class%TYPE             := 'INV';  -- �N���X(���)
    cv_class_cm          ar_payment_schedules_all.class%TYPE             := 'CM';   -- �N���X(�N���W�b�g����)
    cv_account_class_rec ra_cust_trx_line_gl_dist_all.account_class%TYPE := 'REC';  -- ����N���X(���|/������)
    cv_flag_y            ra_customer_trx_all.complete_flag%TYPE          := 'Y';    -- �����t���O(����)
    -- *** ���[�J���ϐ� ***
--
    ln_count        PLS_INTEGER := 0;      -- �J�E���^
    lb_check_flag   BOOLEAN     := FALSE;  -- �������z�G���[�`�F�b�N�t���O
    ld_date         DATE        := NULL;   -- ��������SYSDATE���r���A�傫�������i�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR get_trx_id_cur
    IS
      SELECT /*+ LEADING( xauw rct )
                 USE_NL( xauw rct aps rctl gps fap )
             */
              xauw.rowid                      AS row_id                -- ROWID
             ,rct.customer_trx_id             AS customer_trx_id       -- �������ID
             ,rct.trx_number                  AS trx_number            -- ����ԍ�
             ,xauw.doc_sequence_value         AS doc_sequence_value    -- �����ԍ�
             ,xauw.trx_amount                 AS trx_amount            -- �������z
             ,aps.amount_due_remaining        AS amount_due_remaining  -- ������c��
             ,aps.status                      AS stauts                -- �X�e�[�^�X
             ,DECODE(SIGN(rct.trx_date - ld_date)
                    , -1 , ld_date
                    ,  1 , rct.trx_date
                    ,  0 , rct.trx_date
              )                               AS apply_date            -- ������
             ,DECODE( gps.closing_status
                    , cv_status_o , DECODE(SIGN(rctl.gl_date - gd_receipt_gl_date)
                                           , -1 , gd_receipt_gl_date
                                           ,  1 , rctl.gl_date
                                           ,  0 , rctl.gl_date
                                    )
                    ,  DECODE(SIGN(gd_min_open_date - gd_receipt_gl_date)
                              , -1 , gd_receipt_gl_date
                              ,  1 , gd_min_open_date
                              ,  0 , gd_min_open_date
                              )
              )                               AS apply_gl_date         -- ����GL�L����
      FROM    xxcfr_apply_upload_work     xauw                         -- ���������A�b�v���[�h���[�N
             ,ra_customer_trx             rct                          -- ����e�[�u��
             ,ar_payment_schedules        aps                          -- �x���v��e�[�u��
             ,ra_cust_trx_line_gl_dist    rctl                         -- ����z���e�[�u��
             ,gl_period_statuses          gps                          -- �J�����_
             ,fnd_application             fap                          -- �A�v���P�[�V����
      WHERE   rct.customer_trx_id        = aps.customer_trx_id         -- �������ID
        AND   xauw.doc_sequence_value    = rct.doc_sequence_value      -- �����ԍ�
        AND   rct.customer_trx_id        = rctl.customer_trx_id        -- �������ID
        AND   gps.application_id         = fap.application_id          -- ����ID
        AND   rctl.gl_date         BETWEEN gps.start_date              -- �J�n��
                                       AND gps.end_date                -- �I����
        AND   gps.set_of_books_id        = gn_set_of_bks_id            -- ��v����ID
        AND   fap.application_short_name = cv_appl_name_ar             -- �W��AR
        AND   rct.complete_flag          = cv_flag_y                   -- �����t���O
        AND   xauw.file_id               = gn_file_id                  -- �t�@�C��ID
        AND   xauw.request_id            = cn_request_id               -- �v��ID
        AND   rctl.account_class         = cv_account_class_rec        -- �����^���|����
        AND   aps.class                IN (cv_class_inv                -- ���
                                          ,cv_class_cm                 -- �N���W�b�g����
                                       )
     ;
--
    -- *** ���[�J���E���R�[�h ***
--
    TYPE ttype_row_id               IS TABLE OF rowid
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_customer_trx_id      IS TABLE OF ra_customer_trx.customer_trx_id%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_trx_number           IS TABLE OF ra_customer_trx.trx_number%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_doc_sequence_value   IS TABLE OF xxcfr_apply_upload_work.doc_sequence_value%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_trx_amount           IS TABLE OF xxcfr_apply_upload_work.trx_amount%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_amount_due_remaining IS TABLE OF ar_payment_schedules_all.amount_due_remaining%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_status               IS TABLE OF ar_payment_schedules_all.status%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_apply_date           IS TABLE OF xxcfr_apply_upload_work.apply_date%TYPE
                                       INDEX BY PLS_INTEGER;
    TYPE ttype_apply_gl_date        IS TABLE OF xxcfr_apply_upload_work.apply_gl_date%TYPE
                                       INDEX BY PLS_INTEGER;
--
    lt_row_id                 ttype_row_id;
    lt_customer_trx_id        ttype_customer_trx_id;
    lt_trx_number             ttype_trx_number;
    lt_doc_sequence_value     ttype_doc_sequence_value;
    lt_trx_amount             ttype_trx_amount;
    lt_amount_due_remaining   ttype_amount_due_remaining;
    lt_status                 ttype_status;
    lt_apply_date             ttype_apply_date;
    lt_apply_gl_date          ttype_apply_gl_date;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    lt_row_id.DELETE;
    lt_customer_trx_id.DELETE;
    lt_trx_number.DELETE;
    lt_doc_sequence_value.DELETE;
    lt_trx_amount.DELETE;
    lt_amount_due_remaining.DELETE;
    lt_status.DELETE;
    lt_apply_date.DELETE;
    lt_apply_gl_date.DELETE;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ��������SYSDATE���r���A�傫������ϐ��Ɋi�[����
    IF (gd_receipt_date < SYSDATE) THEN
      ld_date := SYSDATE;
    ELSE
      ld_date := gd_receipt_date;
    END IF;
--
    OPEN get_trx_id_cur;
--
    FETCH get_trx_id_cur BULK COLLECT INTO lt_row_id                -- ROWID
                                          ,lt_customer_trx_id       -- �������ID
                                          ,lt_trx_number            -- ����ԍ�
                                          ,lt_doc_sequence_value    -- �����ԍ�
                                          ,lt_trx_amount            -- �������z
                                          ,lt_amount_due_remaining  -- ������c��
                                          ,lt_status                -- �X�e�[�^�X
                                          ,lt_apply_date            -- ������
                                          ,lt_apply_gl_date         -- ����GL�L����
    ;
--
    CLOSE get_trx_id_cur;
--
    <<error_msg_loop>>
    FOR ln_count IN 1..lt_row_id.COUNT LOOP
--
      -- �@������c���ƇA�������z(�A�b�v���[�h)���قȂ�Ƃ��̓G���[���b�Z�[�W���o�͂��A�G���[�I���Ƃ���B
      -- �P�[�X1�F�@ 10,000 �A 10,500  �� �c���ȏ�̏���
      -- �P�[�X2�F�@ 10,000 �A-   100  �� ������c����������
      -- �P�[�X3�F�@-10,000 �A-10,500  �� �c���ȏ�̏���
      -- �P�[�X4�F�@-10,000 �A    100  �� ������c����������
      IF (  ( SIGN(lt_amount_due_remaining(ln_count))  = SIGN(lt_trx_amount(ln_count)) )  -- �����������ł���
        AND (  ABS(lt_amount_due_remaining(ln_count)) >=  ABS(lt_trx_amount(ln_count)) )  -- ������c���̕����傫��
      ) THEN
--
        NULL;  -- ���Ȃ��̂ŉ������Ȃ��B
--
      ELSE
--
        -- ������c���Ə������z���������Ă��܂��B
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => xxccp_common_pkg.get_msg(
                                     iv_application  => cv_appl_name_cfr         -- 'XXCFR'
                                    ,iv_name         => cv_msg_006a04_011        -- �������z�G���[
                                    ,iv_token_name1  => cv_tkn_006a04_011_1      --�uTRX_NUMBER�v
                                    ,iv_token_value1 => lt_trx_number(ln_count)  -- ����ԍ�
-- ************ 2010/09/02 1.1 M.Watanabe MOD START ************ --
--                                    ,iv_token_name2  => cv_tkn_006a04_011_2      --�uAMOUNT_DUE_REMAINING�v
--                                    ,iv_token_value2 => lt_amount_due_remaining(ln_count)  -- ������c�z
--                                    ,iv_token_name3  => cv_tkn_006a04_011_3      --�uTRX_AMOUNT�v
--                                    ,iv_token_value3 => lt_trx_amount(ln_count)  -- �������z
                                    ,iv_token_name2  => cv_tkn_006a04_010_1               --�uDOC_SEQUENCE_VALUE�v
                                    ,iv_token_value2 => lt_doc_sequence_value(ln_count)   -- �����ԍ�
                                    ,iv_token_name3  => cv_tkn_006a04_011_2               --�uAMOUNT_DUE_REMAINING�v
                                    ,iv_token_value3 => lt_amount_due_remaining(ln_count) -- ������c�z
                                    ,iv_token_name4  => cv_tkn_006a04_011_3               --�uTRX_AMOUNT�v
                                    ,iv_token_value4 => lt_trx_amount(ln_count)           -- �������z
-- ************ 2010/09/02 1.1 M.Watanabe MOD END   ************ --
                                   )
        );
--
        gb_flag := TRUE;
        lb_check_flag := TRUE;
--
      END IF;
--
    END LOOP error_msg_loop;
--
    -- �Ɩ��`�F�b�N�G���[�������͍X�V�����͍s��Ȃ�
    IF NOT( lb_check_flag ) THEN
--
      FORALL ln_count IN 1..lt_row_id.COUNT
  --
        UPDATE xxcfr_apply_upload_work  xauw  -- ���������A�b�v���[�h���[�N
           SET xauw.customer_trx_id     = lt_customer_trx_id(ln_count)  -- �������ID
              ,xauw.trx_number          = lt_trx_number(ln_count)       -- ����ԍ�
              ,xauw.apply_date          = lt_apply_date(ln_count)       -- ������
              ,xauw.apply_gl_date       = lt_apply_gl_date(ln_count)    -- ����GL�L����
         WHERE xauw.rowid = lt_row_id(ln_count)  -- ROWID
        ;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
      IF ( get_trx_id_cur%ISOPEN ) THEN
        CLOSE get_trx_id_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END get_cust_trx_data;
--
  /***********************************************************************************
   * Procedure Name   : get_cash_rec_data
   * Description      : �������擾(A-7)
   ***********************************************************************************/
  PROCEDURE get_cash_rec_data(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_rec_data'; -- �v���O������
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
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    UPDATE xxcfr_apply_upload_work  xauw              -- ���������A�b�v���[�h���[�N
       SET xauw.cash_receipt_id = gn_cash_receipt_id  -- ��������ID
     WHERE xauw.file_id         = gn_file_id          -- �t�@�C��ID
       AND xauw.request_id      = cn_request_id       -- �v��ID
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
--#####################################  �Œ蕔 END  ##########################################
--
  END get_cash_rec_data;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_data_lock
   * Description      : �������r���`�F�b�N(A-10)
   ***********************************************************************************/
  PROCEDURE check_data_lock(
    ov_errbuf     OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data_lock'; -- �v���O������
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
    CURSOR lock_cash_receipt_cur
    IS
      SELECT  xauw.receipt_number  AS receipt_number         -- �����ԍ�
      FROM    xxcfr_apply_upload_work   xauw                 -- ���������A�b�v���[�h���[�N
             ,ar_cash_receipts_all      acra                 -- �����e�[�u��
             ,ar_payment_schedules_all  apsa                 -- �x���v��e�[�u��
      WHERE   xauw.request_id      = cn_request_id           -- �v��ID
        AND   xauw.cash_receipt_id = acra.cash_receipt_id    -- ��������ID
        AND   (xauw.cash_receipt_id = apsa.cash_receipt_id   -- ��������ID
          OR   xauw.customer_trx_id = apsa.customer_trx_id)  -- �������ID
        FOR UPDATE OF acra.cash_receipt_id                   -- ���b�N�ΏہF�����e�[�u��
                     ,apsa.payment_schedule_id               -- ���b�N�ΏہF�x���v��e�[�u��
                      NOWAIT
     ;
--
    -- *** ���[�J���E���R�[�h ***
--
    lock_cash_receipt_rec  lock_cash_receipt_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ���b�N���擾����B
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN lock_cash_receipt_cur;
--
      -- �f�[�^�̎擾
      FETCH lock_cash_receipt_cur INTO lock_cash_receipt_rec;
--
      -- �J�[�\���N���[�Y
      CLOSE lock_cash_receipt_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
--
        IF ( lock_cash_receipt_cur%ISOPEN ) THEN
          CLOSE lock_cash_receipt_cur;
        END IF;
--
        FND_FILE.PUT_LINE(which => FND_FILE.OUTPUT
                         ,buff  => SUBSTRB(xxccp_common_pkg.get_msg(
                                             iv_application  => cv_appl_name_cfr     -- 'XXCFR'
                                            ,iv_name         => cv_msg_006a04_017    -- �e�[�u�����b�N�G���[
                                            ,iv_token_name1  => cv_tkn_006a04_017_1  -- �g�[�N��'PROF_NAME'
                                            ,iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                  cv_appl_name_cfr
                                                                 ,cv_dict_cfr_00604001
                                                                 )
                                          )
                                         ,1
                                         ,5000
                                   )
        );
--
        gb_flag := TRUE;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
      IF ( lock_cash_receipt_cur%ISOPEN ) THEN
        CLOSE lock_cash_receipt_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END check_data_lock;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
  /***********************************************************************************
   * Procedure Name   : ecxec_apply_api
   * Description      : ��������API�N������ (A-8)
   ***********************************************************************************/
  PROCEDURE ecxec_apply_api(
    ov_errbuf     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ) 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ecxec_apply_api'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START  ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status   VARCHAR2(1);    -- �W��API�߂�l(�X�e�[�^�X)
    ln_msg_count       NUMBER;         -- �W��API�߂�l(�Ώی���)
    lv_msg_data        VARCHAR2(2000); -- �W��API�߂�l(���b�Z�[�W)
--
    ln_count           PLS_INTEGER;    -- �J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR get_work_table_cur
    IS
      SELECT   xauw.receipt_number      AS receipt_number      -- �����ԍ�
              ,xauw.account_number      AS account_number      -- �ڋq�R�[�h
              ,xauw.receipt_date        AS receipt_date        -- ������
              ,xauw.apply_date          AS apply_date          -- ������
              ,xauw.apply_gl_date       AS apply_gl_date       -- ����GL�L����
              ,xauw.doc_sequence_value  AS doc_sequence_value  -- �����ԍ�
              ,xauw.cash_receipt_id     AS cash_receipt_id     -- ��������ID
              ,xauw.customer_trx_id     AS customer_trx_id     -- �������ID
              ,xauw.trx_number          AS trx_number          -- ����ԍ�
              ,xauw.trx_amount          AS trx_amount          -- �������z
              ,xauw.comments            AS comments            -- ����
      FROM     xxcfr_apply_upload_work xauw     -- ���������A�b�v���[�h���[�h���[�N
      WHERE    xauw.file_id    = gn_file_id     -- �t�@�C��ID
        AND    xauw.request_id = cn_request_id  -- �v��ID
      ORDER BY xauw.trx_amount ASC              -- ������c���̏���(�}�C�i�X�z�����������)
-- 2014/02/13 Ver.1.3 T.Nakano ADD Start
              ,xauw.doc_sequence_value ASC      -- �����ԍ��̏���(�A�b�v���[�h�V�[�g�ƍ��킹�邽��)
-- 2014/02/13 Ver.1.3 T.Nakano ADD End
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    TYPE ttype_get_work_table IS TABLE OF get_work_table_cur%ROWTYPE
                             INDEX BY PLS_INTEGER;
    lt_get_work_table   ttype_get_work_table;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--
--###########################  �Œ蕔 END  ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN get_work_table_cur;
--
    FETCH get_work_table_cur BULK COLLECT INTO lt_get_work_table;
--
    CLOSE get_work_table_cur;
--
    <<exe_api_loop>>
    FOR ln_count IN 1..lt_get_work_table.COUNT LOOP
--
      -- ��������API�N��
      ar_receipt_api_pub.apply(
         p_api_version     =>  1.0                 -- �o�[�W����
        ,p_init_msg_list   =>  FND_API.G_TRUE
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
        ,p_commit          =>  FND_API.G_FALSE
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
        ,x_return_status   =>  lv_return_status    -- �X�e�[�^�X
        ,x_msg_count       =>  ln_msg_count        -- �Ώی���
        ,x_msg_data        =>  lv_msg_data         -- ���b�Z�[�W
        ,p_customer_trx_id =>  lt_get_work_table(ln_count).customer_trx_id  -- ����w�b�_ID
        ,p_cash_receipt_id =>  lt_get_work_table(ln_count).cash_receipt_id  -- ����ID
        ,p_amount_applied  =>  lt_get_work_table(ln_count).trx_amount       -- �������z
        ,p_apply_date      =>  lt_get_work_table(ln_count).apply_date       -- ������
        ,p_apply_gl_date   =>  lt_get_work_table(ln_count).apply_gl_date    -- ����GL�L����
        ,p_comments        =>  lt_get_work_table(ln_count).comments         -- ����
        );
--
      IF (lv_return_status <> 'S') THEN
        --�G���[����
        lv_errmsg := SUBSTRB(
                        xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_cfr      -- 'XXCFR'
                          ,iv_name         => cv_msg_006a04_012     -- API�G���[���b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--                          ,iv_token_name1  => cv_tkn_006a04_012_1   --�uTRX_NUMBER�v
--                          ,iv_token_value1 => lt_get_work_table(ln_count).trx_number  -- ����ԍ�
---- ************ 2010/09/02 1.1 M.Watanabe ADD START ************ --
--                          ,iv_token_name2  => cv_tkn_006a04_010_1                             --�uDOC_SEQUENCE_VALUE�v
--                          ,iv_token_value2 => lt_get_work_table(ln_count).doc_sequence_value  -- �����ԍ�
---- ************ 2010/09/02 1.1 M.Watanabe ADD END   ************ --
                          ,iv_token_name1  => cv_tkn_006a04_012_2  --�uRECEIPT_NUMBER�v
                          ,iv_token_value1 => gv_receipt_number    -- �����ԍ�
                          ,iv_token_name2  => cv_tkn_006a04_010_1                             --�uDOC_SEQUENCE_VALUE�v
                          ,iv_token_value2 => lt_get_work_table(ln_count).doc_sequence_value  -- �����ԍ�
                          ,iv_token_name3  => cv_tkn_006a04_012_1                     --�uTRX_NUMBER�v
                          ,iv_token_value3 => lt_get_work_table(ln_count).trx_number  -- �������ԍ�(����ԍ�)
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
                        )
                       ,1
                       ,5000
                     );
--
        -- ��������API�G���[���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        -- API�W���G���[���b�Z�[�W���P���̏ꍇ
        IF (ln_msg_count = 1) THEN
--
          FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--             which  => FND_FILE.OUTPUT
             which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
            ,buff   => '�E' || lv_msg_data
          );
--
        -- API�W���G���[���b�Z�[�W���������̏ꍇ
        ELSE
--
          FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--             which  => FND_FILE.OUTPUT
             which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
            ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
--
          ln_msg_count := ln_msg_count - 1;
--
          <<while_loop>>
          WHILE ln_msg_count > 0 LOOP
--
            FND_FILE.PUT_LINE(
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--               which  => FND_FILE.OUTPUT
               which  => FND_FILE.LOG
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
              ,buff   => '�E' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                           ,1
                                           ,5000
                                         )
            );
--
            ln_msg_count := ln_msg_count - 1;
--
          END LOOP while_loop;
--
        END IF;
--
        gb_flag := TRUE;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
        gb_warn_flag := TRUE;
--
        -- �G���[�Ȃ�΃��[���o�b�N
        ROLLBACK;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
        EXIT;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--      END IF;  -- 'S'�ȊO
      ELSE
        -- ����Ȃ�΃R�~�b�g
        COMMIT;
--
        gn_normal_cnt := gn_normal_cnt + 1;
--
        gn_normal_trx_amount_sum := gn_normal_trx_amount_sum + lt_get_work_table(ln_count).trx_amount;
--
      END IF;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    END LOOP exe_api_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ####################################
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
      IF ( get_work_table_cur%ISOPEN ) THEN
        CLOSE get_work_table_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  ##########################################
--
  END ecxec_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : �I������(A-9)
   **********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf     OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START  ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_end'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START  ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
--###########################  �Œ蕔 END  ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL Start
--    -- ����I�����̓��[�N�e�[�u�������폜(�ُ펞�̓��[���o�b�N�����)
--    IF NOT( gb_flag ) THEN
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL End
--
      -- ���[�N�e�[�u���폜
      DELETE FROM  xxcfr_apply_upload_work  xauw
      WHERE xauw.file_id    = gn_file_id
      AND   xauw.request_id = cn_request_id
      ;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL Start
--    END IF;
----
--    -- �ُ�I�����͓�������API��߂��ׂ�ROLLBACK���s
--    IF ( gb_flag ) THEN
--      ROLLBACK;
--    END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa DEL End
    -- �t�@�C���A�b�v���[�hIF�e�[�u���폜
    DELETE FROM  xxccp_mrp_file_ul_interface  xmfui
    WHERE xmfui.file_id = gn_file_id
    ;
--
    -- �ُ�I�����̓t�@�C���A�b�v���[�hIF�e�[�u���폜�̂��߂�COMMIT���s
    IF ( gb_flag ) THEN
      COMMIT;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ###################################
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
--####################################  �Œ蕔 END  ##########################################
--
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_format IN         VARCHAR2    -- �t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START  ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END  ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
   cv_1           CONSTANT VARCHAR2(1)    := '1';  -- �A�b�v���[�h�Ώ�
   cv_2           CONSTANT VARCHAR2(1)    := '2';  -- �_�~�[�l
--
    -- *** ���[�J���ϐ� ***
-- �ϐ�
    ln_count               PLS_INTEGER;  -- �J�E���^
    ln_target_count        PLS_INTEGER;  -- �J�E���^(�Ώی���)
    lv_comment_flag        VARCHAR2(1);
    ln_customer_trx_id     ra_customer_trx_all.customer_trx_id%TYPE;   -- �������ID
    ln_cash_receipt_id     ar_cash_receipts_all.cash_receipt_id%TYPE;  -- ��������ID
-- �e�[�u��
    lt_file_data_tbl       xxccp_common_pkg2.g_file_data_tbl;          -- �t�@�C���A�b�v���[�h�f�[�^�i�[�z��
--
    lt_receipt_number      ttype_receipt_number;      -- �����ԍ�
    lt_account_number      ttype_account_number;      -- �ڋq�R�[�h
    lt_receipt_date        ttype_receipt_date;        -- ������
    lt_doc_sequence_value  ttype_doc_sequence_value;  -- �����ԍ�
    lt_trx_amount          ttype_trx_amount;          -- �������z
    lt_comments            ttype_comments;            -- ����
-- ���R�[�h
    lr_work_rtype          xxcfr_apply_upload_work%ROWTYPE; -- �����������[�N���R�[�h
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
--
    lt_file_data_tbl.DELETE;
    lt_receipt_number.DELETE;      -- �����ԍ�
    lt_account_number.DELETE;      -- �ڋq�R�[�h
    lt_receipt_date.DELETE;        -- ������
    lt_doc_sequence_value.DELETE;  -- �����ԍ�
    lt_trx_amount.DELETE;          -- �������z
    lt_comments.DELETE;            -- ����
--
    lr_work_rtype := NULL;
--
    ln_target_count    := 0;
    lv_comment_flag    := NULL;
    ln_customer_trx_id := NULL;
    ln_cash_receipt_id := NULL;
--
--###########################  �Œ蕔 END   ############################
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
--
    -- ���ʏ��������̌Ăяo��
    proc_init(
       iv_file_format => iv_file_format  -- �t�@�C���t�H�[�}�b�g
      ,ov_retcode     => lv_retcode      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errbuf      => lv_errbuf       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
    -- =====================================================
    get_if_data(
       ot_file_data_tbl => lt_file_data_tbl -- �t�@�C���A�b�v���[�h�f�[�^�i�[�z��
      ,ov_retcode       => lv_retcode       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errbuf        => lv_errbuf        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      gn_target_cnt := gn_target_cnt + 1;
      gb_flag := TRUE;
      RAISE global_process_expt;
    END IF;
--
    --�z��Ɋi�[����Ă���CSV�s��1�s�Â擾����
    <<main_loop>>
    FOR ln_count IN 1..lt_file_data_tbl.COUNT LOOP
--
      gn_target_cnt := gn_target_cnt + 1;   --���������J�E���g
--
      -- =====================================================
      --  �f���~�^�������ڕ���(A-3)
      -- =====================================================
      devide_item(
         iv_file_data  => lt_file_data_tbl(ln_count)  -- �t�@�C���f�[�^
        ,in_count      => ln_count
        ,ov_flag       => lv_comment_flag              -- �f�[�^�敪(�R�����g�s����p)
        ,or_work_table => lr_work_rtype                -- �����������[�N���R�[�h
        ,ov_retcode    => lv_retcode                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_errbuf     => lv_errbuf                    -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �R�����g�s(�����t���O���P�łȂ�)�̍��ڃG���[�̓X�L�b�v
      IF ( lv_retcode = cv_status_warn ) THEN
--
        -- �R�����g�s�͏����Ώی������J�E���g�_�E������
        IF ( NVL( lv_comment_flag , cv_2 ) <> cv_1 ) THEN
          gn_target_cnt := gn_target_cnt - 1;
        END IF;
--
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSE
        -- �J�E���g�A�b�v
        ln_target_count := ln_target_count + 1;
--
        -- ����f�[�^��z��Ɋi�[
        lt_receipt_date(ln_target_count)       := lr_work_rtype.receipt_date;        -- ������
        lt_receipt_number(ln_target_count)     := lr_work_rtype.receipt_number;      -- �����ԍ�
        lt_account_number(ln_target_count)     := lr_work_rtype.account_number;      -- �ڋq�R�[�h
        lt_comments(ln_target_count)           := lr_work_rtype.comments;            -- ��������
        lt_doc_sequence_value(ln_target_count) := lr_work_rtype.doc_sequence_value;  -- �����ԍ�
        lt_trx_amount(ln_target_count)         := lr_work_rtype.trx_amount;          -- �������z
--
      END IF;
--
    END LOOP main_loop;
--
    -- �f���~�^�������ڕ���(A-3)�G���[�̎��͏I������(A-9)���s��
    IF ( gb_flag = FALSE ) THEN
--
      -- =====================================================
      --  ���[�N�e�[�u���o�^(A-4)
      -- =====================================================
      insert_work(
         it_receipt_number      => lt_receipt_number      -- �����ԍ�
        ,it_account_number      => lt_account_number      -- �ڋq�R�[�h
        ,it_receipt_date        => lt_receipt_date        -- ������
        ,it_doc_sequence_value  => lt_doc_sequence_value  -- �����ԍ�
        ,it_trx_amount          => lt_trx_amount          -- �������z
        ,it_comments            => lt_comments            -- ����
        ,ov_retcode             => lv_retcode             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_errbuf              => lv_errbuf              -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���������O���[�o���ϐ��Ɋi�[
      gv_receipt_number := lt_receipt_number(1);  -- �����ԍ�
      gv_account_number := lt_account_number(1);  -- �ڋq�R�[�h
      gd_receipt_date   := lt_receipt_date(1);    -- ������
      gv_receipt_date   := TO_CHAR(lt_receipt_date(1)
                                  ,cv_yyyy_mm_dd
                           );                     -- ������(������)
--
      -- �J��
      lt_receipt_number.DELETE;      -- �����ԍ�
      lt_account_number.DELETE;      -- �ڋq�R�[�h
      lt_receipt_date.DELETE;        -- ������
      lt_doc_sequence_value.DELETE;  -- �����ԍ�
      lt_trx_amount.DELETE;          -- �������z
      lt_comments.DELETE;            -- ����
--
      -- =====================================================
      --  �Ó����`�F�b�N(A-5)
      -- =====================================================
      check_data(
         ov_retcode    => lv_retcode     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_errbuf     => lv_errbuf      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ������ݒ�(A-6)
      -- =====================================================
      get_cust_trx_data(
         ov_retcode    => lv_retcode     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_errbuf     => lv_errbuf      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  �������ݒ�(A-7)
      -- =====================================================
      get_cash_rec_data(
         ov_retcode    => lv_retcode     -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_errbuf     => lv_errbuf      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
      -- �Ɩ��`�F�b�N(A-5�`A-7)�G���[���͓������r���`�F�b�N(A-10)�͍s��Ȃ�
      IF ( gb_flag = FALSE ) THEN
--
        -- =====================================================
        --  �������r���`�F�b�N(A-10)
        -- =====================================================
        check_data_lock(
           ov_retcode    => lv_retcode     -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_errbuf     => lv_errbuf      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- �������r���`�F�b�N(A-10)�G���[���͓�������API�N������(A-8)�͍s��Ȃ�
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
      -- �Ɩ��`�F�b�N(A-5�`A-7)�G���[���͓�������API�N������(A-8)�͍s��Ȃ�
      IF ( gb_flag = FALSE ) THEN
--
        -- =====================================================
        --  ��������API�N������(A-8)
        -- =====================================================
        ecxec_apply_api(
           ov_retcode    => lv_retcode       -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_errbuf     => lv_errbuf        -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    -- =====================================================
    --  �I������(A-9)
    -- =====================================================
    proc_end(
       ov_retcode    => lv_retcode       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errbuf     => lv_errbuf        -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ###################################
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
--####################################  �Œ蕔 END  ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT NOCOPY   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_file_id     IN  VARCHAR2,            --   1.�t�@�C��ID
    iv_file_format IN  VARCHAR2             --   2.�t�@�C���t�H�[�}�b�g
  )
--
--
--###########################  �Œ蕔 START  ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
--    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
--    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_app_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00136'; -- �����ό������z���b�Z�[�W
    cv_unapp_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00137'; -- �������������z���b�Z�[�W
    cv_app_process_no_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00142'; -- ��������No���b�Z�[�W
    cv_rec_header_msg  CONSTANT VARCHAR2(100) := 'APP-XXCFR1-00143'; -- �������ʃw�b�_���b�Z�[�W
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    cv_amt_token       CONSTANT VARCHAR2(10)  := 'AMOUNT';           -- ���z���b�Z�[�W�p�g�[�N����
    cv_app_count_token    CONSTANT VARCHAR2(10)  := 'APP_COUNT';     -- ��������No���b�Z�[�W�p�g�[�N����(�����ό���)
    cv_unapp_count_token  CONSTANT VARCHAR2(11)  := 'UNAPP_COUNT';   -- ��������No���b�Z�[�W�p�g�[�N����(����������)
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
--###########################  �Œ蕔 END  ####################################
--
--
  BEGIN
--
--###########################  �Œ蕔 START  ###########################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    gn_normal_trx_amount_sum := 0;
    gn_error_trx_amount_sum  := 0;
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_out
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END  #############################
--
    -- �t�@�C��ID���O���[�o���ϐ��Ɋm��
    gn_file_id := TO_NUMBER(iv_file_id);
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_file_format => iv_file_format  -- 2.�t�@�C���t�H�[�}�b�g
      ,ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    -- �Ɩ��`�F�b�N�G���[�̎��́A�G���[�����������Ώی����Ɠ��l�ɂ���B(�S�������o���Ȃ������̈Ӗ�)
--    IF ( gb_flag ) THEN
--      gn_error_cnt := gn_target_cnt;
--    ELSE
--      gn_normal_cnt := gn_target_cnt;
--    END IF;
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
--
    gn_error_trx_amount_sum := gn_trx_amount_sum - gn_normal_trx_amount_sum;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    --�G���[���͊֐�����ԋp���ꂽ���b�Z�[�W���o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --�������ʃw�b�_�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_rec_header_msg
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    --���������o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_name_cmn
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
    --�����ό������z�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_app_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name2  => cv_amt_token
                    ,iv_token_value2 => TO_CHAR(gn_normal_trx_amount_sum)
                   );
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    --�G���[�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_name_cmn
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
    --�������������z���b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cfr
                    ,iv_name         => cv_unapp_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                    ,iv_token_name2  => cv_amt_token
                    ,iv_token_value2 => TO_CHAR(gn_error_trx_amount_sum)
                   );
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    lv_message_code := cv_normal_msg;
----
--    --�G���[������΁A�G���[�I���ɏ㏑��
--    IF ( gn_error_cnt > 0) THEN
--      lv_message_code := cv_error_msg;
--      retcode := cv_status_error;
--    END IF;
----
    IF ( gb_warn_flag ) THEN
      lv_retcode := cv_status_warn;
    ELSIF ( gb_flag ) THEN
      lv_retcode := cv_status_error;
    END IF;
--
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => lv_message_code
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD Start
    --�x���I���̏ꍇ
    IF ( lv_retcode = cv_status_warn ) THEN
      --�P�s���s
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
      --��������No���b�Z�[�W
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_cfr
                      ,iv_name         => cv_app_process_no_msg
                      ,iv_token_name1  => cv_app_count_token
                      ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                      ,iv_token_name2  => cv_unapp_count_token
                      ,iv_token_value2 => TO_CHAR(gn_error_cnt)
                     );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
  END IF;
--
-- 2011/08/11 Ver.1.2 A.Shirakawa ADD End
    --�X�e�[�^�X�Z�b�g
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD Start
--    errbuf := lv_errbuf;
    retcode := lv_retcode;
-- 2011/08/11 Ver.1.2 A.Shirakawa MOD End
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START  ###################################
--
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
--######################################  �Œ蕔 END  ########################################
--
END XXCFR006A04C;
/
