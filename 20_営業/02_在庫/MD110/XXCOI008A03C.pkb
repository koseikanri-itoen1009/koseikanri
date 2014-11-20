CREATE OR REPLACE PACKAGE BODY XXCOI008A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A03C(body)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̌����݌Ɏ󕥕\(�A�h�I��)��CSV�t�@�C���ɏo��
 * MD.050           : ���ʎ󕥎c�����n�A�g <MD050_COI_008_A03>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           �݌v���Ȃ��I���f�[�^CSV�쐬(A-9)
 *  create_csv_p           ��(�݌�)CSV�̍쐬(A-6)
 *  get_inv_info_p         �I�����擾(A-5)
 *  recept_month_cur_p     �����݌Ɏ󕥕\(�݌v)���̒��o(A-4)
 *  get_open_period_p      �I�[�v���݌ɉ�v���Ԏ擾(A-3)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���̃I�[�v������(A-2)
 *                           �E�t�@�C���̃N���[�Y����(A-7) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �E�����\������(A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/07    1.0   S.Kanda          �V�K�쐬
 *  2009/04/08    1.1   T.Nakamura       [��Q T1_0197] �����݌Ɏ󕥕\�i�݌v�j�f�[�^�����
 *                                                      �󕥎c�������擾����悤�ύX
 *  2010/01/06    1.2   N.Abe            [E_�{�ғ�_00630] ��݌ɕύX�̎Z�o��ύX
 *                                                        �I�����̑��M��ǉ�
 *  2010/02/03    1.3   H.Sasaki         [E_�{�ғ�_01424] ���ʍ��ڂ��S�ĂO�̃��R�[�h��
 *                                                        �A�g���Ȃ��悤�C��
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOI008A03C';
  cv_appl_short_name_ccp    CONSTANT VARCHAR2(10)  := 'XXCCP';         -- �A�h�I���F���ʁEIF�̈�
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCOI';         -- �A�h�I���F���ʁEIF�̈�
  cv_file_slash             CONSTANT VARCHAR2(2)   := '/';             -- �t�@�C����؂�p
  cv_file_encloser          CONSTANT VARCHAR2(2)   := '"';             -- �����f�[�^����p
  cv_inv_kbn_2              CONSTANT VARCHAR2(2)   := '2';             -- �I���敪(����)
  cv_yes                    CONSTANT VARCHAR2(2)   := 'Y';             -- �t���O�p�ϐ�
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_process_type_0         CONSTANT VARCHAR2(2)   := '0';             -- �����敪(����)
  cv_process_type_1         CONSTANT VARCHAR2(2)   := '1';             -- �����敪(����)
  cv_fmt_date               CONSTANT VARCHAR2(6)   := 'YYYYMM';        -- ���t�^�t�H�[�}�b�g
  cv_fmt_date_hyp           CONSTANT VARCHAR2(7)   := 'YYYY-MM';       -- ���t�^�t�H�[�}�b�g(�n�C�t��)
-- == 2009/04/08 V1.1 Added START ===============================================================
  --
  -- ���b�Z�[�W�萔
  cv_msg_xxcoi_00003        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';
  cv_msg_xxcoi_00004        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';
  cv_msg_xxcoi_00005        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';
  cv_msg_xxcoi_00006        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';
  cv_msg_xxcoi_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00007';
  cv_msg_xxcoi_00008        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';
  cv_msg_xxcoi_00023        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00023';
  cv_msg_xxcoi_00027        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';
  cv_msg_xxcoi_00028        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';
  cv_msg_xxcoi_00029        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_msg_xxcoi_10374        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10374';
  cv_msg_xxcoi_10375        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10375';
  cv_msg_xxcoi_00011        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';
  cv_msg_xxcoi_10376        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10376';
  cv_msg_xxcoi_10377        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10377';
-- == 2009/04/08 V1.1 Added END   ===============================================================
  --
  --�g�[�N��
  cv_tkn_pro                CONSTANT VARCHAR2(10)  := 'PRO_TOK';       -- �v���t�@�C�����p
  cv_tkn_dir                CONSTANT VARCHAR2(10)  := 'DIR_TOK';       -- �v���t�@�C�����p
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';         -- �������b�Z�[�W�p
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';     -- �t�@�C�����p
  cv_tkn_org_code           CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';  -- �݌ɑg�D�R�[�h�p
-- == 2009/04/08 V1.1 Added START ===============================================================
  cv_tkn_process_type       CONSTANT VARCHAR2(15)  := 'PROCESS_TYPE';  -- �����敪�p
  cv_tkn_month              CONSTANT VARCHAR2(15)  := 'MONTH';         -- �N���p
  cv_tkn_base_code          CONSTANT VARCHAR2(15)  := 'BASE_CODE';     -- ���_�R�[�h�p
  cv_tkn_subinventory       CONSTANT VARCHAR2(15)  := 'SUBINVENTORY';  -- �ۊǏꏊ�R�[�h�p
  cv_tkn_item_code          CONSTANT VARCHAR2(15)  := 'ITEM_CODE';     -- �i�ڃR�[�h�p
-- == 2009/04/08 V1.1 Added END   ===============================================================
  --
  --�t�@�C���I�[�v�����[�h
  cv_file_mode              CONSTANT VARCHAR2(2)   := 'W';             -- �I�[�v�����[�h
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                  -- �Ɩ��������t�擾�p
  gv_dire_pass          VARCHAR2(100);                         -- �f�B���N�g���p�X���p
  gv_file_recept_month  VARCHAR2(50);                          -- ���ʎ󕥎c���t�@�C�����p
  gv_organization_code  VARCHAR2(50);                          -- �݌ɑg�D�R�[�h�擾�p
  gn_organization_id    mtl_parameters.organization_id%TYPE;   -- �݌ɑg�DID�擾�p
  gv_company_code       VARCHAR2(50);                          -- ��ЃR�[�h�擾�p
  gv_file_name          VARCHAR2(150);                         -- �t�@�C���p�X���擾�p
  gv_activ_file_h       UTL_FILE.FILE_TYPE;                    -- �t�@�C���n���h���擾�p
-- == 2009/04/08 V1.1 Added START ===============================================================
  gv_process_type          VARCHAR2(1);                        -- �����敪
  gd_sysdate               DATE;                               -- �V�X�e�����t
  gn_open_period_cnt       NUMBER;                             -- �݌ɉ�v���Ԏ擾����
  gn_month_begin_quantity  NUMBER;                             -- ����I����
  gn_inv_result            NUMBER;                             -- �I������
  gn_inv_result_bad        NUMBER;                             -- �I������(�s�Ǖi)
  gn_inv_wear              NUMBER;                             -- �I������
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
  -- ==============================
  -- ���[�U�[��`�J�[�\��
  -- ==============================
-- == 2009/04/08 V1.1 Added START ===============================================================
  -- �I�[�v���݌ɉ�v���Ԏ擾�J�[�\��
  CURSOR get_open_period_cur
  IS
    SELECT   TO_CHAR( oap.period_start_date, cv_fmt_date ) AS year_month
    FROM     org_acct_periods       oap
    WHERE    oap.organization_id  = gn_organization_id
    AND      oap.open_flag        = cv_yes
    AND      oap.period_name     <= TO_CHAR( gd_process_date, cv_fmt_date_hyp )
    ORDER BY year_month
  ;
  TYPE get_open_period_ttype IS TABLE OF get_open_period_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  get_open_period_tab        get_open_period_ttype;
-- == 2009/04/08 V1.1 Added END   ===============================================================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--  -- ���ʎ󕥎c�����擾
--  CURSOR recept_month_cur
--  IS
--    SELECT xirm.practice_month          -- �N��
--         , xirm.base_code               -- ���_�R�[�h
--         , xirm.subinventory_code       -- �ۊǏꏊ
--         , xirm.subinventory_type       -- �ۊǏꏊ�敪
--         , xirm.operation_cost          -- �c�ƌ���
--         , xirm.standard_cost           -- �W������
--         , xirm.month_begin_quantity    -- ����I����
--         , xirm.factory_stock           -- �H�����
--         , xirm.factory_stock_b         -- �H����ɐU��
--         , xirm.change_stock            -- �q�֓���
--         , xirm.warehouse_stock         -- �q�ɂ���̓���
--         , xirm.truck_stock             -- �c�ƎԂ���̓���
--         , xirm.others_stock            -- ���o�ɁQ���̑�����
--         , xirm.goods_transfer_new      -- ���i�U��(�V���i)
--         , xirm.sales_shipped           -- ����o��
--         , xirm.sales_shipped_b         -- ����o�ɐU��
--         , xirm.return_goods            -- �ԕi
--         , xirm.return_goods_b          -- �ԕi�U��
--         , xirm.change_ship             -- �q�֏o��
--         , xirm.warehouse_ship          -- �q�ɂ֏o��
--         , xirm.truck_ship              -- �c�ƎԂ֏o��
--         , xirm.others_ship             -- ���o�ɁQ���̑��o��
--         , xirm.inventory_change_in     -- ��݌ɕύX����
--         , xirm.inventory_change_out    -- ��݌ɕύX�o��
--         , xirm.factory_return          -- �H��ԕi
--         , xirm.factory_return_b        -- �H��ԕi�U��
--         , xirm.factory_change          -- �H��q��
--         , xirm.factory_change_b        -- �H��q�֐U��
--         , xirm.removed_goods           -- �p�p
--         , xirm.removed_goods_b         -- �p�p�U��
--         , xirm.goods_transfer_old      -- ���i�U��(�����i)
--         , xirm.sample_quantity         -- ���{�o��
--         , xirm.sample_quantity_b       -- ���{�o�ɐU��
--         , xirm.customer_sample_ship    -- �ڋq���{�o��
--         , xirm.customer_sample_ship_b  -- �ڋq���{�o�ɐU��
--         , xirm.customer_support_ss     -- �ڋq���^���{�o��
--         , xirm.customer_support_ss_b   -- �ڋq���^���{�o�ɐU��
--         , xirm.ccm_sample_ship         -- �ڋq�L����`��A���Џ��i
--         , xirm.ccm_sample_ship_b       -- �ڋq�L����`��A���Џ��i�U��
--         , xirm.inv_result              -- �I������
--         , xirm.inv_result_bad          -- �I������(�s�Ǖi)
--         , xirm.inv_wear                -- �I������
--         , xirm.last_update_date        -- �ŏI�X�V��
--         , msib.segment1                -- �i�ڃR�[�h
--    FROM   xxcoi_inv_reception_monthly  xirm  -- �����݌Ɏ󕥕\�e�[�u��
--         , mtl_system_items_b           msib  -- �i�ڃ}�X�^
--         , org_acct_periods             oap   -- �݌ɉ�v����
--    WHERE  xirm.inventory_kbn       = cv_inv_kbn_2            -- �I���敪(����)
--    AND    msib.inventory_item_id   = xirm.inventory_item_id  -- �i��ID
--    AND    msib.organization_id     = gn_organization_id      -- A-1.�Ŏ擾�����݌ɑg�DID
--    AND    oap.organization_id      = msib.organization_id    -- �g�DID
--    AND    xirm.practice_date                           -- �����݌Ɏ󕥕\�e�[�u��.�N����
--      BETWEEN oap.period_start_date                     -- ��v���ԊJ�n��
--      AND     oap.schedule_close_date                   -- �N���[�Y�\���
--    AND    oap.open_flag            = cv_yes;           -- �I�[�v���t���O
--
--    --
--    -- recept_month���R�[�h�^
--    recept_month_rec   recept_month_cur%ROWTYPE;
    -- �����݌Ɏ󕥕\(�݌v)��񒊏o�J�[�\��
    CURSOR recept_month_cur(
             iv_practice_date              IN VARCHAR2
           )
    IS
      SELECT xirs.organization_id          AS organization_id           -- �g�DID
           , xirs.inventory_item_id        AS inventory_item_id         -- �i��ID
           , xirs.practice_date            AS practice_date             -- �N��
           , xirs.base_code                AS base_code                 -- ���_�R�[�h
           , xirs.subinventory_code        AS subinventory_code         -- �ۊǏꏊ
           , xirs.subinventory_type        AS subinventory_type         -- �ۊǏꏊ�敪
           , xirs.operation_cost           AS operation_cost            -- �c�ƌ���
           , xirs.standard_cost            AS standard_cost             -- �W������
           , xirs.factory_stock            AS factory_stock             -- �H�����
           , xirs.factory_stock_b          AS factory_stock_b           -- �H����ɐU��
           , xirs.change_stock             AS change_stock              -- �q�֓���
           , xirs.warehouse_stock          AS warehouse_stock           -- �q�ɂ�����
           , xirs.truck_stock              AS truck_stock               -- �c�ƎԂ�����
           , xirs.others_stock             AS others_stock              -- ���o�ɁQ���̑�����
           , xirs.goods_transfer_new       AS goods_transfer_new        -- ���i�U��(�V���i)
           , xirs.sales_shipped            AS sales_shipped             -- ����o��
           , xirs.sales_shipped_b          AS sales_shipped_b           -- ����o�ɐU��
           , xirs.return_goods             AS return_goods              -- �ԕi
           , xirs.return_goods_b           AS return_goods_b            -- �ԕi�U��
           , xirs.change_ship              AS change_ship               -- �q�֏o��
           , xirs.warehouse_ship           AS warehouse_ship            -- �q�ɂ֕Ԍ�
           , xirs.truck_ship               AS truck_ship                -- �c�ƎԂ֏o��
           , xirs.others_ship              AS others_ship               -- ���o�ɁQ���̑��o��
           , xirs.inventory_change_in      AS inventory_change_in       -- ��݌ɕύX����
           , xirs.inventory_change_out     AS inventory_change_out      -- ��݌ɕύX�o��
           , xirs.factory_return           AS factory_return            -- �H��ԕi
           , xirs.factory_return_b         AS factory_return_b          -- �H��ԕi�U��
           , xirs.factory_change           AS factory_change            -- �H��q��
           , xirs.factory_change_b         AS factory_change_b          -- �H��q�֐U��
           , xirs.removed_goods            AS removed_goods             -- �p�p
           , xirs.removed_goods_b          AS removed_goods_b           -- �p�p�U��
           , xirs.goods_transfer_old       AS goods_transfer_old        -- ���i�U��(�����i)
           , xirs.sample_quantity          AS sample_quantity           -- ���{�o��
           , xirs.sample_quantity_b        AS sample_quantity_b         -- ���{�o�ɐU��
           , xirs.customer_sample_ship     AS customer_sample_ship      -- �ڋq���{�o��
           , xirs.customer_sample_ship_b   AS customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           , xirs.customer_support_ss      AS customer_support_ss       -- �ڋq���^���{�o��
           , xirs.customer_support_ss_b    AS customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           , xirs.ccm_sample_ship          AS ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           , xirs.ccm_sample_ship_b        AS ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
           , xirs.book_inventory_quantity  AS book_inventory_quantity   -- ����݌ɐ�
           , xirs.last_update_date         AS last_update_date          -- �ŏI�X�V��
           , msib.segment1                 AS segment1                  -- �i�ڃR�[�h
      FROM   xxcoi_inv_reception_sum       xirs                         -- �����݌Ɏ󕥕\(�݌v)�e�[�u��
           , mtl_system_items_b            msib                         -- �i�ڃ}�X�^
      WHERE  xirs.practice_date            =  iv_practice_date          -- �N��
      AND    msib.inventory_item_id        =  xirs.inventory_item_id    -- �i��ID
      AND    msib.organization_id          =  gn_organization_id        -- A-1.�Ŏ擾�����݌ɑg�DID
      ;
      recept_month_rec   recept_month_cur%ROWTYPE;
-- == 2009/04/08 V1.1 Moded END   ===============================================================
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
    --�v���t�@�C���擾�p�萔
    cv_pro_dire_out_info      CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_INFO';
    cv_pro_file_recept_month  CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_RECEPT_MONTH';
    cv_pro_org_code           CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';
    cv_pro_company_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_COMPANY_CODE';
--
    -- *** ���[�J���ϐ� ***
    lv_directory_path       VARCHAR2(100);     -- �f�B���N�g���p�X�擾�p
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===============================
    --  ����������
    -- ===============================
    gd_process_date       :=  NULL;          -- �Ɩ����t
    gv_dire_pass          :=  NULL;          -- �f�B���N�g���p�X��
    gv_file_recept_month  :=  NULL;          -- ���ʎ󕥎c���t�@�C����
    gv_organization_code  :=  NULL;          -- �݌ɑg�D�R�[�h��
    gn_organization_id    :=  NULL;          -- �݌ɑg�DID��
    gv_company_code       :=  NULL;          -- ��ЃR�[�h��
    gv_file_name          :=  NULL;          -- �t�@�C���p�X��
    lv_directory_path     :=  NULL;          -- �f�B���N�g���t���p�X
-- == 2009/04/08 V1.1 Added START ===============================================================
    gd_sysdate              := NULL;         -- �V�X�e�����t
    gn_open_period_cnt      := 0;            -- �݌ɉ�v���Ԏ擾����
    gn_month_begin_quantity := NULL;         -- ����I����
    gn_inv_result           := NULL;         -- �I������
    gn_inv_result_bad       := NULL;         -- �I������(�s�Ǖi)
    gn_inv_wear             := NULL;         -- �I������
-- == 2009/04/08 V1.1 Added END   ===============================================================
    --
    -- ===============================
    --  1.SYSDATE�擾
    -- ===============================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    gd_process_date   :=  sysdate;
    gd_sysdate   :=  SYSDATE;
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    --
    -- ====================================================
    -- 2.���n_OUTBOUND�i�[�f�B���N�g���������擾
    -- ====================================================
    gv_dire_pass      := fnd_profile.value( cv_pro_dire_out_info );
--
    -- �f�B���N�g������񂪎擾�ł��Ȃ������ꍇ
    IF ( gv_dire_pass IS NULL ) THEN
      -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�f�B���N�g����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00003
                      , iv_token_name1  => cv_tkn_pro
                      , iv_token_value1 => cv_pro_dire_out_info
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 3.���ʎ󕥎c���t�@�C�������擾
    -- =======================================
    gv_file_recept_month   := fnd_profile.value( cv_pro_file_recept_month );
    --
    -- ���ʎ󕥎c���t�@�C�������擾�ł��Ȃ������ꍇ
    IF ( gv_file_recept_month IS NULL ) THEN
      -- �t�@�C�����擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�t�@�C����( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00004
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_file_recept_month
                      );
      lv_errbuf    := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 4.�݌ɑg�D�R�[�h���擾
    -- =====================================
    gv_organization_code := fnd_profile.value( cv_pro_org_code );
    --
    -- �݌ɑg�D�R�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_organization_code  IS NULL ) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:�݌ɑg�D�R�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00005
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_org_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- �݌ɑg�DID�擾
    -- =====================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id( gv_organization_code );
    --
    -- ���ʊ֐��̃��^�[���R�[�h���擾�ł��Ȃ������ꍇ
    IF ( gn_organization_id IS NULL ) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      -- �u�݌ɑg�D�R�[�h( ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B�v
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00006
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================
    -- 5.��ЃR�[�h���擾
    -- =====================================
    gv_company_code  := fnd_profile.value( cv_pro_company_code );
    --
    -- ��ЃR�[�h���擾�ł��Ȃ������ꍇ
    IF  ( gv_company_code  IS NULL ) THEN
      -- ��ЃR�[�h�擾�G���[���b�Z�[�W
      -- �u�v���t�@�C��:��ЃR�[�h( PRO_TOK )�̎擾�Ɏ��s���܂����B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_00007
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_pro_company_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    -- 6.���b�Z�[�W�̏o�͇@
    -- =====================================
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���o��
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_appl_short_name
--                     , iv_name         => cv_msg_xxcoi_00023
--                    );
    -- ���̓p�����[�^.�����敪�̓��e���o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_10374
                     , iv_token_name1  => cv_tkn_process_type
                     , iv_token_value1 => gv_process_type
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
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
    --
    -- ���̓p�����[�^.�����敪��NULL�̏ꍇ
    IF ( gv_process_type IS NULL ) THEN
      -- ���̓p�����[�^���ݒ�G���[�i�����敪�j
      -- �u���̓p�����[�^�F�����敪�����ݒ�ł��B�v
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                       , iv_name         => cv_msg_xxcoi_10375
                      );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    -- =====================================
    -- 7.���b�Z�[�W�̏o�͇A
    -- =====================================
    --
    -- 2.�Ŏ擾�����v���t�@�C���l���f�B���N�g���p�X���擾
    BEGIN
      SELECT directory_path
      INTO   lv_directory_path
      FROM   all_directories     -- �f�B���N�g�����
      WHERE  directory_name = gv_dire_pass;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
        -- �u���̃f�B���N�g�����ł̓f�B���N�g���p�X�͎擾�ł��܂���B
        -- �i�f�B���N�g���� = DIR_TOK �j�v
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00029
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_pass
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j���o��
    -- '�f�B���N�g���p�X'��'/'�Ɓe�t�@�C����'������
    gv_file_name  := lv_directory_path || cv_file_slash || gv_file_recept_month;
    --�u�t�@�C���F FILE_NAME �v
    --�t�@�C�����o�̓��b�Z�[�W
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_00028
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_file_name
                    );
    --
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
-- == 2009/04/08 V1.1 Added START ===============================================================
    -- ===================================
    --  9.�Ɩ��������t�擾
    -- ===================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errmsg   := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                      , iv_name          => cv_msg_xxcoi_00011
                     );
      lv_errbuf   := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
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
-- == 2010/01/06 V1.2 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : create_csv_i
   * Description      : �݌v���Ȃ��I���f�[�^CSV�쐬(A-9)
   ***********************************************************************************/
  PROCEDURE create_csv_i(
     iv_year_month IN  VARCHAR2     --   �N��
   , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_i'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_recept_month     VARCHAR2(3000);  -- CSV�o�͗p�ϐ�
    lv_process_date     VARCHAR2(14);    -- �V�X�e�����t �i�[�p�ϐ�
    lv_last_update_date VARCHAR2(14);    -- �ŏI�X�V�� �i�[�p�ϐ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �󕥑S���ڂO�ŁA�I���̂ݍs���Ă���A�݌v�e�[�u���Ƀf�[�^�����݂��Ȃ��B
    -- ���́A�󕥑S���ڂO�ŁA����݌ɂ̂ݑ��݂��A�݌v�e�[�u���Ƀf�[�^�����݂��Ȃ��B
    -- �݌v���Ȃ��f�[�^���o
    CURSOR  get_no_sumdata_cur(
             iv_year_month              IN VARCHAR2
           )
    IS
      SELECT  xirm.base_code                                          -- ���_�R�[�h
            , xirm.practice_month                                     -- �N��
            , xirm.subinventory_code                                  -- �ۊǏꏊ
            , xirm.subinventory_type                                  -- �ۊǏꏊ�敪
            , msib.segment1                                           -- �i�ڃR�[�h
            , xirm.operation_cost                                     -- �c�ƌ���
            , xirm.standard_cost                                      -- �W������
            , xirm.month_begin_quantity                               -- ����I����
            , xirm.inv_result                                         -- �I������
            , xirm.inv_result_bad                                     -- �I������(�s�Ǖi)
            , xirm.inv_wear                                           -- �I������ 
            , xirm.last_update_date                                   -- �ŏI�X�V��
      FROM    xxcoi_inv_reception_monthly     xirm                    -- �����݌Ɏ󕥕\
             ,mtl_system_items_b              msib                    -- Disc�i�ڃ}�X�^
      WHERE   xirm.practice_month         =   iv_year_month           -- �N��
      AND     xirm.inventory_kbn          =   cv_inv_kbn_2            -- �I���敪
      AND     xirm.organization_id        =   gn_organization_id      -- �g�DID
      AND     (xirm.inv_result            <>  0                       -- �I������
         OR    xirm.inv_result_bad        <>  0                       -- �I������(�s�Ǖi)
         OR    xirm.month_begin_quantity  <>  0)                      -- ����I����
      AND     xirm.sales_shipped          =   0                       -- ����o��
      AND     xirm.sales_shipped_b        =   0                       -- ����o�ɐU��
      AND     xirm.return_goods           =   0                       -- �ԕi
      AND     xirm.return_goods_b         =   0                       -- �ԕi�U��
      AND     xirm.warehouse_ship         =   0                       -- �q�ɂ֕Ԍ�
      AND     xirm.truck_ship             =   0                       -- �c�ƎԂ֏o��
      AND     xirm.others_ship            =   0                       -- ���o�ɁQ���̑��o��
      AND     xirm.warehouse_stock        =   0                       -- �q�ɂ�����
      AND     xirm.truck_stock            =   0                       -- �c�ƎԂ�����
      AND     xirm.others_stock           =   0                       -- ���o�ɁQ���̑�����
      AND     xirm.change_stock           =   0                       -- �q�֓���
      AND     xirm.change_ship            =   0                       -- �q�֏o��
      AND     xirm.goods_transfer_old     =   0                       -- ���i�U�ցi�����i�j
      AND     xirm.goods_transfer_new     =   0                       -- ���i�U�ցi�V���i�j
      AND     xirm.sample_quantity        =   0                       -- ���{�o��
      AND     xirm.sample_quantity_b      =   0                       -- ���{�o�ɐU��
      AND     xirm.customer_sample_ship   =   0                       -- �ڋq���{�o��
      AND     xirm.customer_sample_ship_b =   0                       -- �ڋq���{�o�ɐU��
      AND     xirm.customer_support_ss    =   0                       -- �ڋq���^���{�o��
      AND     xirm.customer_support_ss_b  =   0                       -- �ڋq���^���{�o�ɐU��
      AND     xirm.ccm_sample_ship        =   0                       -- �ڋq�L����`��A���Џ��i
      AND     xirm.ccm_sample_ship_b      =   0                       -- �ڋq�L����`��A���Џ��i�U��
      AND     xirm.vd_supplement_stock    =   0                       -- ����VD��[����
      AND     xirm.vd_supplement_ship     =   0                       -- ����VD��[�o��
      AND     xirm.inventory_change_in    =   0                       -- ��݌ɕύX����
      AND     xirm.inventory_change_out   =   0                       -- ��݌ɕύX�o��
      AND     xirm.factory_return         =   0                       -- �H��ԕi
      AND     xirm.factory_return_b       =   0                       -- �H��ԕi�U��
      AND     xirm.factory_change         =   0                       -- �H��q��
      AND     xirm.factory_change_b       =   0                       -- �H��q�֐U��
      AND     xirm.removed_goods          =   0                       -- �p�p
      AND     xirm.removed_goods_b        =   0                       -- �p�p�U��
      AND     xirm.factory_stock          =   0                       -- �H�����
      AND     xirm.factory_stock_b        =   0                       -- �H����ɐU��
      AND     xirm.wear_decrease          =   0                       -- �I�����Ց�
      AND     xirm.wear_increase          =   0                       -- �I�����Ռ�
      AND     xirm.selfbase_ship          =   0                       -- �ۊǏꏊ�ړ��Q�����_�o��
      AND     xirm.selfbase_stock         =   0                       -- �ۊǏꏊ�ړ��Q�����_����
      AND     xirm.inventory_item_id      =   msib.inventory_item_id  -- �i��ID
      AND     msib.organization_id        =   gn_organization_id      -- �g�DID
      AND NOT EXISTS (SELECT 1
                      FROM  xxcoi_inv_reception_sum xirs                      -- �����݌Ɏ󕥕\(�݌v)
                      WHERE xirs.practice_date      = iv_year_month           -- �N��
                      AND   xirs.base_code          = xirm.base_code          -- ���_�R�[�h
                      AND   xirs.subinventory_code  = xirm.subinventory_code  -- �ۊǏꏊ
                      AND   xirs.inventory_item_id  = xirm.inventory_item_id  -- �i��ID
                     )
      ;
      get_no_sumdata_rec   get_no_sumdata_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ��̏�����
    lv_recept_month     := NULL;
    lv_process_date     := NULL;
    lv_last_update_date := NULL;
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --�݌v�e�[�u�������݃f�[�^�擾�J�[�\���I�[�v��
    OPEN get_no_sumdata_cur( 
           iv_year_month => iv_year_month
         );
      --
      <<no_sumdata_loop>>
      LOOP
        FETCH get_no_sumdata_cur INTO get_no_sumdata_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN get_no_sumdata_cur%NOTFOUND;
        --�Ώی������Z
        gn_target_cnt := gn_target_cnt + 1;
--
        lv_process_date     := TO_CHAR(gd_sysdate , 'YYYYMMDDHH24MISS' );                          -- �A�g����
        lv_last_update_date := TO_CHAR(get_no_sumdata_rec.last_update_date , 'YYYYMMDDHH24MISS');  -- �ŏI�X�V��
--
        -- =================================
        -- CSV�t�@�C���쐬
        -- =================================
        --
        -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[���܂�
        lv_recept_month := 
          cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || -- 1.��ЃR�[�h
                              get_no_sumdata_rec.practice_month                         || cv_csv_com || -- 2.�N��
          cv_file_encloser || get_no_sumdata_rec.base_code          || cv_file_encloser || cv_csv_com || -- 3.���_�i����j�R�[�h
          cv_file_encloser || get_no_sumdata_rec.subinventory_code  || cv_file_encloser || cv_csv_com || -- 4.�ۊǏꏊ�R�[�h
          cv_file_encloser || get_no_sumdata_rec.segment1           || cv_file_encloser || cv_csv_com || -- 5.���i�R�[�h
          cv_file_encloser || get_no_sumdata_rec.subinventory_type  || cv_file_encloser || cv_csv_com || -- 6.�ۊǏꏊ�敪
                              get_no_sumdata_rec.operation_cost                         || cv_csv_com || -- 7.�c�ƌ���
                              get_no_sumdata_rec.standard_cost                          || cv_csv_com || -- 8.�W������
                              get_no_sumdata_rec.month_begin_quantity                   || cv_csv_com || -- 9.����I����
                              0                                                         || cv_csv_com || -- 10.�H�����
                              0                                                         || cv_csv_com || -- 11.�q�֓���
                              0                                                         || cv_csv_com || -- 12.���_������
                              0                                                         || cv_csv_com || -- 13.�U�֓���
                              0                                                         || cv_csv_com || -- 14.����o��
                              0                                                         || cv_csv_com || -- 15.�ڋq�ԕi
                              0                                                         || cv_csv_com || -- 16.�q�֏o��
                              0                                                         || cv_csv_com || -- 17.���_���o��
                              0                                                         || cv_csv_com || -- 18.��݌ɕύX
                              0                                                         || cv_csv_com || -- 19.�H��ԕi
                              0                                                         || cv_csv_com || -- 20.�H��q��
                              0                                                         || cv_csv_com || -- 21.�p�p�o��
                              0                                                         || cv_csv_com || -- 22.�U�֏o��
                              0                                                         || cv_csv_com || -- 23.���^���{
                              get_no_sumdata_rec.inv_result                             || cv_csv_com || -- 24.�I������
                              get_no_sumdata_rec.inv_result_bad                         || cv_csv_com || -- 25.�I������(�s�Ǖi)
                              get_no_sumdata_rec.inv_wear                               || cv_csv_com || -- 26.�I������
                              lv_last_update_date                                       || cv_csv_com || -- 27.�X�V����
                              lv_process_date;                                                           -- 28.�A�g����
    --
        UTL_FILE.PUT_LINE(
            gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
          , lv_recept_month     -- �f���~�^�{��LCSV�o�͍���
          );
  --
        -- ���팏���ɉ��Z
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      --���[�v�̏I��
      END LOOP no_sumdata_loop;
      --
    --�J�[�\���̃N���[�Y
    CLOSE get_no_sumdata_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      -- �G���[���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF get_no_sumdata_cur%ISOPEN THEN
        CLOSE get_no_sumdata_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_i;
-- == 2010/01/06 V1.2 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : create_csv_p
   * Description      : ��(�݌�)CSV�̍쐬(A-6)
   ***********************************************************************************/
  PROCEDURE create_csv_p(
     ir_recept_month_cur   IN  recept_month_cur%ROWTYPE -- �R����NO.
   , ov_errbuf             OUT VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_csv_p'; -- �v���O������
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
    cv_csv_com       CONSTANT VARCHAR2(1)   := ',';
--
    -- *** ���[�J���ϐ� ***
    lv_recept_month     VARCHAR2(3000);  -- CSV�o�͗p�ϐ�
    lv_process_date     VARCHAR2(14);    -- �V�X�e�����t �i�[�p�ϐ�
    lv_last_update_date VARCHAR2(14);    -- �ŏI�X�V�� �i�[�p�ϐ�
    -- �J�[�\���擾�l�̕ҏW�p�ϐ�
    ln_factory_stock    NUMBER;          -- �H�����
    ln_sum_stock        NUMBER;          -- ���_������
    ln_sales_shipped    NUMBER;          -- ����o��
    ln_return_goods     NUMBER;          -- �ڋq�ԕi
    ln_sum_ship         NUMBER;          -- ���_���o��
    ln_sum_inv_change   NUMBER;          -- ��݌ɕύX
    ln_factory_return   NUMBER;          -- �H��ԕi
    ln_factory_change   NUMBER;          -- �H��q��
    ln_removed_goods    NUMBER;          -- �p�p�o��
    ln_sum_sample       NUMBER;          -- ���^���{
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
    -- �ϐ��̏�����
    lv_recept_month     := NULL;
    lv_process_date     := NULL;
    lv_last_update_date := NULL;
    -- �J�[�\���擾�l�̕ҏW�p�ϐ��̏�����
    ln_factory_stock    := 0;
    ln_sum_stock        := 0;
    ln_sales_shipped    := 0;
    ln_return_goods     := 0;
    ln_sum_ship         := 0;
    ln_sum_inv_change   := 0;
    ln_factory_return   := 0;
    ln_factory_change   := 0;
    ln_removed_goods    := 0;
    ln_sum_sample       := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    lv_process_date     := TO_CHAR( gd_process_date , 'YYYYMMDDHH24MISS' );                    -- �A�g����
    lv_process_date     := TO_CHAR( gd_sysdate , 'YYYYMMDDHH24MISS' );                         -- �A�g����
-- == 2009/04/08 V1.1 Moded START ===============================================================
    lv_last_update_date := TO_CHAR(ir_recept_month_cur.last_update_date , 'YYYYMMDDHH24MISS'); -- �ŏI�X�V��
--
    -- ============================================
    -- �J�[�\���Ŏ擾�������ڂ�ҏW
    -- ============================================
    -- �H�����  = �J�[�\���Œ��o�����H����� - �H����ɐU��
    ln_factory_stock := NVL( ir_recept_month_cur.factory_stock , 0 ) - NVL( ir_recept_month_cur.factory_stock_b , 0 );
    --
    -- ���_������  = �J�[�\���Œ��o�����q�ɂ���̓��� + �c�ƎԂ���̓��� + ���o�ɁQ���̑�����
    ln_sum_stock := NVL( ir_recept_month_cur.warehouse_stock , 0 )
                       + NVL( ir_recept_month_cur.truck_stock , 0 ) + NVL( ir_recept_month_cur.others_stock , 0 );
    --
    -- ����o��  = �J�[�\���Œ��o��������o�� - ����o�ɐU��
    ln_sales_shipped := NVL( ir_recept_month_cur.sales_shipped , 0 ) - NVL( ir_recept_month_cur.sales_shipped_b , 0 );
    --
    -- �ڋq�ԕi  = �J�[�\���Œ��o�����ԕi�[�ԕi�U��
    ln_return_goods := NVL( ir_recept_month_cur.return_goods , 0 ) - NVL( ir_recept_month_cur.return_goods_b , 0 );
    --
    -- ���_���o��  = �J�[�\���Œ��o�����q�ɂ֏o�� + �c�ƎԂ֏o�� + ���o�ɁQ���̑��o��
    ln_sum_ship := NVL( ir_recept_month_cur.warehouse_ship , 0 )
                     + NVL( ir_recept_month_cur.truck_ship , 0 ) + NVL( ir_recept_month_cur.others_ship , 0 );
    --
-- == 2010/01/06 V1.2 Modified START ===============================================================
--    -- ��݌ɕύX  = �J�[�\���Œ��o������݌ɕύX���� + ��݌ɕύX�o��
--    ln_sum_inv_change := NVL( ir_recept_month_cur.inventory_change_in , 0 )
--                           + NVL( ir_recept_month_cur.inventory_change_out , 0 );
    -- ��݌ɕύX  = �J�[�\���Œ��o������݌ɕύX���� - ��݌ɕύX�o��
    ln_sum_inv_change := NVL( ir_recept_month_cur.inventory_change_in , 0 )
                           - NVL( ir_recept_month_cur.inventory_change_out , 0 );
-- == 2010/01/06 V1.2 Modified END   ===============================================================
    --
    -- �H��ԕi   = �Œ��o�����H��ԕi - �H��ԕi�U��
    ln_factory_return := NVL( ir_recept_month_cur.factory_return , 0 )
                           - NVL( ir_recept_month_cur.factory_return_b , 0 );
    --
    -- �H��q��  = �J�[�\���Œ��o�����H��q�� - �H��q�֐U��
    ln_factory_change := NVL( ir_recept_month_cur.factory_change , 0 )
                           - NVL( ir_recept_month_cur.factory_change_b , 0 );
    --
    -- �p�p�o��  = �J�[�\���Œ��o�����p�p - �p�p�U��
    ln_removed_goods  := NVL( ir_recept_month_cur.removed_goods , 0 ) - NVL( ir_recept_month_cur.removed_goods_b , 0 );
    --
    -- ���^���{  = �J�[�\���Œ��o����(���{�o�� - ���{�o�ɐU��)
    --                             + (�ڋq���{�o�� - �ڋq���{��ɐU��)
    --                             + (�ڋq���^���{�o�� - �ڋq���^���{�o�ɐU��)
    --                             + (�ڋq�L����`��A���Џ��i - �ڋq�L����`��A���Џ��i�U��)
    ln_sum_sample := (NVL( ir_recept_month_cur.sample_quantity , 0 ) - NVL( ir_recept_month_cur.sample_quantity_b , 0 ))
                       + (NVL( ir_recept_month_cur.customer_sample_ship , 0 )
                         - NVL( ir_recept_month_cur.customer_sample_ship_b , 0 ))
                       + (NVL( ir_recept_month_cur.customer_support_ss , 0 )
                         - NVL( ir_recept_month_cur.customer_support_ss_b , 0 ))
                       + (NVL( ir_recept_month_cur.ccm_sample_ship , 0 )
                         - NVL( ir_recept_month_cur.ccm_sample_ship_b , 0 ));
--
    -- =================================
    -- CSV�t�@�C���쐬
    -- =================================
    --
    -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[���܂�
-- == 2010/02/03 V1.3 Modified START ===============================================================
--    lv_recept_month := 
--      cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || -- 1.��ЃR�[�h
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.practice_month                        || cv_csv_com || -- 2.�N��
--                          ir_recept_month_cur.practice_date                         || cv_csv_com || -- 2.�N��
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--      cv_file_encloser || ir_recept_month_cur.base_code         || cv_file_encloser || cv_csv_com || -- 3.���_�i����j�R�[�h
--      cv_file_encloser || ir_recept_month_cur.subinventory_code || cv_file_encloser || cv_csv_com || -- 4.�ۊǏꏊ�R�[�h
--      cv_file_encloser || ir_recept_month_cur.segment1          || cv_file_encloser || cv_csv_com || -- 5.���i�R�[�h
--      cv_file_encloser || ir_recept_month_cur.subinventory_type || cv_file_encloser || cv_csv_com || -- 6.�ۊǏꏊ�敪
--                          ir_recept_month_cur.operation_cost                        || cv_csv_com || -- 7.�c�ƌ���
--                          ir_recept_month_cur.standard_cost                         || cv_csv_com || -- 8.�W������
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.month_begin_quantity                  || cv_csv_com || -- 9.����I����
--                          gn_month_begin_quantity                                   || cv_csv_com || -- 9.����I����
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--                          ln_factory_stock                                          || cv_csv_com || -- 10.�H�����
--                          ir_recept_month_cur.change_stock                          || cv_csv_com || -- 11.�q�֓���
--                          ln_sum_stock                                              || cv_csv_com || -- 12.���_������
--                          ir_recept_month_cur.goods_transfer_new                    || cv_csv_com || -- 13.�U�֓���
--                          ln_sales_shipped                                          || cv_csv_com || -- 14.����o��
--                          ln_return_goods                                           || cv_csv_com || -- 15.�ڋq�ԕi
--                          ir_recept_month_cur.change_ship                           || cv_csv_com || -- 16.�q�֏o��
--                          ln_sum_ship                                               || cv_csv_com || -- 17.���_���o��
--                          ln_sum_inv_change                                         || cv_csv_com || -- 18.��݌ɕύX
--                          ln_factory_return                                         || cv_csv_com || -- 19.�H��ԕi
--                          ln_factory_change                                         || cv_csv_com || -- 20.�H��q��
--                          ln_removed_goods                                          || cv_csv_com || -- 21.�p�p�o��
--                          ir_recept_month_cur.goods_transfer_old                    || cv_csv_com || -- 22.�U�֏o��
--                          ln_sum_sample                                             || cv_csv_com || -- 23.���^���{
---- == 2009/04/08 V1.1 Moded START ===============================================================
----                          ir_recept_month_cur.inv_result                            || cv_csv_com || -- 24.�I������
----                          ir_recept_month_cur.inv_result_bad                        || cv_csv_com || -- 25.�I������(�s�Ǖi)
----                          ir_recept_month_cur.inv_wear                              || cv_csv_com || -- 26.�I������
--                          gn_inv_result                                             || cv_csv_com || -- 24.�I������
--                          gn_inv_result_bad                                         || cv_csv_com || -- 25.�I������(�s�Ǖi)
--                          gn_inv_wear                                               || cv_csv_com || -- 26.�I������
---- == 2009/04/08 V1.1 Moded END   ===============================================================
--                          lv_last_update_date                                       || cv_csv_com || -- 27.�X�V����
--                          lv_process_date;                                                           -- 28.�A�g����
----
--    UTL_FILE.PUT_LINE(
--        gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
--      , lv_recept_month        -- �f���~�^�{��LCSV�o�͍���
--      );
--
    -- 9.����26.�̐��ʍ��ڂ��S�ĂO�̃��R�[�h��CSV�o�͂��Ȃ�
    IF  NOT(
              (gn_month_begin_quantity                =  0)     --  9.����I����
          AND (ln_factory_stock                       =  0)     -- 10.�H�����
          AND (ir_recept_month_cur.change_stock       =  0)     -- 11.�q�֓���
          AND (ln_sum_stock                           =  0)     -- 12.���_������
          AND (ir_recept_month_cur.goods_transfer_new =  0)     -- 13.�U�֓���
          AND (ln_sales_shipped                       =  0)     -- 14.����o��
          AND (ln_return_goods                        =  0)     -- 15.�ڋq�ԕi
          AND (ir_recept_month_cur.change_ship        =  0)     -- 16.�q�֏o��
          AND (ln_sum_ship                            =  0)     -- 17.���_���o��
          AND (ln_sum_inv_change                      =  0)     -- 18.��݌ɕύX
          AND (ln_factory_return                      =  0)     -- 19.�H��ԕi
          AND (ln_factory_change                      =  0)     -- 20.�H��q��
          AND (ln_removed_goods                       =  0)     -- 21.�p�p�o��
          AND (ir_recept_month_cur.goods_transfer_old =  0)     -- 22.�U�֏o��
          AND (ln_sum_sample                          =  0)     -- 23.���^���{
          AND (gn_inv_result                          =  0)     -- 24.�I������
          AND (gn_inv_result_bad                      =  0)     -- 25.�I������(�s�Ǖi)
          AND (gn_inv_wear                            =  0)     -- 26.�I������
        )
    THEN
      lv_recept_month := 
        cv_file_encloser || gv_company_code                       || cv_file_encloser || cv_csv_com || --  1.��ЃR�[�h
                            ir_recept_month_cur.practice_date                         || cv_csv_com || --  2.�N��
        cv_file_encloser || ir_recept_month_cur.base_code         || cv_file_encloser || cv_csv_com || --  3.���_�i����j�R�[�h
        cv_file_encloser || ir_recept_month_cur.subinventory_code || cv_file_encloser || cv_csv_com || --  4.�ۊǏꏊ�R�[�h
        cv_file_encloser || ir_recept_month_cur.segment1          || cv_file_encloser || cv_csv_com || --  5.���i�R�[�h
        cv_file_encloser || ir_recept_month_cur.subinventory_type || cv_file_encloser || cv_csv_com || --  6.�ۊǏꏊ�敪
                            ir_recept_month_cur.operation_cost                        || cv_csv_com || --  7.�c�ƌ���
                            ir_recept_month_cur.standard_cost                         || cv_csv_com || --  8.�W������
                            gn_month_begin_quantity                                   || cv_csv_com || --  9.����I����
                            ln_factory_stock                                          || cv_csv_com || -- 10.�H�����
                            ir_recept_month_cur.change_stock                          || cv_csv_com || -- 11.�q�֓���
                            ln_sum_stock                                              || cv_csv_com || -- 12.���_������
                            ir_recept_month_cur.goods_transfer_new                    || cv_csv_com || -- 13.�U�֓���
                            ln_sales_shipped                                          || cv_csv_com || -- 14.����o��
                            ln_return_goods                                           || cv_csv_com || -- 15.�ڋq�ԕi
                            ir_recept_month_cur.change_ship                           || cv_csv_com || -- 16.�q�֏o��
                            ln_sum_ship                                               || cv_csv_com || -- 17.���_���o��
                            ln_sum_inv_change                                         || cv_csv_com || -- 18.��݌ɕύX
                            ln_factory_return                                         || cv_csv_com || -- 19.�H��ԕi
                            ln_factory_change                                         || cv_csv_com || -- 20.�H��q��
                            ln_removed_goods                                          || cv_csv_com || -- 21.�p�p�o��
                            ir_recept_month_cur.goods_transfer_old                    || cv_csv_com || -- 22.�U�֏o��
                            ln_sum_sample                                             || cv_csv_com || -- 23.���^���{
                            gn_inv_result                                             || cv_csv_com || -- 24.�I������
                            gn_inv_result_bad                                         || cv_csv_com || -- 25.�I������(�s�Ǖi)
                            gn_inv_wear                                               || cv_csv_com || -- 26.�I������
                            lv_last_update_date                                       || cv_csv_com || -- 27.�X�V����
                            lv_process_date;                                                           -- 28.�A�g����
      --
      UTL_FILE.PUT_LINE(
          gv_activ_file_h     -- A-3.�Ŏ擾�����t�@�C���n���h��
        , lv_recept_month        -- �f���~�^�{��LCSV�o�͍���
        );
      --
      -- ���팏���ɉ��Z
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
-- == 2010/02/03 V1.3 Modified END   ===============================================================
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
  END create_csv_p;
--
-- == 2009/04/08 V1.1 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : get_inv_info_p
   * Description      : �I�����擾(A-5)
   ***********************************************************************************/
  PROCEDURE get_inv_info_p(
     ir_recept_month_rec   IN  recept_month_cur%ROWTYPE -- �R����NO.
   , ov_errbuf             OUT VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_info_p'; -- �v���O������
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
    -- A-5�D�I�����擾
    -- �p�����[�^�u�����敪�v���u0�F�����v�̏ꍇ
    IF ( gv_process_type = cv_process_type_0 ) THEN
--
      -- �݌ɉ�v���Ԃ̌�����1���̏ꍇ�i�O�����ߏ����O�j
      IF ( gn_open_period_cnt > 1 ) THEN
--
        -- �����݌Ɏ󕥕\(�݌v)�̔N�����Ɩ����t�̔N���̏ꍇ
        IF ( ir_recept_month_rec.practice_date < TO_CHAR( gd_process_date, cv_fmt_date ) ) THEN
--
          BEGIN
            -- ����I�������擾
            SELECT xirm.inv_result                                                      -- �I������
            INTO   gn_month_begin_quantity
            FROM   xxcoi_inv_reception_monthly   xirm                                   -- �����݌Ɏ󕥕\�e�[�u��
            WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4�Ŏ擾�����g�DID
            AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4�Ŏ擾�������_�R�[�h
            AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4�Ŏ擾�����ۊǏꏊ
            AND    xirm.practice_month         = TO_CHAR(
                                                     ADD_MONTHS(
                                                         TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                       , -1 )
                                                   , cv_fmt_date )                      -- A-4�Ŏ擾�����N���̑O��
            AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4�Ŏ擾�����i��ID
            AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- �I���敪�F'2'�i�����j
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              gn_month_begin_quantity := 0;
          END;
--
        -- �����݌Ɏ󕥕\(�݌v)�̔N�����Ɩ����t�̔N���̏ꍇ
        ELSE
          gn_month_begin_quantity := 0;
--
        END IF;
--
      -- �݌ɉ�v���Ԃ̌�����1���̏ꍇ�i�O�����ߏ�����j
      ELSE
--
        BEGIN
          -- ����I�������擾
          SELECT xirm.inv_result                                                      -- �I������
          INTO   gn_month_begin_quantity
          FROM   xxcoi_inv_reception_monthly   xirm                                   -- �����݌Ɏ󕥕\�e�[�u��
          WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4�Ŏ擾�����g�DID
          AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4�Ŏ擾�������_�R�[�h
          AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4�Ŏ擾�����ۊǏꏊ
          AND    xirm.practice_month         = TO_CHAR(
                                                   ADD_MONTHS(
                                                       TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                     , -1 )
                                                 , cv_fmt_date )                      -- A-4�Ŏ擾�����N���̑O��
          AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4�Ŏ擾�����i��ID
          AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- �I���敪�F'2'�i�����j
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gn_month_begin_quantity := 0;
        END;
--
      END IF;
--
      -- �I�����ʂ��擾
      gn_inv_result     := ir_recept_month_rec.book_inventory_quantity;
      -- �I������(�s�Ǖi)���擾
      gn_inv_result_bad := 0;
      -- �I�����Ղ��擾
      gn_inv_wear       := 0;
--
    -- �p�����[�^�u�����敪�v���u1�F�����v�̏ꍇ
    ELSE
--
      -- �����݌Ɏ󕥕\(�݌v)�̔N�����Ɩ����t�̔N���̏ꍇ
      IF ( ir_recept_month_rec.practice_date < TO_CHAR( gd_process_date, cv_fmt_date ) ) THEN
--
        BEGIN
          -- �O�����I�������擾
          SELECT   xirm.month_begin_quantity                                            -- ����I����
                 , xirm.inv_result                                                      -- �I������
                 , xirm.inv_result_bad                                                  -- �I������(�s�Ǖi)
                 , xirm.inv_wear                                                        -- �I������
          INTO     gn_month_begin_quantity
                 , gn_inv_result
                 , gn_inv_result_bad
                 , gn_inv_wear
          FROM     xxcoi_inv_reception_monthly   xirm                                   -- �����݌Ɏ󕥕\�e�[�u��
          WHERE    xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4�Ŏ擾�����g�DID
          AND      xirm.base_code              = ir_recept_month_rec.base_code          -- A-4�Ŏ擾�������_�R�[�h
          AND      xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4�Ŏ擾�����ۊǏꏊ
          AND      xirm.practice_month         = ir_recept_month_rec.practice_date      -- A-4�Ŏ擾�����N���̑O��
          AND      xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4�Ŏ擾�����i��ID
          AND      xirm.inventory_kbn          = cv_inv_kbn_2                           -- �I���敪�F'2'�i�����j
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- �O�����I�����擾�G���[���b�Z�[�W
          -- �u�O�����I����񂪎擾�ł��܂���ł����B�����݌Ɏ󕥏����m�F���ĉ������B�v
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                           , iv_name         => cv_msg_xxcoi_10377
                           , iv_token_name1  => cv_tkn_month
                           , iv_token_value1 => ir_recept_month_rec.practice_date
                           , iv_token_name2  => cv_tkn_base_code
                           , iv_token_value2 => ir_recept_month_rec.base_code
                           , iv_token_name3  => cv_tkn_subinventory
                           , iv_token_value3 => ir_recept_month_rec.subinventory_code
                           , iv_token_name4  => cv_tkn_item_code
                           , iv_token_value4 => ir_recept_month_rec.inventory_item_id
                         );
            lv_errbuf := lv_errmsg;
            --
            RAISE global_api_expt;
        END;
--
      -- �����݌Ɏ󕥕\(�݌v)�̔N�����Ɩ����t�̔N���̏ꍇ
      ELSE
        -- ����I�������擾
        BEGIN
          SELECT xirm.inv_result                                                      -- �I������
          INTO   gn_month_begin_quantity
          FROM   xxcoi_inv_reception_monthly   xirm                                   -- �����݌Ɏ󕥕\�e�[�u��
          WHERE  xirm.organization_id        = ir_recept_month_rec.organization_id    -- A-4�Ŏ擾�����g�DID
          AND    xirm.base_code              = ir_recept_month_rec.base_code          -- A-4�Ŏ擾�������_�R�[�h
          AND    xirm.subinventory_code      = ir_recept_month_rec.subinventory_code  -- A-4�Ŏ擾�����ۊǏꏊ
          AND    xirm.practice_month         = TO_CHAR(
                                                   ADD_MONTHS(
                                                       TO_DATE( ir_recept_month_rec.practice_date, cv_fmt_date )
                                                     , -1 )
                                                 , cv_fmt_date )                      -- A-4�Ŏ擾�����N���̑O��
          AND    xirm.inventory_item_id      = ir_recept_month_rec.inventory_item_id  -- A-4�Ŏ擾�����i��ID
          AND    xirm.inventory_kbn          = cv_inv_kbn_2                           -- �I���敪�F'2'�i�����j
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gn_month_begin_quantity := 0;
        END;
--
        -- �I�����ʂ��擾
        gn_inv_result     := ir_recept_month_rec.book_inventory_quantity;
        -- �I������(�s�Ǖi)���擾
        gn_inv_result_bad := 0;
        -- �I�����Ղ��擾
        gn_inv_wear       := 0;
--
      END IF;
--
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
  END get_inv_info_p;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : recept_month_cur_p
   * Description      : �����݌Ɏ󕥕\(�݌v)���̒��o(A-4)
   ***********************************************************************************/
  PROCEDURE recept_month_cur_p(
-- == 2009/04/08 V1.1 Moded END   ===============================================================
--     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
--   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
--   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
     iv_year_month IN  VARCHAR2     --   �N��
   , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'recept_month_cur_p'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    --���ʎ󕥎c���f�[�^�擾�J�[�\���I�[�v��
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    OPEN recept_month_cur;
    OPEN recept_month_cur( 
           iv_practice_date => iv_year_month
         );
-- == 2009/04/08 V1.1 Moded END   ===============================================================
      --
      <<recept_month_loop>>
      LOOP
        FETCH recept_month_cur INTO recept_month_rec;
        --���f�[�^���Ȃ��Ȃ�����I��
        EXIT WHEN recept_month_cur%NOTFOUND;
-- == 2010/02/03 V1.3 Deleted START ===============================================================
--        --�Ώی������Z
--        gn_target_cnt := gn_target_cnt + 1;
-- == 2010/02/03 V1.3 Deleted END   ===============================================================
--
-- == 2009/04/08 V1.1 Added START ===============================================================
        -- ===============================
        -- A-5�D�I�����擾
        -- ===============================
        get_inv_info_p(
            ir_recept_month_rec   => recept_month_rec        -- �R����NO.
          , ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          -- �G���[����
          RAISE global_process_expt;
        END IF;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
        -- ===============================
        -- A-6�D���ʎ󕥎c��CSV�̍쐬
        -- ===============================
        create_csv_p(
            ir_recept_month_cur   => recept_month_rec        -- �R����NO.
          , ov_errbuf             => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode            => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg             => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          -- �G���[����
          RAISE global_process_expt;
        END IF;
--
-- == 2010/02/03 V1.3 Deleted START ===============================================================
--        -- ���팏���ɉ��Z
--        gn_normal_cnt := gn_normal_cnt + 1;
-- == 2010/02/03 V1.3 Deleted END   ===============================================================
      --
      --���[�v�̏I��
      END LOOP recept_month_loop;
      --
    --�J�[�\���̃N���[�Y
    CLOSE recept_month_cur;
-- == 2010/02/03 V1.3 Added START ===============================================================
    -- �Ώی����ݒ�
    gn_target_cnt :=  gn_normal_cnt;
-- == 2010/02/03 V1.3 Added END   ===============================================================
    --
-- == 2009/04/08 V1.1 Deleted START ===============================================================
--    -- �f�[�^���O���ŏI�������ꍇ
--    IF ( gn_target_cnt = 0 ) THEN
--      -- �Ώۃf�[�^�������b�Z�[�W
--      -- �u�Ώۃf�[�^�͂���܂���B�v
--      gv_out_msg   := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_appl_short_name
--                      , iv_name         => cv_msg_xxcoi_00008
--                      );
--      -- ���b�Z�[�W�o��
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--        , buff   => gv_out_msg
--      );
--      FND_FILE.PUT_LINE(
--          which  => FND_FILE.LOG
--        , buff   => gv_out_msg
--      );
--    END IF;
-- == 2009/04/08 V1.1 Deleted END   ===============================================================
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      -- �G���[���b�Z�[�W
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF recept_month_cur%ISOPEN THEN
        CLOSE recept_month_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END recept_month_cur_p;
--
-- == 2009/04/08 V1.1 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : get_open_period_p
   * Description      : �I�[�v���݌ɉ�v���Ԏ擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_open_period_p(
     ov_errbuf             OUT VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode            OUT VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg             OUT VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_open_period_p'; -- �v���O������
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
    -- �J�[�\���I�[�v��
    OPEN  get_open_period_cur;
--
    -- �J�[�\���f�[�^�擾
    FETCH get_open_period_cur BULK COLLECT INTO get_open_period_tab;
--
    -- �J�[�\���̃N���[�Y
    CLOSE get_open_period_cur;
--
    -- ===============================
    -- �Ώی����J�E���g
    -- ===============================
    gn_open_period_cnt := get_open_period_tab.COUNT;
--
    -- ===============================
    -- �݌ɉ�v���Ԏ擾�`�F�b�N
    -- ===============================
    IF ( gn_open_period_cnt = 0 ) THEN
      -- �݌ɉ�v���Ԏ擾�G���[���b�Z�[�W
      -- �u�����ȑO�̃I�[�v�����Ă���݌ɉ�v���Ԃ��擾�ł��܂���ł����B�݌ɉ�v���Ԃ��m�F���ĉ������B�v
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                     , iv_name         => cv_msg_xxcoi_10376
                   );
      lv_errbuf := lv_errmsg;
      --
      RAISE global_api_expt;
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
  END get_open_period_p;
--
-- == 2009/04/08 V1.1 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- == 2009/04/08 V1.1 Moded START ===============================================================
--     ov_errbuf     OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
--   , ov_retcode    OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
--   , ov_errmsg     OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     iv_process_type IN  VARCHAR2    --   �����敪
   , ov_errbuf       OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode      OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg       OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)  := 'submain'; -- �v���O������
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767;
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);                   -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);                -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- �t�@�C���̑��݃`�F�b�N�p�ϐ�
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
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
    -- *** ���[�J����O ***
    remain_file_expt           EXCEPTION;
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
    -- ����������
    -- ===============================
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gv_activ_file_h  := NULL;            -- �t�@�C���n���h��
-- == 2009/04/08 V1.1 Added START ===============================================================
    gv_process_type  := iv_process_type; -- �N���p�����[�^�F�����敪
-- == 2009/04/08 V1.1 Added END   ===============================================================
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ========================================
    --  A-1. ��������
    -- ========================================
    init(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2�D�t�@�C���I�[�v������
    -- ========================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_pass
      , filename     =>  gv_file_recept_month
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
--
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
--
    ELSE
      -- �t�@�C���I�[�v���������s
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_pass          -- �f�B���N�g���p�X
                          , filename     => gv_file_recept_month  -- �t�@�C����
                          , open_mode    => cv_file_mode          -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize       -- �t�@�C���T�C�Y
                         );
    END IF;
    --
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    -- ========================================
--    -- A-3�D���ʎ󕥎c�����̒��o
--    -- ========================================
--    -- A-3�̏���������A-4������
--    recept_month_cur_p(
--        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    --
--    -- �I���p�����[�^����
--    IF (lv_retcode = cv_status_error) THEN
--      -- �G���[����
--      RAISE global_process_expt;
--    END IF;
--
    -- ========================================
    -- A-3�D�I�[�v���݌ɉ�v���Ԏ擾
    -- ========================================
    get_open_period_p(
        ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- �݌ɉ�v���ԒP�ʏ������[�v
    <<open_period_loop>>
    FOR i IN 1 .. get_open_period_tab.COUNT LOOP
      -- ========================================
      -- A-4�D���ʎ󕥎c�����̒��o
      -- ========================================
      -- A-4�̏���������A-5, A-6������
      recept_month_cur_p(
          iv_year_month => get_open_period_tab(i).year_month  -- �N��
        , ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[����
        RAISE global_process_expt;
      END IF;
--
-- == 2010/01/06 V1.2 Added START ===============================================================
      IF (    (gv_process_type = cv_process_type_1)
          AND (LAST_DAY(TO_DATE(get_open_period_tab(i).year_month, cv_fmt_date)) < gd_process_date)
         )
      THEN
        -- �����敪�F�P�i�����j���A�����i�O���j�̏ꍇ
        -- ========================================
        -- A-9�D�݌v���Ȃ��I���f�[�^CSV�쐬
        -- ========================================
        create_csv_i(
            iv_year_month => get_open_period_tab(i).year_month  -- �N��
          , ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          -- �G���[����
          RAISE global_process_expt;
        END IF;
      END IF;
-- == 2010/01/06 V1.2 Added END   ===============================================================
      --
    END LOOP open_period_loop;
--
    -- �f�[�^���O���ŏI�������ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      -- �u�Ώۃf�[�^�͂���܂���B�v
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                      , iv_name         => cv_msg_xxcoi_00008
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
    END IF;
-- 
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    --
    -- ===============================
    -- A-7�D�t�@�C���̃N���[�Y����
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gv_activ_file_h
      );
--
  EXCEPTION
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �t�@�C�����݃`�F�b�N�G���[ ***
    -- �u�t�@�C���u FILE_NAME �v�͂��łɑ��݂��܂��B�v
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name
                        , iv_name         => cv_msg_xxcoi_00027
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_file_recept_month
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- CSV�t�@�C�����I�[�v�����Ă���΃N���[�Y����
      IF( UTL_FILE.IS_OPEN( gv_activ_file_h ) ) THEN
        UTL_FILE.FCLOSE(
          file => gv_activ_file_h
          );
      END IF;
      --
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
-- == 2009/04/08 V1.1 Moded START ===============================================================
--    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
--    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_process_type IN  VARCHAR2       --   �����敪
-- == 2009/04/08 V1.1 Moded END   ===============================================================
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================
    -- �ϐ��̏�����
    -- ===============================
    lv_errbuf    := NULL;   -- �G���[�E���b�Z�[�W
    lv_retcode   := NULL;   -- ���^�[���E�R�[�h
    lv_errmsg    := NULL;   -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
-- == 2009/04/08 V1.1 Moded START ===============================================================
--        ov_retcode => lv_retcode  -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_errbuf  => lv_errbuf   -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        iv_process_type => iv_process_type -- �����敪
      , ov_retcode      => lv_retcode      -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_errbuf       => lv_errbuf       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- == 2009/04/08 V1.1 Moded END   ===============================================================
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
    --
    --==============================================================
    -- A-8�D�����\������
    --==============================================================
    -- �G���[���͐��������o�͂��O�ɃZ�b�g
    --           �G���[�����o�͂��P�ɃZ�b�g
    IF( lv_retcode = cv_status_error ) THEN
-- == 2009/04/08 V1.1 Added START ===============================================================
      gn_target_cnt := 0;
-- == 2009/04/08 V1.1 Added END   ===============================================================
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      -- ����I�����b�Z�[�W
      -- �u����������I�����܂����B�v
      lv_message_code := cv_normal_msg;
    --
    ELSIF(lv_retcode = cv_status_error) THEN
      -- �G���[�I���S���[���o�b�N���b�Z�[�W
      -- �u�������G���[�I�����܂����B�f�[�^�͑S�������O�̏�Ԃɖ߂��܂����B�v
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_ccp
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      --
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
END XXCOI008A03C;
/
