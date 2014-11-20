CREATE OR REPLACE PACKAGE BODY XXCOK010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK010A01C(body)
 * Description      : ������ѐU�֏��e�[�u���̃f�[�^����A
                      ���n�V�X�e����I/F����u���ѐU�ցv���쐬���܂��B
 * MD.050           : ������ѐU�֏���I/F�t�@�C���쐬 (MD050_COK_010_A01)
 * Version          : 1.6
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      ��������                        (A-1)
 *  get_selling_trns_info     ������ѐU�֏�񒊏o            (A-2)
 *  output_csvfile            ������уf�[�^�i���ѐU�ցj�o��  (A-3)
 *  update_selling_trns_info  ������ѐU�֏��X�V            (A-4)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   K.Motohashi      �V�K�쐬
 *  2009/02/06    1.1   M.Hiruta         [��QCOK_013]�f�B���N�g���p�X�̏o�͕��@��ύX
 *  2009/03/04    1.2   M.Hiruta         [��QCOK_072]�o�̓t�@�C��(CSV)�����̃J���}�폜
 *  2009/03/19    1.3   M.Hiruta         [��QT1_0087]�sNo�̃_�u���N�H�[�e�[�V�������폜
 *  2010/01/17    1.4   Y.Kuboshima      [��QE_�{�ғ�_00555,��QE_�{�ғ�_00900]
 *                                       �o�͍��ړ��e�̕ύX
 *                                       �y������z�z������z(�ō�)                            -> ������z(�Ŕ�)
 *                                       �y����Ŋz�z������z(�ō�) - ������z(�Ŕ�)           -> �u0�v�Œ�
 *                                       �y���㐔�ʁz����                                      -> ��P�ʐ���
 *                                       �y�[�i�P���z�[�i�P�����[�i�P�ʂP������̊�P�ʐ���  -> ��P�ʒP��
 *  2010/02/18    1.5   K.Yamaguchi      [��QE_�{�ғ�_01600]��݌ɕi�ڂ̏ꍇ�[�i���ʂ��O�Ƃ���
 *                                                           �ϓ��d�C����A�g�ΏۊO�Ƃ���
 *  2011/04/19    1.6   Y.Nishino        [��QE_�{�ғ�_04976]���n�ւ̘A�g���ڒǉ�
 *
 *****************************************************************************************/
--
-- ===================================================
-- �O���[�o���萔�錾��
-- ===================================================
  cv_pkg_name                CONSTANT VARCHAR2(100)  := 'XXCOK010A01C';                      -- �p�b�P�[�W��
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by              CONSTANT NUMBER         := fnd_global.user_id;                  -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER         := fnd_global.user_id;                  -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER         := fnd_global.login_id;                 -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER         := fnd_global.conc_request_id;          -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER         := fnd_global.prog_appl_id;             -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER         := fnd_global.conc_program_id;          -- PROGRAM_ID
--
  -- *** �萔(�Z�p���[�^) ***
  cv_msg_part                CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)    := '.';
  cv_msg_wq                  CONSTANT CHAR(1)        := '"';                                 -- �_�u���N�H�[�e�C�V����
  cv_msg_c                   CONSTANT CHAR(1)        := ',';                                 -- �R���}
  cv_msg_slash               CONSTANT CHAR(1)        := '/';                                 -- �X���b�V��
--
  -- *** �萔(�J�E���g�p���l) ***
  cn_count_0                 CONSTANT NUMBER         := 0;                                   -- 0
  cn_count_1                 CONSTANT NUMBER         := 1;                                   -- 1
--
  -- *** �萔(���l) ***
  cn_number_0                CONSTANT NUMBER         := 0;                                   -- 0
  cn_number_1                CONSTANT NUMBER         := 1;                                   -- 1
--
  -- *** �萔(�A�v���P�[�V�����Z�k��) ***
  cv_appli_name_xxccp        CONSTANT VARCHAR2(10)   := 'XXCCP';                             -- XXCCP
  cv_appli_name_xxcok        CONSTANT VARCHAR2(10)   := 'XXCOK';                             -- XXCOK
--
  -- *** �萔(�g�[�N��) ***
  cv_tkn_output              CONSTANT VARCHAR2(10)   := 'OUTPUT';
  cv_tkn_count               CONSTANT VARCHAR2(10)   := 'COUNT';                             -- �����o�̓g�[�N��
  cv_tkn_bill_no             CONSTANT VARCHAR2(30)   := 'BILL_NO';                           -- �`�[�ԍ�
  cv_tkn_line_no             CONSTANT VARCHAR2(30)   := 'LINE_NO';                           -- ���הԍ�
  cv_tkn_location_code       CONSTANT VARCHAR2(30)   := 'LOCATION_CODE';                     -- ���_�R�[�h
  cv_tkn_customer_code       CONSTANT VARCHAR2(30)   := 'CUSTOMER_CODE';                     -- �ڋq�R�[�h
  cv_tkn_item_code           CONSTANT VARCHAR2(30)   := 'ITEM_CODE';                         -- �i�ڃR�[�h
  cv_tkn_delivery_price      CONSTANT VARCHAR2(30)   := 'DELIVERY_PRICE';                    -- �[�i�P��
  cv_tkn_profile             CONSTANT VARCHAR2(30)   := 'PROFILE';                           -- �v���t�@�C����
  cv_tkn_directory           CONSTANT VARCHAR2(30)   := 'DIRECTORY';                         -- �f�B���N�g��
  cv_tkn_file_name           CONSTANT VARCHAR2(30)   := 'FILE_NAME';                         -- �t�@�C����
--
  -- *** �萔(���b�Z�[�W) ***
  cv_msg_ccp1_90000          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';                  -- �Ώی����o��
  cv_msg_ccp1_90001          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';                  -- ���������o��
  cv_msg_ccp1_90002          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';                  -- �G���[�����o��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  cv_msg_ccp1_90003          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90003';                  -- �X�L�b�v�����o��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
  cv_msg_ccp1_90004          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';                  -- ����I�����b�Z�[�W
  cv_msg_ccp1_90005          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90005';                  -- �x���I�����b�Z�[�W
  cv_msg_ccp1_90006          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';                  -- �G���[�I�����b�Z�[�W
  cv_msg_ccp1_90008          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90008';                  -- ���̓p�����[�^����
--
  cv_msg_cok1_00001          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00001';                  -- �Ώۃf�[�^���G���[
  cv_msg_cok1_00003          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';                  -- �v���t�@�C���擾�G���[
  cv_msg_cok1_00067          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';                  -- �f�B���N�g���o��
  cv_msg_cok1_00006          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';                  -- �t�@�C�����o��
  cv_msg_cok1_00009          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00009';                  -- �t�@�C�����݃`�F�b�N�G���[
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  cv_msg_cok1_00028          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';                  -- �Ɩ����t�擾�G���[
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
  cv_msg_cok1_10070          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10070';                  -- ���b�N�擾�G���[
  cv_msg_cok1_10071          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10071';                  -- �X�V�G���[
--
  -- *** �萔(�J�X�^���E�v���t�@�C����) ***
  cv_prof_company_code       CONSTANT VARCHAR2(50)   := 'XXCOK1_AFF1_COMPANY_CODE';          -- ��ЃR�[�h
  cv_prof_dire_path          CONSTANT VARCHAR2(50)   := 'XXCOK1_SELLING_DIRE_PATH';          -- ������уf�[�^�f�B���N�g���p�X
  cv_prof_file_name          CONSTANT VARCHAR2(50)   := 'XXCOK1_SELLING_FILE_NAME';          -- ������уf�[�^�t�@�C����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  cv_prof_elec_change        CONSTANT VARCHAR2(50)   := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';      -- �d�C���i�ϓ��j�i�ڃR�[�h
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
  -- *** �萔(CSV�t�@�C���I�[�v��) ***
  cv_fopen_open_mode         CONSTANT VARCHAR2(1)    := 'w';
  cn_fopen_max_line          CONSTANT NUMBER         := 32767;
--
  -- *** �萔(���nI/F�t���O) ***
  cv_info_if_flag_yet        CONSTANT VARCHAR2(1)    := '0';                                 -- ����
  cv_info_if_flag_over       CONSTANT VARCHAR2(1)    := '1';                                 -- ��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  cv_info_if_flag_off        CONSTANT VARCHAR2(1)    := '2';                                 -- �ΏۊO
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  -- *** �萔(�Q�ƃ^�C�v) ***
  cv_lookup_type_01          CONSTANT VARCHAR2(30)   := 'XXCOS1_NO_INV_ITEM_CODE';           -- ��݌ɕi��
  -- *** �萔(�Q�ƃ^�C�v�E�L���t���O) ***
  cv_enable                  CONSTANT VARCHAR2(1)   := 'Y'; -- �L��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
-- ==============
-- ���ʗ�O�錾��
-- ==============
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  --==================================================
  -- �O���[�o����O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt           EXCEPTION;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
  -- ==============
  -- �O���[�o���ϐ�
  -- ==============
  gn_target_cnt         NUMBER              DEFAULT NULL;   -- �Ώی���
  gn_normal_cnt         NUMBER              DEFAULT NULL;   -- ���팏��
  gn_error_cnt          NUMBER              DEFAULT NULL;   -- �G���[����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  gn_skip_cnt           NUMBER              DEFAULT 0;      -- �X�L�b�v����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
  gd_sysdate            DATE                DEFAULT NULL;   -- �V�X�e�����t
  gv_prof_company_code  VARCHAR2(100)       DEFAULT NULL;   -- ��ЃR�[�h
  gv_prof_dire_path     VARCHAR2(100)       DEFAULT NULL;   -- ������уf�[�^�f�B���N�g���p�X
  gv_prof_file_name     VARCHAR2(100)       DEFAULT NULL;   -- ������уf�[�^�t�@�C����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  gv_prof_elec_change   VARCHAR2(100)       DEFAULT NULL;   -- �d�C���i�ϓ��j�i�ڃR�[�h
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
  g_file_handle         UTL_FILE.FILE_TYPE  DEFAULT NULL;   -- �t�@�C���n���h��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
  gd_process_date       DATE                DEFAULT NULL;   -- �Ɩ��������t
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
  -- =================================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ������ѐU�֏�񒊏o�J�[�\��(A-2)
  -- =================================
  CURSOR get_sell_trns_info_cur
  IS
    SELECT xsti.selling_trns_info_id  AS xsti_id                   -- ������ѐU�֏��ID(����ID)
         , xsti.slip_no               AS xsti_slip_no              -- �`�[�ԍ�
         , xsti.detail_no             AS xsti_detail_no            -- ���הԍ�
         , xsti.selling_date          AS xsti_selling_date         -- ����v���
         , xsti.selling_type          AS xsti_selling_type         -- ����敪
         , xsti.delivery_slip_type    AS xsti_delivery_slip_type   -- �[�i�`�[�敪
         , xsti.base_code             AS xsti_base_code            -- ���_�R�[�h
         , xsti.cust_code             AS xsti_cust_code            -- �ڋq�R�[�h
         , xsti.selling_emp_code      AS xsti_selling_emp_code     -- �S���c�ƃR�[�h
         , xsti.delivery_form_type    AS xsti_delivery_form_type   -- �[�i�`�ԋ敪
         , xsti.article_code          AS xsti_article_code         -- �����R�[�h
         , xsti.card_selling_type     AS xsti_card_selling_type    -- �J�[�h����敪
         , xsti.checking_date         AS xsti_checking_date        -- ������
         , xsti.demand_to_cust_code   AS xsti_demand_to_cust_code  -- ������ڋq�R�[�h
         , xsti.h_c                   AS xsti_h_c                  -- H��C
         , xsti.column_no             AS xsti_column_no            -- �R����No.
         , xsti.item_code             AS xsti_item_code            -- �i�ڃR�[�h
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR START
--         , xsti.qty                   AS xsti_qty                  -- ����
         , CASE
             WHEN EXISTS( SELECT 'X'
                          FROM fnd_lookup_values_vl     flvv
                          WHERE flvv.lookup_type        = cv_lookup_type_01 -- ��݌ɕi��
                            AND flvv.lookup_code        = xsti.item_code
                            AND flvv.enabled_flag       = cv_enable
                            AND gd_process_date   BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                                      AND NVL( flvv.end_date_active  , gd_process_date )
                  )
             THEN
               0
             ELSE
               xsti.qty
           END                        AS xsti_qty                  -- ����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR END
         , xsti.delivery_unit_price   AS xsti_delivery_unit_price  -- �[�i�P��
         , xsti.selling_amt           AS xsti_selling_amt          -- ������z
         , xsti.selling_amt_no_tax    AS xsti_selling_amt_notax    -- ������z(�Ŕ���)
         , xsti.tax_code              AS xsti_tax_code             -- ����ŃR�[�h
         , xsti.delivery_base_code    AS xsti_delivery_base_code   -- �[�i���_�R�[�h
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- �P�ʂ̒ǉ�
         , xsti.unit_type             AS xsit_unit_type            -- �P��
-- End   2010/01/07 Ver1.4 Y.Kuboshima
    FROM xxcok_selling_trns_info      xsti                         -- ������ѐU�֏��e�[�u��
    WHERE xsti.info_interface_flag = cv_info_if_flag_yet;
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���e�[�u��
  -- ==============================
  TYPE g_sell_trns_info_ttype IS TABLE OF get_sell_trns_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  g_xsti_tab g_sell_trns_info_ttype;
--
  -- ================
  -- ���[�U�[��`��O
  -- ================
  resouce_busy_expt  EXCEPTION;  -- �O���[�o����O
--
  -- ========
  -- �v���O�}
  -- ========
  PRAGMA EXCEPTION_INIT( resouce_busy_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : update_selling_trns_info
   * Description      : ������ѐU�֏��X�V(A-4)
  ***********************************************************************************/
  PROCEDURE update_selling_trns_info(
    ov_errbuf   OUT VARCHAR2          -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2          -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR START
--  , in_idx      IN  BINARY_INTEGER )  -- �J�[�\���擾�l�i�[���R�[�h
  , in_idx      IN  BINARY_INTEGER    -- �J�[�\���擾�l�i�[���R�[�h
  , iv_if_flag  IN  VARCHAR2          -- ���n�A�g�t���O
  )
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR END
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'update_selling_trns_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  -- =========================
  -- ���b�N�擾�p�J�[�\��(A-4)
  -- =========================
  CURSOR lock_table_cur(
    in_sell_trns_info_id IN xxcok_selling_trns_info.selling_trns_info_id%TYPE )
  IS
    SELECT 'X'                      AS dummy
      FROM xxcok_selling_trns_info  xsti                     -- ������ѐU�֏��e�[�u��
     WHERE xsti.selling_trns_info_id = in_sell_trns_info_id
       FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
    -- ============
    -- ���[�J����O
    -- ============
    update_err_expt  EXCEPTION;  -- ������ѐU�֏��X�V�G���[
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =====================================
    --������ѐU�֏��e�[�u���̃��b�N���擾
    -- =====================================
    OPEN  lock_table_cur( g_xsti_tab( in_idx ).xsti_id );
    CLOSE lock_table_cur;
--
      BEGIN
      -- =============================
      --������ѐU�֏��e�[�u�����X�V
      -- =============================
      UPDATE xxcok_selling_trns_info xsti                               -- ������ѐU�֏��e�[�u��
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR START
--         SET xsti.info_interface_flag     =  cv_info_if_flag_over       -- ���nI/F�t���O='1'(I/F��)
         SET xsti.info_interface_flag     =  iv_if_flag                 -- ���nI/F�t���O
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR END
           , xsti.last_updated_by         =  cn_last_updated_by         -- �ŏI�X�V��
           , xsti.last_update_date        =  SYSDATE                    -- �ŏI�X�V��
           , xsti.last_update_login       =  cn_last_update_login       -- �ŏI�X�V���O�C��ID
           , xsti.request_id              =  cn_request_id              -- �v��ID
           , xsti.program_application_id  =  cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           , xsti.program_id              =   cn_program_id             -- �R���J�����g�E�v���O����ID
           , xsti.program_update_date     =  SYSDATE                    -- �v���O�����X�V��
       WHERE xsti.selling_trns_info_id    =  g_xsti_tab( in_idx ).xsti_id;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appli_name_xxcok
                        , iv_name          =>  cv_msg_cok1_10071
                        , iv_token_name1   =>  cv_tkn_bill_no
                        , iv_token_value1  =>  g_xsti_tab( in_idx ).xsti_slip_no
                        , iv_token_name2   =>  cv_tkn_line_no
                        , iv_token_value2  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_detail_no )
                        , iv_token_name3   =>  cv_tkn_location_code
                        , iv_token_value3  =>  g_xsti_tab( in_idx ).xsti_base_code
                        , iv_token_name4   =>  cv_tkn_customer_code
                        , iv_token_value4  =>  g_xsti_tab( in_idx ).xsti_cust_code
                        , iv_token_name5   =>  cv_tkn_item_code
                        , iv_token_value5  =>  g_xsti_tab( in_idx ).xsti_item_code
                        , iv_token_name6   =>  cv_tkn_delivery_price
                        , iv_token_value6  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which     =>  FND_FILE.OUTPUT
                        , iv_message   =>  lv_out_msg
                        , in_new_line  =>  cn_number_0
                        );
          RAISE update_err_expt;
      END;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    --*** ���b�N�擾�G���[ ***
    WHEN resouce_busy_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appli_name_xxcok
                    , iv_name          =>  cv_msg_cok1_10070
                    , iv_token_name1   =>  cv_tkn_bill_no
                    , iv_token_value1  =>  g_xsti_tab( in_idx ).xsti_slip_no
                    , iv_token_name2   =>  cv_tkn_line_no
                    , iv_token_value2  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_detail_no )
                    , iv_token_name3   =>  cv_tkn_location_code
                    , iv_token_value3  =>  g_xsti_tab( in_idx ).xsti_base_code
                    , iv_token_name4   =>  cv_tkn_customer_code
                    , iv_token_value4  =>  g_xsti_tab( in_idx ).xsti_cust_code
                    , iv_token_name5   =>  cv_tkn_item_code
                    , iv_token_value5  =>  g_xsti_tab( in_idx ).xsti_item_code
                    , iv_token_name6   =>  cv_tkn_delivery_price
                    , iv_token_value6  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** ������ѐU�֏��X�V�G���[ ***
    WHEN update_err_expt THEN
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR START
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR END
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END update_selling_trns_info;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csvfile
   * Description      : ������уf�[�^�i���ѐU�ցj�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_csvfile(
    ov_errbuf   OUT VARCHAR2          -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2          -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
  , in_idx      IN  BINARY_INTEGER )  -- �J�[�\���擾�l�i�[���R�[�h
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'output_csvfile';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)                            DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)                               DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)                            DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode  BOOLEAN                                   DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lv_csvfile  VARCHAR2(3000)                            DEFAULT NULL;  -- CSV�t�@�C��
    lt_tax_amt  xxcok_selling_trns_info.selling_amt%TYPE  DEFAULT NULL;  -- ����Ŋz
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
    ln_sale_qty NUMBER                                    DEFAULT NULL;  -- ���㐔��
-- End   2010/01/07 Ver1.4 Y.Kuboshima
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi ADD START
    ln_item_uom_qty   NUMBER       DEFAULT NULL;
    ln_item_uom_price NUMBER       DEFAULT NULL;
    lv_item_uom_price VARCHAR2(15) DEFAULT NULL;
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi ADD END
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ==============
    -- ����Ŋz�̎Z�o
    -- ==============
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- 0�Œ�Ƃ���悤�C��
--    lt_tax_amt := g_xsti_tab( in_idx ).xsti_selling_amt - g_xsti_tab( in_idx ).xsti_selling_amt_notax;
    lt_tax_amt := cn_number_0;
-- End   2010/01/07 Ver1.4 Y.Kuboshima
    --
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
    -- ==============
    -- ���㐔�ʂ̎Z�o
    -- ==============
    -- ��P�ʐ��ʂ̎擾
    ln_sale_qty := TRUNC( xxcok_common_pkg.get_uom_conversion_qty_f(
                            iv_item_code => g_xsti_tab( in_idx ).xsti_item_code -- �i�ڃR�[�h
                          , iv_uom_code  => g_xsti_tab( in_idx ).xsit_unit_type -- �P��
                          , in_quantity  => g_xsti_tab( in_idx ).xsti_qty       -- ����
                          )
                        , 2
                   )
    ;
-- End   2010/01/07 Ver1.4 Y.Kuboshima
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi ADD START
    -- ��P�ʐ��ʂ̎擾
    ln_item_uom_qty := TRUNC( xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code => g_xsti_tab( in_idx ).xsti_item_code -- �i�ڃR�[�h
                              , iv_uom_code  => g_xsti_tab( in_idx ).xsit_unit_type -- �P��
                              , in_quantity  => 1                                   -- ����
                              )
                            , 2
                       )
    ;
    ln_item_uom_price := ROUND(   g_xsti_tab( in_idx ).xsti_delivery_unit_price -- �[�i�P��
                                / ln_item_uom_qty                               -- ��P�ʐ���
                              , 2
                         )
    ;
    IF( ln_item_uom_price IS NULL ) THEN
      lv_item_uom_price := NULL;
    ELSIF( ln_item_uom_price = TRUNC( ln_item_uom_price ) ) THEN
      lv_item_uom_price := TO_CHAR( ln_item_uom_price );
    ELSE
      lv_item_uom_price := TO_CHAR( ln_item_uom_price, 'FM999999990.99' );
    END IF;
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi ADD END
    --
    -- ================
    -- �t�@�C����������
    -- ================
    lv_csvfile := (
         cv_msg_wq || gv_prof_company_code                                           || cv_msg_wq  -- ��ЃR�[�h
      || cv_msg_c
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_date, 'YYYYMMDD' )                -- ����v��
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_slip_no                              || cv_msg_wq  -- �`�[�ԍ�
      || cv_msg_c
-- Start 2009/03/19 Ver.1.3 M.Hiruta
--      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_detail_no                            || cv_msg_wq  -- �sNo.
                   || g_xsti_tab( in_idx ).xsti_detail_no                                          -- �sNo.
-- End   2009/03/19 Ver.1.3 M.Hiruta
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_cust_code                            || cv_msg_wq  -- �ڋq�R�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_item_code                            || cv_msg_wq  -- ���i�R�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_article_code                         || cv_msg_wq  -- �����R�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_h_c                                  || cv_msg_wq  -- H��C
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_base_code                            || cv_msg_wq  -- ���㋒�_�R�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_selling_emp_code                     || cv_msg_wq  -- ���ю҃R�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_card_selling_type                    || cv_msg_wq  -- �J�[�h����敪
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_base_code                   || cv_msg_wq  -- �[�i���_�R�[�h
      || cv_msg_c
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- ������z(�Ŕ�)��ݒ肷��悤�C��
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_amt )                             -- ������z
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_amt_notax )                       -- ������z
-- End   2010/01/07 Ver1.4 Y.Kuboshima
      || cv_msg_c
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- ��P�ʐ��ʂ�ݒ肷��悤�C��
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_qty )                                     -- ���㐔��
                   || TO_CHAR( ln_sale_qty )                                                       -- ���㐔��
-- End   2010/01/07 Ver1.4 Y.Kuboshima
      || cv_msg_c
                   || TO_CHAR( lt_tax_amt )                                                        -- ����Ŋz
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_slip_type                   || cv_msg_wq  -- ����ԕi�敪
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_selling_type                         || cv_msg_wq  -- ����敪
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_form_type                   || cv_msg_wq  -- �[�i�`�ԋ敪
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_column_no                            || cv_msg_wq  -- �R����No.
      || cv_msg_c
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_checking_date, 'YYYYMMDD' )               -- ������
      || cv_msg_c
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi REPAIR START
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )                     -- �[�i�P��
                   || lv_item_uom_price                                                            -- �[�i�P��
-- 2010/01/08 Ver.1.4 [E_�{�ғ�_00555,E_�{�ғ�_00900] SCS K.Yamaguchi REPAIR END
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_tax_code                             || cv_msg_wq  -- ����ŃR�[�h
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_demand_to_cust_code                  || cv_msg_wq  -- �����ڋq�R�[�h
      || cv_msg_c
-- 2011/04/19 Ver.1.6 [��QE_�{�ғ�_04976] SCS Y.Nishino ADD START
      || cv_msg_wq                                                                   || cv_msg_wq  -- �����`�[�ԍ�
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- �`�[�敪
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- �`�[���ރR�[�h
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- ��K�؂ꎞ��100�~
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- ��K�؂ꎞ��10�~
      || cv_msg_c
                   || cn_number_0                                                                  -- ��P���i�ō��j
      || cv_msg_c
                   || cn_number_0                                                                  -- ������z�i�ō��j
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- ���؋敪
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- ���؎���
      || cv_msg_c
-- 2011/04/19 Ver.1.6 [��QE_�{�ғ�_04976] SCS Y.Nishino ADD END
                   || TO_CHAR( gd_sysdate, 'YYYYMMDDHH24MISS' )                                    -- �V�X�e�����t
    );
--
    -- ============
    -- �t�@�C���o��
    -- ============
    UTL_FILE.PUT_LINE(
      file    =>  g_file_handle
    , buffer  =>  lv_csvfile
    );
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END output_csvfile;
--
--
  /**********************************************************************************
   * Procedure Name   : get_selling_trns_info�i���[�v���j
   * Description      : ������ѐU�֏�񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_selling_trns_info(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_selling_trns_info';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    -- =============
    -- ���[�J����O
    -- =============
    loop_expt     EXCEPTION;  -- ���[�v���̃G���[
    no_data_expt  EXCEPTION;  -- �Ώۃf�[�^���G���[
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    gn_target_cnt := 0;  -- �Ώی���
    gn_normal_cnt := 0;  -- ���팏��
    gn_error_cnt  := 0;  -- �G���[����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
    gn_skip_cnt   := 0;  -- �X�L�b�v����
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
    -- ========================================
    -- ������ѐU�֏��e�[�u������f�[�^�𒊏o
    -- ========================================
    OPEN get_sell_trns_info_cur;
    FETCH get_sell_trns_info_cur BULK COLLECT INTO g_xsti_tab;
    CLOSE get_sell_trns_info_cur;
--
    IF( g_xsti_tab.COUNT = cn_count_0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appli_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00001
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE no_data_expt;
    ELSE
      gn_target_cnt := g_xsti_tab.COUNT;
    END IF;
--
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR START
--    -- ======
--    -- ���[�v
--    -- ======
--    <<get_selling_trns_info_loop>>
--    FOR ln_idx IN g_xsti_tab.FIRST .. g_xsti_tab.LAST LOOP
----
--      -- ==============================
--      -- ������уf�[�^�i���ѐU�ցj�o��
--      -- ==============================
--      output_csvfile(
--        ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
--      , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
--      , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
--      , in_idx      =>  ln_idx      -- �J�[�\���擾�l�i�[���R�[�h
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE loop_expt;
--      END IF;
----
--      -- =====================
--      --�������������̃J�E���g
--      -- =====================
--      gn_normal_cnt := gn_normal_cnt + cn_count_1;
----
--      -- ====================
--      -- ������ѐU�֏��X�V
--      -- ====================
--      update_selling_trns_info(
--        ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
--      , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
--      , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
--      , in_idx      =>  ln_idx      -- �J�[�\���擾�l�i�[���R�[�h
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE loop_expt;
--      END IF;
----
--    END LOOP get_selling_trns_info_loop;
    --==================================================
    -- ���ѐU�֏�񃋁[�v
    --==================================================
    <<get_selling_trns_info_loop>>
    FOR i IN 1 .. g_xsti_tab.COUNT LOOP
      --==================================================
      -- �����ΏۊO�i�ϓ��d�C���j
      --==================================================
      IF( g_xsti_tab( i ).xsti_item_code = gv_prof_elec_change ) THEN
        --==================================================
        -- ������ѐU�֏��X�V
        --==================================================
        update_selling_trns_info(
          ov_errbuf   =>  lv_errbuf               -- �G���[�E���b�Z�[�W
        , ov_retcode  =>  lv_retcode              -- ���^�[���E�R�[�h
        , ov_errmsg   =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        , in_idx      =>  i                       -- �J�[�\���擾�l�i�[���R�[�h
        , iv_if_flag  =>  cv_info_if_flag_off     -- �ΏۊO
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        gn_skip_cnt := gn_skip_cnt + 1;
      --==================================================
      -- �����Ώ�
      --==================================================
      ELSE
        --==================================================
        -- ������уf�[�^�i���ѐU�ցj�o��
        --==================================================
        output_csvfile(
          ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
        , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
        , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
        , in_idx      =>  i           -- �J�[�\���擾�l�i�[���R�[�h
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        --==================================================
        -- ������ѐU�֏��X�V
        --==================================================
        update_selling_trns_info(
          ov_errbuf   =>  lv_errbuf               -- �G���[�E���b�Z�[�W
        , ov_retcode  =>  lv_retcode              -- ���^�[���E�R�[�h
        , ov_errmsg   =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
        , in_idx      =>  i                       -- �J�[�\���擾�l�i�[���R�[�h
        , iv_if_flag  =>  cv_info_if_flag_over    -- ��
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP get_selling_trns_info_loop;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi REPAIR END
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    --*** �Ώۃf�[�^���G���[ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_warn;
    --*** ���[�v���̃G���[ ***
    WHEN loop_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_selling_trns_info;
--
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;  -- ���b�Z�[�W
    lb_exists       BOOLEAN         DEFAULT TRUE;  -- �u�[���l
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_null_prof    VARCHAR2(100)   DEFAULT NULL;  -- �擾���s�����v���t�B�[����
--
    -- ============
    -- ���[�J����O
    -- ============
    prof_err_expt   EXCEPTION;  -- �v���t�@�C���擾�G���[
    file_exist_expt EXCEPTION;  -- �t�@�C�����݃`�F�b�N�G���[
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ==================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�v���o��
    -- ==================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appli_name_xxccp
                  , iv_name         =>  cv_msg_ccp1_90008
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ====================
    -- 2.�V�X�e�����t���擾
    -- ====================
    gd_sysdate := SYSDATE;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
    --==================================================
    -- �Ɩ����t�擾
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appli_name_xxcok
                    , iv_name                 => cv_msg_cok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_out_msg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
--
    -- ====================
    -- 3.�v���t�@�C���̎擾
    -- ====================
    gv_prof_company_code := FND_PROFILE.VALUE( cv_prof_company_code );  -- ��ЃR�[�h
--
    IF( gv_prof_company_code IS NULL ) THEN
      lv_null_prof := cv_prof_company_code;
      RAISE prof_err_expt;
    END IF;
--
    gv_prof_dire_path := FND_PROFILE.VALUE( cv_prof_dire_path );        -- ������уf�[�^�f�B���N�g���p�X
--
    IF( gv_prof_dire_path IS NULL ) THEN
      lv_null_prof := cv_prof_dire_path;
      RAISE prof_err_expt;
    END IF;
--
    gv_prof_file_name := FND_PROFILE.VALUE( cv_prof_file_name );        -- ������уf�[�^�t�@�C����
--
    IF( gv_prof_file_name IS NULL ) THEN
      lv_null_prof := cv_prof_file_name;
      RAISE prof_err_expt;
    END IF;
--
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
    gv_prof_elec_change := FND_PROFILE.VALUE( cv_prof_elec_change );  -- �d�C���i�ϓ��j�i�ڃR�[�h
    IF( gv_prof_elec_change IS NULL ) THEN
      lv_null_prof := cv_prof_elec_change;
      RAISE prof_err_expt;
    END IF;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
    -- =============================================================
    --4.�v���t�@�C���擾��A�f�B���N�g���ƃt�@�C���������b�Z�[�W�o��
    --  ��s���o��
    -- =============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appli_name_xxcok
                  , iv_name          =>  cv_msg_cok1_00067
                  , iv_token_name1   =>  cv_tkn_directory
                  , iv_token_value1  =>  xxcok_common_pkg.get_directory_path_f( gv_prof_dire_path )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appli_name_xxcok
                  , iv_name          =>  cv_msg_cok1_00006
                  , iv_token_name1   =>  cv_tkn_file_name
                  , iv_token_value1  =>  gv_prof_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ========================
    --5�D�t�@�C���̑��݃`�F�b�N
    -- ========================
    UTL_FILE.FGETATTR(
      location     =>  gv_prof_dire_path
    , filename     =>  gv_prof_file_name
    , fexists      =>  lb_exists
    , file_length  =>  ln_file_length
    , block_size   =>  ln_block_size
    );
--
    IF( lb_exists = TRUE ) THEN
      RAISE file_exist_expt;
--
    ELSE
    -- ===================
    --6.�t�@�C���̃I�[�v��
    -- ===================
      g_file_handle := UTL_FILE.FOPEN(
                         location      =>  gv_prof_dire_path
                       , filename      =>  gv_prof_file_name
                       , open_mode     =>  cv_fopen_open_mode
                       , max_linesize  =>  cn_fopen_max_line
                       );
    END IF;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
    --*** �v���t�@�C���擾�G���[ ***
    WHEN prof_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_name_xxcok
                    , iv_name         => cv_msg_cok1_00003
                    , iv_token_name1  => cv_tkn_profile
                    , iv_token_value1 => lv_null_prof
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �t�@�C�����݃`�F�b�N�G���[ ***
    WHEN file_exist_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appli_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00009
                    , iv_token_name1   =>  cv_tkn_file_name
                    , iv_token_value1  =>  gv_prof_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    -- ���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
--
    -- ============
    -- ���[�J���萔
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ========
    -- ��������
    -- ========
    init(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- ������ѐU�֏�񒊏o
    -- ====================
    get_selling_trns_info(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- �o�̓p�����[�^�̐ݒ�
    -- ====================
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
  )
  IS
    -- ================
    -- �Œ胍�[�J���萔
    -- ================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    -- ============
    -- ���[�J���ϐ�
    -- ============
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;  -- ���b�Z�[�W
    lv_message_code  VARCHAR2(5000) DEFAULT NULL;  -- �����I�����b�Z�[�W
    lb_retcode       BOOLEAN        DEFAULT TRUE;  -- ���b�Z�[�W�o�̓t�@���N�V�����߂�l
--
  BEGIN
    -- ============
    -- �ϐ��̏�����
    -- ============
    lv_out_msg := NULL;
--
    -- ==============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ==============================================
    xxccp_common_pkg.put_log_header(
      iv_which    =>  cv_tkn_output
    , ov_retcode  =>  lv_retcode
    , ov_errbuf   =>  lv_errbuf
    , ov_errmsg   =>  lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ==============================================
    submain(
      ov_errbuf   =>  lv_errbuf   -- �G���[�E���b�Z�[�W
    , ov_retcode  =>  lv_retcode  -- ���^�[���E�R�[�h
    , ov_errmsg   =>  lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    -- ==========
    -- �G���[�o��
    -- ==========
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_errmsg
                    , in_new_line  =>  cn_number_1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.LOG
                    , iv_message   =>  lv_errbuf
                    , in_new_line  =>  cn_number_0
                    );
    END IF;
--
    -- ==================
    -- �t�@�C���̃N���[�Y
    -- ==================
    UTL_FILE.FCLOSE(
      file  =>  g_file_handle
    );
--
    -- ====================================
    -- �G���[�����������ꍇ�A����������ݒ�
    -- �G���[���������F1��
    -- ���̑����������F0��
    -- ====================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := cn_count_1;
      gn_target_cnt := cn_count_0;
      gn_normal_cnt := cn_count_0;
    ELSIF( lv_retcode = cv_status_normal ) THEN
      gn_error_cnt  := cn_count_0;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      gn_error_cnt  := cn_count_0;
      gn_target_cnt := cn_count_0;
      gn_normal_cnt := cn_count_0;
    END IF;
--
    -- ===============================
    -- �x����������s�o��
    -- ===============================
    -- ���^�[���R�[�h���x���ł���ꍇ�͋�s���o�͂���
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,NULL
                      ,1
                    );
    END IF;
--
    --�Ώی����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90000
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which         =>  FND_FILE.OUTPUT
                    ,iv_message       =>  lv_out_msg
                    ,in_new_line      =>  cn_number_0
                  );
--
    --���������o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90001
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD START
    -- �X�L�b�v�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appli_name_xxccp
                  , iv_name                  => cv_msg_ccp1_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_out_msg
                  , in_new_line              => 0
                  );
-- 2010/02/18 Ver.1.5 [��QE_�{�ғ�_01600] SCS K.Yamaguchi ADD END
    --�G���[�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90002
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    --�I�����b�Z�[�W
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp1_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp1_90005;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp1_90006;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_name_xxccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK010A01C;
/
