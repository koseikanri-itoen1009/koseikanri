CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A20C(body)
 * Description      : �T���f�[�^�A�b�v���[�h
 * MD.050           : �T���f�[�^�A�b�v���[�h MD050_COK_024_A20
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                                       (A-1)
 *  get_if_data                  IF�f�[�^�擾                                   (A-2)
 *  delete_if_data               IF�f�[�^�폜                                   (A-3)
 *  divide_item                  �A�b�v���[�h�t�@�C�����ڕ���                   (A-4)
 *  error_check                  �G���[�`�F�b�N����                             (A-5)
 *  deduction_date_register      �̔��T���f�[�^�o�^����                         (A-6)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/04/27    1.0   Y.Nakajima       �V�K�쐬
 *  2022/05/20    1.1   SCSK Y.Koh       E_�{�ғ�_18280�Ή�
 *  2022/05/25    1.2   SCSK Y.Koh       E_�{�ғ�_18280�Ή�(�s��Ή�)
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_error_cnt     NUMBER;                    -- �G���[����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
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
  -- ���b�N�G���[
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOK024A20C'; -- �p�b�P�[�W��
--
  cv_csv_delimiter              CONSTANT VARCHAR2(1)  := ',';   -- �J���}
  cv_period                     CONSTANT VARCHAR2(1)  := '.';   -- �s���I�h
  cv_const_y                    CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                    CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
  cv_const_u                    CONSTANT VARCHAR2(1)  := 'U';   -- 'U'
--
  -- ���l
  cn_zero                       CONSTANT NUMBER := 0;   -- 0
  cn_one                        CONSTANT NUMBER := 1;   -- 1
--
  -- �����f�[�^�p
  cn_customer_code              CONSTANT NUMBER := 1;   -- �ڋq�R�[�h
  cn_introduction_chain_code    CONSTANT NUMBER := 2;   -- �`�F�[���X�R�[�h
  cn_corp_code                  CONSTANT NUMBER := 3;   -- ��ƃR�[�h
  cn_base_code                  CONSTANT NUMBER := 4;   -- ���_�R�[�h
  cn_record_date                CONSTANT NUMBER := 5;   -- �v���
  cn_data_type                  CONSTANT NUMBER := 6;   -- �f�[�^���
  cn_item_code                  CONSTANT NUMBER := 7;   -- �i�ڃR�[�h
  cn_deduction_uom_code         CONSTANT NUMBER := 8;   -- �T���P��
  cn_deduction_unit_price       CONSTANT NUMBER := 9;   -- �T���P��
  cn_deduction_quantity         CONSTANT NUMBER := 10;  -- �T������
  cn_deduction_amount           CONSTANT NUMBER := 11;  -- �T���z
-- 2022/05/20 Ver1.1 MOD Start
  cn_compensation               CONSTANT NUMBER := 12;  -- ��U
  cn_margin                     CONSTANT NUMBER := 13;  -- �≮�}�[�W��
  cn_sales_promotion_expenses   CONSTANT NUMBER := 14;  -- �g��
  cn_margin_reduction           CONSTANT NUMBER := 15;  -- �≮�}�[�W�����z
  cn_tax_code                   CONSTANT NUMBER := 16;  -- �ŃR�[�h
  cn_deduction_tax_amount       CONSTANT NUMBER := 17;  -- �T���Ŋz
  cn_remarks                    CONSTANT NUMBER := 18;  -- ���l
  cn_application_no             CONSTANT NUMBER := 19;  -- �\����No
  cn_paid_flag                  CONSTANT NUMBER := 20;  -- �x���σt���O
  cn_c_header                   CONSTANT NUMBER := 20;  -- CSV�t�@�C�����ڐ��i�擾�Ώہj
  cn_c_header_all               CONSTANT NUMBER := 20;  -- CSV�t�@�C�����ڐ��i�S���ځj
--  cn_tax_code                   CONSTANT NUMBER := 12;  -- �ŃR�[�h
--  cn_deduction_tax_amount       CONSTANT NUMBER := 13;  -- �T���Ŋz
--  cn_remarks                    CONSTANT NUMBER := 14;  -- ���l
--  cn_application_no             CONSTANT NUMBER := 15;  -- �\����No
--  cn_c_header                   CONSTANT NUMBER := 15;  -- CSV�t�@�C�����ڐ��i�擾�Ώہj
--  cn_c_header_all               CONSTANT NUMBER := 15;  -- CSV�t�@�C�����ڐ��i�S���ځj
-- 2022/05/20 Ver1.1 MOD End
--
  cv_condition_type_ws_fix      CONSTANT VARCHAR2(3)  :=  '030';  -- �T���^�C�v(�≮�����i��z�j)
  cv_condition_type_ws_add      CONSTANT VARCHAR2(3)  :=  '040';  -- �T���^�C�v(�≮�����i�ǉ��j)
  cv_condition_type_fix_con     CONSTANT VARCHAR2(3)  :=  '070';  -- �T���^�C�v(��z�T��)
--
  cv_uom_book                   CONSTANT VARCHAR2(3)  :=  '�{';   -- �P�ʁi�{�j
  cv_uom_cs                     CONSTANT VARCHAR2(2)  :=  'CS';   -- �P�ʁiCS�j
  cv_uom_bl                     CONSTANT VARCHAR2(2)  :=  'BL';   -- �P�ʁiBL�j
--
  cv_month_jan                  CONSTANT VARCHAR2(2)  :=  '01';   -- 1��
  cv_month_feb                  CONSTANT VARCHAR2(2)  :=  '02';   -- 2��
  cv_month_mar                  CONSTANT VARCHAR2(2)  :=  '03';   -- 3��
  cv_month_apr                  CONSTANT VARCHAR2(2)  :=  '04';   -- 4��
--
  -- �o�̓^�C�v
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';        -- �o��(���[�U���b�Z�[�W�p�o�͐�)
--
  -- �����}�X�N
  cv_date_format        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';    -- ���t����
  cv_date_year          CONSTANT VARCHAR2(4)  := 'YYYY';          -- �N
  cv_date_month         CONSTANT VARCHAR2(2)  := 'MM';            -- ��
--
  -- �A�v���P�[�V�����Z�k��
  cv_msg_kbn_cok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- �A�h�I���F�ʊJ��
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)  := 'XXCOS'; -- �A�h�I���F�̔�
--
--
  -- �Q�ƃ^�C�v
  cv_type_upload_obj      CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';      -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_type_deduction_data  CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- �T���f�[�^���
  cv_type_chain_code      CONSTANT VARCHAR2(30) := 'XXCMM_CHAIN_CODE';            -- �`�F�[���R�[�h
  cv_type_business_type   CONSTANT VARCHAR2(30) := 'XX03_BUSINESS_TYPE';          -- ��ƃR�[�h
  cv_type_departmen       CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT';             -- ���_�R�[�h
--
  -- ����R�[�h
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ���b�Z�[�W��
  cv_msg_ccp_10534      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10534';  -- �x���������b�Z�[�W
--
  cv_msg_cok_00016      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00016';  -- �t�@�C��ID�o�͗p���b�Z�[�W
  cv_msg_cok_00017      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00017';  -- �t�@�C���p�^�[���o�͗p���b�Z�[�W
  cv_msg_cok_00028      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- �Ɩ����t�擾�G���[
  cv_msg_cok_00006      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00006';  -- �t�@�C�����o�͗p���b�Z�[�W
  cv_msg_cok_00061      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00061';  -- �t�@�C���A�b�v���[�hI/F�e�[�u�����b�N�擾�G���[���b�Z�[�W
  cv_msg_cok_00106      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00106';  -- �t�@�C���A�b�v���[�h���̏o�͗p���b�Z�[�W
  cv_msg_coi_00062      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00062';  -- �t�@�C���A�b�v���[�hIF�폜�G���[
  cv_msg_cok_00041      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00041';  -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
  cv_msg_cok_10634      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10634';  -- �t�@�C�����R�[�h�s��v�G���[���b�Z�[�W
  cv_msg_cok_10618      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10618';  -- �}�X�^���o�^�G���[
  cv_msg_cok_10699      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10699';  -- ���͕K�{�G���[
  cv_msg_cok_10621      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10621';  -- ���t���ڃG���[
  cv_msg_cok_10620      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10620';  -- �������ڌ^�G���[
  cv_msg_cok_10619      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10619';  -- �������ڌ^�G���[
  cv_msg_cok_10667      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10667';  -- �T���P�ʕs���G���[1
  cv_msg_cok_10668      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10668';  -- �T���P�ʕs���G���[2
  cv_msg_cok_10676      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10676';  -- �T���ԍ��V�[�P���X�G���[
  cv_msg_cok_00039      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00039';  -- CSV�t�@�C���f�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_cos_11294      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11294';  -- CSV�t�@�C�����擾�G���[
  cv_msg_cok_10706      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10706';  -- �v����������G���[
--
  -- �g�[�N����
  cv_file_id_tok        CONSTANT VARCHAR2(20) := 'FILE_ID';           -- �t�@�C��ID
  cv_format_tok         CONSTANT VARCHAR2(20) := 'FORMAT';            -- �t�H�[�}�b�g
  cv_file_name_tok      CONSTANT VARCHAR2(20) := 'FILE_NAME';         -- �t�@�C����
  cv_upload_object_tok  CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';     -- �A�b�v���[�h�t�@�C����
  cv_data_tok           CONSTANT VARCHAR2(20) := 'DATA';              -- �f�[�^
  cv_col_name_tok       CONSTANT VARCHAR2(20) := 'COLUMN_NAME';       -- ���ږ�
  cv_col_value_tok      CONSTANT VARCHAR2(20) := 'COLUMN_VALUE';      -- ���ڒl
  cv_line_no_tok        CONSTANT VARCHAR2(20) := 'LINE_NO';           -- �s�ԍ�
  cv_deduction_type_tok CONSTANT VARCHAR2(20) := 'DEDUCTION_TYPE';    -- �T���^�C�v
  cv_key_data_tok       CONSTANT VARCHAR2(20) := 'KEY_DATA';          -- ����ł���L�[���e���R�����g�����ăZ�b�g���܂��B
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �z��ޔ�p�̔��T�����[�N�e�[�u����`
  TYPE  gr_sales_deduction_work IS RECORD(
      customer_code_from        xxcok_sales_deduction.customer_code_from%TYPE             -- �ڋq�R�[�h
     ,introduction_chain_code   xxcok_sales_deduction.deduction_chain_code%TYPE           -- �`�F�[���X�R�[�h
     ,corp_code                 xxcok_sales_deduction.corp_code%TYPE                      -- ��ƃR�[�h
     ,base_code                 xxcok_sales_deduction.base_code_from%TYPE                 -- ���_�R�[�h
     ,record_date               xxcok_sales_deduction.record_date%TYPE                    -- �v���
     ,data_type                 xxcok_sales_deduction.data_type%TYPE                      -- �f�[�^���
     ,item_code                 xxcok_sales_deduction.item_code%TYPE                      -- �i�ڃR�[�h
     ,deduction_uom_code        xxcok_sales_deduction.deduction_uom_code%TYPE             -- �T���P��
     ,deduction_unit_price      xxcok_sales_deduction.deduction_unit_price%TYPE           -- �T���P��
     ,deduction_quantity        xxcok_sales_deduction.deduction_quantity%TYPE             -- �T������
     ,deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- �T���z
     ,tax_code                  xxcok_sales_deduction.tax_code%TYPE                       -- �ŃR�[�h
     ,deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- �T���Ŋz
     ,remarks                   xxcok_sales_deduction.remarks%TYPE                        -- ���l
     ,application_no            xxcok_sales_deduction.application_no%TYPE                 -- �\����No.
     ,tax_rate                  xxcok_sales_deduction.tax_rate%TYPE                       -- �ŗ�
-- 2022/05/20 Ver1.1 ADD Start
     ,compensation              xxcok_sales_deduction.compensation%TYPE                   -- ��U
     ,margin                    xxcok_sales_deduction.margin%TYPE                         -- �≮�}�[�W��
     ,sales_promotion_expenses  xxcok_sales_deduction.sales_promotion_expenses%TYPE       -- �g��
     ,margin_reduction          xxcok_sales_deduction.margin_reduction%TYPE               -- �≮�}�[�W�����z
     ,paid_flag                 VARCHAR2(1)                                               -- �x���σt���O
-- 2022/05/20 Ver1.1 ADD End
  );
--
  -- ���[�N�e�[�u���^��`
  TYPE g_sales_deduction_work_ttype  IS TABLE OF gr_sales_deduction_work INDEX BY BINARY_INTEGER;
    gt_sales_deduction_work_tbl  g_sales_deduction_work_ttype;
--
  -- �������ڕ�����f�[�^�i�[�p
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1�����z��
  g_if_data_tab             g_var_data_ttype;                                     -- �����p�ϐ�
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;                    -- CSV�f�[�^�i1�s�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_deduction_type     VARCHAR(3);       -- �T���^�C�v
  gv_sale_base_code     VARCHAR2(10);
  gv_tax_rate           VARCHAR2(10);
  gd_process_date       DATE;             -- �Ɩ����t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER     --   �t�@�C��ID
   ,iv_file_format IN  VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_out_msg              VARCHAR2(1000); -- ���b�Z�[�W
    lb_retcode              BOOLEAN;        -- ���茋��
    lt_file_name            xxccp_mrp_file_ul_interface.file_name%TYPE;
    lt_file_upload_name     fnd_lookup_values.meaning%TYPE;
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
    lt_file_name        :=  NULL;               -- �t�@�C����
    lt_file_upload_name :=  NULL;               -- �t�@�C���A�b�v���[�h����
    lb_retcode          :=  false;
--
    -- 1.�t�@�C��ID���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_00016
                    , iv_token_name1  => cv_file_id_tok
                    , iv_token_value1 => in_file_id
                  );
    -- 1.�t�@�C��ID���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_zero         -- ���s
                  );
    -- 1.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_00017
                    , iv_token_name1  => cv_format_tok
                    , iv_token_value1 => iv_file_format
                  );
    -- 1.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_one          -- ���s
                  );
--
    -- 2.�Ɩ����t�擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�ł��Ȃ��ꍇ
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00028 -- �Ɩ����t�擾�G���[
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.�t�@�C���A�b�v���[�h���́E�t�@�C�����̎擾�ƃ��b�N
    BEGIN
      SELECT  xfu.file_name   AS file_name        -- �t�@�C����
             ,flv.meaning     AS file_upload_name -- �t�@�C���A�b�v���[�h����
      INTO    lt_file_name                        -- �t�@�C����
             ,lt_file_upload_name                 -- �t�@�C���A�b�v���[�h����
      FROM    xxccp_mrp_file_ul_interface  xfu    -- �t�@�C���A�b�v���[�hIF
             ,fnd_lookup_values            flv    -- �N�C�b�N�R�[�h
      WHERE   xfu.file_id = in_file_id            -- �t�@�C��ID
      AND     flv.lookup_type  = cv_type_upload_obj
      AND     flv.lookup_code  = xfu.file_content_type
      AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                  AND NVL(flv.end_date_active, gd_process_date)
      AND     flv.enabled_flag = cv_const_y
      AND     flv.language     = ct_lang
      FOR UPDATE OF xfu.file_name
      ;
    EXCEPTION
      -- ���b�N���擾�ł��Ȃ��ꍇ
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cok
                       ,iv_name         =>  cv_msg_cok_00061  -- �t�@�C���A�b�v���[�hI/F�e�[�u�����b�N�擾�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_file_id_tok    -- �t�@�C��ID
                       ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- �t�@�C���A�b�v���[�h���́E�t�@�C�������擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_11294  -- �t�@�C���A�b�v���[�h���̎擾�G���[���b�Z�[�W
                       ,iv_token_name1  =>  cv_key_data_tok
                       ,iv_token_value1 =>  iv_file_format    -- �t�H�[�}�b�g�p�^�[��
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 4.�擾�����t�@�C�����A�t�@�C���A�b�v���[�h���̂��o��
    -- �t�@�C�������o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
    -- �t�@�C�������o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- �t�@�C�����o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- �t�@�C����
                  )
    );
--
    -- �t�@�C���A�b�v���[�h���̂��o�́i���O�j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- �t�@�C���A�b�v���[�h����
                  )
    );
    -- �t�@�C���A�b�v���[�h���̂��o�́i�o�́j
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- �t�@�C���A�b�v���[�h���̏o�̓��b�Z�[�W
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- �t�@�C���A�b�v���[�h����
                  )
    );
--
    -- ��s���o�́i���O�j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- ��s���o�́i�o�́j
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
    /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER     --   �t�@�C��ID
   ,iv_file_format IN  VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf      OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;        -- �t�@�C����
    lt_file_upload_name fnd_lookup_values.description%TYPE;                -- �t�@�C���A�b�v���[�h����
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
    -- �t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- �t�@�C��ID
     ,ov_file_data => gt_file_line_data_tab -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���ʊ֐��G���[�̏ꍇ
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00041  -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����ݒ�
    gn_target_cnt := gt_file_line_data_tab.COUNT -1;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IF�f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER     --   �t�@�C��ID
   ,ov_errbuf        OUT VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- �v���O������
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
    -- �t�@�C���A�b�v���[�hIF�f�[�^�폜
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- �t�@�C���A�b�v���[�hIF
      WHERE xfu.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- �폜�Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cok
                       ,iv_name         =>  cv_msg_coi_00062  -- �t�@�C���A�b�v���[�hIF�폜�G���[
                       ,iv_token_name1  =>  cv_file_id_tok
                       ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- �f�[�^�����o���݂̂̏ꍇ�G���[
    IF gn_target_cnt = cn_zero THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00039  -- CSV�t�@�C���f�[�^�Ȃ��G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- �t�@�C��ID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �A�b�v���[�h�t�@�C�����ڕ���(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt   IN  NUMBER    --   IF���[�v�J�E���^
   ,ov_errbuf             OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- �v���O������
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
    lv_rec_data         VARCHAR2(32765);  -- ���R�[�h�f�[�^
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
    -- ���[�J���ϐ�������--
    lv_rec_data  := NULL; -- ���R�[�h�f�[�^
--
    -- ���ڐ��`�F�b�N
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- ���ڐ��s��v�̏ꍇ
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_10634  -- �t�@�C�����R�[�h���ڐ��s��v�G���[���b�Z�[�W
                     ,iv_token_name1  =>  cv_line_no_tok
                     ,iv_token_value1 =>  (in_file_if_loop_cnt - 1)
                     ,iv_token_name2  =>  cv_data_tok
                     ,iv_token_value2 =>  lv_rec_data
                   );
      RAISE global_process_expt;
    END IF;
--
    -- �������[�v
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    =>  cv_csv_delimiter
                                   ,in_part_num =>  i
                                  );
    END LOOP data_split_loop;
--
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
  * Procedure Name   : error_check
  * Description      : �G���[�`�F�b�N����(A-5)
  ***********************************************************************************/
  PROCEDURE error_check(
    in_file_if_loop_cnt   IN  NUMBER    -- IF���[�v�J�E���^
   ,ov_errbuf             OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_check'; -- �v���O������
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
    cv_customer_code              CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10635';  -- �ڋq�R�[�h
    cv_introduction_chain_code    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10636';  -- �`�F�[���X�R�[�h
    cv_corp_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10637';  -- ��ƃR�[�h
    cv_base_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10638';  -- ���_�R�[�h
    cv_record_date                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10639';  -- �v���
    cv_data_type                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10640';  -- �f�[�^���
    cv_item_code                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10641';  -- �i�ڃR�[�h
    cv_deduction_uom_code         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10642';  -- �T���P��
    cv_deduction_unit_price       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10643';  -- �T���P��
    cv_deduction_quantity         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10644';  -- �T������
    cv_deduction_amount           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10645';  -- �T���z
    cv_tax_code                   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10646';  -- �ŃR�[�h
    cv_deduction_tax_amount       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10647';  -- �T���Ŋz
    cv_cust_chain_corp            CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10648';  -- �ڋq�A�`�F�[���X�A��Ƃ����ꂩ
-- 2022/05/20 Ver1.1 ADD Start
    cv_compensation               CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10836';  -- ��U
    cv_margin                     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10837';  -- �≮�}�[�W��
    cv_sales_promotion_expenses   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10838';  -- �g��
    cv_margin_reduction           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10839';  -- �≮�}�[�W�����z
-- 2022/05/20 Ver1.1 ADD End
--
    -- *** ���[�J���ϐ� ***
    lv_token_name              VARCHAR(1000);
    lv_dummy                   VARCHAR(30);                 -- �_�~�[
    ld_record_date             DATE;                        -- �v���
    ln_uom_conversion          NUMBER;
    ln_loop_cnt                NUMBER;                      -- ���[�N�e�[�u���o�^�����p
    lv_data_type               VARCHAR2(10);                -- �f�[�^���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    lv_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --========================================
    -- 1.�f�[�^��ރ`�F�b�N
    --========================================
    --
    BEGIN
    --
      SELECT flv.attribute2       AS deduction_type         -- �T���^�C�v
      INTO   gv_deduction_type                              -- �T���^�C�v
      FROM   fnd_lookup_values    flv                       -- �f�[�^���
      WHERE 1 = 1
      AND flv.lookup_type       = cv_type_deduction_data
      AND flv.meaning           = g_if_data_tab(cn_data_type)
      AND flv.language          = ct_lang
      AND flv.enabled_flag      = cv_const_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode    := cv_status_warn;
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10618     -- �}�X�^���o�^�G���[
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => cv_data_type
                         , iv_token_name3  => cv_col_value_tok
                         , iv_token_value3 => g_if_data_tab(cn_data_type)
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
    END;
--
    --========================================
    -- 2.���͕K�{�E���͕s�`�F�b�N
    --========================================
--
    -- 2.1�A�b�v���[�h���ꂽ�f�[�^��NULL�̏ꍇ
--
        -- ���_�R�[�h�`�F�b�N
        IF g_if_data_tab(cn_base_code) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_base_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
    --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
    --
        -- �v����`�F�b�N
        IF g_if_data_tab(cn_record_date) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_record_date;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- �f�[�^��ރ`�F�b�N
        IF g_if_data_tab(cn_data_type) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_data_type;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- �T���z�`�F�b�N
        IF g_if_data_tab(cn_deduction_amount) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_amount;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- �ŃR�[�h�`�F�b�N
        IF g_if_data_tab(cn_tax_code) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_tax_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
        -- �T���Ŋz�`�F�b�N
        IF g_if_data_tab(cn_deduction_tax_amount) IS NULL THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_tax_amount;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok       -- ��L����
                       , iv_token_value2 => lv_token_name
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
    --
        END IF;
    --
    -- 2.3 ���͏d���`�F�b�N
--
    -- �ڋq�R�[�h�A�`�F�[���X�R�[�h�A��ƃR�[�h�̂����ꂩ�Q�ȏオ���͂���Ă���������́A����������͂���Ă��Ȃ��ꍇ
    IF    (g_if_data_tab(cn_customer_code) IS NOT NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS NOT NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS NOT NULL) THEN
      NULL;
    ELSIF (g_if_data_tab(cn_customer_code) IS     NULL AND g_if_data_tab(cn_introduction_chain_code) IS     NULL AND g_if_data_tab(cn_corp_code) IS     NULL) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_cust_chain_corp;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok       -- �����ꂩ�ЂƂ�
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
--
    ELSE
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_cust_chain_corp;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10699      -- ���͕K�{�G���[
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok       -- �����ꂩ�ЂƂ�
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
--
    END IF;
--
    --========================================
    -- 3.���ڏ����`�F�b�N
    --========================================
--
    -- 3.1 �v��������`�F�b�N
--
    BEGIN
      ld_record_date := TO_DATE(g_if_data_tab(cn_record_date), cv_date_format);
    EXCEPTION
      WHEN OTHERS THEN
        lv_retcode    := cv_status_warn;
        lv_token_name := cv_record_date;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cok
                     , iv_name         => cv_msg_cok_10621
                     , iv_token_name1  => cv_line_no_tok
                     , iv_token_value1 => in_file_if_loop_cnt
                     , iv_token_name2  => cv_col_name_tok
                     , iv_token_value2 => lv_token_name
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
    END;
--
    -- 3.2 ���������`�F�b�N
--
    -- �T���P�������͂���Ă���ꍇ�����`�F�b�N
    IF g_if_data_tab(cn_deduction_unit_price) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_deduction_unit_price),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_deduction_unit_price),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
-- 2022/05/20 Ver1.1 MOD Start
        IF ((LENGTH(g_if_data_tab(cn_deduction_unit_price)) - INSTR(g_if_data_tab(cn_deduction_unit_price),cv_period)) > 2) THEN
--        IF ((LENGTH(g_if_data_tab(cn_deduction_unit_price)) - INSTR(g_if_data_tab(cn_deduction_unit_price),cv_period)) >= 2) THEN
-- 2022/05/20 Ver1.1 MOD End
            lv_retcode    := cv_status_warn;
            lv_token_name := cv_deduction_unit_price;
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10620
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => lv_token_name
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        END IF;
      ELSE
        NULL;
      END IF;
    END IF;
--
    -- �T�����ʂ����͂���Ă���ꍇ�����`�F�b�N
    IF g_if_data_tab(cn_deduction_quantity) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_deduction_quantity),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_deduction_quantity),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
-- 2022/05/20 Ver1.1 MOD Start
        IF ((LENGTH(g_if_data_tab(cn_deduction_quantity)) - INSTR(g_if_data_tab(cn_deduction_quantity),cv_period)) > 2) THEN
--        IF ((LENGTH(g_if_data_tab(cn_deduction_quantity)) - INSTR(g_if_data_tab(cn_deduction_quantity),cv_period)) >= 2) THEN
-- 2022/05/20 Ver1.1 MOD End
            lv_retcode    := cv_status_warn;
            lv_token_name := cv_deduction_quantity;
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10620
                         , iv_token_name1  => cv_line_no_tok
                         , iv_token_value1 => in_file_if_loop_cnt
                         , iv_token_name2  => cv_col_name_tok
                         , iv_token_value2 => lv_token_name
                         );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        END IF;
      ELSE
        NULL;
      END IF;
    END IF;
--
    -- 3.3 �����`�F�b�N
--
    -- �T���z�����`�F�b�N
    IF (INSTR(g_if_data_tab(cn_deduction_amount),cv_period) > 0) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_deduction_amount;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10619
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
    END IF;
--
-- 2022/05/20 Ver1.1 ADD Start
    -- ��U�����͂���Ă���ꍇ�̏����`�F�b�N
    IF g_if_data_tab(cn_compensation) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_compensation),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_compensation),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_compensation)) - INSTR(g_if_data_tab(cn_compensation),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_compensation
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- �≮�}�[�W�������͂���Ă���ꍇ�̏����`�F�b�N
    IF g_if_data_tab(cn_margin) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_margin),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_margin),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_margin)) - INSTR(g_if_data_tab(cn_margin),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_margin
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- �g�������͂���Ă���ꍇ�̏����`�F�b�N
    IF g_if_data_tab(cn_sales_promotion_expenses) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_sales_promotion_expenses),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_sales_promotion_expenses),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_sales_promotion_expenses)) - INSTR(g_if_data_tab(cn_sales_promotion_expenses),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_sales_promotion_expenses
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
    -- �≮�}�[�W�����z�����͂���Ă���ꍇ�̏����`�F�b�N
    IF g_if_data_tab(cn_margin_reduction) IS NOT NULL THEN
      -- ����2���ȏ�̏ꍇ�G���[
-- 2022/05/25 Ver1.2 MOD Start
      IF MOD(g_if_data_tab(cn_margin_reduction),1) != 0 THEN
--      IF MOD(g_if_data_tab(cn_margin_reduction),1) >0 THEN
-- 2022/05/25 Ver1.2 MOD End
        IF ((LENGTH(g_if_data_tab(cn_margin_reduction)) - INSTR(g_if_data_tab(cn_margin_reduction),cv_period)) > 2) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10620
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => cv_margin_reduction
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
      END IF;
    END IF;
--
-- 2022/05/20 Ver1.1 ADD End
    -- �T���Ŋz�����`�F�b�N
    IF (INSTR(g_if_data_tab(cn_deduction_tax_amount),cv_period) > 0) THEN
      lv_retcode    := cv_status_warn;
      lv_token_name := cv_deduction_tax_amount;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10619
                   , iv_token_name1  => cv_line_no_tok
                   , iv_token_value1 => in_file_if_loop_cnt
                   , iv_token_name2  => cv_col_name_tok
                   , iv_token_value2 => lv_token_name
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );

--
    END IF;
--
    --========================================
    -- 4.�}�X�^�`�F�b�N
    --========================================
--  
    -- �ڋq�R�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_customer_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  xca.sale_base_code      AS sale_base_code
        INTO    gv_sale_base_code
        FROM    xxcmm_cust_accounts     xca
        WHERE   xca.customer_code    =  g_if_data_tab(cn_customer_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_customer_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_customer_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- �`�F�[���R�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_introduction_chain_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  flv.lookup_code       AS chain_code
        INTO    lv_dummy
        FROM    fnd_lookup_values     flv
        WHERE   1 = 1
        AND     flv.lookup_type    =  cv_type_chain_code
        AND     flv.language       =  ct_lang
        AND     flv.lookup_code    =  g_if_data_tab(cn_introduction_chain_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_introduction_chain_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_introduction_chain_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- ��ƃR�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_corp_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  ffv.flex_value      AS corp_code
        INTO    lv_dummy
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   1 = 1
        AND     ffvs.flex_value_set_name    =  cv_type_business_type
        AND     ffvs.flex_value_set_id      =  ffv.flex_value_set_id
        AND     ffv.flex_value              =  g_if_data_tab(cn_corp_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_corp_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_corp_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- ���_�R�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_base_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  ffv.flex_value      AS base_code
        INTO    lv_dummy
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   1 = 1
        AND     ffvs.flex_value_set_name    =  cv_type_departmen
        AND     ffvs.flex_value_set_id      =  ffv.flex_value_set_id
        AND     ffv.flex_value              =  g_if_data_tab(cn_base_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_base_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_base_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- �i�ڃR�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_item_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  xsib.item_code         AS item_code
        INTO    lv_dummy
        FROM    xxcmm_system_items_b   xsib
        WHERE   1 = 1
        AND     xsib.item_code         =  g_if_data_tab(cn_item_code)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_item_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_item_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    -- �T���P�ʂ��w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_deduction_uom_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  muomt.uom_code            AS uom_code
        INTO    lv_dummy
        FROM    mtl_units_of_measure_tl   muomt
        WHERE   1 = 1
        AND     muomt.uom_code  =  g_if_data_tab(cn_deduction_uom_code)
        AND     muomt.language  =  ct_lang
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_deduction_uom_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_deduction_uom_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;

--
    END IF;
--
    -- �ŃR�[�h���w�肳��Ă���A�}�X�^�ɑ��݂��Ȃ��ꍇ�G���[
    IF g_if_data_tab(cn_tax_code) IS NOT NULL THEN
--
      BEGIN
        SELECT  avtab.tax_rate            AS tax_rate
        INTO    gv_tax_rate
        FROM    ar_vat_tax_all_b          avtab
        WHERE   1 = 1
        AND     avtab.set_of_books_id                                         = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
        AND     avtab.tax_code                                                = g_if_data_tab(cn_tax_code)
        AND     TO_DATE(g_if_data_tab(cn_record_date), cv_date_format)  BETWEEN avtab.start_date
                                                                            AND NVL(avtab.end_date,TO_DATE(g_if_data_tab(cn_record_date), cv_date_format))
        AND     avtab.org_id                                                  = FND_PROFILE.VALUE( 'ORG_ID' )
        AND     avtab.validate_flag                                           = cv_const_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_retcode    := cv_status_warn;
          lv_token_name := cv_tax_code;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10618
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_col_name_tok
                       , iv_token_value2 => lv_token_name
                       , iv_token_name3  => cv_col_value_tok
                       , iv_token_value3 => g_if_data_tab(cn_tax_code)
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END;
--
    END IF;
--
    --========================================
    -- 5.���ڊ֘A�`�F�b�N
    --========================================
--
    -- �v���_�Ɩ��������t�`�F�b�N
    IF TO_DATE(g_if_data_tab(cn_record_date), cv_date_format) > gd_process_date THEN
      lv_retcode := cv_status_warn;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cok
                    , iv_name         => cv_msg_cok_10706
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    -- �T���P��NULL�`�F�b�N
    IF g_if_data_tab(cn_deduction_uom_code) IS NOT NULL THEN
--
    -- �T���^�C�v_�T���P�ʃ`�F�b�N
      -- �T���^�C�v��030�܂���040�̏ꍇ
      IF (gv_deduction_type = cv_condition_type_ws_fix OR gv_deduction_type = cv_condition_type_ws_add) THEN
        -- �P�ʂ��u�{�v�uCS�v�uBL�v�ȊO�̏ꍇ�G���[
        IF (g_if_data_tab(cn_deduction_uom_code)  NOT IN (cv_uom_book, cv_uom_cs, cv_uom_bl)) THEN
          lv_retcode    := cv_status_warn;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10667
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       , iv_token_name2  => cv_deduction_type_tok
                       , iv_token_value2 => gv_deduction_type
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
        END IF;
      END IF;
--
    -- �i�ڃR�[�h_�T���P�ʃ`�F�b�N
    IF g_if_data_tab(cn_item_code) IS NOT NULL THEN
      -- ��P�ʊ��Z���擾�֐��Ăяo��
      ln_uom_conversion := xxcok_common_pkg.get_uom_conversion_qty_f(
                              iv_item_code  => g_if_data_tab(cn_item_code)
                            , iv_uom_code   => g_if_data_tab(cn_deduction_uom_code)
                            , in_quantity   => cn_zero
                            );
      -- ��P�ʊ��Z�㐔�ʂ�NULL�̏ꍇ
      IF ln_uom_conversion IS NULL THEN
        lv_retcode    := cv_status_warn;
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10668
                       , iv_token_name1  => cv_line_no_tok
                       , iv_token_value1 => in_file_if_loop_cnt
                       );
--
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
      END IF;
    END IF;
--
    END IF;
--
    -- �x�����P���ł��������ꍇ
    IF lv_retcode = cv_status_warn THEN
      ov_retcode    := lv_retcode;
      gn_warn_cnt   := gn_warn_cnt + 1;
    END IF;
--
    ln_loop_cnt := in_file_if_loop_cnt - 1;
--
    -- �f�[�^��ޕϊ�
    SELECT flv.lookup_code
    INTO   lv_data_type
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = cv_type_deduction_data
    AND    flv.meaning      = g_if_data_tab(6)
    AND    flv.language     = ct_lang
    AND    flv.enabled_flag = cv_const_y
    ;
--
    -- ���[�N�e�[�u���ɕ��������l��ޔ�
    gt_sales_deduction_work_tbl(ln_loop_cnt).customer_code_from      := g_if_data_tab(1);   -- �ڋq�R�[�h
    gt_sales_deduction_work_tbl(ln_loop_cnt).introduction_chain_code := g_if_data_tab(2);   -- �`�F�[���X�R�[�h
    gt_sales_deduction_work_tbl(ln_loop_cnt).corp_code               := g_if_data_tab(3);   -- ��ƃR�[�h
    gt_sales_deduction_work_tbl(ln_loop_cnt).base_code               := g_if_data_tab(4);   -- �v�㋒�_
    gt_sales_deduction_work_tbl(ln_loop_cnt).record_date             := TO_DATE(g_if_data_tab(5),cv_date_format);   -- �v���
    gt_sales_deduction_work_tbl(ln_loop_cnt).data_type               := lv_data_type;       -- �f�[�^���
    gt_sales_deduction_work_tbl(ln_loop_cnt).item_code               := g_if_data_tab(7);   -- �i�ڃR�[�h
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_uom_code      := g_if_data_tab(8);   -- �T���P��
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_unit_price    := g_if_data_tab(9);   -- �T���P��
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_quantity      := g_if_data_tab(10);  -- �T������
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_amount        := g_if_data_tab(11);  -- �T���z
-- 2022/05/20 Ver1.1 MOD Start
    gt_sales_deduction_work_tbl(ln_loop_cnt).compensation             := g_if_data_tab(cn_compensation);              -- ��U
    gt_sales_deduction_work_tbl(ln_loop_cnt).margin                   := g_if_data_tab(cn_margin);                    -- �≮�}�[�W��
    gt_sales_deduction_work_tbl(ln_loop_cnt).sales_promotion_expenses := g_if_data_tab(cn_sales_promotion_expenses);  -- �g��
    gt_sales_deduction_work_tbl(ln_loop_cnt).margin_reduction         := g_if_data_tab(cn_margin_reduction);          -- �≮�}�[�W�����z
    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_code                 := g_if_data_tab(cn_tax_code);                  -- �ŃR�[�h
    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_tax_amount     := g_if_data_tab(cn_deduction_tax_amount);      -- �T���Ŋz
    gt_sales_deduction_work_tbl(ln_loop_cnt).remarks                  := g_if_data_tab(cn_remarks);                   -- ���l
    gt_sales_deduction_work_tbl(ln_loop_cnt).application_no           := g_if_data_tab(cn_application_no);            -- �\����No.
    gt_sales_deduction_work_tbl(ln_loop_cnt).paid_flag                := g_if_data_tab(cn_paid_flag);                 -- �x���σt���O
--    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_code                := g_if_data_tab(12);  -- �ŃR�[�h
--    gt_sales_deduction_work_tbl(ln_loop_cnt).deduction_tax_amount    := g_if_data_tab(13);  -- �T���Ŋz
--    gt_sales_deduction_work_tbl(ln_loop_cnt).remarks                 := g_if_data_tab(14);  -- ���l
--    gt_sales_deduction_work_tbl(ln_loop_cnt).application_no          := g_if_data_tab(15);  -- �\����No.
-- 2022/05/20 Ver1.1 MOD End
    gt_sales_deduction_work_tbl(ln_loop_cnt).tax_rate                := gv_tax_rate;        -- �ŗ�
--
  -- ���������J�E���g
  IF lv_retcode = cv_status_normal THEN
    ov_retcode    := lv_retcode;
    gn_normal_cnt := gn_normal_cnt + 1;
  END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END error_check;
--
  /**********************************************************************************
  * Procedure Name   : deduction_date_register
  * Description      : �̔��T���f�[�^�o�^����(A-6)
  ***********************************************************************************/
  PROCEDURE deduction_date_register(
    ov_errbuf             OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'deduction_date_register'; -- �v���O������
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
    lt_condition_no               xxcok_condition_header.condition_no%TYPE;
--
    -- �T���ԍ������p
    lt_sql_str                    VARCHAR2(100);
    lv_process_year               VARCHAR2(4);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --  �N�x���擾
    lv_process_year   :=  CASE  WHEN  TO_CHAR( gd_process_date, cv_date_month ) IN( cv_month_jan, cv_month_feb, cv_month_mar, cv_month_apr )
                                  THEN  TO_CHAR( TO_NUMBER( TO_CHAR( gd_process_date, cv_date_year ) ) - 1 )
                                  ELSE  TO_CHAR( gd_process_date, cv_date_year )
                          END;
--
    FOR i IN 1..gt_sales_deduction_work_tbl.COUNT LOOP
--
      --  �T���ԍ������i�N�x���ƂɈقȂ�V�[�P���X���g�p����j
      DECLARE
        lt_sql_str      VARCHAR2(100);
        --
        TYPE  cur_type  IS  REF CURSOR;
        condition_no_cur  cur_type;
        --
        TYPE  rec_type  IS RECORD(
          condition_no        xxcok_condition_header.condition_no%TYPE
        );
        condition_no_rec  rec_type;
      BEGIN
        lt_sql_str  :=    'SELECT XXCOK.XXCOK_UP_CONDITION_NO_' || lv_process_year || '_S01.NEXTVAL  AS  condition_no FROM DUAL';
        OPEN  condition_no_cur FOR lt_sql_str;
        FETCH condition_no_cur INTO condition_no_rec;
        CLOSE condition_no_cur;
        --
        IF ( LENGTHB( condition_no_rec.condition_no ) > 6 ) THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cok
                          , iv_name         => cv_msg_cok_10676
                        );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSE
          lt_condition_no               :=  lv_process_year || 'UP' || LPAD( condition_no_rec.condition_no, 6, '0' );
        END IF;
      END;
--
      -- �̔��T���f�[�^��o�^����
      INSERT INTO xxcok_sales_deduction(
           sales_deduction_id                                         -- �̔��T��ID
          ,base_code_from                                             -- �U�֌����_
          ,base_code_to                                               -- �U�֐拒�_
          ,customer_code_from                                         -- �U�֌��ڋq�R�[�h
          ,customer_code_to                                           -- �U�֐�ڋq�R�[�h
          ,deduction_chain_code                                       -- �`�F�[���X�R�[�h
          ,corp_code                                                  -- ��ƃR�[�h
          ,record_date                                                -- �v���
          ,source_category                                            -- �쐬���敪
          ,source_line_id                                             -- �쐬������ID
          ,condition_id                                               -- �T������ID
          ,condition_no                                               -- �T���ԍ�
          ,condition_line_id                                          -- �T���ڍ�ID
          ,data_type                                                  -- �f�[�^���
          ,status                                                     -- �X�e�[�^�X
          ,item_code                                                  -- �i�ڃR�[�h
          ,sales_uom_code                                             -- �̔��P��
          ,sales_unit_price                                           -- �̔��P��
          ,sales_quantity                                             -- �̔�����
          ,sale_pure_amount                                           -- ����{�̋��z
          ,sale_tax_amount                                            -- �������Ŋz
          ,deduction_uom_code                                         -- �T���P��
          ,deduction_unit_price                                       -- �T���P��
          ,deduction_quantity                                         -- �T������
          ,deduction_amount                                           -- �T���z
-- 2022/05/20 Ver1.1 ADD Start
          ,compensation                                               -- ��U
          ,margin                                                     -- �≮�}�[�W��
          ,sales_promotion_expenses                                   -- �g��
          ,margin_reduction                                           -- �≮�}�[�W�����z
-- 2022/05/20 Ver1.1 ADD End
          ,tax_code                                                   -- �ŃR�[�h
          ,tax_rate                                                   -- �ŗ�
          ,recon_tax_code                                             -- �������ŃR�[�h
          ,recon_tax_rate                                             -- �������ŗ�
          ,deduction_tax_amount                                       -- �T���Ŋz
          ,remarks                                                    -- ���l
          ,application_no                                             -- �\����No.
          ,gl_if_flag                                                 -- GL�A�g�t���O
          ,gl_base_code                                               -- GL�v�㋒�_
          ,gl_date                                                    -- GL�L����
          ,recovery_date                                              -- ���J�o���[���t
          ,cancel_flag                                                -- ����t���O
          ,cancel_base_code                                           -- ������v�㋒�_
          ,cancel_gl_date                                             -- ���GL�L����
          ,cancel_user                                                -- ������{���[�U
          ,recon_base_code                                            -- �������v�㋒�_
          ,recon_slip_num                                             -- �x���`�[�ԍ�
          ,carry_payment_slip_num                                     -- �J�z���x���`�[�ԍ�
          ,report_decision_flag                                       -- ����m��t���O
          ,gl_interface_id                                            -- GL�A�gID
          ,cancel_gl_interface_id                                     -- ���GL�A�gID
          ,created_by                                                 -- �쐬��
          ,creation_date                                              -- �쐬��
          ,last_updated_by                                            -- �ŏI�X�V��
          ,last_update_date                                           -- �ŏI�X�V��
          ,last_update_login                                          -- �ŏI�X�V���O�C��
          ,request_id                                                 -- �v��ID
          ,program_application_id                                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                                                 -- �R���J�����g�E�v���O����ID
          ,program_update_date                                        -- �v���O�����X�V��
        )VALUES(
           xxcok_sales_deduction_s01.nextval                          -- �̔��T��ID
          ,gt_sales_deduction_work_tbl(i).base_code                   -- �U�֌����_
          ,gt_sales_deduction_work_tbl(i).base_code                   -- �U�֐拒�_
          ,gt_sales_deduction_work_tbl(i).customer_code_from          -- �U�֌��ڋq�R�[�h
          ,gt_sales_deduction_work_tbl(i).customer_code_from          -- �U�֐�ڋq�R�[�h
          ,gt_sales_deduction_work_tbl(i).introduction_chain_code     -- �`�F�[���X�R�[�h
          ,gt_sales_deduction_work_tbl(i).corp_code                   -- ��ƃR�[�h
          ,gt_sales_deduction_work_tbl(i).record_date                 -- �v���
          ,cv_const_u                                                 -- �쐬���敪
          ,NULL                                                       -- �쐬������ID
          ,NULL                                                       -- �T������ID
          ,lt_condition_no                                            -- �T���ԍ�
          ,NULL                                                       -- �T���ڍ�ID
          ,gt_sales_deduction_work_tbl(i).data_type                   -- �f�[�^���
          ,cv_const_n                                                 -- �X�e�[�^�X
          ,gt_sales_deduction_work_tbl(i).item_code                   -- �i�ڃR�[�h
          ,NULL                                                       -- �̔��P��
          ,NULL                                                       -- �̔��P��
          ,NULL                                                       -- �̔�����
          ,NULL                                                       -- ����{�̋��z
          ,NULL                                                       -- �������Ŋz
          ,gt_sales_deduction_work_tbl(i).deduction_uom_code          -- �T���P��
          ,gt_sales_deduction_work_tbl(i).deduction_unit_price        -- �T���P��
          ,gt_sales_deduction_work_tbl(i).deduction_quantity          -- �T������
          ,gt_sales_deduction_work_tbl(i).deduction_amount            -- �T���z
-- 2022/05/20 Ver1.1 ADD Start
          ,gt_sales_deduction_work_tbl(i).compensation                -- ��U
          ,gt_sales_deduction_work_tbl(i).margin                      -- �≮�}�[�W��
          ,gt_sales_deduction_work_tbl(i).sales_promotion_expenses    -- �g��
          ,gt_sales_deduction_work_tbl(i).margin_reduction            -- �≮�}�[�W�����z
-- 2022/05/20 Ver1.1 ADD End
          ,gt_sales_deduction_work_tbl(i).tax_code                    -- �ŃR�[�h
          ,gt_sales_deduction_work_tbl(i).tax_rate                    -- �ŗ�
          ,NULL                                                       -- �������ŃR�[�h
          ,NULL                                                       -- �������ŗ�
          ,gt_sales_deduction_work_tbl(i).deduction_tax_amount        -- �T���Ŋz
          ,gt_sales_deduction_work_tbl(i).remarks                     -- ���l
          ,gt_sales_deduction_work_tbl(i).application_no              -- �\����No.
          ,cv_const_n                                                 -- GL�A�g�t���O
          ,NULL                                                       -- GL�v�㋒�_
          ,NULL                                                       -- GL�L����
          ,NULL                                                       -- ���J�o���[���t
          ,cv_const_n                                                 -- ����t���O
          ,NULL                                                       -- ������v�㋒�_
          ,NULL                                                       -- ���GL�L����
          ,NULL                                                       -- ������{���[�U
          ,cv_const_n                                                 -- �������v�㋒�_
-- 2022/05/20 Ver1.1 MOD Start
          ,DECODE(gt_sales_deduction_work_tbl(i).paid_flag, 'Y', '-', NULL)
                                                                      -- �x���`�[�ԍ�
--          ,NULL                                                       -- �x���`�[�ԍ�
          ,DECODE(gt_sales_deduction_work_tbl(i).paid_flag, 'Y', '-', NULL)
                                                                      -- �J�z���x���`�[�ԍ�
--          ,NULL                                                       -- �J�z���x���`�[�ԍ�
-- 2022/05/20 Ver1.1 MOD End
          ,NULL                                                       -- ����m��t���O
          ,NULL                                                       -- GL�A�gID
          ,NULL                                                       -- ���GL�A�gID
          ,cn_created_by                                              -- �쐬��
          ,cd_creation_date                                           -- �쐬��
          ,cn_last_updated_by                                         -- �ŏI�X�V��
          ,cd_last_update_date                                        -- �ŏI�X�V��
          ,cn_last_update_login                                       -- �ŏI�X�V���O�C��
          ,cn_request_id                                              -- �v��ID
          ,cn_program_application_id                                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                              -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                     -- �v���O�����X�V��
        );
    END LOOP;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END deduction_date_register;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER     --   �t�@�C��ID
   ,iv_file_format  IN   VARCHAR2   --   �t�@�C���t�H�[�}�b�g
   ,ov_errbuf       OUT  VARCHAR2   --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT  VARCHAR2   --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT  VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    -- ���[�v���̃J�E���g
    ln_file_if_loop_cnt  NUMBER; -- �t�@�C��IF���[�v�J�E���^
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
    gn_target_cnt        := 0; -- �Ώی���
    gn_normal_cnt        := 0; -- ���팏��
    gn_warn_cnt          := 0; -- �x������
    gn_error_cnt         := 0; -- �G���[����
--
    -- ���[�J���ϐ��̏�����
    ln_file_if_loop_cnt  := 0; -- �t�@�C��IF���[�v�J�E���^
--
    -- ============================================
    -- A-1�D��������
    -- ============================================
    init(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�DIF�f�[�^�擾
    -- ============================================
    get_if_data(
       in_file_id        -- �t�@�C��ID
      ,iv_file_format    -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�DIF�f�[�^�폜
    -- ============================================
    delete_if_data(
       in_file_id        -- �t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ����I���̏ꍇ�̓R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- �t�@�C���A�b�v���[�hIF���[�v
    <<file_if_loop>>
    --�P�s�ڂ̓J�����s�ׁ̈A�Q�s�ڂ��珈������
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      -- ============================================
      -- A-4�D�A�b�v���[�h�t�@�C�����ڕ���
      -- ============================================
--
      divide_item(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-5�D�G���[�`�F�b�N����
      -- ============================================
      error_check(
         ln_file_if_loop_cnt -- IF���[�v�J�E���^
        ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP file_if_loop;
    -- �x�����P���ł��������ꍇ�x������
    IF ( gn_warn_cnt >= 1 ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
    -- ============================================
    -- A-6�D�̔��T���f�[�^�o�^����
    -- ============================================
    IF ( lv_retcode = cv_status_normal ) THEN
      deduction_date_register(
         lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--#################################  �Œ��O������ START   ###################################
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2 --   �G���[���b�Z�[�W #�Œ�#
   ,retcode          OUT   VARCHAR2 --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id       IN    VARCHAR2 --   1.�t�@�C��ID(�K�{)
   ,iv_file_format   IN    VARCHAR2 --   2.�t�@�C���t�H�[�}�b�g(�K�{)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- �v���O������
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg   CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg  CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg    CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_const_normal_msg CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg         CONSTANT VARCHAR2(100)  :=  'APP-XXCOK1-10649'; -- �x���I���S���[���o�b�N
    cv_error_msg        CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token        CONSTANT VARCHAR2(10)   :=  'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      ov_retcode  =>  lv_retcode
     ,ov_errbuf   =>  lv_errbuf
     ,ov_errmsg   =>  lv_errmsg
     ,iv_which    =>  cv_file_type_out
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
       TO_NUMBER(iv_file_id)  -- 1.�t�@�C��ID
      ,iv_file_format         -- 2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (  lv_retcode = cv_status_error
       OR lv_retcode = cv_status_warn ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ����I���ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
    END IF;
--
    -- �G���[������
    IF lv_retcode = cv_status_error THEN
      gn_target_cnt := 0; -- �Ώی���
      gn_normal_cnt := 0; -- ��������
      gn_error_cnt  := 1; -- �G���[����
    ELSIF lv_retcode = cv_status_warn THEN
      gn_normal_cnt := 0; -- ��������
    END IF;
    -- ===============================================================
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================================
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    -- �x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_ccp_10534
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���ʂ̃��O���b�Z�[�W�̏o�͏I��
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�I�����b�Z�[�W�̐ݒ�A�o��
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_const_normal_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cok
                   ,iv_name         => lv_message_code
                  );
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    END IF;
    --
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A20C;
/
