CREATE OR REPLACE PACKAGE BODY XXCOK016A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK016A03C(body)
 * Description      : EDI�V�X�e���ɂăC���t�H�}�[�g�Ђ֑��M���郏�[�N�f�[�^�쐬
 * MD.050           : �C���t�H�}�[�g�p�ԍ����쐬 MD050_COK_016_A03
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  ins_no_diff_header          �����Ȃ��̐ԍ��w�b�_�[���쐬(FB��)(A-13)
 *  ins_debit_fb                �ԃf�[�^�쐬�iFB��j(A-10)
 *  ins_credit_header           �V���w�b�_�[���쐬(A-9)
 *  ins_credit_custom           �V���J�X�^�����׏��쐬�Q(A-8)
 *  difference_check_fb         �����`�F�b�N(A-5-1)
 *                              �V���J�X�^�����׏��쐬�P(A-7)
 *  difference_check_re         �����`�F�b�N�i�g�ݖ߂���j(A-5-2)
 *                              �ԃf�[�^�쐬�i�g�ݖ߂���j(A-6)
 *  ins_snap_data               �̎�c���X�i�b�v�V���b�g�쐬(A-4)
 *  proc_check                  �����`�F�b�N(A-3)
 *  del_work                    ���[�N�e�[�u���f�[�^�폜(A-2)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/02/01    1.0   H.Futamura       �V�K�쐬 E_�{�ғ�_17680 �C���t�H�}�[�g�̓d�q����ۑ��@�Ή�
 *  2022/10/21    1.1   K.Kanada         E_�{�ғ�_18200 ��Q�Ή�
 *  2023/07/26    1.2   Y.Ooyama         E_�{�ғ�_19179 ��Q�Ή�
 *  2024/02/05    1.3   M.Akachi         E_�{�ғ�_19496 ��Q�Ή�
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK016A03C';
  -- �A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxcok  CONSTANT VARCHAR2(10)    := 'XXCOK'; -- ��_�A�v���P�[�V�����Z�k��
  cv_appli_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP'; -- ����_�A�v���P�[�V�����Z�k��
  -- �X�e�[�^�X
  cv_status_normal           CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W
  cv_msg_xxcok1_00003        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90003';  -- �x������
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_msg_xxcok1_10814        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10814';  -- �����쐬����
  cv_msg_xxcok1_10817        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10817';  -- �C���t�H�}�[�g�ԍ��쐬�p�p�����[�^�o��
  cv_msg_xxcok1_10818        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10818';  -- �����Ĕ��l���b�Z�[�WFB�ԗp
  cv_msg_xxcok1_10819        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10819';  -- �����Ĕ��l���b�Z�[�W�V���p
  cv_msg_xxcok1_10820        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10820';  -- �����Ĕ��l���b�Z�[�W�g�ݖ߂��ԗp
  cv_msg_xxcok1_10821        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10821';  -- �������G���[���b�Z�[�W
  cv_msg_xxcok1_10822        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10822';  -- �����ς݃G���[���b�Z�[�W
  cv_msg_xxcok1_10823        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10823';  -- �����Ώی������b�Z�[�W
  cv_msg_xxcok1_10824        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10824';  -- �ԃf�[�^�쐬�������b�Z�[�W
  cv_msg_xxcok1_10825        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10825';  -- ���f�[�^�쐬�������b�Z�[�W
  cv_msg_xxcok1_10826        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10826';  -- �폜�������b�Z�[�W
  -- �g�[�N��
  cv_tkn_profile             CONSTANT VARCHAR2(7)     := 'PROFILE';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_proc_div            CONSTANT VARCHAR2(8)     := 'PROC_DIV';
  -- �v���t�@�C��
  cv_prof_term_name          CONSTANT VARCHAR2(24)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- �f�t�H���g�x������
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(41)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- ��s�萔��_�U���z�
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- ��s�萔��_��z����
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- ��s�萔��_��z�ȏ�
  cv_prof_bm_tax             CONSTANT VARCHAR2(13)    := 'XXCOK1_BM_TAX';                    -- �̔��萔��_����ŗ�
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: �c�ƒP��
  cv_prof_elec_change_item   CONSTANT VARCHAR2(30)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- �d�C���i�ϓ��j�i�ڃR�[�h
-- Ver.1.2 ADD START
  cv_prof_snap_keep_months   CONSTANT VARCHAR2(30)    := 'XXCOK1_SNAPSHOT_KEEP_MONTHS';      -- �X�i�b�v�V���b�g�ێ�����
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
  cv_set_of_books_id         CONSTANT VARCHAR2(30)    := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_xxcok1_set_code         CONSTANT VARCHAR2(30)    := 'XXCOK1_SET_CODE';                  -- �ʒm�������ݒ�R�[�h
-- Ver.1.3 Add End
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
-- Ver.1.2 ADD START
  cv_tax_calc_kbn_line       CONSTANT VARCHAR2(1)     := '2';                   -- �Ōv�Z�敪�F���גP��
  cv_tax_rounding_rule_down  CONSTANT VARCHAR2(4)     := 'DOWN';                -- �[�������敪�F�؎̂�
-- Ver.1.2 ADD END
--
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT 0;                                  -- �Ώی���
  gn_dif_cnt                 NUMBER DEFAULT 0;                                  -- �����Ώی���
  gn_debit_cnt               NUMBER DEFAULT 0;                                  -- �ԃf�[�^�쐬����
  gn_credit_cnt              NUMBER DEFAULT 0;                                  -- ���f�[�^�쐬����
  gn_error_cnt               NUMBER DEFAULT 0;                                  -- �G���[����
  gn_skip_cnt                NUMBER DEFAULT 0;                                  -- �X�L�b�v����
  gd_process_date            DATE   DEFAULT NULL;                               -- �Ɩ��������t
  gv_process_ym              VARCHAR2(6) DEFAULT NULL;                          -- �Ɩ������N��
  gv_process_ym_pre          VARCHAR2(6) DEFAULT NULL;                          -- �Ɩ������O�N��
-- Ver.1.2 ADD START
  gv_snap_keep_oldest_ym     VARCHAR2(6) DEFAULT NULL;                          -- �X�i�b�v�V���b�g�ێ��ŌÔN���iYYYYMM�j
-- Ver.1.2 ADD END
  gd_operating_date          DATE   DEFAULT NULL;                               -- ���ߎx�������o�����t
  gd_closing_date            DATE   DEFAULT NULL;                               -- ���ߓ�
  gd_schedule_date           DATE   DEFAULT NULL;                               -- �x���\���
  gn_org_id                  NUMBER;                                            -- �c�ƒP��ID
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �x������
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_�U���z�
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z����
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z�ȏ�
  gv_elec_change_item_code   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �d�C���i�ϓ��j�i�ڃR�[�h
-- Ver.1.2 ADD START
  gv_snap_keep_months        fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �X�i�b�v�V���b�g�ێ�����
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
  gv_set_of_bks_id           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- GL��v����ID
-- Ver.1.3 Add End
  gn_bm_tax                  NUMBER;                                            -- �̔��萔��_����ŗ�
  gn_tax_include_less        NUMBER;                                            -- �ō���s�萔��_��z����
  gn_tax_include_more        NUMBER;                                            -- �ō���s�萔��_��z�ȏ�
--
  gv_remarks_fb_deb          fnd_new_messages.message_text%TYPE;                -- �����Ĕ��lFB�ԗp
  gv_remarks_new_cre         fnd_new_messages.message_text%TYPE;                -- �����Ĕ��l�V���p
  gv_remarks_re_deb          fnd_new_messages.message_text%TYPE;                -- �����Ĕ��l�g�ݖ߂��ԗp
  gv_line_sum                fnd_new_messages.message_text%TYPE;                -- ���׍��v�s��
--
-- Els Ver1.1 K.Kanada S
--  TYPE g_no_dif_rtype        IS RECORD
--    (supplier_code           xxcok_bm_balance_snap.supplier_code%TYPE
--    ,cust_code               xxcok_bm_balance_snap.cust_code%TYPE
--    );
--  TYPE g_no_dif_sup_rtype    IS RECORD
--    (supplier_code           xxcok_bm_balance_snap.supplier_code%TYPE
--    );
----
--  TYPE g_no_dif_ttype        IS TABLE OF g_no_dif_rtype        INDEX BY BINARY_INTEGER;
--  TYPE g_no_dif_sup_ttype    IS TABLE OF g_no_dif_sup_rtype    INDEX BY BINARY_INTEGER;
----
--  g_no_dif_tab               g_no_dif_ttype;
--  g_no_dif_sup_tab           g_no_dif_sup_ttype;--
-- Ers Ver1.1 K.Kanada E
-- Add Ver1.1 K.Kanada S
--
  TYPE g_dif_sup_rtype IS RECORD
    (supplier_code           xxcok_bm_balance_snap.supplier_code%TYPE
    );
--
  TYPE g_dif_sup_ttype IS TABLE OF g_dif_sup_rtype INDEX BY BINARY_INTEGER;
--
  g_dif_sup_tab              g_dif_sup_ttype;
-- Add Ver1.1 K.Kanada E
--
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- Ver.1.2 ADD START
  /**********************************************************************************
   * Procedure Name   : ins_no_diff_header
   * Description      : �����Ȃ��̐ԍ��w�b�_�[���쐬(FB��)(A-13)
   *                  : �������Ȃ��̐ԍ��J�X�^�����ׂ͍쐬���Ȃ�
   ***********************************************************************************/
  PROCEDURE ins_no_diff_header(
    iv_proc_div   IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_no_diff_header';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- �����Ȃ��iFB��̐ԍ������݂��Ȃ��j�̌����w�b�_�[���
    CURSOR l_ins_no_diff_header_cur
    IS
      SELECT xirh.rowid               AS  row_id                 -- ROWID
            ,pvsa.attribute4          AS  bm_payment_kbn         -- BM�x���敪
           ,(CASE
               WHEN (pvsa.attribute8 IS NOT NULL AND pvsa.attribute9 IS NOT NULL) THEN
                 -- �K�i���������s���Ǝғo�^ �{ �ېŎ��ƎҔԍ�
                 pvsa.attribute8 || pvsa.attribute9
               ELSE
                 NULL
             END)                     AS  vendor_invoice_regnum  -- ���t��C���{�C�X�o�^�ԍ�
      FROM   xxcok_info_rev_header    xirh     -- ����
            ,po_vendors               pv       -- �d����}�X�^
            ,po_vendor_sites_all      pvsa     -- �d����T�C�g
      WHERE  xirh.snapshot_create_ym  = gv_process_ym
      AND    xirh.snapshot_timing     = '1' -- 2�c
      AND    xirh.rev                 = '1' -- �����i2�c�j
      AND    xirh.vendor_code         = pv.segment1
      AND    pv.vendor_id             = pvsa.vendor_id
      AND    (pvsa.inactive_date > gd_process_date
              OR
              pvsa.inactive_date IS NULL)
      AND    pvsa.org_id              = gn_org_id
      AND    NOT EXISTS (
                 SELECT 1
                 FROM   xxcok_info_rev_header    xirh_fb
                 WHERE  xirh_fb.snapshot_create_ym  = gv_process_ym
                 AND    xirh_fb.snapshot_timing     = '2'  -- FB��
                 AND    xirh_fb.vendor_code         = xirh.vendor_code
             )
      ;
--
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    << ins_no_diff_header_loop >>
    FOR l_ins_no_diff_header_rec IN l_ins_no_diff_header_cur LOOP
      -- ===============================================
      -- �w�b�_�[���o�^(�����Ȃ��̐�)
      -- ===============================================
      INSERT INTO xxcok_info_rev_header(
        snapshot_create_ym        -- �X�i�b�v�V���b�g�쐬�N��
       ,snapshot_timing           -- �X�i�b�v�V���b�g�^�C�~���O
       ,rev                       -- REV
       ,check_result              -- �Ó����`�F�b�N����
       ,row_id                    -- ���e�[�u�����R�[�hID
       ,edi_interface_date        -- �A�g���iEDI�x���ē����j
       ,vendor_code               -- ���t��R�[�h
       ,set_code                  -- �ʒm�������ݒ�R�[�h
       ,cust_code                 -- �ڋq�R�[�h
       ,cust_name                 -- ��Ж�
       ,dest_post_code            -- �X�֔ԍ�
       ,dest_address1             -- �Z��
       ,dest_tel                  -- �d�b�ԍ�
       ,fax                       -- FAX�ԍ�
       ,dept_name                 -- ������
       ,send_post_code            -- �X�֔ԍ��i���t���j
       ,send_address1             -- �Z���i���t���j
       ,send_tel                  -- �d�b�ԍ��i���t���j
       ,num                       -- �ԍ�
       ,payment_date              -- �x����
       ,closing_date              -- ���ߓ�
       ,closing_date_min          -- �ŏ����ߓ�
       ,notifi_amt                -- �����Ă̒ʒm���z
       ,total_amt_no_tax_10       -- 10%���v���z�i�Ŕ��j
       ,tax_amt_10                -- 10%����Ŋz
       ,total_amt_10              -- 10%���v���z�i�ō��j
       ,total_amt_no_tax_8        -- �y��8%���v���z�i�Ŕ��j
       ,tax_amt_8                 -- �y��8%����Ŋz
       ,total_amt_8               -- �y��8%���v���z�i�ō��j
       ,total_amt_no_tax_0        -- ��ېō��v���z�i�Ŕ��j
       ,tax_amt_0                 -- ��ېŏ���Ŋz
       ,total_amt_0               -- ��ېō��v���z�i�ō��j
       ,total_sales_qty           -- �̔��{�����v
       ,total_sales_amt           -- �̔����z���v
       ,sales_fee                 -- �̔��萔��
       ,electric_amt              -- �d�C�㓙���v�@�Ŕ�
       ,tax_amt                   -- �����
       ,transfer_fee              -- �U���萔�� �ō�
       ,payment_amt               -- ���x�����z �ō�
       ,remarks                   -- �����Ĕ��l
       ,bank_code                 -- ��s�R�[�h
       ,bank_name                 -- ��s��
       ,branch_code               -- �x�X�R�[�h
       ,branch_name               -- �x�X��
       ,bank_holder_name_alt      -- ������
       ,tax_div                   -- �ŋ敪
       ,target_div                -- �Ώۋ敪
       ,created_by                -- �쐬��
       ,creation_date             -- �쐬��
       ,last_updated_by           -- �ŏI�X�V��
       ,last_update_date          -- �ŏI�X�V��
       ,last_update_login         -- �ŏI�X�V���O�C��
       ,request_id                -- �v��ID
       ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                -- �R���J�����g�E�v���O����ID
       ,program_update_date       -- �v���O�����X�V��
       ,bm_payment_kbn            -- BM�x���敪
       ,tax_calc_kbn              -- �Ōv�Z�敪
       ,bm_tax_kbn                -- BM�ŋ敪
       ,bank_charge_bearer        -- �U���萔�����S��
       ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
       ,sales_fee_tax             -- �̔��萔���i����Łj
       ,sales_fee_with_tax        -- �̔��萔���i�ō��j
       ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
       ,electric_amt_tax          -- �d�C�㓙�i����Łj
       ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
       ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
       ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
       ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
       ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
       ,bank_trans_fee_tax        -- �U���萔���i����Łj
       ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
       ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.3 Add Start
       ,display_code              -- �\���R�[�h
       ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      )
      SELECT
          xirh.snapshot_create_ym                    AS  snapshot_create_ym        -- �X�i�b�v�V���b�g�쐬�N��
         ,iv_proc_div                                AS  snapshot_timing           -- �X�i�b�v�V���b�g�^�C�~���O
         ,'2'                                        AS  rev                       -- REV�i2:�ԁiFB�j)
         ,'1'                                        AS  check_result              -- �Ó����`�F�b�N���ʁi1:�ΏۊO�j
         ,NULL                                       AS  row_id                    -- ���e�[�u�����R�[�hID
         ,NULL                                       AS  edi_interface_date        -- �A�g���iEDI�x���ē����j
         ,xirh.vendor_code                           AS  vendor_code               -- ���t��R�[�h
         ,xirh.set_code                              AS  set_code                  -- �ʒm�������ݒ�R�[�h
         ,xirh.cust_code                             AS  cust_code                 -- �ڋq�R�[�h
         ,xirh.cust_name                             AS  cust_name                 -- ��Ж�
         ,xirh.dest_post_code                        AS  dest_post_code            -- �X�֔ԍ�
         ,xirh.dest_address1                         AS  dest_address1             -- �Z��
         ,xirh.dest_tel                              AS  dest_tel                  -- �d�b�ԍ�
         ,xirh.fax                                   AS  fax                       -- FAX�ԍ�
         ,xirh.dept_name                             AS  dept_name                 -- ������
         ,xirh.send_post_code                        AS  send_post_code            -- �X�֔ԍ��i���t���j
         ,xirh.send_address1                         AS  send_address1             -- �Z���i���t���j
         ,xirh.send_tel                              AS  send_tel                  -- �d�b�ԍ��i���t���j
         ,xirh.num                                   AS  num                       -- �ԍ�
         ,xirh.payment_date                          AS  payment_date              -- �x����
         ,xirh.closing_date                          AS  closing_date              -- ���ߓ�
         ,xirh.closing_date_min                      AS  closing_date_min          -- �ŏ����ߓ�
         ,(xirh.notifi_amt) * -1                     AS  notifi_amt                -- �����Ă̒ʒm���z
         ,(xirh.total_amt_no_tax_10) * -1            AS  total_amt_no_tax_10       -- 10%���v���z�i�Ŕ��j
         ,(xirh.tax_amt_10) * -1                     AS  tax_amt_10                -- 10%����Ŋz
         ,(xirh.total_amt_10) * -1                   AS  total_amt_10              -- 10%���v���z�i�ō��j
         ,(xirh.total_amt_no_tax_8) * -1             AS  total_amt_no_tax_8        -- �y��8%���v���z�i�Ŕ��j
         ,(xirh.tax_amt_8) * -1                      AS  tax_amt_8                 -- �y��8%����Ŋz
         ,(xirh.total_amt_8) * -1                    AS  total_amt_8               -- �y��8%���v���z�i�ō��j
         ,(xirh.total_amt_no_tax_0) * -1             AS  total_amt_no_tax_0        -- ��ېō��v���z�i�Ŕ��j
         ,(xirh.tax_amt_0) * -1                      AS  tax_amt_0                 -- ��ېŏ���Ŋz
         ,(xirh.total_amt_0) * -1                    AS  total_amt_0               -- ��ېō��v���z�i�ō��j
         ,(xirh.total_sales_qty) * -1                AS  total_sales_qty           -- �̔��{�����v
         ,(xirh.total_sales_amt) * -1                AS  total_sales_amt           -- �̔����z���v
         ,(xirh.sales_fee) * -1                      AS  sales_fee                 -- �̔��萔��
         ,(xirh.electric_amt) * -1                   AS  electric_amt              -- �d�C�㓙���v �Ŕ�
         ,(xirh.tax_amt) * -1                        AS  tax_amt                   -- �����
         ,(xirh.transfer_fee) * -1                   AS  transfer_fee              -- �U���萔�� �ō�
         ,(xirh.payment_amt) * -1                    AS  payment_amt               -- ���x�����z �ō�
         ,'"'||SUBSTR(gv_remarks_fb_deb,1,500)||'"'  AS  remarks                   -- �����Ĕ��l
         ,xirh.bank_code                             AS  bank_code                 -- ��s�R�[�h
         ,xirh.bank_name                             AS  bank_name                 -- ��s��
         ,xirh.branch_code                           AS  branch_code               -- �x�X�R�[�h
         ,xirh.branch_name                           AS  branch_name               -- �x�X��
         ,xirh.bank_holder_name_alt                  AS  bank_holder_name_alt      -- ������
         ,xirh.tax_div                               AS  tax_div                   -- �ŋ敪
         ,xirh.target_div                            AS  target_div                -- �Ώۋ敪
         ,cn_created_by                              AS  created_by                -- �쐬��
         ,SYSDATE                                    AS  creation_date             -- �쐬��
         ,cn_last_updated_by                         AS  last_updated_by           -- �ŏI�X�V��
         ,SYSDATE                                    AS  last_update_date          -- �ŏI�X�V��
         ,cn_last_update_login                       AS  last_update_login         -- �ŏI�X�V���O�C��
         ,cn_request_id                              AS  request_id                -- �v��ID
         ,cn_program_application_id                  AS  program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                              AS  program_id                -- �R���J�����g�E�v���O����ID
         ,SYSDATE                                    AS  program_update_date       -- �v���O�����X�V��
         ,xirh.bm_payment_kbn                        AS  bm_payment_kbn            -- BM�x���敪
         ,xirh.tax_calc_kbn                          AS  tax_calc_kbn              -- �Ōv�Z�敪
         ,xirh.bm_tax_kbn                            AS  bm_tax_kbn                -- BM�ŋ敪
         ,xirh.bank_charge_bearer                    AS  bank_charge_bearer        -- �U���萔�����S��
         ,(xirh.sales_fee_no_tax) * -1               AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
         ,(xirh.sales_fee_tax) * -1                  AS  sales_fee_tax             -- �̔��萔���i����Łj
         ,(xirh.sales_fee_with_tax) * -1             AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
         ,(xirh.electric_amt_no_tax) * -1            AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
         ,(xirh.electric_amt_tax) * -1               AS  electric_amt_tax          -- �d�C�㓙�i����Łj
         ,(xirh.electric_amt_with_tax) * -1          AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
         ,(xirh.recalc_total_fee_no_tax) * -1        AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
         ,(xirh.recalc_total_fee_tax) * -1           AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
         ,(xirh.recalc_total_fee_with_tax) * -1      AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
         ,(xirh.bank_trans_fee_no_tax) * -1          AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
         ,(xirh.bank_trans_fee_tax) * -1             AS  bank_trans_fee_tax        -- �U���萔���i����Łj
         ,(xirh.bank_trans_fee_with_tax) * -1        AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
         ,xirh.vendor_invoice_regnum                 AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.3 Add Start
         ,xirh.display_code                          AS  display_code              -- �\���R�[�h
         ,xirh.company_code_bd                       AS  company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      FROM   xxcok_info_rev_header    xirh  -- ����
      WHERE  xirh.rowid = l_ins_no_diff_header_rec.row_id
      ;
--
      -- ===============================================
      -- �w�b�_�[���o�^(�����Ȃ��̐V��)
      -- ===============================================
      INSERT INTO xxcok_info_rev_header(
        snapshot_create_ym        -- �X�i�b�v�V���b�g�쐬�N��
       ,snapshot_timing           -- �X�i�b�v�V���b�g�^�C�~���O
       ,rev                       -- REV
       ,check_result              -- �Ó����`�F�b�N����
       ,row_id                    -- ���e�[�u�����R�[�hID
       ,edi_interface_date        -- �A�g���iEDI�x���ē����j
       ,vendor_code               -- ���t��R�[�h
       ,set_code                  -- �ʒm�������ݒ�R�[�h
       ,cust_code                 -- �ڋq�R�[�h
       ,cust_name                 -- ��Ж�
       ,dest_post_code            -- �X�֔ԍ�
       ,dest_address1             -- �Z��
       ,dest_tel                  -- �d�b�ԍ�
       ,fax                       -- FAX�ԍ�
       ,dept_name                 -- ������
       ,send_post_code            -- �X�֔ԍ��i���t���j
       ,send_address1             -- �Z���i���t���j
       ,send_tel                  -- �d�b�ԍ��i���t���j
       ,num                       -- �ԍ�
       ,payment_date              -- �x����
       ,closing_date              -- ���ߓ�
       ,closing_date_min          -- �ŏ����ߓ�
       ,notifi_amt                -- �����Ă̒ʒm���z
       ,total_amt_no_tax_10       -- 10%���v���z�i�Ŕ��j
       ,tax_amt_10                -- 10%����Ŋz
       ,total_amt_10              -- 10%���v���z�i�ō��j
       ,total_amt_no_tax_8        -- �y��8%���v���z�i�Ŕ��j
       ,tax_amt_8                 -- �y��8%����Ŋz
       ,total_amt_8               -- �y��8%���v���z�i�ō��j
       ,total_amt_no_tax_0        -- ��ېō��v���z�i�Ŕ��j
       ,tax_amt_0                 -- ��ېŏ���Ŋz
       ,total_amt_0               -- ��ېō��v���z�i�ō��j
       ,total_sales_qty           -- �̔��{�����v
       ,total_sales_amt           -- �̔����z���v
       ,sales_fee                 -- �̔��萔��
       ,electric_amt              -- �d�C�㓙���v�@�Ŕ�
       ,tax_amt                   -- �����
       ,transfer_fee              -- �U���萔���@�ō�
       ,payment_amt               -- ���x�����z�@�ō�
       ,remarks                   -- �����Ĕ��l
       ,bank_code                 -- ��s�R�[�h
       ,bank_name                 -- ��s��
       ,branch_code               -- �x�X�R�[�h
       ,branch_name               -- �x�X��
       ,bank_holder_name_alt      -- ������
       ,tax_div                   -- �ŋ敪
       ,target_div                -- �Ώۋ敪
       ,created_by                -- �쐬��
       ,creation_date             -- �쐬��
       ,last_updated_by           -- �ŏI�X�V��
       ,last_update_date          -- �ŏI�X�V��
       ,last_update_login         -- �ŏI�X�V���O�C��
       ,request_id                -- �v��ID
       ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                -- �R���J�����g�E�v���O����ID
       ,program_update_date       -- �v���O�����X�V��
       ,bm_payment_kbn            -- BM�x���敪
       ,tax_calc_kbn              -- �Ōv�Z�敪
       ,bm_tax_kbn                -- BM�ŋ敪
       ,bank_charge_bearer        -- �U���萔�����S��
       ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
       ,sales_fee_tax             -- �̔��萔���i����Łj
       ,sales_fee_with_tax        -- �̔��萔���i�ō��j
       ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
       ,electric_amt_tax          -- �d�C�㓙�i����Łj
       ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
       ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
       ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
       ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
       ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
       ,bank_trans_fee_tax        -- �U���萔���i����Łj
       ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
       ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.3 Add Start
       ,display_code              -- �\���R�[�h
       ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      )
      SELECT
          xirh.snapshot_create_ym                         AS  snapshot_create_ym        -- �X�i�b�v�V���b�g�쐬�N��
         ,iv_proc_div                                     AS  snapshot_timing           -- �X�i�b�v�V���b�g�^�C�~���O
         ,'3'                                             AS  rev                       -- REV�i3:�V���iFB�j)
         ,'1'                                             AS  check_result              -- �Ó����`�F�b�N���ʁi1:�ΏۊO�j
         ,NULL                                            AS  row_id                    -- ���e�[�u�����R�[�hID
         ,NULL                                            AS  edi_interface_date        -- �A�g���iEDI�x���ē����j
         ,xirh.vendor_code                                AS  vendor_code               -- ���t��R�[�h
         ,xirh.set_code                                   AS  set_code                  -- �ʒm�������ݒ�R�[�h
         ,xirh.cust_code                                  AS  cust_code                 -- �ڋq�R�[�h
         ,xirh.cust_name                                  AS  cust_name                 -- ��Ж�
         ,xirh.dest_post_code                             AS  dest_post_code            -- �X�֔ԍ�
         ,xirh.dest_address1                              AS  dest_address1             -- �Z��
         ,xirh.dest_tel                                   AS  dest_tel                  -- �d�b�ԍ�
         ,xirh.fax                                        AS  fax                       -- FAX�ԍ�
         ,xirh.dept_name                                  AS  dept_name                 -- ������
         ,xirh.send_post_code                             AS  send_post_code            -- �X�֔ԍ��i���t���j
         ,xirh.send_address1                              AS  send_address1             -- �Z���i���t���j
         ,xirh.send_tel                                   AS  send_tel                  -- �d�b�ԍ��i���t���j
         ,xirh.num                                        AS  num                       -- �ԍ�
         ,xirh.payment_date                               AS  payment_date              -- �x����
         ,xirh.closing_date                               AS  closing_date              -- ���ߓ�
         ,xirh.closing_date_min                           AS  closing_date_min          -- �ŏ����ߓ�
         ,xirh.notifi_amt                                 AS  notifi_amt                -- �����Ă̒ʒm���z
         ,xirh.total_amt_no_tax_10                        AS  total_amt_no_tax_10       -- 10%���v���z�i�Ŕ��j
         ,xirh.tax_amt_10                                 AS  tax_amt_10                -- 10%����Ŋz
         ,xirh.total_amt_10                               AS  total_amt_10              -- 10%���v���z�i�ō��j
         ,xirh.total_amt_no_tax_8                         AS  total_amt_no_tax_8        -- �y��8%���v���z�i�Ŕ��j
         ,xirh.tax_amt_8                                  AS  tax_amt_8                 -- �y��8%����Ŋz
         ,xirh.total_amt_8                                AS  total_amt_8               -- �y��8%���v���z�i�ō��j
         ,xirh.total_amt_no_tax_0                         AS  total_amt_no_tax_0        -- ��ېō��v���z�i�Ŕ��j
         ,xirh.tax_amt_0                                  AS  tax_amt_0                 -- ��ېŏ���Ŋz
         ,xirh.total_amt_0                                AS  total_amt_0               -- ��ېō��v���z�i�ō��j
         ,xirh.total_sales_qty                            AS  total_sales_qty           -- �̔��{�����v
         ,xirh.total_sales_amt                            AS  total_sales_amt           -- �̔����z���v
         ,xirh.sales_fee                                  AS  sales_fee                 -- �̔��萔��
         ,xirh.electric_amt                               AS  electric_amt              -- �d�C�㓙���v �Ŕ�
         ,xirh.tax_amt                                    AS  tax_amt                   -- �����
         ,xirh.transfer_fee                               AS  transfer_fee              -- �U���萔�� �ō�
         ,xirh.payment_amt                                AS  payment_amt               -- ���x�����z �ō�
         ,'"'||SUBSTR(gv_remarks_new_cre,1,500)||'"'      AS  remarks                   -- �����Ĕ��l
         ,xirh.bank_code                                  AS  bank_code                 -- ��s�R�[�h
         ,xirh.bank_name                                  AS  bank_name                 -- ��s��
         ,xirh.branch_code                                AS  branch_code               -- �x�X�R�[�h
         ,xirh.branch_name                                AS  branch_name               -- �x�X��
         ,xirh.bank_holder_name_alt                       AS  bank_holder_name_alt      -- ������
         ,xirh.tax_div                                    AS  tax_div                   -- �ŋ敪
         ,xirh.target_div                                 AS  target_div                -- �Ώۋ敪
         ,cn_created_by                                   AS  created_by                -- �쐬��
         ,SYSDATE                                         AS  creation_date             -- �쐬��
         ,cn_last_updated_by                              AS  last_updated_by           -- �ŏI�X�V��
         ,SYSDATE                                         AS  last_update_date          -- �ŏI�X�V��
         ,cn_last_update_login                            AS  last_update_login         -- �ŏI�X�V���O�C��
         ,cn_request_id                                   AS  request_id                -- �v��ID
         ,cn_program_application_id                       AS  program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                                   AS  program_id                -- �R���J�����g�E�v���O����ID
         ,SYSDATE                                         AS  program_update_date       -- �v���O�����X�V��
         ,l_ins_no_diff_header_rec.bm_payment_kbn         AS  bm_payment_kbn            -- BM�x���敪
         ,xirh.tax_calc_kbn                               AS  tax_calc_kbn              -- �Ōv�Z�敪
         ,xirh.bm_tax_kbn                                 AS  bm_tax_kbn                -- BM�ŋ敪
         ,xirh.bank_charge_bearer                         AS  bank_charge_bearer        -- �U���萔�����S��
         ,xirh.sales_fee_no_tax                           AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
         ,xirh.sales_fee_tax                              AS  sales_fee_tax             -- �̔��萔���i����Łj
         ,xirh.sales_fee_with_tax                         AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
         ,xirh.electric_amt_no_tax                        AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
         ,xirh.electric_amt_tax                           AS  electric_amt_tax          -- �d�C�㓙�i����Łj
         ,xirh.electric_amt_with_tax                      AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
         ,xirh.recalc_total_fee_no_tax                    AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
         ,xirh.recalc_total_fee_tax                       AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
         ,xirh.recalc_total_fee_with_tax                  AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
         ,xirh.bank_trans_fee_no_tax                      AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
         ,xirh.bank_trans_fee_tax                         AS  bank_trans_fee_tax        -- �U���萔���i����Łj
         ,xirh.bank_trans_fee_with_tax                    AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
         ,l_ins_no_diff_header_rec.vendor_invoice_regnum  AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.3 Add Start
         ,xirh.display_code                               AS  display_code              -- �\���R�[�h
         ,xirh.company_code_bd                            AS  company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      FROM   xxcok_info_rev_header    xirh  -- ����
      WHERE  xirh.rowid = l_ins_no_diff_header_rec.row_id
      ;
--
    END LOOP ins_no_diff_header_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_no_diff_header;
-- Ver.1.2 ADD END
--
  /**********************************************************************************
   * Procedure Name   : ins_debit_fb
   * Description      : �ԃf�[�^�쐬�iFB��j(A-10)
   ***********************************************************************************/
  PROCEDURE ins_debit_fb(
    iv_proc_div      IN  VARCHAR2
-- Mod Ver1.1 K.Kanada S
--   ,i_no_dif_sup_tab IN g_no_dif_sup_ttype
   ,i_dif_sup_tab    IN  g_dif_sup_ttype
-- Mod Ver1.1 K.Kanada E
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_debit_fb';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--    ln_count        NUMBER;  -- Els Ver1.1 K.Kanada
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
-- Els Ver1.1 K.Kanada S
--    INSERT INTO xxcok_info_rev_header(
--      snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--     ,snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--     ,rev                     -- REV
--     ,check_result            -- �Ó����`�F�b�N����
--     ,row_id                  -- ���e�[�u�����R�[�hID
--     ,edi_interface_date      -- �A�g���iEDI�x���ē����j
--     ,vendor_code             -- ���t��R�[�h
--     ,set_code                -- �ʒm�������ݒ�R�[�h
--     ,cust_code               -- �ڋq�R�[�h
--     ,cust_name               -- ��Ж�
--     ,dest_post_code          -- �X�֔ԍ�
--     ,dest_address1           -- �Z��
--     ,dest_tel                -- �d�b�ԍ�
--     ,fax                     -- FAX�ԍ�
--     ,dept_name               -- ������
--     ,send_post_code          -- �X�֔ԍ��i���t���j
--     ,send_address1           -- �Z���i���t���j
--     ,send_tel                -- �d�b�ԍ��i���t���j
--     ,num                     -- �ԍ�
--     ,payment_date            -- �x����
--     ,closing_date            -- ���ߓ�
--     ,closing_date_min        -- �ŏ����ߓ�
--     ,notifi_amt              -- �����Ă̒ʒm���z
--     ,total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
--     ,tax_amt_8               -- �y��8%����Ŋz
--     ,total_amt_8             -- �y��8%���v���z�i�ō��j
--     ,total_sales_qty         -- �̔��{�����v
--     ,total_sales_amt         -- �̔����z���v
--     ,sales_fee               -- �̔��萔��
--     ,electric_amt            -- �d�C�㓙���v�@�Ŕ�
--     ,tax_amt                 -- �����
--     ,transfer_fee            -- �U���萔�� �ō�
--     ,payment_amt             -- ���x�����z �ō�
--     ,remarks                 -- �����Ĕ��l
--     ,bank_code               -- ��s�R�[�h
--     ,bank_name               -- ��s��
--     ,branch_code             -- �x�X�R�[�h
--     ,branch_name             -- �x�X��
--     ,bank_holder_name_alt    -- ������
--     ,tax_div                 -- �ŋ敪
--     ,target_div              -- �Ώۋ敪
--     ,created_by              -- �쐬��
--     ,creation_date           -- �쐬��
--     ,last_updated_by         -- �ŏI�X�V��
--     ,last_update_date        -- �ŏI�X�V��
--     ,last_update_login       -- �ŏI�X�V���O�C��
--     ,request_id              -- �v��ID
--     ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--     ,program_id              -- �R���J�����g�E�v���O����ID
--     ,program_update_date     -- �v���O�����X�V��
--    )
--    SELECT
--        /*+ INDEX(xirh1 xxcok_info_rev_head_n01)
--            INDEX(xirh2 xxcok_info_rev_head_n02) */
--        xirh1.snapshot_create_ym                   AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--       ,iv_proc_div                                AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--       ,'2'                                        AS  rev                     -- REV�i2:�ԁiFB�j)
--       ,'0'                                        AS  check_result            -- �Ó����`�F�b�N����
--       ,NULL                                       AS  row_id                  -- ���e�[�u�����R�[�hID
--       ,NULL                                       AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
--       ,xirh1.vendor_code                          AS  vendor_code             -- ���t��R�[�h
--       ,xirh1.set_code                             AS  set_code                -- �ʒm�������ݒ�R�[�h
--       ,xirh1.cust_code                            AS  cust_code               -- �ڋq�R�[�h
--       ,xirh1.cust_name                            AS  cust_name               -- ��Ж�
--       ,xirh1.dest_post_code                       AS  dest_post_code          -- �X�֔ԍ�
--       ,xirh1.dest_address1                        AS  dest_address1           -- �Z��
--       ,xirh1.dest_tel                             AS  dest_tel                -- �d�b�ԍ�
--       ,xirh1.fax                                  AS  fax                     -- FAX�ԍ�
--       ,xirh1.dept_name                            AS  dept_name               -- ������
--       ,xirh1.send_post_code                       AS  send_post_code          -- �X�֔ԍ��i���t���j
--       ,xirh1.send_address1                        AS  send_address1           -- �Z���i���t���j
--       ,xirh1.send_tel                             AS  send_tel                -- �d�b�ԍ��i���t���j
--       ,xirh1.num                                  AS  num                     -- �ԍ�
--       ,xirh1.payment_date                         AS  payment_date            -- �x����
--       ,xirh1.closing_date                         AS  closing_date            -- ���ߓ�
--       ,xirh1.closing_date_min                     AS  closing_date_min        -- �ŏ����ߓ�
--       ,(xirh1.notifi_amt) * -1                    AS  notifi_amt              -- �����Ă̒ʒm���z
--       ,(xirh1.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
--       ,(xirh1.tax_amt_8) * -1                     AS  tax_amt_8               -- �y��8%����Ŋz
--       ,(xirh1.total_amt_8) * -1                   AS  total_amt_8             -- �y��8%���v���z�i�ō��j
--       ,(xirh1.total_sales_qty) * -1               AS  total_sales_qty         -- �̔��{�����v
--       ,(xirh1.total_sales_amt) * -1               AS  total_sales_amt         -- �̔����z���v
--       ,(xirh1.sales_fee) * -1                     AS  sales_fee               -- �̔��萔��
--       ,(xirh1.electric_amt) * -1                  AS  electric_amt            -- �d�C�㓙���v �Ŕ�
--       ,(xirh1.tax_amt) * -1                       AS  tax_amt                 -- �����
--       ,(xirh1.transfer_fee) * -1                  AS  transfer_fee            -- �U���萔�� �ō�
--       ,(xirh1.payment_amt) * -1                   AS  payment_amt             -- ���x�����z �ō�
--       ,'"'||SUBSTR(gv_remarks_fb_deb,1,500)||'"'  AS  remarks                 -- �����Ĕ��l
--       ,xirh1.bank_code                            AS  bank_code               -- ��s�R�[�h
--       ,xirh1.bank_name                            AS  bank_name               -- ��s��
--       ,xirh1.branch_code                          AS  branch_code             -- �x�X�R�[�h
--       ,xirh1.branch_name                          AS  branch_name             -- �x�X��
--       ,xirh1.bank_holder_name_alt                 AS  bank_holder_name_alt    -- ������
--       ,xirh1.tax_div                              AS  tax_div                 -- �ŋ敪
--       ,xirh1.target_div                           AS  target_div              -- �Ώۋ敪
--       ,cn_created_by                              AS  created_by              -- �쐬��
--       ,SYSDATE                                    AS  creation_date           -- �쐬��
--       ,cn_last_updated_by                         AS  last_updated_by         -- �ŏI�X�V��
--       ,SYSDATE                                    AS  last_update_date        -- �ŏI�X�V��
--       ,cn_last_update_login                       AS  last_update_login       -- �ŏI�X�V���O�C��
--       ,cn_request_id                              AS  request_id              -- �v��ID
--       ,cn_program_application_id                  AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--       ,cn_program_id                              AS  program_id              -- �R���J�����g�E�v���O����ID
--       ,SYSDATE                                    AS  program_update_date     -- �v���O�����X�V��
--    FROM   xxcok_info_rev_header    xirh1  -- ����
--          ,xxcok_info_rev_header    xirh2  -- �V��
--    WHERE  xirh2.snapshot_create_ym                =  gv_process_ym
--    AND    xirh2.snapshot_timing                   =  iv_proc_div
--    AND    xirh2.rev                               =  '3' -- �V���iFB�j
--    AND    xirh2.check_result                      =  '0' -- �Ώ�
--    AND    xirh2.notifi_amt                        >  0
--    AND    xirh1.vendor_code                       =  xirh2.vendor_code
--    AND    xirh1.snapshot_create_ym                =  xirh2.snapshot_create_ym
--    AND    xirh1.snapshot_timing                   =  '1' -- 2�c
--    AND    xirh1.rev                               =  '1' -- �����i2�c�j
--    AND    xirh1.notifi_amt                        >  0
--    ;
----
--    -- �ԃf�[�^�쐬�����J�E���g
--    gn_debit_cnt := SQL%ROWCOUNT;
--
--    -- ������������̂ŐԂ��쐬����Ă��Ȃ��d�����o�^����
--    FOR i IN 1..i_no_dif_sup_tab.COUNT LOOP
--      -- �ԃf�[�^���쐬����Ă��邩�`�F�b�N
--      SELECT COUNT(1)
--      INTO   ln_count
--      FROM   xxcok_info_rev_header  xirh   -- �V��
--      WHERE  xirh.snapshot_create_ym     = gv_process_ym
--      AND    xirh.snapshot_timing        = iv_proc_div
--      AND    xirh.rev                    = '2' -- �ԁiFB�j
--      AND    xirh.check_result           = '0' -- �Ώ�
--      AND    xirh.vendor_code            = i_no_dif_sup_tab(i).supplier_code
--      ;
--
--      -- �쐬����Ă��Ȃ��ꍇ�쐬
--      IF ( ln_count = 0 ) THEN
-- Els Ver1.1 K.Kanada E
--
-- Add Ver1.1 K.Kanada S
    -- ����������d����̐Ԃ�o�^����
    FOR i IN 1..i_dif_sup_tab.COUNT LOOP
-- Add Ver1.1 K.Kanada E
--
      INSERT INTO xxcok_info_rev_header(
        snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
       ,snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
       ,rev                     -- REV
       ,check_result            -- �Ó����`�F�b�N����
       ,row_id                  -- ���e�[�u�����R�[�hID
       ,edi_interface_date      -- �A�g���iEDI�x���ē����j
       ,vendor_code             -- ���t��R�[�h
       ,set_code                -- �ʒm�������ݒ�R�[�h
       ,cust_code               -- �ڋq�R�[�h
       ,cust_name               -- ��Ж�
       ,dest_post_code          -- �X�֔ԍ�
       ,dest_address1           -- �Z��
       ,dest_tel                -- �d�b�ԍ�
       ,fax                     -- FAX�ԍ�
       ,dept_name               -- ������
       ,send_post_code          -- �X�֔ԍ��i���t���j
       ,send_address1           -- �Z���i���t���j
       ,send_tel                -- �d�b�ԍ��i���t���j
       ,num                     -- �ԍ�
       ,payment_date            -- �x����
       ,closing_date            -- ���ߓ�
       ,closing_date_min        -- �ŏ����ߓ�
       ,notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
       ,total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
       ,tax_amt_10              -- 10%����Ŋz
       ,total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
       ,total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
       ,tax_amt_8               -- �y��8%����Ŋz
       ,total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
       ,total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
       ,tax_amt_0               -- ��ېŏ���Ŋz
       ,total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
       ,total_sales_qty         -- �̔��{�����v
       ,total_sales_amt         -- �̔����z���v
       ,sales_fee               -- �̔��萔��
       ,electric_amt            -- �d�C�㓙���v�@�Ŕ�
       ,tax_amt                 -- �����
       ,transfer_fee            -- �U���萔�� �ō�
       ,payment_amt             -- ���x�����z �ō�
       ,remarks                 -- �����Ĕ��l
       ,bank_code               -- ��s�R�[�h
       ,bank_name               -- ��s��
       ,branch_code             -- �x�X�R�[�h
       ,branch_name             -- �x�X��
       ,bank_holder_name_alt    -- ������
       ,tax_div                 -- �ŋ敪
       ,target_div              -- �Ώۋ敪
       ,created_by              -- �쐬��
       ,creation_date           -- �쐬��
       ,last_updated_by         -- �ŏI�X�V��
       ,last_update_date        -- �ŏI�X�V��
       ,last_update_login       -- �ŏI�X�V���O�C��
       ,request_id              -- �v��ID
       ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id              -- �R���J�����g�E�v���O����ID
       ,program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
       ,bm_payment_kbn            -- BM�x���敪
       ,tax_calc_kbn              -- �Ōv�Z�敪
       ,bm_tax_kbn                -- BM�ŋ敪
       ,bank_charge_bearer        -- �U���萔�����S��
       ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
       ,sales_fee_tax             -- �̔��萔���i����Łj
       ,sales_fee_with_tax        -- �̔��萔���i�ō��j
       ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
       ,electric_amt_tax          -- �d�C�㓙�i����Łj
       ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
       ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
       ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
       ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
       ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
       ,bank_trans_fee_tax        -- �U���萔���i����Łj
       ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
       ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
       ,display_code              -- �\���R�[�h
       ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      )
      SELECT
          /*+ INDEX(xirh xxcok_info_rev_head_n03) */
          xirh.snapshot_create_ym                    AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
         ,iv_proc_div                                AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
         ,'2'                                        AS  rev                     -- REV�i2:�ԁiFB�j)
-- Ver.1.2 MOD START
--         ,'0'                                        AS  check_result            -- �Ó����`�F�b�N����
         ,CASE
            WHEN xirh.bm_payment_kbn = '1' THEN  -- BM�x���敪(2�c)���{�U(�ē�������)�̏ꍇ
              '0'  -- �Ώ�
            ELSE
              '1'  -- �ΏۊO
          END                                        AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
         ,NULL                                       AS  row_id                  -- ���e�[�u�����R�[�hID
         ,NULL                                       AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
         ,xirh.vendor_code                           AS  vendor_code             -- ���t��R�[�h
         ,xirh.set_code                              AS  set_code                -- �ʒm�������ݒ�R�[�h
         ,xirh.cust_code                             AS  cust_code               -- �ڋq�R�[�h
         ,xirh.cust_name                             AS  cust_name               -- ��Ж�
         ,xirh.dest_post_code                        AS  dest_post_code          -- �X�֔ԍ�
         ,xirh.dest_address1                         AS  dest_address1           -- �Z��
         ,xirh.dest_tel                              AS  dest_tel                -- �d�b�ԍ�
         ,xirh.fax                                   AS  fax                     -- FAX�ԍ�
         ,xirh.dept_name                             AS  dept_name               -- ������
         ,xirh.send_post_code                        AS  send_post_code          -- �X�֔ԍ��i���t���j
         ,xirh.send_address1                         AS  send_address1           -- �Z���i���t���j
         ,xirh.send_tel                              AS  send_tel                -- �d�b�ԍ��i���t���j
         ,xirh.num                                   AS  num                     -- �ԍ�
         ,xirh.payment_date                          AS  payment_date            -- �x����
         ,xirh.closing_date                          AS  closing_date            -- ���ߓ�
         ,xirh.closing_date_min                      AS  closing_date_min        -- �ŏ����ߓ�
         ,(xirh.notifi_amt) * -1                     AS  notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
         ,(xirh.total_amt_no_tax_10) * -1            AS  total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
         ,(xirh.tax_amt_10) * -1                     AS  tax_amt_10              -- 10%����Ŋz
         ,(xirh.total_amt_10) * -1                   AS  total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
         ,(xirh.total_amt_no_tax_8) * -1             AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
         ,(xirh.tax_amt_8) * -1                      AS  tax_amt_8               -- �y��8%����Ŋz
         ,(xirh.total_amt_8) * -1                    AS  total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
         ,(xirh.total_amt_no_tax_0) * -1             AS  total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
         ,(xirh.tax_amt_0) * -1                      AS  tax_amt_0               -- ��ېŏ���Ŋz
         ,(xirh.total_amt_0) * -1                    AS  total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
         ,(xirh.total_sales_qty) * -1                AS  total_sales_qty         -- �̔��{�����v
         ,(xirh.total_sales_amt) * -1                AS  total_sales_amt         -- �̔����z���v
         ,(xirh.sales_fee) * -1                      AS  sales_fee               -- �̔��萔��
         ,(xirh.electric_amt) * -1                   AS  electric_amt            -- �d�C�㓙���v �Ŕ�
         ,(xirh.tax_amt) * -1                        AS  tax_amt                 -- �����
         ,(xirh.transfer_fee) * -1                   AS  transfer_fee            -- �U���萔�� �ō�
         ,(xirh.payment_amt) * -1                    AS  payment_amt             -- ���x�����z �ō�
         ,'"'||SUBSTR(gv_remarks_fb_deb,1,500)||'"'  AS  remarks                 -- �����Ĕ��l
         ,xirh.bank_code                             AS  bank_code               -- ��s�R�[�h
         ,xirh.bank_name                             AS  bank_name               -- ��s��
         ,xirh.branch_code                           AS  branch_code             -- �x�X�R�[�h
         ,xirh.branch_name                           AS  branch_name             -- �x�X��
         ,xirh.bank_holder_name_alt                  AS  bank_holder_name_alt    -- ������
         ,xirh.tax_div                               AS  tax_div                 -- �ŋ敪
         ,xirh.target_div                            AS  target_div              -- �Ώۋ敪
         ,cn_created_by                              AS  created_by              -- �쐬��
         ,SYSDATE                                    AS  creation_date           -- �쐬��
         ,cn_last_updated_by                         AS  last_updated_by         -- �ŏI�X�V��
         ,SYSDATE                                    AS  last_update_date        -- �ŏI�X�V��
         ,cn_last_update_login                       AS  last_update_login       -- �ŏI�X�V���O�C��
         ,cn_request_id                              AS  request_id              -- �v��ID
         ,cn_program_application_id                  AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                              AS  program_id              -- �R���J�����g�E�v���O����ID
         ,SYSDATE                                    AS  program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
         ,xirh.bm_payment_kbn                        AS  bm_payment_kbn            -- BM�x���敪
         ,xirh.tax_calc_kbn                          AS  tax_calc_kbn              -- �Ōv�Z�敪
         ,xirh.bm_tax_kbn                            AS  bm_tax_kbn                -- BM�ŋ敪
         ,xirh.bank_charge_bearer                    AS  bank_charge_bearer        -- �U���萔�����S��
         ,(xirh.sales_fee_no_tax) * -1               AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
         ,(xirh.sales_fee_tax) * -1                  AS  sales_fee_tax             -- �̔��萔���i����Łj
         ,(xirh.sales_fee_with_tax) * -1             AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
         ,(xirh.electric_amt_no_tax) * -1            AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
         ,(xirh.electric_amt_tax) * -1               AS  electric_amt_tax          -- �d�C�㓙�i����Łj
         ,(xirh.electric_amt_with_tax) * -1          AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
         ,(xirh.recalc_total_fee_no_tax) * -1        AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
         ,(xirh.recalc_total_fee_tax) * -1           AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
         ,(xirh.recalc_total_fee_with_tax) * -1      AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
         ,(xirh.bank_trans_fee_no_tax) * -1          AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
         ,(xirh.bank_trans_fee_tax) * -1             AS  bank_trans_fee_tax        -- �U���萔���i����Łj
         ,(xirh.bank_trans_fee_with_tax) * -1        AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
         ,xirh.vendor_invoice_regnum                 AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
         ,xirh.display_code                          AS  display_code              -- �\���R�[�h
         ,xirh.company_code_bd                       AS  company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
      FROM   xxcok_info_rev_header    xirh  -- ����
      WHERE  xirh.snapshot_create_ym                = gv_process_ym
      AND    xirh.snapshot_timing                   = '1' -- 2�c
      AND    xirh.rev                               = '1' -- �����i2�c�j
-- Mod Ver1.1 K.Kanada S
--      AND    xirh.vendor_code                       = i_no_dif_sup_tab(i).supplier_code
      AND    xirh.vendor_code                       = i_dif_sup_tab(i).supplier_code
-- Mod Ver1.1 K.Kanada E
      AND    xirh.notifi_amt                        > 0
      ;
--
      -- �ԃf�[�^�쐬�����J�E���g
      gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
--      END IF;         -- Els Ver1.1 K.Kanada
    END LOOP;
--
    INSERT INTO xxcok_info_rev_custom (
      snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
     ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
     ,rev                         -- REV
     ,check_result                -- �Ó����`�F�b�N����
     ,row_id                      -- ���e�[�u�����R�[�hID
     ,edi_interface_date          -- �A�g���iEDI�x���ē����j
     ,vendor_code                 -- ���t��R�[�h
     ,cust_code                   -- �ڋq�R�[�h
     ,inst_dest                   -- �ݒu�ꏊ
     ,calc_type                   -- �v�Z����
     ,calc_sort                   -- �v�Z�����\�[�g��
     ,sell_bottle                 -- �����^�e��
     ,sales_qty                   -- �̔��{��
     ,sales_tax_amt               -- �̔����z�i�ō��j
     ,sales_amt                   -- �̔����z�i�Ŕ��j
     ,contract                    -- ���_����e
     ,sales_fee                   -- �̔��萔���i�Ŕ��j
     ,tax_amt                     -- �����
     ,sales_tax_fee               -- �̔��萔���i�ō��j
     ,bottle_code                 -- �e��敪�R�[�h
     ,salling_price               -- �������z
     ,REBATE_RATE                 -- ���ߗ�
     ,REBATE_AMT                  -- ���ߊz
     ,tax_code                    -- �ŃR�[�h
     ,tax_div                     -- �ŋ敪
     ,target_div                  -- �Ώۋ敪
     ,created_by                  -- �쐬��
     ,creation_date               -- �쐬��
     ,last_updated_by             -- �ŏI�X�V��
     ,last_update_date            -- �ŏI�X�V��
     ,last_update_login           -- �ŏI�X�V���O�C��
     ,request_id                  -- �v��ID
     ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                  -- �R���J�����g�E�v���O����ID
     ,program_update_date         -- �v���O�����X�V��
    )
    SELECT
        xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
       ,iv_proc_div                             AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
       ,'2'                                     AS  rev                     -- REV�i2:�ԁiFB�j)
-- Ver.1.2 MOD START
--       ,'0'                                     AS  check_result            -- �Ó����`�F�b�N���ʁi0:�Ώہj
       ,xirh.check_result                       AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
       ,NULL                                    AS  row_id                  -- ���e�[�u�����R�[�hID
       ,NULL                                    AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
       ,xirc.vendor_code                        AS  vendor_code             -- ���t��R�[�h
       ,xirc.cust_code                          AS  cust_code               -- �ڋq�R�[�h
       ,xirc.inst_dest                          AS  inst_dest               -- �ݒu�ꏊ
       ,xirc.calc_type                          AS  calc_type               -- �v�Z����
       ,xirc.calc_sort                          AS  calc_sort               -- �v�Z�����\�[�g��
       ,xirc.sell_bottle                        AS  sell_bottle             -- �����^�e��
       ,(xirc.sales_qty) * -1                   AS  sales_qty               -- �̔��{��
       ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- �̔����z�i�ō��j
       ,(xirc.sales_amt) * -1                   AS  sales_amt               -- �̔����z�i�Ŕ��j
       ,xirc.contract                           AS  contract                -- ���_����e
       ,(xirc.sales_fee) * -1                   AS  sales_fee               -- �̔��萔���i�Ŕ��j
       ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- �����
       ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- �̔��萔���i�ō��j
       ,xirc.bottle_code                        AS  bottle_code             -- �e��敪�R�[�h
       ,xirc.salling_price                      AS  salling_price           -- �������z
       ,xirc.rebate_rate                        AS  rebate_rate             -- ���ߗ�
       ,xirc.rebate_amt                         AS  rebate_amt              -- ���ߊz
       ,xirc.tax_code                           AS  tax_code                -- �ŃR�[�h
       ,xirc.tax_div                            AS  tax_div                 -- �ŋ敪
       ,xirc.target_div                         AS  target_div              -- �Ώۋ敪
       ,cn_created_by                           AS  created_by              -- �쐬��
       ,SYSDATE                                 AS  creation_date           -- �쐬��
       ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
       ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
       ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
       ,cn_request_id                           AS  request_id              -- �v��ID
       ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
       ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
       ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
    FROM   xxcok_info_rev_header     xirh  -- �J�X�^���w�b�_�[:FB(��)              -- Mod Ver1.1 K.Kanada
          ,xxcok_info_rev_custom     xirc  -- �J�X�^������:����
    WHERE  xirh.snapshot_create_ym                 = gv_process_ym
    AND    xirh.snapshot_timing                    = '2' -- FB
    AND    xirh.rev                                = '2' -- �ԁiFB�j
-- Ver.1.2 DEL START
--    AND    xirh.check_result                       = '0' -- �Ώ�
-- Ver.1.2 DEL END
    AND    xirh.vendor_code                        = xirc.vendor_code
    AND    xirh.snapshot_create_ym                 = xirc.snapshot_create_ym
    AND    xirc.snapshot_timing                    = '1' -- 2�c
    AND    xirc.rev                                = '1' -- �����i2�c�j
    ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_debit_fb;
--
  /**********************************************************************************
   * Procedure Name   : ins_credit_header
   * Description      : �V���w�b�_�[���쐬(A-9)
   ***********************************************************************************/
  PROCEDURE ins_credit_header(
    iv_proc_div   IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_credit_header';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver.1.2 ADD START
    ln_recalc_total_fee_no_tax      NUMBER  DEFAULT 0;    -- �Čv�Z�ώ萔���v�i�Ŕ��j
    ln_recalc_total_fee_tax         NUMBER  DEFAULT 0;    -- �Čv�Z�ώ萔���v�i����Łj
    ln_recalc_total_fee_with_tax    NUMBER  DEFAULT 0;    -- �Čv�Z�ώ萔���v�i�ō��j
    ln_bank_trans_fee_no_tax        NUMBER  DEFAULT 0;    -- �U���萔���i�Ŕ��j
    ln_bank_trans_fee_tax           NUMBER  DEFAULT 0;    -- �U���萔���i����Łj
    ln_bank_trans_fee_with_tax      NUMBER  DEFAULT 0;    -- �U���萔���i�ō��j
    ln_total_amt_no_tax_10          NUMBER  DEFAULT 0;    -- 10%���v���z�i�Ŕ��j
    ln_tax_amt_10                   NUMBER  DEFAULT 0;    -- 10%����Ŋz
    ln_total_amt_10                 NUMBER  DEFAULT 0;    -- 10%���v���z�i�ō��j
    ln_total_amt_no_tax_0           NUMBER  DEFAULT 0;    -- ��ېō��v���z�i�Ŕ��j
    ln_tax_amt_0                    NUMBER  DEFAULT 0;    -- ��ېŏ���Ŋz
    ln_total_amt_0                  NUMBER  DEFAULT 0;    -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
--
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
-- Els Ver1.1 K.Kanada S
--    -- ���o�ΏۊO�擾
--    CURSOR l_check_ex_cur
--    IS
--      SELECT xirh2.vendor_code        AS  vendor_code
--      FROM   xxcok_info_rev_header    xirh1  -- ����
--            ,xxcok_info_rev_header    xirh2  -- �V��
--      WHERE  xirh2.snapshot_create_ym = gv_process_ym
--      AND    xirh2.snapshot_timing    = iv_proc_div
--      AND    xirh2.rev                = '3'  -- �V���iFB�j
--      AND    xirh2.request_id         = cn_request_id
--      AND    xirh2.notifi_amt         <= 0
--      AND    xirh1.snapshot_create_ym = xirh2.snapshot_create_ym
--      AND    xirh1.snapshot_timing    = '1'  -- 2�c
--      AND    xirh1.rev                = '1'  -- �����i2�c�j
--      AND    xirh1.vendor_code        = xirh2.vendor_code
--      AND    xirh1.notifi_amt         <= 0
--      ;
----
--    l_check_ex_rec    l_check_ex_cur%ROWTYPE;
-- Els Ver1.1 K.Kanada E
--
-- Ver.1.2 ADD START
    CURSOR l_update_xirh_cur
    IS
      SELECT xirh.rowid                      AS  row_id                     -- ROWID
            ,xirh.bm_payment_kbn             AS  bm_payment_kbn             -- BM�x���敪
            ,xirh.tax_calc_kbn               AS  tax_calc_kbn               -- �Ōv�Z�敪
            ,xirh.bm_tax_kbn                 AS  bm_tax_kbn                 -- BM�ŋ敪
            ,xirh.bank_charge_bearer         AS  bank_charge_bearer         -- �U���萔�����S��
            ,xirh.recalc_total_fee_no_tax    AS  recalc_total_fee_no_tax    -- �Čv�Z�ώ萔���v�i�Ŕ��j
            ,xirh.recalc_total_fee_tax       AS  recalc_total_fee_tax       -- �Čv�Z�ώ萔���v�i����Łj
            ,xirh.recalc_total_fee_with_tax  AS  recalc_total_fee_with_tax  -- �Čv�Z�ώ萔���v�i�ō��j
      FROM   xxcok_info_rev_header xirh    -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
      WHERE  xirh.snapshot_create_ym = gv_process_ym
      AND    xirh.snapshot_timing    = iv_proc_div
      AND    xirh.rev                = '3' -- �V���iFB�j
      AND    xirh.request_id         = cn_request_id
   ;
-- Ver.1.2 ADD END
--
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �w�b�_�[���o�^
    -- ===============================================
    INSERT INTO xxcok_info_rev_header(
      snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
     ,snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
     ,rev                     -- REV
     ,check_result            -- �Ó����`�F�b�N����
     ,row_id                  -- ���e�[�u�����R�[�hID
     ,edi_interface_date      -- �A�g���iEDI�x���ē����j
     ,set_code                -- �ʒm�������ݒ�R�[�h
     ,cust_code               -- �ڋq�R�[�h
     ,cust_name               -- ��Ж�
     ,dest_post_code          -- �X�֔ԍ�
     ,dest_address1           -- �Z��
     ,dest_tel                -- �d�b�ԍ�
     ,fax                     -- FAX�ԍ�
     ,dept_name               -- ������
     ,send_post_code          -- �X�֔ԍ��i���t���j
     ,send_address1           -- �Z���i���t���j
     ,send_tel                -- �d�b�ԍ��i���t���j
     ,num                     -- �ԍ�
     ,vendor_code             -- ���t��R�[�h
     ,payment_date            -- �x����
     ,closing_date            -- ���ߓ�
     ,closing_date_min        -- �ŏ����ߓ�
     ,notifi_amt              -- �����Ă̒ʒm���z
     ,total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
     ,tax_amt_8               -- �y��8%����Ŋz
     ,total_amt_8             -- �y��8%���v���z�i�ō��j
     ,total_sales_qty         -- �̔��{�����v
     ,total_sales_amt         -- �̔����z���v
     ,sales_fee               -- �̔��萔��
     ,electric_amt            -- �d�C�㓙���v�@�Ŕ�
     ,tax_amt                 -- �����
     ,transfer_fee            -- �U���萔���@�ō�
     ,payment_amt             -- ���x�����z�@�ō�
     ,remarks                 -- �����Ĕ��l
     ,bank_code               -- ��s�R�[�h
     ,bank_name               -- ��s��
     ,branch_code             -- �x�X�R�[�h
     ,branch_name             -- �x�X��
     ,bank_holder_name_alt    -- ������
     ,tax_div                 -- �ŋ敪
     ,target_div              -- �Ώۋ敪
     ,created_by              -- �쐬��
     ,creation_date           -- �쐬��
     ,last_updated_by         -- �ŏI�X�V��
     ,last_update_date        -- �ŏI�X�V��
     ,last_update_login       -- �ŏI�X�V���O�C��
     ,request_id              -- �v��ID
     ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id              -- �R���J�����g�E�v���O����ID
     ,program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
     ,bm_payment_kbn            -- BM�x���敪
     ,tax_calc_kbn              -- �Ōv�Z�敪
     ,bm_tax_kbn                -- BM�ŋ敪
     ,bank_charge_bearer        -- �U���萔�����S��
     ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
     ,sales_fee_tax             -- �̔��萔���i����Łj
     ,sales_fee_with_tax        -- �̔��萔���i�ō��j
     ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
     ,electric_amt_tax          -- �d�C�㓙�i����Łj
     ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
     ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
     ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
     ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
     ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
     ,bank_trans_fee_tax        -- �U���萔���i����Łj
     ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
     ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
     ,display_code              -- �\���R�[�h
     ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
    )
-- Mod Ver1.1 K.Kanada S
--    SELECT  /*+ leading(xirh xbbs xirc sum_t sum_ne sum_e) use_nl(xbbs) use_nl(sum_t) use_nl(sum_ne) use_nl(sum_e) */
--            xbbs.snapshot_create_ym               AS  snapshot_create_ym
--           ,xbbs.snapshot_timing                  AS  snapshot_timing
    SELECT  /*+ leading(xirh pv pvsa xirc sum_t sum_ne sum_e) use_nl(pv) use_nl(pvsa) use_nl(sum_t) use_nl(sum_ne) use_nl(sum_e) */
            gv_process_ym                         AS  snapshot_create_ym
           ,iv_proc_div                           AS  snapshot_timing
-- Mod Ver1.1 K.Kanada E
           ,'3'                                   AS  rev
-- Ver.1.2 MOD START
--           ,'0'                                   AS  check_result
           ,CASE
              WHEN MAX(xirh.bm_payment_kbn) = '1' THEN  -- BM�x���敪(2�c)���{�U(�ē�������)�̏ꍇ
                '0'  -- �Ώ�
              ELSE
                '1'  -- �ΏۊO
            END                                   AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,NULL                                  AS  row_id
           ,NULL                                  AS  edi_interface_date
-- Ver.1.3 Mod Start
--           ,CASE
--              WHEN xirh.tax_div = '1' AND NVL(sum_e.sales_fee,0) = 0
--              THEN '0'
--              WHEN xirh.tax_div = '1' AND NVL(sum_e.sales_fee,0) <> 0
--              THEN '1'
--              WHEN xirh.tax_div = '2' AND NVL(sum_e.sales_fee,0) = 0
--              THEN '2'
--              WHEN xirh.tax_div = '2' AND NVL(sum_e.sales_fee,0) <> 0
--              THEN '3'
--            END                                   AS  set_code                -- �ʒm�������ݒ�R�[�h
           ,( SELECT flv.lookup_code        AS set_code
              FROM   fnd_lookup_values flv
              WHERE  flv.lookup_type        = cv_xxcok1_set_code
              AND    flv.language           = 'JA'
              AND    flv.attribute1         = xirh.tax_div
              AND    flv.attribute2         = xbdciv.company_code_bd
              AND    flv.attribute3         = CASE
                                                WHEN NVL(sum_e.sales_fee,0) = 0
                                                THEN '0'
                                                WHEN NVL(sum_e.sales_fee,0) <> 0
                                                THEN '1'
                                              END
            )                                     AS  set_code                -- �ʒm�������ݒ�R�[�h
-- Ver.1.3 Mod End
           ,NULL                                  AS  cust_code               -- �ڋq�R�[�h
           ,xirh.cust_name                        AS  cust_name               -- ��Ж�
           ,xirh.dest_post_code                   AS  dest_post_code          -- �X�֔ԍ�
           ,xirh.dest_address1                    AS  dest_address1           -- �Z��
           ,xirh.dest_tel                         AS  dest_tel                -- �d�b�ԍ�
           ,xirh.fax                              AS  fax                     -- FAX�ԍ�
           ,xirh.dept_name                        AS  dept_name               -- ������
           ,xirh.send_post_code                   AS  send_post_code          -- �X�֔ԍ��i���t���j
           ,xirh.send_address1                    AS  send_address1           -- �Z���i���t���j
           ,xirh.send_tel                         AS  send_tel                -- �d�b�ԍ��i���t���j
-- Mod Ver1.1 K.Kanada S
--           ,xbbs.supplier_code                    AS  num                     -- �ԍ�
--           ,xbbs.supplier_code                    AS  vendor_code             -- ���t��R�[�h
--           ,xirh.payment_date                     AS  payment_date            -- �x����
--           ,MAX(xbbs.closing_date)                AS  closing_date            -- ���ߓ�
--           ,MIN(xbbs.closing_date)                AS  closing_date_min        -- �ŏ����ߓ�
--           ,CASE
--              -- �O��
--              WHEN xirh.tax_div = '1'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       + NVL(sum_t.tax_amt,0)
--                       - CASE
--                           WHEN xbbs.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--              --����
--              WHEN xirh.tax_div = '2'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       - CASE
--                           WHEN xbbs.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--            END                                   AS  notifi_amt              -- �����Ă̒ʒm���z
           ,xirh.vendor_code                      AS  num                     -- �ԍ�
           ,xirh.vendor_code                      AS  vendor_code             -- ���t��R�[�h
           ,xirh.payment_date                     AS  payment_date            -- �x����
           ,( SELECT MAX(xbbs.closing_date)   AS  closing_date
              FROM   xxcok_bm_balance_snap    xbbs
              WHERE  xbbs.snapshot_create_ym  = xirh.snapshot_create_ym
              AND    xbbs.snapshot_timing     = iv_proc_div
              AND    xbbs.supplier_code       = xirh.vendor_code
              -- FB�x���ςݏ���
              AND    xbbs.closing_date <= gd_closing_date          -- �O������
              AND    xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
              AND    xbbs.fb_interface_status  = '1'               -- FB�A�g��
              AND    xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
              AND    xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
              AND    xbbs.payment_amt_tax > 0                      -- FB�x����
              GROUP BY
                     xbbs.snapshot_create_ym
                    ,xbbs.snapshot_timing
                    ,xbbs.supplier_code
              )                                   AS  closing_date            -- ���ߓ�
           ,( SELECT MIN(xbbs.closing_date)   AS  closing_date_min
              FROM   xxcok_bm_balance_snap    xbbs
              WHERE  xbbs.snapshot_create_ym  = xirh.snapshot_create_ym
              AND    xbbs.snapshot_timing     = iv_proc_div
              AND    xbbs.supplier_code       = xirh.vendor_code
              -- FB�x���ςݏ���
              AND    xbbs.closing_date <= gd_closing_date          -- �O������
              AND    xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
              AND    xbbs.fb_interface_status  = '1'               -- FB�A�g��
              AND    xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
              AND    xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
              AND    xbbs.payment_amt_tax > 0                      -- FB�x����
              GROUP BY
                     xbbs.snapshot_create_ym
                    ,xbbs.snapshot_timing
                    ,xbbs.supplier_code
              )                                   AS  closing_date_min        -- �ŏ����ߓ�
-- Ver.1.2 MOD START
--           ,CASE
--              -- �O��
--              WHEN xirh.tax_div = '1'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       + NVL(sum_t.tax_amt,0)
--                       - CASE
--                           WHEN pvsa.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--              --����
--              WHEN xirh.tax_div = '2'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       - CASE
--                           WHEN pvsa.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--            END                                   AS  notifi_amt              -- �����Ă̒ʒm���z
           ,NULL                                  AS  notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 MOD END
-- Mod Ver1.1 K.Kanada E
           ,NVL(sum_t.sales_amt,0)                AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
           ,NVL(sum_t.sales_tax_amt,0) - NVL(sum_t.sales_amt,0)
                                                  AS  tax_amt_8               -- �y��8%����Ŋz
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_amt_8             -- �y��8%���v���z�i�ō��j
           ,NVL(sum_t.sales_qty,0)                AS  total_sales_qty         -- �̔��{�����v
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_sales_amt         -- �̔����z���v
           ,NVL(sum_ne.sales_fee,0)               AS  sales_fee               -- �̔��萔�� �Ŕ��^�̔��萔�� �ō�
           ,NVL(sum_e.sales_fee,0)                AS  electric_amt            -- �d�C�㓙���v �Ŕ��^�d�C�㓙���v �ō�
           ,NVL(sum_t.tax_amt,0)                  AS  tax_amt                 -- ����Ł^�������
-- Mod Ver1.1 K.Kanada S
--           ,CASE
--              WHEN xbbs.bank_charge_bearer = 'I'
--              THEN 0
--              -- �O��
--              WHEN xirh.tax_div = '1'
--                  AND xbbs.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--              THEN gn_tax_include_less
--              WHEN    xirh.tax_div = '1'
--                  AND xbbs.bank_charge_bearer <> 'I' 
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--              THEN gn_tax_include_more
--              --����
--              WHEN    xirh.tax_div = '2'
--                  AND xbbs.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--              THEN gn_tax_include_less
--              WHEN    xirh.tax_div = '2'
--                  AND xbbs.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--              THEN gn_tax_include_more
--            END * -1                              AS  transfer_fee            -- �U���萔�� �ō�
--           ,CASE
--              -- �O��
--              WHEN xirh.tax_div = '1'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       + NVL(sum_t.tax_amt,0)
--                       - CASE
--                           WHEN xbbs.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--              --����
--              WHEN xirh.tax_div = '2'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       - CASE
--                           WHEN xbbs.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    xbbs.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--            END                                   AS  payment_amt             -- ���x�����z �ō�
-- Ver.1.2 MOD START
--           ,CASE
--              WHEN pvsa.bank_charge_bearer = 'I'
--              THEN 0
--              -- �O��
--              WHEN xirh.tax_div = '1'
--                  AND pvsa.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--              THEN gn_tax_include_less
--              WHEN    xirh.tax_div = '1'
--                  AND pvsa.bank_charge_bearer <> 'I' 
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--              THEN gn_tax_include_more
--              --����
--              WHEN    xirh.tax_div = '2'
--                  AND pvsa.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--              THEN gn_tax_include_less
--              WHEN    xirh.tax_div = '2'
--                  AND pvsa.bank_charge_bearer <> 'I'
--                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--              THEN gn_tax_include_more
--            END * -1                              AS  transfer_fee            -- �U���萔�� �ō�
           ,NULL                                  AS  transfer_fee            -- �U���萔�� �ō�
-- Ver.1.2 MOD END
-- Ver.1.2 MOD START
--           ,CASE
--              -- �O��
--              WHEN xirh.tax_div = '1'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       + NVL(sum_t.tax_amt,0)
--                       - CASE
--                           WHEN pvsa.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--              --����
--              WHEN xirh.tax_div = '2'
--              THEN NVL(  NVL(sum_ne.sales_fee,0)
--                       + NVL(sum_e.sales_fee,0)
--                       - CASE
--                           WHEN pvsa.bank_charge_bearer = 'I'
--                           THEN 0
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
--                           THEN gn_tax_include_less
--                           WHEN    pvsa.bank_charge_bearer <> 'I' 
--                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
--                           THEN gn_tax_include_more
--                         END
--                      , 0)
--            END                                   AS  payment_amt             -- ���x�����z �ō�
           ,NULL                                  AS  payment_amt             -- ���x�����z �ō�
-- Ver.1.2 MOD END
-- Mod Ver1.1 K.Kanada E
           ,SUBSTR( '"' || gv_remarks_new_cre || '"', 1, 500 )
                                                  AS  remarks                 -- �����Ĕ��l
           ,NULL                                  AS  bank_code               -- ��s�R�[�h
           ,NULL                                  AS  bank_name               -- ��s��
           ,NULL                                  AS  branch_code             -- �x�X�R�[�h
           ,NULL                                  AS  branch_name             -- �x�X��
           ,NULL                                  AS  bank_holder_name_alt    -- ������
           ,xirh.tax_div                          AS  tax_div                 -- �ŋ敪
           ,xirh.target_div                       AS  target_div              -- �Ώۋ敪
           ,cn_created_by                         AS  created_by              -- �쐬��
           ,SYSDATE                               AS  creation_date           -- �쐬��
           ,cn_last_updated_by                    AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                               AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                  AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                         AS  request_id              -- �v��ID
           ,cn_program_application_id             AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                         AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                               AS  program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
           ,MAX(pvsa.attribute4)                  AS  bm_payment_kbn            -- BM�x���敪
           ,MAX(xirh.tax_calc_kbn)                AS  tax_calc_kbn              -- �Ōv�Z�敪 �i��2�c�j
           ,MAX(xirh.bm_tax_kbn)                  AS  bm_tax_kbn                -- BM�ŋ敪   �i��2�c�j
           ,pvsa.bank_charge_bearer               AS  bank_charge_bearer        -- �U���萔�����S��
           ,NVL(sum_ne.sales_fee_no_tax,0)        AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
           ,NVL(sum_ne.sales_fee_tax,0)           AS  sales_fee_tax             -- �̔��萔���i����Łj
           ,NVL(sum_ne.sales_fee_with_tax,0)      AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
           ,NVL(sum_e.electric_amt_no_tax,0)      AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
           ,NVL(sum_e.electric_amt_tax,0)         AS  electric_amt_tax          -- �d�C�㓙�i����Łj
           ,NVL(sum_e.electric_amt_with_tax,0)    AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
           ,NVL(sum_ne.sales_fee_no_tax,0) + 
              NVL(sum_e.electric_amt_no_tax,0)    AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
           ,NVL(sum_ne.sales_fee_tax,0) + 
             NVL(sum_e.electric_amt_tax,0)        AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
           ,NVL(sum_ne.sales_fee_with_tax,0) + 
             NVL(sum_e.electric_amt_with_tax,0)   AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
           ,NULL                                  AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
           ,NULL                                  AS  bank_trans_fee_tax        -- �U���萔���i����Łj
           ,NULL                                  AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
           ,(CASE
               WHEN (MAX(pvsa.attribute8) IS NOT NULL AND MAX(pvsa.attribute9) IS NOT NULL) THEN
                 -- �K�i���������s���Ǝғo�^ �{ �ېŎ��ƎҔԍ�
                 MAX(pvsa.attribute8) || MAX(pvsa.attribute9)
               ELSE
                 NULL
             END)                                 AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.8 Add Start
           ,pvsa.attribute5                       AS  display_code
           ,xbdciv.company_code_bd                AS  company_code_bd
-- Ver.1.8 Add End
-- Mod Ver1.1 K.Kanada S
--    FROM    xxcok_bm_balance_snap     xbbs        -- �̎�c���e�[�u���X�i�b�v�V���b�g
--           ,xxcok_info_rev_header     xirh        -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
    FROM    xxcok_info_rev_header     xirh     -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
           ,po_vendors                pv       -- �d����}�X�^
           ,po_vendor_sites_all       pvsa     -- �d����T�C�g
-- Mod Ver1.1 K.Kanada E
           ,(SELECT SUM(xirc.sales_qty)      AS  sales_qty
                   ,SUM(xirc.sales_tax_amt)  AS  sales_tax_amt
                   ,SUM(xirc.tax_amt)        AS  tax_amt
                   ,SUM(xirc.sales_amt)      AS  sales_amt
                   ,xirc.vendor_code         AS  vendor_code
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort = 6
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- �V���iFB�j
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
            ) sum_t                               -- �T�}���i���v�j
           ,(SELECT CASE
                      WHEN xirc.tax_div = '1'
                      THEN SUM(xirc.sales_fee)
                      WHEN xirc.tax_div = '2'
                      THEN SUM(xirc.sales_tax_fee)
                    END                     AS  sales_fee
-- Ver.1.2 ADD START
                   ,SUM(xirc.sales_fee)     AS  sales_fee_no_tax    -- �̔��萔���i�Ŕ��j
                   ,SUM(xirc.tax_amt)       AS  sales_fee_tax       -- �̔��萔���i����Łj
                   ,SUM(xirc.sales_tax_fee) AS  sales_fee_with_tax  -- �̔��萔���i�ō��j
-- Ver.1.2 ADD END
                   ,xirc.vendor_code
                   ,xirc.tax_div
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort IN (1,2,3,4) -- �����ʁA�e��ʁA�ꗥ�����A��z����
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- �V���iFB�j
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
                     ,xirc.tax_div
            ) sum_ne                              -- �T�}���i�d�C�㏜���j
           ,(SELECT CASE
                      WHEN xirc.tax_div = '1'
                      THEN SUM(xirc.sales_fee)
                      WHEN xirc.tax_div = '2'
                      THEN SUM(xirc.sales_tax_fee)
                    END                     AS  sales_fee
-- Ver.1.2 ADD START
                   ,SUM(xirc.sales_fee)     AS  electric_amt_no_tax    -- �d�C�㓙�i�Ŕ��j
                   ,SUM(xirc.tax_amt)       AS  electric_amt_tax       -- �d�C�㓙�i����Łj
                   ,SUM(xirc.sales_tax_fee) AS  electric_amt_with_tax  -- �d�C�㓙�i�ō��j
-- Ver.1.2 ADD END
                   ,xirc.vendor_code
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort = 5
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- �V���iFB�j
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
                     ,xirc.tax_div
            ) sum_e                               -- �T�}���i�d�C��j
-- Ver.1.3 Add Start
           ,xxcfr_bd_dept_comp_info_v xbdciv       -- ��������Џ��r���[
-- Ver.1.3 Add End
-- Mod Ver1.1 K.Kanada S
--    WHERE   xbbs.snapshot_create_ym                = gv_process_ym
--    AND     xbbs.snapshot_timing                   = iv_proc_div
--    AND EXISTS (
--          SELECT 1
--          FROM   xxcok_info_rev_custom  xirc
--          WHERE  xirc.snapshot_create_ym           = xbbs.snapshot_create_ym
--          AND    xirc.snapshot_timing              = xbbs.snapshot_timing
--          AND    xirc.rev                          = '3'  -- �V���iFB�j
--          AND    xirc.vendor_code                  = xbbs.supplier_code
--          AND    xirc.request_id                   = cn_request_id )
--    AND     xbbs.supplier_code                     = sum_t.vendor_code(+)
--    AND     xbbs.supplier_code                     = sum_ne.vendor_code(+)
--    AND     xbbs.supplier_code                     = sum_e.vendor_code(+)
--    AND     xirh.vendor_code                       = xbbs.supplier_code
--    AND     xirh.snapshot_create_ym                = gv_process_ym
--    AND     xirh.snapshot_timing                   = '1'  -- 2�c
--    AND     xirh.rev                               = '1'  -- �����i2�c�j
    WHERE   1=1
    AND     xirh.vendor_code         = pv.segment1
    AND     pv.vendor_id             = pvsa.vendor_id
    AND     (  pvsa.inactive_date    > gd_process_date
            OR pvsa.inactive_date    IS NULL )
    AND     pvsa.org_id              = gn_org_id
    AND EXISTS (
          SELECT 1
          FROM   xxcok_info_rev_custom  xirc
          WHERE  xirc.snapshot_create_ym  = gv_process_ym
          AND    xirc.snapshot_timing     = iv_proc_div
          AND    xirc.rev                 = '3'  -- �V���iFB�j
          AND    xirc.vendor_code         = xirh.vendor_code
          AND    xirc.request_id          = cn_request_id
          )
    AND     xirh.vendor_code         = sum_t.vendor_code(+)
    AND     xirh.vendor_code         = sum_ne.vendor_code(+)
    AND     xirh.vendor_code         = sum_e.vendor_code(+)
    AND     xirh.snapshot_create_ym  = gv_process_ym
    AND     xirh.snapshot_timing     = '1'  -- 2�c
    AND     xirh.rev                 = '1'  -- �����i2�c�j
-- Mod Ver1.1 K.Kanada E
-- Ver.1.3 Add Start
    AND     xbdciv.dept_code         = pvsa.attribute5          -- �d����T�C�g�}�X�^.�₢���킹�S�����_�R�[�h�iDFF5�j
    AND     xbdciv.set_of_books_id   = gv_set_of_bks_id         -- ��v����ID
    AND     xbdciv.enabled_flag      = 'Y'
    AND     gd_process_date BETWEEN xbdciv.comp_start_date 
                                AND NVL( xbdciv.comp_end_date, gd_process_date )
-- Ver.1.3 Add End
    GROUP BY
-- Mod Ver1.1 K.Kanada S
--            xbbs.supplier_code
--           ,xbbs.snapshot_create_ym
--           ,xbbs.snapshot_timing
            xirh.vendor_code
           ,xirh.snapshot_create_ym
           ,xirh.snapshot_timing
-- Mod Ver1.1 K.Kanada E
           ,xirh.tax_div
           ,xirh.target_div
           ,xirh.cust_name
           ,xirh.dest_post_code
           ,xirh.dest_address1
           ,xirh.dest_tel
           ,xirh.fax
           ,xirh.dept_name
           ,xirh.send_post_code
           ,xirh.send_address1
           ,xirh.send_tel
           ,xirh.payment_date
           ,sum_ne.sales_fee
           ,sum_e.sales_fee
           ,sum_t.tax_amt
           ,sum_t.sales_amt
           ,sum_t.sales_tax_amt
           ,sum_t.sales_qty
           ,xirh.tax_div
           ,xirh.target_div
-- Mod Ver1.1 K.Kanada S
--           ,xbbs.bank_charge_bearer
           ,pvsa.bank_charge_bearer
-- Mod Ver1.1 K.Kanada S
-- Ver.1.2 ADD START
           ,sum_ne.sales_fee_no_tax
           ,sum_ne.sales_fee_tax
           ,sum_ne.sales_fee_with_tax
           ,sum_e.electric_amt_no_tax
           ,sum_e.electric_amt_tax
           ,sum_e.electric_amt_with_tax
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
           ,pvsa.attribute5
           ,xbdciv.company_code_bd
-- Ver.1.3 Add End
    ;
--
    -- �V���f�[�^�쐬�����J�E���g
    gn_credit_cnt := SQL%ROWCOUNT;
--
-- Els Ver1.1 K.Kanada S
--    -- ===============================================
--    -- ���o�ΏۊO�`�F�b�N
--    -- ===============================================
--    <<check_ex_loop>>
--    FOR l_check_ex_rec IN l_check_ex_cur LOOP
--      -- ===============================================
--      -- �C���t�H�}�[�g�p�ԍ��e�[�u���X�V
--      -- ===============================================
--      UPDATE xxcok_info_rev_header xirh  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
--      SET    xirh.check_result = '1'    -- �ΏۊO
--      WHERE  xirh.snapshot_create_ym = gv_process_ym
--      AND    xirh.snapshot_timing    = iv_proc_div
--      AND    xirh.rev                = '3'  -- �V���iFB�j
--      AND    xirh.request_id         = cn_request_id
--      AND    xirh.vendor_code        = l_check_ex_rec.vendor_code
--      ;
----
--      UPDATE xxcok_info_rev_custom xirc  -- �C���t�H�}�[�g�p�ԍ��i�J�X�^�����ׁj
--      SET    xirc.check_result = '1'    -- �ΏۊO
--      WHERE  xirc.snapshot_create_ym = gv_process_ym
--      AND    xirc.snapshot_timing    = iv_proc_div
--      AND    xirc.rev                = '3'  -- �V���iFB�j
--      AND    xirc.request_id         = cn_request_id
--      AND    xirc.vendor_code        = l_check_ex_rec.vendor_code
--      ;
--    END LOOP check_ex_loop;
-- Els Ver1.1 K.Kanada E
--
-- Ver.1.2 ADD START
    --==================================
    -- �C���t�H�}�[�g�p�ԍ��w�b�_�[�X�V
    --==================================
    -- �̔��萔���v�̍Čv�Z���s���A���̌��ʂ����ƂɐU���萔���A�x�����z���Z�o���A�ԍ��w�b�_�[�֔��f����
    <<update_xirh_loop>>
    FOR l_update_xirh_rec IN l_update_xirh_cur LOOP
      --
      -- �̔��萔���v�̍Čv�Z
      -- ���Čv�Z���s�v�ȏꍇ��IN��OUT�̊e�̔��萔���v�͓������z�ƂȂ�
      xxcok_common_pkg.recalc_pay_amt_p(
        ov_errbuf               =>  lv_errbuf
      , ov_retcode              =>  lv_retcode
      , ov_errmsg               =>  lv_errmsg
      , iv_pay_kbn              =>  l_update_xirh_rec.bm_payment_kbn            -- BM�x���敪
      , iv_tax_calc_kbn         =>  NVL(l_update_xirh_rec.tax_calc_kbn
                                       ,cv_tax_calc_kbn_line)                   -- �Ōv�Z�敪
      , iv_tax_kbn              =>  l_update_xirh_rec.bm_tax_kbn                -- BM�ŋ敪
      , iv_tax_rounding_rule    =>  cv_tax_rounding_rule_down                   -- �[�������敪�F�؎̂�
      , in_tax_rate             =>  gn_bm_tax                                   -- �ŗ�
      , in_pay_amt_no_tax       =>  l_update_xirh_rec.recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
      , in_pay_amt_tax          =>  l_update_xirh_rec.recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
      , in_pay_amt_with_tax     =>  l_update_xirh_rec.recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
      , on_pay_amt_no_tax       =>  ln_recalc_total_fee_no_tax                  -- [OUT]�Čv�Z�ώ萔���v�i�Ŕ��j
      , on_pay_amt_tax          =>  ln_recalc_total_fee_tax                     -- [OUT]�Čv�Z�ώ萔���v�i����Łj
      , on_pay_amt_with_tax     =>  ln_recalc_total_fee_with_tax                -- [OUT]�Čv�Z�ώ萔���v�i�ō��j
      );
      -- ���^�[���R�[�h�m�F
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- �U���萔���̎Z�o
      xxcok_common_pkg.calc_bank_trans_fee_p(
        ov_errbuf                   => lv_errbuf
      , ov_retcode                  => lv_retcode
      , ov_errmsg                   => lv_errmsg
      , in_bank_trans_amt           => ln_recalc_total_fee_with_tax             -- �Čv�Z�ώ萔���v�i�ō��j
      , in_base_amt                 => TO_NUMBER(gv_bank_fee_trans)             -- ��z
      , in_fee_less_base_amt        => TO_NUMBER(gv_bank_fee_less)              -- ��z�����萔��
      , in_fee_more_base_amt        => TO_NUMBER(gv_bank_fee_more)              -- ��z�ȏ�萔��
      , in_fee_tax_rate             => gn_bm_tax                                -- �萔���ŗ�
      , iv_bank_charge_bearer       => l_update_xirh_rec.bank_charge_bearer     -- �U���萔�����S��
      , on_bank_trans_fee_no_tax    => ln_bank_trans_fee_no_tax                 -- [OUT]�U���萔���i�Ŕ��j
      , on_bank_trans_fee_tax       => ln_bank_trans_fee_tax                    -- [OUT]�U���萔���i����Łj
      , on_bank_trans_fee_with_tax  => ln_bank_trans_fee_with_tax               -- [OUT]�U���萔���i�ō��j
      );
      -- ���^�[���R�[�h�m�F
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- �ŗ����Ƃ̐Ŕ��A����ŁA�ō��̋��z��ݒ�
      IF (l_update_xirh_rec.bm_tax_kbn = '3') THEN
        -- �ŋ敪����ېł̏ꍇ
        ln_total_amt_no_tax_10 := 0 - ln_bank_trans_fee_no_tax;
        ln_tax_amt_10          := 0 - ln_bank_trans_fee_tax;
        ln_total_amt_10        := 0 - ln_bank_trans_fee_with_tax;
        ln_total_amt_no_tax_0  := ln_recalc_total_fee_no_tax;
        ln_tax_amt_0           := ln_recalc_total_fee_tax;
        ln_total_amt_0         := ln_recalc_total_fee_with_tax;
      ELSE
        -- �ŋ敪���ō��݁A�Ŕ����̏ꍇ
        ln_total_amt_no_tax_10 := ln_recalc_total_fee_no_tax   - ln_bank_trans_fee_no_tax;
        ln_tax_amt_10          := ln_recalc_total_fee_tax      - ln_bank_trans_fee_tax;
        ln_total_amt_10        := ln_recalc_total_fee_with_tax - ln_bank_trans_fee_with_tax;
        ln_total_amt_no_tax_0  := 0;
        ln_tax_amt_0           := 0;
        ln_total_amt_0         := 0;
      END IF;
      --
      -- �C���t�H�}�[�g�p�ԍ��w�b�_�[�X�V
      UPDATE xxcok_info_rev_header xirh
      SET    -- �����Ă̒ʒm���z
             xirh.notifi_amt                =  ln_recalc_total_fee_with_tax - ln_bank_trans_fee_with_tax
             -- �����
            ,xirh.tax_amt                   =  ln_recalc_total_fee_tax
             -- �U���萔���@�ō�
            ,xirh.transfer_fee              =  ln_bank_trans_fee_with_tax * (-1)
             -- ���x�����z�@�ō�
            ,xirh.payment_amt               =  ln_recalc_total_fee_with_tax - ln_bank_trans_fee_with_tax
             -- 10%���v���z�i�Ŕ��j
            ,xirh.total_amt_no_tax_10       =  ln_total_amt_no_tax_10
             -- 10%����Ŋz
            ,xirh.tax_amt_10                =  ln_tax_amt_10
             -- 10%���v���z�i�ō��j
            ,xirh.total_amt_10              =  ln_total_amt_10
             -- ��ېō��v���z�i�Ŕ��j
            ,xirh.total_amt_no_tax_0        =  ln_total_amt_no_tax_0
             -- ��ېŏ���Ŋz
            ,xirh.tax_amt_0                 =  ln_tax_amt_0
             -- ��ېō��v���z�i�ō��j
            ,xirh.total_amt_0               =  ln_total_amt_0
             -- �Čv�Z�ώ萔���v�i�Ŕ��j
            ,xirh.recalc_total_fee_no_tax   =  ln_recalc_total_fee_no_tax
             -- �Čv�Z�ώ萔���v�i����Łj
            ,xirh.recalc_total_fee_tax      =  ln_recalc_total_fee_tax
             -- �Čv�Z�ώ萔���v�i�ō��j
            ,xirh.recalc_total_fee_with_tax =  ln_recalc_total_fee_with_tax
             -- �U���萔���i�Ŕ��j
            ,xirh.bank_trans_fee_no_tax     =  ln_bank_trans_fee_no_tax   * (-1)
             -- �U���萔���i����Łj
            ,xirh.bank_trans_fee_tax        =  ln_bank_trans_fee_tax      * (-1)
             -- �U���萔���i�ō��j
            ,xirh.bank_trans_fee_with_tax   =  ln_bank_trans_fee_with_tax * (-1)
      WHERE  xirh.rowid = l_update_xirh_rec.row_id
      ;
    END LOOP update_xirh_loop;
-- Ver.1.2 ADD END
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
-- Ver.1.2 ADD START
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
-- Ver.1.2 ADD END
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_credit_header;
--
-- Els Ver1.1 K.Kanada S
--  /**********************************************************************************
--   * Procedure Name   : ins_credit_custom_mon
--   * Description      : �V���J�X�^�����׏��쐬�R(A-12)
--   ***********************************************************************************/
--  PROCEDURE ins_credit_custom_mon(
--    iv_proc_div   IN  VARCHAR2
--   ,i_no_dif_tab  IN  g_no_dif_ttype
--   ,ov_errbuf     OUT VARCHAR2
--   ,ov_retcode    OUT VARCHAR2
--   ,ov_errmsg     OUT VARCHAR2
--  )
--  IS
--    -- ===============================================
--    -- ���[�J���萔
--    -- ===============================================
--    cv_prg_name    CONSTANT VARCHAR2(25) := 'ins_credit_custom_mon';  -- �v���O������
--    -- ===============================================
--    -- ���[�J���ϐ�
--    -- ===============================================
--    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
--    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
--    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--    -- ===============================================
--    -- ���[�J���J�[�\��
--    -- ===============================================
--    -- ��z�̂݃f�[�^�擾
--    CURSOR l_fixed_amt_cur
--    IS
--      SELECT xirc.rowid       AS  row_id
--            ,xirc.vendor_code AS  vendor_code
--            ,xirc.cust_code   AS  cust_code
--      FROM   xxcok_info_rev_custom xirc
--      WHERE  xirc.snapshot_create_ym = gv_process_ym
--      AND    xirc.snapshot_timing    = iv_proc_div
--      AND    xirc.rev                = '3'  -- �V���iFB�j
--      AND    xirc.calc_type          = '40' -- 40:��z
--      AND    xirc.request_id         = cn_request_id
--      AND NOT EXISTS (SELECT '1'
--                      FROM   xxcok_info_rev_custom xirc2
--                      WHERE  xirc2.vendor_code        = xirc.vendor_code
--                      AND    xirc2.cust_code          = xirc.cust_code
--                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
--                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
--                      AND    xirc2.rev                = xirc.rev
--                      AND    xirc2.request_id         = xirc.request_id
--                      AND    xirc2.calc_type          IN ('10','20','30')
--                     )
--    ;
----
--    l_fixed_amt_rec    l_fixed_amt_cur%ROWTYPE;
----
--    -- �d�C��̂݃f�[�^�擾
--    CURSOR l_electric_cur
--    IS
--      SELECT xirc.rowid       AS  row_id
--            ,xirc.vendor_code AS  vendor_code
--            ,xirc.cust_code   AS  cust_code
--      FROM   xxcok_info_rev_custom xirc
--      WHERE  xirc.snapshot_create_ym = gv_process_ym
--      AND    xirc.snapshot_timing    = iv_proc_div
--      AND    xirc.rev                = '3'  -- �V���iFB�j
--      AND    xirc.calc_type  = '50'  -- 50:�d�C��
--      AND    xirc.request_id         = cn_request_id
--      AND NOT EXISTS (SELECT '1'
--                      FROM   xxcok_info_rev_custom xirc2
--                      WHERE  xirc2.vendor_code = xirc.vendor_code
--                      AND    xirc2.cust_code   = xirc.cust_code
--                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
--                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
--                      AND    xirc2.rev         = xirc.rev
--                      AND    xirc2.request_id  = xirc.request_id
--                      AND    xirc2.calc_type   IN ('10','20','30','40')
--                     )
--    ;
----
--    l_electric_rec    l_electric_cur%ROWTYPE;
----
--    -- ===============================================
--    -- ���[�J����O
--    -- ===============================================
----
--  BEGIN
--    -- ===============================================
--    -- �X�e�[�^�X������
--    -- ===============================================
--    ov_retcode := cv_status_normal;
----
--    -- ===============================================
--    -- ���d����E�ڋq�Ō��ׂ��̃f�[�^�ō����Ȃ��ڋq��o�^
--    -- ===============================================
--    FOR i IN 1..i_no_dif_tab.COUNT LOOP
----
--      INSERT INTO xxcok_info_rev_custom (
--        snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--       ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
--       ,rev                         -- REV
--       ,check_result                -- �Ó����`�F�b�N����
--       ,row_id                      -- ���e�[�u�����R�[�hID
--       ,edi_interface_date          -- �A�g���iEDI�x���ē����j
--       ,vendor_code                 -- ���t��R�[�h
--       ,cust_code                   -- �ڋq�R�[�h
--       ,inst_dest                   -- �ݒu�ꏊ
--       ,calc_type                   -- �v�Z����
--       ,calc_sort                   -- �v�Z�����\�[�g��
--       ,sell_bottle                 -- �����^�e��
--       ,sales_qty                   -- �̔��{��
--       ,sales_tax_amt               -- �̔����z�i�ō��j
--       ,sales_amt                   -- �̔����z�i�Ŕ��j
--       ,contract                    -- ���_����e
--       ,sales_fee                   -- �̔��萔���i�Ŕ��j
--       ,tax_amt                     -- �����
--       ,sales_tax_fee               -- �̔��萔���i�ō��j
--       ,bottle_code                 -- �e��敪�R�[�h
--       ,salling_price               -- �������z
--       ,rebate_rate                 -- ���ߗ�
--       ,rebate_amt                  -- ���ߊz
--       ,tax_code                    -- �ŃR�[�h
--       ,tax_div                     -- �ŋ敪
--       ,target_div                  -- �Ώۋ敪
--       ,created_by                  -- �쐬��
--       ,creation_date               -- �쐬��
--       ,last_updated_by             -- �ŏI�X�V��
--       ,last_update_date            -- �ŏI�X�V��
--       ,last_update_login           -- �ŏI�X�V���O�C��
--       ,request_id                  -- �v��ID
--       ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--       ,program_id                  -- �R���J�����g�E�v���O����ID
--       ,program_update_date         -- �v���O�����X�V��
--      )
--      SELECT
--          xbbs.snapshot_create_ym                 AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--         ,xbbs.snapshot_timing                    AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--         ,'3'                                     AS  rev                     -- REV�i3:�V���iFB�j)
--         ,'0'                                     AS  check_result            -- �Ó����`�F�b�N���ʁi0:�Ώہj
--         ,NULL                                    AS  row_id                  -- ���e�[�u�����R�[�hID
--         ,NULL                                    AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
--         ,xbbs.supplier_code                      AS  vendor_code             -- ���t��R�[�h
--         ,xcbs.delivery_cust_code                 AS  cust_code               -- �ڋq�R�[�h
--         ,SUBSTR( xbbs.cust_name, 1, 50 )         AS  inst_dest               -- �ݒu�ꏊ
--         ,xcbs.calc_type                          AS  calc_type               -- �v�Z����
--         ,flv2.calc_type_sort                     AS  calc_sort               -- �v�Z�����\�[�g��
--         ,CASE xcbs.calc_type
--            WHEN '10'
--            THEN TO_CHAR( xcbs.selling_price )
--            WHEN '20'
--            THEN SUBSTR( flv1.container_type_name, 1, 10 )
--            ELSE flv2.disp
--          END                                     AS  sell_bottle             -- �����^�e��
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN NULL
--            ELSE SUM( xcbs.delivery_qty )
--          END                                     AS  sales_qty               -- �̔��{��
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN NULL
--            ELSE SUM( xcbs.selling_amt_tax )
--          END                                     AS  sales_tax_amt           -- �̔����z�i�ō��j
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN NULL
--            ELSE SUM( xcbs.selling_amt_no_tax )
--          END                                     AS  sales_amt               -- �̔����z�i�Ŕ��j
--         ,CASE
--            WHEN ( xcbs.rebate_rate IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
--            THEN xcbs.rebate_rate || '%'
--            WHEN ( xcbs.rebate_amt IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
--            THEN xcbs.rebate_amt || '�~'
--          END                                     AS  contract                -- ���_����e
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN SUM( xcbs.electric_amt_no_tax )
--            ELSE SUM( xcbs.cond_bm_amt_no_tax )
--          END                                     AS  sales_fee               -- �̔��萔���i�Ŕ��j
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN SUM( xcbs.electric_tax_amt )
--            ELSE SUM( xcbs.cond_tax_amt )
--          END                                     AS  tax_amt                 -- �����
--         ,CASE xcbs.calc_type
--            WHEN '50'
--            THEN SUM( xcbs.electric_amt_tax )
--            ELSE SUM( xcbs.cond_bm_amt_tax )
--          END                                     AS  sales_tax_fee           -- �̔��萔���i�ō��j
--         ,flv1.container_type_code                AS  bottle_code             -- �e��敪�R�[�h
--         ,xcbs.selling_price                      AS  salling_price           -- �������z
--         ,xcbs.rebate_rate                        AS  rebate_rate             -- ���ߗ�
--         ,xcbs.rebate_amt                         AS  rebate_amt              -- ���ߊz
--         ,xbbs.tax_code                           AS  tax_code                -- �ŃR�[�h
--         ,CASE
--            WHEN xbbs.bm_tax_kbn = '1'
--            THEN '2'
--            WHEN xbbs.bm_tax_kbn IN ('2','3')
--            THEN '1'
--          END                                     AS  tax_div                 -- �ŋ敪
--         ,SUBSTR( xbbs.supplier_code, -1, 1 )     AS  target_div              -- �Ώۋ敪
--         ,cn_created_by                           AS  created_by              -- �쐬��
--         ,SYSDATE                                 AS  creation_date           -- �쐬��
--         ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
--         ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
--         ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
--         ,cn_request_id                           AS  request_id              -- �v��ID
--         ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
--         ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
--         ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
--      FROM  xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
--           ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
--           ,(SELECT flv.attribute1 AS container_type_code
--                   ,flv.meaning    AS container_type_name
--             FROM fnd_lookup_values flv
--             WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
--             AND flv.language      = USERENV( 'LANG' )
--            )                         flv1  -- �Q�ƕ\�i�e��j
--           ,(SELECT flv.lookup_code AS calc_type
--                   ,flv.meaning     AS line_name
--                   ,flv.attribute2  AS calc_type_sort
--                   ,flv.attribute3  AS disp
--             FROM fnd_lookup_values flv
--             WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
--             AND flv.language      = USERENV( 'LANG' )
--            )                         flv2  -- �Q�ƕ\�i�̎�v�Z�����j
--      WHERE  xbbs.snapshot_create_ym                = gv_process_ym
--      AND    xbbs.snapshot_timing                   = iv_proc_div
--      AND    xbbs.supplier_code                     = i_no_dif_tab(i).supplier_code
--      AND    xbbs.cust_code                         = i_no_dif_tab(i).cust_code
--      AND    xbbs.resv_flag                         IS NULL
--      AND    xbbs.balance_cancel_date               IS NULL
--      AND    xbbs.bm_paymet_kbn                     IN ('1','2')
--      AND    xcbs.base_code                         = xbbs.base_code
--      AND    xcbs.delivery_cust_code                = xbbs.cust_code
--      AND    xcbs.supplier_code                     = xbbs.supplier_code
--      AND    xcbs.closing_date                      = xbbs.closing_date
--      AND    xcbs.expect_payment_date               = xbbs.expect_payment_date
--      AND    xcbs.container_type_code               = flv1.container_type_code(+)
--      AND    xcbs.calc_type                         = flv2.calc_type
--      GROUP BY
--             xbbs.snapshot_create_ym
--            ,xbbs.snapshot_timing
--            ,xbbs.supplier_code
--            ,xcbs.delivery_cust_code
--            ,SUBSTR(xbbs.cust_name,1,50)
--            ,xcbs.calc_type
--            ,flv2.calc_type_sort
--            ,flv1.container_type_code
--            ,flv1.container_type_name
--            ,xcbs.selling_price
--            ,xcbs.rebate_rate
--            ,xcbs.rebate_amt
--            ,xbbs.tax_code
--            ,xbbs.bm_tax_kbn
--            ,flv2.disp
--      ;
----
--      -- ===============================================
--      -- �J�X�^�����׏��o�^(���v�s)
--      -- ===============================================
--      INSERT INTO xxcok_info_rev_custom(
--         snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--        ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
--        ,rev                         -- REV
--        ,check_result                -- �Ó����`�F�b�N����
--        ,vendor_code                 -- ���t��R�[�h
--        ,cust_code                   -- �ڋq�R�[�h
--        ,inst_dest                   -- �ݒu�ꏊ
--        ,calc_sort                   -- �v�Z�����\�[�g��
--        ,sell_bottle                 -- �����^�e��
--        ,sales_qty                   -- �̔��{��
--        ,sales_tax_amt               -- �̔����z�i�ō��j
--        ,sales_amt                   -- �̔����z�i�Ŕ��j
--        ,sales_fee                   -- �̔��萔���i�Ŕ��j
--        ,tax_amt                     -- �����
--        ,sales_tax_fee               -- �̔��萔���i�ō��j
--        ,tax_div                     -- �ŋ敪
--        ,target_div                  -- �Ώۋ敪
--        ,created_by                  -- �쐬��
--        ,creation_date               -- �쐬��
--        ,last_updated_by             -- �ŏI�X�V��
--        ,last_update_date            -- �ŏI�X�V��
--        ,last_update_login           -- �ŏI�X�V���O�C��
--        ,request_id                  -- �v��ID
--        ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        ,program_id                  -- �R���J�����g�E�v���O����ID
--        ,program_update_date         -- �v���O�����X�V��
--      )
--      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--             ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--             ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
--             ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
--             ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
--             ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
--             ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
--             ,2.5                             AS  calc_sort               -- �v�Z�����\�[�g��
--             ,'���v'                          AS  sell_bottle             -- �����^�e��
--             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
--             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
--             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
--             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
--             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
--             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
--             ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
--             ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
--             ,cn_created_by                   AS  created_by              -- �쐬��
--             ,SYSDATE                         AS  creation_date           -- �쐬��
--             ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
--             ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
--             ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
--             ,cn_request_id                   AS  request_id              -- �v��ID
--             ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
--             ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
--             ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
--      FROM    xxcok_info_rev_custom  xirc
--      WHERE   xirc.snapshot_create_ym         = gv_process_ym
--      AND     xirc.snapshot_timing            = iv_proc_div
--      AND     xirc.rev                        = '3' -- �V���iFB�j
--      AND     xirc.calc_type                  IN  ('10','20')
--      AND     xirc.vendor_code                = i_no_dif_tab(i).supplier_code
--      AND     xirc.cust_code                  = i_no_dif_tab(i).cust_code
--      AND     xirc.request_id = cn_request_id
--      GROUP BY
--              xirc.snapshot_create_ym
--             ,xirc.snapshot_timing
--             ,xirc.vendor_code
--             ,xirc.cust_code
--             ,xirc.inst_dest
--             ,xirc.tax_div
--             ,xirc.target_div
--      ;
----
--      -- ===============================================
--      -- �J�X�^�����׏��o�^�i�ꗥ�������׍s�j
--      -- ===============================================
--      INSERT INTO xxcok_info_rev_custom(
--         snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--        ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
--        ,rev                         -- REV
--        ,check_result                -- �Ó����`�F�b�N����
--        ,vendor_code                 -- ���t��R�[�h
--        ,cust_code                   -- �ڋq�R�[�h
--        ,inst_dest                   -- �ݒu�ꏊ
--        ,calc_type                   -- �v�Z����
--        ,calc_sort                   -- �v�Z�����\�[�g��
--        ,sell_bottle                 -- �����^�e��
--        ,sales_qty                   -- �̔��{��
--        ,sales_tax_amt               -- �̔����z�i�ō��j
--        ,sales_amt                   -- �̔����z�i�Ŕ��j
--        ,contract                    -- ���_����e
--        ,sales_fee                   -- �̔��萔���i�Ŕ��j
--        ,tax_amt                     -- �����
--        ,sales_tax_fee               -- �̔��萔���i�ō��j
--        ,bottle_code                 -- �e��敪�R�[�h
--        ,salling_price               -- �������z
--        ,rebate_rate                 -- ���ߗ�
--        ,rebate_amt                  -- ���ߊz
--        ,tax_code                    -- �ŃR�[�h
--        ,tax_div                     -- �ŋ敪
--        ,target_div                  -- �Ώۋ敪
--        ,created_by                  -- �쐬��
--        ,creation_date               -- �쐬��
--        ,last_updated_by             -- �ŏI�X�V��
--        ,last_update_date            -- �ŏI�X�V��
--        ,last_update_login           -- �ŏI�X�V���O�C��
--        ,request_id                  -- �v��ID
--        ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        ,program_id                  -- �R���J�����g�E�v���O����ID
--        ,program_update_date         -- �v���O�����X�V��
--      )
--      SELECT  /*+ 
--                  LEADING(xbbs_1 xseh xsel flv)
--                  USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
--                  */
--              xbbs_1.snapshot_create_ym            AS snapshot_create_ym     -- �X�i�b�v�V���b�g�쐬�N��
--             ,xbbs_1.snapshot_timing               AS snapshot_timing        -- �X�i�b�v�V���b�g�^�C�~���O
--             ,'3'                                  AS rev                    -- REV�i3:�V���iFB�j)
--             ,'0'                                  AS check_result           -- �Ó����`�F�b�N����
--             ,xbbs_1.supplier_code                 AS vendor_code            -- ���t��R�[�h
--             ,xseh.ship_to_customer_code           AS cust_code              -- �ڋq�R�[�h
--             ,SUBSTR( xbbs_1.cust_name, 1, 50)     AS inst_dest              -- �ݒu�ꏊ
--             ,NULL                                 AS calc_type              -- �v�Z����
--             ,'2.7'                                AS calc_sort              -- �v�Z�����\�[�g��
--             ,xsel.dlv_unit_price                  AS sell_bottle            -- �����^�e��
--             ,SUM( xsel.dlv_qty)                   AS sales_qty              -- �̔��{��
--             ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
--                                                   AS sales_tax_amt          -- �̔����z�i�ō��j
--             ,SUM( xsel.pure_amount )              AS sales_amt              -- �̔����z�i�Ŕ��j
--             ,NULL                                 AS contract               -- ���_����e
--             ,NULL                                 AS sales_fee              -- �̔��萔���i�Ŕ��j
--             ,NULL                                 AS tax_amt                -- �����
--             ,NULL                                 AS sales_tax_fee          -- �̔��萔���i�ō��j
--             ,NULL                                 AS bottle_code            -- �e��敪�R�[�h
--             ,NULL                                 AS salling_price          -- �������z
--             ,NULL                                 AS rebate_rate            -- ���ߗ�
--             ,NULL                                 AS rebate_amt             -- ���ߊz
--             ,NULL                                 AS tax_code               -- �ŃR�[�h
--             ,xbbs_1.tax_div                       AS tax_div                -- �ŋ敪
--             ,SUBSTR( xbbs_1.supplier_code, -1, 1) AS target_div             -- �Ώۋ敪
--             ,cn_created_by                        AS created_by             -- �쐬��
--             ,SYSDATE                              AS creation_date          -- �쐬��
--             ,cn_last_updated_by                   AS last_updated_by        -- �ŏI�X�V��
--             ,SYSDATE                              AS last_update_date       -- �ŏI�X�V��
--             ,cn_last_update_login                 AS last_update_login      -- �ŏI�X�V���O�C��
--             ,cn_request_id                        AS request_id             -- �v��id
--             ,cn_program_application_id            AS program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����id
--             ,cn_program_id                        AS program_id             -- �R���J�����g�E�v���O����id
--             ,SYSDATE                              AS program_update_date    -- �v���O�����X�V��
--      FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
--             ,xxcos_sales_exp_lines     xsel  -- �̔����і���
--             ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
--             ,(
--               SELECT  /*+ LEADING(xbbs xcbs) use_nl(xcbs) */
--                       xbbs.supplier_code         AS supplier_code
--                      ,xbbs.cust_code             AS cust_code
--                      ,xbbs.closing_date          AS closing_date
--                      ,xbbs.snapshot_create_ym    AS snapshot_create_ym
--                      ,xbbs.snapshot_timing       AS snapshot_timing
--                      ,xbbs.cust_name             AS cust_name
--                      ,CASE WHEN xbbs.bm_tax_kbn = '1'
--                            THEN '2'
--                            WHEN xbbs.bm_tax_kbn IN ('2','3')
--                            THEN '1'
--                       END                        AS tax_div
--               FROM    xxcok_bm_balance_snap     xbbs   -- �̎�c���e�[�u���X�i�b�v�V���b�g
--                      ,xxcok_cond_bm_support     xcbs   -- �����ʔ̎�̋��e�[�u��
--               WHERE   xbbs.snapshot_create_ym           =  gv_process_ym
--               AND     xbbs.snapshot_timing              =  iv_proc_div
--               AND     xbbs.resv_flag                    IS NULL
--               AND     xbbs.balance_cancel_date          IS NULL
--               AND     xbbs.bm_paymet_kbn                IN ('1','2')
--               AND EXISTS (
--                       SELECT 1
--                       FROM   xxcok_info_rev_custom    xirc
--                       WHERE  xirc.snapshot_create_ym    =  xbbs.snapshot_create_ym
--                       AND    xirc.snapshot_timing       =  xbbs.snapshot_timing
--                       AND    xirc.rev                   =  '3' -- �V���iFB�j
--                       AND    xirc.vendor_code           =  xbbs.supplier_code
--                       AND    xirc.cust_code             =  xbbs.cust_code
--                       AND    xirc.vendor_code           =  i_no_dif_tab(i).supplier_code
--                       AND    xirc.cust_code             =  i_no_dif_tab(i).cust_code
--                       AND    xirc.request_id            =  cn_request_id )
--               AND     xcbs.base_code                    =  xbbs.base_code
--               AND     xcbs.delivery_cust_code           =  xbbs.cust_code
--               AND     xcbs.supplier_code                =  xbbs.supplier_code
--               AND     xcbs.closing_date                 =  xbbs.closing_date
--               AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
--               AND     xcbs.calc_type                    =  '30'                -- 30:�ꗥ����
--               GROUP BY xbbs.supplier_code
--                       ,xbbs.cust_code
--                       ,xbbs.closing_date
--                       ,xbbs.snapshot_create_ym
--                       ,xbbs.snapshot_timing
--                       ,xbbs.cust_name
--                       ,xbbs.bm_tax_kbn
--              ) xbbs_1                        -- �̎���
--      WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
--      AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
--      AND     xseh.ship_to_customer_code  =  xbbs_1.cust_code
--      AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbbs_1.closing_date, -1)) + 1 --������
--      AND     xseh.delivery_date          <= xbbs_1.closing_date                               --������
--      AND     flv.lookup_code             =  xsel.sales_class
--      AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
--      AND     flv.language                =  USERENV( 'LANG' )
--      AND     flv.enabled_flag            =  'Y'
--      AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                  AND NVL( flv.end_date_active  , gd_process_date )
--      AND NOT EXISTS ( SELECT 'X'
--                       FROM fnd_lookup_values flv -- ��݌ɕi��
--                       WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
--                         AND flv.lookup_code         = xsel.item_code
--                         AND flv.language            = USERENV( 'LANG' )
--                         AND flv.enabled_flag        = 'Y'
--                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                   AND NVL( flv.end_date_active  , gd_process_date )
--          )
--      GROUP BY
--              xseh.ship_to_customer_code
--             ,SUBSTR( xbbs_1.cust_name, 1, 50)
--             ,xbbs_1.supplier_code
--             ,SUBSTR( xbbs_1.supplier_code, -1, 1)
--             ,xsel.dlv_unit_price
--             ,xbbs_1.snapshot_create_ym
--             ,xbbs_1.snapshot_timing
--             ,xbbs_1.tax_div
--      ;
----
--      -- ===============================================
--      -- �J�X�^�����׏��o�^(�ꗥ�������v�s)
--      -- ===============================================
--      INSERT INTO xxcok_info_rev_custom(
--         snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--        ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
--        ,rev                         -- REV
--        ,check_result                -- �Ó����`�F�b�N����
--        ,vendor_code                 -- ���t��R�[�h
--        ,cust_code                   -- �ڋq�R�[�h
--        ,inst_dest                   -- �ݒu�ꏊ
--        ,calc_sort                   -- �v�Z�����\�[�g��
--        ,sell_bottle                 -- �����^�e��
--        ,sales_qty                   -- �̔��{��
--        ,sales_tax_amt               -- �̔����z�i�ō��j
--        ,sales_amt                   -- �̔����z�i�Ŕ��j
--        ,sales_fee                   -- �̔��萔���i�Ŕ��j
--        ,tax_amt                     -- �����
--        ,sales_tax_fee               -- �̔��萔���i�ō��j
--        ,tax_div                     -- �ŋ敪
--        ,target_div                  -- �Ώۋ敪
--        ,created_by                  -- �쐬��
--        ,creation_date               -- �쐬��
--        ,last_updated_by             -- �ŏI�X�V��
--        ,last_update_date            -- �ŏI�X�V��
--        ,last_update_login           -- �ŏI�X�V���O�C��
--        ,request_id                  -- �v��ID
--        ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        ,program_id                  -- �R���J�����g�E�v���O����ID
--        ,program_update_date         -- �v���O�����X�V��
--      )
--      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--             ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--             ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
--             ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
--             ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
--             ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
--             ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
--             ,3.5                             AS  calc_sort               -- �v�Z�����\�[�g��
--             ,'���v'                          AS  sell_bottle             -- �����^�e��
--             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
--             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
--             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
--             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
--             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
--             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
--             ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
--             ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
--             ,cn_created_by                   AS  created_by              -- �쐬��
--             ,SYSDATE                         AS  creation_date           -- �쐬��
--             ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
--             ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
--             ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
--             ,cn_request_id                   AS  request_id              -- �v��ID
--             ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
--             ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
--             ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
--      FROM    xxcok_info_rev_custom  xirc
--      WHERE   xirc.snapshot_create_ym = gv_process_ym
--      AND     xirc.snapshot_timing    = iv_proc_div
--      AND     xirc.rev                = '3' -- �V���iFB�j
--      AND     xirc.calc_type  = '30'
--      AND     xirc.vendor_code        = i_no_dif_tab(i).supplier_code
--      AND     xirc.cust_code          = i_no_dif_tab(i).cust_code
--      AND     xirc.request_id         = cn_request_id
--      GROUP BY
--              xirc.snapshot_create_ym
--             ,xirc.snapshot_timing
--             ,xirc.vendor_code
--             ,xirc.cust_code
--             ,xirc.inst_dest
--             ,xirc.tax_div
--             ,xirc.target_div
--      ;
----
--      -- ===============================================
--      -- ��z�̂݃f�[�^�擾
--      -- ===============================================
--      <<fixed_amt_loop>>
--      FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
--        -- ===============================================
--        -- ��z�̂݃f�[�^�X�V
--        -- ===============================================
--        UPDATE xxcok_info_rev_custom xirc
--        SET    ( sales_qty
--                ,sales_amt
--               ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
--                           ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
--                    FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
--                           ,xxcos_sales_exp_lines     xsel  -- �̔����і���
--                           ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
--                           ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
--                           ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
--                    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
--                    AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
--                    AND     flv.lookup_code             =  xsel.sales_class
--                    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
--                    AND     flv.language                =  USERENV( 'LANG' )
--                    AND     flv.enabled_flag            =  'Y'
--                    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                  AND NVL( flv.end_date_active  , gd_process_date )
--                    AND NOT EXISTS ( SELECT '1'
--                                     FROM  fnd_lookup_values flv -- ��݌ɕi��
--                                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
--                                       AND flv.lookup_code         = xsel.item_code
--                                       AND flv.language            = USERENV( 'LANG' )
--                                       AND flv.enabled_flag        = 'Y'
--                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active  , gd_process_date )
--                        )
--                    AND     xseh.ship_to_customer_code        =  xbbs.cust_code
--                    AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --������
--                    AND     xseh.delivery_date                <= xbbs.closing_date --������
--                    AND     xcbs.base_code                    =  xbbs.base_code
--                    AND     xcbs.delivery_cust_code           =  xbbs.cust_code
--                    AND     xcbs.supplier_code                =  xbbs.supplier_code
--                    AND     xcbs.closing_date                 =  xbbs.closing_date
--                    AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
--                    AND     xcbs.calc_type                    =  '40' -- 40:��z
--                    AND     xbbs.supplier_code                = l_fixed_amt_rec.vendor_code
--                    AND     xbbs.cust_code                    = l_fixed_amt_rec.cust_code
--                    AND     xbbs.snapshot_create_ym           = gv_process_ym
--                    AND     xbbs.snapshot_timing              = iv_proc_div
--                    AND     xbbs.resv_flag                    IS NULL
--                    AND     xbbs.balance_cancel_date          IS NULL
--                    AND     xbbs.bm_paymet_kbn                IN ('1','2')
--                    AND EXISTS ( SELECT 1
--                                 FROM  xxcok_info_rev_custom xirc1
--                                 WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
--                                 AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
--                                 AND   xirc1.rev                = '3' -- �V���iFB�j
--                                 AND   xirc1.vendor_code        = xbbs.supplier_code
--                                 AND   xirc1.cust_code          = xbbs.cust_code
--                                 AND   xirc1.vendor_code        = i_no_dif_tab(i).supplier_code
--                                 AND   xirc1.cust_code          = i_no_dif_tab(i).cust_code
--                                 AND   xirc1.request_id         = cn_request_id )
--                    GROUP BY
--                            xbbs.cust_code
--                           ,xbbs.supplier_code
--                   )
--        WHERE xirc.rowid       = l_fixed_amt_rec.row_id
--        ;
----
--      END LOOP fixed_amt_loop;
----
--      -- ===============================================
--      -- �d�C��̂݃f�[�^�擾
--      -- ===============================================
--      <<elctric_loop>>
--      FOR l_electric_rec IN l_electric_cur LOOP
--        -- ===============================================
--        -- �d�C��f�[�^�X�V
--        -- ===============================================
--        UPDATE xxcok_info_rev_custom xirc
--        SET    ( sales_qty
--                ,sales_tax_amt
--                ,sales_amt
--               ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
--                           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- �̔����z�i�ō��j
--                           ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
--                    FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
--                           ,xxcos_sales_exp_lines     xsel  -- �̔����і���
--                           ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
--                           ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
--                           ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
--                    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
--                    AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
--                    AND     flv.lookup_code             =  xsel.sales_class
--                    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
--                    AND     flv.language                =  USERENV( 'LANG' )
--                    AND     flv.enabled_flag            =  'Y'
--                    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                  AND NVL( flv.end_date_active  , gd_process_date )
--                    AND NOT EXISTS ( SELECT '1'
--                                     FROM  fnd_lookup_values flv -- ��݌ɕi��
--                                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
--                                       AND flv.lookup_code         = xsel.item_code
--                                       AND flv.language            = USERENV( 'LANG' )
--                                       AND flv.enabled_flag        = 'Y'
--                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active  , gd_process_date )
--                        )
--                    AND     xseh.ship_to_customer_code        =  xbbs.cust_code
--                    AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --������
--                    AND     xseh.delivery_date                <= xbbs.closing_date                     --������
--                    AND     xcbs.base_code                    =  xbbs.base_code
--                    AND     xcbs.delivery_cust_code           =  xbbs.cust_code
--                    AND     xcbs.supplier_code                =  xbbs.supplier_code
--                    AND     xcbs.closing_date                 =  xbbs.closing_date
--                    AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
--                    AND     xcbs.calc_type                    =  '50'                 -- 50:�d�C��
--                    AND     xbbs.supplier_code                = l_electric_rec.vendor_code
--                    AND     xbbs.cust_code                    = l_electric_rec.cust_code
--                    AND     xbbs.snapshot_create_ym           = gv_process_ym
--                    AND     xbbs.snapshot_timing              = iv_proc_div
--                    AND     xbbs.resv_flag                    IS NULL
--                    AND     xbbs.balance_cancel_date          IS NULL
--                    AND     xbbs.bm_paymet_kbn                IN ('1','2')
--                    AND EXISTS ( SELECT 1
--                                 FROM  xxcok_info_rev_custom xirc1
--                                 WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
--                                 AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
--                                 AND   xirc1.rev                = '3' -- �V���iFB�j
--                                 AND   xirc1.vendor_code        = xbbs.supplier_code
--                                 AND   xirc1.cust_code          = xbbs.cust_code
--                                 AND   xirc1.vendor_code        = i_no_dif_tab(i).supplier_code
--                                 AND   xirc1.cust_code          = i_no_dif_tab(i).cust_code
--                                 AND   xirc1.request_id         = cn_request_id )
--                    GROUP BY
--                            xbbs.cust_code
--                           ,xbbs.supplier_code
--                )
--        WHERE xirc.rowid       = l_electric_rec.row_id
--        ;
--      END LOOP elctric_loop;
----
--      -- ===============================================
--      -- �J�X�^�����׏��o�^(���v�s)
--      -- ===============================================
--      INSERT INTO xxcok_info_rev_custom(
--         snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--        ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O
--        ,rev                         -- REV
--        ,check_result                -- �Ó����`�F�b�N����
--        ,vendor_code                 -- ���t��R�[�h
--        ,cust_code                   -- �ڋq�R�[�h
--        ,inst_dest                   -- �ݒu�ꏊ
--        ,calc_sort                   -- �v�Z�����\�[�g��
--        ,sell_bottle                 -- �����^�e��
--        ,sales_qty                   -- �̔��{��
--        ,sales_tax_amt               -- �̔����z�i�ō��j
--        ,sales_amt                   -- �̔����z�i�Ŕ��j
--        ,sales_fee                   -- �̔��萔���i�Ŕ��j
--        ,tax_amt                     -- �����
--        ,sales_tax_fee               -- �̔��萔���i�ō��j
--        ,tax_div                     -- �ŋ敪
--        ,target_div                  -- �Ώۋ敪
--        ,created_by                  -- �쐬��
--        ,creation_date               -- �쐬��
--        ,last_updated_by             -- �ŏI�X�V��
--        ,last_update_date            -- �ŏI�X�V��
--        ,last_update_login           -- �ŏI�X�V���O�C��
--        ,request_id                  -- �v��ID
--        ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        ,program_id                  -- �R���J�����g�E�v���O����ID
--        ,program_update_date         -- �v���O�����X�V��
--      )
--      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--             ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--             ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
--             ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
--             ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
--             ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
--             ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
--             ,6                               AS  calc_sort               -- �v�Z�����\�[�g��
--             ,'���v'                          AS  sell_bottle             -- �����^�e��
--             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
--             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
--             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
--             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
--             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
--             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
--             ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
--             ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
--             ,cn_created_by                   AS  created_by              -- �쐬��
--             ,SYSDATE                         AS  creation_date           -- �쐬��
--             ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
--             ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
--             ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
--             ,cn_request_id                   AS  request_id              -- �v��ID
--             ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
--             ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
--             ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
--      FROM    xxcok_info_rev_custom  xirc
--      WHERE   xirc.snapshot_create_ym = gv_process_ym
--      AND     xirc.snapshot_timing    = iv_proc_div
--      AND     xirc.rev                = '3' -- �V���iFB�j
--      AND     xirc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
--      AND     xirc.vendor_code        = i_no_dif_tab(i).supplier_code
--      AND     xirc.cust_code          = i_no_dif_tab(i).cust_code
--      AND     xirc.request_id = cn_request_id
--      GROUP BY
--              xirc.vendor_code
--             ,xirc.cust_code
--             ,xirc.inst_dest
--             ,xirc.tax_div
--             ,xirc.target_div
--             ,xirc.snapshot_create_ym
--             ,xirc.snapshot_timing
--      ;
--    END LOOP;
----
--  EXCEPTION
--    -- *** ���ʊ֐�OTHERS��O ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END ins_credit_custom_mon;
-- Els Ver1.1 K.Kanada E
--
  /**********************************************************************************
   * Procedure Name   : ins_credit_custom
   * Description      : �V���J�X�^�����׏��쐬�Q(A-8)
   ***********************************************************************************/
  PROCEDURE ins_credit_custom(
    iv_proc_div   IN  VARCHAR2
--   ,i_no_dif_tab  IN  g_no_dif_ttype  -- Els Ver1.1 K.Kanada
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_credit_custom';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- ��z�̂݃f�[�^�擾
    CURSOR l_fixed_amt_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- �V���iFB�j
      AND    xirc.calc_type          = '40' -- 40:��z
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code        = xirc.vendor_code
                      AND    xirc2.cust_code          = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev                = xirc.rev
                      AND    xirc2.request_id         = xirc.request_id
                      AND    xirc2.calc_type          IN ('10','20','30')
                     )
    ;
--
    l_fixed_amt_rec    l_fixed_amt_cur%ROWTYPE;
--
    -- �d�C��̂݃f�[�^�擾
    CURSOR l_electric_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- �V���iFB�j
      AND    xirc.calc_type  = '50'  -- 50:�d�C��
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code = xirc.vendor_code
                      AND    xirc2.cust_code   = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev         = xirc.rev
                      AND    xirc2.request_id  = xirc.request_id
                      AND    xirc2.calc_type   IN ('10','20','30','40')
                     )
    ;
--
    l_electric_rec    l_electric_cur%ROWTYPE;
--
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �J�X�^�����׏��o�^(���v�s)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
      ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
      ,rev                         -- REV
      ,check_result                -- �Ó����`�F�b�N����
      ,vendor_code                 -- ���t��R�[�h
      ,cust_code                   -- �ڋq�R�[�h
      ,inst_dest                   -- �ݒu�ꏊ
      ,calc_sort                   -- �v�Z�����\�[�g��
      ,sell_bottle                 -- �����^�e��
      ,sales_qty                   -- �̔��{��
      ,sales_tax_amt               -- �̔����z�i�ō��j
      ,sales_amt                   -- �̔����z�i�Ŕ��j
      ,sales_fee                   -- �̔��萔���i�Ŕ��j
      ,tax_amt                     -- �����
      ,sales_tax_fee               -- �̔��萔���i�ō��j
      ,tax_div                     -- �ŋ敪
      ,target_div                  -- �Ώۋ敪
      ,created_by                  -- �쐬��
      ,creation_date               -- �쐬��
      ,last_updated_by             -- �ŏI�X�V��
      ,last_update_date            -- �ŏI�X�V��
      ,last_update_login           -- �ŏI�X�V���O�C��
      ,request_id                  -- �v��ID
      ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                  -- �R���J�����g�E�v���O����ID
      ,program_update_date         -- �v���O�����X�V��
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
-- Ver.1.2 MOD START
--           ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
           ,MAX(xirc.check_result)          AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,2.5                             AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym         = gv_process_ym
    AND     xirc.snapshot_timing            = iv_proc_div
    AND     xirc.rev                        = '3' -- �V���iFB�j
    AND     xirc.calc_type                  IN  ('10','20')
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.snapshot_create_ym
           ,xirc.snapshot_timing
           ,xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
    ;
--
    -- ===============================================
    -- �J�X�^�����׏��o�^�i�ꗥ�������׍s�j
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
      ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
      ,rev                         -- REV
      ,check_result                -- �Ó����`�F�b�N����
      ,vendor_code                 -- ���t��R�[�h
      ,cust_code                   -- �ڋq�R�[�h
      ,inst_dest                   -- �ݒu�ꏊ
      ,calc_type                   -- �v�Z����
      ,calc_sort                   -- �v�Z�����\�[�g��
      ,sell_bottle                 -- �����^�e��
      ,sales_qty                   -- �̔��{��
      ,sales_tax_amt               -- �̔����z�i�ō��j
      ,sales_amt                   -- �̔����z�i�Ŕ��j
      ,contract                    -- ���_����e
      ,sales_fee                   -- �̔��萔���i�Ŕ��j
      ,tax_amt                     -- �����
      ,sales_tax_fee               -- �̔��萔���i�ō��j
      ,bottle_code                 -- �e��敪�R�[�h
      ,salling_price               -- �������z
      ,rebate_rate                 -- ���ߗ�
      ,rebate_amt                  -- ���ߊz
      ,tax_code                    -- �ŃR�[�h
      ,tax_div                     -- �ŋ敪
      ,target_div                  -- �Ώۋ敪
      ,created_by                  -- �쐬��
      ,creation_date               -- �쐬��
      ,last_updated_by             -- �ŏI�X�V��
      ,last_update_date            -- �ŏI�X�V��
      ,last_update_login           -- �ŏI�X�V���O�C��
      ,request_id                  -- �v��ID
      ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                  -- �R���J�����g�E�v���O����ID
      ,program_update_date         -- �v���O�����X�V��
    )
    SELECT  /*+ 
                LEADING(xbbs_1 xseh xsel flv)
                USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                */
            xbbs_1.snapshot_create_ym            AS snapshot_create_ym     -- �X�i�b�v�V���b�g�쐬�N��
           ,xbbs_1.snapshot_timing               AS snapshot_timing        -- �X�i�b�v�V���b�g�^�C�~���O
           ,'3'                                  AS rev                    -- REV�i3:�V���iFB�j)
-- Ver.1.2 MOD START
--           ,'0'                                  AS check_result           -- �Ó����`�F�b�N����
           ,MAX(xbbs_1.check_result)             AS check_result           -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,xbbs_1.supplier_code                 AS vendor_code            -- ���t��R�[�h
           ,xseh.ship_to_customer_code           AS cust_code              -- �ڋq�R�[�h
           ,SUBSTR( xbbs_1.cust_name, 1, 50)     AS inst_dest              -- �ݒu�ꏊ
           ,NULL                                 AS calc_type              -- �v�Z����
           ,'2.7'                                AS calc_sort              -- �v�Z�����\�[�g��
           ,xsel.dlv_unit_price                  AS sell_bottle            -- �����^�e��
           ,SUM( xsel.dlv_qty)                   AS sales_qty              -- �̔��{��
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                 AS sales_tax_amt          -- �̔����z�i�ō��j
           ,SUM( xsel.pure_amount )              AS sales_amt              -- �̔����z�i�Ŕ��j
           ,NULL                                 AS contract               -- ���_����e
           ,NULL                                 AS sales_fee              -- �̔��萔���i�Ŕ��j
           ,NULL                                 AS tax_amt                -- �����
           ,NULL                                 AS sales_tax_fee          -- �̔��萔���i�ō��j
           ,NULL                                 AS bottle_code            -- �e��敪�R�[�h
           ,NULL                                 AS salling_price          -- �������z
           ,NULL                                 AS rebate_rate            -- ���ߗ�
           ,NULL                                 AS rebate_amt             -- ���ߊz
           ,NULL                                 AS tax_code               -- �ŃR�[�h
           ,xbbs_1.tax_div                       AS tax_div                -- �ŋ敪
           ,SUBSTR( xbbs_1.supplier_code, -1, 1) AS target_div             -- �Ώۋ敪
           ,cn_created_by                        AS created_by             -- �쐬��
           ,SYSDATE                              AS creation_date          -- �쐬��
           ,cn_last_updated_by                   AS last_updated_by        -- �ŏI�X�V��
           ,SYSDATE                              AS last_update_date       -- �ŏI�X�V��
           ,cn_last_update_login                 AS last_update_login      -- �ŏI�X�V���O�C��
           ,cn_request_id                        AS request_id             -- �v��id
           ,cn_program_application_id            AS program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����id
           ,cn_program_id                        AS program_id             -- �R���J�����g�E�v���O����id
           ,SYSDATE                              AS program_update_date    -- �v���O�����X�V��
    FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
           ,xxcos_sales_exp_lines     xsel  -- �̔����і���
           ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
           ,(
             SELECT  /*+ LEADING(xbbs xcbs) use_nl(xcbs) */
                     xbbs.supplier_code         AS supplier_code
                    ,xbbs.cust_code             AS cust_code
                    ,xbbs.closing_date          AS closing_date
                    ,xbbs.snapshot_create_ym    AS snapshot_create_ym
                    ,xbbs.snapshot_timing       AS snapshot_timing
                    ,xbbs.cust_name             AS cust_name
                    ,CASE WHEN xbbs.bm_tax_kbn = '1'
                          THEN '2'
                          WHEN xbbs.bm_tax_kbn IN ('2','3')
                          THEN '1'
                     END                        AS tax_div
-- Ver.1.2 ADD START
                    ,(SELECT MAX(xirc2.check_result)
                      FROM   xxcok_info_rev_custom    xirc2
                      WHERE  xirc2.snapshot_create_ym  =  xbbs.snapshot_create_ym
                      AND    xirc2.snapshot_timing     =  xbbs.snapshot_timing
                      AND    xirc2.rev                 =  '3' -- �V���iFB�j
                      AND    xirc2.vendor_code         =  xbbs.supplier_code
                      AND    xirc2.request_id          =  cn_request_id
                     )                          AS check_result
-- Ver.1.2 ADD END
             FROM    xxcok_bm_balance_snap     xbbs   -- �̎�c���e�[�u���X�i�b�v�V���b�g
                    ,xxcok_cond_bm_support     xcbs   -- �����ʔ̎�̋��e�[�u��
             WHERE   xbbs.snapshot_create_ym           =  gv_process_ym
             AND     xbbs.snapshot_timing              =  iv_proc_div
             AND EXISTS (
                     SELECT 1
                     FROM   xxcok_info_rev_custom    xirc
                     WHERE  xirc.snapshot_create_ym    =  xbbs.snapshot_create_ym
                     AND    xirc.snapshot_timing       =  xbbs.snapshot_timing
                     AND    xirc.rev                   =  '3' -- �V���iFB�j
                     AND    xirc.vendor_code           =  xbbs.supplier_code
                     AND    xirc.cust_code             =  xbbs.cust_code
                     AND    xirc.request_id            =  cn_request_id )
             AND     xcbs.base_code                    =  xbbs.base_code
             AND     xcbs.delivery_cust_code           =  xbbs.cust_code
             AND     xcbs.supplier_code                =  xbbs.supplier_code
             AND     xcbs.closing_date                 =  xbbs.closing_date
             AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
             AND     xcbs.calc_type                    =  '30'                -- 30:�ꗥ����
-- Add Ver1.1 K.Kanada S
             -- FB�x���ςݏ���
             AND     xbbs.closing_date <= gd_closing_date          -- �O������
             AND     xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
             AND     xbbs.fb_interface_status  = '1'               -- FB�A�g��
             AND     xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
             AND     xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
             AND     xbbs.payment_amt_tax > 0                      -- FB�x����
-- Add Ver1.1 K.Kanada E
             GROUP BY xbbs.supplier_code
                     ,xbbs.cust_code
                     ,xbbs.closing_date
                     ,xbbs.snapshot_create_ym
                     ,xbbs.snapshot_timing
                     ,xbbs.cust_name
                     ,xbbs.bm_tax_kbn
            ) xbbs_1                        -- �̎���
    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
    AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
    AND     xseh.ship_to_customer_code  =  xbbs_1.cust_code
    AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbbs_1.closing_date, -1)) + 1 --������
    AND     xseh.delivery_date          <= xbbs_1.closing_date                               --������
    AND     flv.lookup_code             =  xsel.sales_class
    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
    AND     flv.language                =  USERENV( 'LANG' )
    AND     flv.enabled_flag            =  'Y'
    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                AND NVL( flv.end_date_active  , gd_process_date )
    AND NOT EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values flv -- ��݌ɕi��
                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
                       AND flv.lookup_code         = xsel.item_code
                       AND flv.language            = USERENV( 'LANG' )
                       AND flv.enabled_flag        = 'Y'
                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND NVL( flv.end_date_active  , gd_process_date )
        )
    GROUP BY
            xseh.ship_to_customer_code
           ,SUBSTR( xbbs_1.cust_name, 1, 50)
           ,xbbs_1.supplier_code
           ,SUBSTR( xbbs_1.supplier_code, -1, 1)
           ,xsel.dlv_unit_price
           ,xbbs_1.snapshot_create_ym
           ,xbbs_1.snapshot_timing
           ,xbbs_1.tax_div
    ;
--
    -- ===============================================
    -- �J�X�^�����׏��o�^(�ꗥ�������v�s)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
      ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
      ,rev                         -- REV
      ,check_result                -- �Ó����`�F�b�N����
      ,vendor_code                 -- ���t��R�[�h
      ,cust_code                   -- �ڋq�R�[�h
      ,inst_dest                   -- �ݒu�ꏊ
      ,calc_sort                   -- �v�Z�����\�[�g��
      ,sell_bottle                 -- �����^�e��
      ,sales_qty                   -- �̔��{��
      ,sales_tax_amt               -- �̔����z�i�ō��j
      ,sales_amt                   -- �̔����z�i�Ŕ��j
      ,sales_fee                   -- �̔��萔���i�Ŕ��j
      ,tax_amt                     -- �����
      ,sales_tax_fee               -- �̔��萔���i�ō��j
      ,tax_div                     -- �ŋ敪
      ,target_div                  -- �Ώۋ敪
      ,created_by                  -- �쐬��
      ,creation_date               -- �쐬��
      ,last_updated_by             -- �ŏI�X�V��
      ,last_update_date            -- �ŏI�X�V��
      ,last_update_login           -- �ŏI�X�V���O�C��
      ,request_id                  -- �v��ID
      ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                  -- �R���J�����g�E�v���O����ID
      ,program_update_date         -- �v���O�����X�V��
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
-- Ver.1.2 MOD START
--           ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
           ,MAX(xirc.check_result)          AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,3.5                             AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym = gv_process_ym
    AND     xirc.snapshot_timing    = iv_proc_div
    AND     xirc.rev                = '3' -- �V���iFB�j
    AND     xirc.calc_type  = '30'
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.snapshot_create_ym
           ,xirc.snapshot_timing
           ,xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
    ;
--
    -- ===============================================
    -- ��z�̂݃f�[�^�擾
    -- ===============================================
    <<fixed_amt_loop>>
    FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
      -- ===============================================
      -- ��z�̂݃f�[�^�X�V
      -- ===============================================
      UPDATE xxcok_info_rev_custom xirc
      SET    ( sales_qty
              ,sales_amt
             ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
                  FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
                         ,xxcos_sales_exp_lines     xsel  -- �̔����і���
                         ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
                         ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
                         ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT '1'
                                   FROM  fnd_lookup_values flv -- ��݌ɕi��
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --������
                  AND     xseh.delivery_date                <= xbbs.closing_date --������
                  AND     xcbs.base_code                    =  xbbs.base_code
                  AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                  AND     xcbs.supplier_code                =  xbbs.supplier_code
                  AND     xcbs.closing_date                 =  xbbs.closing_date
                  AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                  AND     xcbs.calc_type                    =  '40' -- 40:��z
                  AND     xbbs.supplier_code                = l_fixed_amt_rec.vendor_code
                  AND     xbbs.cust_code                    = l_fixed_amt_rec.cust_code
                  AND     xbbs.snapshot_create_ym           = gv_process_ym
                  AND     xbbs.snapshot_timing              = iv_proc_div
-- Add Ver1.1 K.Kanada S
                  -- FB�x���ςݏ���
                  AND     xbbs.closing_date <= gd_closing_date          -- �O������
                  AND     xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
                  AND     xbbs.fb_interface_status  = '1'               -- FB�A�g��
                  AND     xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
                  AND     xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
                  AND     xbbs.payment_amt_tax > 0                      -- FB�x����
-- Add Ver1.1 K.Kanada E
                  AND EXISTS ( SELECT 1
                               FROM  xxcok_info_rev_custom xirc1
                               WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                               AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                               AND   xirc1.rev                = '3' -- �V���iFB�j
                               AND   xirc1.vendor_code        = xbbs.supplier_code
                               AND   xirc1.cust_code          = xbbs.cust_code
                               AND   xirc1.request_id         = cn_request_id )
                  GROUP BY
                          xbbs.cust_code
                         ,xbbs.supplier_code
                 )
      WHERE xirc.rowid       = l_fixed_amt_rec.row_id
      ;
--
    END LOOP fixed_amt_loop;
--
    -- ===============================================
    -- �d�C��̂݃f�[�^�擾
    -- ===============================================
    <<elctric_loop>>
    FOR l_electric_rec IN l_electric_cur LOOP
      -- ===============================================
      -- �d�C��f�[�^�X�V
      -- ===============================================
      UPDATE xxcok_info_rev_custom xirc
      SET    ( sales_qty
              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- �̔����z�i�ō��j
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
                  FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
                         ,xxcos_sales_exp_lines     xsel  -- �̔����і���
                         ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
                         ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
                         ,fnd_lookup_values         flv   -- �Q�ƕ\�i����敪�j
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT '1'
                                   FROM  fnd_lookup_values flv -- ��݌ɕi��
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --������
                  AND     xseh.delivery_date                <= xbbs.closing_date                     --������
                  AND     xcbs.base_code                    =  xbbs.base_code
                  AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                  AND     xcbs.supplier_code                =  xbbs.supplier_code
                  AND     xcbs.closing_date                 =  xbbs.closing_date
                  AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                  AND     xcbs.calc_type                    =  '50'                 -- 50:�d�C��
                  AND     xbbs.supplier_code                = l_electric_rec.vendor_code
                  AND     xbbs.cust_code                    = l_electric_rec.cust_code
                  AND     xbbs.snapshot_create_ym           = gv_process_ym
                  AND     xbbs.snapshot_timing              = iv_proc_div
-- Add Ver1.1 K.Kanada S
                  -- FB�x���ςݏ���
                  AND     xbbs.closing_date <= gd_closing_date          -- �O������
                  AND     xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
                  AND     xbbs.fb_interface_status  = '1'               -- FB�A�g��
                  AND     xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
                  AND     xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
                  AND     xbbs.payment_amt_tax > 0                      -- FB�x����
-- Add Ver1.1 K.Kanada E
                  AND EXISTS ( SELECT 1
                               FROM  xxcok_info_rev_custom xirc1
                               WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                               AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                               AND   xirc1.rev                = '3' -- �V���iFB�j
                               AND   xirc1.vendor_code        = xbbs.supplier_code
                               AND   xirc1.cust_code          = xbbs.cust_code
                               AND   xirc1.request_id         = cn_request_id )
                  GROUP BY
                          xbbs.cust_code
                         ,xbbs.supplier_code
              )
      WHERE xirc.rowid       = l_electric_rec.row_id
      ;
--
    END LOOP elctric_loop;
    -- ===============================================
    -- �J�X�^�����׏��o�^(���v�s)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
      ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O
      ,rev                         -- REV
      ,check_result                -- �Ó����`�F�b�N����
      ,vendor_code                 -- ���t��R�[�h
      ,cust_code                   -- �ڋq�R�[�h
      ,inst_dest                   -- �ݒu�ꏊ
      ,calc_sort                   -- �v�Z�����\�[�g��
      ,sell_bottle                 -- �����^�e��
      ,sales_qty                   -- �̔��{��
      ,sales_tax_amt               -- �̔����z�i�ō��j
      ,sales_amt                   -- �̔����z�i�Ŕ��j
      ,sales_fee                   -- �̔��萔���i�Ŕ��j
      ,tax_amt                     -- �����
      ,sales_tax_fee               -- �̔��萔���i�ō��j
      ,tax_div                     -- �ŋ敪
      ,target_div                  -- �Ώۋ敪
      ,created_by                  -- �쐬��
      ,creation_date               -- �쐬��
      ,last_updated_by             -- �ŏI�X�V��
      ,last_update_date            -- �ŏI�X�V��
      ,last_update_login           -- �ŏI�X�V���O�C��
      ,request_id                  -- �v��ID
      ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                  -- �R���J�����g�E�v���O����ID
      ,program_update_date         -- �v���O�����X�V��
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,xirc.snapshot_timing            AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'3'                             AS  rev                     -- REV�i3:�V���iFB�j)
-- Ver.1.2 MOD START
--           ,'0'                             AS  check_result            -- �Ó����`�F�b�N����
           ,MAX(xirc.check_result)          AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,xirc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xirc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xirc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,6                               AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xirc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xirc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym = gv_process_ym
    AND     xirc.snapshot_timing    = iv_proc_div
    AND     xirc.rev                = '3' -- �V���iFB�j
    AND     xirc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
           ,xirc.snapshot_create_ym
           ,xirc.snapshot_timing
    ;
--
-- Els Ver1.1 K.Kanada E
--    -- ��������d����ɕR�Â��ڋq��V���J�X�^�����ׂ֓o�^
--    INSERT INTO xxcok_info_rev_custom (
--      snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
--     ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
--     ,rev                         -- REV
--     ,check_result                -- �Ó����`�F�b�N����
--     ,row_id                      -- ���e�[�u�����R�[�hID
--     ,edi_interface_date          -- �A�g���iEDI�x���ē����j
--     ,vendor_code                 -- ���t��R�[�h
--     ,cust_code                   -- �ڋq�R�[�h
--     ,inst_dest                   -- �ݒu�ꏊ
--     ,calc_type                   -- �v�Z����
--     ,calc_sort                   -- �v�Z�����\�[�g��
--     ,sell_bottle                 -- �����^�e��
--     ,sales_qty                   -- �̔��{��
--     ,sales_tax_amt               -- �̔����z�i�ō��j
--     ,sales_amt                   -- �̔����z�i�Ŕ��j
--     ,contract                    -- ���_����e
--     ,sales_fee                   -- �̔��萔���i�Ŕ��j
--     ,tax_amt                     -- �����
--     ,sales_tax_fee               -- �̔��萔���i�ō��j
--     ,bottle_code                 -- �e��敪�R�[�h
--     ,salling_price               -- �������z
--     ,rebate_rate                 -- ���ߗ�
--     ,rebate_amt                  -- ���ߊz
--     ,tax_code                    -- �ŃR�[�h
--     ,tax_div                     -- �ŋ敪
--     ,target_div                  -- �Ώۋ敪
--     ,created_by                  -- �쐬��
--     ,creation_date               -- �쐬��
--     ,last_updated_by             -- �ŏI�X�V��
--     ,last_update_date            -- �ŏI�X�V��
--     ,last_update_login           -- �ŏI�X�V���O�C��
--     ,request_id                  -- �v��ID
--     ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--     ,program_id                  -- �R���J�����g�E�v���O����ID
--     ,program_update_date         -- �v���O�����X�V��
--    )
--    SELECT /*+ INDEX(xirc1 xxcok_info_rev_custom_n02) */
--      xirc.snapshot_create_ym            AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--     ,iv_proc_div                        AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O 
--     ,'3'                                AS  rev                     -- REV
--     ,'0'                                AS  check_result            -- �Ó����`�F�b�N����
--     ,NULL                               AS  row_id                  -- ���e�[�u�����R�[�hID
--     ,NULL                               AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
--     ,xirc.vendor_code                   AS  vendor_code             -- ���t��R�[�h
--     ,xirc.cust_code                     AS  cust_code               -- �ڋq�R�[�h
--     ,xirc.inst_dest                     AS  inst_dest               -- �ݒu�ꏊ
--     ,xirc.calc_type                     AS  calc_type               -- �v�Z����
--     ,xirc.calc_sort                     AS  calc_sort               -- �v�Z�����\�[�g��
--     ,xirc.sell_bottle                   AS  sell_bottle             -- �����^�e��
--     ,xirc.sales_qty                     AS  sales_qty               -- �̔��{��
--     ,xirc.sales_tax_amt                 AS  sales_tax_amt           -- �̔����z�i�ō��j
--     ,xirc.sales_amt                     AS  sales_amt               -- �̔����z�i�Ŕ��j
--     ,xirc.contract                      AS  contract                -- ���_����e
--     ,xirc.sales_fee                     AS  sales_fee               -- �̔��萔���i�Ŕ��j
--     ,xirc.tax_amt                       AS  tax_amt                 -- �����
--     ,xirc.sales_tax_fee                 AS  sales_tax_fee           -- �̔��萔���i�ō��j
--     ,xirc.bottle_code                   AS  bottle_code             -- �e��敪�R�[�h
--     ,xirc.salling_price                 AS  salling_price           -- �������z
--     ,xirc.rebate_rate                   AS  rebate_rate             -- ���ߗ�
--     ,xirc.rebate_amt                    AS  rebate_amt              -- ���ߊz
--     ,xirc.tax_code                      AS  tax_code                -- �ŃR�[�h
--     ,xirc.tax_div                       AS  tax_div                 -- �ŋ敪
--     ,xirc.target_div                    AS  target_div              -- �Ώۋ敪
--     ,cn_created_by                      AS  created_by              -- �쐬��
--     ,SYSDATE                            AS  creation_date           -- �쐬��
--     ,cn_last_updated_by                 AS  last_updated_by         -- �ŏI�X�V��
--     ,SYSDATE                            AS  last_update_date        -- �ŏI�X�V��
--     ,cn_last_update_login               AS  last_update_login       -- �ŏI�X�V���O�C��
--     ,cn_request_id                      AS  request_id              -- �v��ID
--     ,cn_program_application_id          AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--     ,cn_program_id                      AS  program_id              -- �R���J�����g�E�v���O����ID
--     ,SYSDATE                            AS  program_update_date     -- �v���O�����X�V��
--    FROM    xxcok_info_rev_custom  xirc
--    WHERE   xirc.snapshot_create_ym = gv_process_ym
--    AND     xirc.snapshot_timing    = '1' -- 2�c
--    AND     xirc.rev                = '1' -- ����
--    AND     xirc.vendor_code IN  (
--              SELECT /*+ INDEX(xirc1 xxcok_info_rev_custom_n02) */
--                     xirc1.vendor_code
--              FROM   xxcok_info_rev_custom  xirc1
--              WHERE  xirc1.snapshot_create_ym = gv_process_ym
--              AND    xirc1.snapshot_timing    = '2' -- FB
--              AND    xirc1.rev                = '3' -- �V��
--              GROUP BY 
--                xirc1.snapshot_create_ym
--               ,xirc1.snapshot_timing
--               ,xirc1.rev
--               ,xirc1.vendor_code
--              )
--    AND NOT EXISTS  (
--              SELECT /*+ INDEX(xirc2 xxcok_info_rev_custom_n02) */
--                     1
--              FROM   xxcok_info_rev_custom  xirc2
--              WHERE  xirc.snapshot_create_ym = xirc2.snapshot_create_ym
--              AND    xirc.vendor_code = xirc2.vendor_code
--              AND    xirc.cust_code = xirc2.cust_code
--              AND    xirc2.snapshot_timing    = '2' -- FB
--              AND    xirc2.rev                = '3' -- �V��
--              )
--    ;
--    -- ���͂��邪�A�V�����쐬���Ȃ��ڋq���폜
--    FOR i IN 1..i_no_dif_tab.COUNT LOOP
----
--      DELETE FROM xxcok_info_rev_custom xirc
--      WHERE  xirc.snapshot_create_ym = gv_process_ym
--      AND    xirc.snapshot_timing    = '2' -- FB
--      AND    xirc.rev                = '3' -- �V��
--      AND    xirc.vendor_code        = i_no_dif_tab(i).supplier_code
--      AND    xirc.cust_code          = i_no_dif_tab(i).cust_code
--      ;
----
--    END LOOP;
-- Els Ver1.1 K.Kanada E
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_credit_custom;
--
-- Divide Ver1.1 K.Kanada   #####  difference_check �� fb��re�̂Q�ɕ���
  /**********************************************************************************
   * Procedure Name   : difference_check_fb
   * Description      : �����`�F�b�N(A-5-1)
   ***********************************************************************************/
--  PROCEDURE difference_check(                 -- Els Ver1.1 K.Kanada
  PROCEDURE difference_check_fb(                -- Add Ver1.1 K.Kanada
    iv_proc_div      IN  VARCHAR2    --  1.�����^�C�~���O
--   ,o_no_dif_tab     OUT g_no_dif_ttype       -- Els Ver1.1 K.Kanada
--   ,o_no_dif_sup_tab OUT g_no_dif_sup_ttype   -- Els Ver1.1 K.Kanada
   ,o_dif_sup_tab    OUT g_dif_sup_ttype        -- Add Ver1.1 K.Kanada
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
-- Mod Ver1.1 K.Kanada S
--    cv_prg_name    CONSTANT VARCHAR2(20) := 'difference_check';  -- �v���O������
    cv_prg_name    CONSTANT VARCHAR2(20) := 'difference_check_fb';  -- �v���O������
-- Mod Ver1.1 K.Kanada E
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Els Ver1.1 K.Kanada S
--    lv_supplier_code_fb_bk  xxcok_bm_balance_snap.supplier_code%TYPE; -- �O�d����R�[�h�iFB�j
--    lv_supplier_code_rec_bk xxcok_bm_balance_snap.supplier_code%TYPE; -- �O�d����R�[�h�i�g�ݖ߂��j
--    ln_count        NUMBER;
-- Els Ver1.1 K.Kanada E
    ln_count_sup    NUMBER;
--
    -- ===============================================
    -- FB�㍷���`�F�b�N�J�[�\��
    -- ===============================================
-- Mod Ver1.1 K.Kanada S
--    CURSOR l_bm_balance_snap_fb_cur (
--             iv_proc_div  IN VARCHAR2
--    )
--    IS
    CURSOR l_bm_balance_snap_fb_cur
    IS
-- Mod Ver1.1 K.Kanada E
-- Add Ver1.1 K.Kanada S
      SELECT diff.supplier_code            AS supplier_code            -- �d����R�[�h
-- Ver.1.2 ADD START
            ,MAX(diff.bm_paymet_kbn_sec)   AS bm_paymet_kbn_sec        -- BM�x���敪(2�c)
-- Ver.1.2 ADD END
      FROM    (
-- Add Ver1.1 K.Kanada E
        SELECT  xbbs_fb.snapshot_create_ym       AS snapshot_create_ym       -- �X�i�b�v�V���b�g�쐬�N��
               ,xbbs_fb.snapshot_timing          AS snapshot_timing          -- �X�i�b�v�V���b�g�^�C�~���O
               ,xbbs_fb.bm_paymet_kbn            AS bm_paymet_kbn            -- BM�x���敪
               ,xbbs_fb.bm_tax_kbn               AS bm_tax_kbn               -- BM�ŋ敪
               ,xbbs_fb.bank_charge_bearer       AS bank_charge_bearer       -- �U���萔�����S��
               ,xbbs_fb.cust_name                AS cust_name                -- �ݒu�於
               ,xbbs_fb.bm_balance_id            AS bm_balance_id            -- �̎�c��ID
               ,xbbs_fb.base_code                AS base_code                -- ���_�R�[�h
               ,xbbs_fb.supplier_code            AS supplier_code            -- �d����R�[�h
               ,xbbs_fb.cust_code                AS cust_code                -- �ڋq�R�[�h
               ,xbbs_fb.closing_date             AS closing_date             -- ���ߓ�
               ,xbbs_fb.expect_payment_date      AS expect_payment_date      -- �x���\���
               ,xbbs_fb.payment_amt_tax          AS payment_amt_tax          -- �x���z�i�ō��j
               ,xbbs_fb.resv_flag                AS resv_flag                -- �ۗ��t���O
               ,xbbs_fb.balance_cancel_date      AS balance_cancel_date      -- �c�������
               ,xbbs_sec.expect_payment_amt_tax  AS expect_payment_amt_tax   -- �����z
               ,xbbs_sec.bank_charge_bearer      AS bank_charge_bearer_pre   -- �U���萔�����S�ҁi���j
-- Ver.1.2 ADD START
               ,xbbs_sec.bm_paymet_kbn           AS bm_paymet_kbn_sec        -- BM�x���敪(2�c)
-- Ver.1.2 ADD END
        FROM
          ( SELECT  /*+ INDEX(xbbs1 xxcok_bm_balance_snap_n01) */
                    xbbs1.bm_balance_id       AS bm_balance_id
                   ,CASE WHEN  xbbs1.closing_date <= gd_closing_date
                           AND xbbs1.expect_payment_date <= gd_schedule_date
                           AND xbbs1.resv_flag IS NULL
                           AND xbbs1.edi_interface_status = '0' -- ���A�g
                           AND xbbs1.fb_interface_status  = '0' -- ���A�g
                           AND xbbs1.gl_interface_status  = '0' -- ���A�g
                           AND xbbs1.amt_fix_status       = '1' -- ���z�m���
                         THEN  xbbs1.expect_payment_amt_tax
                         ELSE  0
                    END                       AS expect_payment_amt_tax  -- �x���\��z�i�ō��j
                   ,xbbs1.bank_charge_bearer  AS bank_charge_bearer      -- �U���萔�����S��
-- Ver.1.2 ADD START
                   ,xbbs1.bm_paymet_kbn       AS bm_paymet_kbn           -- BM�x���敪
-- Ver.1.2 ADD END
            FROM  xxcok_bm_balance_snap xbbs1
            WHERE xbbs1.snapshot_create_ym = gv_process_ym
            AND   xbbs1.snapshot_timing    = '1' -- 2�c
          ) xbbs_sec                          -- �̎�c���X�i�b�v�V���b�g�i2�c�j
         ,( SELECT  /*+ INDEX(xbbs2 xxcok_bm_balance_snap_n01) */
                    xbbs2.snapshot_create_ym  AS snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
                   ,xbbs2.snapshot_timing     AS snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
                   ,xbbs2.bm_paymet_kbn       AS bm_paymet_kbn           -- BM�x���敪
                   ,xbbs2.bm_tax_kbn          AS bm_tax_kbn              -- BM�ŋ敪
                   ,xbbs2.bank_charge_bearer  AS bank_charge_bearer      -- �U���萔�����S��
                   ,xbbs2.cust_name           AS cust_name               -- �ݒu�於
                   ,xbbs2.bm_balance_id       AS bm_balance_id           -- �̎�c��ID
                   ,xbbs2.base_code           AS base_code               -- ���_�R�[�h
                   ,xbbs2.supplier_code       AS supplier_code           -- �d����R�[�h
                   ,xbbs2.cust_code           AS cust_code               -- �ڋq�R�[�h
                   ,xbbs2.closing_date        AS closing_date            -- ���ߓ�
                   ,xbbs2.expect_payment_date AS expect_payment_date     -- �x���\���
                   ,CASE WHEN xbbs2.closing_date <= gd_closing_date
                           AND xbbs2.expect_payment_date <= gd_schedule_date
                           AND xbbs2.fb_interface_status  = '1' -- �A�g��
                           AND xbbs2.balance_cancel_date  IS NULL
                           AND xbbs2.bm_paymet_kbn IN ('1','2') -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
                         THEN  xbbs2.payment_amt_tax
                         ELSE 0
                    END                       AS payment_amt_tax         -- �x���z�i�ō��j
                   ,xbbs2.resv_flag           AS resv_flag               -- �ۗ��t���O
                   ,xbbs2.balance_cancel_date AS balance_cancel_date     -- �c�������
            FROM  xxcok_bm_balance_snap xbbs2
            WHERE xbbs2.snapshot_create_ym = gv_process_ym
            AND   xbbs2.snapshot_timing    = iv_proc_div -- FB
          ) xbbs_fb                           -- �̎�c���X�i�b�v�V���b�g�iFB�j
        WHERE   xbbs_sec.bm_balance_id = xbbs_fb.bm_balance_id
        AND     ( xbbs_sec.bank_charge_bearer <> xbbs_fb.bank_charge_bearer
          OR      xbbs_sec.expect_payment_amt_tax <> xbbs_fb.payment_amt_tax )
-- Els Ver1.1 K.Kanada S
--      ORDER BY  xbbs_fb.supplier_code
--               ,xbbs_fb.cust_code
--               ,xbbs_fb.bm_balance_id
-- Els Ver1.1 K.Kanada E
-- Add Ver1.1 K.Kanada S
        ) diff
      WHERE 1=1
      GROUP BY diff.supplier_code
-- Add Ver1.1 K.Kanada E
      ;
--
      l_bm_balance_snap_fb_rec    l_bm_balance_snap_fb_cur%ROWTYPE;
--
-- Move Ver1.1 K.Kanada S   #####  difference_check_re �Ɉړ�
--    -- ===============================================
--    -- �g�ݖ߂��㍷���`�F�b�N�J�[�\��
--    -- ===============================================
--    CURSOR l_bm_balance_snap_re_cur (
--             iv_proc_div  IN VARCHAR2
--    )
--    IS
--      SELECT  xbbs_rec.snapshot_create_ym      AS snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
--             ,xbbs_rec.snapshot_timing         AS snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
--             ,xbbs_rec.bm_paymet_kbn           AS bm_paymet_kbn           -- BM�x���敪
--             ,xbbs_rec.bm_tax_kbn              AS bm_tax_kbn              -- BM�ŋ敪
--             ,xbbs_rec.bank_charge_bearer      AS bank_charge_bearer      -- �U���萔�����S��
--             ,xbbs_rec.cust_name               AS cust_name               -- �ݒu�於
--             ,xbbs_rec.bm_balance_id           AS bm_balance_id           -- �̎�c��ID
--             ,xbbs_rec.base_code               AS base_code               -- ���_�R�[�h
--             ,xbbs_rec.supplier_code           AS supplier_code           -- �d����R�[�h
--             ,xbbs_rec.cust_code               AS cust_code               -- �ڋq�R�[�h
--             ,xbbs_rec.closing_date            AS closing_date            -- ���ߓ�
--             ,xbbs_rec.expect_payment_date     AS expect_payment_date     -- �x���\���
--             ,xbbs_rec.payment_amt_tax         AS payment_amt_tax         -- �x���z�i�ō��j
--             ,xbbs_rec.resv_flag               AS resv_flag               -- �ۗ��t���O
--             ,xbbs_rec.balance_cancel_date     AS balance_cancel_date     -- �c�������
--             ,xbbs_fb.payment_amt_tax          AS payment_amt_tax_pre     -- �����z
--             ,xbbs_fb.bank_charge_bearer       AS bank_charge_bearer_pre  -- �U���萔�����S�ҁi���j
--      FROM
--        ( SELECT  xbbs3.bm_balance_id       AS bm_balance_id
--                 ,CASE WHEN  xbbs3.closing_date <= gd_closing_date
--                         AND xbbs3.expect_payment_date <= gd_schedule_date
--                         AND xbbs3.fb_interface_status  = '1'
--                         AND xbbs3.balance_cancel_date  IS NULL
--                         AND xbbs3.bm_paymet_kbn IN ('1','2')
--                       THEN  xbbs3.payment_amt_tax
--                       ELSE 0
--                  END                       AS payment_amt_tax
--                 ,xbbs3.bank_charge_bearer  AS bank_charge_bearer
--          FROM  xxcok_bm_balance_snap xbbs3
--          WHERE xbbs3.snapshot_create_ym = gv_process_ym
--          AND   xbbs3.snapshot_timing    = '2' -- FB
--        ) xbbs_fb                           -- �̎�c���X�i�b�v�V���b�g�iFB�j
--       ,( SELECT  xbbs4.snapshot_create_ym  AS snapshot_create_ym         -- �X�i�b�v�V���b�g�쐬�N��
--                 ,xbbs4.snapshot_timing     AS snapshot_timing            -- �X�i�b�v�V���b�g�^�C�~���O
--                 ,xbbs4.bm_paymet_kbn       AS bm_paymet_kbn              -- BM�x���敪
--                 ,xbbs4.bm_tax_kbn          AS bm_tax_kbn                 -- BM�ŋ敪
--                 ,xbbs4.bank_charge_bearer  AS bank_charge_bearer         -- �U���萔�����S��
--                 ,xbbs4.cust_name           AS cust_name                  -- �ݒu�於
--                 ,xbbs4.bm_balance_id       AS bm_balance_id              -- �̎�c��ID
--                 ,xbbs4.base_code           AS base_code                  -- ���_�R�[�h
--                 ,xbbs4.supplier_code       AS supplier_code              -- �d����R�[�h
--                 ,xbbs4.cust_code           AS cust_code                  -- �ڋq�R�[�h
--                 ,xbbs4.closing_date        AS closing_date               -- ���ߓ�
--                 ,xbbs4.expect_payment_date AS expect_payment_date        -- �x���\���
--                 ,CASE WHEN  xbbs4.closing_date <= gd_closing_date
--                         AND xbbs4.expect_payment_date <= gd_schedule_date
--                         AND xbbs4.fb_interface_status  = '1'
--                         AND xbbs4.balance_cancel_date  IS NULL
--                         AND xbbs4.bm_paymet_kbn IN ('1','2')
--                       THEN  xbbs4.payment_amt_tax
--                       ELSE 0
--                  END                       AS payment_amt_tax            -- �x���z�i�ō��j
--                 ,xbbs4.resv_flag           AS resv_flag                  -- �ۗ��t���O
--                 ,xbbs4.balance_cancel_date AS balance_cancel_date        -- �c�������
--          FROM  xxcok_bm_balance_snap xbbs4
--          WHERE xbbs4.snapshot_create_ym = gv_process_ym
--          AND   xbbs4.snapshot_timing    = iv_proc_div -- �g�ݖ߂�
--        ) xbbs_rec                          -- �̎�c���X�i�b�v�V���b�g�i�g�ݖ߂��j
--      WHERE   xbbs_fb.bm_balance_id = xbbs_rec.bm_balance_id
--      AND     xbbs_fb.payment_amt_tax <> xbbs_rec.payment_amt_tax
--      ORDER BY  xbbs_rec.supplier_code
--               ,xbbs_rec.bm_balance_id
--      ;
----
--      l_bm_balance_snap_re_rec    l_bm_balance_snap_re_cur%ROWTYPE;
-- Move Ver1.1 K.Kanada E   #####  difference_check_re �Ɉړ�
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ������
    -- ===============================================
-- Els Ver1.1 K.Kanada S
--    lv_supplier_code_fb_bk  := 'X';
--    lv_supplier_code_rec_bk := 'X';
--    ln_count     := 0;
--    ln_count_sup := 0;
--    o_no_dif_tab.delete;
--    o_no_dif_sup_tab.delete;
-- Els Ver1.1 K.Kanada E
-- Add Ver1.1 K.Kanada S
    ln_count_sup := 0;
    o_dif_sup_tab.delete;
-- Add Ver1.1 K.Kanada E
--
-- Els Ver1.1 K.Kanada S
--    -- ===============================================
--    -- �����^�C�~���O��FB��̏ꍇ
--    -- ===============================================
--    IF ( iv_proc_div = '2' ) THEN
--      -- ===============================================
--      -- A-7.�V���J�X�^�����׏��쐬�P
--      -- ===============================================
--      OPEN l_bm_balance_snap_fb_cur (
--             iv_proc_div
--           );
-- Els Ver1.1 K.Kanada E
-- Add Ver1.1 K.Kanada S
    -- ===============================================
    -- FB�㍷���`�F�b�N�J�[�\��
    -- ===============================================
    OPEN l_bm_balance_snap_fb_cur ;
-- Add Ver1.1 K.Kanada E
--
    << snap_fb_loop >>
    LOOP
      FETCH l_bm_balance_snap_fb_cur INTO l_bm_balance_snap_fb_rec;
      EXIT WHEN l_bm_balance_snap_fb_cur%NOTFOUND;
--
-- Els Ver1.1 K.Kanada S
--        /* �x���z�i�ō��j��0���傫�����ۗ��t���O��'Y'�ł͂Ȃ��܂��͎c����������ݒ肳��Ă��Ȃ��ꍇ�A
--        �܂���BM�x���敪��1:�{�U�i�ē�������j�A2:�{�U�i�ē����Ȃ��j�̏ꍇ�A�쐬����B*/
--        IF ( l_bm_balance_snap_fb_rec.payment_amt_tax > 0
--             AND ( NVL(l_bm_balance_snap_fb_rec.resv_flag,'N') <> 'Y'
--                   OR l_bm_balance_snap_fb_rec.balance_cancel_date IS NULL
--                   OR l_bm_balance_snap_fb_rec.bm_paymet_kbn IN ('1','2') )) THEN
--          NULL;
--        ELSE
--          -- �J�E���g�A�b�v
--          ln_count := ln_count + 1;
--          o_no_dif_tab(ln_count).supplier_code := l_bm_balance_snap_fb_rec.supplier_code;
--          o_no_dif_tab(ln_count).cust_code     := l_bm_balance_snap_fb_rec.cust_code;
--          -- �d����J�E���g�A�b�v
--          IF ( l_bm_balance_snap_fb_rec.supplier_code <> lv_supplier_code_fb_bk ) THEN
--            ln_count_sup := ln_count_sup + 1;
--            o_no_dif_sup_tab(ln_count_sup).supplier_code := l_bm_balance_snap_fb_rec.supplier_code;
--          END IF;
--        END IF;
-- Els Ver1.1 K.Kanada E
--
      -- �d����J�E���g�A�b�v
      gn_dif_cnt := gn_dif_cnt + 1;  -- �����Ώ�
      ln_count_sup := ln_count_sup + 1;
      o_dif_sup_tab(ln_count_sup).supplier_code := l_bm_balance_snap_fb_rec.supplier_code;
--
      -- ===============================================
      -- A-7.�V���J�X�^�����׏��쐬�P
      -- ===============================================
      BEGIN
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
         ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
         ,rev                         -- REV
         ,check_result                -- �Ó����`�F�b�N����
         ,row_id                      -- ���e�[�u�����R�[�hID
         ,edi_interface_date          -- �A�g���iEDI�x���ē����j
         ,vendor_code                 -- ���t��R�[�h
         ,cust_code                   -- �ڋq�R�[�h
         ,inst_dest                   -- �ݒu�ꏊ
         ,calc_type                   -- �v�Z����
         ,calc_sort                   -- �v�Z�����\�[�g��
         ,sell_bottle                 -- �����^�e��
         ,sales_qty                   -- �̔��{��
         ,sales_tax_amt               -- �̔����z�i�ō��j
         ,sales_amt                   -- �̔����z�i�Ŕ��j
         ,contract                    -- ���_����e
         ,sales_fee                   -- �̔��萔���i�Ŕ��j
         ,tax_amt                     -- �����
         ,sales_tax_fee               -- �̔��萔���i�ō��j
         ,bottle_code                 -- �e��敪�R�[�h
         ,salling_price               -- �������z
         ,rebate_rate                 -- ���ߗ�
         ,rebate_amt                  -- ���ߊz
         ,tax_code                    -- �ŃR�[�h
         ,tax_div                     -- �ŋ敪
         ,target_div                  -- �Ώۋ敪
         ,created_by                  -- �쐬��
         ,creation_date               -- �쐬��
         ,last_updated_by             -- �ŏI�X�V��
         ,last_update_date            -- �ŏI�X�V��
         ,last_update_login           -- �ŏI�X�V���O�C��
         ,request_id                  -- �v��ID
         ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                  -- �R���J�����g�E�v���O����ID
         ,program_update_date         -- �v���O�����X�V��
        )
        SELECT
            xbbs.snapshot_create_ym                 AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,xbbs.snapshot_timing                    AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'3'                                     AS  rev                     -- REV�i3:�V���iFB�j)
-- Ver.1.2 MOD START
--           ,'0'                                     AS  check_result            -- �Ó����`�F�b�N���ʁi0:�Ώہj
           ,CASE
              WHEN l_bm_balance_snap_fb_rec.bm_paymet_kbn_sec = '1' THEN  -- BM�x���敪(2�c)���{�U(�ē�������)�̏ꍇ
                '0'  -- �Ώ�
              ELSE
                '1'  -- �ΏۊO
            END                                     AS  check_result            -- �Ó����`�F�b�N����
-- Ver.1.2 MOD END
           ,NULL                                    AS  row_id                  -- ���e�[�u�����R�[�hID
           ,NULL                                    AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
           ,xbbs.supplier_code                      AS  vendor_code             -- ���t��R�[�h
           ,xcbs.delivery_cust_code                 AS  cust_code               -- �ڋq�R�[�h
           ,SUBSTR( xbbs.cust_name, 1, 50 )         AS  inst_dest               -- �ݒu�ꏊ
           ,xcbs.calc_type                          AS  calc_type               -- �v�Z����
           ,flv2.calc_type_sort                     AS  calc_sort               -- �v�Z�����\�[�g��
           ,CASE xcbs.calc_type
              WHEN '10'
              THEN TO_CHAR( xcbs.selling_price )
              WHEN '20'
              THEN SUBSTR( flv1.container_type_name, 1, 10 )
              ELSE flv2.disp
            END                                     AS  sell_bottle             -- �����^�e��
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.delivery_qty )
            END                                     AS  sales_qty               -- �̔��{��
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_tax )
            END                                     AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_no_tax )
            END                                     AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,CASE
              WHEN ( xcbs.rebate_rate IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_rate || '%'
              WHEN ( xcbs.rebate_amt IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_amt || '�~'
            END                                     AS  contract                -- ���_����e
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_no_tax )
              ELSE SUM( xcbs.cond_bm_amt_no_tax )
            END                                     AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_tax_amt )
              ELSE SUM( xcbs.cond_tax_amt )
            END                                     AS  tax_amt                 -- �����
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_tax )
              ELSE SUM( xcbs.cond_bm_amt_tax )
            END                                     AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,flv1.container_type_code                AS  bottle_code             -- �e��敪�R�[�h
           ,xcbs.selling_price                      AS  salling_price           -- �������z
           ,xcbs.rebate_rate                        AS  rebate_rate             -- ���ߗ�
           ,xcbs.rebate_amt                         AS  rebate_amt              -- ���ߊz
           ,xbbs.tax_code                           AS  tax_code                -- �ŃR�[�h
           ,CASE
              WHEN xbbs.bm_tax_kbn = '1'
              THEN '2'
              WHEN xbbs.bm_tax_kbn IN ('2','3')
              THEN '1'
            END                                     AS  tax_div                 -- �ŋ敪
           ,SUBSTR( xbbs.supplier_code, -1, 1 )     AS  target_div              -- �Ώۋ敪
           ,cn_created_by                           AS  created_by              -- �쐬��
           ,SYSDATE                                 AS  creation_date           -- �쐬��
           ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                           AS  request_id              -- �v��ID
           ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
        FROM  xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
             ,xxcok_bm_balance_snap     xbbs  -- �̎�c���e�[�u���X�i�b�v�V���b�g
             ,(SELECT flv.attribute1 AS container_type_code
                     ,flv.meaning    AS container_type_name
               FROM fnd_lookup_values flv
               WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
               AND flv.language      = USERENV( 'LANG' )
              )                         flv1  -- �Q�ƕ\�i�e��j
             ,(SELECT flv.lookup_code AS calc_type
                     ,flv.meaning     AS line_name
                     ,flv.attribute2  AS calc_type_sort
                     ,flv.attribute3  AS disp
               FROM fnd_lookup_values flv
               WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
               AND flv.language      = USERENV( 'LANG' )
              )                         flv2  -- �Q�ƕ\�i�̎�v�Z�����j
-- Mod Ver1.1 K.Kanada S
--        WHERE  xbbs.bm_balance_id                     = l_bm_balance_snap_fb_rec.bm_balance_id
        WHERE  1=1
        AND    xbbs.supplier_code         = l_bm_balance_snap_fb_rec.supplier_code  --�����Ώێd����
-- Mod Ver1.1 K.Kanada E
        AND    xbbs.snapshot_create_ym    = gv_process_ym
        AND    xbbs.snapshot_timing       = iv_proc_div
        AND    xcbs.base_code             = xbbs.base_code
        AND    xcbs.delivery_cust_code    = xbbs.cust_code
        AND    xcbs.supplier_code         = xbbs.supplier_code
        AND    xcbs.closing_date          = xbbs.closing_date
        AND    xcbs.expect_payment_date   = xbbs.expect_payment_date
        AND    xcbs.container_type_code   = flv1.container_type_code(+)
        AND    xcbs.calc_type             = flv2.calc_type
-- Add Ver1.1 K.Kanada S
        -- FB�x���ςݏ���
        AND    xbbs.closing_date <= gd_closing_date          -- �O������
        AND    xbbs.expect_payment_date <= gd_schedule_date  -- ����20����
        AND    xbbs.fb_interface_status  = '1'               -- FB�A�g��
        AND    xbbs.balance_cancel_date  IS NULL             -- �L�����Z������Ă��Ȃ�
        AND    xbbs.bm_paymet_kbn IN ('1','2')               -- '1'(�{�U(�ē�������),'2'(�{�U(�ē����Ȃ�))
        AND    xbbs.payment_amt_tax > 0                      -- FB�x����
-- Add Ver1.1 K.Kanada E
        GROUP BY
               xbbs.snapshot_create_ym
              ,xbbs.snapshot_timing
              ,xbbs.supplier_code
              ,xcbs.delivery_cust_code
              ,SUBSTR(xbbs.cust_name,1,50)
              ,xcbs.calc_type
              ,flv2.calc_type_sort
              ,flv1.container_type_code
              ,flv1.container_type_name
              ,xcbs.selling_price
              ,xcbs.rebate_rate
              ,xcbs.rebate_amt
              ,xbbs.tax_code
              ,xbbs.bm_tax_kbn
              ,flv2.disp
        ;
-- Add Ver1.1 K.Kanada S
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL ;                  -- �S���/�S�ۗ��̏ꍇ�A�J�X�^�����ׂ��쐬�ł��Ȃ��̂� NO_DATA_FOUND �̏����ǉ�
      END ;
-- Add Ver1.1 K.Kanada E
-- Els Ver1.1 K.Kanada S
--        -- �d����R�[�h���O�d����R�[�h�ƈقȂ�ꍇ�A�����ΏۃJ�E���g�A�b�v
--        IF ( l_bm_balance_snap_fb_rec.supplier_code <> lv_supplier_code_fb_bk ) THEN
--          -- �����ΏۃJ�E���g
--          gn_dif_cnt := gn_dif_cnt + 1;
--        END IF;
--        -- �d����R�[�h�ێ�
--        lv_supplier_code_fb_bk := l_bm_balance_snap_fb_rec.supplier_code;
--      END LOOP snap_fb_loop;
----
--    END IF;
-- Els Ver1.1 K.Kanada E
--
    END LOOP snap_fb_loop;
--
-- Add Ver1.1 K.Kanada S
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END difference_check_fb;
-- Add Ver1.1 K.Kanada E
--
-- Add Ver1.1 K.Kanada S
  /**********************************************************************************
   * Procedure Name   : difference_check_re
   * Description      : �����`�F�b�N�i�g�ݖ߂���j(A-5-2)
   ***********************************************************************************/
  PROCEDURE difference_check_re(
    iv_proc_div      IN  VARCHAR2    --  1.�����^�C�~���O
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'difference_check_re';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_supplier_code_rec_bk xxcok_bm_balance_snap.supplier_code%TYPE; -- �O�d����R�[�h�i�g�ݖ߂��j
-- Add Ver1.1 K.Kanada E
--
-- Move Ver1.1 K.Kanada S   #####  difference_check ����ړ�
    -- ===============================================
    -- �g�ݖ߂��㍷���`�F�b�N�J�[�\��
    -- ===============================================
    CURSOR l_bm_balance_snap_re_cur 
    IS
      SELECT  xbbs_rec.snapshot_create_ym      AS snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
             ,xbbs_rec.snapshot_timing         AS snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
             ,xbbs_rec.bm_paymet_kbn           AS bm_paymet_kbn           -- BM�x���敪
             ,xbbs_rec.bm_tax_kbn              AS bm_tax_kbn              -- BM�ŋ敪
             ,xbbs_rec.bank_charge_bearer      AS bank_charge_bearer      -- �U���萔�����S��
             ,xbbs_rec.cust_name               AS cust_name               -- �ݒu�於
             ,xbbs_rec.bm_balance_id           AS bm_balance_id           -- �̎�c��ID
             ,xbbs_rec.base_code               AS base_code               -- ���_�R�[�h
             ,xbbs_rec.supplier_code           AS supplier_code           -- �d����R�[�h
             ,xbbs_rec.cust_code               AS cust_code               -- �ڋq�R�[�h
             ,xbbs_rec.closing_date            AS closing_date            -- ���ߓ�
             ,xbbs_rec.expect_payment_date     AS expect_payment_date     -- �x���\���
             ,xbbs_rec.payment_amt_tax         AS payment_amt_tax         -- �x���z�i�ō��j
             ,xbbs_rec.resv_flag               AS resv_flag               -- �ۗ��t���O
             ,xbbs_rec.balance_cancel_date     AS balance_cancel_date     -- �c�������
             ,xbbs_fb.payment_amt_tax          AS payment_amt_tax_pre     -- �����z
             ,xbbs_fb.bank_charge_bearer       AS bank_charge_bearer_pre  -- �U���萔�����S�ҁi���j
      FROM
        ( SELECT  xbbs3.bm_balance_id       AS bm_balance_id
                 ,CASE WHEN  xbbs3.closing_date <= gd_closing_date
                         AND xbbs3.expect_payment_date <= gd_schedule_date
                         AND xbbs3.fb_interface_status  = '1'
                         AND xbbs3.balance_cancel_date  IS NULL
                         AND xbbs3.bm_paymet_kbn IN ('1','2')
                       THEN  xbbs3.payment_amt_tax
                       ELSE 0
                  END                       AS payment_amt_tax
                 ,xbbs3.bank_charge_bearer  AS bank_charge_bearer
          FROM  xxcok_bm_balance_snap xbbs3
          WHERE xbbs3.snapshot_create_ym = gv_process_ym
          AND   xbbs3.snapshot_timing    = '2' -- FB
        ) xbbs_fb                           -- �̎�c���X�i�b�v�V���b�g�iFB�j
       ,( SELECT  xbbs4.snapshot_create_ym  AS snapshot_create_ym         -- �X�i�b�v�V���b�g�쐬�N��
                 ,xbbs4.snapshot_timing     AS snapshot_timing            -- �X�i�b�v�V���b�g�^�C�~���O
                 ,xbbs4.bm_paymet_kbn       AS bm_paymet_kbn              -- BM�x���敪
                 ,xbbs4.bm_tax_kbn          AS bm_tax_kbn                 -- BM�ŋ敪
                 ,xbbs4.bank_charge_bearer  AS bank_charge_bearer         -- �U���萔�����S��
                 ,xbbs4.cust_name           AS cust_name                  -- �ݒu�於
                 ,xbbs4.bm_balance_id       AS bm_balance_id              -- �̎�c��ID
                 ,xbbs4.base_code           AS base_code                  -- ���_�R�[�h
                 ,xbbs4.supplier_code       AS supplier_code              -- �d����R�[�h
                 ,xbbs4.cust_code           AS cust_code                  -- �ڋq�R�[�h
                 ,xbbs4.closing_date        AS closing_date               -- ���ߓ�
                 ,xbbs4.expect_payment_date AS expect_payment_date        -- �x���\���
                 ,CASE WHEN  xbbs4.closing_date <= gd_closing_date
                         AND xbbs4.expect_payment_date <= gd_schedule_date
                         AND xbbs4.fb_interface_status  = '1'
                         AND xbbs4.balance_cancel_date  IS NULL
                         AND xbbs4.bm_paymet_kbn IN ('1','2')
                       THEN  xbbs4.payment_amt_tax
                       ELSE 0
                  END                       AS payment_amt_tax            -- �x���z�i�ō��j
                 ,xbbs4.resv_flag           AS resv_flag                  -- �ۗ��t���O
                 ,xbbs4.balance_cancel_date AS balance_cancel_date        -- �c�������
          FROM  xxcok_bm_balance_snap xbbs4
          WHERE xbbs4.snapshot_create_ym = gv_process_ym
          AND   xbbs4.snapshot_timing    = iv_proc_div -- �g�ݖ߂�
        ) xbbs_rec                          -- �̎�c���X�i�b�v�V���b�g�i�g�ݖ߂��j
      WHERE   xbbs_fb.bm_balance_id = xbbs_rec.bm_balance_id
      AND     xbbs_fb.payment_amt_tax <> xbbs_rec.payment_amt_tax
      ORDER BY  xbbs_rec.supplier_code
               ,xbbs_rec.bm_balance_id
      ;
--
      l_bm_balance_snap_re_rec    l_bm_balance_snap_re_cur%ROWTYPE;
-- Move Ver1.1 K.Kanada E   #####  difference_check ����ړ�
--
-- Add Ver1.1 K.Kanada S
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ������
    -- ===============================================
    lv_supplier_code_rec_bk := 'X';
--
-- Add Ver1.1 K.Kanada E
    -- ===============================================
    -- �����^�C�~���O���g�ݖ߂���̏ꍇ
    -- ===============================================
    IF ( iv_proc_div = '3' ) THEN
      -- ===============================================
      -- A-6.�ԃf�[�^�쐬�i�g�ݖ߂���j
      -- ===============================================
      OPEN l_bm_balance_snap_re_cur ;
      << snap_re_loop >>
      LOOP
        FETCH l_bm_balance_snap_re_cur INTO l_bm_balance_snap_re_rec;
        EXIT WHEN l_bm_balance_snap_re_cur%NOTFOUND;
--
        -- �d����R�[�h���O�d����R�[�h�ƈقȂ�ꍇ�A�����ΏۃJ�E���g�A�b�v
        IF ( l_bm_balance_snap_re_rec.supplier_code <> lv_supplier_code_rec_bk ) THEN
          -- �����ΏۃJ�E���g
          gn_dif_cnt := gn_dif_cnt + 1;
        -- �d����R�[�h���O�d����R�[�h�Ɠ����ꍇ�A�X�L�b�v����
        ELSE
          CONTINUE;
        END IF;
--
        -- ===============================================
        -- �ԃw�b�_�[�̍쐬
        -- ===============================================
        -- �V�������݂���ꍇ
        INSERT INTO xxcok_info_rev_header(
          snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
         ,snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
         ,rev                     -- REV
         ,check_result            -- �Ó����`�F�b�N����
         ,row_id                  -- ���e�[�u�����R�[�hID
         ,edi_interface_date      -- �A�g���iEDI�x���ē����j
         ,vendor_code             -- ���t��R�[�h
         ,set_code                -- �ʒm�������ݒ�R�[�h
         ,cust_code               -- �ڋq�R�[�h
         ,cust_name               -- ��Ж�
         ,dest_post_code          -- �X�֔ԍ�
         ,dest_address1           -- �Z��
         ,dest_tel                -- �d�b�ԍ�
         ,fax                     -- FAX�ԍ�
         ,dept_name               -- ������
         ,send_post_code          -- �X�֔ԍ��i���t���j
         ,send_address1           -- �Z���i���t���j
         ,send_tel                -- �d�b�ԍ��i���t���j
         ,num                     -- �ԍ�
         ,payment_date            -- �x����
         ,closing_date            -- ���ߓ�
         ,closing_date_min        -- �ŏ����ߓ�
         ,notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
         ,total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
         ,tax_amt_10              -- 10%����Ŋz
         ,total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
         ,total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
         ,tax_amt_8               -- �y��8%����Ŋz
         ,total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
         ,total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
         ,tax_amt_0               -- ��ېŏ���Ŋz
         ,total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
         ,total_sales_qty         -- �̔��{�����v
         ,total_sales_amt         -- �̔����z���v
         ,sales_fee               -- �̔��萔��
         ,electric_amt            -- �d�C�㓙���v�@�Ŕ�
         ,tax_amt                 -- �����
         ,transfer_fee            -- �U���萔�� �ō�
         ,payment_amt             -- ���x�����z �ō�
         ,remarks                 -- �����Ĕ��l
         ,bank_code               -- ��s�R�[�h
         ,bank_name               -- ��s��
         ,branch_code             -- �x�X�R�[�h
         ,branch_name             -- �x�X��
         ,bank_holder_name_alt    -- ������
         ,tax_div                 -- �ŋ敪
         ,target_div              -- �Ώۋ敪
         ,created_by              -- �쐬��
         ,creation_date           -- �쐬��
         ,last_updated_by         -- �ŏI�X�V��
         ,last_update_date        -- �ŏI�X�V��
         ,last_update_login       -- �ŏI�X�V���O�C��
         ,request_id              -- �v��ID
         ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              -- �R���J�����g�E�v���O����ID
         ,program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
         ,bm_payment_kbn            -- BM�x���敪
         ,tax_calc_kbn              -- �Ōv�Z�敪
         ,bm_tax_kbn                -- BM�ŋ敪
         ,bank_charge_bearer        -- �U���萔�����S��
         ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
         ,sales_fee_tax             -- �̔��萔���i����Łj
         ,sales_fee_with_tax        -- �̔��萔���i�ō��j
         ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
         ,electric_amt_tax          -- �d�C�㓙�i����Łj
         ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
         ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
         ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
         ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
         ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
         ,bank_trans_fee_tax        -- �U���萔���i����Łj
         ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
         ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
         ,display_code              -- �\���R�[�h
         ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
        )
        SELECT
            xirh.snapshot_create_ym                   AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,iv_proc_div                               AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'4'                                       AS  rev                     -- REV 4�F�ԁi�g�ݖ߂��j
           ,'0'                                       AS  check_result            -- �Ó����`�F�b�N����
           ,NULL                                      AS  row_id                  -- ���e�[�u�����R�[�hID
           ,NULL                                      AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
           ,xirh.vendor_code                          AS  vendor_code             -- ���t��R�[�h
           ,xirh.set_code                             AS  set_code                -- �ʒm�������ݒ�R�[�h
           ,xirh.cust_code                            AS  cust_code               -- �ڋq�R�[�h
           ,xirh.cust_name                            AS  cust_name               -- ��Ж�
           ,xirh.dest_post_code                       AS  dest_post_code          -- �X�֔ԍ�
           ,xirh.dest_address1                        AS  dest_address1           -- �Z��
           ,xirh.dest_tel                             AS  dest_tel                -- �d�b�ԍ�
           ,xirh.fax                                  AS  fax                     -- FAX�ԍ�
           ,xirh.dept_name                            AS  dept_name               -- ������
           ,xirh.send_post_code                       AS  send_post_code          -- �X�֔ԍ��i���t���j
           ,xirh.send_address1                        AS  send_address1           -- �Z���i���t���j
           ,xirh.send_tel                             AS  send_tel                -- �d�b�ԍ��i���t���j
           ,xirh.num                                  AS  num                     -- �ԍ�
           ,xirh.payment_date                         AS  payment_date            -- �x����
           ,xirh.closing_date                         AS  closing_date            -- ���ߓ�
           ,xirh.closing_date_min                     AS  closing_date_min        -- �ŏ����ߓ�
           ,(xirh.notifi_amt) * -1                    AS  notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
           ,(xirh.total_amt_no_tax_10) * -1           AS  total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
           ,(xirh.tax_amt_10) * -1                    AS  tax_amt_10              -- 10%����Ŋz
           ,(xirh.total_amt_10) * -1                  AS  total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
           ,(xirh.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
           ,(xirh.tax_amt_8) * -1                     AS  tax_amt_8               -- �y��8%����Ŋz
           ,(xirh.total_amt_8) * -1                   AS  total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
           ,(xirh.total_amt_no_tax_0) * -1            AS  total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
           ,(xirh.tax_amt_0) * -1                     AS  tax_amt_0               -- ��ېŏ���Ŋz
           ,(xirh.total_amt_0) * -1                   AS  total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
           ,(xirh.total_sales_qty) * -1               AS  total_sales_qty         -- �̔��{�����v
           ,(xirh.total_sales_amt) * -1               AS  total_sales_amt         -- �̔����z���v
           ,(xirh.sales_fee) * -1                     AS  sales_fee               -- �̔��萔��
           ,(xirh.electric_amt) * -1                  AS  electric_amt            -- �d�C�㓙���v �Ŕ�
           ,(xirh.tax_amt) * -1                       AS  tax_amt                 -- �����
           ,(xirh.transfer_fee) * -1                  AS  transfer_fee            -- �U���萔�� �ō�
           ,(xirh.payment_amt) * -1                   AS  payment_amt             -- ���x�����z �ō�
           ,'"'||SUBSTR(gv_remarks_re_deb,1,500)||'"' AS  remarks                 -- �����Ĕ��l
           ,xirh.bank_code                            AS  bank_code               -- ��s�R�[�h
           ,xirh.bank_name                            AS  bank_name               -- ��s��
           ,xirh.branch_code                          AS  branch_code             -- �x�X�R�[�h
           ,xirh.branch_name                          AS  branch_name             -- �x�X��
           ,xirh.bank_holder_name_alt                 AS  bank_holder_name_alt    -- ������
           ,xirh.tax_div                              AS  tax_div                 -- �ŋ敪
           ,xirh.target_div                           AS  target_div              -- �Ώۋ敪
           ,cn_created_by                             AS  created_by              -- �쐬��
           ,SYSDATE                                   AS  creation_date           -- �쐬��
           ,cn_last_updated_by                        AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                   AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                      AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                             AS  request_id              -- �v��ID
           ,cn_program_application_id                 AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                             AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                   AS  program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
           ,xirh.bm_payment_kbn                       AS  bm_payment_kbn            -- BM�x���敪
           ,xirh.tax_calc_kbn                         AS  tax_calc_kbn              -- �Ōv�Z�敪
           ,xirh.bm_tax_kbn                           AS  bm_tax_kbn                -- BM�ŋ敪
           ,xirh.bank_charge_bearer                   AS  bank_charge_bearer        -- �U���萔�����S��
           ,(xirh.sales_fee_no_tax) * -1              AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
           ,(xirh.sales_fee_tax) * -1                 AS  sales_fee_tax             -- �̔��萔���i����Łj
           ,(xirh.sales_fee_with_tax) * -1            AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
           ,(xirh.electric_amt_no_tax) * -1           AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
           ,(xirh.electric_amt_tax) * -1              AS  electric_amt_tax          -- �d�C�㓙�i����Łj
           ,(xirh.electric_amt_with_tax) * -1         AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
           ,(xirh.recalc_total_fee_no_tax) * -1       AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
           ,(xirh.recalc_total_fee_tax) * -1          AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
           ,(xirh.recalc_total_fee_with_tax) * -1     AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
           ,(xirh.bank_trans_fee_no_tax) * -1         AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
           ,(xirh.bank_trans_fee_tax) * -1            AS  bank_trans_fee_tax        -- �U���萔���i����Łj
           ,(xirh.bank_trans_fee_with_tax) * -1       AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
           ,xirh.vendor_invoice_regnum                AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
           ,xirh.display_code                         AS  display_code              -- �\���R�[�h
           ,xirh.company_code_bd                      AS  company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
        FROM   xxcok_info_rev_header    xirh  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
        WHERE  xirh.vendor_code                       = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym                = gv_process_ym
        AND    xirh.snapshot_timing                   = '2' -- FB
        AND    xirh.rev                               = '3' -- �V���iFB�j
        AND    xirh.check_result                      = '0' -- �Ώ�
        AND    xirh.notifi_amt                        > 0
        ;
--
        -- �ԃf�[�^�쐬�����J�E���g�A�b�v
        gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
--
        -- �V�������݂��Ȃ��ꍇ
        INSERT INTO xxcok_info_rev_header(
          snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
         ,snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
         ,rev                     -- REV
         ,check_result            -- �Ó����`�F�b�N����
         ,row_id                  -- ���e�[�u�����R�[�hID
         ,edi_interface_date      -- �A�g���iEDI�x���ē����j
         ,vendor_code             -- ���t��R�[�h
         ,set_code                -- �ʒm�������ݒ�R�[�h
         ,cust_code               -- �ڋq�R�[�h
         ,cust_name               -- ��Ж�
         ,dest_post_code          -- �X�֔ԍ�
         ,dest_address1           -- �Z��
         ,dest_tel                -- �d�b�ԍ�
         ,fax                     -- FAX�ԍ�
         ,dept_name               -- ������
         ,send_post_code          -- �X�֔ԍ��i���t���j
         ,send_address1           -- �Z���i���t���j
         ,send_tel                -- �d�b�ԍ��i���t���j
         ,num                     -- �ԍ�
         ,payment_date            -- �x����
         ,closing_date            -- ���ߓ�
         ,closing_date_min        -- �ŏ����ߓ�
         ,notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
         ,total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
         ,tax_amt_10              -- 10%����Ŋz
         ,total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
         ,total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
         ,tax_amt_8               -- �y��8%����Ŋz
         ,total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
         ,total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
         ,tax_amt_0               -- ��ېŏ���Ŋz
         ,total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
         ,total_sales_qty         -- �̔��{�����v
         ,total_sales_amt         -- �̔����z���v
         ,sales_fee               -- �̔��萔��
         ,electric_amt            -- �d�C�㓙���v�@�Ŕ�
         ,tax_amt                 -- �����
         ,transfer_fee            -- �U���萔���@�ō�
         ,payment_amt             -- ���x�����z�@�ō�
         ,remarks                 -- �����Ĕ��l
         ,bank_code               -- ��s�R�[�h
         ,bank_name               -- ��s��
         ,branch_code             -- �x�X�R�[�h
         ,branch_name             -- �x�X��
         ,bank_holder_name_alt    -- ������
         ,tax_div                 -- �ŋ敪
         ,target_div              -- �Ώۋ敪
         ,created_by              -- �쐬��
         ,creation_date           -- �쐬��
         ,last_updated_by         -- �ŏI�X�V��
         ,last_update_date        -- �ŏI�X�V��
         ,last_update_login       -- �ŏI�X�V���O�C��
         ,request_id              -- �v��ID
         ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              -- �R���J�����g�E�v���O����ID
         ,program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
         ,bm_payment_kbn            -- BM�x���敪
         ,tax_calc_kbn              -- �Ōv�Z�敪
         ,bm_tax_kbn                -- BM�ŋ敪
         ,bank_charge_bearer        -- �U���萔�����S��
         ,sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
         ,sales_fee_tax             -- �̔��萔���i����Łj
         ,sales_fee_with_tax        -- �̔��萔���i�ō��j
         ,electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
         ,electric_amt_tax          -- �d�C�㓙�i����Łj
         ,electric_amt_with_tax     -- �d�C�㓙�i�ō��j
         ,recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
         ,recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
         ,recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
         ,bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
         ,bank_trans_fee_tax        -- �U���萔���i����Łj
         ,bank_trans_fee_with_tax   -- �U���萔���i�ō��j
         ,vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
         ,display_code              -- �\���R�[�h
         ,company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
        )
        SELECT
            xirh.snapshot_create_ym                   AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,iv_proc_div                               AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'4'                                       AS  rev                     -- REV 4�F�ԁi�g�ݖ߂��j
           ,'0'                                       AS  check_result            -- �Ó����`�F�b�N����
           ,NULL                                      AS  row_id                  -- ���e�[�u�����R�[�hID
           ,NULL                                      AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
           ,xirh.vendor_code                          AS  vendor_code             -- ���t��R�[�h
           ,xirh.set_code                             AS  set_code                -- �ʒm�������ݒ�R�[�h
           ,xirh.cust_code                            AS  cust_code               -- �ڋq�R�[�h
           ,xirh.cust_name                            AS  cust_name               -- ��Ж�
           ,xirh.dest_post_code                       AS  dest_post_code          -- �X�֔ԍ�
           ,xirh.dest_address1                        AS  dest_address1           -- �Z��
           ,xirh.dest_tel                             AS  dest_tel                -- �d�b�ԍ�
           ,xirh.fax                                  AS  fax                     -- FAX�ԍ�
           ,xirh.dept_name                            AS  dept_name               -- ������
           ,xirh.send_post_code                       AS  send_post_code          -- �X�֔ԍ��i���t���j
           ,xirh.send_address1                        AS  send_address1           -- �Z���i���t���j
           ,xirh.send_tel                             AS  send_tel                -- �d�b�ԍ��i���t���j
           ,xirh.num                                  AS  num                     -- �ԍ�
           ,xirh.payment_date                         AS  payment_date            -- �x����
           ,xirh.closing_date                         AS  closing_date            -- ���ߓ�
           ,xirh.closing_date_min                     AS  closing_date_min        -- �ŏ����ߓ�
           ,(xirh.notifi_amt) * -1                    AS  notifi_amt              -- �����Ă̒ʒm���z
-- Ver.1.2 ADD START
           ,(xirh.total_amt_no_tax_10) * -1           AS  total_amt_no_tax_10     -- 10%���v���z�i�Ŕ��j
           ,(xirh.tax_amt_10) * -1                    AS  tax_amt_10              -- 10%����Ŋz
           ,(xirh.total_amt_10) * -1                  AS  total_amt_10            -- 10%���v���z�i�ō��j
-- Ver.1.2 ADD END
           ,(xirh.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
           ,(xirh.tax_amt_8) * -1                     AS  tax_amt_8               -- �y��8%����Ŋz
           ,(xirh.total_amt_8) * -1                   AS  total_amt_8             -- �y��8%���v���z�i�ō��j
-- Ver.1.2 ADD START
           ,(xirh.total_amt_no_tax_0) * -1            AS  total_amt_no_tax_0      -- ��ېō��v���z�i�Ŕ��j
           ,(xirh.tax_amt_0) * -1                     AS  tax_amt_0               -- ��ېŏ���Ŋz
           ,(xirh.total_amt_0) * -1                   AS  total_amt_0             -- ��ېō��v���z�i�ō��j
-- Ver.1.2 ADD END
           ,(xirh.total_sales_qty) * -1               AS  total_sales_qty         -- �̔��{�����v
           ,(xirh.total_sales_amt) * -1               AS  total_sales_amt         -- �̔����z���v
           ,(xirh.sales_fee) * -1                     AS  sales_fee               -- �̔��萔��
           ,(xirh.electric_amt) * -1                  AS  electric_amt            -- �d�C�㓙���v �Ŕ�
           ,(xirh.tax_amt) * -1                       AS  tax_amt                 -- �����
           ,(xirh.transfer_fee) * -1                  AS  transfer_fee            -- �U���萔�� �ō�
           ,(xirh.payment_amt) * -1                   AS  payment_amt             -- ���x�����z �ō�
           ,'"'||SUBSTR(gv_remarks_re_deb,1,500)||'"' AS  remarks                 -- �����Ĕ��l
           ,xirh.bank_code                            AS  bank_code               -- ��s�R�[�h
           ,xirh.bank_name                            AS  bank_name               -- ��s��
           ,xirh.branch_code                          AS  branch_code             -- �x�X�R�[�h
           ,xirh.branch_name                          AS  branch_name             -- �x�X��
           ,xirh.bank_holder_name_alt                 AS  bank_holder_name_alt    -- ������
           ,xirh.tax_div                              AS  tax_div                 -- �ŋ敪
           ,xirh.target_div                           AS  target_div              -- �Ώۋ敪
           ,cn_created_by                             AS  created_by              -- �쐬��
           ,SYSDATE                                   AS  creation_date           -- �쐬��
           ,cn_last_updated_by                        AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                   AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                      AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                             AS  request_id              -- �v��ID
           ,cn_program_application_id                 AS  program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                             AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                   AS  program_update_date     -- �v���O�����X�V��
-- Ver.1.2 ADD START
           ,xirh.bm_payment_kbn                       AS  bm_payment_kbn            -- BM�x���敪
           ,xirh.tax_calc_kbn                         AS  tax_calc_kbn              -- �Ōv�Z�敪
           ,xirh.bm_tax_kbn                           AS  bm_tax_kbn                -- BM�ŋ敪
           ,xirh.bank_charge_bearer                   AS  bank_charge_bearer        -- �U���萔�����S��
           ,(xirh.sales_fee_no_tax) * -1              AS  sales_fee_no_tax          -- �̔��萔���i�Ŕ��j
           ,(xirh.sales_fee_tax) * -1                 AS  sales_fee_tax             -- �̔��萔���i����Łj
           ,(xirh.sales_fee_with_tax) * -1            AS  sales_fee_with_tax        -- �̔��萔���i�ō��j
           ,(xirh.electric_amt_no_tax) * -1           AS  electric_amt_no_tax       -- �d�C�㓙�i�Ŕ��j
           ,(xirh.electric_amt_tax) * -1              AS  electric_amt_tax          -- �d�C�㓙�i����Łj
           ,(xirh.electric_amt_with_tax) * -1         AS  electric_amt_with_tax     -- �d�C�㓙�i�ō��j
           ,(xirh.recalc_total_fee_no_tax) * -1       AS  recalc_total_fee_no_tax   -- �Čv�Z�ώ萔���v�i�Ŕ��j
           ,(xirh.recalc_total_fee_tax) * -1          AS  recalc_total_fee_tax      -- �Čv�Z�ώ萔���v�i����Łj
           ,(xirh.recalc_total_fee_with_tax) * -1     AS  recalc_total_fee_with_tax -- �Čv�Z�ώ萔���v�i�ō��j
           ,(xirh.bank_trans_fee_no_tax) * -1         AS  bank_trans_fee_no_tax     -- �U���萔���i�Ŕ��j
           ,(xirh.bank_trans_fee_tax) * -1            AS  bank_trans_fee_tax        -- �U���萔���i����Łj
           ,(xirh.bank_trans_fee_with_tax) * -1       AS  bank_trans_fee_with_tax   -- �U���萔���i�ō��j
           ,xirh.vendor_invoice_regnum                AS  vendor_invoice_regnum     -- ���t��C���{�C�X�o�^�ԍ�
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
           ,xirh.display_code                         AS  display_code              -- �\���R�[�h
           ,xirh.company_code_bd                      AS  company_code_bd           -- ��ЃR�[�h�i����j
-- Ver.1.3 Add End
        FROM   xxcok_info_rev_header    xirh  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
        WHERE  xirh.vendor_code                       = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym                = gv_process_ym
        AND    xirh.snapshot_timing                   = '1' -- 2�c
        AND    xirh.rev                               = '1' -- �����i2�c�j
-- Ver.1.2 ADD START
        AND    xirh.bm_payment_kbn                    = '1' -- �{�U(�ē�������)
-- Ver.1.2 ADD END
        AND    xirh.notifi_amt                        > 0
        AND NOT EXISTS (
               SELECT 1
               FROM  xxcok_info_rev_header    xirh_new  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
               WHERE xirh_new.snapshot_create_ym = xirh.snapshot_create_ym
               AND   xirh_new.snapshot_timing    = '2' -- FB
               AND   xirh_new.rev                = '3' -- �V���iFB�j
               AND   xirh_new.check_result       = '0' -- �Ώ�
               AND   xirh_new.notifi_amt         > 0
               AND   xirh_new.vendor_code        = xirh.vendor_code 
            )
        ;
--
        -- �ԃf�[�^�쐬�����J�E���g�A�b�v
        gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
--
        -- ===============================================
        -- �ԃJ�X�^�����ׂ̍쐬
        -- ===============================================
        -- �V�������݂���ꍇ
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
         ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
         ,rev                         -- REV
         ,check_result                -- �Ó����`�F�b�N����
         ,row_id                      -- ���e�[�u�����R�[�hID
         ,edi_interface_date          -- �A�g���iEDI�x���ē����j
         ,vendor_code                 -- ���t��R�[�h
         ,cust_code                   -- �ڋq�R�[�h
         ,inst_dest                   -- �ݒu�ꏊ
         ,calc_type                   -- �v�Z����
         ,calc_sort                   -- �v�Z�����\�[�g��
         ,sell_bottle                 -- �����^�e��
         ,sales_qty                   -- �̔��{��
         ,sales_tax_amt               -- �̔����z�i�ō��j
         ,sales_amt                   -- �̔����z�i�Ŕ��j
         ,contract                    -- ���_����e
         ,sales_fee                   -- �̔��萔���i�Ŕ��j
         ,tax_amt                     -- �����
         ,sales_tax_fee               -- �̔��萔���i�ō��j
         ,bottle_code                 -- �e��敪�R�[�h
         ,salling_price               -- �������z
         ,REBATE_RATE                 -- ���ߗ�
         ,REBATE_AMT                  -- ���ߊz
         ,tax_code                    -- �ŃR�[�h
         ,tax_div                     -- �ŋ敪
         ,target_div                  -- �Ώۋ敪
         ,created_by                  -- �쐬��
         ,creation_date               -- �쐬��
         ,last_updated_by             -- �ŏI�X�V��
         ,last_update_date            -- �ŏI�X�V��
         ,last_update_login           -- �ŏI�X�V���O�C��
         ,request_id                  -- �v��ID
         ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                  -- �R���J�����g�E�v���O����ID
         ,program_update_date         -- �v���O�����X�V��
        )
        SELECT
            xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,iv_proc_div                             AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'4'                                     AS  rev                     -- REV�i4:�ԁi�g�ݖ߂��j)
           ,'0'                                     AS  check_result            -- �Ó����`�F�b�N���ʁi0:�Ώہj
           ,NULL                                    AS  row_id                  -- ���e�[�u�����R�[�hID
           ,NULL                                    AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
           ,xirc.vendor_code                        AS  vendor_code             -- ���t��R�[�h
           ,xirc.cust_code                          AS  cust_code               -- �ڋq�R�[�h
           ,xirc.inst_dest                          AS  inst_dest               -- �ݒu�ꏊ
           ,xirc.calc_type                          AS  calc_type               -- �v�Z����
           ,xirc.calc_sort                          AS  calc_sort               -- �v�Z�����\�[�g��
           ,xirc.sell_bottle                        AS  sell_bottle             -- �����^�e��
           ,(xirc.sales_qty) * -1                   AS  sales_qty               -- �̔��{��
           ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,(xirc.sales_amt) * -1                   AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,xirc.contract                           AS  contract                -- ���_����e
           ,(xirc.sales_fee) * -1                   AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- �����
           ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xirc.bottle_code                        AS  bottle_code             -- �e��敪�R�[�h
           ,xirc.salling_price                      AS  salling_price           -- �������z
           ,xirc.rebate_rate                        AS  rebate_rate             -- ���ߗ�
           ,xirc.rebate_amt                         AS  rebate_amt              -- ���ߊz
           ,xirc.tax_code                           AS  tax_code                -- �ŃR�[�h
           ,xirc.tax_div                            AS  tax_div                 -- �ŋ敪
           ,xirc.target_div                         AS  target_div              -- �Ώۋ敪
           ,cn_created_by                           AS  created_by              -- �쐬��
           ,SYSDATE                                 AS  creation_date           -- �쐬��
           ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                           AS  request_id              -- �v��ID
           ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
        FROM   xxcok_info_rev_header     xirh  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
              ,xxcok_info_rev_custom     xirc  -- �C���t�H�}�[�g�p�ԍ��i�J�X�^�����ׁj
        WHERE  xirh.vendor_code                     = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym              = gv_process_ym
        AND    xirh.snapshot_timing                 = '2' -- FB
        AND    xirh.rev                             = '3' -- �V���iFB�j
        AND    xirh.check_result                    = '0' -- �Ώ�
        AND    xirh.notifi_amt                      > 0
        AND    xirh.snapshot_create_ym              = xirc.snapshot_create_ym
        AND    xirh.snapshot_timing                 = xirc.snapshot_timing
        AND    xirh.rev                             = xirc.rev
        AND    xirh.vendor_code                     = xirc.vendor_code
        ;
--
        -- �V�������݂��Ȃ��ꍇ
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- �X�i�b�v�V���b�g�쐬�N��
         ,snapshot_timing             -- �X�i�b�v�V���b�g�^�C�~���O 
         ,rev                         -- REV
         ,check_result                -- �Ó����`�F�b�N����
         ,row_id                      -- ���e�[�u�����R�[�hID
         ,edi_interface_date          -- �A�g���iEDI�x���ē����j
         ,vendor_code                 -- ���t��R�[�h
         ,cust_code                   -- �ڋq�R�[�h
         ,inst_dest                   -- �ݒu�ꏊ
         ,calc_type                   -- �v�Z����
         ,calc_sort                   -- �v�Z�����\�[�g��
         ,sell_bottle                 -- �����^�e��
         ,sales_qty                   -- �̔��{��
         ,sales_tax_amt               -- �̔����z�i�ō��j
         ,sales_amt                   -- �̔����z�i�Ŕ��j
         ,contract                    -- ���_����e
         ,sales_fee                   -- �̔��萔���i�Ŕ��j
         ,tax_amt                     -- �����
         ,sales_tax_fee               -- �̔��萔���i�ō��j
         ,bottle_code                 -- �e��敪�R�[�h
         ,salling_price               -- �������z
         ,REBATE_RATE                 -- ���ߗ�
         ,REBATE_AMT                  -- ���ߊz
         ,tax_code                    -- �ŃR�[�h
         ,tax_div                     -- �ŋ敪
         ,target_div                  -- �Ώۋ敪
         ,created_by                  -- �쐬��
         ,creation_date               -- �쐬��
         ,last_updated_by             -- �ŏI�X�V��
         ,last_update_date            -- �ŏI�X�V��
         ,last_update_login           -- �ŏI�X�V���O�C��
         ,request_id                  -- �v��ID
         ,program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                  -- �R���J�����g�E�v���O����ID
         ,program_update_date         -- �v���O�����X�V��
        )
        SELECT
            xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- �X�i�b�v�V���b�g�쐬�N��
           ,iv_proc_div                             AS  snapshot_timing         -- �X�i�b�v�V���b�g�^�C�~���O
           ,'4'                                     AS  rev                     -- REV�i4:�ԁi�g�ݖ߂��j)
           ,'0'                                     AS  check_result            -- �Ó����`�F�b�N���ʁi0:�Ώہj
           ,NULL                                    AS  row_id                  -- ���e�[�u�����R�[�hID
           ,NULL                                    AS  edi_interface_date      -- �A�g���iEDI�x���ē����j
           ,xirc.vendor_code                        AS  vendor_code             -- ���t��R�[�h
           ,xirc.cust_code                          AS  cust_code               -- �ڋq�R�[�h
           ,xirc.inst_dest                          AS  inst_dest               -- �ݒu�ꏊ
           ,xirc.calc_type                          AS  calc_type               -- �v�Z����
           ,xirc.calc_sort                          AS  calc_sort               -- �v�Z�����\�[�g��
           ,xirc.sell_bottle                        AS  sell_bottle             -- �����^�e��
           ,(xirc.sales_qty) * -1                   AS  sales_qty               -- �̔��{��
           ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,(xirc.sales_amt) * -1                   AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,xirc.contract                           AS  contract                -- ���_����e
           ,(xirc.sales_fee) * -1                   AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- �����
           ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xirc.bottle_code                        AS  bottle_code             -- �e��敪�R�[�h
           ,xirc.salling_price                      AS  salling_price           -- �������z
           ,xirc.rebate_rate                        AS  rebate_rate             -- ���ߗ�
           ,xirc.rebate_amt                         AS  rebate_amt              -- ���ߊz
           ,xirc.tax_code                           AS  tax_code                -- �ŃR�[�h
           ,xirc.tax_div                            AS  tax_div                 -- �ŋ敪
           ,xirc.target_div                         AS  target_div              -- �Ώۋ敪
           ,cn_created_by                           AS  created_by              -- �쐬��
           ,SYSDATE                                 AS  creation_date           -- �쐬��
           ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                           AS  request_id              -- �v��ID
           ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
        FROM   xxcok_info_rev_header     xirh  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
              ,xxcok_info_rev_custom     xirc  -- �C���t�H�}�[�g�p�ԍ��i�J�X�^�����ׁj
        WHERE  xirh.vendor_code                     = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym              = gv_process_ym
        AND    xirh.snapshot_timing                 = '1' -- 2�c
        AND    xirh.rev                             = '1' -- �����i2�c�t�@�C���쐬�j
-- Ver.1.2 ADD START
        AND    xirh.bm_payment_kbn                  = '1' -- �{�U(�ē�������)
-- Ver.1.2 ADD END
        AND    xirh.notifi_amt                      > 0
        AND NOT EXISTS (
               SELECT 1
               FROM  xxcok_info_rev_header    xirh_new  -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
               WHERE xirh_new.snapshot_create_ym = xirh.snapshot_create_ym
               AND   xirh_new.snapshot_timing    = '2' -- FB
               AND   xirh_new.rev                = '3' -- �V���iFB�j
               AND   xirh_new.check_result       = '0' -- �Ώ�
               AND   xirh_new.notifi_amt         > 0
               AND   xirh_new.vendor_code        = xirh.vendor_code 
            )
        AND    xirh.snapshot_create_ym              = xirc.snapshot_create_ym
        AND    xirh.snapshot_timing                 = xirc.snapshot_timing
        AND    xirh.rev                             = xirc.rev
        AND    xirh.vendor_code                     = xirc.vendor_code
        ;
--
        -- �d����R�[�h�ێ�
        lv_supplier_code_rec_bk := l_bm_balance_snap_re_rec.supplier_code;
      END LOOP snap_re_loop;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
-- Mod Ver1.1 K.Kanada S
--  END difference_check;
  END difference_check_re;
-- Mod Ver1.1 K.Kanada E
--
  /**********************************************************************************
   * Procedure Name   : ins_snap_data
   * Description      : �̎�c���X�i�b�v�V���b�g�쐬(A-4)
   ***********************************************************************************/
  PROCEDURE ins_snap_data(
    iv_proc_div    IN  VARCHAR2    --  1.�����^�C�~���O
   ,ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_snap_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ===============================================
    -- �̎�c���J�[�\��
    -- ===============================================
    CURSOR l_bm_balance_snap_cur
    IS
      SELECT  /*+ LEADING(xbbs_sec xbb pv pvsa) */
         CASE iv_proc_div
           WHEN '2' THEN pvsa.attribute4
           WHEN '3' THEN xbbs_fb.bm_paymet_kbn
         END                             AS bm_paymet_kbn                       -- BM�x���敪
        ,xbbs_sec.bm_tax_kbn             AS bm_tax_kbn                          -- BM�ŋ敪
        ,CASE iv_proc_div
           WHEN '2' THEN pvsa.bank_charge_bearer
           WHEN '3' THEN xbbs_fb.bank_charge_bearer
         END                             AS bank_charge_bearer                  -- �U���萔�����S��
        ,xbbs_sec.cust_name              AS cust_name                           -- �ݒu�於
        ,xbb.bm_balance_id               AS bm_balance_id                       -- �̎�c��ID
        ,xbb.base_code                   AS base_code                           -- ���_�R�[�h
        ,xbb.supplier_code               AS supplier_code                       -- �d����R�[�h
        ,xbb.supplier_site_code          AS supplier_site_code                  -- �d����T�C�g�R�[�h
        ,xbb.cust_code                   AS cust_code                           -- �ڋq�R�[�h
        ,xbb.closing_date                AS closing_date                        -- ���ߓ�
        ,xbb.selling_amt_tax             AS selling_amt_tax                     -- �̔����z�i�ō��j
        ,xbb.backmargin                  AS backmargin                          -- �̔��萔��
        ,xbb.backmargin_tax              AS backmargin_tax                      -- �̔��萔���i����Ŋz�j
        ,xbb.electric_amt                AS electric_amt                        -- �d�C��
        ,xbb.electric_amt_tax            AS electric_amt_tax                    -- �d�C���i����Ŋz�j
        ,xbb.tax_code                    AS tax_code                            -- �ŋ��R�[�h
        ,xbb.expect_payment_date         AS expect_payment_date                 -- �x���\���
        ,xbb.expect_payment_amt_tax      AS expect_payment_amt_tax              -- �x���\��z�i�ō��j
        ,xbb.payment_amt_tax             AS payment_amt_tax                     -- �x���z�i�ō��j
        ,xbb.balance_cancel_date         AS balance_cancel_date                 -- �c�������
        ,xbb.resv_flag                   AS resv_flag                           -- �ۗ��t���O
        ,xbb.return_flag                 AS return_flag                         -- �g�ݖ߂��t���O
        ,xbb.publication_date            AS publication_date                    -- �ē���������
        ,xbb.fb_interface_status         AS fb_interface_status                 -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        ,xbb.fb_interface_date           AS fb_interface_date                   -- �A�g���i�{�U�pFB�j
        ,xbb.edi_interface_status        AS edi_interface_status                -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        ,xbb.edi_interface_date          AS edi_interface_date                  -- �A�g���iEDI�x���ē����j
        ,xbb.gl_interface_status         AS gl_interface_status                 -- �A�g�X�e�[�^�X�iGL�j
        ,xbb.gl_interface_date           AS gl_interface_date                   -- �A�g���iGL�j
        ,xbb.amt_fix_status              AS amt_fix_status                      -- ���z�m��X�e�[�^�X
        ,xbb.org_slip_number             AS org_slip_number                     -- ���`�[�ԍ�
        ,xbb.proc_type                   AS proc_type                           -- �����敪
-- Ver.1.2 ADD START
        ,xbbs_sec.tax_calc_kbn           AS tax_calc_kbn                        -- �Ōv�Z�敪 �i��2�c�j
-- Ver.1.2 ADD END
      FROM    xxcok_backmargin_balance  xbb      -- �̎�c���e�[�u��
             ,xxcok_bm_balance_snap     xbbs_sec -- �̎�c���e�[�u���X�i�b�v�V���b�g2�c
             ,xxcok_bm_balance_snap     xbbs_fb  -- �̎�c���e�[�u���X�i�b�v�V���b�gFB
             ,po_vendors                pv       -- �d����}�X�^
             ,po_vendor_sites_all       pvsa     -- �d����T�C�g
      WHERE   xbbs_sec.bm_balance_id        = xbb.bm_balance_id
      AND     xbbs_sec.snapshot_create_ym   = gv_process_ym
      AND     xbbs_sec.snapshot_timing      = '1' -- 2�c
      AND     xbb.supplier_code             = pv.segment1
      AND     pv.vendor_id                  = pvsa.vendor_id
      AND     ( pvsa.inactive_date          > gd_process_date
      OR      pvsa.inactive_date            IS NULL )
      AND     pvsa.org_id                   = gn_org_id
      AND     xbbs_fb.bm_balance_id(+)      = xbbs_sec.bm_balance_id
      AND     xbbs_fb.snapshot_create_ym(+) = gv_process_ym
      AND     xbbs_fb.snapshot_timing(+)    = '2'
      ;
--
    l_bm_balance_snap_rec    l_bm_balance_snap_cur%ROWTYPE;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��2�c�Ɠ����_�ł̔̎�c���X�i�b�v�V���b�g�̎d���挏�����擾
    -- ===============================================
    SELECT COUNT(DISTINCT supplier_code)
    INTO   gn_target_cnt
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing = '1' -- 2�c
    ;
    << bm_balance_snap_loop >>
    FOR l_bm_balance_snap_rec IN l_bm_balance_snap_cur LOOP
      -- ===============================================
      -- �̎�c���X�i�b�v�V���b�g�o�^
      -- ===============================================
      INSERT INTO xxcok_bm_balance_snap(
         snapshot_create_ym                      -- �X�i�b�v�V���b�g�쐬�N��
        ,snapshot_timing                         -- �X�i�b�v�V���b�g�^�C�~���O
        ,bm_paymet_kbn                           -- BM�x���敪
        ,bm_tax_kbn                              -- BM�ŋ敪
        ,bank_charge_bearer                      -- �U���萔�����S��
        ,cust_name                               -- �ݒu�於
        ,bm_balance_id                           -- �̎�c��ID
        ,base_code                               -- ���_�R�[�h
        ,supplier_code                           -- �d����R�[�h
        ,supplier_site_code                      -- �d����T�C�g�R�[�h
        ,cust_code                               -- �ڋq�R�[�h
        ,closing_date                            -- ���ߓ�
        ,selling_amt_tax                         -- �̔����z�i�ō��j
        ,backmargin                              -- �̔��萔��
        ,backmargin_tax                          -- �̔��萔���i����Ŋz�j
        ,electric_amt                            -- �d�C��
        ,electric_amt_tax                        -- �d�C���i����Ŋz�j
        ,tax_code                                -- �ŋ��R�[�h
        ,expect_payment_date                     -- �x���\���
        ,expect_payment_amt_tax                  -- �x���\��z�i�ō��j
        ,payment_amt_tax                         -- �x���z�i�ō��j
        ,balance_cancel_date                     -- �c�������
        ,resv_flag                               -- �ۗ��t���O
        ,return_flag                             -- �g�ݖ߂��t���O
        ,publication_date                        -- �ē���������
        ,fb_interface_status                     -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        ,fb_interface_date                       -- �A�g���i�{�U�pFB�j
        ,edi_interface_status                    -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        ,edi_interface_date                      -- �A�g���iEDI�x���ē����j
        ,gl_interface_status                     -- �A�g�X�e�[�^�X�iGL�j
        ,gl_interface_date                       -- �A�g���iGL�j
        ,amt_fix_status                          -- ���z�m��X�e�[�^�X
        ,org_slip_number                         -- ���`�[�ԍ�
        ,proc_type                               -- �����敪
        ,created_by                              -- �쐬��
        ,creation_date                           -- �쐬��
        ,last_updated_by                         -- �ŏI�X�V��
        ,last_update_date                        -- �ŏI�X�V��
        ,last_update_login                       -- �ŏI�X�V���O�C��
        ,request_id                              -- �v��ID
        ,program_application_id                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                              -- �R���J�����g�E�v���O����ID
        ,program_update_date                     -- �v���O�����X�V��      
-- Ver.1.2 ADD START
        ,tax_calc_kbn                            -- �Ōv�Z�敪
-- Ver.1.2 ADD END
        )
      VALUES (
         gv_process_ym                                                 -- �X�i�b�v�V���b�g�쐬�N��
        ,iv_proc_div                                                   -- �X�i�b�v�V���b�g�^�C�~���O
        ,l_bm_balance_snap_rec.bm_paymet_kbn                           -- BM�x���敪
        ,l_bm_balance_snap_rec.bm_tax_kbn                              -- BM�ŋ敪
        ,l_bm_balance_snap_rec.bank_charge_bearer                      -- �U���萔�����S��
        ,l_bm_balance_snap_rec.cust_name                               -- �ݒu�於
        ,l_bm_balance_snap_rec.bm_balance_id                           -- �̎�c��ID
        ,l_bm_balance_snap_rec.base_code                               -- ���_�R�[�h
        ,l_bm_balance_snap_rec.supplier_code                           -- �d����R�[�h
        ,l_bm_balance_snap_rec.supplier_site_code                      -- �d����T�C�g�R�[�h
        ,l_bm_balance_snap_rec.cust_code                               -- �ڋq�R�[�h
        ,l_bm_balance_snap_rec.closing_date                            -- ���ߓ�
        ,l_bm_balance_snap_rec.selling_amt_tax                         -- �̔����z�i�ō��j
        ,l_bm_balance_snap_rec.backmargin                              -- �̔��萔��
        ,l_bm_balance_snap_rec.backmargin_tax                          -- �̔��萔���i����Ŋz�j
        ,l_bm_balance_snap_rec.electric_amt                            -- �d�C��
        ,l_bm_balance_snap_rec.electric_amt_tax                        -- �d�C���i����Ŋz�j
        ,l_bm_balance_snap_rec.tax_code                                -- �ŋ��R�[�h
        ,l_bm_balance_snap_rec.expect_payment_date                     -- �x���\���
        ,l_bm_balance_snap_rec.expect_payment_amt_tax                  -- �x���\��z�i�ō��j
        ,l_bm_balance_snap_rec.payment_amt_tax                         -- �x���z�i�ō��j
        ,l_bm_balance_snap_rec.balance_cancel_date                     -- �c�������
        ,l_bm_balance_snap_rec.resv_flag                               -- �ۗ��t���O
        ,l_bm_balance_snap_rec.return_flag                             -- �g�ݖ߂��t���O
        ,l_bm_balance_snap_rec.publication_date                        -- �ē���������
        ,l_bm_balance_snap_rec.fb_interface_status                     -- �A�g�X�e�[�^�X�i�{�U�pFB�j
        ,l_bm_balance_snap_rec.fb_interface_date                       -- �A�g���i�{�U�pFB�j
        ,l_bm_balance_snap_rec.edi_interface_status                    -- �A�g�X�e�[�^�X�iEDI�x���ē����j
        ,l_bm_balance_snap_rec.edi_interface_date                      -- �A�g���iEDI�x���ē����j
        ,l_bm_balance_snap_rec.gl_interface_status                     -- �A�g�X�e�[�^�X�iGL�j
        ,l_bm_balance_snap_rec.gl_interface_date                       -- �A�g���iGL�j
        ,l_bm_balance_snap_rec.amt_fix_status                          -- ���z�m��X�e�[�^�X
        ,l_bm_balance_snap_rec.org_slip_number                         -- ���`�[�ԍ�
        ,l_bm_balance_snap_rec.proc_type                               -- �����敪
        ,cn_created_by                                                 -- �쐬��
        ,SYSDATE                                                       -- �쐬��
        ,cn_last_updated_by                                            -- �ŏI�X�V��
        ,SYSDATE                                                       -- �ŏI�X�V��
        ,cn_last_update_login                                          -- �ŏI�X�V���O�C��
        ,cn_request_id                                                 -- �v��ID
        ,cn_program_application_id                                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id                                                 -- �R���J�����g�E�v���O����ID
        ,SYSDATE                                                       -- �v���O�����X�V��
-- Ver.1.2 ADD START
        ,l_bm_balance_snap_rec.tax_calc_kbn                            -- �Ōv�Z�敪
-- Ver.1.2 ADD END
        );
--
    END LOOP bm_balance_snap_loop;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_snap_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_check
   * Description      : �����`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'proc_check';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_count_fb     NUMBER;                                   -- FB���{�m�F����
    ln_count_re     NUMBER;                                   -- �g�ݖ߂����{�m�F����
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** �����`�F�b�N�G���[ ***
    proc_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- FB��̎��s�O�ɑg�ݖ߂�������s�����ꍇ�A�G���[
    SELECT COUNT(1) count_fb
    INTO   ln_count_fb
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing    = '2' -- FB��
    ;
--
    IF ( ln_count_fb = 0 ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10821
                       );
      RAISE proc_expt;
    END IF;
--
    -- ���ɑg�ݖ߂������s���Ă���ꍇ�A�x��
    SELECT COUNT(1) count_re
    INTO   ln_count_re
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing    = '3' -- �g�ݖ߂���
    ;
    IF ( ln_count_re > 0 ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10822
                       );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode    := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END proc_check;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : �ێ����Ԓ��߃f�[�^�폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'del_work';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u���X�i�b�v�V���b�g
    DELETE FROM xxcok_bm_balance_snap xbbs
-- Ver.1.2 MOD START
--    WHERE  xbbs.snapshot_create_ym = gv_process_ym_pre
    WHERE  xbbs.snapshot_create_ym < gv_snap_keep_oldest_ym
-- Ver.1.2 MOD END
    ;
--
    -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j
    DELETE FROM xxcok_info_rev_header xirh
-- Ver.1.2 MOD START
--    WHERE  xirh.snapshot_create_ym = gv_process_ym_pre
    WHERE  xirh.snapshot_create_ym < gv_snap_keep_oldest_ym
-- Ver.1.2 MOD END
    ;
--
    -- �C���t�H�}�[�g�p�ԍ��i�J�X�^�����ׁj
    DELETE FROM xxcok_info_rev_custom xirc
-- Ver.1.2 MOD START
--    WHERE  xirc.snapshot_create_ym = gv_process_ym_pre
    WHERE  xirc.snapshot_create_ym < gv_snap_keep_oldest_ym
-- Ver.1.2 MOD END
    ;
--
    COMMIT ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_div   IN  VARCHAR2    --  1.�����^�C�~���O
   ,ov_errbuf     OUT VARCHAR2    --  �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2    --  ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'init';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    lv_head_item    fnd_new_messages.message_text%TYPE;
    lv_custom_item  fnd_new_messages.message_text%TYPE;
    ln_cnt          NUMBER;
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �O���[�o���ϐ�������
    -- ===============================================
--    g_no_dif_tab.delete ;      -- Els Ver1.1 K.Kanada
--    g_no_dif_sup_tab.delete;   -- Els Ver1.1 K.Kanada
    g_dif_sup_tab.delete;        -- Add Ver1.1 K.Kanada
    -- ===============================================
    -- �R���J�����g���̓p�����[�^���o��
    -- ===============================================
    lv_errmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxcok
                      ,iv_name         => cv_msg_xxcok1_10817
                      ,iv_token_name1  => cv_tkn_proc_div
                      ,iv_token_value1 => iv_proc_div
                     );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 1.�Ɩ����t�擾
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_00028
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�Ɩ����t�N���擾
    -- ===============================================
    gv_process_ym   := TO_CHAR( gd_process_date,'YYYYMM' );
    -- ===============================================
    -- 3.�O���N���擾
    -- ===============================================
    gv_process_ym_pre := TO_CHAR( ADD_MONTHS(gd_process_date,-1),'YYYYMM' );
--
    -- ===============================================
    -- 4.�v���t�@�C���擾(��s�萔��_�U���z�)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                           ,iv_name          => cv_msg_xxcok1_00003
                           ,iv_token_name1   => cv_tkn_profile
                           ,iv_token_value1  => cv_prof_bank_fee_trans
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(��s�萔��_��z����)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_less
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(��s�萔��_��z�ȏ�)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_more
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(�̔��萔��_����ŗ�)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bm_tax
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(�x������_�f�t�H���g)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_term_name
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(�g�DID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.�v���t�@�C���擾(�d�C���i�ϓ��j�i�ڃR�[�h)
    -- ===============================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_prof_elec_change_item ) ;
    IF ( gv_elec_change_item_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_elec_change_item
                    );
      RAISE init_fail_expt;
    END IF;
-- Ver.1.2 ADD START
    -- ===============================================
    -- 4.�v���t�@�C���擾(�X�i�b�v�V���b�g�ێ�����)
    -- ===============================================
    gv_snap_keep_months := FND_PROFILE.VALUE( cv_prof_snap_keep_months ) ;
    IF ( gv_snap_keep_months IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_snap_keep_months
                    );
      RAISE init_fail_expt;
    END IF;
-- Ver.1.2 ADD END
-- Ver.1.3 Add Start
    -- ===============================================
    -- 4.�v���t�@�C���擾(��v����ID)
    -- ===============================================
    gv_set_of_bks_id := FND_PROFILE.VALUE( cv_set_of_books_id ) ;
    IF ( gv_set_of_bks_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_set_of_books_id
                    );
      RAISE init_fail_expt;
    END IF;
-- Ver.1.3 Add End
--
    -- ===============================================
    -- 5.���b�Z�[�W�擾(�����Ĕ��lFB�ԗp)
    -- ===============================================
    gv_remarks_fb_deb  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10818
                          );
    -- ===============================================
    -- 5.���b�Z�[�W�擾(�����Ĕ��l�V���p)
    -- ===============================================
    gv_remarks_new_cre := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10819
                          );
    -- ===============================================
    -- 5.���b�Z�[�W�擾(�����Ĕ��l�g�ݖ߂��ԗp)
    -- ===============================================
    gv_remarks_re_deb  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10820
                          );
--
    -- ===============================================
    -- 6.���ߓ�,�x�����\����擾
    -- ===============================================
    -- �Ɩ����t -1�����̒��ߓ��A�x���\������擾
    gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
    xxcok_common_pkg.get_close_date_p(
        ov_errbuf         => lv_errbuf
       ,ov_retcode        => lv_retcode
       ,ov_errmsg         => lv_errmsg
       ,id_proc_date      => gd_operating_date
       ,iv_pay_cond       => gv_term_name
       ,od_close_date     => gd_closing_date   -- ���ߓ�
       ,od_pay_date       => gd_schedule_date  -- �x���\���
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 7.�ō��萔���擾
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( 1 + gn_bm_tax / 100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( 1 + gn_bm_tax / 100 );
-- Ver.1.2 ADD START
    -- ===============================================
    -- 8.�X�i�b�v�V���b�g�ێ��ŌÔN���iYYYYMM�j�擾
    -- ===============================================
    gv_snap_keep_oldest_ym := TO_CHAR(
                                ADD_MONTHS(gd_process_date, TO_NUMBER(gv_snap_keep_months) * -1)
                               ,'YYYYMM'
                              );
-- Ver.1.2 ADD END
--
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_div   IN  VARCHAR2    --  1.�����^�C�~���O
   ,ov_errbuf     OUT VARCHAR2    --  �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2    --  ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================================
    -- �Œ胍�[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'submain';
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      iv_proc_div   =>  iv_proc_div     --  1.�����^�C�~���O
     ,ov_errbuf     =>  lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����^�C�~���O = 2�FFB�f�[�^�쐬��̏ꍇ
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- �ێ����Ԓ��߃f�[�^�폜(A-2)
      -- ===============================================
      del_work(
        ov_errbuf     => lv_errbuf      --  �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --  ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �����^�C�~���O = 3�F�g�ݖ߂���̏ꍇ
    IF ( iv_proc_div = '3' ) THEN
      -- ===============================================
      -- �����`�F�b�N(A-3)
      -- ===============================================
      proc_check(
        ov_errbuf     => lv_errbuf      --  �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --  ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode    := cv_status_warn;
      END IF;
    END IF;
--
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================================
      -- �̎�c���X�i�b�v�V���b�g�쐬(A-4)
      -- ===============================================
      ins_snap_data(
        iv_proc_div     => iv_proc_div   --  1.�����^�C�~���O
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
-- Add Ver1.1 K.Kanada S
      -- �����^�C�~���O = 3�F�g�ݖ߂���̏ꍇ
      IF ( iv_proc_div = '3' ) THEN
-- Add Ver1.1 K.Kanada E
-- Mod Ver1.1 K.Kanada S
--        -- ===============================================
--        -- �����`�F�b�N(A-5),�ԃf�[�^�쐬�i�g�ݖ߂���j(A-6),�V���J�X�^�����׏��쐬�P(A-7)
--        -- ===============================================
--        difference_check(
        -- ===============================================
        -- �����`�F�b�N(A-5-2),�ԃf�[�^�쐬�i�g�ݖ߂���j(A-6),�V���J�X�^�����׏��쐬�P(A-7)
        -- ===============================================
        difference_check_re(
          iv_proc_div      => iv_proc_div      --  1.�����^�C�~���O
--         ,o_no_dif_tab     => g_no_dif_tab     --  �X�L�b�v����ڋq�e�[�u��    -- Els Ver1.1 K.Kanada
--         ,o_no_dif_sup_tab => g_no_dif_sup_tab --  �X�L�b�v����d����e�[�u��  -- Els Ver1.1 K.Kanada
-- Mod Ver1.1 K.Kanada E
         ,ov_errbuf        => lv_errbuf
         ,ov_retcode       => lv_retcode
         ,ov_errmsg        => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
-- Add Ver1.1 K.Kanada S
      END IF;
-- Add Ver1.1 K.Kanada E
--
      -- �����^�C�~���O = 2�FFB�f�[�^�쐬��̏ꍇ
      IF ( iv_proc_div = '2' ) THEN
-- Add Ver1.1 K.Kanada S
        -- ===============================================
        -- �����`�F�b�N(A-5-1),�V���J�X�^�����׏��쐬�P(A-7)
        -- ===============================================
        difference_check_fb(
          iv_proc_div      => iv_proc_div      --  1.�����^�C�~���O
         ,o_dif_sup_tab    => g_dif_sup_tab    --  �����Ώێd����e�[�u��
         ,ov_errbuf        => lv_errbuf
         ,ov_retcode       => lv_retcode
         ,ov_errmsg        => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
-- Add Ver1.1 K.Kanada E
--
        -- ===============================================
        -- �V���J�X�^�����׏��쐬�Q(A-8)
        -- ===============================================
        ins_credit_custom(
          iv_proc_div   => iv_proc_div  --  1.�����^�C�~���O
--         ,i_no_dif_tab  => g_no_dif_tab --  �X�L�b�v����ڋq�e�[�u��  -- Els Ver1.1 K.Kanada
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
-- Els Ver1.1 K.Kanada S
--        -- ===============================================
--        -- �V���J�X�^�����׏��쐬�R(A-12)
--        -- ===============================================
--        ins_credit_custom_mon(
--          iv_proc_div   => iv_proc_div  --  1.�����^�C�~���O
--         ,i_no_dif_tab  => g_no_dif_tab --  �X�L�b�v����ڋq�e�[�u��
--         ,ov_errbuf     => lv_errbuf
--         ,ov_retcode    => lv_retcode
--         ,ov_errmsg     => lv_errmsg
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
-- Els Ver1.1 K.Kanada E
--
        -- ===============================================
        -- �V���w�b�_�[���쐬(A-9)
        -- ===============================================
        ins_credit_header(
          iv_proc_div   => iv_proc_div   --  1.�����^�C�~���O
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- �ԃf�[�^�쐬�iFB��j(A-10)
        -- ===============================================
        ins_debit_fb(
          iv_proc_div      => iv_proc_div      --  1.�����^�C�~���O
-- Mod Ver1.1 K.Kanada S
--         ,i_no_dif_sup_tab => g_no_dif_sup_tab --  �X�L�b�v����d����e�[�u��
         ,i_dif_sup_tab    => g_dif_sup_tab    --  �����Ώێd����e�[�u��
-- Mod Ver1.1 K.Kanada E
         ,ov_errbuf        => lv_errbuf
         ,ov_retcode       => lv_retcode
         ,ov_errmsg        => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
-- Ver.1.2 ADD START
        -- ===============================================
        -- �����Ȃ��̐ԍ��w�b�_�[���쐬(FB��)(A-13)
        -- ===============================================
        ins_no_diff_header(
          iv_proc_div      => iv_proc_div      --  1.�����^�C�~���O
         ,ov_errbuf        => lv_errbuf
         ,ov_retcode       => lv_retcode
         ,ov_errmsg        => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
-- Ver.1.2 ADD END
--
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_proc_div     IN  VARCHAR2          -- 1.�����^�C�~���O
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20)  := 'main';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- �G���[���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�G���[���b�Z�[�W
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- ���b�Z�[�W�R�[�h
--
  BEGIN
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_proc_div   => iv_proc_div      -- 1.�����^�C�~���O
     ,ov_errbuf     => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
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
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => cv_msg_xxccp1_90000
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- �����Ώی����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_dif_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10823
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_dif_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- �ԃf�[�^�쐬�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_debit_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10824
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_debit_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- ���f�[�^�쐬�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_credit_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10825
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_credit_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => cv_msg_xxccp1_90002
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- �폜���b�Z�[�W�o��
    -- ===============================================
-- Ver.1.2 ADD START
    -- �����^�C�~���O = 2�FFB�f�[�^�쐬��̏ꍇ
    IF ( iv_proc_div = '2' ) THEN
-- Ver.1.2 ADD END
      IF ( lv_retcode    = cv_status_normal ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appli_short_name_xxcok
                         ,iv_name         => cv_msg_xxcok1_10826
                        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
-- Ver.1.2 ADD START
    END IF;
-- Ver.1.2 ADD END
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK016A03C;
/
