CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A09C (body)
 * Description      : �������i�\�f�[�^�_�E�����[�h
 * MD.050           : �������i�\�f�[�^�_�E�����[�h <MD050_COS_003_A09>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_parameter        �p�����[�^�`�F�b�N(A-2)
 *  get_price_list_data    �������i�\�f�[�^�擾(A-3)
 *  output_data            �f�[�^�o��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/04/06    1.0   S.Niki           �V�K�쐬[E_�{�ғ�_14024�Ή�]
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �����`�F�b�N��O ***
  global_format_chk_expt            EXCEPTION;
  --*** ���t�t�]�`�F�b�N��O ***
  global_date_rever_chk_expt        EXCEPTION;
  --*** �Ώ�0����O ***
  global_no_data_expt               EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) := 'XXCOS003A09C';        -- �p�b�P�[�W��
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) := 'XXCOS';               -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) := 'XXCCP';               -- ���ʗ̈�Z�k�A�v����
  -- ���b�Z�[�W
  cv_msg_format_check_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00002';    -- ���t�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00003';    -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_date_rever_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00005';    -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_inv_org_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00091';    -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_parameter               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15201';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_date_from               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15202';    -- ����(FROM)
  cv_msg_date_to                 CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-15203';    -- ����(TO)
  -- �g�[�N����
  cv_tkn_para_date               CONSTANT  VARCHAR2(100) := 'PARA_DATE';           -- ���t
  cv_tkn_base_code               CONSTANT  VARCHAR2(100) := 'BASE_CODE';           -- ���_�R�[�h
  cv_tkn_customer_code           CONSTANT  VARCHAR2(100) := 'CUSTOMER_CODE';       -- �ڋq�R�[�h
  cv_tkn_item_code               CONSTANT  VARCHAR2(100) := 'ITEM_CODE';           -- �i�ڃR�[�h
  cv_tkn_date_from               CONSTANT  VARCHAR2(100) := 'DATE_FROM';           -- ����(FROM)
  cv_tkn_date_to                 CONSTANT  VARCHAR2(100) := 'DATE_TO';             -- ����(TO)
  cv_tkn_profile                 CONSTANT  VARCHAR2(100) := 'PROFILE';             -- �v���t�@�C����
  cv_tkn_org_code_tok            CONSTANT  VARCHAR2(100) := 'ORG_CODE_TOK';        -- �݌ɑg�D�R�[�h
  -- ���t�t�H�[�}�b�g
  cv_fmt_std                     CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';          -- �����FYYYY/MM/DD
  cv_flag_y                      CONSTANT  VARCHAR2(1)   := 'Y';                   -- �t���O�FY
  cv_flag_n                      CONSTANT  VARCHAR2(1)   := 'N';                   -- �t���O�FN
  ct_lang                        CONSTANT  fnd_lookup_values.language%TYPE
                                                         := USERENV( 'LANG' );     -- ����
  cv_qck_typ_head                CONSTANT  VARCHAR2(30)  := 'XXCOS1_EXCEL_OUTPUT_HEAD';    -- �G�N�Z���o�͗p���o��
  cv_qck_typ_003a09              CONSTANT  VARCHAR2(30)  := '003A09%';                     -- �G�N�Z���o�͗p���o���L�[
  -- �v���t�@�C��
  cv_prof_inv_org_code           CONSTANT  VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';    -- �v���t�@�C����(�݌ɑg�D�R�[�h)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���o��
  TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                                        -- �Ɩ����t
  gt_inv_org_id             mtl_parameters.organization_id%TYPE;         -- �݌ɑg�DID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �������i�\�f�[�^�擾
  CURSOR get_price_list_cur(
           icp_base_code           VARCHAR2   -- ���_�R�[�h
          ,icp_customer_code       VARCHAR2   -- �ڋq�R�[�h
          ,icp_item_code           VARCHAR2   -- �i�ڃR�[�h
          ,icp_date_from           DATE       -- ����(FROM)
          ,icp_date_to             DATE       -- ����(TO)
         )
  IS
    SELECT
       NULL                            AS proc_kbn             -- �����敪
      ,hca.account_number              AS customer_code        -- �ڋq�R�[�h
      ,hp.party_name                   AS customer_name        -- �ڋq����
      ,msib.segment1                   AS item_code            -- �i�ڃR�[�h
      ,msib.description                AS item_name            -- �i�ږ���
      ,xspl.price                      AS price                -- ���i
      ,xspl.start_date_active          AS start_date_active    -- �L���J�n��
      ,xspl.end_date_active            AS end_date_active      -- �L���I����
    FROM
       xxcos_sale_price_lists  xspl    -- �������i�\
      ,hz_cust_accounts        hca     -- �ڋq�}�X�^
      ,hz_parties              hp      -- �p�[�e�B�}�X�^
      ,xxcmm_cust_accounts     xca     -- �ڋq�ǉ����
      ,mtl_system_items_b      msib    -- DISC�i�ڃ}�X�^
    WHERE
        hca.cust_account_id      = xspl.customer_id
    AND hca.party_id             = hp.party_id
    AND hca.cust_account_id      = xca.customer_id
    AND xspl.item_id             = msib.inventory_item_id(+)
    AND msib.organization_id(+)  = gt_inv_org_id
    -- �p�����[�^.���_�R�[�h
    AND (  ( icp_base_code  IS NULL )
         OR
           -- �p�����[�^.���_�R�[�h = ���㋒�_�R�[�h
           ( icp_base_code  = xca.sale_base_code )
         OR
           -- �p�����[�^.���_�R�[�h = �[�i���_�R�[�h
           ( icp_base_code  = xca.delivery_base_code )
         OR
           -- �p�����[�^.���_�R�[�h = �̔���{���S�����_
           ( icp_base_code  = xca.sales_head_base_code )
        )
    -- �p�����[�^.�ڋq�R�[�h
    AND (  ( icp_customer_code  IS NULL )
         OR
           ( hca.account_number = icp_customer_code )
        )
    -- �p�����[�^.�i�ڃR�[�h
    AND (  ( icp_item_code      IS NULL )
         OR
           ( msib.segment1      = icp_item_code )
        )
    -- �p�����[�^.����(FROM)(TO)
    AND (  (     ( icp_date_from  IS NULL )
             AND ( icp_date_to    IS NULL )
           )
         OR
           (     ( icp_date_from  <= NVL( xspl.end_date_active   ,icp_date_from ) )
             AND ( icp_date_to    >= NVL( xspl.start_date_active ,icp_date_to   ) )
           )
        )
    ORDER BY
        hca.account_number          -- �ڋq�R�[�h
       ,msib.segment1               -- �i�ڃR�[�h
       ,xspl.start_date_active      -- �L���J�n��
    ;
--
  -- �擾�f�[�^�i�[�ϐ���`
  TYPE g_out_file_ttype IS TABLE OF get_price_list_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code           IN   VARCHAR2  -- ���_�R�[�h
   ,iv_customer_code       IN   VARCHAR2  -- �ڋq�R�[�h
   ,iv_item_code           IN   VARCHAR2  -- �i�ڃR�[�h
   ,iv_date_from           IN   VARCHAR2  -- ����(FROM)
   ,iv_date_to             IN   VARCHAR2  -- ����(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';  -- �v���O������
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
    lv_para_msg            VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lt_inv_org_code        mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
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
    --========================================
    -- �p�����[�^�o�͏���
    --========================================
    -- �p�����[�^�o�̓��b�Z�[�W�擾
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name        -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_parameter           -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_base_code           -- �g�[�N���R�[�h1
                    ,iv_token_value1 => iv_base_code               -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_customer_code       -- �g�[�N���R�[�h2
                    ,iv_token_value2 => iv_customer_code           -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_item_code           -- �g�[�N���R�[�h3
                    ,iv_token_value3 => iv_item_code               -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_date_from           -- �g�[�N���R�[�h4
                    ,iv_token_value4 => iv_date_from               -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_date_to             -- �g�[�N���R�[�h5
                    ,iv_token_value5 => iv_date_to                 -- �g�[�N���l5
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- �Ɩ����t�擾
    --========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_proc_date_err   -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- �݌ɑg�D�R�[�h
    --========================================
    lt_inv_org_code := FND_PROFILE.VALUE( cv_prof_inv_org_code );
    IF ( lt_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_prof_err        -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_profile         -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prof_inv_org_code   -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- �݌ɑg�DID
    --========================================
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => lt_inv_org_code
                     );
    IF ( gt_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name    -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_inv_org_id_err  -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_org_code_tok    -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lt_inv_org_code        -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_date_from           IN   VARCHAR2  -- ����(FROM)
   ,iv_date_to             IN   VARCHAR2  -- ����(TO)
   ,od_date_from           OUT  DATE      -- ����(FROM)
   ,od_date_to             OUT  DATE      -- ����(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    lv_check_item          VARCHAR2(100); -- ���b�Z�[�W�o�͗p
    ld_date_from           DATE;          -- ����(FROM)
    ld_date_to             DATE;          -- ����(TO)
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
    -- ���t�����ɕϊ�
    ld_date_from  := FND_DATE.STRING_TO_DATE( iv_date_from ,cv_fmt_std );
    ld_date_to    := FND_DATE.STRING_TO_DATE( iv_date_to ,cv_fmt_std );
--
    -- ����(FROM)�K�{�`�F�b�N
    IF ( ( iv_date_from IS NULL ) AND ( iv_date_to IS NOT NULL ) ) THEN
      lv_check_item := cv_msg_date_from;
      RAISE global_format_chk_expt;
    END IF;
    -- ����(TO)�K�{�`�F�b�N
    IF ( ( iv_date_from IS NOT NULL ) AND ( iv_date_to IS NULL ) ) THEN
      lv_check_item := cv_msg_date_to;
      RAISE global_format_chk_expt;
    END IF;
--
    -- ����(FROM)�A����(TO)�������͂��ꂽ�ꍇ
    IF ( ( iv_date_from IS NOT NULL ) AND ( iv_date_to IS NOT NULL ) ) THEN
      -- ����(FROM)�^����(TO)���t�t�]�`�F�b�N
      IF ( ld_date_from > ld_date_to ) THEN
        RAISE global_date_rever_chk_expt;
      END IF;
    END IF;
--
    -- �߂�l��ԋp
    od_date_from  := ld_date_from; -- ����(FROM)
    od_date_to    := ld_date_to;   -- ����(TO)
--
  EXCEPTION
--
    -- *** �����`�F�b�N��O�n���h�� ***
    WHEN global_format_chk_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_format_check_err     -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_para_date            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_check_item               -- �g�[�N���l1
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_chk_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_date_rever_err       -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_date_from            -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_date_from            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_date_to              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_msg_date_to              -- �g�[�N���l2
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_price_list_data
   * Description      : �������i�\�f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_price_list_data(
    iv_base_code           IN   VARCHAR2  --  ���_�R�[�h
   ,iv_customer_code       IN   VARCHAR2  --  �ڋq�R�[�h
   ,iv_item_code           IN   VARCHAR2  --  �i�ڃR�[�h
   ,id_date_from           IN   DATE      --  ����(FROM)
   ,id_date_to             IN   DATE      --  ����(TO)
   ,ov_errbuf              OUT  VARCHAR2  --  �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode             OUT  VARCHAR2  --  ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg              OUT  VARCHAR2  --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price_list_data'; -- �v���O������
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
    -- �Ώۃf�[�^�擾
    OPEN get_price_list_cur(
           iv_base_code         -- ���_�R�[�h
          ,iv_customer_code     -- �ڋq�R�[�h
          ,iv_item_code         -- �i�ڃR�[�h
          ,id_date_from         -- ����(FROM)
          ,id_date_to           -- ����(TO)
         );
--
    FETCH get_price_list_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_price_list_cur;
--
    -- �Ώی����J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
  EXCEPTION
    -- *** �Ώ�0����O�n���h�� ***
    WHEN global_no_data_expt THEN
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_price_list_cur%ISOPEN ) THEN
        CLOSE get_price_list_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_price_list_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-4)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    lv_delimit          CONSTANT  VARCHAR2(1) := ',';       -- ��؂蕶��
--
    -- *** ���[�J���ϐ� ***
    lv_line_data        VARCHAR2(5000); -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR head_cur
    IS
      SELECT flv.description AS head
      FROM   fnd_lookup_values flv
      WHERE  flv.language      = ct_lang
      AND    flv.lookup_type   = cv_qck_typ_head
      AND    gd_process_date  >= NVL( flv.start_date_active ,gd_process_date )
      AND    gd_process_date  <= NVL( flv.end_date_active   ,gd_process_date )
      AND    flv.enabled_flag  = cv_flag_y
      AND    flv.meaning       LIKE cv_qck_typ_003a09
      ORDER BY
             flv.meaning
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------
    -- �f�[�^���o���o��
    ----------------------
    -- �f�[�^�̌��o�����擾
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    -- �f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || lv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    -- �f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ----------------------
    -- �f�[�^�o��
    ----------------------
    -- �f�[�^���擾
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      -- ������
      lv_line_data := NULL;
      -- �f�[�^��ҏW
      lv_line_data :=    gt_out_file_tab(i).proc_kbn                                  -- �����敪
        || lv_delimit || gt_out_file_tab(i).customer_code                             -- �ڋq�R�[�h
        || lv_delimit || gt_out_file_tab(i).customer_name                             -- �ڋq����
        || lv_delimit || gt_out_file_tab(i).item_code                                 -- �i�ڃR�[�h
        || lv_delimit || gt_out_file_tab(i).item_name                                 -- �i�ږ���
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).price )                          -- ���i
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).start_date_active ,cv_fmt_std )  -- �L���J�n��
        || lv_delimit || TO_CHAR( gt_out_file_tab(i).end_date_active   ,cv_fmt_std )  -- �L���I����
        ;
--
      -- �f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( head_cur%ISOPEN ) THEN
        CLOSE head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code        IN   VARCHAR2  -- ���_�R�[�h
   ,iv_customer_code    IN   VARCHAR2  -- �ڋq�R�[�h
   ,iv_item_code        IN   VARCHAR2  -- �i�ڃR�[�h
   ,iv_date_from        IN   VARCHAR2  -- ����(FROM)
   ,iv_date_to          IN   VARCHAR2  -- ����(TO)
   ,ov_errbuf           OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_date_from          DATE;  -- ����(FROM)
    ld_date_to            DATE;  -- ����(TO)
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
    init(
      iv_base_code          => iv_base_code           -- ���_�R�[�h
     ,iv_customer_code      => iv_customer_code       -- �ڋq�R�[�h
     ,iv_item_code          => iv_item_code           -- �i�ڃR�[�h
     ,iv_date_from          => iv_date_from           -- ����(FROM)
     ,iv_date_to            => iv_date_to             -- ����(TO)
     ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �p�����[�^�`�F�b�N(A-2)
    -- ===============================
    check_parameter(
      iv_date_from          => iv_date_from           -- ����(FROM)
     ,iv_date_to            => iv_date_to             -- ����(TO)
     ,od_date_from          => ld_date_from           -- ����(FROM)
     ,od_date_to            => ld_date_to             -- ����(TO)
     ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �������i�\�f�[�^�擾(A-3)
    -- ===============================
    get_price_list_data(
      iv_base_code          => iv_base_code           -- ���_�R�[�h
     ,iv_customer_code      => iv_customer_code       -- �ڋq�R�[�h
     ,iv_item_code          => iv_item_code           -- �i�ڃR�[�h
     ,id_date_from          => ld_date_from           -- ����(FROM)
     ,id_date_to            => ld_date_to             -- ����(TO)
     ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����0��
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- ===============================
    -- �f�[�^�o��(A-4)
    -- ===============================
    output_data(
       ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώ�0����O�n���h�� ***
    WHEN global_no_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name
                    ,iv_name        => cv_msg_no_data
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                 OUT  VARCHAR2  -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                OUT  VARCHAR2  -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_base_code           IN   VARCHAR2  -- ���_�R�[�h
   ,iv_customer_code       IN   VARCHAR2  -- �ڋq�R�[�h
   ,iv_item_code           IN   VARCHAR2  -- �i�ڃR�[�h
   ,iv_date_from           IN   VARCHAR2  -- ����(FROM)
   ,iv_date_to             IN   VARCHAR2  -- ����(TO)
  )
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_base_code          => iv_base_code           -- ���_�R�[�h
     ,iv_customer_code      => iv_customer_code       -- �ڋq�R�[�h
     ,iv_item_code          => iv_item_code           -- �i�ڃR�[�h
     ,iv_date_from          => iv_date_from           -- ����(FROM)
     ,iv_date_to            => iv_date_to             -- ����(TO)
     ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF ( lv_retcode = cv_status_warn ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    -- �G���[�o��
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- �����N���A�A�G���[�����Z�b�g
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
    END IF;
    --
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                  ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
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
END XXCOS003A09C;
/
