CREATE OR REPLACE PACKAGE BODY XXCOK015A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK015A05C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : EDI�V�X�e���ɂăC���t�H�}�[�g�Ђ֑��M����x���ē����p�f�[�^�t�@�C���쐬
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  �t�@�C���N���[�Y(A-12)
 *  upd_data                    �A�g�Ώۃf�[�^�X�V(A-11)
 *  chk_data                    �A�g�f�[�^�Ó����`�F�b�N(A-9)
 *  get_work_head_line          ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-7)(A-8)(A-10)
 *  file_open                   �t�@�C���I�[�v��(A-6)
 *  ins_work_header             ���[�N�w�b�_�[���쐬(A-5)
 *  ins_work_custom             ���[�N�J�X�^�����׏��쐬(A-4)
 *  ins_work_line               ���[�N���׏��쐬(A-3)
 *  del_work                    ���[�N�e�[�u���f�[�^�폜(A-2)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/25    1.0   N.Abe            �V�K�쐬
 *  2020/12/14    1.1   N.Abe            E_�{�ғ�_16841
 *  2021/02/16    1.2   N.Abe            E_�{�ғ�_16843
 *  2021/03/03    1.3   K.Kanada         E_�{�ғ�_16843�i�{�ԏ�Q�Ή��j
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK015A05C';
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
  cv_msg_xxcok1_00006        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00006';  -- �t�@�C�����o��
  cv_msg_xxcok1_00009        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00009';  -- �t�@�C�����݃G���[
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok1_00036        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00036';  -- ���߁E�x�����擾�G���[
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00053';  -- �̎�c���e�[�u�����b�N�擾�G���[
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00067';  -- �f�B���N�g���o��
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10434';  -- ��s���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10435';  -- ��s�x�X���S�p�`�F�b�N�x��
  cv_msg_xxcok1_10460        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10460';  -- ��s�R�[�h���p�`�F�b�N�x��
  cv_msg_xxcok1_10461        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10461';  -- �x�X�R�[�h���p�`�F�b�N�x��
  cv_msg_xxcok1_10462        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10462';  -- ���������p�`�F�b�N�x��
  cv_msg_xxcok1_10762        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10762';  -- �����Ĕ��l
  cv_msg_xxcok1_10763        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10763';  -- �C���t�H�}�[�g�p�w�b�_�[���ږ��i�O�Łj
  cv_msg_xxcok1_10764        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10764';  -- �C���t�H�}�[�g�p�w�b�_�[���ږ��i���Łj
  cv_msg_xxcok1_10765        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10765';  -- �C���t�H�}�[�g�p�J�X�^�����׃^�C�g��
  cv_msg_xxcok1_10766        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10766';  -- �C���t�H�}�[�g�p�J�X�^�����׍��ږ�
  cv_msg_xxcok1_10767        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10767';  -- �C���t�H�}�[�g�p���׍��v�s��
  cv_msg_xxcok1_10768        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10768';  -- �C���t�H�}�[�g�p�p�����[�^�o��
  cv_msg_xxcok1_10769        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10769';  -- �S�p�`�F�b�N�x��
  cv_msg_xxcok1_10770        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10770';  -- ���p��������уn�C�t���`�F�b�N�x��
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90000';  -- �Ώی���
  cv_msg_xxccp1_90001        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90001';  -- ��������
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90002';  -- �G���[����
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90003';  -- �x������
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90004';  -- ����I��
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90005';  -- �x���I��
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
  cv_msg_xxccp1_90008        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N��
  cv_tkn_profile             CONSTANT VARCHAR2(7)     := 'PROFILE';
  cv_tkn_directory           CONSTANT VARCHAR2(9)     := 'DIRECTORY';
  cv_tkn_file_name           CONSTANT VARCHAR2(9)     := 'FILE_NAME';
  cv_tkn_conn_loc            CONSTANT VARCHAR2(8)     := 'CONN_LOC';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_bank_code           CONSTANT VARCHAR2(9)     := 'BANK_CODE';
  cv_tkn_bank_name           CONSTANT VARCHAR2(9)     := 'BANK_NAME';
  cv_tkn_bank_branch_code    CONSTANT VARCHAR2(16)    := 'BANK_BRANCH_CODE';
  cv_tkn_bank_branch_name    CONSTANT VARCHAR2(16)    := 'BANK_BRANCH_NAME';
  cv_tkn_bank_holder_name    CONSTANT VARCHAR2(20)    := 'BANK_HOLDER_NAME_ALT';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_col                 CONSTANT VARCHAR2(3)     := 'COL';
  cv_tkn_value               CONSTANT VARCHAR2(5)     := 'VALUE';
  cv_tkn_name                CONSTANT VARCHAR2(4)     := 'NAME';
  cv_tkn_tax_div             CONSTANT VARCHAR2(7)     := 'TAX_DIV';
  cv_tkn_proc_div            CONSTANT VARCHAR2(8)     := 'PROC_DIV';
  cv_tkn_target_div          CONSTANT VARCHAR2(10)    := 'TARGET_DIV';
  -- �v���t�@�C��
  cv_prof_i_dire_path        CONSTANT VARCHAR2(25)    := 'XXCOK1_INFOMART_DIRE_PATH';        -- �C���t�H�}�[�g_�f�B���N�g���p�X
  cv_prof_i_file_name        CONSTANT VARCHAR2(25)    := 'XXCOK1_INFOMART_FILE_NAME';        -- �C���t�H�}�[�g_�t�@�C����
  cv_prof_term_name          CONSTANT VARCHAR2(24)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- �f�t�H���g�x������
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(41)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- ��s�萔��_�U���z�
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- ��s�萔��_��z����
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- ��s�萔��_��z�ȏ�
  cv_prof_bm_tax             CONSTANT VARCHAR2(13)    := 'XXCOK1_BM_TAX';                    -- �̔��萔��_����ŗ�
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: �c�ƒP��
  cv_prof_elec_change_item   CONSTANT VARCHAR2(30)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- �d�C���i�ϓ��j�i�ڃR�[�h
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- �����t�H�[�}�b�g
  cv_fmt_ymd                 CONSTANT VARCHAR2(10)    := 'YYYY/MM/DD';
  -- �t�@�C���I�[�v���p�����[�^
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';                   -- �e�L�X�g�̏�����
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;                 -- 1�s����ő啶����
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT 0;                                  -- �Ώی���
  gn_normal_cnt              NUMBER DEFAULT 0;                                  -- ���팏��
  gn_error_cnt               NUMBER DEFAULT 0;                                  -- �G���[����
  gn_skip_cnt                NUMBER DEFAULT 0;                                  -- �X�L�b�v����
  gd_process_date            DATE   DEFAULT NULL;                               -- �Ɩ��������t
  gd_operating_date          DATE   DEFAULT NULL;                               -- ���ߎx�������o�����t
  gd_closing_date            DATE   DEFAULT NULL;                               -- ���ߓ�
  gd_schedule_date           DATE   DEFAULT NULL;                               -- �x���\���
  gd_pay_date                DATE   DEFAULT NULL;                               -- �x����
  gn_org_id                  NUMBER;                                            -- �c�ƒP��ID
  gv_i_dire_path             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �C���t�H�}�[�g_�f�B���N�g���p�X
  gv_i_file_name             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �C���t�H�}�[�g_�t�@�C����
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �x������
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_�U���z�
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z����
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ��s�萔��_��z�ȏ�
  gv_elec_change_item_code   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �d�C���i�ϓ��j�i�ڃR�[�h
  gn_bm_tax                  NUMBER;                                            -- �̔��萔��_����ŗ�
  gn_tax_include_less        NUMBER;                                            -- �ō���s�萔��_��z����
  gn_tax_include_more        NUMBER;                                            -- �ō���s�萔��_��z�ȏ�
  g_file_handle              UTL_FILE.FILE_TYPE;                                -- �t�@�C���n���h��
--
  gv_remarks                 fnd_new_messages.message_text%TYPE;                -- �����Ĕ��l
  gv_custom_title            fnd_new_messages.message_text%TYPE;                -- �J�X�^�����׃^�C�g��
  gv_line_sum                fnd_new_messages.message_text%TYPE;                -- ���׍��v�s��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gt_head_item               xxcok_common_pkg.g_split_csv_tbl;
  gt_custom_item             xxcok_common_pkg.g_split_csv_tbl;
--
  -- ===============================================
  -- �O���[�o���J�[�\��(�w�b�_�[�E����)
  -- ===============================================
  CURSOR g_head_cur(
      it_tax_div    IN  VARCHAR2
     ,it_target_div IN  VARCHAR2
  )
  IS
    -- �x������
-- Ver1.2 N.Abe MOD START
--    SELECT  xiwh.set_code               AS  set_code
    SELECT  /*+ LEADING(xiwh xiwl) USE_HASH(xiwl) */
            xiwh.set_code               AS  set_code
-- Ver1.2 N.Abe MOD END
           ,xiwh.cust_name              AS  cust_name
           ,NULL                        AS  office
           ,xiwh.dest_post_code         AS  dest_post_code
           ,xiwh.dest_address1          AS  dest_address1
           ,NULL                        AS  dest_address2
           ,xiwh.dest_tel               AS  dest_tel
           ,xiwh.fax                    AS  fax
           ,NULL                        AS  business
           ,xiwh.dept_name              AS  dept_name
           ,xiwh.send_post_code         AS  send_post_code
           ,xiwh.send_address1          AS  send_address1
           ,NULL                        AS  send_address2
           ,xiwh.send_tel               AS  send_tel
           ,xiwh.num                    AS  num
           ,xiwh.vendor_code            AS  vendor_code
-- Ver1.2 N.Abe MOD START
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
-- Ver1.2 N.Abe MOD END
           ,xiwh.payment_date           AS  payment_date
           ,CASE
              WHEN xiwh.notifi_amt < 0 THEN
                0
              ELSE
                xiwh.notifi_amt
            END                         AS  notifi_amt
           ,xiwh.total_amt_no_tax_10    AS  total_amt_no_tax_10
           ,xiwh.tax_amt_10             AS  tax_amt_10
           ,xiwh.total_amt_10           AS  total_amt_10
           ,xiwh.total_amt_no_tax_8     AS  total_amt_no_tax_8
           ,xiwh.tax_amt_8              AS  tax_amt_8
           ,xiwh.total_amt_8            AS  total_amt_8
           ,xiwh.total_amt_no_tax_0     AS  total_amt_no_tax_0
           ,xiwh.tax_amt_0              AS  tax_amt_0
           ,xiwh.total_amt_0            AS  total_amt_0
           ,xiwh.closing_date           AS  closing_date
           ,xiwh.total_sales_qty        AS  total_sales_qty
           ,xiwh.total_sales_amt        AS  total_sales_amt
           ,xiwh.sales_fee              AS  sales_fee
           ,CASE
              WHEN xiwh.set_code IN ('0', '2')
              THEN NULL
              ELSE xiwh.electric_amt
            END                         AS  electric_amt
           ,xiwh.tax_amt                AS  h_tax_amt
           ,xiwh.transfer_fee           AS  transfer_fee
           ,CASE
              WHEN xiwh.payment_amt < 0 THEN
                0
              ELSE
                xiwh.payment_amt
            END                         AS  payment_amt
           ,xiwl.line_item              AS  line_item
           ,xiwl.unit_price             AS  unit_price
           ,xiwl.qty                    AS  qty
           ,xiwl.unit_type              AS  unit_type
           ,xiwl.amt                    AS  amt
           ,xiwl.tax_amt                AS  l_tax_amt
           ,xiwl.total_amt              AS  total_amt
           ,xiwl.inst_dest              AS  inst_dest
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwl.cust_code              AS  cust_code
           ,xiwl.order_num              AS  order_num
           ,xiwl.item_code              AS  item_code
      FROM  xxcok_info_work_header   xiwh
           ,xxcok_info_work_line     xiwl
     WHERE xiwh.vendor_code   = xiwl.vendor_code(+)
     AND   xiwh.tax_div       = it_tax_div
     AND   xiwl.tax_div(+)    = it_tax_div          -- �̔����ׂ����݂��Ȃ��ꍇ���܂ށi�O�������j
     AND   xiwh.target_div    = it_target_div
     AND   xiwl.target_div(+) = it_target_div       -- �̔����ׂ����݂��Ȃ��ꍇ���܂ށi�O�������j
-- Ver1.2 N.Abe ADD START
     AND   xiwl.tax_div(+)    = xiwh.tax_div          -- �̔����ׂ����݂��Ȃ��ꍇ���܂ށi�O�������j
     AND   xiwl.target_div(+) = xiwh.target_div       -- �̔����ׂ����݂��Ȃ��ꍇ���܂ށi�O�������j
-- Ver1.2 N.Abe ADD END
     AND   xiwh.payment_amt   > 0                   -- �x������
    UNION ALL
    -- �x���Ȃ� ���� �̔����ׂ����݂���ꍇ
-- Ver1.2 N.Abe MOD START
--    SELECT
    SELECT  /*+ LEADING(xiwh xiwl) USE_NL(xiwl) INDEX(xiwl XXCOK_INFO_WORK_LINE_N01) */
-- Ver1.2 N.Abe MOD END
            CASE
              WHEN it_tax_div = '1' THEN '0'
              WHEN it_tax_div = '2' THEN '2'
            END                         AS  set_code                -- �ʒm�������ݒ�R�[�h
           ,xiwh.cust_name              AS  cust_name
           ,NULL                        AS  office
           ,xiwh.dest_post_code         AS  dest_post_code
           ,xiwh.dest_address1          AS  dest_address1
           ,NULL                        AS  dest_address2
           ,xiwh.dest_tel               AS  dest_tel
           ,xiwh.fax                    AS  fax
           ,NULL                        AS  business
           ,xiwh.dept_name              AS  dept_name
           ,xiwh.send_post_code         AS  send_post_code
           ,xiwh.send_address1          AS  send_address1
           ,NULL                        AS  send_address2
           ,xiwh.send_tel               AS  send_tel
           ,xiwh.num                    AS  num
           ,xiwh.vendor_code            AS  vendor_code
-- Ver1.2 N.Abe MOD START
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
-- Ver1.2 N.Abe MOD END
           ,xiwh.payment_date           AS  payment_date
           ,0                           AS  notifi_amt
           ,xiwh.total_amt_no_tax_10    AS  total_amt_no_tax_10
           ,xiwh.tax_amt_10             AS  tax_amt_10
           ,xiwh.total_amt_10           AS  total_amt_10
           ,xiwh.total_amt_no_tax_8     AS  total_amt_no_tax_8
           ,xiwh.tax_amt_8              AS  tax_amt_8
           ,xiwh.total_amt_8            AS  total_amt_8
           ,xiwh.total_amt_no_tax_0     AS  total_amt_no_tax_0
           ,xiwh.tax_amt_0              AS  tax_amt_0
           ,xiwh.total_amt_0            AS  total_amt_0
           ,xiwh.closing_date           AS  closing_date
           ,0                           AS  total_sales_qty
           ,0                           AS  total_sales_amt
           ,0                           AS  sales_fee
           ,NULL                        AS  electric_amt
           ,0                           AS  h_tax_amt
           ,0                           AS  transfer_fee
           ,0                           AS  payment_amt
           ,xiwl.line_item              AS  line_item
           ,xiwl.unit_price             AS  unit_price
           ,xiwl.qty                    AS  qty
           ,xiwl.unit_type              AS  unit_type
           ,xiwl.amt                    AS  amt
           ,xiwl.tax_amt                AS  l_tax_amt
           ,xiwl.total_amt              AS  total_amt
           ,xiwl.inst_dest              AS  inst_dest
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwl.cust_code              AS  cust_code
           ,xiwl.order_num              AS  order_num
           ,xiwl.item_code              AS  item_code
      FROM  xxcok_info_work_header   xiwh
           ,xxcok_info_work_line     xiwl
     WHERE xiwh.vendor_code   = xiwl.vendor_code    -- �̔�����(ܰ�����)�����݂���ꍇ�i�������j
     AND   xiwh.tax_div       = it_tax_div
-- Ver1.2 N.Abe MOD START
--     AND   xiwl.tax_div       = it_tax_div          -- �̔�����(ܰ�����)�����݂���ꍇ�i�������j
--     AND   xiwh.target_div    = it_target_div
--     AND   xiwl.target_div    = it_target_div       -- �̔�����(ܰ�����)�����݂���ꍇ�i�������j
     AND   xiwh.target_div    = it_target_div
     AND   xiwl.tax_div       = xiwh.tax_div          -- �̔�����(ܰ�����)�����݂���ꍇ�i�������j
     AND   xiwl.target_div    = xiwh.target_div       -- �̔�����(ܰ�����)�����݂���ꍇ�i�������j
-- Ver1.2 N.Abe MOD END
     AND   xiwh.payment_amt  <= 0                   -- �x���Ȃ�
     ORDER BY
           vendor_code
          ,cust_code
          ,inst_dest
          ,order_num
          ,item_code
          ,unit_price
    ;
--
  g_head_rec    g_head_cur%ROWTYPE;
--
  -- ===============================================
  -- �O���[�o���J�[�\��(�J�X�^������)
  -- ===============================================--
  CURSOR g_custom_cur(
      it_supplier_code  IN  xxcok_backmargin_balance.supplier_code%TYPE
     ,it_tax_div        IN  VARCHAR2
  )
  IS
    SELECT  CASE
              WHEN xiwc.calc_sort = 6
              THEN xiwc.cust_code
              ELSE NULL
            END                         AS  custom1
           ,xiwc.sell_bottle            AS  custom2
           ,SUBSTR(xiwc.sales_qty,1,13) AS  custom3
           ,xiwc.sales_tax_amt          AS  custom4
           ,CASE
              WHEN it_tax_div = '2'
              THEN NULL
              ELSE xiwc.sales_amt
            END                         AS  custom5
           ,xiwc.contract               AS  custom6
           ,xiwc.sales_fee              AS  custom7
           ,xiwc.tax_amt                AS  custom8
           ,xiwc.sales_tax_fee          AS  custom9
           ,xiwc.inst_dest              AS  cust_name
           ,xiwc.calc_type              AS  calc_type
           ,xiwc.cust_code              AS  cust_code
-- Ver1.2 N.Abe MOD START
           ,xiwc.calc_sort              AS  calc_sort
-- Ver1.2 N.Abe MOD END
     FROM   xxcok_info_work_custom   xiwc
     WHERE  xiwc.vendor_code    = it_supplier_code
     AND    xiwc.tax_div        = it_tax_div
     AND    exists (
-- Ver1.2 N.Abe MOD START
--              SELECT 1
              SELECT /*+ use_nl(xiwh) */ 1
-- Ver1.2 N.Abe MOD END
              FROM   xxcok_info_work_header   xiwh
              WHERE  xiwh.vendor_code = xiwc.vendor_code
              AND    xiwh.tax_div     = xiwc.tax_div
              AND    xiwh.payment_amt > 0                 -- �x������
              )
     ORDER BY xiwc.cust_code
-- Ver1.1 N.Abe MOD START
--             ,xiwc.inst_dest
             ,xiwc.calc_sort
             ,xiwc.bottle_code
             ,xiwc.salling_price
-- Ver1.2 N.Abe MOD START
             ,CASE
                WHEN xiwc.calc_sort = '2.7' THEN
                  TO_NUMBER(xiwc.sell_bottle)
                ELSE
                  NULL
              END
-- Ver1.2 N.Abe MOD END
             ,xiwc.rebate_rate
             ,xiwc.rebate_amt
-- Ver1.1 N.Abe MOD END
     ;
--
  g_custom_rec  g_custom_cur%ROWTYPE;
--
  -- ===============================================
  -- ���ʗ�O
  -- ===============================================
  --*** ���b�N�G���[ ***
  global_lock_fail                EXCEPTION;
  --*** ���������ʗ�O ***
  global_process_expt             EXCEPTION;
  --*** ���������ʗ�O(�t�@�C���N���[�Y) ***
  global_process_file_close_expt  EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y(A-12)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_close';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �t�@�C���N���[�Y
    -- ===============================================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_data
   * Description      : �A�g�Ώۃf�[�^�X�V(A-11)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_vendor_code IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR l_lock_cur
    IS
      SELECT  /*+ INDEX(xbb xxcok_backmargin_balance_n06) */
              xbb.bm_balance_id
      FROM    xxcok_backmargin_balance  xbb
      WHERE   xbb.supplier_code         = iv_vendor_code
      AND     xbb.resv_flag             IS NULL
      AND     xbb.edi_interface_status  = '0'
      AND     xbb.fb_interface_status   = '0'
      AND     xbb.gl_interface_status   = '0'
      AND     xbb.closing_date          <= gd_closing_date
      AND     xbb.expect_payment_date   <= gd_schedule_date
      AND     xbb.amt_fix_status        = '1'
      AND     NVL(xbb.payment_amt_tax, 0) = 0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�c���e�[�u�����b�N�擾
    -- ===============================================
    << lock_loop >>
    FOR l_lock_rec IN l_lock_cur LOOP
      -- ===============================================
      -- �̎�c���e�[�u���X�V
      -- ===============================================
      UPDATE xxcok_backmargin_balance xbb
         SET xbb.publication_date        = gd_pay_date                          -- �ē���������
            ,xbb.edi_interface_date      = gd_process_date                      -- �A�g���iEDI�x���ē����j
            ,xbb.edi_interface_status    = '1'                                  -- �A�g�X�e�[�^�X�iEDI�x���ē����j
            ,xbb.last_updated_by         = cn_last_updated_by
            ,xbb.last_update_date        = SYSDATE
            ,xbb.last_update_login       = cn_last_update_login
            ,xbb.request_id              = cn_request_id
            ,xbb.program_application_id  = cn_program_application_id
            ,xbb.program_id              = cn_program_id
            ,xbb.program_update_date     = SYSDATE
       WHERE xbb.bm_balance_id           = l_lock_rec.bm_balance_id
      ;
    END LOOP lock_loop;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �A�g�f�[�^�Ó����`�F�b�N(A-9)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf      OUT    VARCHAR2
   ,ov_retcode     OUT    VARCHAR2
   ,ov_errmsg      OUT    VARCHAR2
   ,it_head_rec    IN     g_head_cur%ROWTYPE
   ,it_cust_rec    IN     g_custom_cur%ROWTYPE
   ,iv_h_c         IN     VARCHAR2
   ,iv_chk_flg     IN OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'chk_data';                      -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- ���b�Z�[�W�֐��߂�l�p
    lb_chk_return   BOOLEAN        DEFAULT TRUE;                                -- �`�F�b�N���ʖ߂�l�p
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- �w�b�_�[�E����
    -- ===============================================
    IF (iv_h_c = 'H') THEN  -- �w�b�_�[�̏ꍇ
      -- �`�F�b�N�t���O��N�̏ꍇ�`�F�b�N����iY�Ȃ�`�F�b�N�ς݁j
      IF (iv_chk_flg = 'N') THEN
        -- ===============================================
        -- �S�p�`�F�b�N
        -- ===============================================
--
        -- ��Ж�
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.cust_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(2)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.cust_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �Z���i���t��j
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.dest_address1
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(5)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_address1
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- ������
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.dept_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(10)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dept_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �Z���i���t���j
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.send_address1
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(12)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_address1
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
-- Ver1.2 N.Abe DEL START
--        -- �����Ĕ��l
--        lb_chk_return := xxccp_common_pkg.chk_double_byte(
--                           iv_chk_char  => it_head_rec.remarks
--                         );
--        IF ( lb_chk_return = FALSE ) THEN
----
--          lv_outmsg       := xxccp_common_pkg.get_msg(
--                               iv_application   => cv_appli_short_name_xxcok
--                              ,iv_name          => cv_msg_xxcok1_10769
--                              ,iv_token_name1   => cv_tkn_col
--                              ,iv_token_value1  => gt_head_item(45)
--                              ,iv_token_name2   => cv_tkn_vendor_code
--                              ,iv_token_value2  => it_head_rec.vendor_code
--                              ,iv_token_name3   => cv_tkn_value
--                              ,iv_token_value3  => it_head_rec.remarks
--                             );
--          lb_msg_return   := xxcok_common_pkg.put_message_f(
--                               in_which         => FND_FILE.LOG
--                              ,iv_message       => lv_outmsg
--                              ,in_new_line      => 0
--                             );
--          ov_retcode := cv_status_warn;
--        END IF;
-- Ver1.2 N.Abe DEL END
--
        -- ��s��
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.bank_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10434
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_name
                              ,iv_token_value4  => it_head_rec.bank_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �x�X��
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.branch_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10435
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                              ,iv_token_name5   => cv_tkn_bank_branch_name
                              ,iv_token_value5  => it_head_rec.branch_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      -- ���׍���
      IF (it_head_rec.line_item IS NOT NULL) THEN
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.line_item
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(37)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.line_item
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
      -- ���喼�i�ݒu�於�j
      IF (it_head_rec.inst_dest IS NOT NULL) THEN
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.inst_dest
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(44)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.inst_dest
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
    END IF;
--
    -- �J�X�^������
    IF (iv_h_c = 'C') THEN
      -- �v�Z�����������ʏ����A�ꗥ�������׍s�ȊO�̏ꍇ
-- Ver1.2 N.Abe MOD START
--      IF ( NVL( it_cust_rec.calc_type, '0' ) <> '10' ) THEN
      IF    ( ( NVL( it_cust_rec.calc_type, '0' ) <> '10' )
        AND   ( NVL( it_cust_rec.calc_sort, '0' ) <> '2.7' ) ) THEN
-- Ver1.2 N.Abe MOD END
        -- �����^�e��
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_cust_rec.custom2
                         );
        IF ( lb_chk_return = FALSE ) THEN
  --
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_custom_item(2)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_cust_rec.custom2
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END IF;
    -- �w�b�_�[�E����
    IF (iv_h_c = 'H') THEN
      -- �`�F�b�N�t���O��N�̏ꍇ�`�F�b�N����iY�Ȃ�`�F�b�N�ς݁j
      IF (iv_chk_flg = 'N') THEN
      -- ===============================================
      -- ���p��������уn�C�t���`�F�b�N
      -- ===============================================
--
        -- �X�֔ԍ��i���t��j
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.dest_post_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(4)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_post_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �d�b�ԍ��i���t��j
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.dest_tel
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(7)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_tel
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- FAX�ԍ�
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.fax
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(8)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.fax
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �X�֔ԍ��i���t���j
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.send_post_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(11)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_post_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �d�b�ԍ��i���t���j
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.send_tel
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(14)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_tel
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
    END IF;
--
    -- �w�b�_�[�E����
    IF (iv_h_c = 'H') THEN
      -- �`�F�b�N�t���O��N�̏ꍇ�`�F�b�N����iY�Ȃ�`�F�b�N�ς݁j
      IF (iv_chk_flg = 'N') THEN
        -- ===============================================
        -- ���p�`�F�b�N
        -- ===============================================
        -- ��s�R�[�h
        lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                           iv_check_char  => it_head_rec.bank_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10460
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- �x�X�R�[�h
        lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                           iv_check_char  => it_head_rec.branch_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10461
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- ===============================================
        -- ���p�p�����L���`�F�b�N
        -- ===============================================
        -- ������
        lb_chk_return := xxccp_common_pkg.chk_single_byte(
                           iv_chk_char  => it_head_rec.bank_holder_name_alt
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10462
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                              ,iv_token_name5   => cv_tkn_bank_holder_name
                              ,iv_token_value5  => it_head_rec.bank_holder_name_alt
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
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
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_work_head_line
   * Description      : ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE get_work_head_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_work_head_line';                      -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- ���b�Z�[�W�֐��߂�l�p
--
    lv_pre_vendor_code    xxcok_info_work_header.vendor_code%TYPE;
    lv_pre_cust_code      xxcok_info_work_custom.cust_code%TYPE;
    ln_l_loop_cnt         NUMBER DEFAULT 0;
    ln_h_loop_cnt         NUMBER DEFAULT 0;
    ln_out_cnt            PLS_INTEGER;
    lv_skip_flg           VARCHAR2(1) DEFAULT 'N';
    lv_chk_flg            VARCHAR2(1) DEFAULT 'N';
    lv_upd_flg            VARCHAR2(1) DEFAULT 'Y';
--
    lv_head_data          VARCHAR2(32767);
--
    TYPE rec_out_data IS RECORD
      (
        column    VARCHAR2(32767)
      );
    TYPE l_tab_out_data IS TABLE OF rec_out_data INDEX BY PLS_INTEGER;
    lt_out_data         l_tab_out_data;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    ln_out_cnt := 1;
    -- ===============================================
    -- �w�b�_�[�E���׃f�[�^�擾�J�[�\��
    -- ===============================================
    OPEN g_head_cur(
            iv_tax_div
           ,iv_target_div
          );
    << head_loop >>
    LOOP 
      FETCH g_head_cur INTO g_head_rec;
      -- �O���ڂŁA�f�[�^���Ȃ��ꍇ���[�v�𔲂���
      IF (ln_h_loop_cnt = 0) THEN
        EXIT WHEN g_head_cur%NOTFOUND;
      END IF;
--
      -- �w�b�_�[�̃��R�[�h�Ȃ��i�ŏI�s�̌�j�A���͑��t��R�[�h���O�񃋁[�v���ƈႤ
      IF    ( g_head_cur%NOTFOUND = TRUE )
        OR  ( NVL( lv_pre_vendor_code, g_head_rec.vendor_code )  <> g_head_rec.vendor_code )
      THEN
--
        -- �J�E���^������
        ln_l_loop_cnt := 0;
--
        -- ===============================================
        -- �J�X�^�����׃f�[�^�擾(A-8)
        -- ===============================================
        OPEN g_custom_cur(
                lv_pre_vendor_code
               ,iv_tax_div
              );
--
        << custom_loop >>
        LOOP
          FETCH g_custom_cur INTO g_custom_rec;
          EXIT WHEN g_custom_cur%NOTFOUND;
--
          -- ===============================================
          -- �A�g�f�[�^�Ó����`�F�b�N(�J�X�^������)(A-9)
          -- ===============================================
          chk_data(
            ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           ,it_head_rec   => g_head_rec
           ,it_cust_rec   => g_custom_rec
           ,iv_h_c        => 'C'
           ,iv_chk_flg    => lv_chk_flg
          );
--
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_skip_flg := 'Y';
          END IF;
--
          -- ===============================================
          -- �A�g�f�[�^�t�@�C���쐬(A-10)
          -- ===============================================
          -- �J�X�^������1�s�ڂ��`�F�b�N
          IF (ln_l_loop_cnt = 0) THEN
            -- ===============================================
            -- �J�X�^�����ׁE���̏o��
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CN>'           -- �ʒm�������ݒ�R�[�h
                || cv_msg_canm || '�ݒu��ʖ���'               -- �J�X�^�����ז���(�ݒu�ꏊ)
                ;
            ln_out_cnt := ln_out_cnt + 1;
--
            -- ===============================================
            -- �J�X�^�����ׁE���ږ��o��
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CH>'           -- �ʒm�������ݒ�R�[�h
                || cv_msg_canm || gt_custom_item(1)            -- �ݒu�ꏊ
                || cv_msg_canm || gt_custom_item(2)            -- �����^�e��
                || cv_msg_canm || gt_custom_item(3)            -- �̔��{��
                || cv_msg_canm || gt_custom_item(4)            -- �̔����z�i�ō��j
                || cv_msg_canm || gt_custom_item(5)            -- �̔����z�i�Ŕ��j
                || cv_msg_canm || gt_custom_item(6)            -- ���_����e
                || cv_msg_canm || gt_custom_item(7)            -- �̔��萔���i�Ŕ��j
                || cv_msg_canm || gt_custom_item(8)            -- �����
                || cv_msg_canm || gt_custom_item(9)            -- �̔��萔���i�ō��j
                ;
--
            ln_out_cnt := ln_out_cnt + 1;
--
          END IF;
--
          -- �O��ڋq��NULL���́A�O��ƒl���Ⴄ�ꍇ
          IF    (lv_pre_cust_code IS NULL)
            OR  (lv_pre_cust_code <> g_custom_rec.cust_code)
          THEN
--
            -- ===============================================
            -- �J�X�^�����ׁE�ڋq���o��
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CD>'            -- �ʒm�������ݒ�R�[�h
                || cv_msg_canm || g_custom_rec.cust_name        -- �ݒu�ꏊ�i�ڋq���j
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂT
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂU
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂV
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂW
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂX
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�O
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�P
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�Q
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�R
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�S
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�T
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�U
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�V
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�W
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�X
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�O
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�P
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�Q
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�R
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�S
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�T
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�U
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�V
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�W
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�X
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�O
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�P
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�Q
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�R
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�S
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�T
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�U
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�V
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�W
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�X
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�O
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�P
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�Q
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�R
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�S
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�T
                || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�U
                ;
--
            ln_out_cnt := ln_out_cnt + 1;
--
          END IF;
          -- ���񃋁[�v�p�Ɍڋq��ێ�
          lv_pre_cust_code := g_custom_rec.cust_code;
--
          -- ===============================================
          -- �J�X�^�����ׁE���ڏ��o��
          -- ===============================================
          lt_out_data(ln_out_cnt).column := '<CD>'            -- �ʒm�������ݒ�R�[�h
              || cv_msg_canm || g_custom_rec.custom1          -- �J�X�^�����ׂP�i�ݒu�ꏊ�j
              || cv_msg_canm || g_custom_rec.custom2          -- �J�X�^�����ׂQ�i�����^�e��j
              || cv_msg_canm || g_custom_rec.custom3          -- �J�X�^�����ׂR�i�̔��{���j
              || cv_msg_canm || g_custom_rec.custom4          -- �J�X�^�����ׂS�i�̔����z�i�ō��j�j
              || cv_msg_canm || g_custom_rec.custom5          -- �J�X�^�����ׂT�i�̔����z�i�Ŕ��j�j
              || cv_msg_canm || g_custom_rec.custom6          -- �J�X�^�����ׂU�i���_����e�j
              || cv_msg_canm || g_custom_rec.custom7          -- �J�X�^�����ׂV�i�̔��萔���i�Ŕ��j�j
              || cv_msg_canm || g_custom_rec.custom8          -- �J�X�^�����ׂW�i����Łj
              || cv_msg_canm || g_custom_rec.custom9          -- �J�X�^�����ׂX�i�̔��萔���i�ō��j�j
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�O
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�P
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�Q
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�R
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�S
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�T
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�U
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�V
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�W
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂP�X
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�O
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�P
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�Q
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�R
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�S
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�T
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�U
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�V
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�W
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂQ�X
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�O
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�P
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�Q
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�R
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�S
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�T
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�U
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�V
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�W
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂR�X
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�O
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�P
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�Q
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�R
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�S
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�T
              || cv_msg_canm || NULL                          -- �J�X�^�����ׂS�U
              ;
--
          ln_out_cnt := ln_out_cnt + 1;
--
          -- �J�X�^�����׃J�E���^
          ln_l_loop_cnt := ln_l_loop_cnt + 1;
--
        END LOOP custom_loop;
        CLOSE g_custom_cur;
--
        -- �x���f�[�^�Ȃ��̏ꍇ�o��
        IF ( lv_skip_flg <> 'Y' ) THEN
          -- �������݃��[�v
          FOR i IN 1..ln_out_cnt - 1 LOOP
            -- ===============================================
            -- �t�@�C���o��
            -- ===============================================
            UTL_FILE.PUT_LINE(
              file      => g_file_handle
             ,buffer    => lt_out_data(i).column
            );
--
            -- ===============================================
            -- �o�͂̕\���֘A�W���o��
            -- ===============================================
            lb_msg_return := xxcok_common_pkg.put_message_f(
                               in_which        => FND_FILE.OUTPUT
                              ,iv_message      => lt_out_data(i).column
                              ,in_new_line     => 0
                             );
--
          END LOOP;
          gn_normal_cnt := gn_normal_cnt + 1;
--
        ELSE
          gn_skip_cnt := gn_skip_cnt + 1;
        END IF;
--
        -- �X�V�Ώۂ��`�F�b�N
        IF ( lv_upd_flg = 'Y' ) AND ( lv_skip_flg = 'N' ) THEN
          -- ===============================================
          -- �A�g�Ώۃf�[�^�X�V(A-11)
          -- ===============================================
          upd_data(
            ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
           ,iv_vendor_code  => lv_pre_vendor_code
          );
        END IF;
--
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        --�J�E���^�A�t���O�A�o�͗p�ϐ���������
        ln_out_cnt  := 1;
        lv_skip_flg := 'N';
        lv_chk_flg  := 'N';
        lv_upd_flg  := 'Y';
        lt_out_data.DELETE;
        -- �J�E���^
        gn_target_cnt := gn_target_cnt + 1;
--
      END IF;
--
      -- �w�b�_�[���Ȃ��ꍇ�͏����𔲂���
      EXIT WHEN g_head_cur%NOTFOUND;
      -- ���񃋁[�v�p�ɑ��t���ێ�
      lv_pre_vendor_code := g_head_rec.vendor_code;
      --
      -- ===============================================
      -- �A�g�f�[�^�t�@�C���쐬(A-10)
      -- ===============================================
      -- 1�s�ڂ��`�F�b�N
      IF (ln_h_loop_cnt = 0) THEN
        -- ===============================================
        -- �w�b�_�[�E���ږ��o��
        -- ===============================================
        lv_head_data := gt_head_item(1)                 -- �ʒm�������ݒ�R�[�h
            || cv_msg_canm || gt_head_item(2)           -- ��Ж�
            || cv_msg_canm || gt_head_item(3)           -- �������E�c�Ə���
            || cv_msg_canm || gt_head_item(4)           -- �X�֔ԍ�
            || cv_msg_canm || gt_head_item(5)           -- �Z��
            || cv_msg_canm || gt_head_item(6)           -- �Z���i�Ԓn�A���������j
            || cv_msg_canm || gt_head_item(7)           -- �d�b�ԍ�
            || cv_msg_canm || gt_head_item(8)           -- FAX�ԍ�
            || cv_msg_canm || gt_head_item(9)           -- ���Ə��E�c�Ə���
            || cv_msg_canm || gt_head_item(10)          -- ������
            || cv_msg_canm || gt_head_item(11)          -- �X�֔ԍ�
            || cv_msg_canm || gt_head_item(12)          -- �Z��
            || cv_msg_canm || gt_head_item(13)          -- �Z���i�Ԓn�E�������j
            || cv_msg_canm || gt_head_item(14)          -- �d�b�ԍ�
            || cv_msg_canm || gt_head_item(15)          -- �ԍ�
            || cv_msg_canm || gt_head_item(16)          -- ���t��R�[�h
            || cv_msg_canm || gt_head_item(17)          -- ����
            || cv_msg_canm || gt_head_item(18)          -- �x����
            || cv_msg_canm || gt_head_item(19)          -- �����Ă̒ʒm���z
            || cv_msg_canm || gt_head_item(20)          -- 10%���v���z�i�Ŕ��j
            || cv_msg_canm || gt_head_item(21)          -- 10%����Ŋz
            || cv_msg_canm || gt_head_item(22)          -- 10%���v���z�i�ō��j
            || cv_msg_canm || gt_head_item(23)          -- �y��8%���v���z�i�Ŕ��j
            || cv_msg_canm || gt_head_item(24)          -- �y��8%����Ŋz
            || cv_msg_canm || gt_head_item(25)          -- �y��8%���v���z�i�ō��j
            || cv_msg_canm || gt_head_item(26)          -- ��ېō��v���z�i�Ŕ��j
            || cv_msg_canm || gt_head_item(27)          -- ��ېŏ���Ŋz
            || cv_msg_canm || gt_head_item(28)          -- ��ېō��v���z�i�ō��j
            || cv_msg_canm || gt_head_item(29)          -- ����
            || cv_msg_canm || gt_head_item(30)          -- �̔��{�����v
            || cv_msg_canm || gt_head_item(31)          -- �̔����z���v
            || cv_msg_canm || gt_head_item(32)          -- �̔��萔���@�Ŕ��^�̔��萔���@�ō�
            || cv_msg_canm || gt_head_item(33)          -- �d�C�㓙���v�@�Ŕ�
            || cv_msg_canm || gt_head_item(34)          -- ����Ł^�������
            || cv_msg_canm || gt_head_item(35)          -- �U���萔���@�ō�
            || cv_msg_canm || gt_head_item(36)          -- ���x�����z�@�ō�
            || cv_msg_canm || gt_head_item(37)          -- ���׍���
            || cv_msg_canm || gt_head_item(38)          -- �P��
            || cv_msg_canm || gt_head_item(39)          -- ����
            || cv_msg_canm || gt_head_item(40)          -- �P��
            || cv_msg_canm || gt_head_item(41)          -- ���z
            || cv_msg_canm || gt_head_item(42)          -- ����Ŋz
            || cv_msg_canm || gt_head_item(43)          -- ���v���z
            || cv_msg_canm || gt_head_item(44)          -- ���喼
            || cv_msg_canm || gt_head_item(45)          -- ���l
            ;
--
            -- ===============================================
            -- �t�@�C���o��
            -- ===============================================
            UTL_FILE.PUT_LINE(
              file      => g_file_handle
             ,buffer    => lv_head_data
            );
--
            -- ===============================================
            -- �o�͂̕\���֘A�W���o��
            -- ===============================================
            lb_msg_return := xxcok_common_pkg.put_message_f(
                               in_which        => FND_FILE.OUTPUT
                              ,iv_message      => lv_head_data
                              ,in_new_line     => 0
                             );
--
      END IF;
      -- ===============================================
      -- �w�b�_�[�E���׏��o��
      -- ===============================================
      lt_out_data(ln_out_cnt).column := g_head_rec.set_code                 -- �ʒm�������ݒ�R�[�h
          || cv_msg_canm || g_head_rec.cust_name                            -- ��Ж�
          || cv_msg_canm || g_head_rec.office                               -- �������E�c�Ə���
          || cv_msg_canm || g_head_rec.dest_post_code                       -- �X�֔ԍ�
          || cv_msg_canm || g_head_rec.dest_address1                        -- �Z��
          || cv_msg_canm || g_head_rec.dest_address2                        -- �Z���i�Ԓn�A���������j
          || cv_msg_canm || g_head_rec.dest_tel                             -- �d�b�ԍ�
          || cv_msg_canm || g_head_rec.fax                                  -- FAX�ԍ�
          || cv_msg_canm || g_head_rec.business                             -- ���Ə��E�c�Ə���
          || cv_msg_canm || g_head_rec.dept_name                            -- ������
          || cv_msg_canm || g_head_rec.send_post_code                       -- �X�֔ԍ�
          || cv_msg_canm || g_head_rec.send_address1                        -- �Z��
          || cv_msg_canm || g_head_rec.send_address2                        -- �Z���i�Ԓn�E�������j
          || cv_msg_canm || g_head_rec.send_tel                             -- �d�b�ԍ�
          || cv_msg_canm || g_head_rec.num                                  -- �ԍ�
          || cv_msg_canm || g_head_rec.vendor_code                          -- ���t��R�[�h
          || cv_msg_canm || g_head_rec.subject                              -- ����
          || cv_msg_canm || TO_CHAR( g_head_rec.payment_date, cv_fmt_ymd )  -- �x����
          || cv_msg_canm || g_head_rec.notifi_amt                           -- �����Ă̒ʒm���z
          || cv_msg_canm || g_head_rec.total_amt_no_tax_10                  -- 10%���v���z�i�Ŕ��j
          || cv_msg_canm || g_head_rec.tax_amt_10                           -- 10%����Ŋz
          || cv_msg_canm || g_head_rec.total_amt_10                         -- 10%���v���z�i�ō��j
          || cv_msg_canm || g_head_rec.total_amt_no_tax_8                   -- �y��8%���v���z�i�Ŕ��j
          || cv_msg_canm || g_head_rec.tax_amt_8                            -- �y��8%����Ŋz
          || cv_msg_canm || g_head_rec.total_amt_8                          -- �y��8%���v���z�i�ō��j
          || cv_msg_canm || g_head_rec.total_amt_no_tax_0                   -- ��ېō��v���z�i�Ŕ��j
          || cv_msg_canm || g_head_rec.tax_amt_0                            -- ��ېŏ���Ŋz
          || cv_msg_canm || g_head_rec.total_amt_0                          -- ��ېō��v���z�i�ō��j
          || cv_msg_canm || TO_CHAR( g_head_rec.closing_date, cv_fmt_ymd )  -- ����
          || cv_msg_canm || g_head_rec.total_sales_qty                      -- �̔��{�����v
          || cv_msg_canm || g_head_rec.total_sales_amt                      -- �̔����z���v
          || cv_msg_canm || g_head_rec.sales_fee                            -- �̔��萔���@�Ŕ��^�̔��萔���@�ō�
          || cv_msg_canm || g_head_rec.electric_amt                         -- �d�C�㓙���v�@�Ŕ�
          || cv_msg_canm || g_head_rec.h_tax_amt                            -- ����Ł^�������
          || cv_msg_canm || g_head_rec.transfer_fee                         -- �U���萔���@�ō�
          || cv_msg_canm || g_head_rec.payment_amt                          -- ���x�����z�@�ō�
          || cv_msg_canm || g_head_rec.line_item                            -- ���׍���
          || cv_msg_canm || g_head_rec.unit_price                           -- �P��
          || cv_msg_canm || g_head_rec.qty                                  -- ����
          || cv_msg_canm || g_head_rec.unit_type                            -- �P��
          || cv_msg_canm || g_head_rec.amt                                  -- ���z
          || cv_msg_canm || g_head_rec.l_tax_amt                            -- ����Ŋz
          || cv_msg_canm || g_head_rec.total_amt                            -- ���v���z
          || cv_msg_canm || g_head_rec.inst_dest                            -- ���喼
          || cv_msg_canm || g_head_rec.remarks                              -- ���l
          ;
--
      ln_out_cnt := ln_out_cnt + 1;
--
      -- ===============================================
      -- �A�g�f�[�^�Ó����`�F�b�N(�w�b�_�[�E����)(A-9)
      -- ===============================================
      chk_data(
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
       ,it_head_rec   => g_head_rec
       ,it_cust_rec   => NULL
       ,iv_h_c        => 'H'
       ,iv_chk_flg    => lv_chk_flg
      );
--
      lv_chk_flg := 'Y';
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_skip_flg := 'Y';
      END IF;
--
      -- ���x�����z���`�F�b�N
      IF ( g_head_rec.payment_amt <= 0 ) THEN
        -- �̎�c���X�V�ΏۊO�ɂ���B
        lv_upd_flg := 'N';
      END IF;

      -- ===============================================
      -- �Ώی����擾
      -- ===============================================
      -- �w�b�_�J�E���^
      ln_h_loop_cnt := ln_h_loop_cnt + 1;
--
    END LOOP head_loop;
    CLOSE g_head_cur;
--
  EXCEPTION
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
  END get_work_head_line;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : �t�@�C���I�[�v��(A-6)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_open';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
    lb_fexist       BOOLEAN        DEFAULT FALSE;             -- �t�@�C�����݃`�F�b�N����
    ln_file_length  NUMBER         DEFAULT NULL;              -- �t�@�C���̒���
    ln_block_size   NUMBER         DEFAULT NULL;              -- �u���b�N�T�C�Y
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �t�@�C�����݃`�F�b�N
    -- ===============================================
    UTL_FILE.FGETATTR(
      location     => gv_i_dire_path  -- �f�B���N�g��
     ,filename     => gv_i_file_name  -- �t�@�C����
     ,fexists      => lb_fexist       -- True:�t�@�C�����݁AFalse:�t�@�C�����݂Ȃ�
     ,file_length  => ln_file_length  -- �t�@�C���̒���
     ,block_size   => ln_block_size   -- �u���b�N�T�C�Y
    );
    IF ( lb_fexist ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00009
                        ,iv_token_name1   => cv_tkn_file_name
                        ,iv_token_value1  => gv_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
      RAISE check_file_expt;
    END IF;
    -- ===============================================
    -- �t�@�C���I�[�v��
    -- ===============================================
    g_file_handle := UTL_FILE.FOPEN(
                       gv_i_dire_path   -- �f�B���N�g��
                      ,gv_i_file_name   -- �t�@�C����
                      ,cv_open_mode_w   -- �t�@�C���I�[�v�����@
                      ,cn_max_linesize  -- 1�s����ő啶����
                     );
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_header
   * Description      : ���[�N�w�b�_�[���쐬(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_header(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_header';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �w�b�_�[���o�^
    -- ===============================================
    INSERT INTO xxcok_info_work_header(
      set_code                -- �ʒm�������ݒ�R�[�h
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
    )
    SELECT  /*+ 
                LEADING(xbb pv pvsa)
                INDEX(xbb xxcok_backmargin_balance_n05)
                USE_NL(pv) USE_NL(pvsa) USE_NL(abau) USE_NL(aba) USE_NL(abb)
                */
            CASE
              WHEN iv_tax_div = '1' AND NVL(sum_e.sales_fee,0) = 0
              THEN '0'
              WHEN iv_tax_div = '1' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '1'
              WHEN iv_tax_div = '2' AND NVL(sum_e.sales_fee,0) = 0
              THEN '2'
              WHEN iv_tax_div = '2' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '3'
            END                                   AS  set_code                -- �ʒm�������ݒ�R�[�h
           ,NULL                                  AS  cust_code               -- �ڋq�R�[�h
           ,SUBSTR( pvsa.attribute1, 1, 30 )      AS  cust_name               -- ��Ж�
           ,SUBSTR(pvsa.zip, 1, 3) || '-' || SUBSTR(pvsa.zip, 4, 4)
                                                  AS  dest_post_code          -- �X�֔ԍ�
           ,SUBSTR( pvsa.address_line1 || pvsa.address_line2, 1, 100 )
                                                  AS  dest_address1           -- �Z��
           ,pvsa.phone                            AS  dest_tel                -- �d�b�ԍ�
           ,pvsa.fax                              AS  fax                     -- FAX�ԍ�
           ,SUBSTR( sub1.dept_name, 1, 30 )       AS  dept_name               -- ������
           ,SUBSTR(sub1.send_post_code, 1, 3) || '-' || SUBSTR(sub1.send_post_code, 4, 4)
                                                  AS  send_post_code          -- �X�֔ԍ��i���t���j
           ,SUBSTR( sub1.send_address1, 1, 100 )  AS  send_address1           -- �Z���i���t���j
           ,sub1.send_tel                         AS  send_tel                -- �d�b�ԍ��i���t���j
           ,xbb.supplier_code                     AS  num                     -- �ԍ�
           ,xbb.supplier_code                     AS  vendor_code             -- ���t��R�[�h
           ,gd_pay_date                           AS  payment_date            -- �x����
           ,MAX(xbb.closing_date)                 AS  closing_date            -- ���ߓ�
           ,CASE
              -- �O��
              WHEN iv_tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --����
              WHEN iv_tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  notifi_amt              -- �����Ă̒ʒm���z
           ,NVL(sum_t.sales_amt,0)                AS  total_amt_no_tax_8      -- �y��8%���v���z�i�Ŕ��j
           ,NVL(sum_t.sales_tax_amt,0) - NVL(sum_t.sales_amt,0)
                                                  AS  tax_amt_8               -- �y��8%����Ŋz
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_amt_8             -- �y��8%���v���z�i�ō��j
           ,NVL(sum_t.sales_qty,0)                AS  total_sales_qty         -- �̔��{�����v
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_sales_amt         -- �̔����z���v
           ,NVL(sum_ne.sales_fee,0)               AS  sales_fee               -- �̔��萔���@�Ŕ��^�̔��萔���@�ō�
           ,NVL(sum_e.sales_fee,0)                AS  electric_amt            -- �d�C�㓙���v�@�Ŕ��^�d�C�㓙���v�@�ō�
           ,NVL(sum_t.tax_amt,0)                  AS  tax_amt                 -- ����Ł^�������
           ,CASE
              WHEN pvsa.bank_charge_bearer = 'I'
              THEN 0
              -- �O��
              WHEN    iv_tax_div = '1'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    iv_tax_div = '1'
                  AND pvsa.bank_charge_bearer <> 'I' 
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
              --����
              WHEN    iv_tax_div = '2'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    iv_tax_div = '2'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
            END * -1                              AS  transfer_fee            -- �U���萔���@�ō�
           ,CASE
              -- �O��
              WHEN iv_tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --����
              WHEN iv_tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  payment_amt             -- ���x�����z�@�ō�
-- Ver1.2 N.Abe MOD START
--           ,SUBSTR( gv_remarks, 1, 500 )          AS  remarks                 -- �����Ĕ��l
           ,SUBSTR( '"' || gv_remarks || '"', 1, 500 )
                                                  AS  remarks                 -- �����Ĕ��l
-- Ver1.2 N.Abe MOD END
           ,abb.bank_number                       AS  bank_code               -- ��s�R�[�h
           ,abb.bank_name                         AS  bank_name               -- ��s��
           ,abb.bank_num                          AS  branch_code             -- �x�X�R�[�h
           ,abb.bank_branch_name                  AS  branch_name             -- �x�X��
           ,aba.account_holder_name_alt           AS  bank_holder_name_alt    -- ������
           ,iv_tax_div                            AS  tax_div                 -- �ŋ敪
           ,SUBSTR( xbb.supplier_code, -1, 1 )    AS  target_div              -- �Ώۋ敪
           ,cn_created_by                         AS  created_by              -- �쐬��
           ,SYSDATE                               AS  creation_date           -- �쐬��
           ,cn_last_updated_by                    AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                               AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                  AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                         AS  request_id              -- �v��ID
           ,cn_program_application_id             AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                         AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                               AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_backmargin_balance  xbb
           ,po_vendors                pv
           ,po_vendor_sites_all       pvsa
           ,ap_bank_account_uses      abau                              -- ��s�����g�p���}�X�^
           ,ap_bank_accounts          aba                               -- ��s�����}�X�^
           ,ap_bank_branches          abb                               -- ��s�x�X�}�X�^
           --���_���
           ,(SELECT hca.account_number        AS  contact_code
                   ,hp.party_name             AS  dept_name
                   ,hl.postal_code            AS  send_post_code
                   ,hl.city     ||
                    hl.address1 ||
                    hl.address2               AS  send_address1
                   ,hl.address_lines_phonetic AS  send_tel
             FROM   hz_cust_accounts    hca   --�ڋq�}�X�^
                   ,hz_cust_acct_sites  hcas  --�ڋq���ݒn
                   ,hz_parties          hp    --�p�[�e�B�[�}�X�^
                   ,hz_party_sites      hps   --�p�[�e�B�[�T�C�g
                   ,hz_locations        hl    --�ڋq���Ə�
             WHERE  hca.cust_account_id = hcas.cust_account_id
             AND    hca.party_id        = hp.party_id
             AND    hcas.party_site_id  = hps.party_site_id
             AND    hps.location_id     = hl.location_id
             AND    hcas.org_id         = gn_org_id
            ) sub1
            --�S��
           ,(SELECT SUM(xiwc.sales_qty)      AS  sales_qty
                   ,SUM(xiwc.sales_tax_amt)  AS  sales_tax_amt
                   ,SUM(xiwc.tax_amt)        AS  tax_amt
                   ,SUM(xiwc.sales_amt)      AS  sales_amt
                   ,xiwc.vendor_code         AS  vendor_code
             FROM   xxcok_info_work_custom  xiwc
             WHERE  xiwc.calc_sort = 6
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_t
            --�d�C�㏜�� 
           ,(SELECT CASE
                      WHEN iv_tax_div = '1'
                      THEN SUM(xiwc.sales_fee)
                      WHEN iv_tax_div = '2'
                      THEN SUM(xiwc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xiwc.vendor_code
             FROM   xxcok_info_work_custom  xiwc
--Mod Ver1.3 K.Kanada S
--             WHERE  calc_sort NOT IN (2.5, 5, 6)  -- ���v�A�d�C��A���v ������
             WHERE  calc_sort IN (1,2,3,4)          -- �����ʁA�e��ʁA�ꗥ�����A��z����
--Mod Ver1.3 K.Kanada E
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_ne
            --�d�C��̂�
           ,(SELECT CASE
                      WHEN iv_tax_div = '1'
                      THEN SUM(xiwc.sales_fee)
                      WHEN iv_tax_div = '2'
                      THEN SUM(xiwc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xiwc.vendor_code
             FROM   xxcok_info_work_custom  xiwc
             WHERE  xiwc.calc_sort = 5
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_e
    WHERE   xbb.supplier_code                      = pv.segment1
    AND     pv.vendor_id                           = pvsa.vendor_id
    AND     ( pvsa.inactive_date                   > gd_process_date
      OR    pvsa.inactive_date                     IS NULL )
    AND     pvsa.org_id                            = gn_org_id
    AND     pvsa.attribute4                        = '1'
    AND     pvsa.attribute5                        = sub1.contact_code
    AND     xbb.supplier_code                      = sum_t.vendor_code(+)
    AND     xbb.supplier_code                      = sum_ne.vendor_code(+)
    AND     xbb.supplier_code                      = sum_e.vendor_code(+)
    AND     xbb.edi_interface_status               = '0'
    AND     SUBSTR( xbb.supplier_code, -1, 1)      = iv_target_div
    AND     xbb.closing_date                      <= gd_closing_date
    AND     xbb.expect_payment_date               <= gd_schedule_date
    AND     xbb.fb_interface_status                = '0'
    AND     xbb.gl_interface_status                = '0'
    AND     NVL(xbb.payment_amt_tax,0)             = 0
    AND     xbb.amt_fix_status                     = '1'
    AND     pvsa.vendor_id                         = abau.vendor_id
    AND     pvsa.vendor_site_id                    = abau.vendor_site_id
    AND     abau.primary_flag                      = 'Y'
    AND     gd_pay_date                            BETWEEN NVL( abau.start_date, gd_pay_date )
                                                   AND     NVL( abau.end_date, gd_pay_date )
    AND     aba.bank_account_id                    = abau.external_bank_account_id
    AND     abb.bank_branch_id                     = aba.bank_branch_id
    AND     iv_tax_div                             = CASE
                                                       WHEN pvsa.attribute6 = '1' THEN          -- �ō�
                                                         '2'
                                                       WHEN pvsa.attribute6 IN ('2', '3') THEN  -- �Ŕ��A��ې�
                                                         '1'
                                                     END
    GROUP BY
            xbb.supplier_code
           ,pvsa.attribute1
           ,pvsa.zip
           ,pvsa.address_line1
           ,pvsa.address_line2
           ,pvsa.phone
           ,pvsa.fax
           ,sub1.dept_name
           ,sub1.send_post_code
           ,sub1.send_address1
           ,sub1.send_tel
           ,xbb.supplier_code
           ,pvsa.bank_charge_bearer
           ,abb.bank_number
           ,abb.bank_name
           ,abb.bank_num
           ,abb.bank_branch_name
           ,aba.account_holder_name_alt
           ,sum_ne.sales_fee
           ,sum_e.sales_fee
           ,sum_t.tax_amt
           ,sum_t.sales_amt
           ,sum_t.sales_tax_amt
           ,sum_t.sales_qty
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_work_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_custom
   * Description      : ���[�N�J�X�^�����׏��쐬(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work_custom(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_custom';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
-- Ver1.2 N.Abe ADD START
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    -- ��z�̂݃f�[�^�擾
    CURSOR l_fixed_amt_cur
    IS
      SELECT xiwc.rowid       AS  row_id
            ,xiwc.vendor_code AS  vendor_code
            ,xiwc.cust_code   AS  cust_code
      FROM   xxcok_info_work_custom xiwc
      WHERE  xiwc.calc_type  = '40'                 -- 40:��z
      AND    xiwc.tax_div    = iv_tax_div
      AND    xiwc.target_div = iv_target_div
      AND NOT EXISTS (SELECT 'X'
                      FROM   xxcok_info_work_custom xiwc2
                      WHERE  xiwc2.vendor_code = xiwc.vendor_code
                      AND    xiwc2.cust_code = xiwc.cust_code
                      AND    xiwc2.calc_type IN ('10','20','30')
                     )
   ;
--
    -- �d�C��̂݃f�[�^�擾
    CURSOR l_electric_cur
    IS
      SELECT xiwc.rowid       AS  row_id
            ,xiwc.vendor_code AS  vendor_code
            ,xiwc.cust_code   AS  cust_code
      FROM   xxcok_info_work_custom xiwc
      WHERE  xiwc.calc_type  = '50'                 -- 50:�d�C��
      AND    xiwc.tax_div    = iv_tax_div
      AND    xiwc.target_div = iv_target_div
      AND NOT EXISTS (SELECT 'X'
                      FROM   xxcok_info_work_custom xiwc2
                      WHERE  xiwc2.vendor_code = xiwc.vendor_code
                      AND    xiwc2.cust_code = xiwc.cust_code
                      AND    xiwc2.calc_type IN ('10','20','30','40')
                     )
   ;

-- Ver1.2 N.Abe ADD END
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �J�X�^�����׏��o�^
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- ���t��R�[�h
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
                LEADING(xbb pv pvsa)
                INDEX(xbb xxcok_backmargin_balance_n05)
                USE_NL(pv) USE_NL(pvsa) USE_NL(xbb) USE_NL(sub1) USE_NL(flv1) USE_NL(flv2)
                */
            xbb.supplier_code                       AS  vendor_code             -- ���t��R�[�h
           ,xcbs.delivery_cust_code                 AS  cust_code               -- �ڋq�R�[�h
-- Ver1.1 N.Abe MOD START
--           ,SUBSTR( sub1.cust_name, 1, 18 )         AS  inst_dest               -- �ݒu�ꏊ
           ,SUBSTR( sub1.cust_name, 1, 50 )         AS  inst_dest               -- �ݒu�ꏊ
-- Ver1.1 N.Abe MOD END
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
           ,xbb.tax_code                            AS  tax_code                -- �ŃR�[�h
           ,iv_tax_div                              AS  tax_div                 -- �ŋ敪
           ,SUBSTR( xbb.supplier_code, -1, 1 )      AS  target_div              -- �Ώۋ敪
           ,cn_created_by                           AS  created_by              -- �쐬��
           ,SYSDATE                                 AS  creation_date           -- �쐬��
           ,cn_last_updated_by                      AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                                 AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login                    AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                           AS  request_id              -- �v��ID
           ,cn_program_application_id               AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                           AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                                 AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_cond_bm_support     xcbs  --�����ʔ̎�̋��e�[�u��
           ,xxcok_backmargin_balance  xbb   --�̎�c���e�[�u��
           ,po_vendors                pv    --�d����
           ,po_vendor_sites_all       pvsa  --�d����T�C�g
           ,(SELECT hca.account_number  AS  cust_code
                   ,hp.party_name       AS  cust_name
             FROM   hz_cust_accounts    hca
                   ,hz_parties          hp
                   ,xxcmm_cust_accounts xca
             WHERE  hca.party_id = hp.party_id
             AND    xca.customer_id = hca.cust_account_id
            )                         sub1  -- �ڋq���
           ,(SELECT flv.attribute1 AS container_type_code
                   ,flv.meaning    AS container_type_name
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
             AND flv.language      = USERENV( 'LANG' )
            )                         flv1
           ,(SELECT flv.lookup_code AS calc_type
                   ,flv.meaning     AS line_name
                   ,flv.attribute2  AS calc_type_sort
                   ,flv.attribute3  AS disp
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
             AND flv.language      = USERENV( 'LANG' )
            ) flv2
    WHERE   xcbs.base_code                         = xbb.base_code
    AND     xcbs.delivery_cust_code                = xbb.cust_code
    AND     xcbs.supplier_code                     = xbb.supplier_code
    AND     xcbs.closing_date                      = xbb.closing_date
    AND     xcbs.expect_payment_date               = xbb.expect_payment_date
    AND     xbb.supplier_code                      = pv.segment1
    AND     pv.vendor_id                           = pvsa.vendor_id
    AND     ( pvsa.inactive_date                   > gd_closing_date
        OR    pvsa.inactive_date                   IS NULL )
    AND     pvsa.org_id                            = gn_org_id
    AND     pvsa.attribute4                        = '1' --�{�U����
    AND     xcbs.delivery_cust_code                = sub1.cust_code
    AND     xcbs.container_type_code               = flv1.container_type_code(+)
    AND     xcbs.calc_type                         = flv2.calc_type
    AND     NVL( xbb.resv_flag, 'N' )             != 'Y'
    AND     xbb.edi_interface_status               = '0'
    AND     SUBSTR( xbb.supplier_code, -1, 1)      = iv_target_div
    AND     xbb.closing_date                      <= gd_closing_date
    AND     xbb.expect_payment_date               <= gd_schedule_date
    AND     xbb.fb_interface_status                = '0'
    AND     xbb.gl_interface_status                = '0'
    AND     NVL(xbb.payment_amt_tax,0)             = 0
    AND     xbb.amt_fix_status                     = '1'
    AND     iv_tax_div                             = CASE
                                                       WHEN pvsa.attribute6 = '1' THEN          -- �ō�
                                                         '2'
                                                       WHEN pvsa.attribute6 IN ('2', '3') THEN  -- �Ŕ��A��ې�
                                                         '1'
                                                     END
    GROUP BY
            xbb.supplier_code
           ,xcbs.delivery_cust_code
           ,sub1.cust_name
           ,xcbs.calc_type
           ,flv2.calc_type_sort
           ,flv1.container_type_code
           ,flv1.container_type_name
           ,xcbs.selling_price
           ,xcbs.rebate_rate
           ,xcbs.rebate_amt
           ,xbb.tax_code
           ,flv2.disp
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- �J�X�^�����׏��o�^(���v�s)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- ���t��R�[�h
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
    SELECT  xiwc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xiwc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xiwc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,2.5                             AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xiwc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xiwc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_work_custom  xiwc
    WHERE   xiwc.calc_type  IN  ('10','20')
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
-- Ver1.2 N.Abe ADD START
    -- ===============================================
    -- �J�X�^�����׏��o�^�i�ꗥ�������׍s�j
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- ���t��R�[�h
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
                LEADING(xbb_1 xseh xsel flv)
                USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                */
            xbb_1.supplier_code                 AS vendor_code            -- 01.���t��R�[�h
           ,xseh.ship_to_customer_code          AS cust_code              -- 02.�ڋq�R�[�h
           ,SUBSTR( hp.party_name, 1, 50)       AS inst_dest              -- 03.�ݒu�ꏊ
           ,NULL                                AS calc_type              -- 04.�v�Z����
           ,'2.7'                               AS calc_sort              -- 05.�v�Z�����\�[�g��
           ,xsel.dlv_unit_price                 AS sell_bottle            -- 06.�����^�e��
           ,SUM( xsel.dlv_qty)                  AS sales_qty              -- 07.�̔��{��
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                AS sales_tax_amt          -- 08.�̔����z�i�ō��j
           ,SUM( xsel.pure_amount )             AS sales_amt              -- 09.�̔����z�i�Ŕ��j
           ,NULL                                AS contract               -- 10.���_����e
           ,NULL                                AS sales_fee              -- 11.�̔��萔���i�Ŕ��j
           ,NULL                                AS tax_amt                -- 12.�����
           ,NULL                                AS sales_tax_fee          -- 13.�̔��萔���i�ō��j
           ,NULL                                AS bottle_code            -- 14.�e��敪�R�[�h
           ,NULL                                AS salling_price          -- 15.�������z
           ,NULL                                AS rebate_rate            -- 16.���ߗ�
           ,NULL                                AS rebate_amt             -- 17.���ߊz
           ,NULL                                AS tax_code               -- 18.�ŃR�[�h
           ,iv_tax_div                          AS tax_div                -- 19.�ŋ敪
           ,SUBSTR( xbb_1.supplier_code, -1, 1) AS target_div             -- 20.�Ώۋ敪
           ,cn_created_by                       AS created_by             -- 21.�쐬��
           ,SYSDATE                             AS creation_date          -- 22.�쐬��
           ,cn_last_updated_by                  AS last_updated_by        -- 23.�ŏI�X�V��
           ,SYSDATE                             AS last_update_date       -- 24.�ŏI�X�V��
           ,cn_last_update_login                AS last_update_login      -- 25.�ŏI�X�V���O�C��
           ,cn_request_id                       AS request_id             -- 26.�v��id
           ,cn_program_application_id           AS program_application_id -- 27.�R���J�����g�E�v���O�����E�A�v���P�[�V����id
           ,cn_program_id                       AS program_id             -- 28.�R���J�����g�E�v���O����id
           ,SYSDATE                             AS program_update_date    -- 29.�v���O�����X�V��
    FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
           ,xxcos_sales_exp_lines     xsel  -- �̔����і���
           ,hz_cust_accounts          hca   -- �ڋq�}�X�^
           ,hz_parties                hp    -- �p�[�e�B�[
           ,fnd_lookup_values         flv   -- �̎�v�Z�Ώ۔���敪
           ,(
             SELECT  /*+ 
                        LEADING(xbb pv pvsa xcbs)
                        INDEX(xbb xxcok_backmargin_balance_n05)
                        USE_NL(pv) USE_NL(pvsa) use_nl(xcbs)
                      */
                     xbb.supplier_code
                    ,xbb.cust_code
                    ,xbb.closing_date
             FROM    xxcok_backmargin_balance  xbb       --�̎�c���e�[�u��
                    ,xxcok_cond_bm_support     xcbs  --�����ʔ̎�̋��e�[�u��
                    ,po_vendors                pv    --�d����
                    ,po_vendor_sites_all       pvsa  --�d����T�C�g
             WHERE   xcbs.base_code                    =  xbb.base_code
             AND     xcbs.delivery_cust_code           =  xbb.cust_code
             AND     xcbs.supplier_code                =  xbb.supplier_code
             AND     xcbs.closing_date                 =  xbb.closing_date
             AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
             AND     xcbs.calc_type                    =  '30'                 -- 30:�ꗥ����
             AND     xbb.supplier_code                 =  pv.segment1
             AND     pv.vendor_id                      =  pvsa.vendor_id
             AND     ( pvsa.inactive_date              >  gd_closing_date     --���ߓ�
                 OR    pvsa.inactive_date              IS NULL )
             AND     pvsa.org_id                       =  gn_org_id
             AND     pvsa.attribute4                   =  '1' --�{�U����
             AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
             AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
             AND     xbb.closing_date                  <= gd_closing_date    --���ߓ�
             AND     xbb.expect_payment_date           <= gd_schedule_date   --�x���\���
             AND     xbb.edi_interface_status          =  '0'
             AND     xbb.fb_interface_status           =  '0'
             AND     xbb.gl_interface_status           =  '0'
             AND     NVL(xbb.payment_amt_tax,0)        =   0
             AND     xbb.amt_fix_status                =  '1'
             AND     iv_tax_div = CASE
                                    WHEN pvsa.attribute6 = '1'         THEN '2' -- �ō� �� ����
                                    WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- �Ŕ��A��ې� �� �O��
                                    END
             GROUP BY xbb.supplier_code, xbb.cust_code, xbb.closing_date
             ) xbb_1
    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
    AND     hca.account_number          =  xseh.ship_to_customer_code
    AND     hca.party_id                =  hp.party_id
    AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
    AND     xseh.ship_to_customer_code  =  xbb_1.cust_code
    AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbb_1.closing_date, -1)) + 1 --������
    AND     xseh.delivery_date          <= xbb_1.closing_date                               --������
    AND     flv.lookup_code             =  xsel.sales_class
    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
    AND     flv.language                =  USERENV( 'LANG' )
    AND     flv.enabled_flag            =  'Y'
    AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
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
           ,SUBSTR( hp.party_name, 1, 50)
           ,xbb_1.supplier_code
           ,SUBSTR( xbb_1.supplier_code, -1, 1)
           ,xsel.dlv_unit_price
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- �J�X�^�����׏��o�^(�ꗥ�������v�s)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- ���t��R�[�h
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
    SELECT  xiwc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xiwc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xiwc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,3.5                             AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xiwc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xiwc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_work_custom  xiwc
    WHERE   xiwc.calc_type  = '30'
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- ��z�̂݃f�[�^�擾
    -- ===============================================
    <<fixed_amt_loop>>
    FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
      -- ===============================================
      -- ��z�̂݃f�[�^�X�V
      -- ===============================================
      UPDATE xxcok_info_work_custom xiwc
      SET    ( sales_qty
--              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  /*+ 
                              LEADING(xbb pv pvsa xcbs xseh xsel flv)
                              INDEX(xbb XXCOK_BACKMARGIN_BALANCE_N06 )
                              USE_NL(pv) USE_NL(pvsa)
                              USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                          */
                          SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
--                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- �̔����z�i�ō��j
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
                  FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
                         ,xxcos_sales_exp_lines     xsel  -- �̔����і���
                         ,hz_cust_accounts          hca   -- �ڋq�}�X�^
                         ,hz_parties                hp    -- �p�[�e�B�[
                         ,fnd_lookup_values         flv   -- �̎�v�Z�Ώ۔���敪
                         ,xxcok_backmargin_balance  xbb   -- �̎�c���e�[�u��
                         ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
                         ,po_vendors                pv    -- �d����
                         ,po_vendor_sites_all       pvsa  -- �d����T�C�g
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     hca.account_number          =  xseh.ship_to_customer_code
                  AND     hca.party_id                =  hp.party_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
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
                  AND     xseh.ship_to_customer_code        =  xbb.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbb.closing_date, -1)) + 1 --������
                  AND     xseh.delivery_date                <= xbb.closing_date                     --������
                  AND     xcbs.base_code                    =  xbb.base_code
                  AND     xcbs.delivery_cust_code           =  xbb.cust_code
                  AND     xcbs.supplier_code                =  xbb.supplier_code
                  AND     xcbs.closing_date                 =  xbb.closing_date
                  AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
                  AND     xcbs.calc_type                    =  '40'                 -- 40:��z
                  AND     xbb.supplier_code                 =  pv.segment1
                  AND     pv.vendor_id                      =  pvsa.vendor_id
                  AND     ( pvsa.inactive_date              >  gd_closing_date     --���ߓ�
                      OR    pvsa.inactive_date              IS NULL )
                  AND     pvsa.org_id                       =  gn_org_id
                  AND     pvsa.attribute4                   =  '1' --�{�U����
                  AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
                  AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
                  AND     xbb.closing_date                  <=  gd_closing_date    --���ߓ�
                  AND     xbb.expect_payment_date           <=  gd_schedule_date   --�x���\���
                  AND     xbb.edi_interface_status          =  '0'
                  AND     xbb.fb_interface_status           =  '0'
                  AND     xbb.gl_interface_status           =  '0'
                  AND     NVL(xbb.payment_amt_tax,0)        =  0
                  AND     xbb.amt_fix_status                =  '1'
                  AND     iv_tax_div                        =  CASE
                                                                 WHEN pvsa.attribute6 = '1'         THEN '2' -- �ō� �� ����
                                                                 WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- �Ŕ��A��ې� �� �O��
                                                               END
                  AND     xbb.supplier_code                 = l_fixed_amt_rec.vendor_code
                  AND     xbb.cust_code                     = l_fixed_amt_rec.cust_code
                  GROUP BY
                          xseh.ship_to_customer_code
                         ,SUBSTR( hp.party_name, 1, 50)
                         ,xbb.supplier_code
                         ,SUBSTR( xbb.supplier_code, -1, 1)
              )
      WHERE xiwc.rowid       = l_fixed_amt_rec.row_id
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
      UPDATE xxcok_info_work_custom xiwc
      SET    ( sales_qty
              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  /*+ 
                              LEADING(xbb pv pvsa xcbs xseh xsel flv)
                              INDEX(xbb XXCOK_BACKMARGIN_BALANCE_N06 )
                              USE_NL(pv) USE_NL(pvsa)
                              USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                          */
                          SUM( xsel.dlv_qty)                                AS sales_qty              -- �̔��{��
                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- �̔����z�i�ō��j
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- �̔����z�i�Ŕ��j
                  FROM    xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_�[
                         ,xxcos_sales_exp_lines     xsel  -- �̔����і���
                         ,hz_cust_accounts          hca   -- �ڋq�}�X�^
                         ,hz_parties                hp    -- �p�[�e�B�[
                         ,fnd_lookup_values         flv   -- �̎�v�Z�Ώ۔���敪
                         ,xxcok_backmargin_balance  xbb   -- �̎�c���e�[�u��
                         ,xxcok_cond_bm_support     xcbs  -- �����ʔ̎�̋��e�[�u��
                         ,po_vendors                pv    -- �d����
                         ,po_vendor_sites_all       pvsa  -- �d����T�C�g
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     hca.account_number          =  xseh.ship_to_customer_code
                  AND     hca.party_id                =  hp.party_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
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
                  AND     xseh.ship_to_customer_code        =  xbb.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbb.closing_date, -1)) + 1 --������
                  AND     xseh.delivery_date                <= xbb.closing_date                     --������
                  AND     xcbs.base_code                    =  xbb.base_code
                  AND     xcbs.delivery_cust_code           =  xbb.cust_code
                  AND     xcbs.supplier_code                =  xbb.supplier_code
                  AND     xcbs.closing_date                 =  xbb.closing_date
                  AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
                  AND     xcbs.calc_type                    =  '50'                 -- 50:�d�C��
                  AND     xbb.supplier_code                 =  pv.segment1
                  AND     pv.vendor_id                      =  pvsa.vendor_id
                  AND     ( pvsa.inactive_date              >  gd_closing_date     --���ߓ�
                      OR    pvsa.inactive_date              IS NULL )
                  AND     pvsa.org_id                       =  gn_org_id
                  AND     pvsa.attribute4                   =  '1' --�{�U����
                  AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
                  AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
                  AND     xbb.closing_date                  <=  gd_closing_date    --���ߓ�
                  AND     xbb.expect_payment_date           <=  gd_schedule_date   --�x���\���
                  AND     xbb.edi_interface_status          =  '0'
                  AND     xbb.fb_interface_status           =  '0'
                  AND     xbb.gl_interface_status           =  '0'
                  AND     NVL(xbb.payment_amt_tax,0)        =  0
                  AND     xbb.amt_fix_status                =  '1'
                  AND     iv_tax_div                        =  CASE
                                                                 WHEN pvsa.attribute6 = '1'         THEN '2' -- �ō� �� ����
                                                                 WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- �Ŕ��A��ې� �� �O��
                                                               END
                  AND     xbb.supplier_code                 = l_electric_rec.vendor_code
                  AND     xbb.cust_code                     = l_electric_rec.cust_code
                  GROUP BY
                          xseh.ship_to_customer_code
                         ,SUBSTR( hp.party_name, 1, 50)
                         ,xbb.supplier_code
                         ,SUBSTR( xbb.supplier_code, -1, 1)
              )
      WHERE xiwc.rowid       = l_electric_rec.row_id
      ;
--
    END LOOP elctric_loop;
-- Ver1.2 N.Abe ADD END
    -- ===============================================
    -- �J�X�^�����׏��o�^(���v�s)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- ���t��R�[�h
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
    SELECT  xiwc.vendor_code                AS  vendor_code             -- ���t��R�[�h
           ,xiwc.cust_code                  AS  cust_code               -- �ڋq�R�[�h
           ,xiwc.inst_dest                  AS  inst_dest               -- �ݒu�ꏊ
           ,6                               AS  calc_sort               -- �v�Z�����\�[�g��
           ,'���v'                          AS  sell_bottle             -- �����^�e��
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- �̔��{��
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- �̔����z�i�ō��j
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- �̔����z�i�Ŕ��j
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- �̔��萔���i�Ŕ��j
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- �����
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- �̔��萔���i�ō��j
           ,xiwc.tax_div                    AS  tax_div                 -- �ŋ敪
           ,xiwc.target_div                 AS  target_div              -- �Ώۋ敪
           ,cn_created_by                   AS  created_by              -- �쐬��
           ,SYSDATE                         AS  creation_date           -- �쐬��
           ,cn_last_updated_by              AS  last_updated_by         -- �ŏI�X�V��
           ,SYSDATE                         AS  last_update_date        -- �ŏI�X�V��
           ,cn_last_update_login            AS  last_update_login       -- �ŏI�X�V���O�C��
           ,cn_request_id                   AS  request_id              -- �v��ID
           ,cn_program_application_id       AS  program_application_id  -- �R���J�����g�E�v���O�����E�A
           ,cn_program_id                   AS  program_id              -- �R���J�����g�E�v���O����ID
           ,SYSDATE                         AS  program_update_date     -- �v���O�����X�V��
    FROM    xxcok_info_work_custom  xiwc
-- Ver1.2 N.Abe MOD START
--    WHERE   xiwc.calc_sort  <> 2.5
    WHERE   xiwc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
-- Ver1.2 N.Abe MOD END
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_work_custom;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_line
   * Description      : ���[�N���׏��쐬(A-3)
   ***********************************************************************************/
  PROCEDURE ins_work_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_line';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ���׏��o�^
    -- ===============================================
    INSERT INTO xxcok_info_work_line(
      order_num                   --  1.����
     ,line_item                   --  2.���׍���
     ,unit_price                  --  3.�P��
     ,qty                         --  4.����
     ,unit_type                   --  5.�P��
     ,amt                         --  6.���z
     ,tax_amt                     --  7.����Ŋz
     ,total_amt                   --  8.���v���z
     ,inst_dest                   --  9.�ݒu�於
     ,cust_code                   -- 10.�ڋq�R�[�h
     ,item_code                   -- 11.�i�ڃR�[�h
     ,vendor_code                 -- 12.���t��R�[�h
     ,tax_div                     -- 13.�ŋ敪�i�p�����[�^�j
     ,target_div                  -- 14.�Ώۋ敪
     ,created_by                  -- 15.�쐬��
     ,creation_date               -- 16.�쐬��
     ,last_updated_by             -- 17.�ŏI�X�V��
     ,last_update_date            -- 18.�ŏI�X�V��
     ,last_update_login           -- 19.�ŏI�X�V���O�C��
     ,request_id                  -- 20.�v��ID
     ,program_application_id      -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                  -- 22.�R���J�����g�E�v���O����ID
     ,program_update_date         -- 23.�v���O�����X�V��
    )
    SELECT  /*+ 
                LEADING(xbb_1)
                USE_NL(xseh) USE_NL(xsel) USE_NL(iimb) USE_NL(ximb) USE_NL(hca) USE_NL(hp)
                */
            '1'                                 AS  order_num               --  1.����
           ,ximb.item_short_name                AS  line_item               --  2.���׍���
           ,xsel.dlv_unit_price                 AS  unit_price              --  3.�P��
           ,SUM( xsel.dlv_qty)                  AS  qty                     --  4.����
           ,xsel.dlv_uom_code                   AS  unit_type               --  5.�P��
           ,SUM( xsel.pure_amount )             AS  amt                     --  6.���z
           ,SUM( xsel.tax_amount )              AS  tax_amt                 --  7.����Ŋz
-- Ver1.2 N.Abe MOD START
--           ,SUM( xsel.sale_amount )             AS  total_amt               --  8.���v���z
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                AS  total_amt               --  8.���v���z
-- Ver1.2 N.Abe MOD END
           ,SUBSTR( hp.party_name, 1, 50)       AS  inst_dest               --  9.�ݒu�於
           ,xseh.ship_to_customer_code          AS  cust_code               -- 10.�ڋq�R�[�h
           ,xsel.item_code                      AS  item_code               -- 11.�i�ڃR�[�h
           ,xbb_1.supplier_code                 AS  vendor_code             -- 12.���t��R�[�h
           ,iv_tax_div                          AS  tax_div                 -- 13.�ŋ敪�i�p�����[�^�j
           ,SUBSTR( xbb_1.supplier_code, -1, 1) AS  target_div              -- 14.�Ώۋ敪
           ,cn_created_by                       AS  created_by              -- 15.�쐬��
           ,SYSDATE                             AS  creation_date           -- 16.�쐬��
           ,cn_last_updated_by                  AS  last_updated_by         -- 17.�ŏI�X�V��
           ,SYSDATE                             AS  last_update_date        -- 18.�ŏI�X�V��
           ,cn_last_update_login                AS  last_update_login       -- 19.�ŏI�X�V���O�C��
           ,cn_request_id                       AS  request_id              -- 20.�v��ID
           ,cn_program_application_id           AS  program_application_id  -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                       AS  program_id              -- 22.�R���J�����g�E�v���O����ID
           ,SYSDATE                             AS  program_update_date     -- 23.�v���O�����X�V��
    FROM    xxcos_sales_exp_headers   xseh      --�̔����уw�b�_�[
           ,xxcos_sales_exp_lines     xsel      --�̔����і���
           ,xxcmn_item_mst_b          ximb      --OPM�i�ڃA�h�I��
           ,ic_item_mst_b             iimb      --OPM�i��
           ,hz_cust_accounts          hca       --�ڋq�}�X�^
           ,hz_parties                hp        --�p�[�e�B�[
           ,(
             SELECT  /*+ 
                         LEADING(xbb pv pvsa)
                         INDEX(xbb xxcok_backmargin_balance_n05)
                         USE_NL(pv) USE_NL(pvsa) 
                      */
                     xbb.supplier_code
                    ,xbb.cust_code
             FROM    xxcok_backmargin_balance  xbb       --�̎�c���e�[�u��
                    ,po_vendors                pv        --�d����}�X�^
                    ,po_vendor_sites_all       pvsa      --�d����T�C�g
             WHERE   1=1
             AND     xbb.edi_interface_status                     = '0'
             AND     SUBSTR( xbb.supplier_code, -1, 1)            = iv_target_div
             AND     xbb.closing_date                            <= gd_closing_date    --���ߓ�
             AND     xbb.expect_payment_date                     <= gd_schedule_date   --�x���\���
             AND     xbb.fb_interface_status                      = '0'
             AND     xbb.gl_interface_status                      = '0'
             AND     NVL(xbb.payment_amt_tax,0)                   = 0
             AND     xbb.amt_fix_status                           = '1'
             AND     xbb.supplier_code                            = pv.segment1
             AND     pv.vendor_id                                 = pvsa.vendor_id
             AND     ( pvsa.inactive_date                         > gd_process_date
               OR    pvsa.inactive_date                          IS NULL )
             AND     pvsa.org_id                                  = gn_org_id
             AND     pvsa.attribute4                              = '1'
             AND     iv_tax_div                                   = CASE
                                                                      WHEN pvsa.attribute6 = '1' THEN          -- �ō�
                                                                        '2'
                                                                      WHEN pvsa.attribute6 IN ('2', '3') THEN  -- �Ŕ��A��ې�
                                                                        '1'
                                                                    END
             GROUP BY xbb.supplier_code, xbb.cust_code
             ) xbb_1
    WHERE   xseh.sales_exp_header_id                     = xsel.sales_exp_header_id
    AND     xsel.item_code                              <> gv_elec_change_item_code       -- �d�C���i�ϓ��j�i�ڃR�[�h ������
    AND     iimb.item_no                                 = xsel.item_code
    AND     ximb.item_id                                 = iimb.item_id
    AND     ximb.start_date_active                      <= xseh.delivery_date
    AND     ximb.end_date_active                        >= xseh.delivery_date
    AND     hca.account_number                           = xseh.ship_to_customer_code
    AND     hca.party_id                                 = hp.party_id
    AND     xseh.delivery_date                          >= LAST_DAY(ADD_MONTHS(gd_closing_date, -1)) + 1 --������
    AND     xseh.delivery_date                          <= LAST_DAY(gd_closing_date)                     --������
    AND     xseh.ship_to_customer_code                   = xbb_1.cust_code
-- Ver1.1 N.Abe ADD START
    AND EXISTS ( SELECT 'X'
                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                 WHERE flv.lookup_type         = 'XXCOK1_CALC_SALES_CLASS'      -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                   AND flv.lookup_code         = xsel.sales_class
                   AND flv.language            = USERENV( 'LANG' )
                   AND flv.enabled_flag        = 'Y'
                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                             AND NVL( flv.end_date_active  , gd_process_date )
                   AND ROWNUM = 1
        )
    AND NOT EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values flv -- ��݌ɕi��
                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- �Q�ƃ^�C�v�F��݌ɕi��
                       AND flv.lookup_code         = xsel.item_code
                       AND flv.language            = USERENV( 'LANG' )
                       AND flv.enabled_flag        = 'Y'
                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND NVL( flv.end_date_active  , gd_process_date )
                       AND ROWNUM = 1
        )
-- Ver1.1 N.Abe ADD END
    GROUP BY
            ximb.item_short_name
           ,xsel.dlv_unit_price
           ,xsel.dlv_uom_code
           ,hp.party_name
           ,xseh.ship_to_customer_code
           ,xsel.item_code
           ,xbb_1.supplier_code
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- ���׏��o�^(���v�s)
    -- ===============================================
    INSERT INTO xxcok_info_work_line(
      order_num                   -- 1.����
     ,line_item                   -- 2.���׍���
     ,qty                         -- 3.����
     ,unit_type                   -- 4.�P��
     ,amt                         -- 5.���z
     ,tax_amt                     -- 6.����Ŋz
     ,total_amt                   -- 7.���v���z
     ,inst_dest                   -- 8.�ݒu�於
     ,cust_code                   -- 9.�ڋq�R�[�h
     ,vendor_code                 -- 10.���t��R�[�h
     ,tax_div                     -- 11.�ŋ敪�i�p�����[�^�j
     ,target_div                  -- 12.�Ώۋ敪
     ,created_by                  -- 13.�쐬��
     ,creation_date               -- 14.�쐬��
     ,last_updated_by             -- 15.�ŏI�X�V��
     ,last_update_date            -- 16.�ŏI�X�V��
     ,last_update_login           -- 17.�ŏI�X�V���O�C��
     ,request_id                  -- 18.�v��ID
     ,program_application_id      -- 19.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id                  -- 20.�R���J�����g�E�v���O����ID
     ,program_update_date         -- 21.�v���O�����X�V��
    )
    SELECT  '2'                         AS  order_num               -- 1.����
           ,gv_line_sum                 AS  line_item               -- 2.���׍���
           ,SUM(xiwl.qty)               AS  qty                     -- 3.����
           ,MAX(xiwl.unit_type)         AS  unit_type               -- 4.�P��
           ,SUM(xiwl.amt)               AS  amt                     -- 5.���z
           ,SUM(xiwl.tax_amt)           AS  tax_amt                 -- 6.����Ŋz
           ,SUM(xiwl.total_amt)         AS  total_amt               -- 7.���v���z
           ,xiwl.inst_dest              AS  inst_dest               -- 8.�ݒu�於
           ,xiwl.cust_code              AS  cust_code               -- 9.�ڋq�R�[�h
           ,xiwl.vendor_code            AS  vendor_code             -- 10.���t��R�[�h
           ,iv_tax_div                  AS  tax_div                 -- 11.�ŋ敪(�p�����[�^)
           ,xiwl.target_div             AS  target_div              -- 12.�Ώۋ敪
           ,cn_created_by               AS  created_by              -- 13.�쐬��
           ,SYSDATE                     AS  creation_date           -- 14.�쐬��
           ,cn_last_updated_by          AS  last_updated_by         -- 15.�ŏI�X�V��
           ,SYSDATE                     AS  last_update_date        -- 16.�ŏI�X�V��
           ,cn_last_update_login        AS  last_update_login       -- 17.�ŏI�X�V���O�C��
           ,cn_request_id               AS  request_id              -- 18.�v��ID
           ,cn_program_application_id   AS  program_application_id  -- 19.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id               AS  program_id              -- 20.�R���J�����g�E�v���O����ID
           ,SYSDATE                     AS  program_update_date     -- 21.�v���O�����X�V��
    FROM    xxcok_info_work_line      xiwl  --�C���t�H�}�[�g�p���[�N�i���ׁj
    WHERE   xiwl.tax_div    = iv_tax_div
    AND     xiwl.target_div = iv_target_div
    AND     xiwl.request_id = cn_request_id
    GROUP BY
            xiwl.cust_code
           ,xiwl.inst_dest
           ,xiwl.vendor_code
           ,xiwl.tax_div
           ,xiwl.target_div
    ;
--
    -- �o�^�����i���������j
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_work_line;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_work(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
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
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���݃`�F�b�N�G���[ ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ���[�N�e�[�u���폜����
    -- ===============================================
    -- �C���t�H�}�[�g�p���[�N�i�w�b�_�[�j
    DELETE xxcok_info_work_header xiwh
    WHERE  xiwh.tax_div    = iv_tax_div
    AND    xiwh.target_div = iv_target_div
    ;
--
    -- �C���t�H�}�[�g�p���[�N�i���ׁj
    DELETE xxcok_info_work_line xiwl
    WHERE  xiwl.tax_div    = iv_tax_div
    AND    xiwl.target_div = iv_target_div
    ;
--
    -- �C���t�H�}�[�g�p���[�N�i�J�X�^�����ׁj
    DELETE xxcok_info_work_custom xiwc
    WHERE  xiwc.tax_div    = iv_tax_div
    AND    xiwc.target_div = iv_target_div
    ;
--
    COMMIT ;
--
  EXCEPTION
    -- *** ���݃`�F�b�N�G���[ ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
    iv_tax_div    IN  VARCHAR2    --  1.�ŋ敪
   ,iv_proc_div   IN  VARCHAR2    --  2.�����敪
   ,iv_target_div IN  VARCHAR2    --  3.�Ώۋ敪
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
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
--
    lv_head_item    fnd_new_messages.message_text%TYPE;
    lv_custom_item  fnd_new_messages.message_text%TYPE;
    ln_cnt          NUMBER;
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    --*** ���������G���[ ***
    init_fail_expt  EXCEPTION;
    --*** �N�C�b�N�R�[�h�f�[�^�擾�G���[ ***
    no_data_expt    EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �R���J�����g���̓p�����[�^���o��
    -- ===============================================
    lv_outmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxcok
                      ,iv_name         => cv_msg_xxcok1_10768
                      ,iv_token_name1  => cv_tkn_tax_div
                      ,iv_token_value1 => iv_tax_div
                      ,iv_token_name2  => cv_tkn_proc_div
                      ,iv_token_value2 => iv_proc_div
                      ,iv_token_name3  => cv_tkn_target_div
                      ,iv_token_value3 => iv_target_div
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_outmsg
                      ,in_new_line     => 2
                     );
    -- ===============================================
    -- 1.�Ɩ��������t�擾
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_00028
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
      RAISE init_fail_expt;
    END IF;
--
    -- �t�@�C���o�͎��̂ݎ擾
    IF ( iv_proc_div = '2' ) THEN
--
      -- ===============================================
      -- 2.�v���t�@�C���擾(�x���ē���_�C���t�H�}�[�g_�f�B���N�g���p�X)
      -- ===============================================
      gv_i_dire_path  := FND_PROFILE.VALUE( cv_prof_i_dire_path );
      IF ( gv_i_dire_path IS NULL ) THEN
        lv_outmsg     := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_i_dire_path
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
        RAISE init_fail_expt;
      END IF;
      -- ===============================================
      -- 2.�v���t�@�C���擾(�x���ē���_�C���t�H�}�[�g_�t�@�C����)
      -- ===============================================
      gv_i_file_name  := FND_PROFILE.VALUE( cv_prof_i_file_name );
      IF ( gv_i_file_name IS NULL ) THEN
        lv_outmsg     := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_i_file_name
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
        RAISE init_fail_expt;
      END IF;
--
      -- �t�@�C�����ݒ�i�O�ŁE���Łj
      gv_i_file_name := gv_i_file_name || iv_tax_div || iv_target_div || '.csv';
--
    END IF;
--
    -- ===============================================
    -- 2.�v���t�@�C���擾(FB�x������)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_term_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
                        ,iv_message       => lv_outmsg
                        ,in_new_line      => 0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(��s�萔��_�U���z�)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_outmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                           ,iv_name          => cv_msg_xxcok1_00003
                           ,iv_token_name1   => cv_tkn_profile
                           ,iv_token_value1  => cv_prof_bank_fee_trans
                          );
      lb_msg_return    := xxcok_common_pkg.put_message_f(
                            in_which         => FND_FILE.LOG
                           ,iv_message       => lv_outmsg
                           ,in_new_line      => 0
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(��s�萔��_��z����)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_less
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(��s�萔��_��z�ȏ�)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_more
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(�̔��萔��_����ŗ�)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(�g�DID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.�v���t�@�C���擾(�d�C���i�ϓ��j�i�ڃR�[�h)
    -- ===============================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_prof_elec_change_item ) ;
    IF ( gv_elec_change_item_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_elec_change_item
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.���b�Z�[�W�擾(�����Ĕ��l)
    -- ===============================================
    gv_remarks  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_short_name_xxcok
                    ,iv_name         => cv_msg_xxcok1_10762
                   );
--
    -- �p�����[�^�ŋ敪�F�O�ł̏ꍇ
    IF ( iv_tax_div = '1' ) THEN
      -- ===============================================
      -- 3.���b�Z�[�W�擾(�C���t�H�}�[�g�p�w�b�_�[���ږ��i�O�Łj)
      -- ===============================================
      lv_head_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10763
                       );
--
    -- �p�����[�^�ŋ敪�F���ł̏ꍇ
    ELSE
      -- ===============================================
      -- 3.���b�Z�[�W�擾(�C���t�H�}�[�g�p�w�b�_�[���ږ��i���Łj)
      -- ===============================================
      lv_head_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10764
                       );
--
    END IF;
--
    -- ���ڕ���(�J���}�P��)
    -- ===============================================
    -- CSV�����񕪊�
    -- ===============================================
    xxcok_common_pkg.split_csv_data_p(
     ov_errbuf        => lv_errbuf
    ,ov_retcode       => lv_retcode
    ,ov_errmsg        => lv_errmsg
    ,iv_csv_data      => lv_head_item
    ,on_csv_col_cnt   => ln_cnt
    ,ov_split_csv_tab => gt_head_item
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.���b�Z�[�W�擾(�C���t�H�}�[�g�p�J�X�^�����׃^�C�g��)
    -- ===============================================
    gv_custom_title  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appli_short_name_xxcok
                         ,iv_name         => cv_msg_xxcok1_10765
                        );
--
    -- ===============================================
    -- 3.���b�Z�[�W�擾(�C���t�H�}�[�g�p�J�X�^�����׍��ږ�)
    -- ===============================================
    lv_custom_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10766
                       );
--
    -- ���ڕ���(�J���}�P��)
    -- ===============================================
    -- CSV�����񕪊�
    -- ===============================================
    xxcok_common_pkg.split_csv_data_p(
     ov_errbuf        => lv_errbuf
    ,ov_retcode       => lv_retcode
    ,ov_errmsg        => lv_errmsg
    ,iv_csv_data      => lv_custom_item
    ,on_csv_col_cnt   => ln_cnt
    ,ov_split_csv_tab => gt_custom_item
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.���b�Z�[�W�擾(�C���t�H�}�[�g�p���׍��v�s��)
    -- ===============================================
    gv_line_sum  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10767
                    );
--
    -- �Ɩ����t -1�����̒��ߓ��A�x���\������擾
    gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
    -- ===============================================
    -- 5.���ߓ��A�x�����\����擾
    -- ===============================================
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
    -- �x�����擾
    -- ===============================================
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                    id_proc_date      => gd_schedule_date
                   ,in_days           => 0
                   ,in_proc_type      => 1
                  );
    IF ( gd_pay_date IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00036
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 6.�ō��萔���擾
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( 1 + gn_bm_tax / 100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( 1 + gn_bm_tax / 100 );
--
    -- �t�@�C���o�͎��̂ݎ擾
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- 7.�f�B���N�g���o��
      -- ===============================================
      lv_outmsg      := xxccp_common_pkg.get_msg(
                          iv_application   => cv_appli_short_name_xxcok
                         ,iv_name          => cv_msg_xxcok1_00067
                         ,iv_token_name1   => cv_tkn_directory
                         ,iv_token_value1  => xxcok_common_pkg.get_directory_path_f( gv_i_dire_path )
                        );
      lb_msg_return  := xxcok_common_pkg.put_message_f(
                          in_which         => FND_FILE.LOG
                         ,iv_message       => lv_outmsg
                         ,in_new_line      => 0
                        );
      -- ===============================================
      -- 8.�t�@�C�����o��
      -- ===============================================
      lv_outmsg      := xxccp_common_pkg.get_msg(
                          iv_application   => cv_appli_short_name_xxcok
                         ,iv_name          => cv_msg_xxcok1_00006
                         ,iv_token_name1   => cv_tkn_file_name
                         ,iv_token_value1  => gv_i_file_name
                        );
      lb_msg_return  := xxcok_common_pkg.put_message_f(
                          in_which         => FND_FILE.LOG
                         ,iv_message       => lv_outmsg
                         ,in_new_line      => 1
                        );
    END IF;
--
  EXCEPTION
    -- *** �N�C�b�N�R�[�h�f�[�^�擾�G���[***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
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
    iv_tax_div    IN  VARCHAR2    --  1.�ŋ敪
   ,iv_proc_div   IN  VARCHAR2    --  2.�����敪
   ,iv_target_div IN  VARCHAR2    --  3.�Ώۋ敪
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
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
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
      iv_tax_div    =>  iv_tax_div      --  1.�ŋ敪
     ,iv_proc_div   =>  iv_proc_div     --  2.�����敪
     ,iv_target_div =>  iv_target_div   --  3.�Ώۋ敪
     ,ov_errbuf     =>  lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����敪 = 1�F�v�Z�����̏ꍇ
    IF ( iv_proc_div = '1' ) THEN
      -- ===============================================
      -- ���[�N�e�[�u���f�[�^�폜(A-2)
      -- ===============================================
      del_work(
        iv_tax_div    => iv_tax_div      --  1.�ŋ敪
       ,iv_target_div => iv_target_div   --  3.�Ώۋ敪
       ,ov_errbuf     => lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ���[�N���׏��쐬(A-3)
      -- ===============================================
      ins_work_line(
        iv_tax_div    => iv_tax_div      --  1.�ŋ敪
       ,iv_target_div => iv_target_div   --  3.�Ώۋ敪
       ,ov_errbuf     => lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ���[�N�J�X�^�����׏��쐬(A-4)
      -- ===============================================
      ins_work_custom(
        iv_tax_div    => iv_tax_div      --  1.�ŋ敪
       ,iv_target_div => iv_target_div   --  3.�Ώۋ敪
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
      -- ===============================================
      -- ���[�N�w�b�_�[���׏��쐬(A-5)
      -- ===============================================
      ins_work_header(
        iv_tax_div    => iv_tax_div      --  1.�ŋ敪
       ,iv_target_div => iv_target_div   --  3.�Ώۋ敪
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
    END IF;
--
    -- �����敪 = 2�F�t�@�C���o��
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- �t�@�C���I�[�v��(A-6)
      -- ===============================================
      file_open(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-7)
      -- ===============================================
      get_work_head_line(
        iv_tax_div    => iv_tax_div
       ,iv_target_div => iv_target_div
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
      -- ===============================================
      -- �t�@�C���N���[�Y(A-12)
      -- ===============================================
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================================
    -- �X�L�b�v���������݂���ꍇ�A�X�e�[�^�X�x��
    -- ===============================================
    IF ( gn_skip_cnt > 0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O(�t�@�C���N���[�Y) ***
    WHEN global_process_file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_tax_div      IN  VARCHAR2          -- 1.�ŋ敪
   ,iv_proc_div     IN  VARCHAR2          -- 2.�����敪
   ,iv_target_div   IN  VARCHAR2          -- 3.�Ώۋ敪
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
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;              -- ���b�Z�[�W�ϐ�
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- ���b�Z�[�W�R�[�h
    lb_msg_return    BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
--
  BEGIN
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_tax_div    => iv_tax_div       -- 1.�ŋ敪
     ,iv_proc_div   => iv_proc_div      -- 2.�����敪
     ,iv_target_div => iv_target_div    -- 3.�Ώۋ敪
     ,ov_errbuf     => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #e
     ,ov_errmsg     => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ===============================================
    -- �G���[�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => lv_errmsg
                        ,in_new_line   => 1
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => lv_errbuf
                        ,in_new_line   => 0
                       );
    END IF;
    -- ===============================================
    -- �x����������s�o��
    -- ===============================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => NULL
                        ,in_new_line   => 1
                       );
    END IF;
--
    -- �Ώی����̓t�@�C���o�͎��̏o��
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- �Ώی����o��
      -- ===============================================
      lv_out_msg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxccp
                        ,iv_name         => cv_msg_xxccp1_90000
                        ,iv_token_name1  => cv_tkn_count
                        ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_out_msg
                        ,in_new_line     => 0
                       );
    END IF;
--
    -- ===============================================
    -- ���������o��(�G���[������0��)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90001
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90002
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
    -- ===============================================
    -- �X�L�b�v�����o��
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90003
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_skip_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 1
                     );
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
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => lv_message_code
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
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
END XXCOK015A05C;
/
