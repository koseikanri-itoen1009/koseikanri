CREATE OR REPLACE PACKAGE BODY XXCFR001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A01C(body)
 * Description      : AR������͂̌ڋq���X�V
 * MD.050           : MD050_CFR_001_A01_AR������͂̌ڋq���X�V
 * MD.070           : MD050_CFR_001_A01_AR������͂̌ڋq���X�V
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_process_date       p �Ɩ��������t�擾����                    (A-2)
 *  get_ar_interface_lines p �X�V�Ώ�AR ���OIF�e�[�u���擾          (A-3)
 *  get_convert_cust_code  p �Ǒ֐�����ڋq�擾                      (A-4)
 *  get_receipt_dept_code  p �������_�擾                            (A-5)
 *  update_ar_interface_lines p �Ώۃe�[�u���X�V                     (A-6)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.00 SCS ���� ��      ����쐬
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  dml_expt              EXCEPTION;      -- �c�l�k�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A01C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_001a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --�f�[�^���擾�ł��Ȃ�
  cv_msg_001a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --�f�[�^���b�N�G���[���b�Z�[�W
  cv_msg_001a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00055'; --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_001a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�擾�G���[���b�Z�[�W
--
-- �g�[�N��
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- �f�[�^
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- �R�����g
--
  -- �g�pDB��
  cv_table_ra_oif    CONSTANT VARCHAR2(100) := 'RA_INTERFACE_LINES_ALL'; -- ����I�[�v���C���^�[�t�F�[�X�e�[�u��
  cv_table_type      CONSTANT VARCHAR2(100) := 'RA_CUST_TRX_TYPES_ALL';  -- ����^�C�v�}�X�^
  cv_table_xca       CONSTANT VARCHAR2(100) := 'XXCMM_CUST_ACCOUNTS';    -- �ڋq�ǉ����e�[�u��
--
  cv_col_rec_b_cd    CONSTANT VARCHAR2(100) := 'RECEIPT_BASE_CODE';      -- �������_
  cv_col_cust_id     CONSTANT VARCHAR2(100) := 'CUSTOMER_ID';            -- �ڋq�h�c
--
  -- ���{�ꎫ��
  cv_dict_rila       CONSTANT VARCHAR2(100) := 'CFR001A01001';    -- AR�������OIF
--
  -- ���s�R�[�h
  cv_cr              CONSTANT VARCHAR2(1) := CHR(10);      -- ���s�R�[�h
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- �L���t���O�i�x�j
--
  cv_ship_to                CONSTANT VARCHAR2(100) := 'SHIP_TO'; -- �o�א�
  cv_cust_class_code_ar_mng CONSTANT VARCHAR2(10) := '14';       -- �ڋq�敪���u14�v�i���|���Ǘ���ڋq�j
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  TYPE g_rowid_ttype               IS TABLE OF ROWID INDEX BY PLS_INTEGER;
  TYPE g_bill_customer_id_ttype    IS TABLE OF ra_interface_lines_all.orig_system_bill_customer_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_bill_address_id_ttype     IS TABLE OF ra_interface_lines_all.orig_system_bill_address_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_ship_customer_id_ttype    IS TABLE OF ra_interface_lines_all.orig_system_ship_customer_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_ship_address_id_ttype     IS TABLE OF ra_interface_lines_all.orig_system_ship_address_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_cust_trx_type_id_ttype    IS TABLE OF ra_interface_lines_all.cust_trx_type_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_header_attribute7_ttype   IS TABLE OF ra_interface_lines_all.header_attribute7%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_header_attribute11_ttype  IS TABLE OF ra_interface_lines_all.header_attribute11%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_customer_class_code_ttype IS TABLE OF hz_cust_accounts.customer_class_code%type
                                               INDEX BY PLS_INTEGER;
  gt_ril_rowid                          g_rowid_ttype;
  gt_ril_bill_customer_id               g_bill_customer_id_ttype;
  gt_ril_bill_address_id                g_bill_address_id_ttype;
  gt_ril_ship_customer_id               g_ship_customer_id_ttype;
  gt_ril_ship_address_id                g_ship_address_id_ttype;
  gt_ril_cust_trx_type_id               g_cust_trx_type_id_ttype;
  gt_ril_header_attribute7              g_header_attribute7_ttype;
  gt_ril_header_attribute11             g_header_attribute11_ttype;
  gt_hca_customer_class_code            g_customer_class_code_ttype;
--
  TYPE c_out_flag_ttype     IS TABLE OF VARCHAR2(1);
  TYPE c_hold_status_ttype  IS TABLE OF VARCHAR2(10);
  gt_out_flag         c_out_flag_ttype := c_out_flag_ttype ( 'Y', 'N' );          -- ���������s�敪
  gt_hold_status      c_hold_status_ttype := c_hold_status_ttype ( 'OPEN', 'HOLD' ); -- �������ۗ��X�e�[�^�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;              -- �Ɩ��������t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a01_013 -- �Ɩ��������t�擾�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_interface_lines
   * Description      : �X�V�Ώ�AR ���OIF�e�[�u���擾 (A-3)
   ***********************************************************************************/
  PROCEDURE get_ar_interface_lines(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_interface_lines'; -- �v���O������
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
    cv_ar_inv_inp_source_name CONSTANT VARCHAR2(100) := 'XXCFR1_AR_INV_INP_SOURCE_NAME';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���o
    CURSOR get_ar_interface_cur
    IS
      SELECT rila.ROWID,                                                         -- ROWID
             rila.orig_system_bill_customer_id   orig_system_bill_customer_id,   -- ������ڋq�h�c
             rila.orig_system_bill_address_id    orig_system_bill_address_id,    -- ������ڋq���ݒn�h�c
             rila.orig_system_ship_customer_id   orig_system_ship_customer_id,   -- �o�א�ڋq�h�c
             rila.orig_system_ship_address_id    orig_system_ship_address_id,    -- �o�א�ڋq���ݒn�h�c
             rila.cust_trx_type_id               cust_trx_type_id,               -- ����^�C�v�h�c
             hca.customer_class_code             customer_class_code,            -- �ڋq�敪
             DECODE ( rctt.attribute1,
                      gt_out_flag(1), gt_hold_status(1),
                      gt_out_flag(2), gt_hold_status(2),
                      gt_hold_status(2) ) output_invoice_hold_sts         -- �������ۗ��X�e�[�^�X
      FROM ra_interface_lines_all         rila,
           hz_cust_accounts               hca,
           ra_cust_trx_types_all          rctt
      WHERE rila.batch_source_name IN (
              SELECT flvv.meaning
              FROM fnd_lookup_values_vl  flvv
              WHERE flvv.lookup_type             = cv_ar_inv_inp_source_name   -- AR������͂̎d��\�[�X�^�C�v
                AND flvv.enabled_flag            = cv_enabled_yes
-- Modified Start by SCS)H.Nakamura 2008/11/25 �Ɩ��������t�Q�Ƃ��邱�ƂɏC��
--                AND ( flvv.start_date_active     IS NULL
--                   OR flvv.start_date_active     <= SYSDATE )
--                AND ( flvv.end_date_active       IS NULL
--                   OR flvv.end_date_active       >= SYSDATE )
                AND ( flvv.start_date_active     IS NULL
                   OR flvv.start_date_active     <= gd_process_date )
                AND ( flvv.end_date_active       IS NULL
                   OR flvv.end_date_active       >= gd_process_date )
-- Modified End by SCS)H.Nakamura 2008/11/25 �Ɩ��������t�Q�Ƃ��邱�ƂɏC��
            )
        AND rila.interface_status   IS NULL
        AND NOT EXISTS ( 
            SELECT 'X'
            FROM ra_interface_errors_all  riea
            WHERE rila.interface_line_id   = riea.interface_line_id
            )
        AND rila.orig_system_bill_customer_id       = hca.cust_account_id
        AND rila.cust_trx_type_id                   = rctt.cust_trx_type_id(+)
      FOR UPDATE OF rila.INTERFACE_LINE_ID NOWAIT
    ;
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
    -- �J�[�\���I�[�v��
    OPEN get_ar_interface_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_ar_interface_cur BULK COLLECT INTO
          gt_ril_rowid,
          gt_ril_bill_customer_id,
          gt_ril_bill_address_id,
          gt_ril_ship_customer_id,
          gt_ril_ship_address_id,
          gt_ril_cust_trx_type_id,
          gt_hca_customer_class_code,
          gt_ril_header_attribute7;
--
    -- ���������̃Z�b�g
    gn_target_cnt := gt_ril_rowid.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_ar_interface_cur;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_001a01_011    -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
--                                                     ,xxcfr_common_pkg.get_table_comment(cv_table_ra_oif))
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfr
                                                      ,cv_dict_rila 
                                                     ))
                                                    -- ����I�[�v���C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
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
  END get_ar_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_convert_cust_code
   * Description      : �Ǒ֐�����ڋq�擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_convert_cust_code(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_convert_cust_code'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    ln_bill_customer_id   hz_cust_accounts.cust_account_id%type;            -- ������ڋq�h�c
    ln_bill_address_id    hz_cust_acct_sites_all.cust_acct_site_id%type;    -- ������ڋq���ݒn�h�c
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �Ώی������O�łȂ��ꍇ�A�Ǒ֐�����ڋq���擾
    IF ( gn_target_cnt > 0 ) THEN
      <<cust_data_loop>>
      FOR ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST LOOP
--
--        -- �����l�̐ݒ�
--        gt_ril_ship_customer_id(ln_loop_cnt) := NULL;
--        gt_ril_ship_address_id(ln_loop_cnt)  := NULL;
--
        -- �ڋq�敪���u14�v�i���|���Ǘ���ڋq�j�łȂ��ꍇ�A�ǂݑւ��������s��
        IF ( gt_hca_customer_class_code(ln_loop_cnt) <> cv_cust_class_code_ar_mng ) THEN
--
          -- �o�א�ڋq�ɐ�����ڋq��ݒ肷��
          gt_ril_ship_customer_id(ln_loop_cnt) := gt_ril_bill_customer_id(ln_loop_cnt);
          gt_ril_ship_address_id(ln_loop_cnt)  := gt_ril_bill_address_id(ln_loop_cnt);
--
          -- �ڋq�R�[�h��ǂݑւ���
          BEGIN
            SELECT hca2.cust_account_id,
                   hcasa2.cust_acct_site_id
            INTO ln_bill_customer_id,
                 ln_bill_address_id
            FROM hz_cust_accounts              hca,
                 hz_cust_acct_sites_all        hcasa,
                 hz_cust_site_uses_all         hcsua,
                 hz_cust_site_uses_all         hcsua2,
                 hz_cust_acct_sites_all        hcasa2,
                 hz_cust_accounts              hca2
            WHERE hca.cust_account_id          = hcasa.cust_account_id  
              AND hcasa.cust_acct_site_id      = hcsua.cust_acct_site_id
              AND hcsua.site_use_code          = cv_ship_to
              AND hcsua.bill_to_site_use_id    = hcsua2.site_use_id
              AND hcsua2.cust_acct_site_id     = hcasa2.cust_acct_site_id
              AND hca2.cust_account_id         = hcasa2.cust_account_id  
              AND hca.cust_account_id          = gt_ril_ship_customer_id(ln_loop_cnt)
              AND hcasa.cust_acct_site_id      = gt_ril_ship_address_id(ln_loop_cnt)
            ;
--
            gt_ril_bill_customer_id(ln_loop_cnt) := ln_bill_customer_id;
            gt_ril_bill_address_id(ln_loop_cnt)  := ln_bill_address_id;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- �f�[�^���擾�ł��Ȃ��ꍇ�A������̓Ǒւ͂��Ȃ��i���̂܂܁j�B
              NULL;
          END;
        END IF;
      END LOOP cust_data_loop;
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
  END get_convert_cust_code;
--
  /**********************************************************************************
   * Procedure Name   : get_receipt_dept_code
   * Description      :�������_�擾 (A-5)
   ***********************************************************************************/
  PROCEDURE get_receipt_dept_code(
    ov_errbuf               OUT VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_dept_code'; -- �v���O������
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
    ln_target_cnt   NUMBER;         -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �Ώی������O�łȂ��ꍇ�A�������_���擾
    IF ( gn_target_cnt > 0 ) THEN
      -- �������_���擾
      <<receipt_dept_code_loop>>
      FOR ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST LOOP
--
        -- �����l�̐ݒ�
        gt_ril_header_attribute11(ln_loop_cnt) := NULL;
        BEGIN
          SELECT NVL( xca.receiv_base_code, xca.sale_base_code ) receiv_base_code
          INTO gt_ril_header_attribute11(ln_loop_cnt)
          FROM xxcmm_cust_accounts    xca     -- �ڋq�ǉ����e�[�u��
          WHERE xca.customer_id       = gt_ril_bill_customer_id(ln_loop_cnt)
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            -- �f�[�^���擾�ł��Ȃ��ꍇ�A�Ȃɂ����Ȃ�
            NULL;
        END;
      END LOOP receipt_dept_code_loop;
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
  END get_receipt_dept_code;
--
  /**********************************************************************************
   * Procedure Name   : update_ar_interface_lines
   * Description      : �Ώۃe�[�u���X�V (A-6)
   ***********************************************************************************/
  PROCEDURE update_ar_interface_lines(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ar_interface_lines'; -- �v���O������
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
    ln_loop_cnt     NUMBER;        -- ���[�v�J�E���^
    ln_normal_cnt   NUMBER := 0;   -- ���팏��
    ln_error_cnt    NUMBER;        -- �G���[�J�E���^
--
    lv_errmsg_tmp   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W�E�e���|����
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
    -- =====================================================
    --  �Ώۃe�[�u���X�V (A-5)
    -- =====================================================
    -- �Ώی������O�łȂ��ꍇ�A�Ώۃf�[�^�X�V
    IF ( gn_target_cnt > 0 ) THEN
      <<update_loop>>
      FORALL ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST SAVE EXCEPTIONS
        UPDATE ra_interface_lines_all
        SET orig_system_bill_customer_id   = gt_ril_bill_customer_id(ln_loop_cnt)       -- ������ڋq�h�c
           ,orig_system_bill_address_id    = gt_ril_bill_address_id(ln_loop_cnt)        -- ������ڋq���ݒn�h�c
           ,orig_system_ship_customer_id   = gt_ril_ship_customer_id(ln_loop_cnt)       -- �o�א�ڋq�h�c
           ,orig_system_ship_address_id    = gt_ril_ship_address_id(ln_loop_cnt)        -- �o�א�ڋq���ݒn�h�c
           ,header_attribute7              = gt_ril_header_attribute7(ln_loop_cnt)      -- �������ۗ��X�e�[�^�X
           ,header_attribute11             = gt_ril_header_attribute11(ln_loop_cnt)     -- �������_
           ,last_updated_by                = cn_last_updated_by                         -- �ŏI�X�V��
           ,last_update_date               = cd_last_update_date                        -- �ŏI�X�V��
           ,last_update_login              = cn_last_update_login                       -- �ŏI�X�V���O�C��
--           ,request_id                     = cn_request_id  -- �X�V����ƁA�C���^�[�t�F�[�X����Ȃ��Ȃ邽�߁A�폜
        WHERE ROWID                        = gt_ril_rowid(ln_loop_cnt)
      ;
    END IF;
--
    gn_normal_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
    -- DML�����s�ɂăG���[������
    WHEN dml_expt THEN
      ln_error_cnt := SQL%BULK_EXCEPTIONS.COUNT;
      FOR ln_loop_cnt IN 1..ln_error_cnt LOOP
        lv_errmsg_tmp := SUBSTRB( xxcmn_common_pkg.get_msg(
                                                        cv_msg_kbn_cfr       -- 'XXCFR'
                                                       ,cv_msg_001a01_012    -- �e�[�u�����X�V�ł��Ȃ�
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
--                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_ra_oif)
                                                       ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfr
                                                        ,cv_dict_rila 
                                                       )
                                                       ,cv_tkn_comment       -- �g�[�N��'COMMENT'
                                                       ,xxcfr_common_pkg.get_col_comment(cv_table_xca, cv_col_cust_id)
                                                       || cv_msg_part
                                                       || gt_ril_bill_customer_id(SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_INDEX)
                                                       ) -- �ڋq�h�c
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errbuf || SQLERRM(-SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_CODE) || cv_cr;
        lv_errmsg := lv_errmsg || lv_errmsg_tmp || cv_cr;
--
        -- �G���[�J�E���g���i�[
        gn_error_cnt := SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_INDEX;
--
      END LOOP;
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
  END update_ar_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ɩ��������t�擾���� (A-2)
    -- =====================================================
    get_process_date(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �X�V�Ώ�AR ���OIF�e�[�u���擾 (A-3)
    -- =====================================================
    get_ar_interface_lines(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ǒ֐�����ڋq�擾 (A-4)
    -- =====================================================
    get_convert_cust_code(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �������_�擾 (A-5)
    -- =====================================================
    get_receipt_dept_code(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ώۃe�[�u���X�V (A-6)
    -- =====================================================
    update_ar_interface_lines(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
    errbuf        OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT     VARCHAR2          --    �G���[�R�[�h     #�Œ�#
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
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
      ,ov_retcode => lv_retcode
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
       lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --����łȂ��ꍇ�A�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --�P�s���s
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
    );
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
END XXCFR001A01C;
/
