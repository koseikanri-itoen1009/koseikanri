CREATE OR REPLACE PACKAGE BODY XXCOK016A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK016A04C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : EDI�V�X�e���ɂăC���t�H�}�[�g�Ђ֑��M����x���ē����p�ԍ��f�[�^�t�@�C���쐬
 * Version          : 1.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  upd_data_h                  �A�g�Ώۃf�[�^�X�V(�w�b�_�[)(A-6)
 *  upd_data_c                  �A�g�Ώۃf�[�^�X�V(�J�X�^������)(A-5)
 *  get_work_head_line          ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-2)(A-3)
 *  init                        ��������(A-1)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/02/18    1.0   K.Yoshikawa      �V�K�쐬  E_�{�ғ�_17680
 *  2023/08/31    1.1   Y.Ooyama         E_�{�ғ�_19179�i�C���{�C�X�Ή��iBM�֘A�j�j
 *  2023/11/30    1.2   R.Oikawa         E_�{�ғ�_19707
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK016A04C';
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
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok1_10813        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10813';  -- �ԍ��쐬���b�Z�[�W
  cv_msg_xxcok1_10815        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10815';  -- �C���t�H�}�[�g�����o�͗p�p�����[�^�o��
  cv_msg_xxcok1_10763        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10763';  -- �C���t�H�}�[�g�p�w�b�_�[���ږ��i�O�Łj
  cv_msg_xxcok1_10764        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10764';  -- �C���t�H�}�[�g�p�w�b�_�[���ږ��i���Łj
  cv_msg_xxcok1_10765        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10765';  -- �C���t�H�}�[�g�p�J�X�^�����׃^�C�g��
  cv_msg_xxcok1_10766        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10766';  -- �C���t�H�}�[�g�p�J�X�^�����׍��ږ�
  cv_msg_xxcok1_10767        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10767';  -- �C���t�H�}�[�g�p���׍��v�s��
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
  cv_tkn_file_name           CONSTANT VARCHAR2(9)     := 'FILE_NAME';
  cv_tkn_conn_loc            CONSTANT VARCHAR2(8)     := 'CONN_LOC';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_col                 CONSTANT VARCHAR2(3)     := 'COL';
  cv_tkn_value               CONSTANT VARCHAR2(5)     := 'VALUE';
  cv_tkn_name                CONSTANT VARCHAR2(4)     := 'NAME';
  cv_tkn_tax_div             CONSTANT VARCHAR2(7)     := 'TAX_DIV';
  cv_tkn_rev                 CONSTANT VARCHAR2(3)     := 'REV';
  -- �v���t�@�C��
  cv_prof_i_file_name        CONSTANT VARCHAR2(27)    := 'XXCOK1_INFOMART_R_FILE_NAME';        -- �C���t�H�}�[�g_�t�@�C����
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: �c�ƒP��
-- Ver.1.1 ADD START
  cv_prof_i_regnum_prompt    CONSTANT VARCHAR2(30)    := 'XXCOK1_INFOMART_REGNUM_PROMPT';    -- �C���t�H�}�[�g_�o�^�ԍ��v�����v�g
  cv_prof_invoice_t_no       CONSTANT VARCHAR2(30)    := 'XXCMM1_INVOICE_T_NO';              -- �K�i���������s���Ǝғo�^�ԍ�
  cv_prof_bus_div_tax        CONSTANT VARCHAR2(30)    := 'XXCOK1_BUS_DIV_TAX';               -- ���Ǝҋ敪�i�ېŁj
-- Ver.1.1 ADD END
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- �����t�H�[�}�b�g
  cv_fmt_ymd                 CONSTANT VARCHAR2(10)    := 'YYYY/MM/DD';
  cv_fmt_ymd2                CONSTANT VARCHAR2(8)    := 'YYYYMMDD';
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
-- Ver.1.2 ADD START
  gv_process_ym              VARCHAR2(6) DEFAULT NULL;                          -- �Ɩ������N��
-- Ver.1.2 ADD END
  gn_org_id                  NUMBER;                                            -- �c�ƒP��ID
-- Ver.1.1 ADD START
  gv_i_regnum_prompt         fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �C���t�H�}�[�g_�o�^�ԍ��v�����v�g�i�����ɔ��p�X�y�[�X�t���j
  gv_invoice_t_no            fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- �K�i���������s���Ǝғo�^�ԍ�
  gv_bus_div_tax             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- ���Ǝҋ敪�i�ېŁj
-- Ver.1.1 ADD END
--
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
     ,it_rev        IN  VARCHAR2
  )
  IS
    SELECT  xiwh.set_code               AS  set_code
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
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
           ,xiwh.payment_date           AS  payment_date
           ,xiwh.notifi_amt             AS  notifi_amt
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
           ,xiwh.closing_date_min       AS  closing_date_min
           ,xiwh.total_sales_qty        AS  total_sales_qty
           ,xiwh.total_sales_amt        AS  total_sales_amt
           ,xiwh.sales_fee              AS  sales_fee
           ,CASE
              WHEN xiwh.set_code IN ('0', '2')
              THEN NULL
              ELSE xiwh.electric_amt
            END                         AS  electric_amt
           ,xiwh.tax_amt                AS  h_tax_amt
-- Ver.1.1 MOD START
--           ,xiwh.transfer_fee           AS  transfer_fee
           ,CASE
              WHEN xiwh.set_code IN ('0', '1') THEN
                 -- �O�ł̏ꍇ
                 xiwh.bank_trans_fee_no_tax
              ELSE
                 -- ���ł̏ꍇ
                 xiwh.bank_trans_fee_with_tax
            END                          AS  transfer_fee              -- �U���萔���F(�O��)�U���萔���@�Ŕ��^(����)�U���萔���@�ō�
-- Ver.1.1 MOD END
           ,xiwh.payment_amt            AS  payment_amt
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwh.rowid                  AS  row_id_h
-- Ver.1.1 ADD START
           ,NVL(xiwh.tax_calc_kbn, '2') AS  tax_calc_kbn              -- �Ōv�Z�敪
           ,xiwh.bm_tax_kbn             AS  bm_tax_kbn                -- BM�ŋ敪
           ,NVL2(
              xiwh.vendor_invoice_regnum
             ,gv_bus_div_tax
             ,NULL
            )                           AS  bus_div                    -- ���Ǝҋ敪
           ,NVL2(
              xiwh.vendor_invoice_regnum
             ,gv_i_regnum_prompt || xiwh.vendor_invoice_regnum
             ,NULL
            )                           AS  to_regnum                 -- ���t��o�^�ԍ�
           ,(
              gv_i_regnum_prompt || gv_invoice_t_no
            )                           AS  from_regnum               -- ���t���o�^�ԍ�
           ,CASE
              WHEN xiwh.set_code IN ('0', '1') THEN
                -- �O�ł̏ꍇ
                xiwh.recalc_total_fee_no_tax
              ELSE
                -- ���ł̏ꍇ
                xiwh.recalc_total_fee_with_tax
            END                         AS  recalc_total_fee          -- �萔���v  �F(�O��)�萔���v�@�Ŕ��^(����)�萔���v�@�ō�
           ,CASE
              WHEN xiwh.set_code IN ('0', '1') THEN
                -- �O�ł̏ꍇ
                xiwh.recalc_total_fee_with_tax
              ELSE
                -- ���ł̏ꍇ
                xiwh.recalc_total_fee_no_tax
            END                         AS  recalc_total_fee2         -- �萔���v�Q�F(�O��)�萔���v�@�ō��^(����)�萔���v�@�Ŕ�
           ,xiwh.bank_trans_fee_tax     AS  bank_trans_fee_tax        -- �U���萔���i����Łj
           ,CASE
              WHEN xiwh.set_code IN ('0', '1') THEN
                -- �O�ł̏ꍇ
                xiwh.bank_trans_fee_with_tax
              ELSE
                -- ���ł̏ꍇ
                xiwh.bank_trans_fee_no_tax
            END                         AS  bank_trans_fee2           -- �U���萔���Q�F(�O��)�U���萔���@�ō��^(����)�U���萔���@�Ŕ�
-- Ver.1.1 ADD END
     FROM  xxcok_info_rev_header   xiwh
     WHERE xiwh.tax_div       = it_tax_div
     AND   xiwh.rev           = it_rev
     AND   xiwh.check_result  = '0'
     AND   ((    xiwh.rev           = '2'
             AND xiwh.payment_amt   <  0  )
            OR
            (    xiwh.rev           = '3'
             AND xiwh.payment_amt   >  0  )
            OR
            (    xiwh.rev           = '4'
             AND xiwh.payment_amt   <  0  )
           )
-- Ver.1.2 ADD START
     AND   xiwh.snapshot_create_ym  = gv_process_ym
-- Ver.1.2 ADD END
     ORDER BY
           vendor_code
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
     ,it_rev            IN  VARCHAR2
-- Ver.1.1 ADD START
     ,it_tax_calc_kbn   IN  xxcok_info_rev_header.tax_calc_kbn%TYPE  -- �Ōv�Z�敪
     ,it_bm_tax_kbn     IN  xxcok_info_rev_header.bm_tax_kbn%TYPE    -- BM�ŋ敪
-- Ver.1.1 ADD END
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
-- Ver.1.1 MOD START
--           ,xiwc.sales_fee              AS  custom7
--           ,xiwc.tax_amt                AS  custom8
--           ,xiwc.sales_tax_fee          AS  custom9
           ,CASE
              WHEN it_tax_calc_kbn = '1' AND it_bm_tax_kbn = '1' THEN  --�Ōv�Z�敪���ē����P�ʂ��ABM�ŋ敪���ō��̏ꍇ�A�̔��萔���i�Ŕ��j�͏o�͂��Ȃ�
                NULL
              ELSE
                xiwc.sales_fee
            END                         AS  custom7
           ,CASE
              WHEN it_tax_calc_kbn = '1' THEN                         --�Ōv�Z�敪���ē����P�ʂ̏ꍇ�A����ł͏o�͂��Ȃ�
                NULL
              ELSE
                xiwc.tax_amt
            END                         AS  custom8
           ,CASE
              WHEN it_tax_calc_kbn = '1' AND it_bm_tax_kbn IN ('2','3') THEN  --�Ōv�Z�敪���ē����P�ʂ��ABM�ŋ敪���Ŕ��܂��͔�ېł̏ꍇ�A�̔��萔���i�ō��j�͏o�͂��Ȃ�
                NULL
              ELSE
                xiwc.sales_tax_fee
            END                         AS  custom9
-- Ver.1.1 MOD END
           ,xiwc.inst_dest              AS  cust_name
           ,xiwc.calc_type              AS  calc_type
           ,xiwc.cust_code              AS  cust_code
           ,xiwc.calc_sort              AS  calc_sort
           ,xiwc.rowid                  AS  row_id_c
     FROM   xxcok_info_rev_custom   xiwc
     WHERE  xiwc.vendor_code    = it_supplier_code
     AND    xiwc.tax_div        = it_tax_div
     AND    exists (
              SELECT 1
              FROM   xxcok_info_rev_header   xiwh
              WHERE  xiwh.vendor_code   = xiwc.vendor_code
              AND    xiwh.tax_div       = xiwc.tax_div
              AND    xiwh.rev           = xiwc.rev
              AND    xiwh.check_result  = '0'
              AND    ((    xiwh.rev           = '2'
                       AND xiwh.payment_amt   <  0  )
                      OR
                      (    xiwh.rev           = '3'
                       AND xiwh.payment_amt   >  0  )
                      OR
                      (    xiwh.rev           = '4'
                       AND xiwh.payment_amt   <  0  )
                     )
-- Ver.1.2 ADD START
              AND    xiwh.snapshot_create_ym  = gv_process_ym
-- Ver.1.2 ADD END
                   )
     AND    xiwc.rev            = it_rev
     AND    xiwc.check_result   = '0'
-- Ver.1.2 ADD START
     AND    xiwc.snapshot_create_ym  = gv_process_ym
-- Ver.1.2 ADD END
     ORDER BY xiwc.cust_code
             ,xiwc.calc_sort
             ,xiwc.bottle_code
             ,xiwc.salling_price
             ,CASE
                WHEN xiwc.calc_sort = '2.7' THEN
                  TO_NUMBER(xiwc.sell_bottle)
                ELSE
                  NULL
              END
             ,xiwc.rebate_rate
             ,xiwc.rebate_amt
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
  --*** ���ʊ֐���O ***
  global_api_expt                 EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : upd_data_c
   * Description      : �A�g�Ώۃf�[�^�X�V(�J�X�^������)(A-5)
   ***********************************************************************************/
  PROCEDURE upd_data_c(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_row_id_c    IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data_c';  -- �v���O������
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- �o�͗p���b�Z�[�W
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- ���b�Z�[�W�֐��߂�l�p
--
  BEGIN
    -- ===============================================
    -- �X�e�[�^�X������
    -- ===============================================
    ov_retcode := cv_status_normal;
      -- ===============================================
      -- �C���t�H�}�[�g�p�ԍ��i�J�X�^�����ׁj�e�[�u���X�V
      -- ===============================================
    UPDATE xxcok_info_rev_custom xirc
       SET xirc.edi_interface_date      = gd_process_date                      -- �A�g���iEDI�x���ē����j
          ,xirc.last_updated_by         = cn_last_updated_by
          ,xirc.last_update_date        = SYSDATE
          ,xirc.last_update_login       = cn_last_update_login
          ,xirc.request_id              = cn_request_id
          ,xirc.program_application_id  = cn_program_application_id
          ,xirc.program_id              = cn_program_id
          ,xirc.program_update_date     = SYSDATE
     WHERE xirc.rowid                   = iv_row_id_c
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
  END upd_data_c;
--
  /**********************************************************************************
   * Procedure Name   : upd_data_h
   * Description      : �A�g�Ώۃf�[�^�X�V(�w�b�_�[)(A-6)
   ***********************************************************************************/
  PROCEDURE upd_data_h(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_row_id_h    IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data_h';  -- �v���O������
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
--
    -- ===============================================
    -- �C���t�H�}�[�g�p�ԍ��i�w�b�_�[�j�e�[�u���X�V
    -- ===============================================
    UPDATE xxcok_info_rev_header xirh
       SET xirh.edi_interface_date      = gd_process_date                      -- �A�g���iEDI�x���ē����j
          ,xirh.last_updated_by         = cn_last_updated_by
          ,xirh.last_update_date        = SYSDATE
          ,xirh.last_update_login       = cn_last_update_login
          ,xirh.request_id              = cn_request_id
          ,xirh.program_application_id  = cn_program_application_id
          ,xirh.program_id              = cn_program_id
          ,xirh.program_update_date     = SYSDATE
     WHERE xirh.rowid                   = iv_row_id_h
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
  END upd_data_h;
--
  /**********************************************************************************
   * Procedure Name   : get_work_head_line
   * Description      : ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_work_head_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_rev        IN  VARCHAR2
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
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- �o�͗p���b�Z�[�W
--
    lv_pre_vendor_code    xxcok_info_rev_header.vendor_code%TYPE;
    lv_pre_h_row_id       ROWID;
    lv_pre_cust_code      xxcok_info_rev_custom.cust_code%TYPE;
-- Ver.1.1 ADD START
    lt_pre_tax_calc_kbn   xxcok_info_work_header.tax_calc_kbn%TYPE;  -- �Ōv�Z�敪
    lt_pre_bm_tax_kbn     xxcok_info_work_header.bm_tax_kbn%TYPE;    -- BM�ŋ敪
-- Ver.1.1 ADD END
    ln_l_loop_cnt         NUMBER DEFAULT 0;
    ln_h_loop_cnt         NUMBER DEFAULT 0;
    ln_out_cnt            PLS_INTEGER;
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
           ,iv_rev
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
        -- �J�X�^�����׃f�[�^�擾(A-3)
        -- ===============================================
        OPEN g_custom_cur(
                lv_pre_vendor_code
               ,iv_tax_div
               ,iv_rev
-- Ver.1.1 ADD START
               ,lt_pre_tax_calc_kbn
               ,lt_pre_bm_tax_kbn
-- Ver.1.1 ADD END
              );
--
        << custom_loop >>
        LOOP
          FETCH g_custom_cur INTO g_custom_rec;
          EXIT WHEN g_custom_cur%NOTFOUND;
--
          -- ===============================================
          -- �A�g�f�[�^�t�@�C���쐬(A-4)
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
          -- ===============================================
          -- �A�g�Ώۃf�[�^�X�V(�J�X�^������)(A-5)
          -- ===============================================
          upd_data_c(
            ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
           ,iv_row_id_c     => g_custom_rec.row_id_c
          );
--
        END LOOP custom_loop;
        CLOSE g_custom_cur;
--
        -- �������݃��[�v
        FOR i IN 1..ln_out_cnt - 1 LOOP
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
        -- ===============================================
        -- �A�g�Ώۃf�[�^�X�V(�w�b�_�[)(A-6)
        -- ===============================================
        upd_data_h(
          ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
         ,iv_row_id_h     => lv_pre_h_row_id
        );
--
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        lv_outmsg    := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_10813
                          ,iv_token_name1   => cv_tkn_vendor_code
                          ,iv_token_value1  => lv_pre_vendor_code
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which        => FND_FILE.LOG
                          ,iv_message      => lv_outmsg
                          ,in_new_line     => 0
                         );
--
        --�J�E���^�A�t���O�A�o�͗p�ϐ���������
        ln_out_cnt  := 1;
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
      lv_pre_h_row_id    := g_head_rec.row_id_h;
      -- Ver.1.1 ADD START
      lt_pre_tax_calc_kbn := g_head_rec.tax_calc_kbn;
      lt_pre_bm_tax_kbn   := g_head_rec.bm_tax_kbn;
      -- Ver.1.1 ADD END
      --
      -- ===============================================
      -- �A�g�f�[�^�t�@�C���쐬(A-4)
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
            || cv_msg_canm || gt_head_item(35)          -- �U���萔���F(�O��)�U���萔���@�Ŕ��^(����)�U���萔���@�ō�
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
            || cv_msg_canm || gt_head_item(46)          -- �Ώۊ��ԊJ�n��
            || cv_msg_canm || gt_head_item(47)          -- �Ώۊ��ԏI����
-- Ver.1.1 ADD START
            || cv_msg_canm || gt_head_item(48)          -- ���Ǝҋ敪
            || cv_msg_canm || gt_head_item(49)          -- ���t��o�^�ԍ�
            || cv_msg_canm || gt_head_item(50)          -- ���t���o�^�ԍ�
            || cv_msg_canm || gt_head_item(51)          -- �萔���v  �F(�O��)�萔���v�@�Ŕ��^(����)�萔���v�@�ō�
            || cv_msg_canm || gt_head_item(52)          -- �萔���v�Q�F(�O��)�萔���v�@�ō��^(����)�萔���v�@�Ŕ�
            || cv_msg_canm || gt_head_item(53)          -- �U���萔���@�����
            || cv_msg_canm || gt_head_item(54)          -- �U���萔���Q�F(�O��)�U���萔���@�ō��^(����)�U���萔���@�Ŕ�
-- Ver.1.1 ADD END
            ;
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
          || cv_msg_canm || g_head_rec.transfer_fee                         -- �U���萔���F(�O��)�U���萔���@�Ŕ��^(����)�U���萔���@�ō�
          || cv_msg_canm || g_head_rec.payment_amt                          -- ���x�����z�@�ō�
          || cv_msg_canm || null                                            -- ���׍���
          || cv_msg_canm || null                                            -- �P��
          || cv_msg_canm || null                                            -- ����
          || cv_msg_canm || null                                            -- �P��
          || cv_msg_canm || null                                            -- ���z
          || cv_msg_canm || null                                            -- ����Ŋz
          || cv_msg_canm || null                                            -- ���v���z
          || cv_msg_canm || null                                            -- ���喼
          || cv_msg_canm || g_head_rec.remarks                              -- ���l
          || cv_msg_canm || SUBSTR(
                                   TO_CHAR( g_head_rec.closing_date_min, cv_fmt_ymd2 )
                                   ,1
                                   ,6
                                   ) ||'01'                                  -- �Ώۊ��ԊJ�n��
          || cv_msg_canm || TO_CHAR( g_head_rec.closing_date, cv_fmt_ymd2 )  -- �Ώۊ��ԏI����
-- Ver.1.1 ADD START
          || cv_msg_canm || g_head_rec.bus_div                              -- ���Ǝҋ敪
          || cv_msg_canm || g_head_rec.to_regnum                            -- ���t��o�^�ԍ�
          || cv_msg_canm || g_head_rec.from_regnum                          -- ���t���o�^�ԍ�
          || cv_msg_canm || g_head_rec.recalc_total_fee                     -- �萔���v  �F(�O��)�萔���v�@�Ŕ��^(����)�萔���v�@�ō�
          || cv_msg_canm || g_head_rec.recalc_total_fee2                    -- �萔���v�Q�F(�O��)�萔���v�@�ō��^(����)�萔���v�@�Ŕ�
          || cv_msg_canm || g_head_rec.bank_trans_fee_tax                   -- �U���萔���i����Łj
          || cv_msg_canm || g_head_rec.bank_trans_fee2                      -- �U���萔���Q�F(�O��)�U���萔���@�ō��^(����)�U���萔���@�Ŕ�
-- Ver.1.1 ADD END
          ;
--
      ln_out_cnt := ln_out_cnt + 1;
--
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
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_tax_div    IN  VARCHAR2    --  1.�ŋ敪
   ,iv_rev        IN  VARCHAR2    --  2.REV
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
                      ,iv_name         => cv_msg_xxcok1_10815
                      ,iv_token_name1  => cv_tkn_tax_div
                      ,iv_token_value1 => iv_tax_div
                      ,iv_token_name2  => cv_tkn_rev
                      ,iv_token_value2 => iv_rev
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
-- Ver.1.2 ADD START
    -- ===============================================
    -- �Ɩ����t�N���擾
    -- ===============================================
    gv_process_ym   := TO_CHAR( gd_process_date,'YYYYMM' );
-- Ver.1.2 ADD END
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
--
-- Ver.1.1 ADD START
    -- ===============================================
    -- 2.�v���t�@�C���擾(�C���t�H�}�[�g_�o�^�ԍ��v�����v�g) ��NULL���e
    -- ===============================================
    gv_i_regnum_prompt  := FND_PROFILE.VALUE( cv_prof_i_regnum_prompt );
    IF (gv_i_regnum_prompt IS NOT NULL) THEN
      -- NULL�łȂ��ꍇ�A�����ɔ��p�X�y�[�X��t��
      gv_i_regnum_prompt := gv_i_regnum_prompt || ' ';
    END IF;
--
    -- ===============================================
    -- 2.�v���t�@�C���擾(�K�i���������s���Ǝғo�^�ԍ�)
    -- ===============================================
    gv_invoice_t_no  := FND_PROFILE.VALUE( cv_prof_invoice_t_no );
    IF ( gv_invoice_t_no IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_invoice_t_no
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
                        ,iv_message       => lv_outmsg
                        ,in_new_line      => 0
                       );
      RAISE init_fail_expt;
    END IF;
    --
    -- ===============================================
    -- 2.�v���t�@�C���擾(���Ǝҋ敪�i�ېŁj)
    -- ===============================================
    gv_bus_div_tax  := FND_PROFILE.VALUE( cv_prof_bus_div_tax );
    IF ( gv_bus_div_tax IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_bus_div_tax
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
                        ,iv_message       => lv_outmsg
                        ,in_new_line      => 0
                       );
      RAISE init_fail_expt;
    END IF;
-- Ver.1.1 ADD END
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
   ,iv_rev        IN  VARCHAR2    --  2.REV
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
     ,iv_rev        =>  iv_rev          --  2.REV
     ,ov_errbuf     =>  lv_errbuf       --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���[�N�w�b�_�[�E���בΏۃf�[�^���o(A-2)
    -- ===============================================
    get_work_head_line(
      iv_tax_div    => iv_tax_div
     ,iv_rev        => iv_rev
     ,ov_errbuf     => lv_errbuf
     ,ov_retcode    => lv_retcode
     ,ov_errmsg     => lv_errmsg
    );
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
   ,iv_tax_div      IN  VARCHAR2          -- 1.�ŋ敪
   ,iv_rev          IN  VARCHAR2          -- 2.REV
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
     ,iv_rev        => iv_rev           -- 2.REV
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
END XXCOK016A04C;
/
