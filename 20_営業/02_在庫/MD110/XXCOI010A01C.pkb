CREATE OR REPLACE PACKAGE BODY XXCOI010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A01C(body)
 * Description      : �c�ƈ��݌�IF�o��
 * MD.050           : �c�ƈ��݌�IF�o�� MD050_COI_010_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_sal_stf_inv        �݌ɏ�񒊏o (A-3)
 *  submain                ���C�������v���V�[�W��
 *                         UTL�t�@�C���I�[�v�� (A-2)
 *                         �K�{���ڃ`�F�b�N���� (A-4)
 *                         �c�ƈ��݌�CSV�쐬 (A-5)
 *                         UTL�t�@�C���N���[�Y (A-6)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   T.Nakamura       �V�K�쐬
 *  2009/05/12    1.1   T.Nakamura       [��QT1_0813]�e��Q�R�[�hNULL�`�F�b�N���폜
 *  2018/01/10    1.2   S.Yamashita      [E_�{�ғ�_14486]����HHT�V�X�e�� ���A���^�C���݌ɑΉ�
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOI010A01C';     -- �p�b�P�[�W��
  cv_appl_short_name_xxccp    CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�v���P�[�V�����Z�k���FXXCCP
  cv_appl_short_name_xxcoi    CONSTANT VARCHAR2(10)  := 'XXCOI';            -- �A�v���P�[�V�����Z�k���FXXCOI
--
  -- ���b�Z�[�W
  cv_para_target_date_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10316'; -- �p�����[�^�F�����Ώۓ�
  cv_file_name_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00028'; -- �t�@�C�����o�̓��b�Z�[�W
  cv_no_data_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_proc_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_dire_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00003'; -- �f�B���N�g�����擾�G���[���b�Z�[�W
  cv_dire_path_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00029'; -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_file_name_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00004'; -- �t�@�C�����擾�G���[���b�Z�[�W
  cv_org_code_get_err_msg     CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_cat_set_n_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00014'; -- �J�e�S���Z�b�g���擾�G���[���b�Z�[�W
  cv_file_remain_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00027'; -- �t�@�C�����݃`�F�b�N�G���[���b�Z�[�W
  cv_ss_code_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10022'; -- �c�ƈ��R�[�h�`�F�b�N�G���[���b�Z�[�W
  cv_vg_code_chk_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10023'; -- �e��Q�R�[�h�`�F�b�N�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_p_date               CONSTANT VARCHAR2(20)  := 'P_DATE';           -- �����Ώۓ�
  cv_tkn_pro_tok              CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �v���t�@�C����
  cv_tkn_org_kode_tok         CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- �݌ɑg�D�R�[�h
  cv_tkn_base_code_tok        CONSTANT VARCHAR2(20)  := 'BASE_CODE_TOK';    -- ���_�R�[�h
  cv_tkn_inv_code_tok         CONSTANT VARCHAR2(20)  := 'INV_CODE_TOK';     -- �ۊǏꏊ
  cv_tkn_item_code_tok        CONSTANT VARCHAR2(20)  := 'ITEM_CODE_TOK';    -- �i�ڃR�[�h
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';          -- �f�B���N�g����
--
-- Ver.1.2 S.Yamashita Add Start
  cv_subinv_type_warehouse    CONSTANT VARCHAR2(20)  := '1';                -- �ۊǏꏊ�敪�F�q��
-- Ver.1.2 S.Yamashita Add End
  cv_subinv_type_sal_stf      CONSTANT VARCHAR2(20)  := '2';                -- �ۊǏꏊ�敪�F�c�ƈ�
  cv_dept_hht_div_dept        CONSTANT VARCHAR2(20)  := '1';                -- �S�ݓXHHT�敪�F�S�ݓX
  cv_cust_class_code_base     CONSTANT VARCHAR2(20)  := '1';                -- �ڋq�敪�F���_
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_target_date     VARCHAR2(50);        -- �����Ώۓ��F�����^
  gd_target_date     DATE;                -- �����Ώۓ��F���t�^
  gd_sysdate         DATE;                -- SYSDATE
  gd_process_date    DATE;                -- �Ɩ����t
  gv_dire_name       VARCHAR2(50);        -- �f�B���N�g����
  gv_file_name       VARCHAR2(50);        -- �t�@�C����
  gv_org_code        VARCHAR2(50);        -- �݌ɑg�D�R�[�h
  gn_org_id          VARCHAR2(50);        -- �݌ɑg�DID
  gv_cat_set_name    VARCHAR2(50);        -- �J�e�S���Z�b�g��
  g_file_handle      UTL_FILE.FILE_TYPE;  -- �t�@�C���n���h��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �c�ƈ��݌ɏ�񒊏o
  CURSOR get_sal_stf_inv_cur
  IS
    SELECT   DECODE( xca.dept_hht_div                               -- �ڋq�ǉ����̕S�ݓXHHT�敪��
                   , cv_dept_hht_div_dept                           -- '1'�̏ꍇ
                   , xca.management_base_code                       -- �ڋq�ǉ����̊Ǘ������_�R�[�h
                   , xird.base_code )     AS sale_base_code         -- ����ȊO�̏ꍇ�A�����݌Ɏ󕥕\(����)�̋��_�R�[�h
           , xird.book_inventory_quantity AS prev_inv_quantity      -- �O���݌ɐ�
           , msi.attribute3               AS sale_staff_code        -- �c�ƈ��R�[�h
           , xsib.vessel_group            AS vessel_group_code      -- �e��Q�R�[�h
           , msib.segment1                AS item_code              -- �i�ڃR�[�h
           , mcb.segment1                 AS item_division          -- ���i�敪
           , msi.secondary_inventory_name AS inv_code               -- �ۊǏꏊ�R�[�h
-- Ver.1.2 S.Yamashita Add Start
           , xird.subinventory_type       AS subinventory_type      -- �ۊǏꏊ�敪
-- Ver.1.2 S.Yamashita Add ENd
    FROM     xxcoi_inv_reception_daily    xird                      -- �����݌Ɏ󕥕\(����)�e�[�u��
           , mtl_secondary_inventories    msi                       -- �ۊǏꏊ�}�X�^
           , mtl_system_items_b           msib                      -- �i�ڃ}�X�^
           , mtl_categories_b             mcb                       -- �i�ڃJ�e�S���}�X�^
           , mtl_item_categories          mic                       -- �i�ڃJ�e�S������
           , mtl_category_sets_tl         mcst                      -- �J�e�S���Z�b�g
           , xxcmm_system_items_b         xsib                      -- Disc�i�ڃA�h�I��
           , hz_cust_accounts             hca                       -- �ڋq�}�X�^
           , xxcmm_cust_accounts          xca                       -- �ڋq�ǉ����
-- Ver.1.2 S.Yamashita Mod Start
--    WHERE    xird.subinventory_type       = cv_subinv_type_sal_stf  -- ���o�����F�ۊǏꏊ�敪���c�ƈ�
    WHERE    xird.subinventory_type       IN ( cv_subinv_type_warehouse, cv_subinv_type_sal_stf )  -- ���o�����F�ۊǏꏊ�敪���q�ɂ܂��͉c�ƈ�
-- Ver.1.2 S.Yamashita Mod End
    AND      xird.practice_date           = NVL( gd_target_date     -- ���o�����F�N�����������Ώۓ��Ɠ�����
                                               , gd_process_date )  -- �����Ώۓ���NULL�̏ꍇ�A�Ɩ����t�Ɠ�����
    AND      msi.secondary_inventory_name = xird.subinventory_code  -- ���������F�ۊǏꏊ�}�X�^�ƌ����݌Ɏ󕥕\(����)
    AND      msib.inventory_item_id       = xird.inventory_item_id  -- ���������F�i�ڃ}�X�^�ƌ����݌Ɏ󕥕\(����)
    AND      msib.organization_id         = gn_org_id               -- ���o�����F�݌ɑg�DID�����������Ŏ擾������
    AND      mcst.category_set_name       = gv_cat_set_name         -- ���o�����G�J�e�S���Z�b�g�������������Ŏ擾������
    AND      mcst.language                = USERENV( 'LANG' )       -- ���o�����G���ꂪ���[�U�̊��Ɠ���
    AND      mic.category_set_id          = mcst.category_set_id    -- ���������F�i�ڃJ�e�S�������ƃJ�e�S���Z�b�g
    AND      mic.inventory_item_id        = xird.inventory_item_id  -- ���������F�i�ڃJ�e�S�������ƌ����݌Ɏ󕥕\(����)
    AND      mic.category_id              = mcb.category_id         -- ���������F�i�ڃJ�e�S�������ƕi�ڃJ�e�S���}�X�^
    AND      mic.organization_id          = msib.organization_id    -- ���������F�i�ڃJ�e�S�������ƕi�ڃ}�X�^
    AND      xsib.item_code               = msib.segment1           -- ���������FDisc�i�ڃA�h�I���ƕi�ڃ}�X�^
    AND      hca.account_number           = xird.base_code          -- ���������F�ڋq�}�X�^�ƌ����݌Ɏ󕥕\(����)
    AND      hca.customer_class_code      = cv_cust_class_code_base -- �擾�����F�ڋq�敪�����_
    AND      xca.customer_id              = hca.cust_account_id     -- ���������F�ڋq�ǉ����ƌڋq�}�X�^
    ;
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���e�[�u��
  -- ==============================
  TYPE g_get_sal_stf_inv_ttype IS TABLE OF get_sal_stf_inv_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_get_sal_stf_inv_tab        g_get_sal_stf_inv_ttype;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  remain_file_expt          EXCEPTION;     -- �t�@�C�����݃G���[
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �v���t�@�C�� XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
    cv_prf_dire_out_hht        CONSTANT VARCHAR2(30) := 'XXCOI1_DIRE_OUT_HHT';
    -- �v���t�@�C�� XXCOI:�c�ƈ��݌�IF�o�̓t�@�C����
    cv_prf_file_sal_staff      CONSTANT VARCHAR2(30) := 'XXCOI1_FILE_SALE_STAFF';
    -- �v���t�@�C�� XXCOI:�݌ɑg�D�R�[�h
    cv_prf_file_org_code       CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
    -- �v���t�@�C�� XXCOS:�{�Џ��i�敪
    cv_prf_file_item_div_h     CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';
--
    cv_slash                   CONSTANT VARCHAR2(1)  := '/';  -- �X���b�V��
--
    -- *** ���[�J���ϐ� ***
    lv_dire_path               VARCHAR2(100);                 -- �f�B���N�g���t���p�X�i�[�ϐ�
    lv_file_name               VARCHAR2(100);                 -- �t�@�C�����i�[�ϐ�
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
    -- ===============================
    -- �R���J�����g���̓p�����[�^�o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxcoi
                    , iv_name         => cv_para_target_date_msg
                    , iv_token_name1  => cv_tkn_p_date
                    , iv_token_value1 => TO_CHAR( TRUNC( gd_target_date ), 'YYYY/MM/DD' )
                  );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    -- ===============================
    -- SYSDATE�擾
    -- ===============================
    gd_sysdate := SYSDATE;
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_proc_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���F�f�B���N�g���p�X�擾
    -- ===============================
    -- �f�B���N�g���p�X�擾
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- �f�B���N�g���p�X���擾�ł��Ȃ��ꍇ
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_dire_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �f�B���N�g���t���p�X�擾
    BEGIN
      SELECT directory_path
      INTO   lv_dire_path
      FROM   all_directories
      WHERE  directory_name    = gv_dire_name;
    EXCEPTION
      -- �f�B���N�g���t���p�X���擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_xxcoi
                         , iv_name         => cv_dire_path_get_err_msg
                         , iv_token_name1  => cv_tkn_dir_tok
                         , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �v���t�@�C���F�t�@�C�����擾
    -- ===============================
    gv_file_name := fnd_profile.value( cv_prf_file_sal_staff );
    -- �t�@�C�������擾�ł��Ȃ��ꍇ
    IF ( gv_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_file_name_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_sal_staff
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���F�݌ɑg�D�R�[�h�擾
    -- ===============================
    gv_org_code := fnd_profile.value( cv_prf_file_org_code );
    -- �݌ɑg�D�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( gv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gn_org_id := xxcoi_common_pkg.get_organization_id( iv_organization_code => gv_org_code );
    -- �݌ɑg�DID���擾�ł��Ȃ��ꍇ
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_kode_tok
                     , iv_token_value1 => gv_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���F�J�e�S���Z�b�g���擾
    -- ===============================
    gv_cat_set_name := fnd_profile.value( cv_prf_file_item_div_h );
    -- �J�e�S���Z�b�g���擾�ł��Ȃ��ꍇ
    IF ( gv_cat_set_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_xxcoi
                     , iv_name         => cv_cat_set_n_get_err_msg
                     , iv_token_name1  => cv_tkn_pro_tok
                     , iv_token_value1 => cv_prf_file_item_div_h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================================
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j�o��
    -- ==============================================================
    lv_file_name := lv_dire_path || cv_slash || gv_file_name;
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_name_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => lv_file_name
                    );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
   * Procedure Name   : get_sal_stf_inv
   * Description      : �݌ɏ�񒊏o(A-3)
   ***********************************************************************************/
  PROCEDURE get_sal_stf_inv(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sal_stf_inv'; -- �v���O������
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
    -- �J�[�\���I�[�v��
    OPEN  get_sal_stf_inv_cur;
--
    -- �J�[�\���f�[�^�擾
    FETCH get_sal_stf_inv_cur BULK COLLECT INTO g_get_sal_stf_inv_tab;
--
    -- �J�[�\���̃N���[�Y
    CLOSE get_sal_stf_inv_cur;
--
    -- ===============================
    -- �Ώی����J�E���g
    -- ===============================
    gn_target_cnt := g_get_sal_stf_inv_tab.COUNT;
--
    -- ===============================
    -- ���o0���`�F�b�N
    -- ===============================
    IF ( gn_target_cnt = 0 ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_no_data_msg
                    );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    END IF;
--
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
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( get_sal_stf_inv_cur%ISOPEN ) THEN
        CLOSE get_sal_stf_inv_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sal_stf_inv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_open_mode             CONSTANT VARCHAR2(1) := 'w';  -- �I�[�v�����[�h�F��������
    cv_delimiter             CONSTANT VARCHAR2(1) := ',';  -- ��؂蕶��
    cv_encloser              CONSTANT VARCHAR2(1) := '"';  -- ���蕶��
    cv_const_zero            CONSTANT VARCHAR2(1) := '0';  -- '0'�Œ�
--
    -- *** ���[�J���ϐ� ***
    ln_file_length           NUMBER;                       -- �t�@�C���̒����̕ϐ�
    ln_block_size            NUMBER;                       -- �u���b�N�T�C�Y�̕ϐ�
    lb_fexists               BOOLEAN;                      -- �t�@�C�����݃`�F�b�N����
    lv_csv_file              VARCHAR2(1500);               -- CSV�t�@�C��
    lv_prev_inv_quantity     VARCHAR2(100);                -- �O���݌ɐ�
    lv_sysdate               VARCHAR2(100);                -- SYSDATE
--
    lv_chk_status            BOOLEAN;                      -- �K�{�`�F�b�N�X�e�[�^�X
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- UTL�t�@�C���I�[�v�� (A-2)
    -- ===============================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR(
        location    => gv_dire_name
      , filename    => gv_file_name
      , fexists     => lb_fexists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    IF( lb_fexists = TRUE ) THEN
      RAISE remain_file_expt;
    END IF;
--
    -- �t�@�C���̃I�[�v��
    g_file_handle := UTL_FILE.FOPEN(
                         location  => gv_dire_name
                       , filename  => gv_file_name
                       , open_mode => cv_open_mode
                     );
--
    -- ===============================
    -- �݌ɏ�񒊏o (A-3)
    -- ===============================
    get_sal_stf_inv(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�v�J�n
    -- ===============================
    <<create_file_loop>>
    FOR i IN 1 .. g_get_sal_stf_inv_tab.COUNT LOOP
--
      -- �K�{�`�F�b�N�X�e�[�^�X�̏�����
      lv_chk_status := TRUE;
--
-- Ver.1.2 S.Yamashita Add Start
      -- �c�ƈ��̏ꍇ
      IF ( g_get_sal_stf_inv_tab(i).subinventory_type = cv_subinv_type_sal_stf ) THEN
-- Ver.1.2 S.Yamashita Add End
        -- ===============================
        -- �K�{���ڃ`�F�b�N���� (A-4)
        -- ===============================
        -- �c�ƈ��R�[�hNULL�`�F�b�N
        IF ( g_get_sal_stf_inv_tab(i).sale_staff_code IS NULL ) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_xxcoi
                          , iv_name         => cv_ss_code_chk_err_msg
                          , iv_token_name1  => cv_tkn_base_code_tok
                          , iv_token_value1 => g_get_sal_stf_inv_tab(i).sale_base_code
                          , iv_token_name2  => cv_tkn_inv_code_tok
                          , iv_token_value2 => g_get_sal_stf_inv_tab(i).inv_code
                          , iv_token_name3  => cv_tkn_item_code_tok
                          , iv_token_value3 => g_get_sal_stf_inv_tab(i).item_code
                        );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
            , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
          );
          lv_chk_status := FALSE;
          ov_retcode    := cv_status_warn;
        END IF;
-- Ver.1.2 S.Yamashita Add Start
      END IF;
-- Ver.1.2 S.Yamashita Add End
--
-- == 2009/05/12 V1.1 Deleted START ================================================================
--      -- �e��Q�R�[�hNULL�`�F�b�N
--      IF ( g_get_sal_stf_inv_tab(i).vessel_group_code IS NULL ) THEN
--        gv_out_msg := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_appl_short_name_xxcoi
--                        , iv_name         => cv_vg_code_chk_err_msg
--                        , iv_token_name1  => cv_tkn_base_code_tok
--                        , iv_token_value1 => g_get_sal_stf_inv_tab(i).sale_base_code
--                        , iv_token_name2  => cv_tkn_inv_code_tok
--                        , iv_token_value2 => g_get_sal_stf_inv_tab(i).inv_code
--                        , iv_token_name3  => cv_tkn_item_code_tok
--                        , iv_token_value3 => g_get_sal_stf_inv_tab(i).item_code
--                      );
--        -- ���b�Z�[�W�o��
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--          , buff   => gv_out_msg
--        );
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.LOG
--          , buff   => SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||gv_out_msg,1,5000 )
--        );
--        lv_chk_status := FALSE;
--        ov_retcode    := cv_status_warn;
--      END IF;
-- == 2009/05/12 V1.1 Deleted END   ================================================================
--
      -- �K�{�`�F�b�N�X�e�[�^�X��FALSE�̏ꍇ
      IF ( lv_chk_status = FALSE ) THEN
        gn_warn_cnt := gn_warn_cnt + 1;
      -- �X�e�[�^�X������̏ꍇ
      ELSE
        -- ===============================
        -- �c�ƈ��݌�CSV�쐬 (A-5)
        -- ===============================
-- Ver.1.2 S.Yamashita Add Start
        -- �q�ɂ̏ꍇ
        IF ( g_get_sal_stf_inv_tab(i).subinventory_type = cv_subinv_type_warehouse ) THEN
          lv_prev_inv_quantity := NULL; -- �O���݌ɐ�
        ELSE
-- Ver.1.2 S.Yamashita Add End
          lv_prev_inv_quantity := TO_CHAR( g_get_sal_stf_inv_tab(i).prev_inv_quantity ); -- �O���݌ɐ�
-- Ver.1.2 S.Yamashita Add Start
        END IF;
-- Ver.1.2 S.Yamashita Add End
        lv_sysdate           := TO_CHAR( gd_sysdate, 'YYYY/MM/DD HH24:MI:SS' );        -- SYSDATE
--
        -- CSV�f�[�^���쐬
        lv_csv_file := (
          cv_encloser || g_get_sal_stf_inv_tab(i).sale_base_code    || cv_encloser || cv_delimiter || -- ���㋒�_�R�[�h
          cv_encloser || g_get_sal_stf_inv_tab(i).sale_staff_code   || cv_encloser || cv_delimiter || -- �c�ƈ��R�[�h
          cv_encloser || g_get_sal_stf_inv_tab(i).vessel_group_code || cv_encloser || cv_delimiter || -- �e��Q�R�[�h
          cv_encloser || g_get_sal_stf_inv_tab(i).item_code         || cv_encloser || cv_delimiter || -- �i�ڃR�[�h
                         lv_prev_inv_quantity                                      || cv_delimiter || -- �O���݌ɐ�
                         cv_const_zero                                             || cv_delimiter || -- �q�ɂ�����
                         cv_const_zero                                             || cv_delimiter || -- ����o��
          cv_encloser || lv_sysdate                                 || cv_encloser || cv_delimiter || -- SYSDATE
          cv_encloser || g_get_sal_stf_inv_tab(i).item_division     || cv_encloser                    -- ���i�敪
-- Ver.1.2 S.Yamashita Add Start
          || cv_delimiter || cv_encloser || g_get_sal_stf_inv_tab(i).inv_code                     || cv_encloser  -- �ۊǏꏊ�R�[�h
          || cv_delimiter ||                TO_CHAR( g_get_sal_stf_inv_tab(i).prev_inv_quantity )                 -- �O���݌ɐ��i�c�ƎԁE�q�Ɂj
-- Ver.1.2 S.Yamashita Add End
        );
--
        -- ===============================
        -- CSV�f�[�^���o��
        -- ===============================
        UTL_FILE.PUT_LINE(
            file   => g_file_handle
          , buffer => lv_csv_file
        );
--
        -- ===============================
        -- ���������J�E���g
        -- ===============================
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP create_file_loop;
--
    -- ===============================
    -- UTL�t�@�C���N���[�Y (A-6)
    -- ===============================
    UTL_FILE.FCLOSE( file => g_file_handle );
--
  EXCEPTION
--
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    WHEN remain_file_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_xxcoi
                      , iv_name         => cv_file_remain_err_msg
                      , iv_token_name1  => cv_tkn_file_name
                      , iv_token_value1 => gv_file_name
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C����OPEN���Ă���ꍇ
      IF ( UTL_FILE.IS_OPEN( file => g_file_handle ) ) THEN
        UTL_FILE.FCLOSE( file => g_file_handle );
      END IF;
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
      errbuf          OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode         OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    , iv_target_date  IN  VARCHAR2)      --   �����Ώۓ�
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- �p�����[�^�̏����Ώۓ����O���[�o���ϐ��Ɋi�[
    gv_target_date := iv_target_date;
    gd_target_date := TO_DATE( gv_target_date, 'YYYY/MM/DD HH24:MI:SS' );
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        ov_errbuf  => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      -- ���������A�X�L�b�v�����̏������y�уG���[�����̃Z�b�g
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg       -- ���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf       -- �G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_xxccp
                    , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI010A01C;
/
