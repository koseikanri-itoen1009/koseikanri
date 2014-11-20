CREATE OR REPLACE PACKAGE BODY XXCOK021A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A04C(body)
 * Description      : ���n�V�X�e���C���^�[�t�F�[�X�t�@�C���쐬-�≮�x��
 * MD.050           : ���n�V�X�e���C���^�[�t�F�[�X�t�@�C���쐬-�≮�x�� MD050_COK_021_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_file_open          �t�@�C���I�[�v��(A-2)
 *  get_wholesale_info     �A�g�Ώۖ≮�x�����擾(A-3)
 *  file_output            �t���b�g�t�@�C���쐬(A-4)
 *  update_status          �o�͍σf�[�^�X�e�[�^�X�X�V(A-5)
 *  file_close             �t�@�C���N���[�Y(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   A.Yano           �V�K�쐬
 *  2009/02/06    1.1   T.Abe            [��QCOK_016] �f�B���N�g���p�X�o�͑Ή�
 *  2009/03/19    1.2   A.Yano           [��QT1_0087] �K�{���ڂ̕s��Ή�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20)   := 'XXCOK021A04C';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER         := fnd_global.user_id;           -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER         := fnd_global.user_id;           -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER         := fnd_global.login_id;          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := fnd_global.conc_request_id;   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := fnd_global.prog_appl_id;      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := fnd_global.conc_program_id;   -- PROGRAM_ID
  -- �Z�p���[�^
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)    := '.';
  -- �A�v���P�[�V�����Z�k��
  cv_app_name_ccp           CONSTANT VARCHAR2(5)    := 'XXCCP';
  cv_app_name_cok           CONSTANT VARCHAR2(5)    := 'XXCOK';
  -- ���b�Z�[�W
  cv_no_parameter_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCCP1-90008';           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_profile_err_msg        CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00003';           -- �v���t�@�C���擾�G���[
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00013';           -- �݌ɑg�DID�擾�G���[
  cv_process_date_err_msg   CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00028';           -- �Ɩ��������t�擾�G���[
  cv_out_filename_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00006';           -- �t�@�C�������b�Z�[�W�o��
  cv_file_chk_err_msg       CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00009';           -- �t�@�C�����݃`�F�b�N�G���[
  cv_lock_err_msg           CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-10068';           -- �≮�x����񃍃b�N�擾�G���[
  cv_update_err_msg         CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-10069';           -- �A�g�X�e�[�^�X�X�V�G���[
  cv_out_dire_path_msg      CONSTANT VARCHAR2(20)   := 'APP-XXCOK1-00067';           -- �f�B���N�g���p�X���b�Z�[�W�o��
  -- �g�[�N��
  cv_tkn_profile_name       CONSTANT VARCHAR2(10)   := 'PROFILE';                    -- �v���t�@�C����
  cv_tkn_org_code           CONSTANT VARCHAR2(10)   := 'ORG_CODE';                   -- �݌ɑg�D�R�[�h
  cv_tkn_file_name          CONSTANT VARCHAR2(10)   := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_dire_path_name     CONSTANT VARCHAR2(10)   := 'DIRECTORY';                  -- �f�B���N�g���p�X
  cv_tkn_wholesale_id       CONSTANT VARCHAR2(20)   := 'WHOLESALE_ID';               -- �≮�x��ID
  -- �v���t�@�C����
  cv_comp_code              CONSTANT VARCHAR2(30)   := 'XXCOK1_AFF1_COMPANY_CODE';   -- XXCOK:��ЃR�[�h
  cv_wholesale_dire_path    CONSTANT VARCHAR2(30)   := 'XXCOK1_WHOLESALE_DIRE_PATH'; -- XXCOK:�f�B���N�g���p�X
  cv_wholesale_file_name    CONSTANT VARCHAR2(30)   := 'XXCOK1_WHOLESALE_FILE_NAME'; -- XXCOK:�t�@�C����
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�START�z------------------------------------------------------
  cv_emp_code_dummy         CONSTANT VARCHAR2(30)   := 'XXCOK1_EMP_CODE_DUMMY';      -- XXCOK:�S���҃R�[�h_�_�~�[�l
  cv_estimated_type_dummy   CONSTANT VARCHAR2(30)   := 'XXCOK1_ESTIMATED_TYPE_DUMMY';-- XXCOK:���ϋ敪_�_�~�[�l
  cv_estimated_no_dummy     CONSTANT VARCHAR2(30)   := 'XXCOK1_ESTIMATED_NO_DUMMY';  -- XXCOK:���ϔԍ�_�_�~�[�l
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�END  �z------------------------------------------------------
  cv_organization_code      CONSTANT VARCHAR2(30)   := 'XXCOK1_ORG_CODE_SALES';      -- XXCOK:�݌ɑg�D�R�[�h_�c�Ƒg�D
  -- AP�A�g�X�e�[�^�X
  cv_ap_interface_status    CONSTANT VARCHAR2(1)    := '1';                          -- �A�g��
  -- ���n�V�X�e���A�g�X�e�[�^�X
  cv_info_if_status_before  CONSTANT VARCHAR2(1)    := '0';                          -- ������
  cv_info_if_status_after   CONSTANT VARCHAR2(1)    := '1';                          -- ������
  -- �L��
  cv_slash                  CONSTANT VARCHAR2(1)    := '/';
  cv_double_quotation       CONSTANT VARCHAR2(1)    := '"';
  cv_comma                  CONSTANT VARCHAR2(1)    := ',';
  -- �t�@�C���I�[�v�����p�����[�^
  cv_write_mode             CONSTANT VARCHAR2(1)    := 'w';                          -- �t�@�C���㏑��
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;                        -- �ő���o�̓T�C�Y
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt             NUMBER                                               DEFAULT 0;     -- �Ώی���
  gn_normal_cnt             NUMBER                                               DEFAULT 0;     -- ���팏��
  gn_error_cnt              NUMBER                                               DEFAULT 0;     -- �G���[����
  gn_warn_cnt               NUMBER                                               DEFAULT 0;     -- �X�L�b�v����
  gd_process_date           DATE                                                 DEFAULT NULL;  -- �Ɩ��������t
  gd_sysdate                DATE                                                 DEFAULT NULL;  -- �V�X�e�����t
  gv_comp_code              VARCHAR2(5)                                          DEFAULT NULL;  -- ��ЃR�[�h
  gv_wholesale_dire_path    fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- �f�B���N�g���p�X
  gv_wholesale_file_name    fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- �t�@�C����
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�START�z------------------------------------------------------
  gv_emp_code_dummy         fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- �S���҃R�[�h_�_�~�[�l
  gv_estimated_type_dummy   fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- ���ϋ敪_�_�~�[�l
  gv_estimated_no_dummy     fnd_profile_option_values.profile_option_value%TYPE  DEFAULT NULL;  -- ���ϔԍ�_�_�~�[�l
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�END  �z------------------------------------------------------
  gn_organization_id        NUMBER                                               DEFAULT NULL;  -- �݌ɑg�DID
  g_file_handle             UTL_FILE.FILE_TYPE;                                                 -- �t�@�C���n���h��
  gv_dire_path              VARCHAR2(1000)                                       DEFAULT NULL;  -- �f�B���N�g���p�X(���b�Z�[�W�o�͗p)
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- �A�g�Ώۖ≮�x�����
  CURSOR g_wholesale_info_cur
  IS
    SELECT xwp.wholesale_payment_id                 AS wholesale_payment_id       -- �≮�x��ID
          ,xwp.expect_payment_date                  AS expect_payment_date        -- �x���\���
          ,xwp.selling_month                        AS selling_month              -- ����Ώ۔N��
          ,xwp.base_code                            AS base_code                  -- ���_�R�[�h
          ,xwp.supplier_code                        AS supplier_code              -- �d����R�[�h
          ,xwp.emp_code                             AS emp_code                   -- �S���҃R�[�h
          ,xwp.wholesale_code_admin                 AS wholesale_code_admin       -- �≮�Ǘ��R�[�h
          ,xwp.oprtn_status_code                    AS oprtn_status_code          -- �ƑԃR�[�h
          ,xwp.cust_code                            AS cust_code                  -- �ڋq�R�[�h
          ,xwp.sales_outlets_code                   AS sales_outlets_code         -- �≮������R�[�h
          ,xwp.estimated_type                       AS estimated_type             -- ���ϋ敪
          ,xwp.estimated_no                         AS estimated_no               -- ���ϔԍ�
          ,xwp.container_group_code                 AS container_group_code       -- �e��Q�R�[�h
          ,item.case_qty                            AS case_qty                   -- �P�[�X����
          ,xwp.item_code                            AS item_code                  -- ���i�R�[�h(�i�ڃR�[�h)
          ,xwp.market_amt                           AS market_amt                 -- ���l
          ,xwp.selling_discount                     AS selling_discount           -- ����l��
          ,xwp.normal_store_deliver_amt             AS normal_store_deliver_amt   -- �ʏ�X�[
          ,xwp.once_store_deliver_amt               AS once_store_deliver_amt     -- ����X�[
          ,xwp.net_selling_price                    AS net_selling_price          -- NET���i
          ,xwp.coverage_amt                         AS coverage_amt               -- ��U
          ,xwp.wholesale_margin_sum                 AS wholesale_margin_sum       -- �≮�}�[�W��
          ,xwp.expansion_sales_amt                  AS expansion_sales_amt        -- �g����
          ,item.list_price                          AS list_price                 -- �艿
          ,xwp.demand_unit_type                     AS demand_unit_type           -- �����P��
          ,xwp.demand_qty                           AS demand_qty                 -- ��������
          ,xwp.demand_unit_price                    AS demand_unit_price          -- �����P��
          ,xwp.demand_amt                           AS demand_amt                 -- �������z(�Ŕ�)
          ,xwp.payment_qty                          AS payment_qty                -- �x������
          ,xwp.payment_unit_price                   AS payment_unit_price         -- �x���P��
          ,xwp.payment_amt                          AS payment_amt                -- �x�����z(�Ŕ�)
          ,xwp.acct_code                            AS acct_code                  -- ����ȖڃR�[�h
          ,xwp.sub_acct_code                        AS sub_acct_code              -- �⏕�ȖڃR�[�h
          ,xwp.coverage_amt * payment_qty           AS coverage_amt_sum           -- ��U�z
          ,xwp.wholesale_margin_sum * payment_qty   AS wholesale_margin_amt_sum   -- �≮�}�[�W���z
          ,xwp.expansion_sales_amt * payment_qty    AS expansion_sales_amt_sum    -- �g����z
          ,xwp.misc_acct_amt                        AS misc_acct_amt              -- ���̑��Ȗ�
    FROM   xxcok_wholesale_payment  xwp
          ,( SELECT msib.segment1              AS item_code
                   ,iimb.attribute11           AS case_qty
                   ,CASE
                      WHEN NVL( TO_DATE( iimb.attribute6, 'YYYY/MM/DD' ), gd_process_date ) > gd_process_date
                      THEN
                        iimb.attribute4
                      ELSE
                        iimb.attribute5
                    END                        AS list_price
             FROM mtl_system_items_b  msib
                 ,ic_item_mst_b       iimb
             WHERE msib.segment1           = iimb.item_no
             AND   msib.organization_id    = gn_organization_id
           )                        item
    WHERE xwp.ap_interface_status   = cv_ap_interface_status
    AND   xwp.info_interface_status = cv_info_if_status_before
    AND   xwp.item_code             = item.item_code(+)
    FOR UPDATE OF xwp.wholesale_payment_id NOWAIT
  ;
  -- ===============================
  -- �O���[�o��TABLE�^
  -- ===============================
  -- �A�g�Ώۖ≮�x�����
  TYPE g_wholesale_info_ttype IS TABLE OF g_wholesale_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- �O���[�o��PL/SQL�\
  -- ===============================
  -- �A�g�Ώۖ≮�x�����
  g_wholesale_info_tab    g_wholesale_info_ttype;
  -- ===============================
  -- ��O
  -- ===============================
  --*** ���������ʗ�O(�t�@�C���N���[�Y�����Ȃ�) ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
--
  close_file_process_expt     EXCEPTION;    -- ���������ʗ�O(�t�@�C���N���[�Y��������)
  no_data_expt                EXCEPTION;    -- �f�[�^�擾��O
  lock_expt                   EXCEPTION;    -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf    OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode   OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg    OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name                CONSTANT VARCHAR2(5)  := 'init'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(2000) DEFAULT NULL;                -- �o�̓��b�Z�[�W
    lb_retcode                 BOOLEAN        DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_organization_code       VARCHAR2(10)   DEFAULT NULL;                -- �݌ɑg�D�R�[�h
    lv_nodata_profile          VARCHAR2(30)   DEFAULT NULL;                -- ���擾�̃v���t�@�C����
    -- *** ���[�J����O ***
    nodata_profile_expt        EXCEPTION;         -- �v���t�@�C���l�擾��O
    process_date_expt          EXCEPTION;         -- �Ɩ��������t�擾��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. ���b�Z�[�W�o��
    -- ===============================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_no_parameter_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.LOG
                    ,lv_out_msg
                    ,2
                  );
    -- ===============================
    -- 2. �V�X�e�����t���擾
    -- ===============================
    gd_sysdate := SYSDATE;
    -- ===============================
    -- 3. �v���t�@�C�����擾
    -- ===============================
    -- (1)��ЃR�[�h�擾
    gv_comp_code := FND_PROFILE.VALUE( cv_comp_code );
    IF( gv_comp_code IS NULL ) THEN
      lv_nodata_profile := cv_comp_code;
      RAISE nodata_profile_expt;
    END IF;
    -- (2)�f�B���N�g���p�X�擾
    gv_wholesale_dire_path := FND_PROFILE.VALUE( cv_wholesale_dire_path );
    IF( gv_wholesale_dire_path IS NULL ) THEN
      lv_nodata_profile := cv_wholesale_dire_path;
      RAISE nodata_profile_expt;
    END IF;
    -- (3)�t�@�C�����擾
    gv_wholesale_file_name := FND_PROFILE.VALUE( cv_wholesale_file_name );
    IF( gv_wholesale_file_name IS NULL ) THEN
      lv_nodata_profile := cv_wholesale_file_name;
      RAISE nodata_profile_expt;
    END IF;
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�START�z------------------------------------------------------
    -- (4)�S���҃R�[�h_�_�~�[�l�擾
    gv_emp_code_dummy := FND_PROFILE.VALUE( cv_emp_code_dummy );
    IF( gv_emp_code_dummy IS NULL ) THEN
      lv_nodata_profile := cv_emp_code_dummy;
      RAISE nodata_profile_expt;
    END IF;
    -- (5)���ϋ敪_�_�~�[�l�擾
    gv_estimated_type_dummy := FND_PROFILE.VALUE( cv_estimated_type_dummy );
    IF( gv_estimated_type_dummy IS NULL ) THEN
      lv_nodata_profile := cv_estimated_type_dummy;
      RAISE nodata_profile_expt;
    END IF;
    -- (6)���ϔԍ�_�_�~�[�l�擾
    gv_estimated_no_dummy := FND_PROFILE.VALUE( cv_estimated_no_dummy );
    IF( gv_estimated_no_dummy IS NULL ) THEN
      lv_nodata_profile := cv_estimated_no_dummy;
      RAISE nodata_profile_expt;
    END IF;
--�y2009/03/19 A.Yano Ver.1.2 �ǉ�END  �z------------------------------------------------------
    -- (7)�݌ɑg�D�R�[�h�擾
    lv_organization_code := FND_PROFILE.VALUE( cv_organization_code );
    IF( lv_organization_code IS NULL ) THEN
      lv_nodata_profile := cv_organization_code;
      RAISE nodata_profile_expt;
    END IF;
    -- ===============================
    -- 4. �݌ɑg�DID���擾
    -- ===============================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_organization_code
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- 5. �Ɩ��������t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date();
    IF( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    -- ===============================
    -- 6. �t�@�C�����o��
    -- ===============================
    -- �f�B���N�g���p�X�o��
    gv_dire_path := xxcok_common_pkg.get_directory_path_f(
                      iv_directory_name => gv_wholesale_dire_path
                    );
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_out_dire_path_msg
                    ,iv_token_name1  => cv_tkn_dire_path_name
                    ,iv_token_value1 => gv_dire_path
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
    -- �t�@�C�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_cok
                    ,iv_name         => cv_out_filename_msg
                    ,iv_token_name1  => cv_tkn_file_name
                    ,iv_token_value1 => gv_wholesale_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
--
  EXCEPTION
    -- *** �v���t�@�C���擾��O�n���h�� ****
    WHEN nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_tkn_profile_name
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �݌ɑg�DID�擾��O�n���h�� ***
    WHEN no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_org_id_nodata_msg
                      ,iv_token_name1  => cv_tkn_org_code
                      ,iv_token_value1 => lv_organization_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ��������t�擾��O�n���h�� ***
    WHEN process_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_process_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_file_open
   * Description      : �t�@�C���I�[�v��(A-2)
   ***********************************************************************************/
  PROCEDURE chk_file_open(
     ov_errbuf       OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name           CONSTANT VARCHAR2(20)    := 'chk_file_open'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf             VARCHAR2(5000)  DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1)     DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000)  DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg            VARCHAR2(2000)  DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode            BOOLEAN         DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    lb_exists             BOOLEAN         DEFAULT FALSE;                -- �t�@�C���̗L��
    ln_file_length        NUMBER          DEFAULT NULL;                 -- �t�@�C������
    ln_blocksize          BINARY_INTEGER  DEFAULT NULL;                 -- �u���b�N�T�C�Y
    -- *** ���[�J����O ***
    file_check_expt       EXCEPTION;          -- �t�@�C�����݃`�F�b�N��O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. �t�@�C���̑��݃`�F�b�N
    -- ===============================
    UTL_FILE.FGETATTR(
       location      =>   gv_wholesale_dire_path
      ,filename      =>   gv_wholesale_file_name
      ,fexists       =>   lb_exists
      ,file_length   =>   ln_file_length
      ,block_size    =>   ln_blocksize
    );
    IF( lb_exists ) THEN
      RAISE file_check_expt;
    END IF;
    -- ===============================
    -- 2. �t�@�C���I�[�v��
    -- ===============================
    g_file_handle := UTL_FILE.FOPEN(
                        gv_wholesale_dire_path
                       ,gv_wholesale_file_name
                       ,cv_write_mode
                       ,cn_max_linesize
                     );
--
  EXCEPTION
    -- *** �t�@�C�����݃`�F�b�N��O ****
    WHEN file_check_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_file_chk_err_msg
                      ,iv_token_name1  => cv_tkn_file_name
                      ,iv_token_value1 => gv_wholesale_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END chk_file_open;
--
  /**********************************************************************************
   * Procedure Name   : get_wholesale_info
   * Description      : �A�g�Ώۖ≮�x�����擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_wholesale_info(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name     CONSTANT VARCHAR2(20) := 'get_wholesale_info'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;                -- �o�̓��b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �A�g�Ώۖ≮�x�����擾
    -- �≮�x���e�[�u�����b�N�擾
    -- ===============================
    OPEN  g_wholesale_info_cur;
    FETCH g_wholesale_info_cur BULK COLLECT INTO g_wholesale_info_tab;
    CLOSE g_wholesale_info_cur;
--
  EXCEPTION
    -- *** ���b�N�擾��O�n���h�� ****
    WHEN lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_cok
                      ,iv_name         => cv_lock_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_out_msg
                      ,0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_wholesale_info;
--
  /**********************************************************************************
   * Procedure Name   : file_output
   * Description      : �t���b�g�t�@�C���쐬(A-4)
   ***********************************************************************************/
  PROCEDURE file_output(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,in_index      IN  NUMBER        -- PL/SQL�\�C���f�b�N�X
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name             CONSTANT VARCHAR2(15) := 'file_output'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf               VARCHAR2(5000)              DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1)                 DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000)              DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg              VARCHAR2(2000)              DEFAULT NULL;              -- �o�̓��b�Z�[�W
    lb_retcode              BOOLEAN                     DEFAULT TRUE;              -- ���b�Z�[�W�o�͊֐��̖߂�l
    lv_file_output_info     VARCHAR2(3000)              DEFAULT NULL;              -- �t�@�C���o�͂���≮�x�����
    -- �t�@�C���o�̓f�[�^
    lv_wholesale_payment_id VARCHAR2(20)                                      DEFAULT NULL;  -- �≮�x��ID
    lv_payment_date         VARCHAR2(20)                                      DEFAULT NULL;  -- �x���\���
    lv_selling_month        xxcok_wholesale_payment.selling_month%TYPE        DEFAULT NULL;  -- ����Ώ۔N��
    lv_base_code            xxcok_wholesale_payment.base_code%TYPE            DEFAULT NULL;  -- ���_�R�[�h
    lv_supplier_code        xxcok_wholesale_payment.supplier_code%TYPE        DEFAULT NULL;  -- �d����R�[�h
    lv_emp_code             xxcok_wholesale_payment.emp_code%TYPE             DEFAULT NULL;  -- �S���҃R�[�h
    lv_wholesale_code_admin xxcok_wholesale_payment.wholesale_code_admin%TYPE DEFAULT NULL;  -- �≮�Ǘ��R�[�h
    lv_oprtn_status_code    xxcok_wholesale_payment.oprtn_status_code%TYPE    DEFAULT NULL;  -- �ƑԃR�[�h
    lv_cust_code            xxcok_wholesale_payment.cust_code%TYPE            DEFAULT NULL;  -- �ڋq�R�[�h
    lv_sales_outlets_code   xxcok_wholesale_payment.sales_outlets_code%TYPE   DEFAULT NULL;  -- �≮������R�[�h
    lv_estimated_type       xxcok_wholesale_payment.estimated_type%TYPE       DEFAULT NULL;  -- ���ϋ敪
    lv_estimated_no         xxcok_wholesale_payment.estimated_no%TYPE         DEFAULT NULL;  -- ���ϔԍ�
    lv_container_group_code xxcok_wholesale_payment.container_group_code%TYPE DEFAULT NULL;  -- �e��Q�R�[�h
    lv_case_qty             VARCHAR2(20)                                      DEFAULT NULL;  -- �P�[�X����
    lv_item_code            xxcok_wholesale_payment.item_code%TYPE            DEFAULT NULL;  -- ���i�R�[�h
    lv_market_amt           VARCHAR2(20)                                      DEFAULT NULL;  -- ���l
    lv_selling_discount     VARCHAR2(20)                                      DEFAULT NULL;  -- ����l��
    lv_normal_dlv_amt       VARCHAR2(20)                                      DEFAULT NULL;  -- �ʏ�X�[
    lv_once_dlv_amt         VARCHAR2(20)                                      DEFAULT NULL;  -- ����X�[
    lv_net_selling_price    VARCHAR2(20)                                      DEFAULT NULL;  -- NET���i
    lv_coverage_amt         VARCHAR2(20)                                      DEFAULT NULL;  -- ��U
    lv_wholesale_margin_amt VARCHAR2(20)                                      DEFAULT NULL;  -- �≮�}�[�W��
    lv_expansion_sales_amt  VARCHAR2(20)                                      DEFAULT NULL;  -- �g����
    lv_list_price           VARCHAR2(20)                                      DEFAULT NULL;  -- �艿
    lv_demand_unit_type     xxcok_wholesale_payment.demand_unit_type%TYPE     DEFAULT NULL;  -- �����P��
    lv_demand_qty           VARCHAR2(20)                                      DEFAULT NULL;  -- ��������
    lv_demand_unit_price    VARCHAR2(20)                                      DEFAULT NULL;  -- �����P��
    lv_demand_amt           VARCHAR2(20)                                      DEFAULT NULL;  -- �������z(�Ŕ�)
    lv_payment_qty          VARCHAR2(20)                                      DEFAULT NULL;  -- �x������
    lv_payment_unit_price   VARCHAR2(20)                                      DEFAULT NULL;  -- �x���P��
    lv_payment_amt          VARCHAR2(20)                                      DEFAULT NULL;  -- �x�����z(�Ŕ�)
    lv_acct_code            xxcok_wholesale_payment.acct_code%TYPE            DEFAULT NULL;  -- ����ȖڃR�[�h
    lv_sub_acct_code        xxcok_wholesale_payment.sub_acct_code%TYPE        DEFAULT NULL;  -- �⏕�ȖڃR�[�h
    lv_coverage_amt_sum     VARCHAR2(20)                                      DEFAULT NULL;  -- ��U�z
    lv_wholesale_margin_sum VARCHAR2(20)                                      DEFAULT NULL;  -- �≮�}�[�W���z
    lv_expansion_sales_sum  VARCHAR2(20)                                      DEFAULT NULL;  -- �g����z
    lv_misc_acct_amt        VARCHAR2(20)                                      DEFAULT NULL;  -- ���̑��Ȗڊz
    lv_sysdate              VARCHAR2(14)                                      DEFAULT NULL;  -- �V�X�e�����t
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �ϐ��ɑ��
    -- ===============================
    lv_wholesale_payment_id := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_payment_id );     -- �≮�x��ID
    lv_payment_date         :=
      TO_CHAR( g_wholesale_info_tab( in_index ).expect_payment_date, 'YYYYMMDD' );                   -- �x���\���
    lv_selling_month        := g_wholesale_info_tab( in_index ).selling_month;                       -- ����Ώ۔N��
    lv_base_code            := g_wholesale_info_tab( in_index ).base_code;                           -- ���_�R�[�h
    lv_supplier_code        := g_wholesale_info_tab( in_index ).supplier_code;                       -- �d����R�[�h
--�y2009/03/19 A.Yano Ver.1.2 START�z------------------------------------------------------
--    lv_emp_code             := g_wholesale_info_tab( in_index ).emp_code;                            -- �S���҃R�[�h
    lv_emp_code             := NVL( g_wholesale_info_tab( in_index ).emp_code, gv_emp_code_dummy );  -- �S���҃R�[�h
--�y2009/03/19 A.Yano Ver.1.2 END  �z------------------------------------------------------
    lv_wholesale_code_admin := g_wholesale_info_tab( in_index ).wholesale_code_admin;                -- �≮�Ǘ��R�[�h
    lv_oprtn_status_code    := g_wholesale_info_tab( in_index ).oprtn_status_code;                   -- �ƑԃR�[�h
    lv_cust_code            := g_wholesale_info_tab( in_index ).cust_code;                           -- �ڋq�R�[�h
    lv_sales_outlets_code   := g_wholesale_info_tab( in_index ).sales_outlets_code;                  -- �≮������R�[�h
--�y2009/03/19 A.Yano Ver.1.2 START�z------------------------------------------------------
--    lv_estimated_type       := g_wholesale_info_tab( in_index ).estimated_type;                      -- ���ϋ敪
--    lv_estimated_no         := g_wholesale_info_tab( in_index ).estimated_no;                        -- ���ϔԍ�
    lv_estimated_type       :=
      NVL( g_wholesale_info_tab( in_index ).estimated_type, gv_estimated_type_dummy );               -- ���ϋ敪
    lv_estimated_no         :=
      NVL( g_wholesale_info_tab( in_index ).estimated_no, gv_estimated_no_dummy );                   -- ���ϔԍ�
--�y2009/03/19 A.Yano Ver.1.2 END  �z------------------------------------------------------
    lv_container_group_code := g_wholesale_info_tab( in_index ).container_group_code;                -- �e��Q�R�[�h
    lv_case_qty             := TO_CHAR( g_wholesale_info_tab( in_index ).case_qty );                 -- �P�[�X����
    lv_item_code            := g_wholesale_info_tab( in_index ).item_code;                           -- ���i�R�[�h
    lv_market_amt           := TO_CHAR( g_wholesale_info_tab( in_index ).market_amt );               -- ���l
    lv_selling_discount     := TO_CHAR( g_wholesale_info_tab( in_index ).selling_discount );         -- ����l��
    lv_normal_dlv_amt       := TO_CHAR( g_wholesale_info_tab( in_index ).normal_store_deliver_amt ); -- �ʏ�X�[
    lv_once_dlv_amt         := TO_CHAR( g_wholesale_info_tab( in_index ).once_store_deliver_amt );   -- ����X�[
    lv_net_selling_price    := TO_CHAR( g_wholesale_info_tab( in_index ).net_selling_price );        -- NET���i
    lv_coverage_amt         := TO_CHAR( g_wholesale_info_tab( in_index ).coverage_amt );             -- ��U
    lv_wholesale_margin_amt := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_margin_sum );     -- �≮�}�[�W��
    lv_expansion_sales_amt  := TO_CHAR( g_wholesale_info_tab( in_index ).expansion_sales_amt );      -- �g����
    lv_list_price           := TO_CHAR( g_wholesale_info_tab( in_index ).list_price );               -- �艿
    lv_demand_unit_type     := g_wholesale_info_tab( in_index ).demand_unit_type;                    -- �����P��
    lv_demand_qty           := TO_CHAR( g_wholesale_info_tab( in_index ).demand_qty );               -- ��������
    lv_demand_unit_price    := TO_CHAR( g_wholesale_info_tab( in_index ).demand_unit_price );        -- �����P��
    lv_demand_amt           := TO_CHAR( g_wholesale_info_tab( in_index ).demand_amt );               -- �������z(�Ŕ�)
    lv_payment_qty          := TO_CHAR( g_wholesale_info_tab( in_index ).payment_qty );              -- �x������
    lv_payment_unit_price   := TO_CHAR( g_wholesale_info_tab( in_index ).payment_unit_price );       -- �x���P��
    lv_payment_amt          := TO_CHAR( g_wholesale_info_tab( in_index ).payment_amt );              -- �x�����z(�Ŕ�)
    lv_acct_code            := g_wholesale_info_tab( in_index ).acct_code;                           -- ����ȖڃR�[�h
    lv_sub_acct_code        := g_wholesale_info_tab( in_index ).sub_acct_code;                       -- �⏕�ȖڃR�[�h
    lv_coverage_amt_sum     := TO_CHAR( g_wholesale_info_tab( in_index ).coverage_amt_sum );         -- ��U�z
    lv_wholesale_margin_sum := TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_margin_amt_sum ); -- �≮�}�[�W���z
    lv_expansion_sales_sum  := TO_CHAR( g_wholesale_info_tab( in_index ).expansion_sales_amt_sum );  -- �g����z
    lv_misc_acct_amt        := TO_CHAR( g_wholesale_info_tab( in_index ).misc_acct_amt );            -- ���̑��Ȗڊz
    lv_sysdate              := TO_CHAR( gd_sysdate, 'YYYYMMDDHH24MISS' );                            -- �V�X�e�����t
    -- ===============================
    -- �o�̓f�[�^��ϐ��Ɋi�[
    -- ===============================
    lv_file_output_info :=
                                            lv_wholesale_payment_id                          -- �≮�x��ID
      || cv_comma || cv_double_quotation || gv_comp_code            || cv_double_quotation   -- ��ЃR�[�h
      || cv_comma ||                        lv_payment_date                                  -- �x���\���
      || cv_comma ||                        lv_selling_month                                 -- ����Ώ۔N��
      || cv_comma || cv_double_quotation || lv_base_code            || cv_double_quotation   -- ���_�R�[�h
      || cv_comma || cv_double_quotation || lv_supplier_code        || cv_double_quotation   -- �d����R�[�h
      || cv_comma || cv_double_quotation || lv_emp_code             || cv_double_quotation   -- �S���҃R�[�h
      || cv_comma || cv_double_quotation || lv_wholesale_code_admin || cv_double_quotation   -- �≮�Ǘ��R�[�h
      || cv_comma || cv_double_quotation || lv_oprtn_status_code    || cv_double_quotation   -- �ƑԃR�[�h
      || cv_comma || cv_double_quotation || lv_cust_code            || cv_double_quotation   -- �ڋq�R�[�h
      || cv_comma || cv_double_quotation || lv_sales_outlets_code   || cv_double_quotation   -- �≮������R�[�h
      || cv_comma || cv_double_quotation || lv_estimated_type       || cv_double_quotation   -- ���ϋ敪
      || cv_comma || cv_double_quotation || lv_estimated_no         || cv_double_quotation   -- ���ϔԍ�
      || cv_comma || cv_double_quotation || lv_container_group_code || cv_double_quotation   -- �e��Q�R�[�h
      || cv_comma ||                        lv_case_qty                                      -- �P�[�X����
      || cv_comma || cv_double_quotation || lv_item_code            || cv_double_quotation   -- ���i�R�[�h
      || cv_comma ||                        lv_market_amt                                    -- ���l
      || cv_comma ||                        lv_selling_discount                              -- ����l��
      || cv_comma ||                        lv_normal_dlv_amt                                -- �ʏ�X�[
      || cv_comma ||                        lv_once_dlv_amt                                  -- ����X�[
      || cv_comma ||                        lv_net_selling_price                             -- NET���i
      || cv_comma ||                        lv_coverage_amt                                  -- ��U
      || cv_comma ||                        lv_wholesale_margin_amt                          -- �≮�}�[�W��
      || cv_comma ||                        lv_expansion_sales_amt                           -- �g����
      || cv_comma ||                        lv_list_price                                    -- �艿
      || cv_comma || cv_double_quotation || lv_demand_unit_type     || cv_double_quotation   -- �����P��
      || cv_comma ||                        lv_demand_qty                                    -- ��������
      || cv_comma ||                        lv_demand_unit_price                             -- �����P��
      || cv_comma ||                        lv_demand_amt                                    -- �������z(�Ŕ�)
      || cv_comma ||                        lv_payment_qty                                   -- �x������
      || cv_comma ||                        lv_payment_unit_price                            -- �x���P��
      || cv_comma ||                        lv_payment_amt                                   -- �x�����z(�Ŕ�)
      || cv_comma || cv_double_quotation || lv_acct_code            || cv_double_quotation   -- ����ȖڃR�[�h
      || cv_comma || cv_double_quotation || lv_sub_acct_code        || cv_double_quotation   -- �⏕�ȖڃR�[�h
      || cv_comma ||                        lv_coverage_amt_sum                              -- ��U�z
      || cv_comma ||                        lv_wholesale_margin_sum                          -- �≮�}�[�W���z
      || cv_comma ||                        lv_expansion_sales_sum                           -- �g����z
      || cv_comma ||                        lv_misc_acct_amt                                 -- ���̑��Ȗڊz
      || cv_comma ||                        lv_sysdate                                       -- �V�X�e�����t
    ;
    -- ===============================
    -- �t�@�C���o��
    -- ===============================
    UTL_FILE.PUT_LINE(
       file      =>   g_file_handle
      ,buffer    =>   lv_file_output_info
    );
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END file_output;
--
  /**********************************************************************************
   * Procedure Name   : update_status
   * Description      : �o�͍σf�[�^�X�e�[�^�X�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE update_status(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,in_index      IN  NUMBER        -- PL/SQL�\�C���f�b�N�X
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(15) := 'update_status'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
    -- *** ���[�J����O ***
    local_update_expt         EXCEPTION;          -- �X�V������O
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    BEGIN
--
      -- ===============================
      -- ���n�V�X�e���A�g�X�e�[�^�X�X�V
      -- ===============================
      UPDATE xxcok_wholesale_payment
      SET info_interface_status   = cv_info_if_status_after     -- ���n�V�X�e���A�g�X�e�[�^�X
         ,last_updated_by         = cn_last_updated_by          -- �ŏI�X�V��
         ,last_update_date        = SYSDATE                     -- �ŏI�X�V��
         ,last_update_login       = cn_last_update_login        -- �ŏI�X�V���O�C��
         ,request_id              = cn_request_id               -- �v��ID
         ,program_application_id  = cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              = cn_program_id               -- �R���J�����g�E�v���O����ID
         ,program_update_date     = SYSDATE                     -- �v���O�����X�V��
      WHERE wholesale_payment_id  = g_wholesale_info_tab( in_index ).wholesale_payment_id
      ;
--
    EXCEPTION
      -- *** �X�V������O�n���h�� ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name_cok
                        ,iv_name         => cv_update_err_msg
                        ,iv_token_name1  => cv_tkn_wholesale_id
                        ,iv_token_value1 => TO_CHAR( g_wholesale_info_tab( in_index ).wholesale_payment_id )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         FND_FILE.OUTPUT
                        ,lv_out_msg
                        ,0
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_status;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : �t�@�C���N���[�Y(A-6)
   ***********************************************************************************/
  PROCEDURE file_close(
     ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name     CONSTANT VARCHAR2(15) := 'file_close'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf       VARCHAR2(5000)   DEFAULT NULL;                   -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)      DEFAULT cv_status_normal;       -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)   DEFAULT NULL;                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)   DEFAULT NULL;                   -- �o�̓��b�Z�[�W
    lb_retcode      BOOLEAN          DEFAULT TRUE;                   -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- �t�@�C���N���[�Y
    -- ===============================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name               CONSTANT VARCHAR2(10) := 'submain'; -- �v���O������
    -- *** ���[�J���ϐ� ***
    lv_errbuf                 VARCHAR2(5000)  DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1)     DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000)  DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000)  DEFAULT NULL;                 -- �o�̓��b�Z�[�W
    lb_retcode                BOOLEAN         DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �t�@�C���I�[�v��(A-2)
    -- ===============================
    chk_file_open(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- �A�g�Ώۖ≮�x�����擾(A-3)
    -- ===============================
    get_wholesale_info(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE close_file_process_expt;
    END IF;
    -- �Ώی���
    gn_target_cnt := g_wholesale_info_tab.COUNT;
    IF( gn_target_cnt > 0 ) THEN
      << wholesale_info_loop >>
      FOR ln_index IN g_wholesale_info_tab.FIRST..g_wholesale_info_tab.LAST LOOP
        -- ===============================
        -- �t���b�g�t�@�C���쐬(A-4)
        -- ===============================
        file_output(
           ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ,in_index      =>    ln_index       -- PL/SQL�\�C���f�b�N�X
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE close_file_process_expt;
        END IF;
        -- ===============================
        -- �o�͍σf�[�^�X�e�[�^�X�X�V(A-5)
        -- ===============================
        update_status(
           ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          ,in_index      =>    ln_index       -- PL/SQL�\�C���f�b�N�X
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE close_file_process_expt;
        END IF;
        -- ���팏��
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP wholesale_info_loop;
    END IF;
    -- ===============================
    -- �t�@�C���N���[�Y(A-6)
    -- ===============================
    file_close(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h��(�t�@�C���N���[�Y) ***
    WHEN close_file_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
      -- �t�@�C���N���[�Y
      file_close(
         ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      -- �t�@�C���N���[�Y
      file_close(
         ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
      -- �t�@�C���N���[�Y
      file_close(
         ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
  IS
    -- ===============================
    -- �錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_prg_name        CONSTANT VARCHAR2(5)   := 'main';             -- �v���O������
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- *** ���[�J���ϐ� ***
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;               -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)     DEFAULT cv_status_normal;   -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;               -- �I�����b�Z�[�W
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;               -- �o�̓��b�Z�[�W
    lb_retcode         BOOLEAN         DEFAULT TRUE;               -- ���b�Z�[�W�o�͊֐��̖߂�l
--
  BEGIN
--
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf     =>    lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode    =>    lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg     =>    lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,lv_errmsg  --���[�U�[�E�G���[�E���b�Z�[�W
                      ,1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.LOG
                      ,lv_errbuf  --�G���[���b�Z�[�W
                      ,1
                    );
    END IF;
    -- �ُ�I���̏ꍇ�̌����Z�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --�Ώی����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    --���������o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
                  );
--
    --�G���[�����o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,1
                  );
--
    --�I�����b�Z�[�W
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     FND_FILE.OUTPUT
                    ,lv_out_msg
                    ,0
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
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK021A04C;
/
