CREATE OR REPLACE PACKAGE BODY XXCOI016A11R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A11R(body)
 * Description      : ���b�g�ʎ󕥎c���\�i�q�Ɂj
 * MD.050           : MD050_COI_016_A11_���b�g�ʎ󕥎c���\�i�q�Ɂj.doc
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_end               �I������(A-6)
 *  execute_svf            SVF�N��(A-5)
 *  ins_work_data          ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  get_monthly_data       ���b�g�ʎ󕥁i�����j�f�[�^�擾(A-3)
 *  get_daily_data         ���b�g�ʎ󕥁i�����j�f�[�^�擾(A-2)
 *  proc_init              ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/11/06    1.0   Y.Nagasue        �V�K�쐬
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
  old_date_expt                EXCEPTION; -- �ߋ����G���[
  in_para_expt                 EXCEPTION; -- ���̓p�����[�^�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOI016A11R'; -- �p�b�P�[�W��
  cv_xxcoi_short_name          CONSTANT VARCHAR2(5)   := 'XXCOI'; -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_msg_xxcoi1_00005          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00006          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00011          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
                                                  -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10460          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10460';
                                                  -- �Ώۓ�NULL�l�G���[
  cv_msg_xxcoi1_10461          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10461';
                                                  -- �Ώۓ����̓G���[
  cv_msg_xxcoi1_10462          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10462';
                                                  -- �Ώۓ����t�^�G���[
  cv_msg_xxcoi1_10463          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10463';
                                                  -- �Ώۓ��������G���[
  cv_msg_xxcoi1_10464          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10464';
                                                  -- �Ώی�NULL�l�G���[
  cv_msg_xxcoi1_10465          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10465';
                                                  -- �Ώی����̓G���[
  cv_msg_xxcoi1_10466          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10466';
                                                  -- �Ώی����t�^�G���[
  cv_msg_xxcoi1_10467          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10467';
                                                  -- �Ώی��������G���[
  cv_msg_xxcoi1_10116          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10116';
                                                  -- ���O�C�����[�U���_�R�[�h���o�G���[���b�Z�[�W
  cv_msg_xxcoi1_10468          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10468';
                                                  -- ���_�R�[�hNULL�`�F�b�N�G���[
  cv_msg_xxcoi1_10459          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10459';
                                                  -- ���b�g�ʎ󕥎c���\�i�q�Ɂj�R���J�����g���̓p�����[�^
  cv_msg_xxcoi1_10469          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10469';
                                                  -- �{�Џ��i�敪�擾�G���[
  cv_msg_xxcoi1_00026          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00026';
                                                  -- �݌ɉ�v���ԃX�e�[�^�X�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10451          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10451';
                                                  -- �݌Ɋm��󎚕����擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00008          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
                                                  -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_10119          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10119';
                                                  -- SVF�N���G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';        -- �v���t�@�C����
  cv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';   -- �݌ɑg�D�R�[�h
  cv_tkn_exe_type              CONSTANT VARCHAR2(20) := 'EXE_TYPE';       -- ���s�敪
  cv_tkn_exe_type_name         CONSTANT VARCHAR2(20) := 'EXE_TYPE_NAME';  -- ���s�敪����
  cv_tkn_target_date           CONSTANT VARCHAR2(20) := 'TARGET_DATE';    -- �Ώۓ�
  cv_tkn_target_month          CONSTANT VARCHAR2(20) := 'TARGET_MONTH';   -- �Ώی�
  cv_tkn_base_code             CONSTANT VARCHAR2(20) := 'BASE_CODE';      -- ���_�R�[�h
  cv_tkn_base_name             CONSTANT VARCHAR2(20) := 'BASE_NAME';      -- ���_��
  cv_tkn_subinv_code           CONSTANT VARCHAR2(20) := 'SUBINV_CODE';    -- �ۊǏꏊ�R�[�h
  cv_tkn_subinv_name           CONSTANT VARCHAR2(20) := 'SUBINV_NAME';    -- �ۊǏꏊ��
  cv_tkn_business_date         CONSTANT VARCHAR2(20) := 'BUSINESS_DATE';  -- �Ɩ����t
--
  -- �v���t�@�C����
  cv_xxcoi1_organization_code  CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:�݌ɑg�D�R�[�h
  cv_xxcoi1_inv_cl_character   CONSTANT VARCHAR2(50) := 'XXCOI1_INV_CL_CHARACTER';  -- XXCOI:�݌Ɋm��󎚕���
  cv_xxcos1_item_div_h         CONSTANT VARCHAR2(50) := 'XXCOS1_ITEM_DIV_H';        -- XXCOS:�{�Џ��i�敪
--
  -- �Q�ƃ^�C�v��
  ct_lot_rep_output_type       CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOI1_LOT_REP_OUTPUT_TYPE';
                                                                          -- ���b�g�ʎ󕥕\���s�敪
--
  -- SVF�p
  cv_pdf                       CONSTANT VARCHAR2(4)  := '.pdf';             -- �g���q�FPDF
  cv_output_mode_1             CONSTANT VARCHAR2(1)  := '1';                -- �o�͋敪�FPDF
  cv_frm_file                  CONSTANT VARCHAR2(20) := 'XXCOI016A11S.xml'; -- �t�H�[���l���t�@�C����
  cv_vrq_file                  CONSTANT VARCHAR2(20) := 'XXCOI016A11S.vrq'; -- �N�G���[�l���t�@�C����
--
  -- �X�e�[�^�X��
  -- ���̓p�����[�^.���s�敪
  cv_exe_type_10               CONSTANT VARCHAR2(2) := '10'; -- ����
  cv_exe_type_20               CONSTANT VARCHAR2(2) := '20'; -- ����
  -- �t���O
  cv_flag_y                    CONSTANT VARCHAR2(1)  := 'Y'; -- �t���O�FY
  cv_flag_n                    CONSTANT VARCHAR2(1)  := 'N'; -- �t���O�FN
  -- �ڋq�}�X�^
  ct_cust_status_a             CONSTANT hz_cust_accounts.status%TYPE               := 'A'; -- �X�e�[�^�X�FA
  ct_cust_class_code_1         CONSTANT hz_cust_accounts.customer_class_code%TYPE  := '1'; -- �ڋq�敪�F1
  -- �ۊǏꏊ�}�X�^
  ct_warehouse_flag_y          CONSTANT mtl_secondary_inventories.attribute14%TYPE := 'Y'; -- �q�ɊǗ��Ώۋ敪�F'Y'
  -- �Ǘ������_����
  cv_management_chk_1          CONSTANT VARCHAR2(1)  := '1'; -- �Ǘ������_
  cv_management_chk_0          CONSTANT VARCHAR2(1)  := '0'; -- ��Ǘ������_
  -- ����
  ct_lang                      CONSTANT mtl_category_sets_tl.language%TYPE := USERENV('LANG'); -- ����
--
  -- ���t�`��
  cv_yyyymmddhh24miss          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS'; -- ���t�`���FYYYY/MM/DD HH24:MI:SS
  cv_yyyymmdd                  CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';            -- ���t�`���FYYYY/MM/DD
  cv_yyyymmdd2                 CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              -- ���t�`���FYYYYMMDD
  cv_yyyymm                    CONSTANT VARCHAR2(6)  := 'YYYYMM';                -- ���t�`���FYYYYMM
  cv_yy                        CONSTANT VARCHAR2(2)  := 'YY';                    -- ���t�`���FYYYY
  cv_mm                        CONSTANT VARCHAR2(2)  := 'MM';                    -- ���t�`���FMM
  cv_dd                        CONSTANT VARCHAR2(2)  := 'DD';                    -- ���t�`���FDD
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����Ώۋ��_���i�[�p
  TYPE g_base_code_rtype IS RECORD(
    base_code hz_cust_accounts.account_number%TYPE -- ���_�R�[�h
  );
  TYPE g_base_code_ttype IS TABLE OF g_base_code_rtype INDEX BY BINARY_INTEGER;
  g_base_code_tab g_base_code_ttype;
--
  -- ���[���[�N�e�[�u���p
  TYPE g_lot_rec_work_ttype IS TABLE OF xxcoi_rep_lot_rec_ship_work%ROWTYPE INDEX BY BINARY_INTEGER;
  g_lot_rec_work_tab g_lot_rec_work_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p�ϐ�
  gt_exe_type                  fnd_lookup_values.lookup_code%TYPE;                      -- ���s�敪
  gv_target_date               VARCHAR2(30);                                            -- �Ώۓ�
  gv_target_month              VARCHAR2(6);                                             -- �Ώی�
  gt_login_base_code           hz_cust_accounts.account_number%TYPE;                    -- ���_
  gt_subinventory_code         mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ
--
  -- ���������擾�l
  gt_org_code                  mtl_parameters.organization_code%TYPE;               -- �݌ɑg�D�R�[�h
  gt_org_id                    mtl_parameters.organization_id%TYPE;                 -- �݌ɑg�DID
  gd_proc_date                 DATE;                                                -- �Ɩ����t
  gv_proc_date_char            VARCHAR2(11);                                        -- �Ɩ����t������
  gt_exe_type_meaning          fnd_lookup_values.meaning%TYPE;                      -- ���̓p�����[�^.���s�敪����
  gd_target_date               DATE;                                                -- ���̓p�����[�^DATE�^
  gt_base_code                 hz_cust_accounts.account_number%TYPE;                -- ���O�C�����[�U�������_�R�[�h
  gt_base_name                 hz_parties.party_name%TYPE;                          -- ���̓p�����[�^.���_��
  gt_subinv_name               mtl_secondary_inventories.description%TYPE;          -- �ۊǏꏊ��
  gt_item_div_h                fnd_profile_option_values.profile_option_value%TYPE; -- �v���t�@�C���l�F�{�Џ��i�敪
  gt_inv_cl_char               fnd_profile_option_values.profile_option_value%TYPE; -- �v���t�@�C���l�F�݌Ɋm�蕶��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �Ǘ������_���擾�J�[�\��
  CURSOR get_manage_base_cur(
    iv_base_code VARCHAR2                                  -- �����Ώۋ��_
  ) IS
    SELECT hca.account_number base_code                    -- ���_�R�[�h
    FROM   hz_cust_accounts    hca                         -- �ڋq�}�X�^
          ,xxcmm_cust_accounts xca                         -- �ڋq�ǉ����
    WHERE  hca.cust_account_id      = xca.customer_id
    AND    hca.customer_class_code  = ct_cust_class_code_1 -- �ڋq�敪�F���_
    AND    hca.status               = ct_cust_status_a     -- �X�e�[�^�X�F�L��
    AND    xca.management_base_code = iv_base_code         -- �����Ώۋ��_
  ;
  g_get_manage_base_rec get_manage_base_cur%ROWTYPE;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : �I������(A-6)
   ***********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_end'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    --==============================================================
    -- ���[�N�e�[�u���f�[�^�폜
    --==============================================================
    DELETE
    FROM   xxcoi_rep_lot_rec_ship_work xrlrsw
    WHERE  xrlrsw.request_id = cn_request_id
    ;
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
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_file_name VARCHAR2(200); -- �o�̓t�@�C����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- SVF�N���O�ɁACOMMIT���s
    --==============================================================
    COMMIT;
--
    --==============================================================
    -- SVF�N��
    --==============================================================
    -- �t�@�C�����ݒ�
    lv_file_name := cv_pkg_name || TO_CHAR( SYSDATE, cv_yyyymmdd2 ) || TO_CHAR( cn_request_id ) || cv_pdf;
--
    -- ���ʊ֐����s
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode      => lv_retcode               -- ���^�[���R�[�h
     ,ov_errbuf       => lv_errbuf                -- �G���[���b�Z�[�W
     ,ov_errmsg       => lv_errmsg                -- ���[�U�[�E�G���[���b�Z�[�W
     ,iv_conc_name    => cv_pkg_name              -- �R���J�����g��
     ,iv_file_name    => lv_file_name             -- �o�̓t�@�C����
     ,iv_file_id      => cv_pkg_name              -- ���[ID
     ,iv_output_mode  => cv_output_mode_1         -- �o�͋敪
     ,iv_frm_file     => cv_frm_file              -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_vrq_file              -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id        -- ORG_ID
     ,iv_user_name    => fnd_global.user_name     -- ���O�C���E���[�U��
     ,iv_resp_name    => fnd_global.resp_name     -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                     -- ������
     ,iv_printer_name => NULL                     -- �v�����^��
     ,iv_request_id   => TO_CHAR( cn_request_id ) -- �v��ID
     ,iv_nodata_msg   => NULL                     -- �f�[�^�Ȃ����b�Z�[�W
    );
    -- �G���[����
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_10119
                   );
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work_data(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_data'; -- �v���O������
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
    lv_no_data_msg    VARCHAR2(1000);                                    -- �Ώ�0�����b�Z�[�W
    lt_practice_year  xxcoi_rep_lot_rec_ship_work.practice_year%TYPE;  -- �Ώ۔N
    lt_practice_month xxcoi_rep_lot_rec_ship_work.practice_month%TYPE; -- �Ώی�
    lt_practice_day   xxcoi_rep_lot_rec_ship_work.practice_day%TYPE;   -- �Ώۓ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �Ώ�0��������
    --==============================================================
    -- ���[���[�N�e�[�u���p�e�[�u���^�ϐ��̌�����0���̏ꍇ
    IF ( g_lot_rec_work_tab.COUNT = 0 ) THEN
      -- ----------------------------------
      -- �Ώ�0�����b�Z�[�W���Z�b�g
      -- ----------------------------------
      lv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcoi_short_name
                         ,iv_name         => cv_msg_xxcoi1_00008
                        );
--
      -- ----------------------------------
      -- ���_�A�ۊǏꏊ���Z�b�g
      -- ----------------------------------
      g_lot_rec_work_tab(1).base_code         := NVL( gt_login_base_code, gt_base_code ); -- ���_�R�[�h
      g_lot_rec_work_tab(1).base_name         := gt_base_name;                            -- ���_��
      g_lot_rec_work_tab(1).subinventory_code := gt_subinventory_code;                    -- �ۊǏꏊ�R�[�h
      g_lot_rec_work_tab(1).subinventory_name := gt_subinv_name;                          -- �ۊǏꏊ��
--
    -- 0���ȊO�̏ꍇ�́A�Ώ�0�����b�Z�[�W��NULL���Z�b�g
    ELSE
      lv_no_data_msg := NULL;
    END IF;
--
    --==============================================================
    -- ���b�g�ʒI���E�󕥊m�F�\(�q��)���[���[�N�e�[�u���쐬
    --==============================================================
    -- ----------------------------------
    -- �Ώ۔N�E�Ώی��E�Ώۓ��ݒ�
    -- ----------------------------------
    lt_practice_year  := TO_CHAR( gd_target_date, cv_yy ); -- �Ώ۔N
    lt_practice_month := TO_CHAR( gd_target_date, cv_mm ); -- �Ώی�
    -- �����̏ꍇ
    IF ( gt_exe_type = cv_exe_type_10 ) THEN
      lt_practice_day := TO_CHAR( gd_target_date, cv_dd ); -- �Ώۓ�
    -- �����̏ꍇ
    ELSE
      lt_practice_day := NULL;                             -- �Ώۓ�
    END IF;
--
    -- ���[���[�N�e�[�u���p�e�[�u���^�ϐ��̌��������f�[�^�s�쐬
    <<ins_work_data_loop>>
    FOR i IN 1..g_lot_rec_work_tab.COUNT LOOP
      INSERT INTO xxcoi_rep_lot_rec_ship_work(
        execute_type                                  -- ���s�敪
       ,practice_year                                 -- �Ώ۔N
       ,practice_month                                -- �Ώی�
       ,practice_day                                  -- �Ώۓ�
       ,base_code                                     -- ���_�R�[�h
       ,base_name                                     -- ���_��
       ,subinventory_code                             -- �ۊǏꏊ�R�[�h
       ,subinventory_name                             -- �ۊǏꏊ��
       ,inv_cl_char                                   -- �݌Ɋm��󎚕���
       ,item_type                                     -- ���i�敪
       ,gun_code                                      -- �Q�R�[�h
       ,child_item_code                               -- �q���i�R�[�h
       ,child_item_name                               -- �q���i��
       ,taste_term                                    -- �ܖ�����
       ,difference_summary_code                       -- �ŗL�L��
       ,location_code                                 -- ���P�[�V�����R�[�h
       ,location_name                                 -- ���P�[�V������
       ,month_begin_quantity                          -- ����I����
       ,factory_stock                                 -- �H�����
       ,change_stock                                  -- �q�֓���
       ,truck_stock                                   -- �c�ƎԂ�����
       ,truck_ship                                    -- �c�ƎԂ֏o��
       ,sales_shipped                                 -- ����o��
       ,support                                       -- ���^���{
       ,removed_goods                                 -- �p�p�o��
       ,change_ship                                   -- �q�֏o��
       ,factory_return                                -- �H��ԕi
       ,location_move                                 -- ���P�[�V�����ړ�
       ,inv_adjust                                    -- �݌ɒ���
       ,book_inventory_quantity                       -- ����݌�
       ,message                                       -- ���b�Z�[�W
       ,created_by                                    -- �쐬��
       ,creation_date                                 -- �쐬��
       ,last_updated_by                               -- �ŏI�X�V��
       ,last_update_date                              -- �ŏI�X�V��
       ,last_update_login                             -- �ŏI�X�V���O�C��
       ,request_id                                    -- �v��ID
       ,program_application_id                        -- �A�v���P�[�V����ID
       ,program_id                                    -- �v���O����ID
       ,program_update_date                           -- �v���O�����X�V��
      )VALUES(
        gt_exe_type_meaning                           -- ���s�敪
       ,lt_practice_year                              -- �Ώ۔N
       ,lt_practice_month                             -- �Ώی�
       ,lt_practice_day                               -- �Ώۓ�
       ,g_lot_rec_work_tab(i).base_code               -- ���_�R�[�h
       ,g_lot_rec_work_tab(i).base_name               -- ���_��
       ,g_lot_rec_work_tab(i).subinventory_code       -- �ۊǏꏊ�R�[�h
       ,g_lot_rec_work_tab(i).subinventory_name       -- �ۊǏꏊ��
       ,gt_inv_cl_char                                -- �݌Ɋm��󎚕���
       ,g_lot_rec_work_tab(i).item_type               -- ���i�敪
       ,g_lot_rec_work_tab(i).gun_code                -- �Q�R�[�h
       ,g_lot_rec_work_tab(i).child_item_code         -- �q���i�R�[�h
       ,g_lot_rec_work_tab(i).child_item_name         -- �q���i��
       ,g_lot_rec_work_tab(i).taste_term              -- �ܖ�����
       ,g_lot_rec_work_tab(i).difference_summary_code -- �ŗL�L��
       ,g_lot_rec_work_tab(i).location_code           -- ���P�[�V�����R�[�h
       ,g_lot_rec_work_tab(i).location_name           -- ���P�[�V������
       ,g_lot_rec_work_tab(i).month_begin_quantity    -- ����I����
       ,g_lot_rec_work_tab(i).factory_stock           -- �H�����
       ,g_lot_rec_work_tab(i).change_stock            -- �q�֓���
       ,g_lot_rec_work_tab(i).truck_stock             -- �c�ƎԂ�����
       ,g_lot_rec_work_tab(i).truck_ship              -- �c�ƎԂ֏o��
       ,g_lot_rec_work_tab(i).sales_shipped           -- ����o��
       ,g_lot_rec_work_tab(i).support                 -- ���^���{
       ,g_lot_rec_work_tab(i).removed_goods           -- �p�p�o��
       ,g_lot_rec_work_tab(i).change_ship             -- �q�֏o��
       ,g_lot_rec_work_tab(i).factory_return          -- �H��ԕi
       ,g_lot_rec_work_tab(i).location_move           -- ���P�[�V�����ړ�
       ,g_lot_rec_work_tab(i).inv_adjust              -- �݌ɒ���
       ,g_lot_rec_work_tab(i).book_inventory_quantity -- ����݌�
       ,lv_no_data_msg                                -- ���b�Z�[�W
       ,cn_created_by                                 -- �쐬��
       ,cd_creation_date                              -- �쐬��
       ,cn_last_updated_by                            -- �ŏI�X�V��
       ,cd_last_update_date                           -- �ŏI�X�V��
       ,cn_last_update_login                          -- �ŏI�X�V���O�C��
       ,cn_request_id                                 -- �v��ID
       ,cn_program_application_id                     -- �A�v���P�[�V����ID
       ,cn_program_id                                 -- �v���O����ID
       ,cd_program_update_date                        -- �v���O�����X�V��
      );
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP ins_work_data_loop;
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
  END ins_work_data;
--
  /**********************************************************************************
   * Procedure Name   : get_monthly_data
   * Description      : ���b�g�ʎ󕥁i�����j�f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_monthly_data(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_monthly_data'; -- �v���O������
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
    ln_dummy NUMBER; -- ���b�g�ʎ�(����)���݃`�F�b�N
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���b�g�ʎ�(����)���J�[�\��
    CURSOR get_monthly_data_cur(
      iv_base_code VARCHAR2 -- �Ώۋ��_
    )IS
      SELECT xlrm.base_code                    base_code               -- ���_�R�[�h
            ,hp.party_name                     party_name              -- �p�[�e�B��
            ,xlrm.subinventory_code            subinventory_code       -- �ۊǏꏊ�R�[�h
            ,msi.description                   subinventory_name       -- �ۊǏꏊ��
            ,mcb.segment1                      item_type               -- ���i�敪
            ,SUBSTRB(
               (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date -- �E�v�J�n��>�Ɩ����t
                 THEN iimb.attribute1 -- �Q�R�[�h(��)
                 ELSE iimb.attribute2 -- �Q�R�[�h(�V)
               END) ,1 ,3 )                    gun_code                -- �Q�R�[�h
            ,msib.segment1                     item_code               -- �q�i�ڃR�[�h
            ,ximb.item_short_name              item_name               -- �q�i�ږ�
            ,xlrm.lot                          lot                     -- ���b�g
            ,xlrm.difference_summary_code      diff_sum_code           -- �ŗL�L��
            ,xlrm.location_code                location_code           -- ���P�[�V�����R�[�h
            ,xwlmv.location_name               location_name           -- ���P�[�V������
            ,SUM(xlrm.month_begin_quantity)    month_begin_quantity    -- �����I����
            ,SUM(xlrm.factory_stock)           factory_stock           -- �H�����
            ,SUM(xlrm.factory_stock_b)         factory_stock_b         -- �H����ɐU��
            ,SUM(xlrm.change_stock)            change_stock            -- �q�֓���
            ,SUM(xlrm.others_stock)            others_stock            -- ���o�ɁQ���̑�����
            ,SUM(xlrm.truck_stock)             truck_stock             -- �c�ƎԂ�����
            ,SUM(xlrm.truck_ship)              truck_ship              -- �c�ƎԂ֏o��
            ,SUM(xlrm.sales_shipped)           sales_shipped           -- ����o��
            ,SUM(xlrm.sales_shipped_b)         sales_shipped_b         -- ����o�ɐU��
            ,SUM(xlrm.return_goods)            return_goods            -- �ԕi
            ,SUM(xlrm.return_goods_b)          return_goods_b          -- �ԕi�U��
            ,SUM(xlrm.customer_sample_ship)    customer_sample_ship    -- �ڋq���{�o��
            ,SUM(xlrm.customer_sample_ship_b)  customer_sample_ship_b  -- �ڋq���{�o�ɐU��
            ,SUM(xlrm.customer_support_ss)     customer_support_ss     -- �ڋq���^���{�o��
            ,SUM(xlrm.customer_support_ss_b)   customer_support_ss_b   -- �ڋq���^���{�o�ɐU��
            ,SUM(xlrm.ccm_sample_ship)         ccm_sample_ship         -- �ڋq�L����`��A���Џ��i
            ,SUM(xlrm.ccm_sample_ship_b)       ccm_sample_ship_b       -- �ڋq�L����`��A���Џ��i�U��
            ,SUM(xlrm.vd_supplement_stock)     vd_supplement_stock     -- ����VD��[����
            ,SUM(xlrm.vd_supplement_ship)      vd_supplement_ship      -- ����VD��[�o��
            ,SUM(xlrm.removed_goods)           removed_goods           -- �p�p
            ,SUM(xlrm.removed_goods_b)         removed_goods_b         -- �p�p�U��
            ,SUM(xlrm.change_ship)             change_ship             -- �q�֏o��
            ,SUM(xlrm.others_ship)             others_ship             -- ���o�ɁQ���̑��o��
            ,SUM(xlrm.factory_change)          factory_change          -- �H��q��
            ,SUM(xlrm.factory_change_b)        factory_change_b        -- �H��q�֐U��
            ,SUM(xlrm.factory_return)          factory_return          -- �H��ԕi
            ,SUM(xlrm.factory_return_b)        factory_return_b        -- �H��ԕi�U��
            ,SUM(xlrm.location_decrease)       location_decrease       -- ���P�[�V�����ړ���
            ,SUM(xlrm.location_increase)       location_increase       -- ���P�[�V�����ړ���
            ,SUM(xlrm.adjust_decrease)         adjust_decrease         -- �݌ɒ�����
            ,SUM(xlrm.adjust_increase)         adjust_increase         -- �݌ɒ�����
            ,SUM(xlrm.book_inventory_quantity) book_inventory_quantity -- ����݌ɐ�
      FROM   xxcoi_lot_reception_monthly       xlrm                    -- ���b�g�ʎ�(����)
            ,hz_cust_accounts                  hca                     -- �ڋq�}�X�^
            ,hz_parties                        hp                      -- �p�[�e�B�}�X�^
            ,mtl_secondary_inventories         msi                     -- �ۊǏꏊ�}�X�^
            ,mtl_system_items_b                msib                    -- Disc�i�ڃ}�X�^
            ,ic_item_mst_b                     iimb                    -- OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b                  ximb                    -- OPM�i�ڃ}�X�^�A�h�I��
            ,mtl_categories_b                  mcb                     -- �i�ڃJ�e�S���}�X�^
            ,mtl_item_categories               mic                     -- �i�ڃJ�e�S���}�X�^����
            ,mtl_category_sets_b               mcsb                    -- �i�ڃJ�e�S���Z�b�g
            ,mtl_category_sets_tl              mcst                    -- �i�ڃJ�e�S���Z�b�g���{��
            ,xxcoi_warehouse_location_mst_v    xwlmv                   -- �q�Ƀ��P�[�V�����}�X�^
      WHERE  xlrm.practice_month     = gv_target_month                 -- ���̓p�����[�^.�N��
      AND    xlrm.base_code          = iv_base_code                    -- ���_�R�[�h
      AND    xlrm.subinventory_code  = NVL( gt_subinventory_code, xlrm.subinventory_code )
                                                                       -- ���̓p�����[�^.�ۊǏꏊ
      AND    xlrm.organization_id    = gt_org_id                       -- �݌ɑg�DID
      AND    xlrm.base_code          = hca.account_number
      AND    hca.customer_class_code = ct_cust_class_code_1            -- �ڋq�敪�F���_
      AND    hca.status              = ct_cust_status_a                -- �X�e�[�^�X�F�L��
      AND    hca.party_id            = hp.party_id 
      AND    xlrm.subinventory_code  = msi.secondary_inventory_name
      AND    xlrm.organization_id    = msi.organization_id
      AND    msi.attribute14         = ct_warehouse_flag_y             -- �q�ɊǗ��Ώ�
      AND    xlrm.child_item_id      = msib.inventory_item_id
      AND    xlrm.organization_id    = msib.organization_id
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    gd_proc_date BETWEEN ximb.start_date_active 
                              AND ximb.end_date_active                 -- �L����
      AND    msib.inventory_item_id  = mic.inventory_item_id
      AND    msib.organization_id    = mic.organization_id
      AND    mic.category_id         = mcb.category_id
      AND    mic.category_set_id     = mcsb.category_set_id
      AND    mcsb.category_set_id    = mcst.category_set_id
      AND    mcst.language           = ct_lang                         -- ����
      AND    mcst.category_set_name  = gt_item_div_h                   -- �v���t�@�C���l�F�{�Џ��i�敪
      AND    xlrm.organization_id    = xwlmv.organization_id(+)
      AND    xlrm.base_code          = xwlmv.base_code(+)
      AND    xlrm.subinventory_code  = xwlmv.subinventory_code(+)
      AND    xlrm.location_code      = xwlmv.location_code(+)
      GROUP BY
         xlrm.base_code                                                -- ���_�R�[�h
        ,hp.party_name                                                 -- �p�[�e�B��
        ,xlrm.subinventory_code                                        -- �ۊǏꏊ�R�[�h
        ,msi.description                                               -- �ۊǏꏊ��
        ,mcb.segment1                                                  -- ���i�敪
        ,SUBSTRB(
           (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date
             THEN iimb.attribute1
             ELSE iimb.attribute2
           END) ,1 ,3 )                                                -- �Q�R�[�h
        ,msib.segment1                                                 -- �q�i�ڃR�[�h
        ,ximb.item_short_name                                          -- �q�i�ږ�
        ,xlrm.lot                                                      -- ���b�g
        ,xlrm.difference_summary_code                                  -- �ŗL�L��
        ,xlrm.location_code                                            -- ���P�[�V�����R�[�h
        ,xwlmv.location_name                                           -- ���P�[�V������
    ;
--
    -- *** ���[�J���E���R�[�h ***
    -- ���b�g�ʎ�(����)��񃌃R�[�h
    l_get_monthly_data_rec get_monthly_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    g_base_code_tab.DELETE; -- �����Ώۋ��_���i�[�p�e�[�u���^
--
    --==============================================================
    -- �Ǘ������_���擾
    --==============================================================
    -- �Ǘ������_���擾�J�[�\���I�[�v��
    OPEN get_manage_base_cur(
      iv_base_code => NVL( gt_login_base_code, gt_base_code ) -- ���̓p�����[�^or���O�C�����[�U�������_
    );
--
    <<manage_base_loop>>
    LOOP
      -- �Ǘ������_���t�F�b�`
      FETCH get_manage_base_cur INTO g_get_manage_base_rec;
      EXIT WHEN get_manage_base_cur%NOTFOUND;
--
      -- ���b�g�ʎ�(����)���݃`�F�b�N������
      ln_dummy := 0;
--
      -- --------------------------------
      -- ���b�g�ʎ�(����)���݃`�F�b�N
      -- --------------------------------
      SELECT COUNT(1)
      INTO   ln_dummy
      FROM   mtl_secondary_inventories msi
            ,xxcoi_lot_reception_monthly xlrm
      WHERE  msi.attribute14              = ct_warehouse_flag_y             -- �q�ɊǗ��Ώ�
      AND    msi.organization_id          = gt_org_id                       -- �݌ɑg�DID
      AND    msi.secondary_inventory_name = xlrm.subinventory_code
      AND    msi.organization_id          = xlrm.organization_id
      AND    xlrm.base_code               = g_get_manage_base_rec.base_code -- ���_�R�[�h
      AND    xlrm.practice_date           = gd_target_date                  -- ���̓p�����[�^.�N����
      AND    ROWNUM                       = 1
      ;
      -- ---------------------------------------
      -- ���݂���ꍇ�́A�����Ώۋ��_�Ƃ��ĕێ�
      -- ---------------------------------------
      IF ( ln_dummy > 0 ) THEN
        g_base_code_tab(g_base_code_tab.COUNT + 1).base_code := g_get_manage_base_rec.base_code;
      END IF;
--
    END LOOP manage_base_loop;
    -- �Ǘ������_���擾�J�[�\���N���[�Y
    CLOSE get_manage_base_cur;
--
    -- �Ǘ������_���擾���擾�ł��Ă��Ȃ��ꍇ�A���̓p�����[�^.���_�������ΏۂƂ���
    IF ( g_base_code_tab.COUNT = 0 ) THEN
      g_base_code_tab(1).base_code := gt_login_base_code;
    END IF;
--
    --==============================================================
    -- ���b�g�ʎ�(����)���擾
    --==============================================================
    -- ---------------------------------------
    -- �����Ώۋ��_�̌����������s
    -- ---------------------------------------
    <<get_monthly_data_loop>>
    FOR i IN 1..g_base_code_tab.COUNT LOOP
      -- �����Ώۋ��_���Z�b�g���J�[�\���I�[�v��
      OPEN get_monthly_data_cur(
        iv_base_code => g_base_code_tab(i).base_code -- �����Ώۋ��_
      );
--
      -- �擾���������g�p���A���[���[�N�e�[�u���f�[�^���i�[����
      <<set_work_tbl_data_loop>>
      LOOP
--
        -- �f�[�^�t�F�b�`
        FETCH get_monthly_data_cur INTO l_get_monthly_data_rec;
        EXIT WHEN get_monthly_data_cur%NOTFOUND;
--
        -- �����J�E���g
        gn_target_cnt := gn_target_cnt + 1; -- ��������
--
        --==============================================================
        -- �擾�����l�𒠕[���[�N�e�[�u���p�e�[�u���^�ϐ��Ƀf�[�^���Z�b�g
        --==============================================================
        -- ���_�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).base_code
          := l_get_monthly_data_rec.base_code;
--
        -- ���_��
        g_lot_rec_work_tab(gn_target_cnt).base_name
          := l_get_monthly_data_rec.party_name;
--
        -- �ۊǏꏊ�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).subinventory_code
          := l_get_monthly_data_rec.subinventory_code;
--
        -- �ۊǏꏊ��
        g_lot_rec_work_tab(gn_target_cnt).subinventory_name
          := l_get_monthly_data_rec.subinventory_name;
--
        -- ���i�敪
        g_lot_rec_work_tab(gn_target_cnt).item_type
          := l_get_monthly_data_rec.item_type;
--
        -- �Q�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).gun_code
          := l_get_monthly_data_rec.gun_code;
--
        -- �q�i�ڃR�[�h
        g_lot_rec_work_tab(gn_target_cnt).child_item_code
          := l_get_monthly_data_rec.item_code;
--
        -- �q�i�ږ�
        g_lot_rec_work_tab(gn_target_cnt).child_item_name
          := l_get_monthly_data_rec.item_name;
--
        -- ���b�g(�ܖ�����)
        g_lot_rec_work_tab(gn_target_cnt).taste_term
          := l_get_monthly_data_rec.lot;
--
        -- �ŗL�L��
        g_lot_rec_work_tab(gn_target_cnt).difference_summary_code
          := l_get_monthly_data_rec.diff_sum_code;
--
        -- ���P�[�V�����R�[�h
        g_lot_rec_work_tab(gn_target_cnt).location_code
          := l_get_monthly_data_rec.location_code;
--
        -- ���P�[�V������
        g_lot_rec_work_tab(gn_target_cnt).location_name
          := l_get_monthly_data_rec.location_name;
--
        -- ����I����
        g_lot_rec_work_tab(gn_target_cnt).month_begin_quantity
          := l_get_monthly_data_rec.month_begin_quantity;
--
        -- �H�����
        g_lot_rec_work_tab(gn_target_cnt).factory_stock
          := l_get_monthly_data_rec.factory_stock            -- �H�����
           - l_get_monthly_data_rec.factory_stock_b          -- �H����ɐU��
        ;
--
        -- �q�֓���
        g_lot_rec_work_tab(gn_target_cnt).change_stock
          := l_get_monthly_data_rec.change_stock             -- �q�֓���
           + l_get_monthly_data_rec.others_stock             -- ���o��_���̑�����
           + l_get_monthly_data_rec.vd_supplement_stock      -- ����VD��[����
        ;
--
        -- �c�ƎԂ�����
        g_lot_rec_work_tab(gn_target_cnt).truck_stock
          := l_get_monthly_data_rec.truck_stock              -- �c�ƎԂ�����
        ;
--
        -- �c�ƎԂ֏o��
        g_lot_rec_work_tab(gn_target_cnt).truck_ship
          := l_get_monthly_data_rec.truck_ship               -- �c�ƎԂ֏o��
        ;
--
        -- ����o��
        g_lot_rec_work_tab(gn_target_cnt).sales_shipped
          := l_get_monthly_data_rec.sales_shipped            -- ����o��
           - l_get_monthly_data_rec.sales_shipped_b          -- ����o�ɐU��
           - l_get_monthly_data_rec.return_goods             -- �ԕi
           + l_get_monthly_data_rec.return_goods_b           -- �ԕi�U��
        ;
--
        -- ���^���{
        g_lot_rec_work_tab(gn_target_cnt).support
          := l_get_monthly_data_rec.customer_sample_ship     -- �ڋq���{�o��
           - l_get_monthly_data_rec.customer_sample_ship_b   -- �ڋq���{�o�ɐU��
           + l_get_monthly_data_rec.customer_support_ss      -- �ڋq���^���{�o��
           - l_get_monthly_data_rec.customer_support_ss_b    -- �ڋq���^���{�o�ɐU��
           + l_get_monthly_data_rec.ccm_sample_ship          -- �ڋq�L����`��A���Џ��i
           - l_get_monthly_data_rec.ccm_sample_ship_b        -- �ڋq�L����`��A���Џ��i�U��
        ;
--
        -- �p�p�o��
        g_lot_rec_work_tab(gn_target_cnt).removed_goods
          := l_get_monthly_data_rec.removed_goods            -- �p�p
           - l_get_monthly_data_rec.removed_goods_b          -- �p�p�U��
        ;
--
        -- �q�֏o��
        g_lot_rec_work_tab(gn_target_cnt).change_ship
          := l_get_monthly_data_rec.change_ship              -- �q�֏o��
           + l_get_monthly_data_rec.others_ship              -- ���o�ɁQ���̑��o��
           + l_get_monthly_data_rec.factory_change           -- �H��q��
           - l_get_monthly_data_rec.factory_change_b         -- �H��q�֐U��
           + l_get_monthly_data_rec.vd_supplement_ship       -- ����VD��[�o��
        ;
--
        -- �H��ԕi
        g_lot_rec_work_tab(gn_target_cnt).factory_return
          := l_get_monthly_data_rec.factory_return           -- �H��ԕi
           - l_get_monthly_data_rec.factory_return_b         -- �H��ԕi�U��
        ;
--
        -- ���P�[�V�����ړ�
        g_lot_rec_work_tab(gn_target_cnt).location_move
          := l_get_monthly_data_rec.location_decrease        -- ���P�[�V�����ړ���
           - l_get_monthly_data_rec.location_increase        -- ���P�[�V�����ړ���
        ;
--
        -- �݌ɒ���
        g_lot_rec_work_tab(gn_target_cnt).inv_adjust
          := l_get_monthly_data_rec.adjust_decrease          -- �݌ɒ�����
           - l_get_monthly_data_rec.adjust_increase          -- �݌ɒ�����
        ;
--
        -- ����݌�
        g_lot_rec_work_tab(gn_target_cnt).book_inventory_quantity
          := l_get_monthly_data_rec.book_inventory_quantity; -- ����݌ɐ�
--
      END LOOP set_work_tbl_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE get_monthly_data_cur;
--
    END LOOP get_monthly_data_loop;
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
      -- �J�[�\���N���[�Y
      IF ( get_manage_base_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
      IF ( get_monthly_data_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_monthly_data;
--
  /**********************************************************************************
   * Procedure Name   : get_daily_data
   * Description      : ���b�g�ʎ�(����)�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_daily_data(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_daily_data'; -- �v���O������
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
    ln_dummy NUMBER; -- ���b�g�ʎ�(����)���݃`�F�b�N
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���b�g�ʎ�(����)���J�[�\��
    CURSOR get_daily_data_cur(
      iv_base_code VARCHAR2 -- �Ώۋ��_
    )IS
      SELECT xlrd.base_code                   base_code                   -- ���_�R�[�h
            ,hp.party_name                    party_name                  -- �p�[�e�B��
            ,xlrd.subinventory_code           subinventory_code           -- �ۊǏꏊ�R�[�h
            ,msi.description                  subinventory_name           -- �ۊǏꏊ��
            ,mcb.segment1                     item_type                   -- ���i�敪
            ,SUBSTRB(
               (CASE WHEN (TO_DATE( iimb.attribute3, cv_yyyymmdd ) ) > gd_proc_date -- �E�v�J�n��>�Ɩ����t
                 THEN iimb.attribute1 -- �Q�R�[�h(��)
                 ELSE iimb.attribute2 -- �Q�R�[�h(�V)
               END) ,1 ,3 )                   gun_code                    -- �Q�R�[�h
            ,msib.segment1                    item_code                   -- �q�i�ڃR�[�h
            ,ximb.item_short_name             item_name                   -- �q�i�ږ�
            ,xlrd.lot                         lot                         -- ���b�g
            ,xlrd.difference_summary_code     diff_sum_code               -- �ŗL�L��
            ,xlrd.location_code               location_code               -- ���P�[�V�����R�[�h
            ,xwlmv.location_name              location_name               -- ���P�[�V������
            ,xlrd.previous_inventory_quantity previous_inventory_quantity -- �O���݌ɐ�
            ,xlrd.factory_stock               factory_stock               -- �H�����
            ,xlrd.factory_stock_b             factory_stock_b             -- �H����ɐU��
            ,xlrd.change_stock                change_stock                -- �q�֓���
            ,xlrd.others_stock                others_stock                -- ���o�ɁQ���̑�����
            ,xlrd.truck_stock                 truck_stock                 -- �c�ƎԂ�����
            ,xlrd.truck_ship                  truck_ship                  -- �c�ƎԂ֏o��
            ,xlrd.sales_shipped               sales_shipped               -- ����o��
            ,xlrd.sales_shipped_b             sales_shipped_b             -- ����o�ɐU��
            ,xlrd.return_goods                return_goods                -- �ԕi
            ,xlrd.return_goods_b              return_goods_b              -- �ԕi�U��
            ,xlrd.customer_sample_ship        customer_sample_ship        -- �ڋq���{�o��
            ,xlrd.customer_sample_ship_b      customer_sample_ship_b      -- �ڋq���{�o�ɐU��
            ,xlrd.customer_support_ss         customer_support_ss         -- �ڋq���^���{�o��
            ,xlrd.customer_support_ss_b       customer_support_ss_b       -- �ڋq���^���{�o�ɐU��
            ,xlrd.ccm_sample_ship             ccm_sample_ship             -- �ڋq�L����`��A���Џ��i
            ,xlrd.ccm_sample_ship_b           ccm_sample_ship_b           -- �ڋq�L����`��A���Џ��i�U��
            ,xlrd.vd_supplement_stock         vd_supplement_stock         -- ����VD��[����
            ,xlrd.vd_supplement_ship          vd_supplement_ship          -- ����VD��[�o��
            ,xlrd.removed_goods               removed_goods               -- �p�p
            ,xlrd.removed_goods_b             removed_goods_b             -- �p�p�U��
            ,xlrd.change_ship                 change_ship                 -- �q�֏o��
            ,xlrd.others_ship                 others_ship                 -- ���o�ɁQ���̑��o��
            ,xlrd.factory_change              factory_change              -- �H��q��
            ,xlrd.factory_change_b            factory_change_b            -- �H��q�֐U��
            ,xlrd.factory_return              factory_return              -- �H��ԕi
            ,xlrd.factory_return_b            factory_return_b            -- �H��ԕi�U��
            ,xlrd.location_decrease           location_decrease           -- ���P�[�V�����ړ���
            ,xlrd.location_increase           location_increase           -- ���P�[�V�����ړ���
            ,xlrd.adjust_decrease             adjust_decrease             -- �݌ɒ�����
            ,xlrd.adjust_increase             adjust_increase             -- �݌ɒ�����
            ,xlrd.book_inventory_quantity     book_inventory_quantity     -- ����݌ɐ�
      FROM   xxcoi_lot_reception_daily        xlrd                        -- ���b�g�ʎ�(����)
            ,hz_cust_accounts                 hca                         -- �ڋq�}�X�^
            ,hz_parties                       hp                          -- �p�[�e�B�}�X�^
            ,mtl_secondary_inventories        msi                         -- �ۊǏꏊ�}�X�^
            ,mtl_system_items_b               msib                        -- Disc�i�ڃ}�X�^
            ,ic_item_mst_b                    iimb                        -- OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b                 ximb                        -- OPM�i�ڃ}�X�^�A�h�I��
            ,mtl_categories_b                 mcb                         -- �i�ڃJ�e�S���}�X�^
            ,mtl_item_categories              mic                         -- �i�ڃJ�e�S���}�X�^����
            ,mtl_category_sets_b              mcsb                        -- �i�ڃJ�e�S���Z�b�g
            ,mtl_category_sets_tl             mcst                        -- �i�ڃJ�e�S���Z�b�g���{��
            ,xxcoi_warehouse_location_mst_v   xwlmv                       -- �q�Ƀ��P�[�V�����}�X�^
      WHERE  xlrd.practice_date      = gd_target_date                     -- ���̓p�����[�^.�N����
      AND    xlrd.base_code          = iv_base_code                       -- ���_�R�[�h
      AND    xlrd.subinventory_code  = NVL( gt_subinventory_code, xlrd.subinventory_code )
                                                                          -- ���̓p�����[�^.�ۊǏꏊ
      AND    xlrd.organization_id    = gt_org_id                          -- �݌ɑg�DID
      AND    xlrd.base_code          = hca.account_number
      AND    hca.customer_class_code = ct_cust_class_code_1               -- �ڋq�敪�F���_
      AND    hca.status              = ct_cust_status_a                   -- �X�e�[�^�X�F�L��
      AND    hca.party_id            = hp.party_id 
      AND    xlrd.subinventory_code  = msi.secondary_inventory_name
      AND    xlrd.organization_id    = msi.organization_id
      AND    msi.attribute14         = ct_warehouse_flag_y                -- �q�ɊǗ��Ώ�
      AND    xlrd.child_item_id      = msib.inventory_item_id
      AND    xlrd.organization_id    = msib.organization_id
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    gd_proc_date BETWEEN ximb.start_date_active 
                              AND ximb.end_date_active                    -- �L����
      AND    msib.inventory_item_id  = mic.inventory_item_id
      AND    msib.organization_id    = mic.organization_id
      AND    mic.category_id         = mcb.category_id
      AND    mic.category_set_id     = mcsb.category_set_id
      AND    mcsb.category_set_id    = mcst.category_set_id
      AND    mcst.language           = ct_lang                            -- ����
      AND    mcst.category_set_name  = gt_item_div_h                      -- �v���t�@�C���l�F�{�Џ��i�敪
      AND    xlrd.organization_id    = xwlmv.organization_id(+)
      AND    xlrd.base_code          = xwlmv.base_code(+)
      AND    xlrd.subinventory_code  = xwlmv.subinventory_code(+)
      AND    xlrd.location_code      = xwlmv.location_code(+)
    ;
--
    -- *** ���[�J���E���R�[�h ***
    -- ���b�g�ʎ�(����)��񃌃R�[�h
    l_get_daily_data_rec get_daily_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    g_base_code_tab.DELETE; -- �����Ώۋ��_���i�[�p�e�[�u���^
--
    --==============================================================
    -- �Ǘ������_���擾
    --==============================================================
    -- �Ǘ������_���擾�J�[�\���I�[�v��
    OPEN get_manage_base_cur(
      iv_base_code => NVL( gt_login_base_code, gt_base_code ) -- ���̓p�����[�^or���O�C�����[�U�������_
    );
--
    <<manage_base_loop>>
    LOOP
      -- �Ǘ������_���t�F�b�`
      FETCH get_manage_base_cur INTO g_get_manage_base_rec;
      EXIT WHEN get_manage_base_cur%NOTFOUND;
--
      -- ���b�g�ʎ�(����)���݃`�F�b�N������
      ln_dummy := 0;
--
      -- --------------------------------
      -- ���b�g�ʎ�(����)���݃`�F�b�N
      -- --------------------------------
      SELECT COUNT(1)
      INTO   ln_dummy
      FROM   mtl_secondary_inventories msi
            ,xxcoi_lot_reception_daily xlrd
      WHERE  msi.attribute14              = ct_warehouse_flag_y             -- �q�ɊǗ��Ώ�
      AND    msi.organization_id          = gt_org_id                       -- �݌ɑg�DID
      AND    msi.secondary_inventory_name = xlrd.subinventory_code
      AND    msi.organization_id          = xlrd.organization_id
      AND    xlrd.base_code               = g_get_manage_base_rec.base_code -- ���_�R�[�h
      AND    xlrd.practice_date           = gd_target_date                  -- ���̓p�����[�^.�N����
      AND    ROWNUM                       = 1
      ;
      -- ---------------------------------------
      -- ���݂���ꍇ�́A�����Ώۋ��_�Ƃ��ĕێ�
      -- ---------------------------------------
      IF ( ln_dummy > 0 ) THEN
        g_base_code_tab(g_base_code_tab.COUNT + 1).base_code := g_get_manage_base_rec.base_code;
      END IF;
--
    END LOOP manage_base_loop;
    -- �Ǘ������_���擾�J�[�\���N���[�Y
    CLOSE get_manage_base_cur;
--
    -- �Ǘ������_���擾���擾�ł��Ă��Ȃ��ꍇ�A���̓p�����[�^.���_�������ΏۂƂ���
    IF ( g_base_code_tab.COUNT = 0 ) THEN
      g_base_code_tab(1).base_code := gt_login_base_code;
    END IF;
--
    --==============================================================
    -- ���b�g�ʎ�(����)���擾
    --==============================================================
    -- ---------------------------------------
    -- �����Ώۋ��_�̌����������s
    -- ---------------------------------------
    <<get_daily_data_loop>>
    FOR i IN 1..g_base_code_tab.COUNT LOOP
      -- �����Ώۋ��_���Z�b�g���J�[�\���I�[�v��
      OPEN get_daily_data_cur(
        iv_base_code => g_base_code_tab(i).base_code -- �����Ώۋ��_
      );
--
      -- �擾���������g�p���A���[���[�N�e�[�u���f�[�^���i�[����
      <<set_work_tbl_data_loop>>
      LOOP
--
        -- �f�[�^�t�F�b�`
        FETCH get_daily_data_cur INTO l_get_daily_data_rec;
        EXIT WHEN get_daily_data_cur%NOTFOUND;
--
        -- �����J�E���g
        gn_target_cnt := gn_target_cnt + 1; -- ��������
--
        --==============================================================
        -- �擾�����l�𒠕[���[�N�e�[�u���p�e�[�u���^�ϐ��Ƀf�[�^���Z�b�g
        --==============================================================
        -- ���_�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).base_code
          := l_get_daily_data_rec.base_code;
--
        -- ���_��
        g_lot_rec_work_tab(gn_target_cnt).base_name
          := l_get_daily_data_rec.party_name;
--
        -- �ۊǏꏊ�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).subinventory_code
          := l_get_daily_data_rec.subinventory_code;
--
        -- �ۊǏꏊ��
        g_lot_rec_work_tab(gn_target_cnt).subinventory_name
          := l_get_daily_data_rec.subinventory_name;
--
        -- ���i�敪
        g_lot_rec_work_tab(gn_target_cnt).item_type
          := l_get_daily_data_rec.item_type;
--
        -- �Q�R�[�h
        g_lot_rec_work_tab(gn_target_cnt).gun_code
          := l_get_daily_data_rec.gun_code;
--
        -- �q�i�ڃR�[�h
        g_lot_rec_work_tab(gn_target_cnt).child_item_code
          := l_get_daily_data_rec.item_code;
--
        -- �q�i�ږ�
        g_lot_rec_work_tab(gn_target_cnt).child_item_name
          := l_get_daily_data_rec.item_name;
--
        -- ���b�g(�ܖ�����)
        g_lot_rec_work_tab(gn_target_cnt).taste_term
          := l_get_daily_data_rec.lot;
--
        -- �ŗL�L��
        g_lot_rec_work_tab(gn_target_cnt).difference_summary_code
          := l_get_daily_data_rec.diff_sum_code;
--
        -- ���P�[�V�����R�[�h
        g_lot_rec_work_tab(gn_target_cnt).location_code
          := l_get_daily_data_rec.location_code;
--
        -- ���P�[�V������
        g_lot_rec_work_tab(gn_target_cnt).location_name
          := l_get_daily_data_rec.location_name;
--
        -- ����I����
        g_lot_rec_work_tab(gn_target_cnt).month_begin_quantity
          := l_get_daily_data_rec.previous_inventory_quantity;
--
        -- �H�����
        g_lot_rec_work_tab(gn_target_cnt).factory_stock
          := l_get_daily_data_rec.factory_stock            -- �H�����
           - l_get_daily_data_rec.factory_stock_b          -- �H����ɐU��
        ;
--
        -- �q�֓���
        g_lot_rec_work_tab(gn_target_cnt).change_stock
          := l_get_daily_data_rec.change_stock             -- �q�֓���
           + l_get_daily_data_rec.others_stock             -- ���o��_���̑�����
           + l_get_daily_data_rec.vd_supplement_stock      -- ����VD��[����
        ;
--
        -- �c�ƎԂ�����
        g_lot_rec_work_tab(gn_target_cnt).truck_stock
          := l_get_daily_data_rec.truck_stock              -- �c�ƎԂ�����
        ;
--
        -- �c�ƎԂ֏o��
        g_lot_rec_work_tab(gn_target_cnt).truck_ship
          := l_get_daily_data_rec.truck_ship               -- �c�ƎԂ֏o��
        ;
--
        -- ����o��
        g_lot_rec_work_tab(gn_target_cnt).sales_shipped
          := l_get_daily_data_rec.sales_shipped            -- ����o��
           - l_get_daily_data_rec.sales_shipped_b          -- ����o�ɐU��
           - l_get_daily_data_rec.return_goods             -- �ԕi
           + l_get_daily_data_rec.return_goods_b           -- �ԕi�U��
        ;
--
        -- ���^���{
        g_lot_rec_work_tab(gn_target_cnt).support
          := l_get_daily_data_rec.customer_sample_ship     -- �ڋq���{�o��
           - l_get_daily_data_rec.customer_sample_ship_b   -- �ڋq���{�o�ɐU��
           + l_get_daily_data_rec.customer_support_ss      -- �ڋq���^���{�o��
           - l_get_daily_data_rec.customer_support_ss_b    -- �ڋq���^���{�o�ɐU��
           + l_get_daily_data_rec.ccm_sample_ship          -- �ڋq�L����`��A���Џ��i
           - l_get_daily_data_rec.ccm_sample_ship_b        -- �ڋq�L����`��A���Џ��i�U��
        ;
--
        -- �p�p�o��
        g_lot_rec_work_tab(gn_target_cnt).removed_goods
          := l_get_daily_data_rec.removed_goods            -- �p�p
           - l_get_daily_data_rec.removed_goods_b          -- �p�p�U��
        ;
--
        -- �q�֏o��
        g_lot_rec_work_tab(gn_target_cnt).change_ship
          := l_get_daily_data_rec.change_ship              -- �q�֏o��
           + l_get_daily_data_rec.others_ship              -- ���o�ɁQ���̑��o��
           + l_get_daily_data_rec.factory_change           -- �H��q��
           - l_get_daily_data_rec.factory_change_b         -- �H��q�֐U��
           + l_get_daily_data_rec.vd_supplement_ship       -- ����VD��[�o��
        ;
--
        -- �H��ԕi
        g_lot_rec_work_tab(gn_target_cnt).factory_return
          := l_get_daily_data_rec.factory_return           -- �H��ԕi
           - l_get_daily_data_rec.factory_return_b         -- �H��ԕi�U��
        ;
--
        -- ���P�[�V�����ړ�
        g_lot_rec_work_tab(gn_target_cnt).location_move
          := l_get_daily_data_rec.location_decrease        -- ���P�[�V�����ړ���
           - l_get_daily_data_rec.location_increase        -- ���P�[�V�����ړ���
        ;
--
        -- �݌ɒ���
        g_lot_rec_work_tab(gn_target_cnt).inv_adjust
          := l_get_daily_data_rec.adjust_decrease          -- �݌ɒ�����
           - l_get_daily_data_rec.adjust_increase          -- �݌ɒ�����
        ;
--
        -- ����݌�
        g_lot_rec_work_tab(gn_target_cnt).book_inventory_quantity
          := l_get_daily_data_rec.book_inventory_quantity; -- ����݌ɐ�
--
      END LOOP set_work_tbl_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE get_daily_data_cur;
--
    END LOOP get_daily_data_loop;
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
      -- �J�[�\���N���[�Y
      IF ( get_manage_base_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
      IF ( get_daily_data_cur%ISOPEN ) THEN
        CLOSE get_manage_base_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_manage_base_flag VARCHAR2(1);                                -- �Ǘ������_�t���O
    lb_status           boolean;                                    -- �݌ɉ�v���ԃX�e�[�^�X
    lv_in_para_err      VARCHAR2(5000);                             -- ���̓p�����[�^�`�F�b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    -- �O���[�o���ϐ�
    gt_org_code         := NULL; -- �݌ɑg�D�R�[�h
    gt_org_id           := NULL; -- �݌ɑg�DID
    gd_proc_date        := NULL; -- �Ɩ����t
    gv_proc_date_char   := NULL; -- �Ɩ����t������
    gt_exe_type_meaning := NULL; -- ���̓p�����[�^.���s�敪����
    gd_target_date      := NULL; -- ���̓p�����[�^.�N����DATE�^
    gt_base_code        := NULL; -- ���O�C�����[�U�������_�R�[�h
    gt_base_name        := NULL; -- ���̓p�����[�^.���_��
    gt_subinv_name      := NULL; -- ���̓p�����[�^.�ۊǏꏊ��
    gt_item_div_h       := NULL; -- �v���t�@�C���l�F�{�Џ��i�敪
    gt_inv_cl_char      := NULL; -- �v���t�@�C���l�F�݌Ɋm�蕶��
    -- ���[�J���ϐ�
    lv_manage_base_flag := NULL; -- �Ǘ������_�t���O
    lb_status           := NULL; -- �݌ɉ�v���ԃX�e�[�^�X
    lv_in_para_err      := NULL; -- ���̓p�����[�^�`�F�b�N�G���[
--
    --==============================================================
    -- �݌ɑg�D�R�[�h�擾
    --==============================================================
    gt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00005
                    ,iv_token_name1  => cv_tkn_pro_tok              -- �v���t�@�C����
                    ,iv_token_value1 => cv_xxcoi1_organization_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �݌ɑg�DID�擾
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00006
                    ,iv_token_name1  => cv_tkn_org_code_tok -- �݌ɑg�D�R�[�h
                    ,iv_token_value1 => gt_org_code
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �Ɩ����t�擾
    --==============================================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00011
                   );
      RAISE global_process_expt;
    END IF;
    -- ������ϊ�
    gv_proc_date_char := TO_CHAR( gd_proc_date, cv_yyyymmdd );
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    BEGIN
      -- ---------------------------
      -- ���s�敪�`�F�b�N
      -- ---------------------------
      gt_exe_type_meaning := xxcoi_common_pkg.get_meaning(
                               iv_lookup_type => ct_lot_rep_output_type -- �Q�ƃ^�C�v��
                              ,iv_lookup_code => gt_exe_type            -- �Q�ƃ^�C�v�R�[�h
                             );
--
      -- ---------------------------
      -- �Ώۓ��`�F�b�N
      -- ---------------------------
      -- NULL�l�`�F�b�N
      IF ( gt_exe_type = cv_exe_type_10 AND gv_target_date IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10460
                     );
        RAISE in_para_expt;
      END IF;
--
      -- �����œ��͂���Ă���ꍇ
      IF ( gt_exe_type = cv_exe_type_20 AND gv_target_date IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10461
                     );
        RAISE in_para_expt;
      END IF;
--
      IF ( gt_exe_type = cv_exe_type_10 ) THEN
        BEGIN
--
          -- ���t�`���`�F�b�N
          gd_target_date := TO_DATE( gv_target_date, cv_yyyymmddhh24miss );
--
          -- �ߋ����`�F�b�N
          IF ( gd_proc_date < gd_target_date ) THEN
            RAISE old_date_expt;
          END IF;
--
        EXCEPTION
          -- �ߋ����`�F�b�N�G���[
          WHEN old_date_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10463
                          ,iv_token_name1  => cv_tkn_target_date   -- �Ώۓ�
                          ,iv_token_value1 => gv_target_date
                          ,iv_token_name2  => cv_tkn_business_date -- �Ɩ����t
                          ,iv_token_value2 => gv_proc_date_char
                         );
            RAISE in_para_expt;
          -- �^�`�F�b�N�G���[
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10462
                          ,iv_token_name1  => cv_tkn_target_date   -- �Ώۓ�
                          ,iv_token_value1 => gv_target_date
                         );
            RAISE in_para_expt;
        END;
      END IF;
--
      -- ---------------------------
      -- �Ώی��`�F�b�N
      -- ---------------------------
      -- NULL�l�`�F�b�N
      IF ( gt_exe_type = cv_exe_type_20 AND gv_target_month IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10464
                     );
        RAISE in_para_expt;
      END IF;
--
      -- �����œ��͂���Ă���ꍇ
      IF ( gt_exe_type = cv_exe_type_10 AND gv_target_month IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10465
                     );
        RAISE in_para_expt;
      END IF;
--
      IF ( gt_exe_type = cv_exe_type_20 ) THEN
        BEGIN
--
          -- ���t�^�`�F�b�N
          gd_target_date := TO_DATE( gv_target_month, cv_yyyymm );
--
          -- �ߋ����`�F�b�N
          IF ( gd_proc_date < gd_target_date ) THEN
            RAISE old_date_expt;
          END IF;
--
        EXCEPTION
          -- �ߋ����`�F�b�N�G���[
          WHEN old_date_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10467
                          ,iv_token_name1  => cv_tkn_target_month  -- �Ώۓ�
                          ,iv_token_value1 => gv_target_month
                          ,iv_token_name2  => cv_tkn_business_date -- �Ɩ����t
                          ,iv_token_value2 => gv_proc_date_char
                         );
            RAISE in_para_expt;
          -- �^�`�F�b�N�G���[
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcoi_short_name
                          ,iv_name         => cv_msg_xxcoi1_10466
                          ,iv_token_name1  => cv_tkn_target_month -- �Ώی�
                          ,iv_token_value1 => gv_target_month
                         );
            RAISE in_para_expt;
        END;
      END IF;
--
      -- ---------------------------
      -- ���_�`�F�b�N
      -- ---------------------------
      -- ���̓p�����[�^.���_��NULL�̏ꍇ
      IF ( gt_login_base_code IS NULL ) THEN
--
        -- ���O�C�����[�U�������_�擾
        gt_base_code := xxcoi_common_pkg.get_base_code(
                          in_user_id     => cn_created_by -- ���[�UID
                         ,id_target_date => gd_proc_date  -- �Ɩ����t
                        );
        IF ( gt_base_code IS NULL ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_msg_xxcoi1_10116
                       );
          RAISE in_para_expt;
        END IF;
--
        -- �Ǘ������_�`�F�b�N
        SELECT CASE WHEN xca.customer_code = xca.management_base_code
                 THEN cv_management_chk_1
                 ELSE cv_management_chk_0
               END manage_base_flag                           -- �Ǘ������_�t���O
        INTO   lv_manage_base_flag
        FROM   hz_cust_accounts    hca                        -- �ڋq�}�X�^
              ,xxcmm_cust_accounts xca                        -- �ڋq�ǉ����
        WHERE  xca.customer_code       = gt_base_code         -- ���O�C�����[�U�������_
        AND    hca.customer_class_code = ct_cust_class_code_1 -- �ڋq�敪�F���_
        AND    hca.status              = ct_cust_status_a     -- �X�e�[�^�X�F�L��
        AND    hca.cust_account_id     = xca.customer_id
        ;
        -- �t���O��0�̏ꍇ�G���[
        IF ( lv_manage_base_flag = cv_management_chk_0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_msg_xxcoi1_10468
                       );
          RAISE in_para_expt;
        END IF;
--
      END IF;
--
      -- ���_���擾
      SELECT xlbiv.base_name base_name
      INTO   gt_base_name
      FROM   xxcos_login_base_info_v xlbiv
      WHERE  xlbiv.base_code = NVL( gt_login_base_code, gt_base_code ) -- ���̓p�����[�^or���O�C�����[�U�������_
      ;
--
      -- ---------------------------
      -- �ۊǏꏊ���擾
      -- ---------------------------
      IF ( gt_subinventory_code IS NOT NULL ) THEN
        SELECT msi.description subinv_name
        INTO   gt_subinv_name
        FROM   mtl_secondary_inventories msi
             , xxcoi_base_info2_v        xbiv
        WHERE  msi.attribute7                          = xbiv.base_code
        AND    msi.attribute14                         = ct_warehouse_flag_y  -- �q�ɊǗ��Ώۃt���O�FY
        AND    msi.organization_id                     = gt_org_id            -- �݌ɑg�DID
        AND    NVL(msi.disable_date, gd_proc_date + 1) > gd_proc_date         -- �L�����`�F�b�N
        AND    xbiv.focus_base_code                    = gt_login_base_code   -- �i���݋��_
        AND    msi.secondary_inventory_name            = gt_subinventory_code -- �ۊǏꏊ
        ;
      END IF;
--
    EXCEPTION
      WHEN in_para_expt THEN
        lv_in_para_err := lv_errmsg;
    END;
--
    --==============================================================
    -- ���̓p�����[�^���O�o��
    --==============================================================
    -- ���b�Z�[�W�擾
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_xxcoi_short_name
                  ,iv_name               => cv_msg_xxcoi1_10459
                  ,iv_token_name1        => cv_tkn_exe_type                         -- ���s�敪
                  ,iv_token_value1       => gt_exe_type
                  ,iv_token_name2        => cv_tkn_exe_type_name                    -- ���s�敪����
                  ,iv_token_value2       => gt_exe_type_meaning
                  ,iv_token_name3        => cv_tkn_target_date                      -- �Ώۓ�
                  ,iv_token_value3       => gv_target_date
                  ,iv_token_name4        => cv_tkn_target_month                     -- �Ώی�
                  ,iv_token_value4       => gv_target_month
                  ,iv_token_name5        => cv_tkn_base_code                        -- ���_�R�[�h
                  ,iv_token_value5       => NVL( gt_login_base_code, gt_base_code )
                  ,iv_token_name6        => cv_tkn_base_name                        -- ���_��
                  ,iv_token_value6       => gt_base_name 
                  ,iv_token_name7        => cv_tkn_subinv_code                      -- �ۊǏꏊ�R�[�h
                  ,iv_token_value7       => gt_subinventory_code
                  ,iv_token_name8        => cv_tkn_subinv_name                      -- �ۊǏꏊ��
                  ,iv_token_value8       => gt_subinv_name
                 );
--
    -- ���b�Z�[�W�o��(���O)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
--
    -- ��s�o��(���O)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => ''
    );
--
    -- ���̓p�����[�^�`�F�b�N�ŃG���[�����������ꍇ�́A��O���������{
    IF ( lv_in_para_err IS NOT NULL ) THEN
      lv_errmsg := lv_in_para_err;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���l�F�{�Џ��i�敪�擾
    --==============================================================
    gt_item_div_h := FND_PROFILE.VALUE( cv_xxcos1_item_div_h );
    IF ( gt_item_div_h IS NULL )THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_10469
                    ,iv_token_name1  => cv_tkn_pro_tok       -- �v���t�@�C����
                    ,iv_token_value1 => cv_xxcos1_item_div_h
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �݌ɉ�v���ԃI�[�v���`�F�b�N
    --==============================================================
    -- �����̏ꍇ�́A�����Ń`�F�b�N����
    IF ( gt_exe_type = cv_exe_type_20 ) THEN
      gd_target_date := LAST_DAY( gd_target_date );
    END IF;
--
    -- ---------------------------------
    -- ���ʊ֐��F�݌ɉ�v���ԃ`�F�b�N
    -- ---------------------------------
    xxcoi_common_pkg.org_acct_period_chk(
      in_organization_id => gt_org_id      -- �݌ɑg�DID
     ,id_target_date     => gd_target_date -- �Ώۓ�
     ,ob_chk_result      => lb_status      -- �X�e�[�^�X
     ,ov_errbuf          => lv_errbuf      -- �G���[���b�Z�[�W
     ,ov_retcode         => lv_retcode     -- ���^�[���E�R�[�h(0:����A2:�G���[)
     ,ov_errmsg          => lv_errmsg      -- ���[�U�[�E�G���[���b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_msg_xxcoi1_00026
                    ,iv_token_name1  => cv_tkn_target_date                     -- �Ώۓ�
                    ,iv_token_value1 => TO_CHAR( gd_target_date, cv_yyyymmdd )
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���l�F�݌Ɋm��󎚕���
    --==============================================================
    -- ��v���Ԃ��N���[�Y�̏ꍇ�̂ݎ擾
    IF ( lb_status = FALSE ) THEN
      gt_inv_cl_char := FND_PROFILE.VALUE( cv_xxcoi1_inv_cl_character );
      IF ( gt_inv_cl_char IS NULL )THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10451
                      ,iv_token_name1  => cv_tkn_pro_tok             -- �v���t�@�C����
                      ,iv_token_value1 => cv_xxcoi1_inv_cl_character
                     );
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W 
  )IS
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    proc_init(
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------
    -- �����̏ꍇ
    -- --------------------
    IF ( gt_exe_type = cv_exe_type_10 ) THEN
      -- ===============================
      -- ���b�g�ʎ󕥁i�����j�f�[�^�擾(A-2)
      -- ===============================
      get_daily_data(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
       ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
       ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      );
      -- �G���[����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- --------------------
    -- �����̏ꍇ
    -- --------------------
    ELSE
      -- ===============================
      -- ���b�g�ʎ󕥁i�����j�f�[�^�擾(A-3)
      -- ===============================
      get_monthly_data(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
       ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
       ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      );
      -- �G���[����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- ���[�N�e�[�u���f�[�^�o�^(A-4)
    -- ===============================
    ins_work_data(
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- SVF�N��(A-5)
    -- ===============================
    execute_svf(
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �I������(A-6)
    -- ===============================
    proc_end(
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
    -- �G���[����
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
    errbuf               OUT VARCHAR2 -- �G���[���b�Z�[�W 
   ,retcode              OUT VARCHAR2 -- �G���[�R�[�h     
   ,iv_exe_type          IN  VARCHAR2 -- ���s�敪
   ,iv_target_date       IN  VARCHAR2 -- �Ώۓ�
   ,iv_target_month      IN  VARCHAR2 -- �Ώی�
   ,iv_login_base_code   IN  VARCHAR2 -- ���_
   ,iv_subinventory_code IN  VARCHAR2 -- �ۊǏꏊ
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
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
    -- ���̓p�����[�^�ޔ�
    gt_exe_type          := iv_exe_type;
    gv_target_date       := iv_target_date;
    gv_target_month      := iv_target_month;
    gt_login_base_code   := iv_login_base_code;
    gt_subinventory_code := iv_subinventory_code;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������Z�b�g
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �Ώی�����0���̏ꍇ�́A����������0���ɂ���
    IF ( gn_target_cnt = 0 ) THEN
      gn_normal_cnt := 0;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSE
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCOI016A11R;
/
