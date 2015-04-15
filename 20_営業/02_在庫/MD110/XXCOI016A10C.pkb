CREATE OR REPLACE PACKAGE BODY XXCOI016A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A10C(body)
 * Description      : ���b�g�ʎ󕥃f�[�^�쐬(����)
 * MD.050           : MD050_COI_016_A10_���b�g�ʎ󕥃f�[�^�쐬(����).doc
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_end               �I������(A-6)
 *  cre_inout_data         ���b�g�ʎ󕥁i�����j�f�[�^�o�^�E�X�V���� (A-5)
 *  cal_inout_data         �󕥍��ڎZ�o���� (A-4)
 *  get_inout_data         �󕥃f�[�^�擾����(A-3)
 *  cre_carry_data         �J�z�f�[�^�쐬����(A-2)
 *  proc_init              ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/27    1.0   Y.Nagasue        �V�K�쐬
 *  2015/04/07    1.1   S.Yamashita      E_�{�ғ�_12237�i�q�ɊǗ��s��Ή��j
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(20) := 'XXCOI016A10C'; -- �p�b�P�[�W��
  cv_xxcoi_short_name          CONSTANT VARCHAR2(5)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W
  cv_msg_xxcoi1_00005          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
                                                  -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00006          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; 
                                                  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00011          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011'; 
                                                  -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10455          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10455'; 
                                                  -- �N���t���O�s���G���[
  cv_msg_xxcoi1_10454          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10454'; 
                                                  -- ���b�g�ʎ󕥃f�[�^�쐬�i�����j�R���J�����g���̓p�����[�^
  cv_msg_xxcoi1_10456          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10456'; 
                                                  -- �����ώ��ID�擾�G���[
  cv_msg_xxcoi1_10457          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10457'; 
                                                  -- ���b�g�ʎ󕥃f�[�^�쐬�i�����j�Ώ�0�����b�Z�[�W
  cv_msg_xxcoi1_10458          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10458'; 
                                                  -- ���b�g�ʎ󕥁i�����j�Ώێ��ID���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_pro_tok               CONSTANT VARCHAR2(20) := 'PRO_TOK';          -- �g�[�N���F�v���t�@�C����
  cv_tkn_org_code_tok          CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';     -- �g�[�N���F�݌ɑg�D�R�[�h
  cv_tkn_base_code             CONSTANT VARCHAR2(20) := 'BASE_CODE';        -- �g�[�N���F���_�R�[�h
  cv_tkn_base_name             CONSTANT VARCHAR2(20) := 'BASE_NAME';        -- �g�[�N���F���_��
  cv_tkn_startup_flg           CONSTANT VARCHAR2(20) := 'STARTUP_FLG';      -- �g�[�N���F�N���t���O
  cv_tkn_startup_flg_name      CONSTANT VARCHAR2(20) := 'STARTUP_FLG_NAME'; -- �g�[�N���F�N���t���O��
  cv_tkn_subinv_code           CONSTANT VARCHAR2(20) := 'SUBINV_CODE';      -- �g�[�N���F�ۊǏꏊ�R�[�h
  cv_tkn_subinv_name           CONSTANT VARCHAR2(20) := 'SUBINV_NAME';      -- �g�[�N���F�ۊǏꏊ��
  cv_tkn_program_name          CONSTANT VARCHAR2(20) := 'PROGRAM_NAME';     -- �g�[�N���F�v���O������
  cv_tkn_min_trx_id            CONSTANT VARCHAR2(20) := 'MIN_TRX_ID';       -- �g�[�N���F�ŏ����ID
  cv_tkn_max_trx_id            CONSTANT VARCHAR2(20) := 'MAX_TRX_ID';       -- �g�[�N���F�ő���ID
--
  -- �v���t�@�C����
  cv_xxcoi1_organization_code  CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:�݌ɑg�D�R�[�h
--
  -- �Q�ƃ^�C�v��
  ct_xxcoi1_lot_rep_month_type fnd_lookup_values.lookup_type%TYPE := 'XXCOI1_LOT_REP_MONTH_TYPE';
                                                  -- �Q�ƃ^�C�v�F���b�g�ʎ󕥃f�[�^�쐬(����)�N���t���O
--
  -- ����^�C�v�R�[�h
  ct_trx_type_10               CONSTANT fnd_lookup_values.lookup_code%TYPE := '10';  -- ���o��
  ct_trx_type_20               CONSTANT fnd_lookup_values.lookup_code%TYPE := '20';  -- �q��
  ct_trx_type_70               CONSTANT fnd_lookup_values.lookup_code%TYPE := '70';  -- ����VD��[
  ct_trx_type_90               CONSTANT fnd_lookup_values.lookup_code%TYPE := '90';  -- �H��ԕi
  ct_trx_type_100              CONSTANT fnd_lookup_values.lookup_code%TYPE := '100'; -- �H��ԕi�U��
  ct_trx_type_110              CONSTANT fnd_lookup_values.lookup_code%TYPE := '110'; -- �H��q��
  ct_trx_type_120              CONSTANT fnd_lookup_values.lookup_code%TYPE := '120'; -- �H��q�֐U��
  ct_trx_type_130              CONSTANT fnd_lookup_values.lookup_code%TYPE := '130'; -- �p�p
  ct_trx_type_140              CONSTANT fnd_lookup_values.lookup_code%TYPE := '140'; -- �p�p�U��
  ct_trx_type_150              CONSTANT fnd_lookup_values.lookup_code%TYPE := '150'; -- �H�����
  ct_trx_type_160              CONSTANT fnd_lookup_values.lookup_code%TYPE := '160'; -- �H����ɐU��
  ct_trx_type_170              CONSTANT fnd_lookup_values.lookup_code%TYPE := '170'; -- ����o��
  ct_trx_type_180              CONSTANT fnd_lookup_values.lookup_code%TYPE := '180'; -- ����o�ɐU��
  ct_trx_type_190              CONSTANT fnd_lookup_values.lookup_code%TYPE := '190'; -- �ԕi
  ct_trx_type_200              CONSTANT fnd_lookup_values.lookup_code%TYPE := '200'; -- �ԕi�U��
  ct_trx_type_320              CONSTANT fnd_lookup_values.lookup_code%TYPE := '320'; -- �ڋq���{�o��
  ct_trx_type_330              CONSTANT fnd_lookup_values.lookup_code%TYPE := '330'; -- �ڋq���{�o�ɐU��
  ct_trx_type_340              CONSTANT fnd_lookup_values.lookup_code%TYPE := '340'; -- �ڋq���^���{�o��
  ct_trx_type_350              CONSTANT fnd_lookup_values.lookup_code%TYPE := '350'; -- �ڋq���^���{�o�ɐU��
  ct_trx_type_360              CONSTANT fnd_lookup_values.lookup_code%TYPE := '360'; -- �ڋq�L����`��A���Џ��i
  ct_trx_type_370              CONSTANT fnd_lookup_values.lookup_code%TYPE := '370'; -- �ڋq�L����`��A���Џ��i�U��
  ct_trx_type_380              CONSTANT fnd_lookup_values.lookup_code%TYPE := '380'; -- �o�׊m��
  ct_trx_type_390              CONSTANT fnd_lookup_values.lookup_code%TYPE := '390'; -- ���P�[�V�����ړ�
  ct_trx_type_400              CONSTANT fnd_lookup_values.lookup_code%TYPE := '400'; -- �݌Ɉړ���
  ct_trx_type_410              CONSTANT fnd_lookup_values.lookup_code%TYPE := '410'; -- �݌Ɉړ���
--
  -- �X�e�[�^�X��
  -- �ڋq�}�X�^
  ct_cust_status_a             CONSTANT hz_cust_accounts.status%TYPE               := 'A'; -- �X�e�[�^�X�FA
  ct_cust_class_code_1         CONSTANT hz_cust_accounts.customer_class_code%TYPE  := '1'; -- �ڋq�敪�F1
  -- �N���t���O�F���b�g�ʎ�(����).�f�[�^�敪
  ct_data_type_1               CONSTANT xxcoi_lot_reception_monthly.data_type%TYPE := '1'; -- �f�[�^�敪�F1
  ct_data_type_2               CONSTANT xxcoi_lot_reception_monthly.data_type%TYPE := '2'; -- �f�[�^�敪�F2
  -- �ۊǏꏊ�敪
  ct_subinv_kbn_2              CONSTANT mtl_secondary_inventories.attribute1%TYPE  := '2'; -- �ۊǏꏊ�敪�F2
  -- �t���O
  cv_flag_y                    CONSTANT VARCHAR2(1)                                := 'Y'; -- �t���O�FY
  cv_flag_n                    CONSTANT VARCHAR2(1)                                := 'N'; -- �t���O�FN
--
  -- ����
  cv_yyyymm                    CONSTANT VARCHAR2(6) := 'YYYYMM'; -- �N���ϊ��p
--
  -- ���̑�
  cn_minus_1                   CONSTANT NUMBER := -1; -- �Œ�l�}�C�i�X1
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�ێ��ϐ�
  gt_base_code                 xxcoi_lot_reception_monthly.base_code%TYPE;               -- ���_�R�[�h
  gt_subinv_code               xxcoi_lot_reception_monthly.subinventory_code%TYPE;       -- �ۊǏꏊ�R�[�h
  gt_startup_flg               xxcoi_lot_reception_monthly.data_type%TYPE;               -- �N���t���O�i�f�[�^�敪�j
--
  -- ���������擾�l
  gt_org_code                  mtl_parameters.organization_code%TYPE;                    -- �݌ɑg�D�R�[�h
  gt_org_id                    mtl_parameters.organization_id%TYPE;                      -- �݌ɑg�DID
  gd_proc_date                 DATE;                                                     -- �Ɩ����t
  gt_pre_exe_id                xxcoi_cooperation_control.transaction_id%TYPE;            -- �O����ID
  gt_no_data_flag              VARCHAR2(1);                                              -- �Ώ�0���t���O
  gt_max_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;               -- �ő���ID
  gt_min_trx_id                xxcoi_lot_transactions.transaction_id%TYPE;               -- �ŏ����ID
--
  -- �O���R�[�h���b�g���ێ��p�ϐ�
  gt_bef_practice_month        xxcoi_lot_reception_monthly.practice_month%TYPE;          -- ����N��
  gt_bef_base_code             xxcoi_lot_reception_monthly.base_code%TYPE;               -- ���_�R�[�h
  gt_bef_subinventory_code     xxcoi_lot_reception_monthly.subinventory_code%TYPE;       -- �ۊǏꏊ�R�[�h
  gt_bef_subinv_type           xxcoi_lot_reception_monthly.subinventory_type%TYPE;       -- �ۊǏꏊ�敪
  gt_bef_location_code         xxcoi_lot_reception_monthly.location_code%TYPE;           -- ���P�[�V�����R�[�h
  gt_bef_parent_item_id        xxcoi_lot_reception_monthly.parent_item_id%TYPE;          -- �e�i��ID
  gt_bef_child_item_id         xxcoi_lot_reception_monthly.child_item_id%TYPE;           -- �q�i��ID
  gt_bef_lot                   xxcoi_lot_reception_monthly.lot%TYPE;                     -- ���b�g
  gt_bef_diff_sum_code         xxcoi_lot_reception_monthly.difference_summary_code%TYPE; -- �ŗL�L��
--
  -- �󕥍��ڌv�Z���ʕێ��p�ϐ�
  gt_factory_stock             xxcoi_lot_reception_monthly.factory_stock%TYPE;           -- �H�����
  gt_factory_stock_b           xxcoi_lot_reception_monthly.factory_stock_b%TYPE;         -- �H����ɐU��
  gt_change_stock              xxcoi_lot_reception_monthly.change_stock%TYPE;            -- �q�֓���
  gt_others_stock              xxcoi_lot_reception_monthly.others_stock%TYPE;            -- ���o�ɁQ���̑�����
  gt_truck_stock               xxcoi_lot_reception_monthly.truck_stock%TYPE;             -- �c�ƎԂ�����
  gt_truck_ship                xxcoi_lot_reception_monthly.truck_ship%TYPE;              -- �c�ƎԂ֏o��
  gt_sales_shipped             xxcoi_lot_reception_monthly.sales_shipped%TYPE;           -- ����o��
  gt_sales_shipped_b           xxcoi_lot_reception_monthly.sales_shipped_b%TYPE;         -- ����o�ɐU��
  gt_return_goods              xxcoi_lot_reception_monthly.return_goods%TYPE;            -- �ԕi
  gt_return_goods_b            xxcoi_lot_reception_monthly.return_goods_b%TYPE;          -- �ԕi�U��
  gt_customer_sample_ship      xxcoi_lot_reception_monthly.customer_sample_ship%TYPE;    -- �ڋq���{�o��
  gt_customer_sample_ship_b    xxcoi_lot_reception_monthly.customer_sample_ship_b%TYPE;  -- �ڋq���{�o�ɐU��
  gt_customer_support_ss       xxcoi_lot_reception_monthly.customer_support_ss%TYPE;     -- �ڋq���^���{�o��
  gt_customer_support_ss_b     xxcoi_lot_reception_monthly.customer_support_ss_b%TYPE;   -- �ڋq���^���{�o�ɐU��
  gt_ccm_sample_ship           xxcoi_lot_reception_monthly.ccm_sample_ship%TYPE;         -- �ڋq�L����`��A���Џ��i
  gt_ccm_sample_ship_b         xxcoi_lot_reception_monthly.ccm_sample_ship_b%TYPE;       -- �ڋq�L����`��A���Џ��i�U��
  gt_vd_supplement_stock       xxcoi_lot_reception_monthly.vd_supplement_stock%TYPE;     -- ����VD��[����
  gt_vd_supplement_ship        xxcoi_lot_reception_monthly.vd_supplement_ship%TYPE;      -- ����VD��[�o��
  gt_removed_goods             xxcoi_lot_reception_monthly.removed_goods%TYPE;           -- �p�p
  gt_removed_goods_b           xxcoi_lot_reception_monthly.removed_goods_b%TYPE;         -- �p�p�U��
  gt_change_ship               xxcoi_lot_reception_monthly.change_ship%TYPE;             -- �q�֏o��
  gt_others_ship               xxcoi_lot_reception_monthly.others_ship%TYPE;             -- ���o�ɁQ���̑��o��
  gt_factory_change            xxcoi_lot_reception_monthly.factory_change%TYPE;          -- �H��q��
  gt_factory_change_b          xxcoi_lot_reception_monthly.factory_change_b%TYPE;        -- �H��q�֐U��
  gt_factory_return            xxcoi_lot_reception_monthly.factory_return%TYPE;          -- �H��ԕi
  gt_factory_return_b          xxcoi_lot_reception_monthly.factory_return_b%TYPE;        -- �H��ԕi�U��
  gt_location_decrease         xxcoi_lot_reception_monthly.location_decrease%TYPE;       -- ���P�[�V�����ړ���
  gt_location_increase         xxcoi_lot_reception_monthly.location_increase%TYPE;       -- ���P�[�V�����ړ���
  gt_adjust_decrease           xxcoi_lot_reception_monthly.adjust_decrease%TYPE;         -- �݌ɒ�����
  gt_adjust_increase           xxcoi_lot_reception_monthly.adjust_increase%TYPE;         -- �݌ɒ�����
  gt_book_inventory_quantity   xxcoi_lot_reception_monthly.book_inventory_quantity%TYPE; -- ����݌ɐ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �󕥑Ώۃf�[�^�擾�J�[�\���i������s�j
  CURSOR get_rep_data_1_cur IS
    SELECT xlt.transaction_month             trx_month             -- ����N��
          ,xlt.base_code                     base_code             -- ���_�R�[�h
          ,xlt.subinventory_code             subinv_code           -- �ۊǏꏊ�R�[�h
          ,msi1.attribute1                   subinv_type           -- �ۊǏꏊ�敪
          ,xlt.location_code                 location_code         -- ���P�[�V�����R�[�h
          ,xlt.parent_item_id                parent_item_id        -- �e�i��ID
          ,xlt.child_item_id                 child_item_id         -- �q�i��ID
          ,xlt.lot                           lot                   -- ���b�g
          ,xlt.difference_summary_code       diff_sum_code         -- �ŗL�L��
          ,xlt.transfer_subinventory         tran_subinv           -- �]����ۊǏꏊ�R�[�h
          ,msi2.attribute1                   tran_subinv_kbn       -- �]����ۊǏꏊ�敪
          ,xlt.transaction_type_code         trx_type_code         -- ����^�C�v�R�[�h
          ,xlt.reserve_transaction_type_code reserve_trx_type_code -- ����������^�C�v�R�[�h
          ,SUM(xlt.summary_qty)              rep_qty               -- �󕥐���
    FROM   xxcoi_lot_transactions    xlt                           -- ���b�g�ʎ������
          ,mtl_secondary_inventories msi1                          -- �ۊǏꏊ
          ,mtl_secondary_inventories msi2                          -- �]����ۊǏꏊ
          ,org_acct_periods          oap                           -- �݌ɉ�v���ԃe�[�u��
    WHERE  xlt.transaction_id        > gt_pre_exe_id               -- �O����ID���傫��
    AND    xlt.organization_id       = gt_org_id                   -- ���������Ŏ擾�����݌ɑg�DID
    AND    xlt.subinventory_code     = msi1.secondary_inventory_name
    AND    xlt.organization_id       = msi1.organization_id
    AND    xlt.transfer_subinventory = msi2.secondary_inventory_name(+)
    AND    xlt.organization_id       = msi2.organization_id(+)
    AND    xlt.transaction_month     = TO_CHAR( oap.period_start_date, cv_yyyymm )
    AND    xlt.organization_id       = oap.organization_id
    AND    oap.open_flag             = cv_flag_y                   -- �݌ɉ�v���ԃI�[�v���t���O�FY
    GROUP BY
      xlt.transaction_month                                        -- ����N��
     ,xlt.base_code                                                -- ���_�R�[�h
     ,xlt.subinventory_code                                        -- �ۊǏꏊ�R�[�h
     ,msi1.attribute1                                              -- �ۊǏꏊ�敪
     ,xlt.location_code                                            -- ���P�[�V�����R�[�h
     ,xlt.parent_item_id                                           -- �e�i��ID
     ,xlt.child_item_id                                            -- �q�i��ID
     ,xlt.lot                                                      -- ���b�g
     ,xlt.difference_summary_code                                  -- �ŗL�L��
     ,xlt.transfer_subinventory                                    -- �]����ۊǏꏊ�R�[�h
     ,msi2.attribute1                                              -- �]����ۊǏꏊ�敪
     ,xlt.transaction_type_code                                    -- ����^�C�v�R�[�h
     ,xlt.reserve_transaction_type_code                            -- ����������^�C�v�R�[�h
    ORDER BY
      xlt.transaction_month                                        -- ����N��
     ,xlt.base_code                                                -- ���_�R�[�h
     ,xlt.subinventory_code                                        -- �ۊǏꏊ�R�[�h
     ,xlt.location_code                                            -- ���P�[�V�����R�[�h
     ,xlt.parent_item_id                                           -- �e�i��ID
     ,xlt.child_item_id                                            -- �q�i��ID
     ,xlt.lot                                                      -- ���b�g
     ,xlt.difference_summary_code                                  -- �ŗL�L��
  ;
--
  -- �󕥑Ώۃf�[�^�擾�J�[�\���i�������s�j
  CURSOR get_rep_data_2_cur IS
    SELECT xlt.transaction_month             trx_month             -- ����N��
          ,xlt.base_code                     base_code             -- ���_�R�[�h
          ,xlt.subinventory_code             subinv_code           -- �ۊǏꏊ�R�[�h
          ,msi1.attribute1                   subinv_type           -- �ۊǏꏊ�敪
          ,xlt.location_code                 location_code         -- ���P�[�V�����R�[�h
          ,xlt.parent_item_id                parent_item_id        -- �e�i��ID
          ,xlt.child_item_id                 child_item_id         -- �q�i��ID
          ,xlt.lot                           lot                   -- ���b�g
          ,xlt.difference_summary_code       diff_sum_code         -- �ŗL�L��
          ,xlt.transfer_subinventory         tran_subinv           -- �]����ۊǏꏊ�R�[�h
          ,msi2.attribute1                   tran_subinv_kbn       -- �]����ۊǏꏊ�敪
          ,xlt.transaction_type_code         trx_type_code         -- ����^�C�v�R�[�h
          ,xlt.reserve_transaction_type_code reserve_trx_type_code -- ����������^�C�v�R�[�h
          ,SUM(xlt.summary_qty)              rep_qty               -- �󕥐���
    FROM   xxcoi_lot_transactions    xlt                           -- ���b�g�ʎ������
          ,mtl_secondary_inventories msi1                          -- �ۊǏꏊ
          ,mtl_secondary_inventories msi2                          -- �]����ۊǏꏊ
          ,org_acct_periods          oap                           -- �݌ɉ�v���ԃe�[�u��
    WHERE  xlt.transaction_id        > gt_pre_exe_id               -- �O����ID���傫��
    AND    xlt.organization_id       = gt_org_id                   -- ���������Ŏ擾�����݌ɑg�DID
    AND    xlt.base_code             = gt_base_code                -- ���̓p�����[�^�F���_
    AND    xlt.subinventory_code     = gt_subinv_code              -- ���̓p�����[�^�F�ۊǏꏊ
    AND    xlt.subinventory_code     = msi1.secondary_inventory_name
    AND    xlt.organization_id       = msi1.organization_id
    AND    xlt.transfer_subinventory = msi2.secondary_inventory_name(+)
    AND    xlt.organization_id       = msi2.organization_id(+)
    AND    xlt.transaction_month     = TO_CHAR( oap.period_start_date, cv_yyyymm )
    AND    xlt.organization_id       = oap.organization_id
    AND    oap.open_flag             = cv_flag_y                   -- �݌ɉ�v���ԃI�[�v���t���O�FY
    GROUP BY
      xlt.transaction_month                                        -- ����N��
     ,xlt.base_code                                                -- ���_�R�[�h
     ,xlt.subinventory_code                                        -- �ۊǏꏊ�R�[�h
     ,msi1.attribute1                                              -- �ۊǏꏊ�敪
     ,xlt.location_code                                            -- ���P�[�V�����R�[�h
     ,xlt.parent_item_id                                           -- �e�i��ID
     ,xlt.child_item_id                                            -- �q�i��ID
     ,xlt.lot                                                      -- ���b�g
     ,xlt.difference_summary_code                                  -- �ŗL�L��
     ,xlt.transfer_subinventory                                    -- �]����ۊǏꏊ�R�[�h
     ,msi2.attribute1                                              -- �]����ۊǏꏊ�敪
     ,xlt.transaction_type_code                                    -- ����^�C�v�R�[�h
     ,xlt.reserve_transaction_type_code                            -- ����������^�C�v�R�[�h
    ORDER BY
      xlt.transaction_month                                        -- ����N��
     ,xlt.base_code                                                -- ���_�R�[�h
     ,xlt.subinventory_code                                        -- �ۊǏꏊ�R�[�h
     ,xlt.location_code                                            -- ���P�[�V�����R�[�h
     ,xlt.parent_item_id                                           -- �e�i��ID
     ,xlt.child_item_id                                            -- �q�i��ID
     ,xlt.lot                                                      -- ���b�g
     ,xlt.difference_summary_code                                  -- �ŗL�L��
  ;
--
  -- �󕥑Ώۃf�[�^�擾���ʕێ����R�[�h
  g_get_rep_data_rec get_rep_data_1_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : proc_end
   * Description      : �I������(A-6)
   ***********************************************************************************/
  PROCEDURE proc_end(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
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
    -- �f�[�^�A�g����e�[�u���X�V
    --==============================================================
    UPDATE xxcoi_cooperation_control xcc
    SET    xcc.last_cooperation_date  = gd_proc_date              -- �ŏI�A�g�����F�Ɩ����t
          ,xcc.transaction_id         = gt_max_trx_id             -- ���ID�F�ő���ID
          ,xcc.last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,xcc.last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,xcc.last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
          ,xcc.request_id             = cn_request_id             -- �v��ID
          ,xcc.program_application_id = cn_program_application_id -- �A�v���P�[�V����ID
          ,xcc.program_id             = cn_program_id             -- �v���O����ID
          ,xcc.program_update_date    = cd_program_update_date    -- �v���O�����X�V��
    WHERE  xcc.program_short_name     = cv_pkg_name               -- �v���O������
    ;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_end;
--
  /**********************************************************************************
   * Procedure Name   : cre_inout_data
   * Description      : ���b�g�ʎ󕥁i�����j�f�[�^�o�^�E�X�V���� (A-5)
   ***********************************************************************************/
  PROCEDURE cre_inout_data(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_inout_data'; -- �v���O������
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
    ln_exist_chk1       NUMBER;      -- ���b�g�ʎ󕥁i�����j���݃`�F�b�N
    ln_exist_chk2       NUMBER;      -- ���b�g�ʎ󕥁i�����j�����f�[�^���݃`�F�b�N
    lv_proc_date_yyyymm VARCHAR2(6); -- �Ɩ����tYYYYMM�^
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
    ln_exist_chk1       := 0;                                  -- ���b�g�ʎ󕥁i�����j���݃`�F�b�N
    ln_exist_chk2       := 0;                                  -- ���b�g�ʎ󕥁i�����j�����f�[�^���݃`�F�b�N
    lv_proc_date_yyyymm := TO_CHAR( gd_proc_date, cv_yyyymm ); -- �Ɩ����tYYYYMM�^
--
    --==============================================================
    -- �����Ώۂ̃f�[�^�����݂��邩�`�F�b�N
    --==============================================================
    SELECT COUNT(1)
    INTO   ln_exist_chk1                                           -- ���b�g�ʎ󕥁i�����j���݃`�F�b�N
    FROM   xxcoi_lot_reception_monthly xlrm
    WHERE  xlrm.practice_month          = gt_bef_practice_month    -- ����N��
    AND    xlrm.base_code               = gt_bef_base_code         -- ���_�R�[�h
    AND    xlrm.subinventory_code       = gt_bef_subinventory_code -- �ۊǏꏊ�R�[�h
    AND    xlrm.location_code           = gt_bef_location_code     -- ���P�[�V�����R�[�h
    AND    xlrm.parent_item_id          = gt_bef_parent_item_id    -- �e�i��ID
    AND    xlrm.child_item_id           = gt_bef_child_item_id     -- �q�i��ID
    AND    xlrm.lot                     = gt_bef_lot               -- ���b�g
    AND    xlrm.difference_summary_code = gt_bef_diff_sum_code     -- �ŗL�L��
    AND    xlrm.data_type               = gt_startup_flg           -- �f�[�^�敪
    AND    ROWNUM                       = 1
    ;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�́A�V�K�쐬
    IF ( ln_exist_chk1 = 0 ) THEN
      --==============================================================
      -- ���b�g�ʎ󕥁i�����j�V�K�쐬
      --==============================================================
      INSERT INTO xxcoi_lot_reception_monthly(
        base_code                                               -- ���_�R�[�h
       ,organization_id                                         -- �݌ɑg�DID
       ,subinventory_code                                       -- �ۊǏꏊ�R�[�h
       ,subinventory_type                                       -- �ۊǏꏊ�敪
       ,location_code                                           -- ���P�[�V�����R�[�h
       ,practice_month                                          -- �N��
       ,practice_date                                           -- �N����
       ,parent_item_id                                          -- �e�i��ID
       ,child_item_id                                           -- �q�i��ID
       ,lot                                                     -- ���b�g
       ,difference_summary_code                                 -- �ŗL�L��
       ,month_begin_quantity                                    -- ����I����
       ,factory_stock                                           -- �H�����
       ,factory_stock_b                                         -- �H����ɐU��
       ,change_stock                                            -- �q�֓���
       ,others_stock                                            -- ���o�ɁQ���̑�����
       ,truck_stock                                             -- �c�ƎԂ�����
       ,truck_ship                                              -- �c�ƎԂ֏o��
       ,sales_shipped                                           -- ����o��
       ,sales_shipped_b                                         -- ����o�ɐU��
       ,return_goods                                            -- �ԕi
       ,return_goods_b                                          -- �ԕi�U��
       ,customer_sample_ship                                    -- �ڋq���{�o��
       ,customer_sample_ship_b                                  -- �ڋq���{�o�ɐU��
       ,customer_support_ss                                     -- �ڋq���^���{�o��
       ,customer_support_ss_b                                   -- �ڋq���^���{�o�ɐU��
       ,ccm_sample_ship                                         -- �ڋq�L����`��A���Џ��i
       ,ccm_sample_ship_b                                       -- �ڋq�L����`��A���Џ��i�U��
       ,vd_supplement_stock                                     -- ����VD��[����
       ,vd_supplement_ship                                      -- ����VD��[�o��
       ,removed_goods                                           -- �p�p
       ,removed_goods_b                                         -- �p�p�U��
       ,change_ship                                             -- �q�֏o��
       ,others_ship                                             -- ���o�ɁQ���̑��o��
       ,factory_change                                          -- �H��q��
       ,factory_change_b                                        -- �H��q�֐U��
       ,factory_return                                          -- �H��ԕi
       ,factory_return_b                                        -- �H��ԕi�U��
       ,location_decrease                                       -- ���P�[�V�����ړ���
       ,location_increase                                       -- ���P�[�V�����ړ���
       ,adjust_decrease                                         -- �݌ɒ�����
       ,adjust_increase                                         -- �݌ɒ�����
       ,book_inventory_quantity                                 -- ����݌ɐ�
       ,data_type                                               -- �f�[�^�敪
       ,created_by                                              -- �쐬��
       ,creation_date                                           -- �쐬��
       ,last_updated_by                                         -- �ŏI�X�V��
       ,last_update_date                                        -- �ŏI�X�V��
       ,last_update_login                                       -- �ŏI�X�V���O�C��
       ,request_id                                              -- �v��ID
       ,program_application_id                                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                                              -- �R���J�����g�E�v���O����ID
       ,program_update_date                                     -- �v���O�����X�V��
      )VALUES(
        gt_bef_base_code                                        -- ���_�R�[�h
       ,gt_org_id                                               -- �݌ɑg�DID
       ,gt_bef_subinventory_code                                -- �ۊǏꏊ�R�[�h
       ,gt_bef_subinv_type                                      -- �ۊǏꏊ�敪
       ,gt_bef_location_code                                    -- ���P�[�V�����R�[�h
       ,gt_bef_practice_month                                   -- �N��
       ,LAST_DAY( TO_DATE( gt_bef_practice_month, cv_yyyymm ) ) -- �N����
       ,gt_bef_parent_item_id                                   -- �e�i��ID
       ,gt_bef_child_item_id                                    -- �q�i��ID
       ,gt_bef_lot                                              -- ���b�g
       ,gt_bef_diff_sum_code                                    -- �ŗL�L��
       ,0                                                       -- ����I����
       ,gt_factory_stock                                        -- �H�����
       ,(gt_factory_stock_b) * cn_minus_1                       -- �H����ɐU��
       ,gt_change_stock                                         -- �q�֓���
       ,gt_others_stock                                         -- ���o�ɁQ���̑�����
       ,gt_truck_stock                                          -- �c�ƎԂ�����
       ,(gt_truck_ship) * cn_minus_1                            -- �c�ƎԂ֏o��
       ,(gt_sales_shipped) * cn_minus_1                         -- ����o��
       ,gt_sales_shipped_b                                      -- ����o�ɐU��
       ,gt_return_goods                                         -- �ԕi
       ,(gt_return_goods_b) * cn_minus_1                        -- �ԕi�U��
       ,(gt_customer_sample_ship) * cn_minus_1                  -- �ڋq���{�o��
       ,gt_customer_sample_ship_b                               -- �ڋq���{�o�ɐU��
       ,(gt_customer_support_ss) * cn_minus_1                   -- �ڋq���^���{�o��
       ,gt_customer_support_ss_b                                -- �ڋq���^���{�o�ɐU��
       ,(gt_ccm_sample_ship) * cn_minus_1                       -- �ڋq�L����`��A���Џ��i
       ,gt_ccm_sample_ship_b                                    -- �ڋq�L����`��A���Џ��i�U��
       ,gt_vd_supplement_stock                                  -- ����VD��[����
       ,(gt_vd_supplement_ship) * cn_minus_1                    -- ����VD��[�o��
       ,(gt_removed_goods) * cn_minus_1                         -- �p�p
       ,gt_removed_goods_b                                      -- �p�p�U��
       ,(gt_change_ship) * cn_minus_1                           -- �q�֏o��
       ,(gt_others_ship) * cn_minus_1                           -- ���o�ɁQ���̑��o��
       ,(gt_factory_change) * cn_minus_1                        -- �H��q��
       ,gt_factory_change_b                                     -- �H��q�֐U��
       ,(gt_factory_return) * cn_minus_1                        -- �H��ԕi
       ,gt_factory_return_b                                     -- �H��ԕi�U��
       ,gt_location_decrease                                    -- ���P�[�V�����ړ���
       ,(gt_location_increase) * cn_minus_1                     -- ���P�[�V�����ړ���
       ,gt_adjust_decrease                                      -- �݌ɒ�����
       ,(gt_adjust_increase) * cn_minus_1                       -- �݌ɒ�����
       ,gt_book_inventory_quantity                              -- ����݌ɐ�
       ,gt_startup_flg                                          -- �f�[�^�敪
       ,cn_created_by                                           -- �쐬��
       ,cd_creation_date                                        -- �쐬��
       ,cn_last_updated_by                                      -- �ŏI�X�V��
       ,cd_last_update_date                                     -- �ŏI�X�V��
       ,cn_last_update_login                                    -- �ŏI�X�V���O�C��
       ,cn_request_id                                           -- �v��ID
       ,cn_program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                           -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                                  -- �v���O�����X�V��
      );
--
      -- ���������J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
--
    -- �Ώۃf�[�^�����݂���ꍇ�́A�X�V
    ELSE
      --==============================================================
      -- ���b�g�ʎ󕥁i�����j�X�V
      --==============================================================
      UPDATE xxcoi_lot_reception_monthly xlrm
      SET    xlrm.factory_stock           = xlrm.factory_stock           + gt_factory_stock
                                                                 -- �H�����
            ,xlrm.factory_stock_b         = xlrm.factory_stock_b         + (gt_factory_stock_b) * cn_minus_1
                                                                 -- �H����ɐU��
            ,xlrm.change_stock            = xlrm.change_stock            + gt_change_stock
                                                                 -- �q�֓���
            ,xlrm.others_stock            = xlrm.others_stock            + gt_others_stock
                                                                 -- ���o�ɁQ���̑�����
            ,xlrm.truck_stock             = xlrm.truck_stock             + gt_truck_stock
                                                                 -- �c�ƎԂ�����
            ,xlrm.truck_ship              = xlrm.truck_ship              + (gt_truck_ship) * cn_minus_1
                                                                 -- �c�ƎԂ֏o��
            ,xlrm.sales_shipped           = xlrm.sales_shipped           + (gt_sales_shipped) * cn_minus_1
                                                                 -- ����o��
            ,xlrm.sales_shipped_b         = xlrm.sales_shipped_b         + gt_sales_shipped_b
                                                                 -- ����o�ɐU��
            ,xlrm.return_goods            = xlrm.return_goods            + gt_return_goods
                                                                 -- �ԕi
            ,xlrm.return_goods_b          = xlrm.return_goods_b          + (gt_return_goods_b) * cn_minus_1
                                                                 -- �ԕi�U��
            ,xlrm.customer_sample_ship    = xlrm.customer_sample_ship    + (gt_customer_sample_ship) * cn_minus_1
                                                                 -- �ڋq���{�o��
            ,xlrm.customer_sample_ship_b  = xlrm.customer_sample_ship_b  + gt_customer_sample_ship_b
                                                                 -- �ڋq���{�o�ɐU��
            ,xlrm.customer_support_ss     = xlrm.customer_support_ss     + (gt_customer_support_ss) * cn_minus_1
                                                                 -- �ڋq���^���{�o��
            ,xlrm.customer_support_ss_b   = xlrm.customer_support_ss_b   + gt_customer_support_ss_b
                                                                 -- �ڋq���^���{�o�ɐU��
            ,xlrm.ccm_sample_ship         = xlrm.ccm_sample_ship         + (gt_ccm_sample_ship) * cn_minus_1
                                                                 -- �ڋq�L����`��A���Џ��i
            ,xlrm.ccm_sample_ship_b       = xlrm.ccm_sample_ship_b       + gt_ccm_sample_ship_b
                                                                 -- �ڋq�L����`��A���Џ��i�U��
            ,xlrm.vd_supplement_stock     = xlrm.vd_supplement_stock     + gt_vd_supplement_stock
                                                                 -- ����VD��[����
            ,xlrm.vd_supplement_ship      = xlrm.vd_supplement_ship      + (gt_vd_supplement_ship) * cn_minus_1
                                                                 -- ����VD��[�o��
            ,xlrm.removed_goods           = xlrm.removed_goods           + (gt_removed_goods) * cn_minus_1
                                                                 -- �p�p
            ,xlrm.removed_goods_b         = xlrm.removed_goods_b         + gt_removed_goods_b
                                                                 -- �p�p�U��
            ,xlrm.change_ship             = xlrm.change_ship             + (gt_change_ship) * cn_minus_1
                                                                 -- �q�֏o��
            ,xlrm.others_ship             = xlrm.others_ship             + (gt_others_ship) * cn_minus_1
                                                                 -- ���o�ɁQ���̑��o��
            ,xlrm.factory_change          = xlrm.factory_change          + (gt_factory_change) * cn_minus_1
                                                                 -- �H��q��
            ,xlrm.factory_change_b        = xlrm.factory_change_b        + gt_factory_change_b
                                                                 -- �H��q�֐U��
            ,xlrm.factory_return          = xlrm.factory_return          + (gt_factory_return) * cn_minus_1
                                                                 -- �H��ԕi
            ,xlrm.factory_return_b        = xlrm.factory_return_b        + gt_factory_return_b
                                                                 -- �H��ԕi�U��
            ,xlrm.location_decrease       = xlrm.location_decrease       + gt_location_decrease
                                                                 -- ���P�[�V�����ړ���
            ,xlrm.location_increase       = xlrm.location_increase       + (gt_location_increase) * cn_minus_1
                                                                 -- ���P�[�V�����ړ���
            ,xlrm.adjust_decrease         = xlrm.adjust_decrease         + gt_adjust_decrease
                                                                 -- �݌ɒ�����
            ,xlrm.adjust_increase         = xlrm.adjust_increase         + (gt_adjust_increase) * cn_minus_1
                                                                 -- �݌ɒ�����
            ,xlrm.book_inventory_quantity = xlrm.book_inventory_quantity + gt_book_inventory_quantity
                                                                 -- ����݌ɐ�
            ,xlrm.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
            ,xlrm.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
            ,xlrm.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,xlrm.request_id              = cn_request_id             -- �v��ID
            ,xlrm.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xlrm.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
            ,xlrm.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
      WHERE  xlrm.practice_month          = gt_bef_practice_month     -- ����N��
      AND    xlrm.base_code               = gt_bef_base_code          -- ���_�R�[�h
      AND    xlrm.subinventory_code       = gt_bef_subinventory_code  -- �ۊǏꏊ�R�[�h
      AND    xlrm.location_code           = gt_bef_location_code      -- ���P�[�V�����R�[�h
      AND    xlrm.parent_item_id          = gt_bef_parent_item_id     -- �e�i��ID
      AND    xlrm.child_item_id           = gt_bef_child_item_id      -- �q�i��ID
      AND    xlrm.lot                     = gt_bef_lot                -- ���b�g
      AND    xlrm.difference_summary_code = gt_bef_diff_sum_code      -- �ŗL�L��
      AND    xlrm.data_type               = gt_startup_flg            -- �f�[�^�敪
      ;
--
      -- ���������J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
--
    -- �����Ώۂ̎���N�����Ɩ����t���ߋ����̏ꍇ
    IF ( gt_bef_practice_month < lv_proc_date_yyyymm ) THEN
      --==============================================================
      -- �����Ώۂ̃f�[�^�ŁA�����f�[�^�����݂��邩�`�F�b�N
      --==============================================================
      SELECT COUNT(1)
      INTO   ln_exist_chk2                                           -- ���b�g�ʎ󕥁i�����j���݃`�F�b�N
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.practice_month          = lv_proc_date_yyyymm      -- �Ɩ����t
      AND    xlrm.base_code               = gt_bef_base_code         -- ���_�R�[�h
      AND    xlrm.subinventory_code       = gt_bef_subinventory_code -- �ۊǏꏊ�R�[�h
      AND    xlrm.location_code           = gt_bef_location_code     -- ���P�[�V�����R�[�h
      AND    xlrm.parent_item_id          = gt_bef_parent_item_id    -- �e�i��ID
      AND    xlrm.child_item_id           = gt_bef_child_item_id     -- �q�i��ID
      AND    xlrm.lot                     = gt_bef_lot               -- ���b�g
      AND    xlrm.difference_summary_code = gt_bef_diff_sum_code     -- �ŗL�L��
      AND    xlrm.data_type               = gt_startup_flg           -- �f�[�^�敪
      AND    ROWNUM                       = 1
      ;
--
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�́A�V�K�쐬
      IF ( ln_exist_chk2 = 0 ) THEN
        --==============================================================
        -- ���b�g�ʎ󕥁i�����j�V�K�쐬
        --==============================================================
        INSERT INTO xxcoi_lot_reception_monthly(
          base_code                  -- ���_�R�[�h
         ,organization_id            -- �݌ɑg�DID
         ,subinventory_code          -- �ۊǏꏊ�R�[�h
         ,subinventory_type          -- �ۊǏꏊ�敪
         ,location_code              -- ���P�[�V�����R�[�h
         ,practice_month             -- �N��
         ,practice_date              -- �N����
         ,parent_item_id             -- �e�i��ID
         ,child_item_id              -- �q�i��ID
         ,lot                        -- ���b�g
         ,difference_summary_code    -- �ŗL�L��
         ,month_begin_quantity       -- ����I����
         ,factory_stock              -- �H�����
         ,factory_stock_b            -- �H����ɐU��
         ,change_stock               -- �q�֓���
         ,others_stock               -- ���o�ɁQ���̑�����
         ,truck_stock                -- �c�ƎԂ�����
         ,truck_ship                 -- �c�ƎԂ֏o��
         ,sales_shipped              -- ����o��
         ,sales_shipped_b            -- ����o�ɐU��
         ,return_goods               -- �ԕi
         ,return_goods_b             -- �ԕi�U��
         ,customer_sample_ship       -- �ڋq���{�o��
         ,customer_sample_ship_b     -- �ڋq���{�o�ɐU��
         ,customer_support_ss        -- �ڋq���^���{�o��
         ,customer_support_ss_b      -- �ڋq���^���{�o�ɐU��
         ,ccm_sample_ship            -- �ڋq�L����`��A���Џ��i
         ,ccm_sample_ship_b          -- �ڋq�L����`��A���Џ��i�U��
         ,vd_supplement_stock        -- ����VD��[����
         ,vd_supplement_ship         -- ����VD��[�o��
         ,removed_goods              -- �p�p
         ,removed_goods_b            -- �p�p�U��
         ,change_ship                -- �q�֏o��
         ,others_ship                -- ���o�ɁQ���̑��o��
         ,factory_change             -- �H��q��
         ,factory_change_b           -- �H��q�֐U��
         ,factory_return             -- �H��ԕi
         ,factory_return_b           -- �H��ԕi�U��
         ,location_decrease          -- ���P�[�V�����ړ���
         ,location_increase          -- ���P�[�V�����ړ���
         ,adjust_decrease            -- �݌ɒ�����
         ,adjust_increase            -- �݌ɒ�����
         ,book_inventory_quantity    -- ����݌ɐ�
         ,data_type                  -- �f�[�^�敪
         ,created_by                 -- �쐬��
         ,creation_date              -- �쐬��
         ,last_updated_by            -- �ŏI�X�V��
         ,last_update_date           -- �ŏI�X�V��
         ,last_update_login          -- �ŏI�X�V���O�C��
         ,request_id                 -- �v��ID
         ,program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 -- �R���J�����g�E�v���O����ID
         ,program_update_date        -- �v���O�����X�V��
        )VALUES(
          gt_bef_base_code           -- ���_�R�[�h
         ,gt_org_id                  -- �݌ɑg�DID
         ,gt_bef_subinventory_code   -- �ۊǏꏊ�R�[�h
         ,gt_bef_subinv_type         -- �ۊǏꏊ�敪
         ,gt_bef_location_code       -- ���P�[�V�����R�[�h
         ,lv_proc_date_yyyymm        -- �N��
         ,LAST_DAY( gd_proc_date )   -- �N����
         ,gt_bef_parent_item_id      -- �e�i��ID
         ,gt_bef_child_item_id       -- �q�i��ID
         ,gt_bef_lot                 -- ���b�g
         ,gt_bef_diff_sum_code       -- �ŗL�L��
         ,gt_book_inventory_quantity -- ����I����
         ,0                          -- �H�����
         ,0                          -- �H����ɐU��
         ,0                          -- �q�֓���
         ,0                          -- ���o�ɁQ���̑�����
         ,0                          -- �c�ƎԂ�����
         ,0                          -- �c�ƎԂ֏o��
         ,0                          -- ����o��
         ,0                          -- ����o�ɐU��
         ,0                          -- �ԕi
         ,0                          -- �ԕi�U��
         ,0                          -- �ڋq���{�o��
         ,0                          -- �ڋq���{�o�ɐU��
         ,0                          -- �ڋq���^���{�o��
         ,0                          -- �ڋq���^���{�o�ɐU��
         ,0                          -- �ڋq�L����`��A���Џ��i
         ,0                          -- �ڋq�L����`��A���Џ��i
         ,0                          -- ����VD��[����
         ,0                          -- ����VD��[�o��
         ,0                          -- �p�p
         ,0                          -- �p�p�U��
         ,0                          -- �q�֏o��
         ,0                          -- ���o�ɁQ���̑��o��
         ,0                          -- �H��q��
         ,0                          -- �H��q�֐U��
         ,0                          -- �H��ԕi
         ,0                          -- �H��ԕi�U��
         ,0                          -- ���P�[�V�����ړ���
         ,0                          -- ���P�[�V�����ړ���
         ,0                          -- �݌ɒ�����
         ,0                          -- �݌ɒ�����
         ,gt_book_inventory_quantity -- ����݌ɐ�
         ,gt_startup_flg             -- �f�[�^�敪
         ,cn_created_by              -- �쐬��
         ,cd_creation_date           -- �쐬��
         ,cn_last_updated_by         -- �ŏI�X�V��
         ,cd_last_update_date        -- �ŏI�X�V��
         ,cn_last_update_login       -- �ŏI�X�V���O�C��
         ,cn_request_id              -- �v��ID
         ,cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id              -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date     -- �v���O�����X�V��
        );
--
        -- ���������J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
--
      -- �Ώۃf�[�^�����݂���ꍇ�́A�X�V
      ELSE
        --==============================================================
        -- ���b�g�ʎ󕥁i�����j�X�V
        --==============================================================
        UPDATE xxcoi_lot_reception_monthly xlrm
        SET    xlrm.month_begin_quantity    = xlrm.month_begin_quantity    + gt_book_inventory_quantity
                                                                   -- ����I����
              ,xlrm.book_inventory_quantity = xlrm.book_inventory_quantity + gt_book_inventory_quantity
                                                                   -- ����݌ɐ�
              ,xlrm.last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
              ,xlrm.last_update_date        = cd_last_update_date       -- �ŏI�X�V��
              ,xlrm.last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,xlrm.request_id              = cn_request_id             -- �v��ID
              ,xlrm.program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xlrm.program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
              ,xlrm.program_update_date     = cd_program_update_date    -- �v���O�����X�V��
        WHERE  xlrm.practice_month          = lv_proc_date_yyyymm       -- �Ɩ����t
        AND    xlrm.base_code               = gt_bef_base_code          -- ���_�R�[�h
        AND    xlrm.subinventory_code       = gt_bef_subinventory_code  -- �ۊǏꏊ�R�[�h
        AND    xlrm.location_code           = gt_bef_location_code      -- ���P�[�V�����R�[�h
        AND    xlrm.parent_item_id          = gt_bef_parent_item_id     -- �e�i��ID
        AND    xlrm.child_item_id           = gt_bef_child_item_id      -- �q�i��ID
        AND    xlrm.lot                     = gt_bef_lot                -- ���b�g
        AND    xlrm.difference_summary_code = gt_bef_diff_sum_code      -- �ŗL�L��
        AND    xlrm.data_type               = gt_startup_flg            -- �f�[�^�敪
        ;
--
        -- ���������J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END IF;
--
    -- �ϐ��̃��Z�b�g
    -- �O���R�[�h���b�g���ێ��p�ϐ�
    gt_bef_practice_month      := NULL;      -- ����N��
    gt_bef_base_code           := NULL;      -- ���_�R�[�h
    gt_bef_subinventory_code   := NULL;      -- �ۊǏꏊ�R�[�h
    gt_bef_subinv_type         := NULL;      -- �ۊǏꏊ�敪
    gt_bef_location_code       := NULL;      -- ���P�[�V�����R�[�h
    gt_bef_parent_item_id      := NULL;      -- �e�i��ID
    gt_bef_child_item_id       := NULL;      -- �q�i��ID
    gt_bef_lot                 := NULL;      -- ���b�g
    gt_bef_diff_sum_code       := NULL;      -- �ŗL�L��
--
    -- �󕥍��ڌv�Z���ʕێ��p�ϐ�
    gt_factory_stock           := 0;         -- �H�����
    gt_factory_stock_b         := 0;         -- �H����ɐU��
    gt_change_stock            := 0;         -- �q�֓���
    gt_others_stock            := 0;         -- ���o�ɁQ���̑�����
    gt_truck_stock             := 0;         -- �c�ƎԂ�����
    gt_truck_ship              := 0;         -- �c�ƎԂ֏o��
    gt_sales_shipped           := 0;         -- ����o��
    gt_sales_shipped_b         := 0;         -- ����o�ɐU��
    gt_return_goods            := 0;         -- �ԕi
    gt_return_goods_b          := 0;         -- �ԕi�U��
    gt_customer_sample_ship    := 0;         -- �ڋq���{�o��
    gt_customer_sample_ship_b  := 0;         -- �ڋq���{�o�ɐU��
    gt_customer_support_ss     := 0;         -- �ڋq���^���{�o��
    gt_customer_support_ss_b   := 0;         -- �ڋq���^���{�o�ɐU��
    gt_ccm_sample_ship         := 0;         -- �ڋq�L����`��A���Џ��i
    gt_ccm_sample_ship_b       := 0;         -- �ڋq�L����`��A���Џ��i�U��
    gt_vd_supplement_stock     := 0;         -- ����VD��[����
    gt_vd_supplement_ship      := 0;         -- ����VD��[�o��
    gt_removed_goods           := 0;         -- �p�p
    gt_removed_goods_b         := 0;         -- �p�p�U��
    gt_change_ship             := 0;         -- �q�֏o��
    gt_others_ship             := 0;         -- ���o�ɁQ���̑��o��
    gt_factory_change          := 0;         -- �H��q��
    gt_factory_change_b        := 0;         -- �H��q�֐U��
    gt_factory_return          := 0;         -- �H��ԕi
    gt_factory_return_b        := 0;         -- �H��ԕi�U��
    gt_location_decrease       := 0;         -- ���P�[�V�����ړ���
    gt_location_increase       := 0;         -- ���P�[�V�����ړ���
    gt_adjust_decrease         := 0;         -- �݌ɒ�����
    gt_adjust_increase         := 0;         -- �݌ɒ�����
    gt_book_inventory_quantity := 0;         -- ����݌ɐ�
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cre_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : cal_inout_data
   * Description      : �󕥍��ڎZ�o���� (A-4)
   ***********************************************************************************/
  PROCEDURE cal_inout_data(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cal_inout_data'; -- �v���O������
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
    lv_not_exist_flag VARCHAR2(1); -- �ŏI���R�[�h�t���O
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
    -- �O���R�[�h���b�g���ێ��p�ϐ�
    gt_bef_practice_month      := NULL;      -- ����N��
    gt_bef_base_code           := NULL;      -- ���_�R�[�h
    gt_bef_subinventory_code   := NULL;      -- �ۊǏꏊ�R�[�h
    gt_bef_subinv_type         := NULL;      -- �ۊǏꏊ�敪
    gt_bef_location_code       := NULL;      -- ���P�[�V�����R�[�h
    gt_bef_parent_item_id      := NULL;      -- �e�i��ID
    gt_bef_child_item_id       := NULL;      -- �q�i��ID
    gt_bef_lot                 := NULL;      -- ���b�g
    gt_bef_diff_sum_code       := NULL;      -- �ŗL�L��
--
    -- �󕥍��ڌv�Z���ʕێ��p�ϐ�
    gt_factory_stock           := 0;         -- �H�����
    gt_factory_stock_b         := 0;         -- �H����ɐU��
    gt_change_stock            := 0;         -- �q�֓���
    gt_others_stock            := 0;         -- ���o�ɁQ���̑�����
    gt_truck_stock             := 0;         -- �c�ƎԂ�����
    gt_truck_ship              := 0;         -- �c�ƎԂ֏o��
    gt_sales_shipped           := 0;         -- ����o��
    gt_sales_shipped_b         := 0;         -- ����o�ɐU��
    gt_return_goods            := 0;         -- �ԕi
    gt_return_goods_b          := 0;         -- �ԕi�U��
    gt_customer_sample_ship    := 0;         -- �ڋq���{�o��
    gt_customer_sample_ship_b  := 0;         -- �ڋq���{�o�ɐU��
    gt_customer_support_ss     := 0;         -- �ڋq���^���{�o��
    gt_customer_support_ss_b   := 0;         -- �ڋq���^���{�o�ɐU��
    gt_ccm_sample_ship         := 0;         -- �ڋq�L����`��A���Џ��i
    gt_ccm_sample_ship_b       := 0;         -- �ڋq�L����`��A���Џ��i�U��
    gt_vd_supplement_stock     := 0;         -- ����VD��[����
    gt_vd_supplement_ship      := 0;         -- ����VD��[�o��
    gt_removed_goods           := 0;         -- �p�p
    gt_removed_goods_b         := 0;         -- �p�p�U��
    gt_change_ship             := 0;         -- �q�֏o��
    gt_others_ship             := 0;         -- ���o�ɁQ���̑��o��
    gt_factory_change          := 0;         -- �H��q��
    gt_factory_change_b        := 0;         -- �H��q�֐U��
    gt_factory_return          := 0;         -- �H��ԕi
    gt_factory_return_b        := 0;         -- �H��ԕi�U��
    gt_location_decrease       := 0;         -- ���P�[�V�����ړ���
    gt_location_increase       := 0;         -- ���P�[�V�����ړ���
    gt_adjust_decrease         := 0;         -- �݌ɒ�����
    gt_adjust_increase         := 0;         -- �݌ɒ�����
    gt_book_inventory_quantity := 0;         -- ����݌ɐ�
--
    -- ���[�J���ϐ�
    lv_not_exist_flag          := cv_flag_n; -- �ŏI���R�[�h�t���O
--
    -- ------------------------------------
    -- 1���R�[�h�ڃt�F�b�`
    -- ------------------------------------
    -- ������s��
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      FETCH get_rep_data_1_cur INTO g_get_rep_data_rec;
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    -- �������s��
    ELSE
      FETCH get_rep_data_2_cur INTO g_get_rep_data_rec;
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
    END IF;
--
    <<rep_data_loop>>
    LOOP
      --==============================================================
      -- �󕥍��ڂ̌v�Z
      --==============================================================
      -- ����^�C�v�F���o��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_10 ) THEN
        -- ------------------------------------
        -- �]����ۊǏꏊ�A�󕥐��ʂ́{�|�ŕ���
        -- ------------------------------------
        -- �c�ƎԂ�����
        IF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2     -- �]����ۊǏꏊ�敪�F�c�Ǝ�
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- �󕥐��ʂ��v���X
          gt_truck_stock := gt_truck_stock + g_get_rep_data_rec.rep_qty;
        -- �c�ƎԂ֏o��
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2  -- �]����ۊǏꏊ�敪�F�c�Ǝ�
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- �󕥐��ʂ��}�C�i�X
          gt_truck_ship := gt_truck_ship + g_get_rep_data_rec.rep_qty;
        -- ���o�ɁQ���̑�����
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- �]����ۊǏꏊ�敪�F�c�ƎԈȊO
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- �󕥐��ʂ��v���X
          gt_others_stock := gt_others_stock + g_get_rep_data_rec.rep_qty;
        -- ���o�ɁQ���̑��o��
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- �]����ۊǏꏊ�敪�F�c�ƎԈȊO
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- �󕥐��ʂ��}�C�i�X
          gt_others_ship := gt_others_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- ����^�C�v�F�q��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_20 ) THEN
        -- ------------------------------------
        -- �]����ۊǏꏊ�A�󕥐��ʂ́{�|�ŕ���
        -- ------------------------------------
        -- �c�ƎԂ�����
        IF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2     -- �]����ۊǏꏊ�敪�F�c�Ǝ�
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- �󕥐��ʂ��v���X
          gt_truck_stock := gt_truck_stock + g_get_rep_data_rec.rep_qty;
        -- �c�ƎԂ֏o��
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn = ct_subinv_kbn_2  -- �]����ۊǏꏊ�敪�F�c�Ǝ�
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- �󕥐��ʂ��}�C�i�X
          gt_truck_ship := gt_truck_ship + g_get_rep_data_rec.rep_qty;
        -- �q�֓���
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- �]����ۊǏꏊ�敪�F�c�ƎԈȊO
          AND g_get_rep_data_rec.rep_qty >= 0 ) THEN                 -- �󕥐��ʂ��v���X
          gt_change_stock := gt_change_stock + g_get_rep_data_rec.rep_qty;
        -- �q�֏o��
        ELSIF( g_get_rep_data_rec.tran_subinv_kbn <> ct_subinv_kbn_2 -- �]����ۊǏꏊ�敪�F�c�ƎԈȊO
          AND g_get_rep_data_rec.rep_qty < 0 ) THEN                  -- �󕥐��ʂ��}�C�i�X
          gt_change_ship := gt_change_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- ����^�C�v�F����VD��[
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_70 ) THEN
        -- ------------------------------------
        -- �]����ۊǏꏊ�A�󕥐��ʂ́{�|�ŕ���
        -- ------------------------------------
        -- ����VD��[����
        IF ( g_get_rep_data_rec.rep_qty >= 0 ) THEN -- �󕥐��ʂ��v���X
          gt_vd_supplement_stock := gt_vd_supplement_stock + g_get_rep_data_rec.rep_qty;
        -- ����VD��[�o��
        ELSE                                        -- �󕥐��ʂ��}�C�i�X
          gt_vd_supplement_ship  := gt_vd_supplement_ship + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- ����^�C�v�F�H��ԕi
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_90 ) THEN
         gt_factory_return := gt_factory_return + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�H��ԕi�U��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_100 ) THEN
         gt_factory_return_b := gt_factory_return_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�H��q��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_110 ) THEN
         gt_factory_change := gt_factory_change + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�H��q�֐U��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_120 ) THEN
         gt_factory_change_b := gt_factory_change_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�p�p
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_130 ) THEN
         gt_removed_goods := gt_removed_goods + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�p�p�U��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_140 ) THEN
         gt_removed_goods_b := gt_removed_goods_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�H�����
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_150 ) THEN
         gt_factory_stock := gt_factory_stock + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�H����ɐU��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_160 ) THEN
         gt_factory_stock_b := gt_factory_stock_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ԕi
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_190 ) THEN
         gt_return_goods := gt_return_goods + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ԕi�U��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_200 ) THEN
         gt_return_goods_b := gt_return_goods_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq���{�o��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_320 ) THEN
         gt_customer_sample_ship := gt_customer_sample_ship + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq���{�o�ɐU��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_330 ) THEN
         gt_customer_sample_ship_b := gt_customer_sample_ship_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F����o��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_170 ) THEN
         gt_sales_shipped := gt_sales_shipped + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F����o�ɐU��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_180 ) THEN
         gt_sales_shipped_b := gt_sales_shipped_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq���^���{�o��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_340 ) THEN
         gt_customer_support_ss := gt_customer_support_ss + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq���^���{�o�ɐU��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_350 ) THEN
         gt_customer_support_ss_b := gt_customer_support_ss_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq�L����`��A���Џ��i
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_360 ) THEN
         gt_ccm_sample_ship := gt_ccm_sample_ship + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�ڋq�L����`��A���Џ��i�U��
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_370 ) THEN
         gt_ccm_sample_ship_b := gt_ccm_sample_ship_b + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F���P�[�V�����ړ�
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_390 ) THEN
        -- ------------------------------------
        -- �󕥐��ʂ́{�|�ŕ���
        -- ------------------------------------
        -- ���P�[�V�����ړ���
        IF ( g_get_rep_data_rec.rep_qty >= 0 ) THEN
          gt_location_decrease := gt_location_decrease + g_get_rep_data_rec.rep_qty;
        -- ���P�[�V�����ړ���
        ELSE
          gt_location_increase := gt_location_increase + g_get_rep_data_rec.rep_qty;
        END IF;
      END IF;
--
      -- ����^�C�v�F�݌ɒ�����
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_400 ) THEN
         gt_adjust_decrease := gt_adjust_decrease + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ����^�C�v�F�݌Ɉړ���
      IF ( g_get_rep_data_rec.trx_type_code = ct_trx_type_410 ) THEN
         gt_adjust_increase := gt_adjust_increase + g_get_rep_data_rec.rep_qty;
      END IF;
--
      -- ------------------------------------
      -- ����݌ɐ����Z
      -- ------------------------------------
      gt_book_inventory_quantity := gt_book_inventory_quantity + g_get_rep_data_rec.rep_qty;
--
      --==============================================================
      -- �O���R�[�h���ێ�
      --==============================================================
      gt_bef_practice_month    := g_get_rep_data_rec.trx_month;      -- ����N��
      gt_bef_base_code         := g_get_rep_data_rec.base_code;      -- ���_�R�[�h
      gt_bef_subinventory_code := g_get_rep_data_rec.subinv_code;    -- �ۊǏꏊ�R�[�h
      gt_bef_subinv_type       := g_get_rep_data_rec.subinv_type;    -- �ۊǏꏊ�敪
      gt_bef_location_code     := g_get_rep_data_rec.location_code;  -- ���P�[�V�����R�[�h
      gt_bef_parent_item_id    := g_get_rep_data_rec.parent_item_id; -- �e�i��ID
      gt_bef_child_item_id     := g_get_rep_data_rec.child_item_id;  -- �q�i��ID
      gt_bef_lot               := g_get_rep_data_rec.lot;            -- ���b�g
      gt_bef_diff_sum_code     := g_get_rep_data_rec.diff_sum_code;  -- �ŗL�L��
--
      --==============================================================
      -- �f�[�^�t�F�b�`
      --==============================================================
      -- ������s��
      IF ( gt_startup_flg = ct_data_type_1 ) THEN
        FETCH get_rep_data_1_cur INTO g_get_rep_data_rec;
        -- �V�K���R�[�h���擾�ł��Ȃ������ꍇ�A�ŏI���R�[�h�t���O��Y�ɂ���
        IF ( get_rep_data_1_cur%NOTFOUND ) THEN
          lv_not_exist_flag := cv_flag_y;
        -- �V�K���R�[�h���擾�o�����ꍇ�́A�Ώی����J�E���g
        ELSE
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
--
      -- �������s��
      ELSE
        FETCH get_rep_data_2_cur INTO g_get_rep_data_rec;
        -- �V�K���R�[�h���擾�ł��Ȃ������ꍇ�A�ŏI���R�[�h�t���O��Y�ɂ���
        IF ( get_rep_data_2_cur%NOTFOUND ) THEN
          lv_not_exist_flag := cv_flag_y;
        -- �V�K���R�[�h���擾�o�����ꍇ�́A�Ώی����J�E���g
        ELSE
          gn_target_cnt := gn_target_cnt + 1;
        END IF;
      END IF;
--
      --==============================================================
      -- �o�^�E�X�V�������s����
      --==============================================================
      -- �ŏI���R�[�h�̏ꍇ�A�o�^�E�X�V���������s���A���[�v�𔲂���
      IF ( lv_not_exist_flag = cv_flag_y ) THEN
        --==============================================================
        -- ���b�g�ʎ󕥁i�����j�f�[�^�o�^�E�X�V���� (A-5)
        --==============================================================
        cre_inout_data(
          ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �G���[����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ------------------------------------
        -- ���[�v�𔲂���
        -- ------------------------------------
        EXIT;
--
      -- �ŏI���R�[�h�ȊO�̏ꍇ
      ELSE
        --==============================================================
        -- �擾�������R�[�h���ƑO���R�[�h��񂪊��S��v���邩�`�F�b�N
        --==============================================================
        -- ��v����ꍇ�͎���^�C�v�A����������^�C�v�R�[�h�ʐ��ʂ̌v�Z���p��
        IF (
              gt_bef_practice_month    = g_get_rep_data_rec.trx_month      -- ����N��
          AND gt_bef_base_code         = g_get_rep_data_rec.base_code      -- ���_�R�[�h
          AND gt_bef_subinventory_code = g_get_rep_data_rec.subinv_code    -- �ۊǏꏊ�R�[�h
          AND gt_bef_location_code     = g_get_rep_data_rec.location_code  -- ���P�[�V�����R�[�h
          AND gt_bef_parent_item_id    = g_get_rep_data_rec.parent_item_id -- �e�i��ID
          AND gt_bef_child_item_id     = g_get_rep_data_rec.child_item_id  -- �q�i��ID
          AND gt_bef_lot               = g_get_rep_data_rec.lot            -- ���b�g
          AND gt_bef_diff_sum_code     = g_get_rep_data_rec.diff_sum_code  -- �ŗL�L��
        ) THEN
          -- ����^�C�v�A����������^�C�v�R�[�h�ʐ��ʂ̌v�Z���p��(�������Ȃ�)
          NULL;
--
        -- ��v���Ȃ��ꍇ�́A�o�^�E�X�V���������s
        ELSE
          --==============================================================
          -- ���b�g�ʎ󕥁i�����j�f�[�^�o�^�E�X�V���� (A-5)
          --==============================================================
          cre_inout_data(
            ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �G���[����
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP rep_data_loop;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cal_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : get_inout_data
   * Description      : �󕥃f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_inout_data(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inout_data'; -- �v���O������
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
    -- �󕥃f�[�^�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    -- ������s���́A�S���_�E�S�ۊǏꏊ��Ώ�
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      OPEN get_rep_data_1_cur;
    -- �������s���́A���̓p�����[�^�Ŏw�肵�����_�E�ۊǏꏊ�̂�
    ELSE
      OPEN get_rep_data_2_cur;
    END IF;
--
    --==============================================================
    -- �󕥍��ڎZ�o����(A-4)
    --==============================================================
    cal_inout_data(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    IF ( get_rep_data_1_cur%ISOPEN ) THEN
      CLOSE get_rep_data_1_cur;
    END IF;
--
    IF ( get_rep_data_2_cur%ISOPEN ) THEN
      CLOSE get_rep_data_2_cur;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( get_rep_data_1_cur%ISOPEN ) THEN
        CLOSE get_rep_data_1_cur;
      END IF;
--
      IF ( get_rep_data_2_cur%ISOPEN ) THEN
        CLOSE get_rep_data_2_cur;
      END IF;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF ( get_rep_data_1_cur%ISOPEN ) THEN
        CLOSE get_rep_data_1_cur;
      END IF;
--
      IF ( get_rep_data_2_cur%ISOPEN ) THEN
        CLOSE get_rep_data_2_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inout_data;
--
  /**********************************************************************************
   * Procedure Name   : cre_carry_data
   * Description      : �J�z�f�[�^�쐬����(A-2)
   ***********************************************************************************/
  PROCEDURE cre_carry_data(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_carry_data'; -- �v���O������
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
    ln_data_cre_judge NUMBER; -- �J�z�f�[�^�쐬����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���b�g�ʎ󕥁i�����j�O���f�[�^�擾�J�[�\��
    CURSOR get_pre_mounth_data_cur(
      iv_practice_month VARCHAR2 -- �Ώ۔N��
    )IS
      SELECT xlrm.base_code               base_code               -- ���_�R�[�h
            ,xlrm.subinventory_code       subinventory_code       -- �ۊǏꏊ�R�[�h
            ,xlrm.subinventory_type       subinventory_type       -- �ۊǏꏊ�敪
            ,xlrm.location_code           location_code           -- ���P�[�V�����R�[�h
            ,xlrm.parent_item_id          parent_item_id          -- �e�i��ID
            ,xlrm.child_item_id           child_item_id           -- �q�i��ID
            ,xlrm.lot                     lot                     -- ���b�g
            ,xlrm.difference_summary_code difference_summary_code -- �ŗL�L��
            ,xlrm.book_inventory_quantity book_inventory_quantity -- ����݌ɐ�
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.practice_month          = iv_practice_month     -- �Ώ۔N��
      AND    xlrm.book_inventory_quantity > 0
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_get_pre_mounth_data_rec get_pre_mounth_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2015/04/07 E_�{�ғ�_12237 V1.1 DEL START
--    -- �ϐ�������
--    ln_data_cre_judge := 0; -- �J�z�f�[�^�쐬����
--
--    --==============================================================
--    -- ����N���̔���
--    --==============================================================
--    -- ������s�̏ꍇ�̂݌����擾
--    IF ( gt_startup_flg = ct_data_type_1 ) THEN
--      SELECT COUNT(1)
--      INTO   ln_data_cre_judge
--      FROM   xxcoi_lot_reception_monthly xlrm
--      WHERE  xlrm.practice_month = TO_CHAR( gd_proc_date, cv_yyyymm ) -- �Ɩ����t�̔N��
--      AND    ROWNUM              = 1
--      ;
--    -- �������s�̏ꍇ�A�J�z�f�[�^�쐬�����1�Ƃ��A�㑱�̏������s��Ȃ�
--    ELSE
--      ln_data_cre_judge := 1;
--    END IF;
--
--    --==============================================================
--    -- �f�[�^���o�A�J�z�f�[�^�쐬
--    --==============================================================
--    -- �J�z�f�[�^�쐬���肪0�̏ꍇ�̂ݎ��{
--    IF ( ln_data_cre_judge = 0 ) THEN
--
-- 2015/04/07 E_�{�ғ�_12237 V1.1 DEL END
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD START
    -- ������s�̏ꍇ�̂݌J�z�������s��
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD END
      -- �J�[�\���I�[�v��
      OPEN get_pre_mounth_data_cur(
        iv_practice_month => TO_CHAR( ADD_MONTHS( gd_proc_date, -1 ), cv_yyyymm ) -- �Ɩ����t�̑O��
      );
--
      <<pre_mounth_data_loop>>
      LOOP
        -- �f�[�^�t�F�b�`
        FETCH get_pre_mounth_data_cur INTO l_get_pre_mounth_data_rec;
        EXIT WHEN get_pre_mounth_data_cur%NOTFOUND;
--
        -- �擾�����J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD START
        -- �ϐ�������
        ln_data_cre_judge := 0; -- �J�z�f�[�^�쐬����
--
        -- �N�����Ɩ����t���̓����f�[�^�����݂��邩�`�F�b�N
        SELECT COUNT(1) AS cnt
        INTO   ln_data_cre_judge
        FROM   xxcoi_lot_reception_monthly xlrm  -- ���b�g�ʎ�(����)
        WHERE  xlrm.practice_month          = TO_CHAR( gd_proc_date, cv_yyyymm ) -- �N��
        AND    xlrm.base_code               = l_get_pre_mounth_data_rec.base_code            -- ���_�R�[�h
        AND    xlrm.subinventory_code       = l_get_pre_mounth_data_rec.subinventory_code    -- �ۊǏꏊ�R�[�h
        AND    xlrm.location_code           = l_get_pre_mounth_data_rec.location_code        -- ���P�[�V�����R�[�h
        AND    xlrm.parent_item_id          = l_get_pre_mounth_data_rec.parent_item_id       -- �e�i��ID
        AND    xlrm.child_item_id           = l_get_pre_mounth_data_rec.child_item_id        -- �q�i��ID
        AND    xlrm.lot                     = l_get_pre_mounth_data_rec.lot                  -- ���b�g
        AND    xlrm.difference_summary_code = l_get_pre_mounth_data_rec.difference_summary_code -- �ŗL�L��
        AND    ROWNUM = 1
        ;
--
        -- �N�����Ɩ����t���̓����f�[�^�����݂��Ȃ��ꍇ
        IF ( ln_data_cre_judge = 0 ) THEN
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD END
--
          -- �J�z�f�[�^�쐬
          INSERT INTO xxcoi_lot_reception_monthly(
            base_code                                         -- ���_�R�[�h
           ,organization_id                                   -- �݌ɑg�DID
           ,subinventory_code                                 -- �ۊǏꏊ�R�[�h
           ,subinventory_type                                 -- �ۊǏꏊ�敪
           ,location_code                                     -- ���P�[�V�����R�[�h
           ,practice_month                                    -- �N��
           ,practice_date                                     -- �N����
           ,parent_item_id                                    -- �e�i��ID
           ,child_item_id                                     -- �q�i��ID
           ,lot                                               -- ���b�g
           ,difference_summary_code                           -- �ŗL�L��
           ,month_begin_quantity                              -- ����I����
           ,factory_stock                                     -- �H�����
           ,factory_stock_b                                   -- �H����ɐU��
           ,change_stock                                      -- �q�֓���
           ,others_stock                                      -- ���o�ɁQ���̑�����
           ,truck_stock                                       -- �c�ƎԂ�����
           ,truck_ship                                        -- �c�ƎԂ֏o��
           ,sales_shipped                                     -- ����o��
           ,sales_shipped_b                                   -- ����o�ɐU��
           ,return_goods                                      -- �ԕi
           ,return_goods_b                                    -- �ԕi�U��
           ,customer_sample_ship                              -- �ڋq���{�o��
           ,customer_sample_ship_b                            -- �ڋq���{�o�ɐU��
           ,customer_support_ss                               -- �ڋq���^���{�o��
           ,customer_support_ss_b                             -- �ڋq���^���{�o�ɐU��
           ,ccm_sample_ship                                   -- �ڋq�L����`��A���Џ��i
           ,ccm_sample_ship_b                                 -- �ڋq�L����`��A���Џ��i�U��
           ,vd_supplement_stock                               -- ����VD��[����
           ,vd_supplement_ship                                -- ����VD��[�o��
           ,removed_goods                                     -- �p�p
           ,removed_goods_b                                   -- �p�p�U��
           ,change_ship                                       -- �q�֏o��
           ,others_ship                                       -- ���o�ɁQ���̑��o��
           ,factory_change                                    -- �H��q��
           ,factory_change_b                                  -- �H��q�֐U��
           ,factory_return                                    -- �H��ԕi
           ,factory_return_b                                  -- �H��ԕi�U��
           ,location_decrease                                 -- ���P�[�V�����ړ���
           ,location_increase                                 -- ���P�[�V�����ړ���
           ,adjust_decrease                                   -- �݌ɒ�����
           ,adjust_increase                                   -- �݌ɒ�����
           ,book_inventory_quantity                           -- ����݌ɐ�
           ,data_type                                         -- �f�[�^�敪
           ,created_by                                        -- �쐬��
           ,creation_date                                     -- �쐬��
           ,last_updated_by                                   -- �ŏI�X�V��
           ,last_update_date                                  -- �ŏI�X�V��
           ,last_update_login                                 -- �ŏI�X�V���O�C��
           ,request_id                                        -- �v��ID
           ,program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                                        -- �R���J�����g�E�v���O����ID
           ,program_update_date                               -- �v���O�����X�V��
          )VALUES(
            l_get_pre_mounth_data_rec.base_code               -- ���_�R�[�h
           ,gt_org_id                                         -- �݌ɑg�DID
           ,l_get_pre_mounth_data_rec.subinventory_code       -- �ۊǏꏊ�R�[�h
           ,l_get_pre_mounth_data_rec.subinventory_type       -- �ۊǏꏊ�敪
           ,l_get_pre_mounth_data_rec.location_code           -- ���P�[�V�����R�[�h
           ,TO_CHAR( gd_proc_date, cv_yyyymm )                -- �N��
           ,LAST_DAY( gd_proc_date )                          -- �N����
           ,l_get_pre_mounth_data_rec.parent_item_id          -- �e�i��ID
           ,l_get_pre_mounth_data_rec.child_item_id           -- �q�i��ID
           ,l_get_pre_mounth_data_rec.lot                     -- ���b�g
           ,l_get_pre_mounth_data_rec.difference_summary_code -- �ŗL�L��
           ,l_get_pre_mounth_data_rec.book_inventory_quantity -- ����I����
           ,0                                                 -- �H�����
           ,0                                                 -- �H����ɐU��
           ,0                                                 -- �q�֓���
           ,0                                                 -- ���o�ɁQ���̑�����
           ,0                                                 -- �c�ƎԂ�����
           ,0                                                 -- �c�ƎԂ֏o��
           ,0                                                 -- ����o��
           ,0                                                 -- ����o�ɐU��
           ,0                                                 -- �ԕi
           ,0                                                 -- �ԕi�U��
           ,0                                                 -- �ڋq���{�o��
           ,0                                                 -- �ڋq���{�o�ɐU��
           ,0                                                 -- �ڋq���^���{�o��
           ,0                                                 -- �ڋq���^���{�o�ɐU��
           ,0                                                 -- �ڋq�L����`��A���Џ��i
           ,0                                                 -- �ڋq�L����`��A���Џ��i�U��
           ,0                                                 -- ����VD��[����
           ,0                                                 -- ����VD��[�o��
           ,0                                                 -- �p�p
           ,0                                                 -- �p�p�U��
           ,0                                                 -- �q�֏o��
           ,0                                                 -- ���o�ɁQ���̑��o��
           ,0                                                 -- �H��q��
           ,0                                                 -- �H��q�֐U��
           ,0                                                 -- �H��ԕi
           ,0                                                 -- �H��ԕi�U��
           ,0                                                 -- ���P�[�V�����ړ���
           ,0                                                 -- ���P�[�V�����ړ���
           ,0                                                 -- �݌ɒ�����
           ,0                                                 -- �݌ɒ�����
           ,l_get_pre_mounth_data_rec.book_inventory_quantity -- ����݌ɐ�
           ,gt_startup_flg                                    -- �f�[�^�敪
           ,cn_created_by                                     -- �쐬��
           ,cd_creation_date                                  -- �쐬��
           ,cn_last_updated_by                                -- �ŏI�X�V��
           ,cd_last_update_date                               -- �ŏI�X�V��
           ,cn_last_update_login                              -- �ŏI�X�V���O�C��
           ,cn_request_id                                     -- �v��ID
           ,cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                                     -- �R���J�����g�E�v���O����ID
           ,cd_program_update_date                            -- �v���O�����X�V��
          );
--
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD START
        -- �N�����Ɩ����t���̓����f�[�^�����݂���ꍇ�͍X�V
        ELSE
          UPDATE xxcoi_lot_reception_monthly -- ���b�g�ʎ�(����)
          SET    month_begin_quantity     = l_get_pre_mounth_data_rec.book_inventory_quantity     -- ����݌ɐ�
                ,book_inventory_quantity  = book_inventory_quantity
                                              + l_get_pre_mounth_data_rec.book_inventory_quantity -- ����݌ɐ�
                ,last_updated_by          = cn_last_updated_by             -- �ŏI�X�V��
                ,last_update_date         = cd_last_update_date            -- �ŏI�X�V��
                ,last_update_login        = cn_last_update_login           -- �ŏI�X�V���O�C��
                ,request_id               = cn_request_id                  -- �v��ID
                ,program_application_id   = cn_program_application_id      -- �A�v���P�[�V����ID
                ,program_id               = cn_program_id                  -- �v���O����ID
                ,program_update_date      = cd_program_update_date         -- �v���O�����X�V��
          WHERE  practice_month           = TO_CHAR( gd_proc_date, cv_yyyymm )           -- �N��
          AND    base_code                = l_get_pre_mounth_data_rec.base_code          -- ���_�R�[�h
          AND    subinventory_code        = l_get_pre_mounth_data_rec.subinventory_code  -- �ۊǏꏊ�R�[�h
          AND    location_code            = l_get_pre_mounth_data_rec.location_code      -- ���P�[�V�����R�[�h
          AND    parent_item_id           = l_get_pre_mounth_data_rec.parent_item_id     -- �e�i��ID
          AND    child_item_id            = l_get_pre_mounth_data_rec.child_item_id      -- �q�i��ID
          AND    lot                      = l_get_pre_mounth_data_rec.lot                -- ���b�g
          AND    difference_summary_code  = l_get_pre_mounth_data_rec.difference_summary_code  -- �ŗL�L��
          ;
        END IF;
-- 2015/04/07 E_�{�ғ�_12237 V1.1 ADD END
        -- ���������J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP pre_mounth_data_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE get_pre_mounth_data_cur;
--
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
      IF ( get_pre_mounth_data_cur%ISOPEN ) THEN
        CLOSE get_pre_mounth_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END cre_carry_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2 --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2 --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2 --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���̓p�����[�^����
    lt_base_name        hz_parties.party_name%TYPE;                 -- ���_��
    lt_subinv_name      mtl_secondary_inventories.description%TYPE; -- �ۊǏꏊ��
    lt_startup_flg_name fnd_lookup_values.meaning%TYPE;             -- �N���t���O��
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
    -- �O���[�o���ϐ�������
    --==============================================================
    -- ���̓p�����[�^����
    lt_base_name        := NULL;      -- ���_��
    lt_subinv_name      := NULL;      -- �ۊǏꏊ��
    lt_startup_flg_name := NULL;      -- �N���t���O��
    -- ���������擾�l
    gt_org_code         := NULL;      -- �݌ɑg�D�R�[�h
    gt_org_id           := NULL;      -- �݌ɑg�DID
    gd_proc_date        := NULL;      -- �Ɩ����t
    gt_pre_exe_id       := NULL;      -- �O����ID
    gt_no_data_flag     := cv_flag_n; -- �Ώ�0���t���O
    gt_max_trx_id       := NULL;      -- �ő���ID
    gt_min_trx_id       := NULL;      -- �ŏ����ID
--
    --==============================================================
    -- �݌ɑg�D�R�[�h�擾
    --==============================================================
    gt_org_code := FND_PROFILE.VALUE( cv_xxcoi1_organization_code );
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00005
                    ,iv_token_name1        => cv_tkn_pro_tok              -- �v���t�@�C����
                    ,iv_token_value1       => cv_xxcoi1_organization_code
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
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00006
                    ,iv_token_name1        => cv_tkn_org_code_tok         -- �݌ɑg�D�R�[�h
                    ,iv_token_value1       => gt_org_code
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
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_00011
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- 1.�N���t���O�̃`�F�b�N
    -- ���擾�̏ꍇ�́A�p�����[�^�o�͌�Ƀn���h�����O
    lt_startup_flg_name := xxcoi_common_pkg.get_meaning(
                             iv_lookup_type => ct_xxcoi1_lot_rep_month_type -- �Q�ƃ^�C�v��
                            ,iv_lookup_code => gt_startup_flg               -- �Q�ƃ^�C�v�R�[�h
                           );
--
    -- 2.���_���̎擾
    IF ( gt_base_code IS NOT NULL) THEN
      SELECT hp.party_name party_name -- �p�[�e�B��
      INTO   lt_base_name
      FROM   hz_parties       hp
            ,hz_cust_accounts hca
      WHERE  hca.account_number      = gt_base_code         -- ���̓p�����[�^.���_�R�[�h
      AND    hca.customer_class_code = ct_cust_class_code_1 -- �ڋq�敪�F���_
      AND    hca.status              = ct_cust_status_a     -- �X�e�[�^�X�F�L��
      AND    hca.party_id            = hp.party_id
      ;
    END IF;
--
    -- 3.�ۊǏꏊ���擾
    IF ( gt_subinv_code IS NOT NULL ) THEN
      SELECT msi.description description -- �ۊǏꏊ��
      INTO   lt_subinv_name
      FROM   mtl_secondary_inventories msi
      WHERE  msi.secondary_inventory_name              = gt_subinv_code -- ���̓p�����[�^.�ۊǏꏊ
      AND    msi.attribute7                            = gt_base_code   -- ���̓p�����[�^.���_�R�[�h
      AND    NVL( msi.disable_date, gd_proc_date + 1 ) > gd_proc_date   -- �������`�F�b�N
      AND    msi.organization_id                       = gt_org_id      -- �݌ɑg�DID
      ;
    END IF;
--
    --==============================================================
    -- ���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    -- ���b�Z�[�W�擾
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application        => cv_xxcoi_short_name
                  ,iv_name               => cv_msg_xxcoi1_10454
                  ,iv_token_name1        => cv_tkn_base_code        -- ���_�R�[�h
                  ,iv_token_value1       => gt_base_code
                  ,iv_token_name2        => cv_tkn_base_name        -- ���_��
                  ,iv_token_value2       => lt_base_name
                  ,iv_token_name3        => cv_tkn_subinv_code      -- �ۊǏꏊ�R�[�h
                  ,iv_token_value3       => gt_subinv_code
                  ,iv_token_name4        => cv_tkn_subinv_name      -- �ۊǏꏊ��
                  ,iv_token_value4       => lt_subinv_name
                  ,iv_token_name5        => cv_tkn_startup_flg      -- �N���t���O
                  ,iv_token_value5       => gt_startup_flg
                  ,iv_token_name6        => cv_tkn_startup_flg_name -- �N���t���O��
                  ,iv_token_value6       => lt_startup_flg_name
                 );
--
    -- ���b�Z�[�W�o��(�o�͂̕\��)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => lv_errmsg
    );
--
    -- ��s�o��(�o�͂̕\��)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT
     ,buff  => ''
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
    -- �N���t���O�s���G���[�n���h�����O
    IF ( lt_startup_flg_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcoi_short_name
                    ,iv_name               => cv_msg_xxcoi1_10455
                    ,iv_token_name1        => cv_tkn_startup_flg
                    ,iv_token_value1       => gt_startup_flg
                   );
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �O����ID�擾
    --==============================================================
    BEGIN
      SELECT xcc.transaction_id transaction_id
      INTO   gt_pre_exe_id
      FROM   xxcoi_cooperation_control xcc
      WHERE  xcc.program_short_name = cv_pkg_name -- �v���O������
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application        => cv_xxcoi_short_name
                      ,iv_name               => cv_msg_xxcoi1_10456
                      ,iv_token_name1        => cv_tkn_program_name -- �v���O������
                      ,iv_token_value1       => cv_pkg_name
                     );
      RAISE global_process_expt;
    END;
--
    --==============================================================
    -- �ŏ����ID�A�ő���ID�擾
    --==============================================================
    -- ������s��
    -- �O�񏈗��ψȍ~�̃f�[�^
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      SELECT MIN(xlt.transaction_id) min_trx_id     -- �ŏ����ID
            ,MAX(xlt.transaction_id) max_trx_id     -- �ő���ID
      INTO   gt_min_trx_id
            ,gt_max_trx_id
      FROM   xxcoi_lot_transactions xlt
      WHERE  xlt.transaction_id > gt_pre_exe_id     -- �O�񏈗���ID
      ;
    -- �������s��
    -- �O�񏈗��ψȍ~���A���̓p�����[�^�Ŏw�肵�����_�E�ۊǏꏊ�̃f�[�^
    ELSE
      SELECT MIN(xlt.transaction_id) min_trx_id     -- �ŏ����ID
            ,MAX(xlt.transaction_id) max_trx_id     -- �ő���ID
      INTO   gt_min_trx_id
            ,gt_max_trx_id
      FROM   xxcoi_lot_transactions xlt
      WHERE  xlt.transaction_id    > gt_pre_exe_id  -- �O�񏈗���ID
      AND    xlt.base_code         = gt_base_code   -- ���̓p�����[�^.���_
      AND    xlt.subinventory_code = gt_subinv_code -- ���̓p�����[�^.�ۊǏꏊ
      ;
    END IF;
--
    -- NULL�̏ꍇ�́A�Ώ�0���t���O��'Y'�ɂ���
    IF ( gt_max_trx_id IS NULL ) THEN
      gt_no_data_flag := cv_flag_y;
    END IF;
--
    --==============================================================
    -- �����f�[�^�폜
    --==============================================================
    -- ������s��
    -- �S�Ă̐������s�f�[�^
    IF ( gt_startup_flg = ct_data_type_1 ) THEN
      DELETE
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.data_type         = ct_data_type_2 -- �f�[�^�敪�F2
      ;
    -- �������s��
    -- ���̓p�����[�^�Ŏw�肵�����_�E�ۊǏꏊ�̃f�[�^
    ELSE
      DELETE
      FROM   xxcoi_lot_reception_monthly xlrm
      WHERE  xlrm.data_type         = ct_data_type_2 -- �f�[�^�敪�F2
      AND    xlrm.base_code         = gt_base_code   -- ���̓p�����[�^.���_
      AND    xlrm.subinventory_code = gt_subinv_code -- ���̓p�����[�^.�ۊǏꏊ
      ;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �J�z�f�[�^�쐬����(A-2)
    -- ===============================
    cre_carry_data(
      ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώ�0���t���O��'N'�̏ꍇ�̂ݎ��{
    IF ( gt_no_data_flag = cv_flag_n ) THEN
      -- ===============================
      -- �󕥃f�[�^�擾����(A-3)
      -- ===============================
      get_inout_data(
        ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[����
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ������s���̂݁A�������s��
      IF ( gt_startup_flg = ct_data_type_1 ) THEN
        -- ===============================
        -- �I������(A-6)
        -- ===============================
        proc_end(
          ov_errbuf  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �G���[����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
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
    errbuf               OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
   ,retcode              OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
   ,iv_login_base_code   IN  VARCHAR2 -- ���_�R�[�h
   ,iv_subinventory_code IN  VARCHAR2 -- �ۊǏꏊ�R�[�h
   ,iv_startup_flg       IN  VARCHAR2 -- �N���t���O
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
    -- ���̓p�����[�^�i�[
    gt_base_code   := iv_login_base_code;
    gt_subinv_code := iv_subinventory_code;
    gt_startup_flg := iv_startup_flg;
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
    --�G���[������
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
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
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    IF ( gt_no_data_flag = cv_flag_y ) THEN
      -- �Ώ�0�����b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10457
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      -- �Ώێ��ID���b�Z�[�W�o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_msg_xxcoi1_10458
                      ,iv_token_name1  => cv_tkn_min_trx_id
                      ,iv_token_value1 => TO_CHAR(gt_min_trx_id)
                      ,iv_token_name2  => cv_tkn_max_trx_id
                      ,iv_token_value2 => TO_CHAR(gt_max_trx_id)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
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
    ELSE
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
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOI016A10C;
/
