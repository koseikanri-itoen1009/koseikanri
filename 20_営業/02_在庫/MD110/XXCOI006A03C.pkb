CREATE OR REPLACE PACKAGE BODY XXCOI006A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A03C(body)
 * Description      : �����݌Ɏ󕥁i�����j�����ɁA�����݌Ɏ󕥕\���쐬���܂��B
 * MD.050           : �����݌Ɏ󕥕\�쐬<MD050_COI_006_A03>
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  close_process          �I������                             (A-14)
 *  ins_month_balance      ����c���o��                         (A-13)
 *  ins_daily_invcntl      �I���Ǘ��o�́i��������f�[�^�j       (A-11)
 *  ins_daily_data         �����݌Ɏ󕥏o�́i��������f�[�^�j   (A-10)
 *  upd_inv_control        �I���Ǘ��o�́i�I�����ʃf�[�^�j       (A-8)
 *  ins_inv_result         �����݌Ɏ󕥏o�́i�I�����ʃf�[�^�j   (A-7)
 *  ins_inv_control        �I���Ǘ��o�́i�����f�[�^�j           (A-5)
 *  ins_invrcp_daily       �����݌Ɏ󕥏o�́i�����f�[�^�j       (A-4)
 *  del_invrcp_monthly     �쐬�ς݌����݌Ɏ󕥃f�[�^�폜       (A-3)
 *  init                   ��������                             (A-1)
 *  submain                ���C�������v���V�[�W��
 *                         �����݌Ɏ󕥁i�����j���擾         (A-2)
 *                         �I�����ʏ�񒊏o                     (A-6)
 *                         ��������f�[�^�擾                   (A-9)
 *                         �O���I�����ʒ��o                     (A-12)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/12    1.0   H.Sasaki         ���ō쐬
 *  2009/02/17    1.1   H.Sasaki         [��QCOI_007]�I���Ǘ�����̌����݌Ɏ󕥂̍쐬�����ǉ�
 *  2009/02/17    1.2   H.Sasaki         [��QCOI_008]���ގ������̌����݌Ɏ󕥂̍쐬�����ǉ�
 *  2009/02/18    1.3   H.Sasaki         [��QCOI_016]�I���Ǘ��̒��o���@�ύX
 *  2009/02/19    1.4   H.Sasaki         [��QCOI_020]�I���Ǘ��V�K�쐬���̏�����ǉ�
 *  2009/03/17    1.5   H.Sasaki         [T1_0076]����I�����Z�o�̎��s�����ύX
 *  2009/03/30    1.6   H.Sasaki         [T1_0195]�I�����o�^���̋��_�R�[�h�ϊ������ύX
 *  2009/04/27    1.7   H.Sasaki         [T1_0553]�N�����̐ݒ�l�ύX
 *  2009/05/11    1.8   T.Nakamura       [T1_0839]���_�Ԉړ��I�[�_�[���󕥃f�[�^�쐬�Ώۂɒǉ�
 *  2009/05/14    1.9   H.Sasaki         [T1_0840][T1_0842]�q�֐��ʂ̏W�v�����ύX
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A03C'; -- �p�b�P�[�W��
  -- �I���敪�i1:����  2:�����j
  cv_inv_kbn_1          CONSTANT VARCHAR2(1)  :=  '1';
  cv_inv_kbn_2          CONSTANT VARCHAR2(1)  :=  '2';
  -- �I���X�e�[�^�X�i1:�捞��  2:�󕥍쐬�j
  cv_invsts_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_invsts_2           CONSTANT VARCHAR2(1)  :=  '2';
  -- �ۊǏꏊ�敪�i1:�q��  2:�c�Ǝ�  3:�a����  4:���X�j
  cv_subinv_1           CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2           CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3           CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4           CONSTANT VARCHAR2(1)  :=  '4';
  -- �Ǖi�敪�i0:�Ǖi  1:�s�Ǖi�j
  cv_quality_0          CONSTANT VARCHAR2(1)  :=  '0';
  cv_quality_1          CONSTANT VARCHAR2(1)  :=  '1';
  -- �ۊǏꏊ�敪
  cv_inv_type_5         CONSTANT VARCHAR2(1)  :=  '5';
  cv_inv_type_8         CONSTANT VARCHAR2(1)  :=  '8';
  -- �ڋq�敪�i1:���_�j
  cv_cust_cls_1         CONSTANT VARCHAR2(1)  :=  '1';
  -- ���t�^
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  -- ���b�Z�[�W�֘A
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';
  cv_msg_xxcoi1_10144   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10144';
  cv_msg_xxcoi1_10145   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10145';
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';
  cv_msg_xxcoi1_10233   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10233';
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';
  cv_token_10233_1      CONSTANT VARCHAR2(30) :=  'INV_KBN';
  cv_token_10233_2      CONSTANT VARCHAR2(30) :=  'BASE_CODE';
  cv_token_10233_3      CONSTANT VARCHAR2(30) :=  'STARTUP_FLG';
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
  -- �󕥏W�v�L�[�i����^�C�v�j
  cv_trans_type_010     CONSTANT VARCHAR2(3) :=  '10';        -- ����o��
  cv_trans_type_020     CONSTANT VARCHAR2(3) :=  '20';        -- ����o�ɐU��
  cv_trans_type_030     CONSTANT VARCHAR2(3) :=  '30';        -- �ԕi
  cv_trans_type_040     CONSTANT VARCHAR2(3) :=  '40';        -- �ԕi�U��
  cv_trans_type_050     CONSTANT VARCHAR2(3) :=  '50';        -- ���o��
  cv_trans_type_060     CONSTANT VARCHAR2(3) :=  '60';        -- �q��
  cv_trans_type_070     CONSTANT VARCHAR2(3) :=  '70';        -- ���i�U�ցi�����i�j
  cv_trans_type_080     CONSTANT VARCHAR2(3) :=  '80';        -- ���i�U�ցi�V���i�j
  cv_trans_type_090     CONSTANT VARCHAR2(3) :=  '90';        -- ���{�o��
  cv_trans_type_100     CONSTANT VARCHAR2(3) :=  '100';       -- ���{�o�ɐU��
  cv_trans_type_110     CONSTANT VARCHAR2(3) :=  '110';       -- �ڋq���{�o��
  cv_trans_type_120     CONSTANT VARCHAR2(3) :=  '120';       -- �ڋq���{�o�ɐU��
  cv_trans_type_130     CONSTANT VARCHAR2(3) :=  '130';       -- �ڋq���^���{�o��
  cv_trans_type_140     CONSTANT VARCHAR2(3) :=  '140';       -- �ڋq���^���{�o�ɐU��
  cv_trans_type_150     CONSTANT VARCHAR2(3) :=  '150';       -- ����VD��[
  cv_trans_type_160     CONSTANT VARCHAR2(3) :=  '160';       -- ��݌ɕύX
  cv_trans_type_170     CONSTANT VARCHAR2(3) :=  '170';       -- �H��ԕi
  cv_trans_type_180     CONSTANT VARCHAR2(3) :=  '180';       -- �H��ԕi�U��
  cv_trans_type_190     CONSTANT VARCHAR2(3) :=  '190';       -- �H��q��
  cv_trans_type_200     CONSTANT VARCHAR2(3) :=  '200';       -- �H��q�֐U��
  cv_trans_type_210     CONSTANT VARCHAR2(3) :=  '210';       -- �p�p
  cv_trans_type_220     CONSTANT VARCHAR2(3) :=  '220';       -- �p�p�U��
  cv_trans_type_230     CONSTANT VARCHAR2(3) :=  '230';       -- �H�����
  cv_trans_type_240     CONSTANT VARCHAR2(3) :=  '240';       -- �H����ɐU��
  cv_trans_type_250     CONSTANT VARCHAR2(3) :=  '250';       -- �ڋq�L����`��A���Џ��i
  cv_trans_type_260     CONSTANT VARCHAR2(3) :=  '260';       -- �ڋq�L����`��A���Џ��i�U��
  cv_trans_type_270     CONSTANT VARCHAR2(3) :=  '270';       -- �I�����Չv
  cv_trans_type_280     CONSTANT VARCHAR2(3) :=  '280';       -- �I�����Ց�
  cv_trans_type_290     CONSTANT VARCHAR2(3) :=  '290';       -- �ړ��I�[�_�[�ړ�
  -- ���̑�
  cv_exec_1             CONSTANT VARCHAR2(1)  :=  '1';        -- �N���t���O�F�R���J�����g�N��
  cv_exec_2             CONSTANT VARCHAR2(1)  :=  '2';        -- �N���t���O�F������ԋ����m��
  cv_control_base_1     CONSTANT VARCHAR2(1)  :=  '1';        -- ���_����t���O�i1:�Ǘ������_�j
  cv_status_a           CONSTANT VARCHAR2(1)  :=  'A';        -- �ڋq�}�X�^�D�X�e�[�^�X
  cv_yes                CONSTANT VARCHAR2(1)  :=  'Y';
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE';   -- �v���t�@�C�����i�݌ɑg�D�R�[�h�j
  cv_pgsname_a09c       CONSTANT VARCHAR2(30) :=  'XXCOI006A09C';
  cv_on                 CONSTANT VARCHAR2(1)  :=  '1';        -- �����݌Ɏ󕥕\�쐬�ς�
  cv_off                CONSTANT VARCHAR2(1)  :=  '0';        -- �����݌Ɏ󕥕\���쐬
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE acct_num_type IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
  gt_f_account_number   acct_num_type;      -- �����Ώۋ��_
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- ����^�C�v�ʐ���
  TYPE daily_data    IS TABLE OF xxcoi_inv_reception_monthly%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_daily_data         daily_data;         -- �����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_param_inventory_kbn      VARCHAR2(1);        -- �I���敪
  gv_param_base_code          VARCHAR2(4);        -- ���_
  gv_param_exec_flag          VARCHAR2(1);        -- �N���t���O
  -- ���������ݒ�l
  gd_f_process_date           DATE;               -- �Ɩ��������t
  gv_f_organization_code      VARCHAR2(10);       -- �݌ɑg�D�R�[�h
  gn_f_organization_id        NUMBER;             -- �݌ɑg�DID
  gv_f_inv_acct_period        VARCHAR2(6);        -- �݌ɉ�v���ԁi�N�� YYYYMM�j
  gn_f_last_transaction_id    NUMBER;             -- �����ώ��ID
  gd_f_last_cooperation_date  DATE;               -- ������
  gn_f_max_transaction_id     NUMBER;             -- �ő���ID
  -- ���̑��ϐ�
  gt_save_1_inv_seq           xxcoi_inv_control.inventory_seq%TYPE;                 -- �I��SEQ
  gt_save_1_base_code         xxcoi_inv_reception_daily.base_code%TYPE;             -- ���_�R�[�h
  gt_save_1_subinv_code       xxcoi_inv_reception_daily.subinventory_code%TYPE;     -- �ۊǏꏊ
  gt_save_2_inv_seq           xxcoi_inv_control.inventory_seq%TYPE;                 -- �I��SEQ
  gt_save_2_base_code         xxcoi_inv_control.base_code%TYPE;                     -- ���_�R�[�h
  gt_save_2_subinv_code       xxcoi_inv_control.subinventory_code%TYPE;             -- �ۊǏꏊ
  gt_save_3_inv_seq           xxcoi_inv_reception_monthly.inv_seq%TYPE;             -- �I��SEQ
  gt_save_3_inv_seq_sub       xxcoi_inv_reception_monthly.inv_seq%TYPE;             -- �I��SEQ
  gt_save_3_base_code         mtl_secondary_inventories.attribute7%TYPE;            -- ���_�R�[�h
  gt_save_3_inv_code          mtl_material_transactions.subinventory_code%TYPE;     -- �ۊǏꏊ�R�[�h
  gt_save_3_item_id           mtl_material_transactions.inventory_item_id%TYPE;     -- �i��ID
  gt_save_3_inv_type          mtl_secondary_inventories.attribute1%TYPE;            -- �ۊǏꏊ�^�C�v
  gn_data_cnt                 NUMBER;                                               -- �����f�[�^�ێ��p�J�E���^
  gv_create_flag              VARCHAR2(1);                                          -- �����݌Ɏ󕥕\�쐬�t���O
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- A-2.�����݌Ɏ󕥁i�����j���擾(�y�N���p�����[�^�z�I���敪:1)
  CURSOR  invrcp_daily_1_cur(
            iv_base_code        IN  VARCHAR2        -- ���_�R�[�h
          )
  IS
    SELECT
      xird.base_code                      base_code                 -- ���_�R�[�h
     ,xird.organization_id                organization_id           -- �g�DID
     ,xird.subinventory_code              subinventory_code         -- �ۊǏꏊ
     ,xird.subinventory_type              subinventory_type         -- �ۊǏꏊ�敪
     ,xird.inventory_item_id              inventory_item_id         -- �i��ID
     ,MAX(xird.operation_cost)            operation_cost            -- �c�ƌ���
     ,MAX(xird.standard_cost)             standard_cost             -- �W������
     ,SUM(xird.sales_shipped)             sales_shipped             -- ����o��
     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- ����o�ɐU��
     ,SUM(xird.return_goods)              return_goods              -- �ԕi
     ,SUM(xird.return_goods_b)            return_goods_b            -- �ԕi�U��
     ,SUM(xird.warehouse_ship)            warehouse_ship            -- �q�ɂ֕Ԍ�
     ,SUM(xird.truck_ship)                truck_ship                -- �c�ƎԂ֏o��
     ,SUM(xird.others_ship)               others_ship               -- ���o�ɁQ���̑��o��
     ,SUM(xird.warehouse_stock)           warehouse_stock           -- �q�ɂ�����
     ,SUM(xird.truck_stock)               truck_stock               -- �c�ƎԂ�����
     ,SUM(xird.others_stock)              others_stock              -- ���o�ɁQ���̑�����
     ,SUM(xird.change_stock)              change_stock              -- �q�֓���
     ,SUM(xird.change_ship)               change_ship               -- �q�֏o��
     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- ���i�U�ցi�����i�j
     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- ���i�U�ցi�V���i�j
     ,SUM(xird.sample_quantity)           sample_quantity           -- ���{�o��
     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- ���{�o�ɐU��
     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- �ڋq���{�o��
     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- �ڋq���{�o�ɐU��
     ,SUM(xird.customer_support_ss)       customer_support_ss       -- �ڋq���^���{�o��
     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- ����VD��[����
     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- ����VD��[�o��
     ,SUM(xird.inventory_change_in)       inventory_change_in       -- ��݌ɕύX����
     ,SUM(xird.inventory_change_out)      inventory_change_out      -- ��݌ɕύX�o��
     ,SUM(xird.factory_return)            factory_return            -- �H��ԕi
     ,SUM(xird.factory_return_b)          factory_return_b          -- �H��ԕi�U��
     ,SUM(xird.factory_change)            factory_change            -- �H��q��
     ,SUM(xird.factory_change_b)          factory_change_b          -- �H��q�֐U��
     ,SUM(xird.removed_goods)             removed_goods             -- �p�p
     ,SUM(xird.removed_goods_b)           removed_goods_b           -- �p�p�U��
     ,SUM(xird.factory_stock)             factory_stock             -- �H�����
     ,SUM(xird.factory_stock_b)           factory_stock_b           -- �H����ɐU��
     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
     ,SUM(xird.wear_decrease)             wear_decrease             -- �I�����Ց�
     ,SUM(xird.wear_increase)             wear_increase             -- �I�����Ռ�
     ,SUM(xird.selfbase_ship)             selfbase_ship             -- �ۊǏꏊ�ړ��Q�����_�o��
     ,SUM(xird.selfbase_stock)            selfbase_stock            -- �ۊǏꏊ�ړ��Q�����_����
     ,MAX(xic.inventory_seq)              inventory_seq             -- �I��SEQ
-- == 2009/04/27 V1.7 Added START ===============================================================
     ,MAX(xird.practice_date)             practice_date
     ,MAX(xic.inventory_date)             inventory_date
-- == 2009/04/27 V1.7 Added END   ===============================================================
    FROM    xxcoi_inv_reception_daily   xird                        -- �����݌Ɏ󕥕\�i�����j
           ,(SELECT   sub_msi.attribute7            base_code
                     ,sub_xic.subinventory_code     subinventory_code
                     ,MAX(sub_xic.inventory_date)   inventory_date
                     ,MAX(sub_xic.inventory_seq)    inventory_seq
             FROM     xxcoi_inv_control           sub_xic
                     ,mtl_secondary_inventories   sub_msi
             WHERE    sub_xic.inventory_kbn     =   gv_param_inventory_kbn
             AND      sub_xic.inventory_status  =   cv_invsts_1
             AND      sub_xic.subinventory_code =   sub_msi.secondary_inventory_name
             AND      sub_msi.attribute7        =   iv_base_code
             GROUP BY sub_msi.attribute7
                     ,sub_xic.subinventory_code
            )                           xic
    WHERE   xird.base_code          =   xic.base_code
    AND     xird.subinventory_code  =   xic.subinventory_code
    AND     xird.organization_id    =   gn_f_organization_id
    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xird.practice_date     <=   xic.inventory_date
    GROUP BY
            xird.base_code
           ,xird.organization_id
           ,xird.subinventory_code
           ,xird.inventory_item_id
           ,xird.subinventory_type
    ORDER BY
            xird.base_code
           ,xird.subinventory_code;
  --
  -- A-2.�����݌Ɏ󕥁i�����j���擾(�y�N���p�����[�^�z�I���敪:2)
  CURSOR invrcp_daily_2_cur(
            iv_base_code        IN  VARCHAR2        -- ���_�R�[�h
          )
  IS
    SELECT
      xird.base_code                      base_code                 -- ���_�R�[�h
     ,xird.organization_id                organization_id           -- �g�DID
     ,xird.subinventory_code              subinventory_code         -- �ۊǏꏊ
     ,xird.subinventory_type              subinventory_type         -- �ۊǏꏊ�敪
     ,xird.inventory_item_id              inventory_item_id         -- �i��ID
     ,MAX(xird.operation_cost)            operation_cost            -- �c�ƌ���
     ,MAX(xird.standard_cost)             standard_cost             -- �W������
     ,SUM(xird.sales_shipped)             sales_shipped             -- ����o��
     ,SUM(xird.sales_shipped_b)           sales_shipped_b           -- ����o�ɐU��
     ,SUM(xird.return_goods)              return_goods              -- �ԕi
     ,SUM(xird.return_goods_b)            return_goods_b            -- �ԕi�U��
     ,SUM(xird.warehouse_ship)            warehouse_ship            -- �q�ɂ֕Ԍ�
     ,SUM(xird.truck_ship)                truck_ship                -- �c�ƎԂ֏o��
     ,SUM(xird.others_ship)               others_ship               -- ���o�ɁQ���̑��o��
     ,SUM(xird.warehouse_stock)           warehouse_stock           -- �q�ɂ�����
     ,SUM(xird.truck_stock)               truck_stock               -- �c�ƎԂ�����
     ,SUM(xird.others_stock)              others_stock              -- ���o�ɁQ���̑�����
     ,SUM(xird.change_stock)              change_stock              -- �q�֓���
     ,SUM(xird.change_ship)               change_ship               -- �q�֏o��
     ,SUM(xird.goods_transfer_old)        goods_transfer_old        -- ���i�U�ցi�����i�j
     ,SUM(xird.goods_transfer_new)        goods_transfer_new        -- ���i�U�ցi�V���i�j
     ,SUM(xird.sample_quantity)           sample_quantity           -- ���{�o��
     ,SUM(xird.sample_quantity_b)         sample_quantity_b         -- ���{�o�ɐU��
     ,SUM(xird.customer_sample_ship)      customer_sample_ship      -- �ڋq���{�o��
     ,SUM(xird.customer_sample_ship_b)    customer_sample_ship_b    -- �ڋq���{�o�ɐU��
     ,SUM(xird.customer_support_ss)       customer_support_ss       -- �ڋq���^���{�o��
     ,SUM(xird.customer_support_ss_b)     customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
     ,SUM(xird.vd_supplement_stock)       vd_supplement_stock       -- ����VD��[����
     ,SUM(xird.vd_supplement_ship)        vd_supplement_ship        -- ����VD��[�o��
     ,SUM(xird.inventory_change_in)       inventory_change_in       -- ��݌ɕύX����
     ,SUM(xird.inventory_change_out)      inventory_change_out      -- ��݌ɕύX�o��
     ,SUM(xird.factory_return)            factory_return            -- �H��ԕi
     ,SUM(xird.factory_return_b)          factory_return_b          -- �H��ԕi�U��
     ,SUM(xird.factory_change)            factory_change            -- �H��q��
     ,SUM(xird.factory_change_b)          factory_change_b          -- �H��q�֐U��
     ,SUM(xird.removed_goods)             removed_goods             -- �p�p
     ,SUM(xird.removed_goods_b)           removed_goods_b           -- �p�p�U��
     ,SUM(xird.factory_stock)             factory_stock             -- �H�����
     ,SUM(xird.factory_stock_b)           factory_stock_b           -- �H����ɐU��
     ,SUM(xird.ccm_sample_ship)           ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
     ,SUM(xird.ccm_sample_ship_b)         ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
     ,SUM(xird.wear_decrease)             wear_decrease             -- �I�����Ց�
     ,SUM(xird.wear_increase)             wear_increase             -- �I�����Ռ�
     ,SUM(xird.selfbase_ship)             selfbase_ship             -- �ۊǏꏊ�ړ��Q�����_�o��
     ,SUM(xird.selfbase_stock)            selfbase_stock            -- �ۊǏꏊ�ړ��Q�����_����
     ,MAX(xic.inventory_seq)              inventory_seq             -- �I��SEQ
-- == 2009/04/27 V1.7 Added START ===============================================================
     ,MAX(xird.practice_date)             practice_date
     ,MAX(xic.inventory_date)             inventory_date
-- == 2009/04/27 V1.7 Added END   ===============================================================
    FROM    xxcoi_inv_reception_daily   xird                        -- �����݌Ɏ󕥕\�i�����j
           ,(SELECT   sub_msi.attribute7                base_code
                     ,sub_xic.subinventory_code         subinventory_code
                     ,MAX(sub_xic.inventory_seq)        inventory_seq
                     ,MAX(sub_xic.inventory_date)       inventory_date
             FROM     xxcoi_inv_control           sub_xic
                     ,mtl_secondary_inventories   sub_msi
             WHERE    sub_xic.inventory_kbn     =   gv_param_inventory_kbn
             AND      sub_xic.subinventory_code =   sub_msi.secondary_inventory_name
             AND      ((iv_base_code IS NOT NULL AND sub_msi.attribute7 = iv_base_code)
                       OR
                       (iv_base_code IS NULL)
                      )
             GROUP BY  sub_msi.attribute7
                      ,sub_xic.subinventory_code
            )                           xic
    WHERE   xird.base_code          =   xic.base_code(+)
    AND     xird.subinventory_code  =   xic.subinventory_code(+)
    AND     xird.organization_id    =   gn_f_organization_id
    AND     ((iv_base_code IS NOT NULL AND xird.base_code = iv_base_code)
             OR
             (iv_base_code IS NULL)
            )
    AND     xird.practice_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xird.practice_date     <=   LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month))
    GROUP BY
            xird.base_code
           ,xird.organization_id
           ,xird.subinventory_code
           ,xird.inventory_item_id
           ,xird.subinventory_type
    ORDER BY
            xird.base_code
           ,xird.subinventory_code;
    --
  -- A-6.�I�����ʏ�񒊏o(�y�N���p�����[�^�z�I���敪:1)
  CURSOR  inv_result_1_cur(
            iv_base_code          IN  VARCHAR2                -- ���_�R�[�h
          )
  IS
    SELECT  xid.inventory_seq           xir_inv_seq                 -- �I��SEQ
           ,msi.attribute7              base_code                   -- ���_�R�[�h
           ,xid.inventory_date          inventory_date              -- �I����
           ,MAX(xir.warehouse_kbn)      warehouse_kbn               -- �q�ɋ敪
           ,msib.inventory_item_id      inventory_item_id           -- �i��ID
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_0, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           standard_article_qty        -- �Ǖi���i0:�Ǖi�j
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_1, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           sub_standard_article_qty    -- �s�Ǖi���i1:�s�Ǖi�j
           ,xic.subinventory_code       subinventory_code           -- �ۊǏꏊ
    FROM    xxcoi_inv_result              xir                       -- HHT�I�����ʃe�[�u��
           ,xxcoi_inv_control             xic                       -- �I���Ǘ��e�[�u��
           ,mtl_system_items_b            msib                      -- Disc�i�ځi�c�Ƒg�D�j
           ,mtl_secondary_inventories     msi                       -- �ۊǏꏊ�}�X�^
           ,(SELECT  MAX(xir.inventory_seq)      inventory_seq
                    ,MAX(xir.inventory_date)     inventory_date
                    ,xir.base_code               base_code                   -- ���_�R�[�h
                    ,xir.inventory_place         inventory_place             -- �I���ꏊ
             FROM    xxcoi_inv_result              xir                       -- HHT�I�����ʃe�[�u��
                    ,xxcoi_inv_control             xic                       -- �I���Ǘ��e�[�u��
                    ,mtl_secondary_inventories     msi
             WHERE   xir.inventory_seq       =   xic.inventory_seq
             AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND     xir.inventory_date     <=   gd_f_process_date
             AND     xir.inventory_kbn       =   gv_param_inventory_kbn
             AND     xic.inventory_status    =   cv_invsts_1                 -- 1:�捞�ς�
             AND     xic.subinventory_code   =   msi.secondary_inventory_name
             AND     msi.attribute7          =   iv_base_code
             AND     msi.organization_id     =   gn_f_organization_id
             GROUP BY   xir.base_code
                       ,xir.inventory_place
           )                              xid
    WHERE   xid.base_code           =   xir.base_code
    AND     xid.inventory_place     =   xir.inventory_place
    AND     xir.item_code           =   msib.segment1
    AND     msib.organization_id    =   gn_f_organization_id
    AND     xir.inventory_seq       =   xic.inventory_seq
    AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xir.inventory_date     <=   gd_f_process_date
    AND     xir.inventory_kbn       =   gv_param_inventory_kbn
    AND     xic.inventory_status    =   cv_invsts_1                 -- 1:�捞�ς�
    AND     xic.subinventory_code   =   msi.secondary_inventory_name
    AND     msi.organization_id     =   gn_f_organization_id
    AND     msi.attribute7          =   iv_base_code
    GROUP BY  xid.inventory_seq
             ,msi.attribute7
             ,xid.inventory_date
             ,xic.subinventory_code
             ,msib.inventory_item_id
    ORDER BY  base_code
             ,subinventory_code;
  --
  -- A-6.�I�����ʏ�񒊏o(�y�N���p�����[�^�z�I���敪:2)
  CURSOR  inv_result_2_cur(
            iv_base_code          IN  VARCHAR2                -- ���_�R�[�h
          )
  IS
    SELECT  xid.inventory_seq           xir_inv_seq                 -- �I��SEQ
           ,msi.attribute7              base_code                   -- ���_�R�[�h
           ,xid.inventory_date          inventory_date              -- �I����
           ,MAX(xir.warehouse_kbn)      warehouse_kbn               -- �q�ɋ敪
           ,msib.inventory_item_id      inventory_item_id           -- �i��ID
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_0, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           standard_article_qty        -- �Ǖi���i0:�Ǖi�j
           ,SUM(DECODE(xir.quality_goods_kbn, cv_quality_1, xir.case_qty * xir.case_in_qty + xir.quantity
                                                 , 0
                )
            )                           sub_standard_article_qty    -- �s�Ǖi���i1:�s�Ǖi�j
           ,xic.subinventory_code       subinventory_code           -- �ۊǏꏊ
    FROM    xxcoi_inv_result              xir                       -- HHT�I�����ʃe�[�u��
           ,xxcoi_inv_control             xic                       -- �I���Ǘ��e�[�u��
           ,mtl_system_items_b            msib                      -- Disc�i�ځi�c�Ƒg�D�j
           ,mtl_secondary_inventories     msi                       -- �ۊǏꏊ�}�X�^
           ,(SELECT  MAX(xir.inventory_seq)      inventory_seq
                    ,MAX(xir.inventory_date)     inventory_date
                    ,xir.base_code               base_code                   -- ���_�R�[�h
                    ,xir.inventory_place         inventory_place             -- �I���ꏊ
             FROM    xxcoi_inv_result              xir                       -- HHT�I�����ʃe�[�u��
                    ,xxcoi_inv_control             xic                       -- �I���Ǘ��e�[�u��
                    ,mtl_secondary_inventories     msi
             WHERE   xir.inventory_seq       =   xic.inventory_seq
             AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
             AND     xir.inventory_date     <=   gd_f_process_date
             AND     xir.inventory_kbn       =   gv_param_inventory_kbn
             AND     xic.subinventory_code   =   msi.secondary_inventory_name
             AND     msi.organization_id     =   gn_f_organization_id
             AND     ((iv_base_code IS NOT NULL AND msi.attribute7  =  iv_base_code)
                      OR
                      (iv_base_code IS NULL)
                     )
             GROUP BY   xir.base_code
                       ,xir.inventory_place
           )                              xid
    WHERE   xid.base_code           =   xir.base_code
    AND     xid.inventory_place     =   xir.inventory_place
    AND     xir.item_code           =   msib.segment1
    AND     msib.organization_id    =   gn_f_organization_id
    AND     xir.inventory_seq       =   xic.inventory_seq
    AND     xir.inventory_date     >=   TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
    AND     xir.inventory_date     <=   gd_f_process_date
    AND     xir.inventory_kbn       =   gv_param_inventory_kbn
    AND     xic.subinventory_code   =   msi.secondary_inventory_name
    AND     msi.organization_id     =   gn_f_organization_id
    AND     ((iv_base_code IS NOT NULL AND msi.attribute7  =  iv_base_code)
             OR
             (iv_base_code IS NULL)
            )
    GROUP BY  xid.inventory_seq
             ,msi.attribute7
             ,xid.inventory_date
             ,xic.subinventory_code
             ,msib.inventory_item_id
    ORDER BY  base_code
             ,subinventory_code;
  --
  -- A-9.��������f�[�^�擾
  CURSOR  daily_trans_cur(
            iv_base_code          IN  VARCHAR2                -- ���_�R�[�h
          )
  IS
    SELECT  msi1.attribute7               base_code             -- ���_�R�[�h
           ,msi1.attribute1               inventory_type        -- �ۊǏꏊ�敪
           ,msi2.attribute7               sub_base_code         -- ����拒�_�R�[�h
           ,msi2.attribute1               subinventory_type     -- �����ۊǏꏊ�敪
           ,mmt.subinventory_code         subinventory_code     -- �ۊǏꏊ�R�[�h
           ,mtt.attribute3                transaction_type      -- �󕥕\�W�v�L�[
           ,mmt.inventory_item_id         inventory_item_id     -- �i��ID
           ,mmt.transaction_quantity      transaction_qty       -- �������
           ,xirm.inv_seq                  inventory_seq         -- �󕥒I��SEQ
    FROM    mtl_material_transactions     mmt                   -- ���ގ���e�[�u��
           ,mtl_secondary_inventories     msi1                  -- �ۊǏꏊ
           ,mtl_secondary_inventories     msi2                  -- �ۊǏꏊ
           ,xxcoi_inv_reception_monthly   xirm                  -- �����݌Ɏ󕥕\�i�����j
           ,mtl_transaction_types         mtt                   -- ����^�C�v�}�X�^
    WHERE   mmt.organization_id       =   gn_f_organization_id
    AND     mmt.transaction_id        >   gn_f_last_transaction_id
    AND     mmt.transaction_id       <=   gn_f_max_transaction_id
    AND     mmt.subinventory_code     =   msi1.secondary_inventory_name
    AND     mmt.organization_id       =   msi1.organization_id
    AND     ((iv_base_code IS NOT NULL AND msi1.attribute7 = iv_base_code)
             OR
             (iv_base_code IS NULL)
            )
    AND     mmt.transfer_subinventory  =  msi2.secondary_inventory_name(+)
    AND     TO_CHAR(mmt.transaction_date, cv_month)   =   gv_f_inv_acct_period
    AND     msi1.attribute1           <>  cv_inv_type_5
    AND     msi1.attribute1           <>  cv_inv_type_8
    AND     mmt.organization_id        =  xirm.organization_id(+)
    AND     mmt.subinventory_code      =  xirm.subinventory_code(+)
    AND     mmt.inventory_item_id      =  xirm.inventory_item_id(+)
    AND     xirm.practice_month(+)     =  gv_f_inv_acct_period
    AND     ((xirm.inventory_kbn IS NOT NULL AND xirm.inventory_kbn = gv_param_inventory_kbn)
             OR
             (xirm.inventory_kbn IS NULL)
            )
    AND     mmt.transaction_type_id    =  mtt.transaction_type_id
    AND     mtt.attribute3       IS NOT NULL
    ORDER BY  msi1.attribute7
             ,mmt.subinventory_code
             ,msi1.attribute1
             ,mmt.inventory_item_id;
  --
  -- A-12.�O���I�����ʒ��o
  CURSOR  last_month_cur(
            iv_base_code          IN  VARCHAR2                -- ���_�R�[�h
          )
  IS
    SELECT  xirm1.inv_seq                               inventory_seq         -- �I��SEQ�i�����j
           ,xirm1.base_code                             base_code             -- ���_�R�[�h
           ,xirm1.organization_id                       organization_id       -- �g�DID
           ,xirm1.subinventory_type                     subinventory_type     -- �ۊǏꏊ�敪
           ,xirm1.subinventory_code                     subinventory_code     -- �ۊǏꏊ�R�[�h
           ,xirm1.practice_date                         practice_date         -- �N����
           ,xirm1.inventory_item_id                     inventory_item_id     -- �i��ID
           ,xirm2.inv_result + xirm2.inv_result_bad     inv_result            -- �I�����i�O���j
           ,xirm2.inv_seq                               last_month_inv_seq    -- �I��SEQ�i�O���j
    FROM    xxcoi_inv_reception_monthly   xirm1         -- �����݌Ɏ�_����
           ,xxcoi_inv_reception_monthly   xirm2         -- �����݌Ɏ�_�O��
    WHERE   xirm1.base_code           =   xirm2.base_code(+)
    AND     xirm1.subinventory_code   =   xirm2.subinventory_code(+)
    AND     xirm1.inventory_item_id   =   xirm2.inventory_item_id(+)
    AND     ((iv_base_code IS NOT NULL AND xirm1.base_code  = iv_base_code)
             OR
             (iv_base_code IS NULL)
            )
    AND     ((    (xirm2.practice_month IS NOT NULL)
              AND (xirm2.practice_month = TO_CHAR(ADD_MONTHS(TO_DATE(gv_f_inv_acct_period,cv_month), -1), cv_month))
             )
             OR
             (xirm2.practice_month IS NULL)
            )
    AND     xirm1.practice_month      =   gv_f_inv_acct_period
    AND     xirm1.inventory_kbn       =   gv_param_inventory_kbn
    AND     xirm2.inventory_kbn(+)    =   cv_inv_kbn_2
    ORDER BY  xirm1.base_code
             ,xirm1.subinventory_code;
  --
  /**********************************************************************************
   * Procedure Name   : close_process
   * Description      : �I������(A-14)
   ***********************************************************************************/
  PROCEDURE close_process(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_process'; -- �v���O������
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --
    -- ���������擾
    SELECT  COUNT(1)
    INTO    gn_normal_cnt
    FROM    xxcoi_inv_reception_monthly
    WHERE   request_id  = cn_request_id;
    --
    -- �Ώی����ݒ�
    gn_target_cnt :=  gn_normal_cnt + gn_error_cnt;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END close_process;
--
  /**********************************************************************************
   * Procedure Name   : ins_month_balance
   * Description      : ����c���o��(A-13)
   ***********************************************************************************/
  PROCEDURE ins_month_balance(
    ir_month_balance  IN  last_month_cur%ROWTYPE,       -- 1.��������f�[�^
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_month_balance'; -- �v���O������
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    -- �X�V����
    UPDATE  xxcoi_inv_reception_monthly
    SET     inv_wear                =   inv_wear + ir_month_balance.inv_result        -- �I������
           ,month_begin_quantity    =   ir_month_balance.inv_result                   -- ����I����
           ,last_update_date        =   SYSDATE                                       -- �ŏI�X�V��
           ,last_updated_by         =   cn_last_updated_by                            -- �ŏI�X�V��
           ,last_update_login       =   cn_last_update_login                          -- �ŏI�X�V���[�U
           ,request_id              =   cn_request_id                                 -- �v��ID
           ,program_application_id  =   cn_program_application_id                     -- �v���O�����A�v���P�[�V����ID
           ,program_id              =   cn_program_id                                 -- �v���O����ID
           ,program_update_date     =   SYSDATE                                       -- �v���O�����X�V��
    WHERE   inv_seq            =   ir_month_balance.inventory_seq
    AND     inventory_item_id  =   ir_month_balance.inventory_item_id;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_month_balance;
--
  /**********************************************************************************
   * Procedure Name   : ins_daily_invcntl
   * Description      :  �I���Ǘ��o�́i��������f�[�^�j(A-11)
   ***********************************************************************************/
  PROCEDURE ins_daily_invcntl(
    ir_daily_trans    IN  daily_trans_cur%ROWTYPE,      -- 1.��������f�[�^
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_daily_invcntl'; -- �v���O������
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
    lt_base_code    xxcmm_cust_accounts.management_base_code%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �����P���ڂł͂Ȃ��A���A�O���R�[�h�̒I��SEQ��NULL�ŁA
    -- �����݌ɍ쐬�t���OON�A���A�N���t���O�F������ԋ����m��A����
    -- �L�[���ځi���_�A�ۊǏꏊ�j���ύX���ꂽ�A�܂��́A�ŏI�f�[�^�̏ꍇ
    IF ((gt_save_3_base_code  IS NOT NULL)
        AND
        (gt_save_3_inv_seq_sub IS NULL)
        AND
        (gv_create_flag = cv_on)
        AND
        (gv_param_exec_flag = cv_exec_2)
        AND
        (gt_save_3_base_code <> ir_daily_trans.base_code
         OR
         gt_save_3_inv_code  <> ir_daily_trans.subinventory_code
         OR
         daily_trans_cur%NOTFOUND
        )
       )
    THEN
      --
      BEGIN
        -- �I���Ǘ��p���_�R�[�h�擾
        SELECT  xca.management_base_code
        INTO    lt_base_code
        FROM    hz_cust_accounts    hca
               ,xxcmm_cust_accounts xca
        WHERE   hca.cust_account_id       =   xca.customer_id
        AND     hca.account_number        =   gt_save_3_base_code
        AND     hca.customer_class_code   =   '1'           -- ���_
        AND     hca.status                =   'A'           -- �L��
-- == 2009/03/30 V1.6 Added START ===============================================================
        AND     xca.dept_hht_div          =   '1';          -- HHT�敪�i1:�S�ݓX�j
-- == 2009/03/30 V1.6 Added END   ===============================================================
        --
        IF (lt_base_code IS NULL) THEN
          lt_base_code  :=  gt_save_3_base_code;
        END IF;
-- == 2009/03/30 V1.6 Added START ===============================================================
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_base_code  :=  gt_save_3_base_code;
-- == 2009/03/30 V1.6 Added END   ===============================================================
      END;
      --
      INSERT INTO xxcoi_inv_control(
        inventory_seq                         -- 01.�I��SEQ
       ,inventory_kbn                         -- 02.�I���敪
       ,base_code                             -- 03.���_�R�[�h
       ,subinventory_code                     -- 04.�ۊǏꏊ
       ,warehouse_kbn                         -- 05.�q�ɋ敪
       ,inventory_year_month                  -- 06.�N��
       ,inventory_date                        -- 07.�I����
       ,inventory_status                      -- 08.�I���X�e�[�^�X
       ,last_update_date                      -- 09.�ŏI�X�V��
       ,last_updated_by                       -- 10.�ŏI�X�V��
       ,creation_date                         -- 11.�쐬��
       ,created_by                            -- 12.�쐬��
       ,last_update_login                     -- 13.�ŏI�X�V���[�U
       ,request_id                            -- 14.�v��ID
       ,program_application_id                -- 15.�v���O�����A�v���P�[�V����ID
       ,program_id                            -- 16.�v���O����ID
       ,program_update_date                   -- 17.�v���O�����X�V��
      )VALUES(
        gt_save_3_inv_seq                     -- 01
       ,gv_param_inventory_kbn                -- 02
       ,lt_base_code                          -- 03
       ,gt_save_3_inv_code                    -- 04
       ,gt_save_3_inv_type                    -- 05
       ,gv_f_inv_acct_period                  -- 06
       ,gd_f_process_date                     -- 07
       ,cv_invsts_2                           -- 08�i2:�󕥍쐬�j
       ,SYSDATE                               -- 09
       ,cn_last_updated_by                    -- 10
       ,SYSDATE                               -- 11
       ,cn_created_by                         -- 12
       ,cn_last_update_login                  -- 13
       ,cn_request_id                         -- 14
       ,cn_program_application_id             -- 15
       ,cn_program_id                         -- 16
       ,SYSDATE                               -- 17
      );
      --
    END IF;
    --
    IF ((gt_save_3_inv_seq_sub IS NULL)
        AND
        (gv_create_flag = cv_on)
       )
    THEN
      -- �����݌Ɏ󕥍쐬�t���O������
      gv_create_flag  :=  cv_off;
    END IF;
      --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_daily_invcntl;
--
  /**********************************************************************************
   * Procedure Name   : ins_daily_data
   * Description      : �����݌Ɏ󕥏o�́i��������f�[�^�j(A-10)
   ***********************************************************************************/
  PROCEDURE ins_daily_data(
    ir_daily_trans    IN  daily_trans_cur%ROWTYPE,      -- 1.��������f�[�^
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_daily_data'; -- �v���O������
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
    ln_dummy              NUMBER;       -- �_�~�[�ϐ�
    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- �c�ƌ���
    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- �W������
    ln_exec_flag          NUMBER;
    ln_inventory_seq      NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    IF ((gt_save_3_base_code  IS NOT NULL)
        AND
        (gt_save_3_base_code <> ir_daily_trans.base_code
         OR
         gt_save_3_inv_code  <> ir_daily_trans.subinventory_code
         OR
         daily_trans_cur%NOTFOUND
        )
       )
    THEN
      -- �����P���ڂł͂Ȃ��A�L�[���ځi���_�A�ۊǏꏊ�j���ύX���ꂽ�A�܂��́A�ŏI�f�[�^�̏W�v���������Ă���ꍇ
      -- ���s�t���O�P�FINSERT���s�A�I��SEQ�ݒ�
      ln_exec_flag  :=  1;
      --
    ELSIF ((gt_save_3_base_code IS NOT NULL)
           AND
           (gt_save_3_item_id <> ir_daily_trans.inventory_item_id)
          )
    THEN
      -- �L�[���ځi�i��ID�j���ύX���ꂽ�ꍇ
      -- ���s�t���O�Q�F�f�[�^�ێ��A�I��SEQ�ݒ�Ȃ�
      ln_exec_flag  :=  2;
    ELSE
      -- ���s�t���O�O�FINSERT���s�Ȃ��A�����������Ȃ�
      ln_exec_flag  :=  0;
    END IF;
    --
    IF (ln_exec_flag <> 0) THEN
      gn_data_cnt :=  gn_data_cnt + 1;
      --
      -- �����f�[�^�ێ�
      gt_daily_data(gn_data_cnt).inv_seq                 :=  gt_save_3_inv_seq_sub;
      gt_daily_data(gn_data_cnt).base_code               :=  gt_save_3_base_code;
      gt_daily_data(gn_data_cnt).organization_id         :=  gn_f_organization_id;
      gt_daily_data(gn_data_cnt).subinventory_code       :=  gt_save_3_inv_code;
      gt_daily_data(gn_data_cnt).subinventory_type       :=  gt_save_3_inv_type;
      gt_daily_data(gn_data_cnt).practice_month          :=  gv_f_inv_acct_period;
      gt_daily_data(gn_data_cnt).practice_date           :=  gd_f_process_date;
      gt_daily_data(gn_data_cnt).inventory_kbn           :=  gv_param_inventory_kbn;
      gt_daily_data(gn_data_cnt).inventory_item_id       :=  gt_save_3_item_id;
      gt_daily_data(gn_data_cnt).sales_shipped           :=  gt_quantity(1)  * -1;
      gt_daily_data(gn_data_cnt).sales_shipped_b         :=  gt_quantity(2)  *  1;
      gt_daily_data(gn_data_cnt).return_goods            :=  gt_quantity(3)  *  1;
      gt_daily_data(gn_data_cnt).return_goods_b          :=  gt_quantity(4)  * -1;
      gt_daily_data(gn_data_cnt).warehouse_ship          :=  gt_quantity(5)  * -1;
      gt_daily_data(gn_data_cnt).truck_ship              :=  gt_quantity(6)  * -1;
      gt_daily_data(gn_data_cnt).others_ship             :=  gt_quantity(7)  * -1;
      gt_daily_data(gn_data_cnt).warehouse_stock         :=  gt_quantity(8)  *  1;
      gt_daily_data(gn_data_cnt).truck_stock             :=  gt_quantity(9)  *  1;
      gt_daily_data(gn_data_cnt).others_stock            :=  gt_quantity(10) *  1;
      gt_daily_data(gn_data_cnt).change_stock            :=  gt_quantity(11) *  1;
      gt_daily_data(gn_data_cnt).change_ship             :=  gt_quantity(12) * -1;
      gt_daily_data(gn_data_cnt).goods_transfer_old      :=  gt_quantity(13) * -1;
      gt_daily_data(gn_data_cnt).goods_transfer_new      :=  gt_quantity(14) *  1;
      gt_daily_data(gn_data_cnt).sample_quantity         :=  gt_quantity(15) * -1;
      gt_daily_data(gn_data_cnt).sample_quantity_b       :=  gt_quantity(16) *  1;
      gt_daily_data(gn_data_cnt).customer_sample_ship    :=  gt_quantity(17) * -1;
      gt_daily_data(gn_data_cnt).customer_sample_ship_b  :=  gt_quantity(18) *  1;
      gt_daily_data(gn_data_cnt).customer_support_ss     :=  gt_quantity(19) * -1;
      gt_daily_data(gn_data_cnt).customer_support_ss_b   :=  gt_quantity(20) *  1;
      gt_daily_data(gn_data_cnt).vd_supplement_stock     :=  gt_quantity(21) *  1;
      gt_daily_data(gn_data_cnt).vd_supplement_ship      :=  gt_quantity(22) * -1;
      gt_daily_data(gn_data_cnt).inventory_change_in     :=  gt_quantity(23) *  1;
      gt_daily_data(gn_data_cnt).inventory_change_out    :=  gt_quantity(24) * -1;
      gt_daily_data(gn_data_cnt).factory_return          :=  gt_quantity(25) * -1;
      gt_daily_data(gn_data_cnt).factory_return_b        :=  gt_quantity(26) *  1;
      gt_daily_data(gn_data_cnt).factory_change          :=  gt_quantity(27) * -1;
      gt_daily_data(gn_data_cnt).factory_change_b        :=  gt_quantity(28) *  1;
      gt_daily_data(gn_data_cnt).removed_goods           :=  gt_quantity(29) * -1;
      gt_daily_data(gn_data_cnt).removed_goods_b         :=  gt_quantity(30) *  1;
      gt_daily_data(gn_data_cnt).factory_stock           :=  gt_quantity(31) *  1;
      gt_daily_data(gn_data_cnt).factory_stock_b         :=  gt_quantity(32) * -1;
      gt_daily_data(gn_data_cnt).ccm_sample_ship         :=  gt_quantity(33) * -1;
      gt_daily_data(gn_data_cnt).ccm_sample_ship_b       :=  gt_quantity(34) *  1;
      gt_daily_data(gn_data_cnt).wear_decrease           :=  gt_quantity(35) *  1;
      gt_daily_data(gn_data_cnt).wear_increase           :=  gt_quantity(36) * -1;
      gt_daily_data(gn_data_cnt).selfbase_ship           :=  gt_quantity(37) * -1;
      gt_daily_data(gn_data_cnt).selfbase_stock          :=  gt_quantity(38) *  1;
      gt_daily_data(gn_data_cnt).inv_result              :=  0;
      gt_daily_data(gn_data_cnt).inv_result_bad          :=  0;
      gt_daily_data(gn_data_cnt).inv_wear                :=   gt_quantity(1)  + gt_quantity(2)  + gt_quantity(3)  + gt_quantity(4)
                                                            + gt_quantity(5)  + gt_quantity(6)  + gt_quantity(7)  + gt_quantity(8)
                                                            + gt_quantity(9)  + gt_quantity(10) + gt_quantity(11) + gt_quantity(12)
                                                            + gt_quantity(13) + gt_quantity(14) + gt_quantity(15) + gt_quantity(16)
                                                            + gt_quantity(17) + gt_quantity(18) + gt_quantity(19) + gt_quantity(20)
                                                            + gt_quantity(21) + gt_quantity(22) + gt_quantity(23) + gt_quantity(24)
                                                            + gt_quantity(25) + gt_quantity(26) + gt_quantity(27) + gt_quantity(28)
                                                            + gt_quantity(29) + gt_quantity(30) + gt_quantity(31) + gt_quantity(32)
                                                            + gt_quantity(33) + gt_quantity(34) + gt_quantity(35) + gt_quantity(36)
                                                            + gt_quantity(37) + gt_quantity(38);
      gt_daily_data(gn_data_cnt).month_begin_quantity    :=  0;
      --
      IF (ln_exec_flag = 1) THEN
        -- ���s�t���O�P�̏ꍇ
        --
        -- ===================================
        --  1.�I��SEQ�擾
        -- ===================================
        <<set_seq_loop>>
        FOR ln_seq_cnt  IN  1 .. gn_data_cnt  LOOP
          IF (gt_daily_data(ln_seq_cnt).inv_seq IS NOT NULL) THEN
            -- ���_�A�ۊǏꏊ�P�ʂŁA��ł��I��SEQ���ݒ肳��Ă���ꍇ
            gt_save_3_inv_seq     :=  gt_daily_data(ln_seq_cnt).inv_seq;
            gt_save_3_inv_seq_sub :=  gt_daily_data(ln_seq_cnt).inv_seq;
            --
            EXIT set_seq_loop;
          ELSIF (ln_seq_cnt = gn_data_cnt) THEN
            -- �S�Ă̒I��SEQ��NULL�̏ꍇ�A�V�K�̔�
            --
            SELECT  xxcoi_inv_control_s01.NEXTVAL
            INTO    gt_save_3_inv_seq
            FROM    dual;
            --
            gt_save_3_inv_seq_sub :=  NULL;
          END IF;
        END LOOP set_seq_loop;
        --
        --
        <<daily_set_loop>>
        FOR ln_loop_cnt IN  1 .. gn_data_cnt  LOOP
          IF (    (gt_daily_data(ln_loop_cnt).sales_shipped           = 0)
              AND (gt_daily_data(ln_loop_cnt).sales_shipped_b         = 0)
              AND (gt_daily_data(ln_loop_cnt).return_goods            = 0)
              AND (gt_daily_data(ln_loop_cnt).return_goods_b          = 0)
              AND (gt_daily_data(ln_loop_cnt).warehouse_ship          = 0)
              AND (gt_daily_data(ln_loop_cnt).truck_ship              = 0)
              AND (gt_daily_data(ln_loop_cnt).others_ship             = 0)
              AND (gt_daily_data(ln_loop_cnt).warehouse_stock         = 0)
              AND (gt_daily_data(ln_loop_cnt).truck_stock             = 0)
              AND (gt_daily_data(ln_loop_cnt).others_stock            = 0)
              AND (gt_daily_data(ln_loop_cnt).change_stock            = 0)
              AND (gt_daily_data(ln_loop_cnt).change_ship             = 0)
              AND (gt_daily_data(ln_loop_cnt).goods_transfer_old      = 0)
              AND (gt_daily_data(ln_loop_cnt).goods_transfer_new      = 0)
              AND (gt_daily_data(ln_loop_cnt).sample_quantity         = 0)
              AND (gt_daily_data(ln_loop_cnt).sample_quantity_b       = 0)
              AND (gt_daily_data(ln_loop_cnt).customer_sample_ship    = 0)
              AND (gt_daily_data(ln_loop_cnt).customer_sample_ship_b  = 0)
              AND (gt_daily_data(ln_loop_cnt).customer_support_ss     = 0)
              AND (gt_daily_data(ln_loop_cnt).customer_support_ss_b   = 0)
              AND (gt_daily_data(ln_loop_cnt).vd_supplement_stock     = 0)
              AND (gt_daily_data(ln_loop_cnt).vd_supplement_ship      = 0)
              AND (gt_daily_data(ln_loop_cnt).inventory_change_in     = 0)
              AND (gt_daily_data(ln_loop_cnt).inventory_change_out    = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_return          = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_return_b        = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_change          = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_change_b        = 0)
              AND (gt_daily_data(ln_loop_cnt).removed_goods           = 0)
              AND (gt_daily_data(ln_loop_cnt).removed_goods_b         = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_stock           = 0)
              AND (gt_daily_data(ln_loop_cnt).factory_stock_b         = 0)
              AND (gt_daily_data(ln_loop_cnt).ccm_sample_ship         = 0)
              AND (gt_daily_data(ln_loop_cnt).ccm_sample_ship_b       = 0)
              AND (gt_daily_data(ln_loop_cnt).wear_decrease           = 0)
              AND (gt_daily_data(ln_loop_cnt).wear_increase           = 0)
              AND (gt_daily_data(ln_loop_cnt).selfbase_ship           = 0)
              AND (gt_daily_data(ln_loop_cnt).selfbase_stock          = 0)
             )
          THEN
            -- ����o�ɂ���A�ۊǏꏊ�ړ��Q�����_���ɂ܂őS���ڂO�̏ꍇ�A�f�[�^�쐬���s��Ȃ�
            NULL;
            --
          ELSIF (gt_daily_data(ln_loop_cnt).inv_seq IS NULL) THEN
            -- ���_�A�ۊǏꏊ�A�i�ڒP�ʂŁA�����݌Ɏ󕥃f�[�^�����݂��Ȃ��ꍇ�A���A
            -- ������ԋ����m�莞�̂ݎ��s
            --
            -- ===================================
            --  2.�W�������擾
            -- ===================================
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  gt_daily_data(ln_loop_cnt).inventory_item_id  -- �i��ID
             ,in_org_id       =>  gn_f_organization_id                          -- �g�DID
             ,id_period_date  =>  gd_f_process_date                             -- �Ώۓ�
             ,ov_cmpnt_cost   =>  lt_standard_cost                              -- �W������
             ,ov_errbuf       =>  lv_errbuf                                     -- �G���[���b�Z�[�W
             ,ov_retcode      =>  lv_retcode                                    -- ���^�[���E�R�[�h
             ,ov_errmsg       =>  lv_errmsg                                     -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- �I���p�����[�^����
            IF (lv_retcode = cv_status_error) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- ===================================
            --  3.�c�ƌ����擾
            -- ===================================
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  gt_daily_data(ln_loop_cnt).inventory_item_id  -- �i��ID
             ,in_org_id         =>  gn_f_organization_id                          -- �g�DID
             ,id_target_date    =>  gd_f_process_date                             -- �Ώۓ�
             ,ov_discrete_cost  =>  lt_operation_cost                             -- �c�ƌ���
             ,ov_errbuf         =>  lv_errbuf                                     -- �G���[���b�Z�[�W
             ,ov_retcode        =>  lv_retcode                                    -- ���^�[���E�R�[�h
             ,ov_errmsg         =>  lv_errmsg                                     -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- �I���p�����[�^����
            IF (lv_retcode = cv_status_error) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_api_expt;
            END IF;
            --
            -- ===================================
            --  4.�����݌Ɏ󕥃e�[�u���o��
            -- ===================================
            INSERT INTO xxcoi_inv_reception_monthly(
              inv_seq                                   -- 01.�I��SEQ
             ,base_code                                 -- 02.���_�R�[�h
             ,organization_id                           -- 03.�g�DID
             ,subinventory_code                         -- 04.�ۊǏꏊ
             ,subinventory_type                         -- 05.�ۊǏꏊ�敪
             ,practice_month                            -- 06.�N��
             ,practice_date                             -- 07.�N����
             ,inventory_kbn                             -- 08.�I���敪
             ,inventory_item_id                         -- 09.�i��ID
             ,operation_cost                            -- 10.�c�ƌ���
             ,standard_cost                             -- 11.�W������
             ,sales_shipped                             -- 12.����o��
             ,sales_shipped_b                           -- 13.����o�ɐU��
             ,return_goods                              -- 14.�ԕi
             ,return_goods_b                            -- 15.�ԕi�U��
             ,warehouse_ship                            -- 16.�q�ɂ֕Ԍ�
             ,truck_ship                                -- 17.�c�ƎԂ֏o��
             ,others_ship                               -- 18.���o�ɁQ���̑��o��
             ,warehouse_stock                           -- 19.�q�ɂ�����
             ,truck_stock                               -- 20.�c�ƎԂ�����
             ,others_stock                              -- 21.���o�ɁQ���̑�����
             ,change_stock                              -- 22.�q�֓���
             ,change_ship                               -- 23.�q�֏o��
             ,goods_transfer_old                        -- 24.���i�U�ցi�����i�j
             ,goods_transfer_new                        -- 25.���i�U�ցi�V���i�j
             ,sample_quantity                           -- 26.���{�o��
             ,sample_quantity_b                         -- 27.���{�o�ɐU��
             ,customer_sample_ship                      -- 28.�ڋq���{�o��
             ,customer_sample_ship_b                    -- 29.�ڋq���{�o�ɐU��
             ,customer_support_ss                       -- 30.�ڋq���^���{�o��
             ,customer_support_ss_b                     -- 31.�ڋq���^���{�o�ɐU��
             ,vd_supplement_stock                       -- 32.����VD��[����
             ,vd_supplement_ship                        -- 33.����VD��[�o��
             ,inventory_change_in                       -- 34.��݌ɕύX����
             ,inventory_change_out                      -- 35.��݌ɕύX�o��
             ,factory_return                            -- 36.�H��ԕi
             ,factory_return_b                          -- 37.�H��ԕi�U��
             ,factory_change                            -- 38.�H��q��
             ,factory_change_b                          -- 39.�H��q�֐U��
             ,removed_goods                             -- 40.�p�p
             ,removed_goods_b                           -- 41.�p�p�U��
             ,factory_stock                             -- 42.�H�����
             ,factory_stock_b                           -- 43.�H����ɐU��
             ,ccm_sample_ship                           -- 44.�ڋq�L����`��A���Џ��i
             ,ccm_sample_ship_b                         -- 45.�ڋq�L����`��A���Џ��i�U��
             ,wear_decrease                             -- 46.�I�����Ց�
             ,wear_increase                             -- 47.�I�����Ռ�
             ,selfbase_ship                             -- 48.�ۊǏꏊ�ړ��Q�����_�o��
             ,selfbase_stock                            -- 49.�ۊǏꏊ�ړ��Q�����_����
             ,inv_result                                -- 50.�I������
             ,inv_result_bad                            -- 51.�I�����ʁi�s�Ǖi�j
             ,inv_wear                                  -- 52.�I������
             ,month_begin_quantity                      -- 53.����I����
             ,last_update_date                          -- 54.�ŏI�X�V��
             ,last_updated_by                           -- 55.�ŏI�X�V��
             ,creation_date                             -- 56.�쐬��
             ,created_by                                -- 57.�쐬��
             ,last_update_login                         -- 58.�ŏI�X�V���[�U
             ,request_id                                -- 59.�v��ID
             ,program_application_id                    -- 60.�v���O�����A�v���P�[�V����ID
             ,program_id                                -- 61.�v���O����ID
             ,program_update_date                       -- 62.�v���O�����X�V��
            )VALUES(
              gt_save_3_inv_seq                                   -- 01
             ,gt_daily_data(ln_loop_cnt).base_code                -- 02
             ,gt_daily_data(ln_loop_cnt).organization_id          -- 03
             ,gt_daily_data(ln_loop_cnt).subinventory_code        -- 04
             ,gt_daily_data(ln_loop_cnt).subinventory_type        -- 05
             ,gt_daily_data(ln_loop_cnt).practice_month           -- 06
             ,gt_daily_data(ln_loop_cnt).practice_date            -- 07
             ,gt_daily_data(ln_loop_cnt).inventory_kbn            -- 08
             ,gt_daily_data(ln_loop_cnt).inventory_item_id        -- 09
             ,TO_NUMBER(lt_operation_cost)                        -- 10
             ,TO_NUMBER(lt_standard_cost)                         -- 11
             ,gt_daily_data(ln_loop_cnt).sales_shipped            -- 12
             ,gt_daily_data(ln_loop_cnt).sales_shipped_b          -- 13
             ,gt_daily_data(ln_loop_cnt).return_goods             -- 14
             ,gt_daily_data(ln_loop_cnt).return_goods_b           -- 15
             ,gt_daily_data(ln_loop_cnt).warehouse_ship           -- 16
             ,gt_daily_data(ln_loop_cnt).truck_ship               -- 17
             ,gt_daily_data(ln_loop_cnt).others_ship              -- 18
             ,gt_daily_data(ln_loop_cnt).warehouse_stock          -- 19
             ,gt_daily_data(ln_loop_cnt).truck_stock              -- 20
             ,gt_daily_data(ln_loop_cnt).others_stock             -- 21
             ,gt_daily_data(ln_loop_cnt).change_stock             -- 22
             ,gt_daily_data(ln_loop_cnt).change_ship              -- 23
             ,gt_daily_data(ln_loop_cnt).goods_transfer_old       -- 24
             ,gt_daily_data(ln_loop_cnt).goods_transfer_new       -- 25
             ,gt_daily_data(ln_loop_cnt).sample_quantity          -- 26
             ,gt_daily_data(ln_loop_cnt).sample_quantity_b        -- 27
             ,gt_daily_data(ln_loop_cnt).customer_sample_ship     -- 28
             ,gt_daily_data(ln_loop_cnt).customer_sample_ship_b   -- 29
             ,gt_daily_data(ln_loop_cnt).customer_support_ss      -- 30
             ,gt_daily_data(ln_loop_cnt).customer_support_ss_b    -- 31
             ,gt_daily_data(ln_loop_cnt).vd_supplement_stock      -- 32
             ,gt_daily_data(ln_loop_cnt).vd_supplement_ship       -- 33
             ,gt_daily_data(ln_loop_cnt).inventory_change_in      -- 34
             ,gt_daily_data(ln_loop_cnt).inventory_change_out     -- 35
             ,gt_daily_data(ln_loop_cnt).factory_return           -- 36
             ,gt_daily_data(ln_loop_cnt).factory_return_b         -- 37
             ,gt_daily_data(ln_loop_cnt).factory_change           -- 38
             ,gt_daily_data(ln_loop_cnt).factory_change_b         -- 39
             ,gt_daily_data(ln_loop_cnt).removed_goods            -- 40
             ,gt_daily_data(ln_loop_cnt).removed_goods_b          -- 41
             ,gt_daily_data(ln_loop_cnt).factory_stock            -- 42
             ,gt_daily_data(ln_loop_cnt).factory_stock_b          -- 43
             ,gt_daily_data(ln_loop_cnt).ccm_sample_ship          -- 44
             ,gt_daily_data(ln_loop_cnt).ccm_sample_ship_b        -- 45
             ,gt_daily_data(ln_loop_cnt).wear_decrease            -- 46
             ,gt_daily_data(ln_loop_cnt).wear_increase            -- 47
             ,gt_daily_data(ln_loop_cnt).selfbase_ship            -- 48
             ,gt_daily_data(ln_loop_cnt).selfbase_stock           -- 49
             ,gt_daily_data(ln_loop_cnt).inv_result               -- 50
             ,gt_daily_data(ln_loop_cnt).inv_result_bad           -- 51
             ,gt_daily_data(ln_loop_cnt).inv_wear                 -- 52
             ,gt_daily_data(ln_loop_cnt).month_begin_quantity     -- 53
             ,SYSDATE                                             -- 54
             ,cn_last_updated_by                                  -- 55
             ,SYSDATE                                             -- 56
             ,cn_created_by                                       -- 57
             ,cn_last_update_login                                -- 58
             ,cn_request_id                                       -- 59
             ,cn_program_application_id                           -- 60
             ,cn_program_id                                       -- 61
             ,SYSDATE                                             -- 62
            );
            --
            -- �����݌Ɏ󕥍쐬�t���OON
            gv_create_flag  :=  cv_on;
            --
          ELSE
            -- ���_�A�ۊǏꏊ�A�i�ڒP�ʂŁA�����݌Ɏ󕥃f�[�^�����݂���ꍇ
            -- �X�V����
            UPDATE  xxcoi_inv_reception_monthly
            SET     sales_shipped
                       =   sales_shipped          + gt_daily_data(ln_loop_cnt).sales_shipped            -- ����o��
                   ,sales_shipped_b
                       =   sales_shipped_b        + gt_daily_data(ln_loop_cnt).sales_shipped_b          -- ����o�ɐU��
                   ,return_goods
                       =   return_goods           + gt_daily_data(ln_loop_cnt).return_goods             -- �ԕi
                   ,return_goods_b
                       =   return_goods_b         + gt_daily_data(ln_loop_cnt).return_goods_b           -- �ԕi�U��
                   ,warehouse_ship
                       =   warehouse_ship         + gt_daily_data(ln_loop_cnt).warehouse_ship           -- �q�ɂ֕Ԍ�
                   ,truck_ship
                       =   truck_ship             + gt_daily_data(ln_loop_cnt).truck_ship               -- �c�ƎԂ֏o��
                   ,others_ship
                       =   others_ship            + gt_daily_data(ln_loop_cnt).others_ship              -- ���o�ɁQ���̑��o��
                   ,warehouse_stock
                       =   warehouse_stock        + gt_daily_data(ln_loop_cnt).warehouse_stock          -- �q�ɂ�����
                   ,truck_stock
                       =   truck_stock            + gt_daily_data(ln_loop_cnt).truck_stock              -- �c�ƎԂ�����
                   ,others_stock
                       =   others_stock           + gt_daily_data(ln_loop_cnt).others_stock             -- ���o�ɁQ���̑�����
                   ,change_stock
                       =   change_stock           + gt_daily_data(ln_loop_cnt).change_stock             -- �q�֓���
                   ,change_ship
                       =   change_ship            + gt_daily_data(ln_loop_cnt).change_ship              -- �q�֏o��
                   ,goods_transfer_old
                       =   goods_transfer_old     + gt_daily_data(ln_loop_cnt).goods_transfer_old       -- ���i�U�ցi�����i�j
                   ,goods_transfer_new
                       =   goods_transfer_new     + gt_daily_data(ln_loop_cnt).goods_transfer_new       -- ���i�U�ցi�V���i�j
                   ,sample_quantity
                       =   sample_quantity        + gt_daily_data(ln_loop_cnt).sample_quantity          -- ���{�o��
                   ,sample_quantity_b
                       =   sample_quantity_b      + gt_daily_data(ln_loop_cnt).sample_quantity_b        -- ���{�o�ɐU��
                   ,customer_sample_ship
                       =   customer_sample_ship   + gt_daily_data(ln_loop_cnt).customer_sample_ship     -- �ڋq���{�o��
                   ,customer_sample_ship_b
                       =   customer_sample_ship_b + gt_daily_data(ln_loop_cnt).customer_sample_ship_b   -- �ڋq���{�o�ɐU��
                   ,customer_support_ss
                       =   customer_support_ss    + gt_daily_data(ln_loop_cnt).customer_support_ss      -- �ڋq���^���{�o��
                   ,customer_support_ss_b
                       =   customer_support_ss_b  + gt_daily_data(ln_loop_cnt).customer_support_ss_b    -- �ڋq���^���{�o�ɐU��
                   ,vd_supplement_stock
                       =   vd_supplement_stock    + gt_daily_data(ln_loop_cnt).vd_supplement_stock      -- ����VD��[����
                   ,vd_supplement_ship
                       =   vd_supplement_ship     + gt_daily_data(ln_loop_cnt).vd_supplement_ship       -- ����VD��[�o��
                   ,inventory_change_in
                       =   inventory_change_in    + gt_daily_data(ln_loop_cnt).inventory_change_in      -- ��݌ɕύX����
                   ,inventory_change_out
                       =   inventory_change_out   + gt_daily_data(ln_loop_cnt).inventory_change_out     -- ��݌ɕύX�o��
                   ,factory_return
                       =   factory_return         + gt_daily_data(ln_loop_cnt).factory_return           -- �H��ԕi
                   ,factory_return_b
                       =   factory_return_b       + gt_daily_data(ln_loop_cnt).factory_return_b         -- �H��ԕi�U��
                   ,factory_change
                       =   factory_change         + gt_daily_data(ln_loop_cnt).factory_change           -- �H��q��
                   ,factory_change_b
                       =   factory_change_b       + gt_daily_data(ln_loop_cnt).factory_change_b         -- �H��q�֐U��
                   ,removed_goods
                       =   removed_goods          + gt_daily_data(ln_loop_cnt).removed_goods            -- �p�p
                   ,removed_goods_b
                       =   removed_goods_b        + gt_daily_data(ln_loop_cnt).removed_goods_b          -- �p�p�U��
                   ,factory_stock
                       =   factory_stock          + gt_daily_data(ln_loop_cnt).factory_stock            -- �H�����
                   ,factory_stock_b
                       =   factory_stock_b        + gt_daily_data(ln_loop_cnt).factory_stock_b          -- �H����ɐU��
                   ,ccm_sample_ship
                       =   ccm_sample_ship        + gt_daily_data(ln_loop_cnt).ccm_sample_ship          -- �ڋq�L����`��A���Џ��i
                   ,ccm_sample_ship_b
                       =   ccm_sample_ship_b      + gt_daily_data(ln_loop_cnt).ccm_sample_ship_b        -- �ڋq�L����`��A���Џ��i�U��
                   ,wear_decrease
                       =   wear_decrease          + gt_daily_data(ln_loop_cnt).wear_decrease            -- �I�����Ց�
                   ,wear_increase
                       =   wear_increase          + gt_daily_data(ln_loop_cnt).wear_increase            -- �I�����Ռ�
                   ,selfbase_ship
                       =   selfbase_ship          + gt_daily_data(ln_loop_cnt).selfbase_ship            -- �ۊǏꏊ�ړ��Q�����_�o��
                   ,selfbase_stock
                       =   selfbase_stock         + gt_daily_data(ln_loop_cnt).selfbase_stock           -- �ۊǏꏊ�ړ��Q�����_����
                   ,inv_wear
                       =   inv_wear               + gt_daily_data(ln_loop_cnt).inv_wear                 -- �I������
                   ,last_update_date
                       =   SYSDATE                                                                      -- �ŏI�X�V��
                   ,last_updated_by
                       =   cn_last_updated_by                                                           -- �ŏI�X�V��
                   ,last_update_login
                       =   cn_last_update_login                                                         -- �ŏI�X�V���[�U
                   ,request_id
                       =   cn_request_id                                                                -- �v��ID
                   ,program_application_id
                       =   cn_program_application_id                                                    -- �v���O�����A�v���P�[�V����ID
                   ,program_id
                       =   cn_program_id                                                                -- �v���O����ID
                   ,program_update_date
                       =   SYSDATE                                                                      -- �v���O�����X�V��
            WHERE   inv_seq            =   gt_save_3_inv_seq
            AND     inventory_item_id  =   gt_daily_data(ln_loop_cnt).inventory_item_id;
            --
          END IF;
        END LOOP daily_set_loop;
        --
        -- ���[�v�J�E���^�A���ގ���f�[�^������
        gn_data_cnt   :=  0;
        gt_daily_data.DELETE;
      END IF;
      --
      -- �e���ʂ�������
      FOR i IN  1 .. 38 LOOP
        gt_quantity(i)  :=  0;
      END LOOP;
    END IF;
    --
    IF NOT(daily_trans_cur%NOTFOUND) THEN
      -- �󕥏W�v�i����^�C�v�ʁj
      CASE  ir_daily_trans.transaction_type
        WHEN  cv_trans_type_010  THEN   -- 01.����o��
          gt_quantity(1)   :=  gt_quantity(1) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_020  THEN   -- 02.����o�ɐU��
          gt_quantity(2)   :=  gt_quantity(2) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_030  THEN   -- 03.�ԕi
          gt_quantity(3)   :=  gt_quantity(3) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_040  THEN   -- 04.�ԕi�U��
          gt_quantity(4)   :=  gt_quantity(4) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_050  THEN
          IF (    (ir_daily_trans.transaction_qty    < 0)
              AND (ir_daily_trans.inventory_type     = cv_subinv_2)
              AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 07.���o�ɁQ���̑��o��
            gt_quantity(7)   :=  gt_quantity(7) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     = cv_subinv_2)
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 10.���o�ɁQ���̑�����
            gt_quantity(10)  :=  gt_quantity(10) + ir_daily_trans.transaction_qty;
          END IF;
        WHEN  cv_trans_type_060  THEN
-- == 2009/05/14 V1.9 Modified START ===============================================================
--          IF (ir_daily_trans.transaction_qty >= 0) THEN
--            -- 11.�q�֓���
--            gt_quantity(11)  :=  gt_quantity(11) + ir_daily_trans.transaction_qty;
--          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
--            -- 12.�q�֏o��
--            gt_quantity(12)  :=  gt_quantity(12) + ir_daily_trans.transaction_qty;
--          END IF;
--
          IF (    (ir_daily_trans.transaction_qty    < 0)
              AND (ir_daily_trans.inventory_type     = cv_subinv_2)
              AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
             )
          THEN
            -- 05.�q�ɂ֕Ԍ�
            gt_quantity(5)   :=  gt_quantity(5) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 06.�c�ƎԂ֏o��
            gt_quantity(6)   :=  gt_quantity(6) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    < 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 12.�q�֏o��
            gt_quantity(12)  :=  gt_quantity(12) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     = cv_subinv_2)
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 08.�q�ɂ�����
            gt_quantity(8)   :=  gt_quantity(8) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  = cv_subinv_2)
                )
          THEN
            -- 09.�c�ƎԂ�����
            gt_quantity(9)   :=  gt_quantity(9) + ir_daily_trans.transaction_qty;
          ELSIF (    (ir_daily_trans.transaction_qty    > 0)
                 AND (ir_daily_trans.inventory_type     IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                 AND (ir_daily_trans.subinventory_type  IN(cv_subinv_1, cv_subinv_3, cv_subinv_4))
                )
          THEN
            -- 11.�q�֓���
            gt_quantity(11)  :=  gt_quantity(11) + ir_daily_trans.transaction_qty;
          END IF;
-- == 2009/05/14 V1.9 Modified END   ===============================================================
        WHEN  cv_trans_type_070  THEN   -- 13.���i�U�ցi�����i�j
          gt_quantity(13)  :=  gt_quantity(13) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_080  THEN   -- 14.���i�U�ցi�V���i�j
          gt_quantity(14)  :=  gt_quantity(14) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_090  THEN   -- 15.���{�o��
          gt_quantity(15)  :=  gt_quantity(15) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_100 THEN   -- 16.���{�o�ɐU��
          gt_quantity(16)  :=  gt_quantity(16) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_110 THEN   -- 17.�ڋq���{�o��
          gt_quantity(17)  :=  gt_quantity(17) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_120 THEN   -- 18.�ڋq���{�o�ɐU��
          gt_quantity(18)  :=  gt_quantity(18) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_130 THEN   -- 19.�ڋq���^���{�o��
          gt_quantity(19)  :=  gt_quantity(19) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_140 THEN   -- 20.�ڋq���^���{�o�ɐU��
          gt_quantity(20)  :=  gt_quantity(20) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_150 THEN
          IF (ir_daily_trans.transaction_qty >= 0) THEN
            -- 21.����VD��[����
            gt_quantity(21)  :=  gt_quantity(21) + ir_daily_trans.transaction_qty;
          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
            -- 22.����VD��[�o��
            gt_quantity(22)  :=  gt_quantity(22) + ir_daily_trans.transaction_qty;
          END IF;
        WHEN  cv_trans_type_160 THEN
          IF (ir_daily_trans.transaction_qty   >= 0) THEN
            -- 23.��݌ɕύX����
            gt_quantity(23)  :=  gt_quantity(23) + ir_daily_trans.transaction_qty;
          ELSIF (ir_daily_trans.transaction_qty < 0) THEN
            -- 24.��݌ɕύX�o��
            gt_quantity(24)  :=  gt_quantity(24) + ir_daily_trans.transaction_qty;
          END IF;
        WHEN  cv_trans_type_170 THEN   -- 25.�H��ԕi
          gt_quantity(25)  :=  gt_quantity(25) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_180 THEN   -- 26.�H��ԕi�U��
          gt_quantity(26)  :=  gt_quantity(26) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_190 THEN   -- 27.�H��q��
          gt_quantity(27)  :=  gt_quantity(27) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_200 THEN   -- 28.�H��q�֐U��
          gt_quantity(28)  :=  gt_quantity(28) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_210 THEN   -- 29.�p�p
          gt_quantity(29)  :=  gt_quantity(29) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_220 THEN   -- 30.�p�p�U��
          gt_quantity(30)  :=  gt_quantity(30) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_230 THEN   -- 31.�H�����
          gt_quantity(31)  :=  gt_quantity(31) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_240 THEN   -- 32.�H����ɐU��
          gt_quantity(32)  :=  gt_quantity(32) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_250 THEN   -- 33.�ڋq�L����`��A���Џ��i
          gt_quantity(33)  :=  gt_quantity(33) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_260 THEN   -- 34.�ڋq�L����`��A���Џ��i�U��
          gt_quantity(34)  :=  gt_quantity(34) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_270 THEN   -- 35.�I�����Ց�
          gt_quantity(35)  :=  gt_quantity(35) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_280 THEN   -- 36.�I�����Ռ�
          gt_quantity(36)  :=  gt_quantity(36) + ir_daily_trans.transaction_qty;
        WHEN  cv_trans_type_290 THEN
-- == 2009/05/11 V1.8 Deleted START ===============================================================
--          IF (ir_daily_trans.base_code = ir_daily_trans.sub_base_code) THEN
-- == 2009/05/11 V1.8 Deleted END   ===============================================================
            IF (ir_daily_trans.transaction_qty < 0) THEN
              -- 37.�ۊǏꏊ�ړ��Q�����_�o��
              gt_quantity(37)  :=  gt_quantity(37) + ir_daily_trans.transaction_qty;
            ELSIF (ir_daily_trans.transaction_qty >= 0) THEN
              -- 38.�ۊǏꏊ�ړ��Q�����_����
              gt_quantity(38)  :=  gt_quantity(38) + ir_daily_trans.transaction_qty;
            END IF;
-- == 2009/05/11 V1.8 Deleted START ===============================================================
--          END IF;
-- == 2009/05/11 V1.8 Deleted END   ===============================================================
        ELSE  NULL;
      END CASE;
    END IF;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_control
   * Description      : �I���Ǘ��o�́i�I�����ʃf�[�^�j(A-8)
   ***********************************************************************************/
  PROCEDURE upd_inv_control(
    ir_inv_result     IN  inv_result_1_cur%ROWTYPE,     -- 1.�I�����ʏ��
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_control'; -- �v���O������
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
    ln_dummy      NUMBER;             -- �_�~�[�ϐ�
    ld_end_date   DATE;               -- �I�����͈̔́i�I�[�j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  xic_lock_cur
    IS
      SELECT  1
      INTO    ln_dummy
      FROM    xxcoi_inv_control   xic     -- �I���Ǘ��e�[�u��
      WHERE   subinventory_code       =   ir_inv_result.subinventory_code
      AND     inventory_status        =   cv_invsts_1
      AND     inventory_kbn           =   gv_param_inventory_kbn
      AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                              AND     ld_end_date
      FOR UPDATE NOWAIT;
    --
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �����P���ځA�܂��́A�����ꂩ�̃L�[���ڂ��ύX���ꂽ�ꍇ�ȉ������s
    IF ((gt_save_2_base_code IS NULL)
        OR
        (gt_save_2_base_code <> ir_inv_result.base_code)
        OR
        (gt_save_2_subinv_code <> ir_inv_result.subinventory_code)
       )
    THEN
      BEGIN
        -- �I�����͈̔́i�I�[�j��ݒ�
        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
          -- �����̏ꍇ�A�擾�����ő�I�����܂�
          ld_end_date :=  ir_inv_result.inventory_date;
        ELSE
          -- �����̏ꍇ�A
          ld_end_date :=  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month));
        END IF;
        --
        -- ���b�N����
        OPEN  xic_lock_cur;
        CLOSE xic_lock_cur;
        --
        -- �X�V����
        UPDATE  xxcoi_inv_control
        SET     inventory_status        =   cv_invsts_2                 -- �I���X�e�[�^�X
               ,last_update_date        =   SYSDATE                     -- �ŏI�X�V��
               ,last_updated_by         =   cn_last_updated_by          -- �ŏI�X�V��
               ,last_update_login       =   cn_last_update_login        -- �ŏI�X�V���[�U
               ,request_id              =   cn_request_id               -- �v��ID
               ,program_application_id  =   cn_program_application_id   -- �v���O�����A�v���P�[�V����ID
               ,program_id              =   cn_program_id               -- �v���O����ID
               ,program_update_date     =   SYSDATE                     -- �v���O�����X�V��
        WHERE   subinventory_code       =   ir_inv_result.subinventory_code
        AND     inventory_status        =   cv_invsts_1
        AND     inventory_kbn           =   gv_param_inventory_kbn
        AND     inventory_date  BETWEEN TRUNC(TO_DATE(gv_f_inv_acct_period, cv_month))
                                AND     ld_end_date;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �X�V�Ώۂ��Ȃ��ꍇ�́A�㑱���������s
          NULL;
          --
        WHEN lock_error_expt THEN     -- ���b�N�擾���s��
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10144
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_result
   * Description      : �����݌Ɏ󕥏o�́i�I�����ʃf�[�^�j(A-7)
   ***********************************************************************************/
  PROCEDURE ins_inv_result(
    ir_inv_result     IN  inv_result_1_cur%ROWTYPE,     -- 1.�I�����ʏ��
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_result'; -- �v���O������
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
    ln_dummy              NUMBER;       -- �_�~�[�ϐ�
    lt_operation_cost     cm_cmpt_dtl.cmpnt_cost%TYPE;      -- �c�ƌ���
    lt_standard_cost      cst_item_costs.item_cost%TYPE;    -- �W������
    ln_inventory_seq      NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    BEGIN
      -- �����݌Ɏ󕥕\�f�[�^���݃`�F�b�N
      SELECT  1
      INTO    ln_dummy
      FROM    xxcoi_inv_reception_monthly   xirm
      WHERE   xirm.inv_seq            =   ir_inv_result.xir_inv_seq
      AND     xirm.inventory_item_id  =   ir_inv_result.inventory_item_id
      AND     ROWNUM  = 1;
      --
      -- �����݌Ɏ󕥕\�ɑΏۃf�[�^�����݂����ꍇ�A�X�V���������s
      UPDATE  xxcoi_inv_reception_monthly
      SET     inv_result              =   ir_inv_result.standard_article_qty        -- �I������
             ,inv_result_bad          =   ir_inv_result.sub_standard_article_qty    -- �I�����ʁi�s�Ǖi�j
             ,inv_wear                =   inv_wear
                                        + (ir_inv_result.standard_article_qty + ir_inv_result.sub_standard_article_qty) * -1
                                                                                    -- �I������
             ,last_update_date        =   SYSDATE                                   -- �ŏI�X�V��
             ,last_updated_by         =   cn_last_updated_by                        -- �ŏI�X�V��
             ,last_update_login       =   cn_last_update_login                      -- �ŏI�X�V���[�U
             ,request_id              =   cn_request_id                             -- �v��ID
             ,program_application_id  =   cn_program_application_id                 -- �v���O�����A�v���P�[�V����ID
             ,program_id              =   cn_program_id                             -- �v���O����ID
             ,program_update_date     =   SYSDATE                                   -- �v���O�����X�V��
      WHERE   inv_seq               =   ir_inv_result.xir_inv_seq
      AND     inventory_item_id     =   ir_inv_result.inventory_item_id;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �����݌Ɏ󕥕\�ɑΏۃf�[�^�����݂��Ȃ��ꍇ�A�쐬���������s
        -- ===================================
        --  2.�W�������擾
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  ir_inv_result.inventory_item_id     -- �i��ID
         ,in_org_id       =>  gn_f_organization_id                -- �g�DID
         ,id_period_date  =>  ir_inv_result.inventory_date        -- �Ώۓ�
         ,ov_cmpnt_cost   =>  lt_standard_cost                    -- �W������
         ,ov_errbuf       =>  lv_errbuf                           -- �G���[���b�Z�[�W
         ,ov_retcode      =>  lv_retcode                          -- ���^�[���E�R�[�h
         ,ov_errmsg       =>  lv_errmsg                           -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  2.�c�ƌ����擾
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  ir_inv_result.inventory_item_id     -- �i��ID
         ,in_org_id         =>  gn_f_organization_id                -- �g�DID
         ,id_target_date    =>  ir_inv_result.inventory_date        -- �Ώۓ�
         ,ov_discrete_cost  =>  lt_operation_cost                   -- �c�ƌ���
         ,ov_errbuf         =>  lv_errbuf                           -- �G���[���b�Z�[�W
         ,ov_retcode        =>  lv_retcode                          -- ���^�[���E�R�[�h
         ,ov_errmsg         =>  lv_errmsg                           -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        --
        -- ===================================
        --  3.�����݌Ɏ󕥃e�[�u���o��
        -- ===================================
        INSERT INTO xxcoi_inv_reception_monthly(
          inv_seq                                   -- 01.�I��SEQ
         ,base_code                                 -- 02.���_�R�[�h
         ,organization_id                           -- 03.�g�Did
         ,subinventory_code                         -- 04.�ۊǏꏊ
         ,subinventory_type                         -- 05.�ۊǏꏊ�敪
         ,practice_month                            -- 06.�N��
         ,practice_date                             -- 07.�N����
         ,inventory_kbn                             -- 08.�I���敪
         ,inventory_item_id                         -- 09.�i��ID
         ,operation_cost                            -- 10.�c�ƌ���
         ,standard_cost                             -- 11.�W������
         ,sales_shipped                             -- 12.����o��
         ,sales_shipped_b                           -- 13.����o�ɐU��
         ,return_goods                              -- 14.�ԕi
         ,return_goods_b                            -- 15.�ԕi�U��
         ,warehouse_ship                            -- 16.�q�ɂ֕Ԍ�
         ,truck_ship                                -- 17.�c�ƎԂ֏o��
         ,others_ship                               -- 18.���o�ɁQ���̑��o��
         ,warehouse_stock                           -- 19.�q�ɂ�����
         ,truck_stock                               -- 20.�c�ƎԂ�����
         ,others_stock                              -- 21.���o�ɁQ���̑�����
         ,change_stock                              -- 22.�q�֓���
         ,change_ship                               -- 23.�q�֏o��
         ,goods_transfer_old                        -- 24.���i�U�ցi�����i�j
         ,goods_transfer_new                        -- 25.���i�U�ցi�V���i�j
         ,sample_quantity                           -- 26.���{�o��
         ,sample_quantity_b                         -- 27.���{�o�ɐU��
         ,customer_sample_ship                      -- 28.�ڋq���{�o��
         ,customer_sample_ship_b                    -- 29.�ڋq���{�o�ɐU��
         ,customer_support_ss                       -- 30.�ڋq���^���{�o��
         ,customer_support_ss_b                     -- 31.�ڋq���^���{�o�ɐU��
         ,ccm_sample_ship                           -- 32.�ڋq�L����`��a���Џ��i
         ,ccm_sample_ship_b                         -- 33.�ڋq�L����`��a���Џ��i�U��
         ,vd_supplement_stock                       -- 34.����vd��[����
         ,vd_supplement_ship                        -- 35.����vd��[�o��
         ,inventory_change_in                       -- 36.��݌ɕύX����
         ,inventory_change_out                      -- 37.��݌ɕύX�o��
         ,factory_return                            -- 38.�H��ԕi
         ,factory_return_b                          -- 39.�H��ԕi�U��
         ,factory_change                            -- 40.�H��q��
         ,factory_change_b                          -- 41.�H��q�֐U��
         ,removed_goods                             -- 42.�p�p
         ,removed_goods_b                           -- 43.�p�p�U��
         ,factory_stock                             -- 44.�H�����
         ,factory_stock_b                           -- 45.�H����ɐU��
         ,wear_decrease                             -- 46.�I�����Ց�
         ,wear_increase                             -- 47.�I�����Ռ�
         ,selfbase_ship                             -- 48.�ۊǏꏊ�ړ��Q�����_�o��
         ,selfbase_stock                            -- 49.�ۊǏꏊ�ړ��Q�����_����
         ,inv_result                                -- 50.�I������
         ,inv_result_bad                            -- 51.�I�����ʁi�s�Ǖi�j
         ,inv_wear                                  -- 52.�I������
         ,month_begin_quantity                      -- 53.����I����
         ,last_update_date                          -- 54.�ŏI�X�V��
         ,last_updated_by                           -- 55.�ŏI�X�V��
         ,creation_date                             -- 56.�쐬��
         ,created_by                                -- 57.�쐬��
         ,last_update_login                         -- 58.�ŏI�X�V���[�U
         ,request_id                                -- 59.�v��ID
         ,program_application_id                    -- 60.�v���O�����A�v���P�[�V����ID
         ,program_id                                -- 61.�v���O����ID
         ,program_update_date                       -- 62.�v���O�����X�V��
        )VALUES(
          ir_inv_result.xir_inv_seq                 -- 01
         ,ir_inv_result.base_code                   -- 02
         ,gn_f_organization_id                      -- 03
         ,ir_inv_result.subinventory_code           -- 04
         ,ir_inv_result.warehouse_kbn               -- 05
         ,gv_f_inv_acct_period                      -- 06
         ,ir_inv_result.inventory_date              -- 07
         ,gv_param_inventory_kbn                    -- 08
         ,ir_inv_result.inventory_item_id           -- 09
         ,TO_NUMBER(lt_operation_cost)              -- 10
         ,TO_NUMBER(lt_standard_cost)               -- 11
         ,0                                         -- 12
         ,0                                         -- 13
         ,0                                         -- 14
         ,0                                         -- 15
         ,0                                         -- 16
         ,0                                         -- 17
         ,0                                         -- 18
         ,0                                         -- 19
         ,0                                         -- 20
         ,0                                         -- 21
         ,0                                         -- 22
         ,0                                         -- 23
         ,0                                         -- 24
         ,0                                         -- 25
         ,0                                         -- 26
         ,0                                         -- 27
         ,0                                         -- 28
         ,0                                         -- 29
         ,0                                         -- 30
         ,0                                         -- 31
         ,0                                         -- 32
         ,0                                         -- 33
         ,0                                         -- 34
         ,0                                         -- 35
         ,0                                         -- 36
         ,0                                         -- 37
         ,0                                         -- 38
         ,0                                         -- 39
         ,0                                         -- 40
         ,0                                         -- 41
         ,0                                         -- 42
         ,0                                         -- 43
         ,0                                         -- 44
         ,0                                         -- 45
         ,0                                         -- 46
         ,0                                         -- 47
         ,0                                         -- 48
         ,0                                         -- 49
         ,ir_inv_result.standard_article_qty        -- 50
         ,ir_inv_result.sub_standard_article_qty    -- 51
         ,(ir_inv_result.standard_article_qty + ir_inv_result.sub_standard_article_qty) * -1
                                                    -- 52
         ,0                                         -- 53
         ,SYSDATE                                   -- 54
         ,cn_last_updated_by                        -- 55
         ,SYSDATE                                   -- 56
         ,cn_created_by                             -- 57
         ,cn_last_update_login                      -- 58
         ,cn_request_id                             -- 59
         ,cn_program_application_id                 -- 60
         ,cn_program_id                             -- 61
         ,SYSDATE                                   -- 62
        );
        --
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_inv_result;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_control
   * Description      :  �I���Ǘ��o�́i�����f�[�^�j(A-5)
   ***********************************************************************************/
  PROCEDURE ins_inv_control(
    ir_invrcp_daily   IN  invrcp_daily_1_cur%ROWTYPE,   -- 1.�����݌Ɏ󕥁i�����j���
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_control'; -- �v���O������
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
    ln_dummy      NUMBER(1);          -- �_�~�[�ϐ�
    lt_base_code  xxcmm_cust_accounts.management_base_code%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �����P���ځA�܂��́A�����ꂩ�̃L�[���ځi���_�A�ۊǏꏊ�j���ύX���ꂽ�ꍇ�ȉ������s
    IF  ((gt_save_1_base_code IS NULL)
         OR
         (gt_save_1_base_code   <> ir_invrcp_daily.base_code)
         OR
         (gt_save_1_subinv_code <> ir_invrcp_daily.subinventory_code)
        )
    THEN
      IF (    (ir_invrcp_daily.inventory_seq IS NULL)
          AND (gv_param_exec_flag = cv_exec_2)
         )
      THEN
        -- �I��SEQ��NULL�A���A�N���t���O�F������ԋ����m��̏ꍇ
        BEGIN
          -- �I���Ǘ��p���_�R�[�h�擾
          SELECT  xca.management_base_code
          INTO    lt_base_code
          FROM    hz_cust_accounts    hca
                 ,xxcmm_cust_accounts xca
          WHERE   hca.cust_account_id       =   xca.customer_id
          AND     hca.account_number        =   ir_invrcp_daily.base_code
          AND     hca.customer_class_code   =   '1'           -- ���_
          AND     hca.status                =   'A'           -- �L��
-- == 2009/03/30 V1.6 Added START ===============================================================
          AND     xca.dept_hht_div          =   '1';          -- HHT�敪�i1:�S�ݓX�j
-- == 2009/03/30 V1.6 Added END   ===============================================================
          --
          IF (lt_base_code IS NULL) THEN
            lt_base_code  :=  ir_invrcp_daily.base_code;
          END IF;
-- == 2009/03/30 V1.6 Added START ===============================================================
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_base_code  :=  ir_invrcp_daily.base_code;
-- == 2009/03/30 V1.6 Added END   ===============================================================
        END;
        --
        -- �I��SEQ��NULL�̏ꍇ
        INSERT INTO xxcoi_inv_control(
          inventory_seq                         -- 01.�I��SEQ
         ,inventory_kbn                         -- 02.�I���敪
         ,base_code                             -- 03.���_�R�[�h
         ,subinventory_code                     -- 04.�ۊǏꏊ
         ,warehouse_kbn                         -- 05.�q�ɋ敪
         ,inventory_year_month                  -- 06.�N��
         ,inventory_date                        -- 07.�I����
         ,inventory_status                      -- 08.�I���X�e�[�^�X
         ,last_update_date                      -- 09.�ŏI�X�V��
         ,last_updated_by                       -- 10.�ŏI�X�V��
         ,creation_date                         -- 11.�쐬��
         ,created_by                            -- 12.�쐬��
         ,last_update_login                     -- 13.�ŏI�X�V���[�U
         ,request_id                            -- 14.�v��ID
         ,program_application_id                -- 15.�v���O�����A�v���P�[�V����ID
         ,program_id                            -- 16.�v���O����ID
         ,program_update_date                   -- 17.�v���O�����X�V��
        )VALUES(
          gt_save_1_inv_seq                     -- 01
         ,gv_param_inventory_kbn                -- 02
         ,lt_base_code                          -- 03
         ,ir_invrcp_daily.subinventory_code     -- 04
         ,ir_invrcp_daily.subinventory_type     -- 05
         ,gv_f_inv_acct_period                  -- 06
         ,gd_f_process_date                     -- 07
         ,cv_invsts_2                           -- 08
         ,SYSDATE                               -- 09
         ,cn_last_updated_by                    -- 10
         ,SYSDATE                               -- 11
         ,cn_created_by                         -- 12
         ,cn_last_update_login                  -- 13
         ,cn_request_id                         -- 14
         ,cn_program_application_id             -- 15
         ,cn_program_id                         -- 16
         ,SYSDATE                               -- 17
        );
      END IF;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_invrcp_daily
   * Description      : �����݌Ɏ󕥏o�́i�����f�[�^�j(A-4)
   ***********************************************************************************/
  PROCEDURE ins_invrcp_daily(
    ir_invrcp_daily   IN  invrcp_daily_1_cur%ROWTYPE,   -- 1.�����݌Ɏ󕥁i�����j���
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_invrcp_daily'; -- �v���O������
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
    lt_inventory_seq        xxcoi_inv_control.inventory_seq%TYPE;     -- �I��SEQ
    ln_inv_wear             NUMBER;                                   -- �I������
-- == 2009/04/27 V1.7 Added START ===============================================================
    ld_practice_date        DATE;                                     -- �N����
-- == 2009/04/27 V1.7 Added END   ===============================================================
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�I��SEQ�̔�
    -- ===================================
    IF (ir_invrcp_daily.inventory_seq IS NOT NULL) THEN
      -- �I��SEQ���擾���ꂽ�ꍇ
      lt_inventory_seq  :=  ir_invrcp_daily.inventory_seq;
-- == 2009/04/27 V1.7 Added START ===============================================================
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- �R���J�����g�N����
        ld_practice_date  :=  ir_invrcp_daily.inventory_date;
      ELSE
        ld_practice_date  :=  gd_f_process_date;
      END IF;
-- == 2009/04/27 V1.7 Added END   ===============================================================
      --
    ELSIF ((gt_save_1_base_code IS NULL)
           OR
           (gt_save_1_base_code   <> ir_invrcp_daily.base_code)
           OR
           (gt_save_1_subinv_code <> ir_invrcp_daily.subinventory_code)
          )
    THEN
      -- �����P���ځA�܂��́A�����ꂩ�̃L�[���ځi���_�A�ۊǏꏊ�j���ύX���ꂽ�ꍇ
      SELECT  xxcoi_inv_control_s01.NEXTVAL
      INTO    lt_inventory_seq
      FROM    dual;
-- == 2009/04/27 V1.7 Added START ===============================================================
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- �R���J�����g�N����
        ld_practice_date  :=  ir_invrcp_daily.practice_date;
      ELSE
        ld_practice_date  :=  gd_f_process_date;
      END IF;
-- == 2009/04/27 V1.7 Added END   ===============================================================
    ELSE
      -- ��L�ȊO�̏ꍇ
      lt_inventory_seq  :=  gt_save_1_inv_seq;
-- == 2009/04/27 V1.7 Added START ===============================================================
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- �R���J�����g�N����
        ld_practice_date  :=  ir_invrcp_daily.practice_date;
      ELSE
        ld_practice_date  :=  gd_f_process_date;
      END IF;
-- == 2009/04/27 V1.7 Added END   ===============================================================
    END IF;
    --
    -- ===================================
    --  2.�����݌Ɏ󕥃e�[�u���o��
    -- ===================================
    -- �I�����Ղ��Z�o
    ln_inv_wear   :=    ir_invrcp_daily.sales_shipped           * -1    -- ����o��
                      + ir_invrcp_daily.sales_shipped_b         *  1    -- ����o�ɐU��
                      + ir_invrcp_daily.return_goods            *  1    -- �ԕi
                      + ir_invrcp_daily.return_goods_b          * -1    -- �ԕi�U��
                      + ir_invrcp_daily.warehouse_ship          * -1    -- �q�ɂ֕Ԍ�
                      + ir_invrcp_daily.truck_ship              * -1    -- �c�ƎԂ֏o��
                      + ir_invrcp_daily.others_ship             * -1    -- ���o�ɁQ���̑��o��
                      + ir_invrcp_daily.warehouse_stock         *  1    -- �q�ɂ�����
                      + ir_invrcp_daily.truck_stock             *  1    -- �c�ƎԂ�����
                      + ir_invrcp_daily.others_stock            *  1    -- ���o�ɁQ���̑�����
                      + ir_invrcp_daily.change_stock            *  1    -- �q�֓���
                      + ir_invrcp_daily.change_ship             * -1    -- �q�֏o��
                      + ir_invrcp_daily.goods_transfer_old      * -1    -- ���i�U�ցi�����i�j
                      + ir_invrcp_daily.goods_transfer_new      *  1    -- ���i�U�ցi�V���i�j
                      + ir_invrcp_daily.sample_quantity         * -1    -- ���{�o��
                      + ir_invrcp_daily.sample_quantity_b       *  1    -- ���{�o�ɐU��
                      + ir_invrcp_daily.customer_sample_ship    * -1    -- �ڋq���{�o��
                      + ir_invrcp_daily.customer_sample_ship_b  *  1    -- �ڋq���{�o�ɐU��
                      + ir_invrcp_daily.customer_support_ss     * -1    -- �ڋq���^���{�o��
                      + ir_invrcp_daily.customer_support_ss_b   *  1    -- �ڋq���^���{�o�ɐU��
                      + ir_invrcp_daily.vd_supplement_stock     *  1    -- ����VD��[����
                      + ir_invrcp_daily.vd_supplement_ship      * -1    -- ����VD��[�o��
                      + ir_invrcp_daily.inventory_change_in     *  1    -- ��݌ɕύX����
                      + ir_invrcp_daily.inventory_change_out    * -1    -- ��݌ɕύX�o��
                      + ir_invrcp_daily.factory_return          * -1    -- �H��ԕi
                      + ir_invrcp_daily.factory_return_b        *  1    -- �H��ԕi�U��
                      + ir_invrcp_daily.factory_change          * -1    -- �H��q��
                      + ir_invrcp_daily.factory_change_b        *  1    -- �H��q�֐U��
                      + ir_invrcp_daily.removed_goods           * -1    -- �p�p
                      + ir_invrcp_daily.removed_goods_b         *  1    -- �p�p�U��
                      + ir_invrcp_daily.factory_stock           *  1    -- �H�����
                      + ir_invrcp_daily.factory_stock_b         * -1    -- �H����ɐU��
                      + ir_invrcp_daily.ccm_sample_ship         * -1    -- �ڋq�L����`��A���Џ��i
                      + ir_invrcp_daily.ccm_sample_ship_b       *  1    -- �ڋq�L����`��A���Џ��i�U��
                      + ir_invrcp_daily.wear_decrease           *  1    -- �I�����Ց�
                      + ir_invrcp_daily.wear_increase           * -1    -- �I�����Ռ�
                      + ir_invrcp_daily.selfbase_ship           * -1    -- �ۊǏꏊ�ړ��Q�����_�o��
                      + ir_invrcp_daily.selfbase_stock          *  1;   -- �ۊǏꏊ�ړ��Q�����_����
    --
    -- �����݌Ɏ󕥕\�i�����jINSERT
    INSERT INTO xxcoi_inv_reception_monthly(
      inv_seq                                   -- 01.�I��SEQ
     ,base_code                                 -- 02.���_�R�[�h
     ,organization_id                           -- 03.�g�Did
     ,subinventory_code                         -- 04.�ۊǏꏊ
     ,subinventory_type                         -- 05.�ۊǏꏊ�敪
     ,practice_month                            -- 06.�N��
     ,practice_date                             -- 07.�N����
     ,inventory_kbn                             -- 08.�I���敪
     ,inventory_item_id                         -- 09.�i��ID
     ,operation_cost                            -- 10.�c�ƌ���
     ,standard_cost                             -- 11.�W������
     ,sales_shipped                             -- 12.����o��
     ,sales_shipped_b                           -- 13.����o�ɐU��
     ,return_goods                              -- 14.�ԕi
     ,return_goods_b                            -- 15.�ԕi�U��
     ,warehouse_ship                            -- 16.�q�ɂ֕Ԍ�
     ,truck_ship                                -- 17.�c�ƎԂ֏o��
     ,others_ship                               -- 18.���o�ɁQ���̑��o��
     ,warehouse_stock                           -- 19.�q�ɂ�����
     ,truck_stock                               -- 20.�c�ƎԂ�����
     ,others_stock                              -- 21.���o�ɁQ���̑�����
     ,change_stock                              -- 22.�q�֓���
     ,change_ship                               -- 23.�q�֏o��
     ,goods_transfer_old                        -- 24.���i�U�ցi�����i�j
     ,goods_transfer_new                        -- 25.���i�U�ցi�V���i�j
     ,sample_quantity                           -- 26.���{�o��
     ,sample_quantity_b                         -- 27.���{�o�ɐU��
     ,customer_sample_ship                      -- 28.�ڋq���{�o��
     ,customer_sample_ship_b                    -- 29.�ڋq���{�o�ɐU��
     ,customer_support_ss                       -- 30.�ڋq���^���{�o��
     ,customer_support_ss_b                     -- 31.�ڋq���^���{�o�ɐU��
     ,ccm_sample_ship                           -- 32.�ڋq�L����`��a���Џ��i
     ,ccm_sample_ship_b                         -- 33.�ڋq�L����`��a���Џ��i�U��
     ,vd_supplement_stock                       -- 34.����vd��[����
     ,vd_supplement_ship                        -- 35.����vd��[�o��
     ,inventory_change_in                       -- 36.��݌ɕύX����
     ,inventory_change_out                      -- 37.��݌ɕύX�o��
     ,factory_return                            -- 38.�H��ԕi
     ,factory_return_b                          -- 39.�H��ԕi�U��
     ,factory_change                            -- 40.�H��q��
     ,factory_change_b                          -- 41.�H��q�֐U��
     ,removed_goods                             -- 42.�p�p
     ,removed_goods_b                           -- 43.�p�p�U��
     ,factory_stock                             -- 44.�H�����
     ,factory_stock_b                           -- 45.�H����ɐU��
     ,wear_decrease                             -- 46.�I�����Ց�
     ,wear_increase                             -- 47.�I�����Ռ�
     ,selfbase_ship                             -- 48.�ۊǏꏊ�ړ��Q�����_�o��
     ,selfbase_stock                            -- 49.�ۊǏꏊ�ړ��Q�����_����
     ,inv_result                                -- 50.�I������
     ,inv_result_bad                            -- 51.�I�����ʁi�s�Ǖi�j
     ,inv_wear                                  -- 52.�I������
     ,month_begin_quantity                      -- 53.����I����
     ,last_update_date                          -- 54.�ŏI�X�V��
     ,last_updated_by                           -- 55.�ŏI�X�V��
     ,creation_date                             -- 56.�쐬��
     ,created_by                                -- 57.�쐬��
     ,last_update_login                         -- 58.�ŏI�X�V���[�U
     ,request_id                                -- 59.�v��ID
     ,program_application_id                    -- 60.�v���O�����A�v���P�[�V����ID
     ,program_id                                -- 61.�v���O����ID
     ,program_update_date                       -- 62.�v���O�����X�V��
    )VALUES(
      lt_inventory_seq                          -- 01
     ,ir_invrcp_daily.base_code                 -- 02
     ,ir_invrcp_daily.organization_id           -- 03
     ,ir_invrcp_daily.subinventory_code         -- 04
     ,ir_invrcp_daily.subinventory_type         -- 05
     ,gv_f_inv_acct_period                      -- 06
-- == 2009/04/27 V1.7 Modified START ===============================================================
--    ,gd_f_process_date                          -- 07
     ,ld_practice_date                          -- 07
-- == 2009/04/27 V1.7 Modified END   ===============================================================
     ,gv_param_inventory_kbn                    -- 08
     ,ir_invrcp_daily.inventory_item_id         -- 09
     ,ir_invrcp_daily.operation_cost            -- 10
     ,ir_invrcp_daily.standard_cost             -- 11
     ,ir_invrcp_daily.sales_shipped             -- 12
     ,ir_invrcp_daily.sales_shipped_b           -- 13
     ,ir_invrcp_daily.return_goods              -- 14
     ,ir_invrcp_daily.return_goods_b            -- 15
     ,ir_invrcp_daily.warehouse_ship            -- 16
     ,ir_invrcp_daily.truck_ship                -- 17
     ,ir_invrcp_daily.others_ship               -- 18
     ,ir_invrcp_daily.warehouse_stock           -- 19
     ,ir_invrcp_daily.truck_stock               -- 20
     ,ir_invrcp_daily.others_stock              -- 21
     ,ir_invrcp_daily.change_stock              -- 22
     ,ir_invrcp_daily.change_ship               -- 23
     ,ir_invrcp_daily.goods_transfer_old        -- 24
     ,ir_invrcp_daily.goods_transfer_new        -- 25
     ,ir_invrcp_daily.sample_quantity           -- 26
     ,ir_invrcp_daily.sample_quantity_b         -- 27
     ,ir_invrcp_daily.customer_sample_ship      -- 28
     ,ir_invrcp_daily.customer_sample_ship_b    -- 29
     ,ir_invrcp_daily.customer_support_ss       -- 30
     ,ir_invrcp_daily.customer_support_ss_b     -- 31
     ,ir_invrcp_daily.ccm_sample_ship           -- 32
     ,ir_invrcp_daily.ccm_sample_ship_b         -- 33
     ,ir_invrcp_daily.vd_supplement_stock       -- 34
     ,ir_invrcp_daily.vd_supplement_ship        -- 35
     ,ir_invrcp_daily.inventory_change_in       -- 36
     ,ir_invrcp_daily.inventory_change_out      -- 37
     ,ir_invrcp_daily.factory_return            -- 38
     ,ir_invrcp_daily.factory_return_b          -- 39
     ,ir_invrcp_daily.factory_change            -- 40
     ,ir_invrcp_daily.factory_change_b          -- 41
     ,ir_invrcp_daily.removed_goods             -- 42
     ,ir_invrcp_daily.removed_goods_b           -- 43
     ,ir_invrcp_daily.factory_stock             -- 44
     ,ir_invrcp_daily.factory_stock_b           -- 45
     ,ir_invrcp_daily.wear_decrease             -- 46
     ,ir_invrcp_daily.wear_increase             -- 47
     ,ir_invrcp_daily.selfbase_ship             -- 48
     ,ir_invrcp_daily.selfbase_stock            -- 49
     ,0                                         -- 50
     ,0                                         -- 51
     ,ln_inv_wear                               -- 52
     ,0                                         -- 53
     ,SYSDATE                                   -- 54
     ,cn_last_updated_by                        -- 55
     ,SYSDATE                                   -- 56
     ,cn_created_by                             -- 57
     ,cn_last_update_login                      -- 58
     ,cn_request_id                             -- 59
     ,cn_program_application_id                 -- 60
     ,cn_program_id                             -- 61
     ,SYSDATE                                   -- 62
    );
    --
    -- �I��SEQ��ێ�
    gt_save_1_inv_seq     :=  lt_inventory_seq;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END ins_invrcp_daily;
--
  /**********************************************************************************
   * Procedure Name   : del_invrcp_daily
   * Description      : �쐬�ς݌����݌Ɏ󕥃f�[�^�폜(A-3)
   ***********************************************************************************/
  PROCEDURE del_invrcp_monthly(
    it_base_code      IN  xxcoi_inv_reception_monthly.base_code%TYPE,
                                                        -- 1.���_�R�[�h
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_invrcp_monthly'; -- �v���O������
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
    ln_dummy      NUMBER(1);                    -- �_�~�[�ϐ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  monthly_lock_conc_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_reception_monthly   xirm            -- �����݌Ɏ󕥕\�i�����j
      WHERE   xirm.organization_id    =   gn_f_organization_id
      AND     xirm.base_code          =   it_base_code
      AND     xirm.inventory_kbn      =   gv_param_inventory_kbn
      AND     xirm.practice_month     =   gv_f_inv_acct_period
      FOR UPDATE NOWAIT;
    --
    CURSOR  monthly_lock_cur
    IS
      SELECT  1
      FROM    xxcoi_inv_reception_monthly   xirm            -- �����݌Ɏ󕥕\�i�����j
      WHERE   xirm.organization_id    =   gn_f_organization_id
      AND     xirm.inventory_kbn      =   gv_param_inventory_kbn
      AND     xirm.practice_month     =   gv_f_inv_acct_period
      FOR UPDATE NOWAIT;
    --
    -- <�J�[�\����>���R�[�h�^
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
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�����݌Ɏ󕥕\�폜
    -- ===================================
    BEGIN
      IF (gv_param_exec_flag = cv_exec_1) THEN
        -- �u�R���J�����g�N���v�̏ꍇ
        -- ���b�N�擾
        OPEN  monthly_lock_conc_cur;
        CLOSE monthly_lock_conc_cur;
        --
        -- �폜����
        DELETE FROM xxcoi_inv_reception_monthly
        WHERE   organization_id    =   gn_f_organization_id
        AND     base_code          =   it_base_code
        AND     inventory_kbn      =   gv_param_inventory_kbn
        AND     practice_month     =   gv_f_inv_acct_period;
        --
      ELSIF (gv_param_exec_flag = cv_exec_2) THEN
        -- �u������ԋ����m�裂̏ꍇ
        -- ���b�N�擾
        OPEN  monthly_lock_cur;
        CLOSE monthly_lock_cur;
        --
        -- �폜����
        DELETE FROM xxcoi_inv_reception_monthly
        WHERE   organization_id    =   gn_f_organization_id
        AND     inventory_kbn      =   gv_param_inventory_kbn
        AND     practice_month     =   gv_f_inv_acct_period;
        --
      END IF;
      --
    EXCEPTION
      WHEN lock_error_expt THEN     -- ���b�N�擾���s��
        IF (monthly_lock_conc_cur%ISOPEN) THEN
          CLOSE monthly_lock_conc_cur;
        END IF;
        IF (monthly_lock_cur%ISOPEN) THEN
          CLOSE monthly_lock_cur;
        END IF;
        --
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10145
                       );
        lv_errbuf   := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END del_invrcp_monthly;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_cnt      NUMBER;         -- LOOP�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- --------------------------
    --  �Ώۋ��_�擾
    -- --------------------------
    CURSOR  acct_num_cur
    IS
      SELECT  hca.account_number            -- ���_�R�[�h
      FROM    hz_cust_accounts      hca     -- �ڋq�}�X�^
             ,xxcmm_cust_accounts   xca     -- �ڋq�ǉ����
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     hca.customer_class_code   =   cv_cust_cls_1
      AND     hca.status                =   cv_status_a
      AND     xca.management_base_code  =   gv_param_base_code;
    --
    acct_num_rec    acct_num_cur%ROWTYPE;
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
    -- ===================================
    --  1.�N���p�����[�^���O�o��
    -- ===================================
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10233
                    ,iv_token_name1  => cv_token_10233_1
                    ,iv_token_value1 => gv_param_inventory_kbn
                    ,iv_token_name2  => cv_token_10233_2
                    ,iv_token_value2 => gv_param_base_code
                    ,iv_token_name3  => cv_token_10233_3
                    ,iv_token_value3 => gv_param_exec_flag
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    --
    -- ===================================
    --  2.�݌ɑg�D�R�[�h�擾
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00005
                      ,iv_token_name1  => cv_token_00005_1
                      ,iv_token_value1 => cv_prf_name_orgcd
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.�݌ɑg�DID�擾
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00006
                      ,iv_token_name1  => cv_token_00006_1
                      ,iv_token_value1 => gv_f_organization_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.WHO�J�����擾
    -- ===================================
    -- �O���[�o���Œ�l�̐ݒ蕔�Ŏ擾���Ă��܂��B
    --
    -- ===================================
    --  5.�I�[�v���݌ɉ�v���ԏ��擾
    -- ===================================
    SELECT  MIN(TO_CHAR(oap.period_start_date, cv_month)) -- �ł��Â���v�N��
    INTO    gv_f_inv_acct_period
    FROM    org_acct_periods      oap                     -- �݌ɉ�v���ԃe�[�u��
    WHERE   oap.organization_id   =   gn_f_organization_id
    AND     oap.open_flag         =   cv_yes;
    --
    -- ===================================
    --  6.�Ɩ��������t�擾
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_f_process_date IS NULL) THEN
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    IF (TO_CHAR(gd_f_process_date, cv_month) <> gv_f_inv_acct_period) THEN
      -- �݌ɉ�v�N���ƕs��v�̏ꍇ�A��v�N���̌��������Ɩ��������t�Ƃ��Đݒ�
      gd_f_process_date :=  LAST_DAY(TO_DATE(gv_f_inv_acct_period, cv_month));
    END IF;
    --
    IF (gv_param_inventory_kbn  = cv_inv_kbn_2) THEN     -- 2:����
      -- ===================================
      --  7.���ID�擾�i�O��A�g���j
      -- ===================================
      SELECT  xcc.transaction_id                      -- ���ID
             ,xcc.last_cooperation_date               -- �ŏI�A�g����
      INTO    gn_f_last_transaction_id                -- �����ώ��ID
             ,gd_f_last_cooperation_date              -- ������
      FROM    xxcoi_cooperation_control   xcc         -- �f�[�^�A�g����e�[�u��
      WHERE   xcc.program_short_name  =   cv_pgsname_a09c;
      --
      -- ===================================
      --  8.�ő����h�c�擾�i���ގ���j
      -- ===================================
      BEGIN
        SELECT  MAX(mmt.transaction_id)
        INTO    gn_f_max_transaction_id
        FROM    mtl_material_transactions   mmt
        WHERE   mmt.organization_id   =   gn_f_organization_id
        AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �ő���ID�擾�G���[���b�Z�[�W
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10127
                         );
          lv_errbuf   := lv_errmsg;
          --
          RAISE global_process_expt;
      END;
      --
    END IF;
    --
    -- ===================================
    --  9.�����Ώۋ��_�擾
    -- ===================================
    ln_cnt  :=  0;
    <<set_base_loop>>
    FOR acct_num_rec  IN  acct_num_cur LOOP
      -- �p�����[�^���_���Ǘ������_�̏ꍇ�A�Ǘ����̋��_�S�Ă�ΏۂƂ���
      ln_cnt  :=  ln_cnt + 1;
      gt_f_account_number(ln_cnt)  :=  acct_num_rec.account_number;
    END LOOP set_base_loop;
    --
    IF (ln_cnt = 0) THEN
      -- ���_���擾�ł��Ȃ��ꍇ�A�Ǘ������_�ł͂Ȃ����ߓ��͋��_�݂̂��Ώ�
      gt_f_account_number(1)  :=  gv_param_base_code;
    END IF;
    --
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (acct_num_cur%ISOPEN) THEN
        CLOSE acct_num_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (acct_num_cur%ISOPEN) THEN
        CLOSE acct_num_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (acct_num_cur%ISOPEN) THEN
        CLOSE acct_num_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn  IN  VARCHAR2,     --  1.�I���敪
    iv_base_code      IN  VARCHAR2,     --  2.���_
    iv_exec_flag      IN  VARCHAR2,     --  3.�N���t���O
    ov_errbuf         OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_main_end         NUMBER;
    lv_base_code        VARCHAR2(4);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
    invrcp_daily_rec    invrcp_daily_1_cur%ROWTYPE;
    inv_result_rec      inv_result_1_cur%ROWTYPE;
    daily_trans_rec     daily_trans_cur%ROWTYPE;
    last_month_rec      last_month_cur%ROWTYPE;
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
    --  0.�O���[�o���l�̐ݒ�
    -- ===============================
    -- �O���[�o���ϐ��̏�����
    gv_param_inventory_kbn  :=  iv_inventory_kbn;         -- �y�N���p�����[�^�z�I���敪
    gv_param_base_code      :=  iv_base_code;             -- �y�N���p�����[�^�z���_
    gv_param_exec_flag      :=  iv_exec_flag;             -- �y�N���p�����[�^�z�N���t���O
    --
    FOR i IN 1 .. 38 LOOP
      gt_quantity(i)  :=  0;    -- ����^�C�v�ʐ���
    END LOOP;
--
    -- ===============================
    --  A-1.��������
    -- ===============================
    init(
      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    --
    <<main_loop>>   -- ���C��LOOP
    FOR ln_main_cnt IN  1 .. gt_f_account_number.LAST LOOP
      -- �O���[�o���ϐ��̏�����
      gt_save_1_base_code     :=  NULL;
      gt_save_1_subinv_code   :=  NULL;
      --
      gt_save_2_base_code     :=  NULL;
      gt_save_2_subinv_code   :=  NULL;
      --
      gt_save_3_inv_seq       :=  NULL;
      gt_save_3_base_code     :=  NULL;
      gt_save_3_inv_code      :=  NULL;
      gt_save_3_item_id       :=  NULL;
      gt_save_3_inv_type      :=  NULL;
      gt_save_3_inv_seq_sub   :=  NULL;
      --
      gn_data_cnt             :=  0;
      gt_daily_data.DELETE;
      gv_create_flag          :=  cv_off;
      --
      --
      -- ===================================
      --  A-3.�쐬�ς݌����݌Ɏ󕥃f�[�^�폜
      -- ===================================
      IF (gv_param_inventory_kbn  = cv_inv_kbn_2) THEN
        -- �I���敪�F�Q�i�����j�̏ꍇ�A�폜�����s
        del_invrcp_monthly(
          it_base_code      =>  gt_f_account_number(ln_main_cnt)    -- �Ώۋ��_�R�[�h
         ,ov_errbuf         =>  lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>  lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>  lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      -- ===========================================
      --  A-2.�����݌Ɏ󕥁i�����j���擾�iCURSOR�j
      -- ===========================================
      --
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        -- �I���敪�F�P�i�����j�̏ꍇ
        OPEN  invrcp_daily_1_cur(
                iv_base_code        =>  gt_f_account_number(ln_main_cnt)                  -- ���_�R�[�h
              );
      ELSE
        -- �I���敪�F�Q�i�����j�̏ꍇ
        OPEN  invrcp_daily_2_cur(
                iv_base_code        =>  gt_f_account_number(ln_main_cnt)                  -- ���_�R�[�h
             );
      END IF;
      --
      <<daily_data_loop>>    -- �����f�[�^�o��LOOP
      LOOP
        -- �����f�[�^�o�͏I������
        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
          FETCH invrcp_daily_1_cur  INTO  invrcp_daily_rec;
          EXIT  daily_data_loop   WHEN  invrcp_daily_1_cur%NOTFOUND;
        ELSE
          FETCH invrcp_daily_2_cur  INTO  invrcp_daily_rec;
          EXIT  daily_data_loop   WHEN  invrcp_daily_2_cur%NOTFOUND;
        END IF;
        --
        -- �����A���[�U�N���ŁA�I���Ǘ���񂪑��݂��Ȃ��ꍇ�ȊO�ɁA�ȉ������s
        -- ===================================
        --  A-4.�����݌Ɏ󕥏o�́i�����f�[�^�j
        -- ===================================
        ins_invrcp_daily(
          ir_invrcp_daily   =>  invrcp_daily_rec  --  �����݌Ɏ󕥃f�[�^
         ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================
        --  A-5.�I���Ǘ��o�́i�����f�[�^�j
        -- ===================================
        ins_inv_control(
          ir_invrcp_daily   =>  invrcp_daily_rec  --  �����݌Ɏ󕥃f�[�^
         ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- �L�[���ڂ�ێ�
        gt_save_1_base_code   :=  invrcp_daily_rec.base_code;          -- ���_
        gt_save_1_subinv_code :=  invrcp_daily_rec.subinventory_code;  -- �ۊǏꏊ
        --
      END LOOP daily_data_loop;
      --
      -- ----------------
      --  CURSOR�N���[�Y
      -- ----------------
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        CLOSE invrcp_daily_1_cur;
      ELSE
        CLOSE invrcp_daily_2_cur;
      END IF;
      --
      -- ===================================
      --  A-6.�I�����ʏ�񒊏o
      -- ===================================
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        -- �I���敪�F�P�i�����j�̏ꍇ
        OPEN  inv_result_1_cur(
                iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- ���_�R�[�h
              );
      ELSE
        -- �I���敪�F�Q�i�����j�̏ꍇ
        OPEN  inv_result_2_cur(
                iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- ���_�R�[�h
             );
      END IF;
      --
      <<inv_conseq_loop>>   -- �I�����ʏo��LOOP
      LOOP
        -- �I�����ʏo�͏I������
        IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
          FETCH inv_result_1_cur  INTO  inv_result_rec;
          EXIT  inv_conseq_loop WHEN  inv_result_1_cur%NOTFOUND;
        ELSE
          FETCH inv_result_2_cur  INTO  inv_result_rec;
          EXIT  inv_conseq_loop WHEN  inv_result_2_cur%NOTFOUND;
        END IF;
        --
        -- =======================================
        --  A-7.�����݌Ɏ󕥏o�́i�I�����ʃf�[�^�j
        -- =======================================
        ins_inv_result(
          ir_inv_result     =>  inv_result_rec    --  �I�����ʏ��
         ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- =======================================
        --  A-8.�I���Ǘ��o�́i�I�����ʃf�[�^�j
        -- =======================================
        upd_inv_control(
          ir_inv_result     =>  inv_result_rec    --  �I�����ʏ��
         ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �I���p�����[�^����
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- �L�[���ڂ�ێ�
        gt_save_2_base_code   :=  inv_result_rec.base_code;            -- ���_
        gt_save_2_subinv_code :=  inv_result_rec.subinventory_code;    -- �ۊǏꏊ
        --
      END LOOP inv_conseq_loop;
      --
      -- ----------------
      --  CURSOR�N���[�Y
      -- ----------------
      IF (gv_param_inventory_kbn  = cv_inv_kbn_1) THEN
        CLOSE inv_result_1_cur;
      ELSE
        CLOSE inv_result_2_cur;
      END IF;
      --
      -- A-9����A-11�́A�����̏ꍇ�̂ݎ��s
      IF (gv_param_inventory_kbn = cv_inv_kbn_2) THEN
        --
        -- �ő���ID�Ə����ώ��ID���s��v�̏ꍇ�AA-9, A-10, A-11 �����s
        IF (gn_f_last_transaction_id <> gn_f_max_transaction_id) THEN
          -- ================================================
          --  A-9.��������f�[�^�擾�iCURSOR:daily_trans_cur)
          -- ================================================
          OPEN  daily_trans_cur(
                  iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- ���_�R�[�h
                );
          <<the_day_output_loop>>   -- ��������o��LOOP
          LOOP
            FETCH daily_trans_cur INTO  daily_trans_rec;
            --
            -- ========================================
            --  A-10.�����݌Ɏ󕥏o�́i��������f�[�^�j
            -- ========================================
            ins_daily_data(
              ir_daily_trans    =>  daily_trans_rec   --  ��������f�[�^
             ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            -- �I���p�����[�^����
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
            --
            -- ========================================
            --  A-11.�I���Ǘ��o�́i��������f�[�^�j
            -- ========================================
            ins_daily_invcntl(
              ir_daily_trans    =>  daily_trans_rec   --  ��������f�[�^
             ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            -- �I���p�����[�^����
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
            -- 
            EXIT  the_day_output_loop WHEN  daily_trans_cur%NOTFOUND;
            --
            -- �L�[���ڂ�ێ�
            gt_save_3_base_code   :=  daily_trans_rec.base_code;            -- ���_�R�[�h
            gt_save_3_inv_code    :=  daily_trans_rec.subinventory_code;    -- �ۊǏꏊ�R�[�h
            gt_save_3_item_id     :=  daily_trans_rec.inventory_item_id;    -- �i��ID
            gt_save_3_inv_type    :=  daily_trans_rec.inventory_type;       -- �ۊǏꏊ�^�C�v
            gt_save_3_inv_seq_sub :=  daily_trans_rec.inventory_seq;        -- �L�[���ڒP�ʂ̑O�f�[�^�̒I��SEQ
            --
          END LOOP the_day_output_loop;
          --
          -- ----------------
          --  CURSOR�N���[�Y
          -- ----------------
          CLOSE daily_trans_cur;
        END IF;
      END IF;
      --
      -- ===================================
      --  A-12.�O���I�����ʒ��o
      -- ===================================
      OPEN  last_month_cur(
              iv_base_code        =>  gt_f_account_number(ln_main_cnt)              -- ���_�R�[�h
            );
      --
      <<month_balance_loop>>    -- ����c��LOOP
      LOOP
        FETCH last_month_cur  INTO  last_month_rec;
        EXIT  month_balance_loop  WHEN  last_month_cur%NOTFOUND;
        --
        IF (last_month_rec.last_month_inv_seq IS NOT NULL) THEN
          -- ========================================
          --  A-13.����c���o��
          -- ========================================
          ins_month_balance(
            ir_month_balance  =>  last_month_rec    --  ����c��
           ,ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          -- �I���p�����[�^����
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
      END LOOP month_balance_loop;
      -- ----------------
      --  CURSOR�N���[�Y
      -- ----------------
      CLOSE last_month_cur;
      --
    END LOOP main_loop;
    --
    -- ===============================
    --  A-15.�㏈��
    -- ===============================
    close_process(
      ov_errbuf         =>  lv_errbuf         --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        =>  lv_retcode        --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         =>  lv_errmsg         --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      IF (invrcp_daily_1_cur%ISOPEN) THEN
        CLOSE invrcp_daily_1_cur;
      END IF;
      IF (invrcp_daily_2_cur%ISOPEN) THEN
        CLOSE invrcp_daily_2_cur;
      END IF;
      IF (inv_result_1_cur%ISOPEN) THEN
        CLOSE inv_result_1_cur;
      END IF;
      IF (inv_result_2_cur%ISOPEN) THEN
        CLOSE inv_result_2_cur;
      END IF;
      IF (daily_trans_cur%ISOPEN) THEN
        CLOSE daily_trans_cur;
      END IF;
      IF (last_month_cur%ISOPEN) THEN
        CLOSE last_month_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      IF (invrcp_daily_1_cur%ISOPEN) THEN
        CLOSE invrcp_daily_1_cur;
      END IF;
      IF (invrcp_daily_2_cur%ISOPEN) THEN
        CLOSE invrcp_daily_2_cur;
      END IF;
      IF (inv_result_1_cur%ISOPEN) THEN
        CLOSE inv_result_1_cur;
      END IF;
      IF (inv_result_2_cur%ISOPEN) THEN
        CLOSE inv_result_2_cur;
      END IF;
      IF (daily_trans_cur%ISOPEN) THEN
        CLOSE daily_trans_cur;
      END IF;
      IF (last_month_cur%ISOPEN) THEN
        CLOSE last_month_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      gn_normal_cnt :=  0;
      IF (invrcp_daily_1_cur%ISOPEN) THEN
        CLOSE invrcp_daily_1_cur;
      END IF;
      IF (invrcp_daily_2_cur%ISOPEN) THEN
        CLOSE invrcp_daily_2_cur;
      END IF;
      IF (inv_result_1_cur%ISOPEN) THEN
        CLOSE inv_result_1_cur;
      END IF;
      IF (inv_result_2_cur%ISOPEN) THEN
        CLOSE inv_result_2_cur;
      END IF;
      IF (daily_trans_cur%ISOPEN) THEN
        CLOSE daily_trans_cur;
      END IF;
      IF (last_month_cur%ISOPEN) THEN
        CLOSE last_month_cur;
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
    errbuf              OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_inventory_kbn    IN  VARCHAR2,       -- �y�K�{�z�I���敪�i1:�����A2:�����j
    iv_base_code        IN  VARCHAR2,       -- �y�C�Ӂz���_
    iv_exec_flag        IN  VARCHAR2        -- �y�K�{�z�N���t���O�i1:�R���J�����g�N���A2:������ԋ����m��j
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
        iv_inventory_kbn    =>  iv_inventory_kbn    -- �I���敪
       ,iv_base_code        =>  iv_base_code        -- ���_
       ,iv_exec_flag        =>  iv_exec_flag        -- �N���t���O
       ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
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
    fnd_file.put_line(
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
END XXCOI006A03C;
/
