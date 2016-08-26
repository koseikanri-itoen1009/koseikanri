CREATE OR REPLACE PACKAGE BODY APPS.XXCOI017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A02C(body)
 * Description      : ���b�g�ʈ������CSV�����[�N�t���[�`���Ŕz�M���܂��B
 * MD.050           : ���b�g�ʏo�׏��z�M <MD050_COI_017_A02>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_data            CSV�o�͏���(A-2)
 *  upd_lot_reserve_info   ���b�g�ʈ������X�V����(A-3)
 *  submain                ���C�������v���V�[�W��
 *                         �I������(A-4)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/08/01    1.0   K.Kiriu          �V�K�쐬
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
  --*** ���b�N�G���[ ***
  global_lock_expt          EXCEPTION;
  --*** �x���� ***
  global_warn_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI017A02C';             -- �p�b�P�[�W��
  -- �A�v���P�[�V����
  cv_app_xxcoi          CONSTANT VARCHAR2(5)   := 'XXCOI';                    -- �A�v���P�[�V�����Z�k��(�݌�)
  -- �v���t�@�C��
  cv_organization_code  CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:�݌ɑg�D�R�[�h
  -- ���b�Z�[�W
  cv_msg_xxcoi_00005    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005';         -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_00006    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006';         -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10039    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10039';         -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_xxcoi_10531    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10531';         -- �����t�]�G���[���b�Z�[�W
  cv_msg_xxcoi_10716    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10716';         -- �z�M�Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_xxcoi_10717    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10717';         -- ���b�g�ʏo�׏��z�M�R���J�����g���̓p�����[�^
  cv_msg_xxcoi_10718    CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10718';         -- ���b�g�ʈ������e�[�u���X�V�G���[���b�Z�[�W
  -- �g�[�N��
  cv_tkn_pro_tok        CONSTANT VARCHAR2(7)   := 'PRO_TOK';                  -- �v���t�@�C��
  cv_tkn_org_code_tok   CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';             -- �݌ɑg�D�R�[�h
  cv_tkn_param1         CONSTANT VARCHAR2(6)   := 'PARAM1';                   -- �p�����[�^1
  cv_tkn_param2         CONSTANT VARCHAR2(6)   := 'PARAM2';                   -- �p�����[�^2
  cv_tkn_param3         CONSTANT VARCHAR2(6)   := 'PARAM3';                   -- �p�����[�^3
  cv_tkn_param_name1    CONSTANT VARCHAR2(11)  := 'PARAM_NAME1';              -- �p�����[�^1�i���́j
  cv_tkn_err_msg        CONSTANT VARCHAR2(11)  := 'ERR_MSG';                  -- �G���[���b�Z�[�W
  -- �t�H�[�}�b�g
  cv_fmt_date           CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';               -- ����
  cv_fmt_date_time_s    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';    -- �������b(�Z�p���[�g����)
  cv_fmt_date_time      CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';         -- �������b(�Z�p���[�g�Ȃ�)
  -- �ڋq�֘A
  cv_cust_cls_cd_base   CONSTANT VARCHAR2(1)   := '1';                        -- �ڋq�敪(1:���_)
  -- WF�֘A
  cv_ope_div            CONSTANT VARCHAR2(2)   := '14';                       -- �����敪:14(���b�g�ʏo�׏��)
  cv_wf_class           CONSTANT VARCHAR2(1)   := '9';                        -- �Ώ�:9(�P�ꋒ�_�Ώۃ��[�U�[)
  -- ���b�g�ʈ�����񒊏o�֘A
  cv_p_shipping_st_10   CONSTANT VARCHAR2(2)   := '10';                       -- ������
  cv_p_shipping_st_20   CONSTANT VARCHAR2(2)   := '20';                       -- ������
  cv_p_shipping_st_25   CONSTANT VARCHAR2(2)   := '25';                       -- �o�׉��m��
  cv_p_shipping_st_30   CONSTANT VARCHAR2(2)   := '30';                       -- �o�׊m��
  -- �o�͍��ڊ֘A
  cv_company_name       CONSTANT VARCHAR2(5)   := 'ITOEN';                    -- ��Ж�
  cv_data_type          CONSTANT VARCHAR2(3)   := '620';                      -- �o�׏��
  cv_branch_no_header   CONSTANT VARCHAR2(2)   := '10';                       -- �`���p�}��(�w�b�_)
  cv_branch_no_line     CONSTANT VARCHAR2(2)   := '20';                       -- �`���p�}��(����)
  cv_data_class         CONSTANT VARCHAR2(1)   := '0';                        -- �f�[�^�敪
  cv_null               CONSTANT VARCHAR2(1)   := '';                         -- NULL
  -- �t�@�C������֘A
  cv_file_mode          CONSTANT VARCHAR2(1)   := 'W';                        -- �㏑
  -- ���̑��ėp
  cv_yes                CONSTANT VARCHAR2(1)   := 'Y';                        -- Y
  cv_sep_hyphen         CONSTANT VARCHAR2(1)   := '-';                        -- �n�C�t��
  cv_sep_underscore     CONSTANT VARCHAR2(1)   := '_';                        -- �A���_�[�X�R�A
  cv_sep_comma          CONSTANT VARCHAR2(1)   := ',';                        -- �J���}
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE row_id_tbl IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_rowid_tbl  row_id_tbl;               -- ���b�g�ʎ�����e�[�u��ROWID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_organization_id    mtl_parameters.organization_id%TYPE   DEFAULT NULL;  -- �݌ɑg�DID
  gt_base_code          hz_cust_accounts.account_number%TYPE  DEFAULT NULL;  -- ���_�R�[�h
  gd_request_date_from  DATE                                  DEFAULT NULL;  -- �p�����[�^����(From)
  gd_request_date_to    DATE                                  DEFAULT NULL;  -- �p�����[�^����(To)
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- ���b�g�ʈ������
  CURSOR g_target_data_cur(
     it_organization_id   mtl_parameters.organization_id%TYPE   -- �݌ɑg�DID
    ,it_base_code         hz_cust_accounts.account_number%TYPE  -- ���_�R�[�h
    ,id_request_date_from DATE                                  -- ����(From)
    ,id_request_date_to   DATE                                  -- ����(To)
  )
  IS
    SELECT  /*+
              LEADING( xlri )
              USE_NL( xlri msi )
            */
            xlri.rowid                        row_id                       -- ���b�g�ʈ������ROWID
           ,xlri.slip_num                     slip_num                     -- �`�[No
           ,xlri.base_code                    base_code                    -- ���_�R�[�h
           ,xlri.base_name                    base_name                    -- ���_��
           ,xlri.order_number                 order_number                 -- �󒍔ԍ�
           ,xlri.parent_shipping_status       parent_shipping_status       -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
           ,xlri.parent_shipping_status_name  parent_shipping_status_name  -- �o�׏��X�e�[�^�X����(�󒍔ԍ��P��)
           ,xlri.whse_code                    whse_code                    -- �ۊǏꏊ�R�[�h
           ,xlri.whse_name                    whse_name                    -- �ۊǏꏊ��
           ,xlri.location_code                location_code                -- ���P�[�V�����R�[�h
           ,xlri.location_name                location_name                -- ���P�[�V��������
           ,xlri.shipping_status              shipping_status              -- �o�׏��X�e�[�^�X
           ,xlri.shipping_status_name         shipping_status_name         -- �o�׏��X�e�[�^�X����
           ,xlri.chain_code                   chain_code                   -- �`�F�[���X�R�[�h
           ,xlri.chain_name                   chain_name                   -- �`�F�[���X��
           ,xlri.shop_code                    shop_code                    -- �X�܃R�[�h
           ,xlri.shop_name                    shop_name                    -- �X�ܖ�
           ,xlri.customer_code                customer_code                -- �ڋq�R�[�h
           ,xlri.customer_name                customer_name                -- �ڋq��
           ,xlri.center_code                  center_code                  -- �Z���^�[�R�[�h
           ,xlri.center_name                  center_name                  -- �Z���^�[��
           ,xlri.area_code                    area_code                    -- �n��R�[�h
           ,xlri.area_name                    area_name                    -- �n�於��
           ,xlri.shipped_date                 shipped_date                 -- �o�ד�
           ,xlri.arrival_date                 arrival_date                 -- ����
           ,xlri.item_div                     item_div                     -- ���i�敪
           ,xlri.item_div_name                item_div_name                -- ���i�敪��
           ,xlri.parent_item_code             parent_item_code             -- �e�i�ڃR�[�h
           ,xlri.parent_item_name             parent_item_name             -- �e�i�ږ���
           ,xlri.item_code                    item_code                    -- �q�i�ڃR�[�h
           ,xlri.item_name                    item_name                    -- �q�i�ږ���
           ,xlri.lot                          lot                          -- ���b�g =>�ܖ�����
           ,xlri.difference_summary_code      difference_summary_code      -- �ŗL�L��
           ,xlri.case_in_qty                  case_in_qty                  -- ����
           ,xlri.case_qty                     case_qty                     -- �P�[�X��
           ,xlri.singly_qty                   singly_qty                   -- �o����
           ,xlri.summary_qty                  summary_qty                  -- ����
           ,xlri.before_ordered_quantity      before_ordered_quantity      -- �����O�󒍐���
           ,xlri.regular_sale_class_line      regular_sale_class_line      -- ��ԓ����敪(����)
           ,xlri.regular_sale_class_name_line regular_sale_class_name_line -- ��ԓ����敪��(����)
           ,xlri.edi_received_date            edi_received_date            -- EDI��M��
           ,xlri.delivery_order_edi           delivery_order_edi           -- �z����(EDI)
    FROM    xxcoi_lot_reserve_info    xlri
           ,mtl_secondary_inventories msi
    WHERE   msi.organization_id          = it_organization_id
    AND     msi.attribute15              = cv_yes                   -- �z�M�ΏەۊǏꏊ
    AND     xlri.base_code               = it_base_code
    AND     xlri.arrival_date      BETWEEN id_request_date_from
                                   AND     id_request_date_to
    AND     msi.secondary_inventory_name = xlri.whse_code
    AND     msi.attribute7               = it_base_code
    AND     xlri.parent_shipping_status IN (
                                               cv_p_shipping_st_10
                                              ,cv_p_shipping_st_20
                                              ,cv_p_shipping_st_25
                                              ,cv_p_shipping_st_30
                                           )                        -- �������E�����ρE�o�׉��m��E�o�׊m��
    AND     xlri.wf_delivery_flag IS NULL                           -- ���z�M
    ORDER BY
            xlri.slip_num          ASC  -- �`�[No
           ,xlri.order_number      ASC  -- �󒍔ԍ�
           ,xlri.whse_code         ASC  -- �ۊǏꏊ�R�[�h
           ,xlri.location_code     ASC  -- ���P�[�V�����R�[�h
           ,xlri.parent_item_code  ASC  -- �e�i�ڃR�[�h
           ,xlri.item_code         ASC  -- �q�i�ڃR�[�h
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_login_base_code   IN  VARCHAR2     -- 1.���_�R�[�h
    ,iv_request_date_from IN  VARCHAR2     -- 2.�����iFrom�j
    ,iv_request_date_to   IN  VARCHAR2     -- 3.�����iTo�j
    ,ov_errbuf            OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lt_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  -- �݌ɑg�D�R�[�h
    lt_base_name          hz_parties.party_name%TYPE            DEFAULT NULL;  -- ���_����
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
    --==================================
    -- �݌ɑg�DID�擾
    --==================================
--
    -- �݌ɑg�D�R�[�h�擾
    lt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
--
    IF ( lt_organization_code IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00005
                     ,iv_token_name1  => cv_tkn_pro_tok
                     ,iv_token_value1 => cv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �݌ɑg�DID�擾
    gt_organization_id := xxcoi_common_pkg.get_organization_id( lt_organization_code );
--
    IF ( gt_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_00006
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => lt_organization_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ���_���̎擾
    --==================================
--
    gt_base_code := iv_login_base_code;
--
    BEGIN
      SELECT  hp.party_name  base_name
      INTO    lt_base_name
      FROM    hz_parties hp
             ,hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_cust_cls_cd_base
      AND     hca.account_number      = gt_base_code
      AND     hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_base_name := NULL;
    END;
--
    --==================================
    -- �p�����[�^�o��
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application        => cv_app_xxcoi
                   ,iv_name               => cv_msg_xxcoi_10717
                   ,iv_token_name1        => cv_tkn_param1
                   ,iv_token_value1       => gt_base_code
                   ,iv_token_name2        => cv_tkn_param_name1
                   ,iv_token_value2       => lt_base_name
                   ,iv_token_name3        => cv_tkn_param2
                   ,iv_token_value3       => iv_request_date_from
                   ,iv_token_name4        => cv_tkn_param3
                   ,iv_token_value4       => iv_request_date_to
                 );
--
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => NULL
    );
--
    --==================================
    -- ���t�t�]�`�F�b�N
    --==================================
--
    gd_request_date_from := TO_DATE( iv_request_date_from, cv_fmt_date_time_s );
    gd_request_date_to   := TO_DATE( iv_request_date_to  , cv_fmt_date_time_s );
--
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      -- �����t�]�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10531
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : output_data
   * Description      : CSV�o�͏���(A-2)
   ***********************************************************************************/
  PROCEDURE output_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec         DEFAULT NULL;  -- �t�@�C�����i�[���R�[�h
    lf_file_hand        UTL_FILE.FILE_TYPE                   DEFAULT NULL;  -- �t�@�C���E�n���h��
    lv_file_name        VARCHAR2(150)                        DEFAULT NULL;  -- �t�@�C����
    lv_csv_data         VARCHAR2(4000)                       DEFAULT NULL;  -- CSV������
    lt_slip_num         xxcoi_lot_reserve_info.slip_num%TYPE DEFAULT NULL;  -- �O���R�[�h�̓`�[No
    ln_cnt              NUMBER                               DEFAULT 0;     -- �z��Y����
    ln_loop_cnt         NUMBER                               DEFAULT 0;     -- ���������p
    ln_lock_dummy       NUMBER;                                             -- ���b�N�p�_�~�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    l_target_data_rec g_target_data_cur%ROWTYPE;
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
    --==================================
    -- ���[�N�t���[���擾
    --==================================
--
    -- ���ʊ֐��u�A�E�g�o�E���h�����擾�֐��v�ďo
    xxwsh_common3_pkg.get_wsh_wf_info(
       iv_wf_ope_div       => cv_ope_div     -- �����敪
      ,iv_wf_class         => cv_wf_class    -- �Ώ�
      ,iv_wf_notification  => gt_base_code   -- ����(���_�R�[�h)
      ,or_wf_whs_rec       => lr_wf_whs_rec  -- �t�@�C�����
      ,ov_errbuf           => lv_errbuf      -- �G���[�E���b�Z�[�W
      ,ov_retcode          => lv_retcode     -- ���^�[���E�R�[�h
      ,ov_errmsg           => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C�����ҏW
    lv_file_name := cv_ope_div                                                      -- �����敪
                    || cv_sep_hyphen     || gt_base_code                            -- ����
                    || cv_sep_underscore || TO_CHAR( SYSDATE, cv_fmt_date_time )    -- ��������
                    || lr_wf_whs_rec.file_name                                      -- �t�@�C����
    ;
--
    -- WF�I�[�i�[���N�����[�U�֕ύX
    lr_wf_whs_rec.wf_owner := fnd_global.user_name;
--
    --==================================
    -- �t�@�C���I�[�v��
    --==================================
    lf_file_hand := UTL_FILE.FOPEN(
                       lr_wf_whs_rec.directory -- �f�B���N�g��
                      ,lv_file_name            -- �t�@�C����
                      ,cv_file_mode            -- ���[�h�i�㏑�j
                    );
--
    --==================================
    -- ���b�g�ʈ�����񒊏o
    --==================================
    << target_data_loop>>
    FOR  l_target_data_rec IN g_target_data_cur(
                                 gt_organization_id      -- �݌ɑg�DID
                                ,gt_base_code            -- �p�����[�^.���_�R�[�h
                                ,gd_request_date_from    -- �p�����[�^.����(From)
                                ,gd_request_date_to      -- �p�����[�^.����(To)
                              )
    LOOP
--
      EXIT WHEN g_target_data_cur%NOTFOUND;
--
      -- �Ώی����J�E���g
      ln_loop_cnt := ln_loop_cnt + 1;
--
      -- ���[�v����A�������́A�O���R�[�h�̓`�[No�ƌ��R�[�h�̓`�[No���قȂ�ꍇ
      IF ( ( lt_slip_num IS NULL ) OR ( lt_slip_num <> l_target_data_rec.slip_num ) )THEN
--
        -- ������
        lv_csv_data := NULL;
--
        --==================================
        -- �w�b�_���o��
        --==================================
--
        -- �o�̓f�[�^�̕ҏW
        lv_csv_data := cv_company_name                                           || cv_sep_comma || -- ��Ж�
                       cv_data_type                                              || cv_sep_comma || -- �f�[�^���
                       cv_branch_no_header                                       || cv_sep_comma || -- �`���p�}��
                       l_target_data_rec.slip_num                                || cv_sep_comma || -- �`�[No
                       l_target_data_rec.base_code                               || cv_sep_comma || -- ���_�R�[�h
                       l_target_data_rec.base_name                               || cv_sep_comma || -- ���_��
                       cv_null                                                   || cv_sep_comma || -- �󒍔ԍ�
                       cv_null                                                   || cv_sep_comma || -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
                       cv_null                                                   || cv_sep_comma || -- �o�׏��X�e�[�^�X��(�󒍔ԍ��P��)
                       cv_null                                                   || cv_sep_comma || -- �ۊǏꏊ�R�[�h
                       cv_null                                                   || cv_sep_comma || -- �ۊǏꏊ��
                       cv_null                                                   || cv_sep_comma || -- ���P�[�V�����R�[�h
                       cv_null                                                   || cv_sep_comma || -- ���P�[�V������
                       cv_null                                                   || cv_sep_comma || -- �o�׏��X�e�[�^�X
                       cv_null                                                   || cv_sep_comma || -- �o�׏��X�e�[�^�X��
                       cv_null                                                   || cv_sep_comma || -- �`�F�[���X�R�[�h
                       cv_null                                                   || cv_sep_comma || -- �`�F�[���X��
                       cv_null                                                   || cv_sep_comma || -- �X�܃R�[�h
                       cv_null                                                   || cv_sep_comma || -- �X�ܖ�
                       cv_null                                                   || cv_sep_comma || -- �ڋq�R�[�h
                       cv_null                                                   || cv_sep_comma || -- �ڋq��
                       cv_null                                                   || cv_sep_comma || -- �Z���^�[�R�[�h
                       cv_null                                                   || cv_sep_comma || -- �Z���^�[��
                       cv_null                                                   || cv_sep_comma || -- �n��R�[�h
                       cv_null                                                   || cv_sep_comma || -- �n�於��
                       cv_null                                                   || cv_sep_comma || -- �o�ד�
                       cv_null                                                   || cv_sep_comma || -- ����
                       cv_null                                                   || cv_sep_comma || -- ���i�敪
                       cv_null                                                   || cv_sep_comma || -- ���i�敪��
                       cv_null                                                   || cv_sep_comma || -- �e�i�ڃR�[�h
                       cv_null                                                   || cv_sep_comma || -- �e�i�ږ���
                       cv_null                                                   || cv_sep_comma || -- �q�i�ڃR�[�h
                       cv_null                                                   || cv_sep_comma || -- �q�i�ږ���
                       cv_null                                                   || cv_sep_comma || -- �ܖ�����
                       cv_null                                                   || cv_sep_comma || -- �ŗL�L��
                       cv_null                                                   || cv_sep_comma || -- ����
                       cv_null                                                   || cv_sep_comma || -- �P�[�X��
                       cv_null                                                   || cv_sep_comma || -- �o����
                       cv_null                                                   || cv_sep_comma || -- �������
                       cv_null                                                   || cv_sep_comma || -- �󒍐���
                       cv_null                                                   || cv_sep_comma || -- ��ԓ����敪
                       cv_null                                                   || cv_sep_comma || -- ��ԓ����敪��
                       cv_null                                                   || cv_sep_comma || -- EDI��M��
                       cv_null                                                   || cv_sep_comma || -- �z����(EDI)
                       cv_null                                                   || cv_sep_comma || -- �f�[�^�敪
                       TO_CHAR( SYSDATE, cv_fmt_date_time_s )                                       -- �X�V��
        ;
--
        -- �w�b�_�o��
        UTL_FILE.PUT_LINE(
          lf_file_hand
         ,lv_csv_data
        );
--
      END IF;
--
      --==================================
      -- ���׏��o��
      --==================================
--
      -- ������
      lv_csv_data := NULL;
--
      -- �o�̓f�[�^�̕ҏW
      lv_csv_data := cv_company_name                                             || cv_sep_comma || -- ��Ж�
                     cv_data_type                                                || cv_sep_comma || -- �f�[�^���
                     cv_branch_no_line                                           || cv_sep_comma || -- �`���p�}��
                     cv_null                                                     || cv_sep_comma || -- �`�[No
                     cv_null                                                     || cv_sep_comma || -- ���_�R�[�h
                     cv_null                                                     || cv_sep_comma || -- ���_��
                     l_target_data_rec.order_number                              || cv_sep_comma || -- �󒍔ԍ�
                     l_target_data_rec.parent_shipping_status                    || cv_sep_comma || -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)
                     l_target_data_rec.parent_shipping_status_name               || cv_sep_comma || -- �o�׏��X�e�[�^�X��(�󒍔ԍ��P��)
                     l_target_data_rec.whse_code                                 || cv_sep_comma || -- �ۊǏꏊ�R�[�h
                     l_target_data_rec.whse_name                                 || cv_sep_comma || -- �ۊǏꏊ��
                     l_target_data_rec.location_code                             || cv_sep_comma || -- ���P�[�V�����R�[�h
                     l_target_data_rec.location_name                             || cv_sep_comma || -- ���P�[�V������
                     l_target_data_rec.shipping_status                           || cv_sep_comma || -- �o�׏��X�e�[�^�X
                     l_target_data_rec.shipping_status_name                      || cv_sep_comma || -- �o�׏��X�e�[�^�X��
                     l_target_data_rec.chain_code                                || cv_sep_comma || -- �`�F�[���X�R�[�h
                     l_target_data_rec.chain_name                                || cv_sep_comma || -- �`�F�[���X��
                     l_target_data_rec.shop_code                                 || cv_sep_comma || -- �X�܃R�[�h
                     l_target_data_rec.shop_name                                 || cv_sep_comma || -- �X�ܖ�
                     l_target_data_rec.customer_code                             || cv_sep_comma || -- �ڋq�R�[�h
                     l_target_data_rec.customer_name                             || cv_sep_comma || -- �ڋq��
                     l_target_data_rec.center_code                               || cv_sep_comma || -- �Z���^�[�R�[�h
                     l_target_data_rec.center_name                               || cv_sep_comma || -- �Z���^�[��
                     l_target_data_rec.area_code                                 || cv_sep_comma || -- �n��R�[�h
                     l_target_data_rec.area_name                                 || cv_sep_comma || -- �n�於��
                     TO_CHAR( l_target_data_rec.shipped_date, cv_fmt_date )      || cv_sep_comma || -- �o�ד�
                     TO_CHAR( l_target_data_rec.arrival_date, cv_fmt_date )      || cv_sep_comma || -- ����
                     l_target_data_rec.item_div                                  || cv_sep_comma || -- ���i�敪
                     l_target_data_rec.item_div_name                             || cv_sep_comma || -- ���i�敪��
                     l_target_data_rec.parent_item_code                          || cv_sep_comma || -- �e�i�ڃR�[�h
                     l_target_data_rec.parent_item_name                          || cv_sep_comma || -- �e�i�ږ���
                     l_target_data_rec.item_code                                 || cv_sep_comma || -- �q�i�ڃR�[�h
                     l_target_data_rec.item_name                                 || cv_sep_comma || -- �q�i�ږ���
                     l_target_data_rec.lot                                       || cv_sep_comma || -- �ܖ�����
                     l_target_data_rec.difference_summary_code                   || cv_sep_comma || -- �ŗL�L��
                     l_target_data_rec.case_in_qty                               || cv_sep_comma || -- ����
                     l_target_data_rec.case_qty                                  || cv_sep_comma || -- �P�[�X��
                     l_target_data_rec.singly_qty                                || cv_sep_comma || -- �o����
                     l_target_data_rec.summary_qty                               || cv_sep_comma || -- �������
                     l_target_data_rec.before_ordered_quantity                   || cv_sep_comma || -- �󒍐���
                     l_target_data_rec.regular_sale_class_line                   || cv_sep_comma || -- ��ԓ����敪
                     l_target_data_rec.regular_sale_class_name_line              || cv_sep_comma || -- ��ԓ����敪��
                     TO_CHAR( l_target_data_rec.edi_received_date, cv_fmt_date)  || cv_sep_comma || -- EDI��M��
                     l_target_data_rec.delivery_order_edi                        || cv_sep_comma || -- �z����(EDI)
                     cv_data_class                                               || cv_sep_comma || -- �f�[�^�敪
                     TO_CHAR( SYSDATE, cv_fmt_date_time_s )                                         -- �X�V��
      ;
--
      -- ���׏o��
      UTL_FILE.PUT_LINE(
        lf_file_hand
       ,lv_csv_data
      );
--
      -- �w�b�_�o�͔���ׁ̈A�`�[No��ϐ��ɕێ�
      lt_slip_num := l_target_data_rec.slip_num;
--
      -- �o�׏��X�e�[�^�X(�󒍔ԍ��P��)���u�o�׉��m��v�u�o�׊m��v�̏ꍇ
      IF ( l_target_data_rec.parent_shipping_status IN ( cv_p_shipping_st_25, cv_p_shipping_st_30 ) ) THEN
        --==================================
        -- ���b�N�擾
        --==================================
        -- �z�M��̃��b�N�G���[�������ׁA�����Ń��b�N
        SELECT 1  dummy
        INTO   ln_lock_dummy
        FROM   xxcoi_lot_reserve_info    xlri
        WHERE  xlri.rowid = l_target_data_rec.row_id
        FOR UPDATE OF
               xlri.lot_reserve_info_id
        NOWAIT
        ;
        -- ���b�g�ʈ������X�V�ׁ̈AROWID���i�[
        ln_cnt               := ln_cnt + 1;
        gt_rowid_tbl(ln_cnt) := l_target_data_rec.row_id;
      END IF;
--
    END LOOP target_data_loop;
--
    -- �Ώی����E���������̐ݒ�
    gn_target_cnt := ln_loop_cnt;
--
    --==================================
    -- �t�@�C���N���[�Y
    --==================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    --==================================
    -- ���[�N�t���[�ʒm
    --==================================
    -- �Ώۂ����݂���ꍇ�̂ݒʒm
    IF ( gn_target_cnt <> 0 ) THEN
--
      -- ���[�N�t���[�N���֐������s
      xxwsh_common3_pkg.wf_whs_start(
         ir_wf_whs_rec => lr_wf_whs_rec      -- ���[�N�t���[�֘A���
        ,iv_filename   => lv_file_name       -- �t�@�C����
        ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W
        ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h
        ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
--
    -- �Ώی�����0���̏ꍇ�͌x��
    ELSE
      -- ���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10716
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --�X�e�[�^�X���x���ɂ���
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
    -- *** ���b�N��O�n���h�� ***--
    WHEN global_lock_expt THEN
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE( lf_file_hand );
      -- ���b�Z�[�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_xxcoi
                     ,iv_name         => cv_msg_xxcoi_10039
                   );
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_lot_reserve_info
   * Description      : ���b�g�ʈ������X�V����(A-3)
   ***********************************************************************************/
  PROCEDURE upd_lot_reserve_info(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lot_reserve_info'; -- �v���O������
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
    BEGIN
      -- ���b�g�ʈ������e�[�u���X�V
      FORALL i IN 1.. gt_rowid_tbl.COUNT
        UPDATE  xxcoi_lot_reserve_info xilri
        SET     xilri.wf_delivery_flag          =   cv_yes               --WF�z�M�t���O(�z�M��)
               ,xilri.last_update_date          =   cd_last_update_date
               ,xilri.last_updated_by           =   cn_last_updated_by
               ,xilri.last_update_login         =   cn_last_update_login
               ,xilri.request_id                =   cn_request_id
               ,xilri.program_id                =   cn_program_id
               ,xilri.program_application_id    =   cn_program_application_id
               ,xilri.program_update_date       =   cd_last_update_date
        WHERE   xilri.rowid  =  gt_rowid_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ���b�Z�[�W����
        lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_xxcoi
               ,iv_name         => cv_msg_xxcoi_10718
               ,iv_token_name1  => cv_tkn_err_msg
               ,iv_token_value1 => SQLERRM
             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END upd_lot_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_login_base_code    IN  VARCHAR2     -- 1.���_�R�[�h
    ,iv_request_date_from  IN  VARCHAR2     -- 2.�����iFrom�j
    ,iv_request_date_to    IN  VARCHAR2     -- 3.�����iTo�j
    ,ov_errbuf             OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode            OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_login_base_code    => iv_login_base_code     -- 1.���_�R�[�h
      ,iv_request_date_from  => iv_request_date_from   -- 2.�����iFrom�j
      ,iv_request_date_to    => iv_request_date_to     -- 3.�����iTo�j
      ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSV�o�͏���(A-2)
    -- ===============================
    output_data(
       ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_warn) THEN
      RAISE global_warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �o�׉��m��E�o�׊m��̏o�͑Ώۂ����݂����ꍇ
    IF ( gt_rowid_tbl.COUNT <> 0 ) THEN
      -- ===============================
      -- ���b�g�ʈ������X�V����(A-3)
      -- ===============================
      upd_lot_reserve_info(
         ov_errbuf   => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode  => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg   => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
    -- *** �x����(�ΏۂȂ�) ***
    WHEN global_warn_expt THEN
      -- �������x���I���Ƃ���
      ov_retcode := lv_retcode;
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_login_base_code    IN  VARCHAR2,      -- 1.���_�R�[�h
    iv_request_date_from  IN  VARCHAR2,      -- 2.�����iFrom�j
    iv_request_date_to    IN  VARCHAR2       -- 3.�����iTo�j
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
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_login_base_code    => iv_login_base_code    -- 1.���_�R�[�h
      ,iv_request_date_from  => iv_request_date_from  -- 2.�����iFrom�j
      ,iv_request_date_to    => iv_request_date_to    -- 3.�����iTo�j
      ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --�����ݒ�
      gn_target_cnt := 0;  -- �Ώی���
      gn_normal_cnt := 0;  -- ��������
      gn_error_cnt  := 1;  -- �G���[����
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- �����ݒ�(�x��)
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
    ELSE
      -- �����ݒ�(����)
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    FND_FILE.PUT_LINE(
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
END XXCOI017A02C;
/
