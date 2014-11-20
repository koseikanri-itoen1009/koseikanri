CREATE OR REPLACE PACKAGE BODY XXCOI006A18R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A18R(body)
 * Description      : ���o���ו\�i���_�ʁE���v�j
 * MD.050           : ���o���ו\�i���_�ʁE���v�j <MD050_XXCOI_006_A18>
 * Version          : V1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data           ���[�N�e�[�u���f�[�^�폜               (A-6)
 *  call_output_svf        SVF�N��                                (A-5)
 *  ins_svf_data           ���[�N�e�[�u���f�[�^�o�^               (A-4)
 *  valid_param_value      �p�����[�^�`�F�b�N                     (A-2)
 *  init                   ��������                               (A-1)
 *  submain                ���C�������v���V�[�W��
 *                         �f�[�^�擾                             (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   Y.Kobayashi      ���ō쐬
 *  2009/05/13    1.1   T.Nakamura       [��QT1_0960]�Q�Ƃ���J�e�S�������i���i�敪�ɕύX
 *  2009/06/26    1.2   H.Sasaki         [0000258]���ʌv�Z�ɒI�����Ր������Z���Ȃ�
 *                                                ���o���v�Ɋ�݌ɕύX���ɂ�ǉ�
 *  2009/07/13    1.3   N.Abe            [0000282]�S�ݓX�v�A���X�v�̖��̏o�͂��C��
 *  2009/07/14    1.4   N.Abe            [0000462]�Q�R�[�h�擾���@�C��
 *  2009/07/21    1.5   H.Sasaki         [0000807]VD�o�ɐ��ʂ��A��݌ɕύX���ɐ��ʂ����Z
 *  2009/09/11    1.6   N.Abe            [0001266]OPM�i�ڃA�h�I���̎擾���@�C��
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOI006A18R';           -- �p�b�P�[�W��
  -- ���b�Z�[�W�֘A
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)  :=  'XXCOI';                    -- �A�v���P�[�V�����Z�k��
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00008';         -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00011';         -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10098       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10098';         -- �p�����[�^�o�͋敪�l�G���[���b�Z�[�W
  cv_msg_xxcoi1_10107       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10107';         -- �p�����[�^�󕥔N���l���b�Z�[�W
  cv_msg_xxcoi1_10108       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10108';         -- �p�����[�^�����敪�l���b�Z�[�W
  cv_msg_xxcoi1_10109       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10109';         -- �p�����[�^���_�l���b�Z�[�W
  cv_msg_xxcoi1_10110       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10110';         -- �󕥔N���^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10111       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10111';         -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10113       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10113';         -- �o�͋敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10114       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10114';         -- �����敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10115       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10115';         -- ���_�R�[�hNULL�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10116       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10116';         -- ���O�C�����[�U���_�R�[�h���o�G���[���b�Z�[�W
  cv_msg_xxcoi1_10117       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10117';         -- ���X�v���_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10118       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10118';         -- �S�ݓX�v���_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10296       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10296';         -- �S�ݓX�v���_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10119';         -- SVF�N��API�G���[���b�Z�[�W
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  cv_msg_xxcoi1_10146       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10146';         -- �i�ڋ敪�J�e�S���Z�b�g���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10382       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10382';         -- ���i���i�敪�J�e�S���Z�b�g���擾�G���[���b�Z�[�W
-- == 2009/05/13 V1.1 Modified END   ===============================================================
  cv_token_10098_1          CONSTANT VARCHAR2(30) :=  'P_OUT_TYPE';               -- APP-XXCOI1-10098�p�g�[�N���i�o�͋敪�j
  cv_token_10107_1          CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';        -- APP-XXCOI1-10107�p�g�[�N���i�󕥔N���j
  cv_token_10108_1          CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';              -- APP-XXCOI1-10108�p�g�[�N���i�����敪�j
  cv_token_10109_1          CONSTANT VARCHAR2(30) :=  'P_BASE_CODE';              -- APP-XXCOI1-10109�p�g�[�N���i���_�R�[�h�j
  cv_token_10146_1          CONSTANT VARCHAR2(30) :=  'PRO_TOK';                  -- APP-XXCOI1-10146�p�g�[�N���i�v���t�@�C�����j
  cv_prf_name_sp_manage     CONSTANT VARCHAR2(30) :=  'XXCOI1_SP_MANAGEMENT';         -- �v���t�@�C�����i���X�v���_�R�[�h�j
  cv_prf_name_dp_manage     CONSTANT VARCHAR2(30) :=  'XXCOI1_DEPT_MANAGEMENT';       -- �v���t�@�C�����i�S�ݓX�v���_�R�[�h�j
  cv_prf_name_item_dept     CONSTANT VARCHAR2(30) :=  'XXCOI1_ITEM_DEPT_BASE_CODE';   -- �v���t�@�C�����i���i�����_�R�[�h�j
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  cv_prf_name_category      CONSTANT VARCHAR2(30) :=  'XXCOI1_ITEM_CATEGORY_CLASS';   -- �v���t�@�C�����i�i�ڋ敪�J�e�S���Z�b�g���j
  cv_prf_name_category      CONSTANT VARCHAR2(30) :=  'XXCOI1_GOODS_PRODUCT_CLASS';   -- �v���t�@�C�����i���i���i�敪�J�e�S���Z�b�g���j
-- == 2009/05/13 V1.1 Modified END   ===============================================================
  -- �o�͋敪�i30:���_�� 40:���X�� 50:�S�ݓX�� 60:���X�v 70:�S�ݓX�v 80:���c�X�v 90:�S�Ќv�j
  cv_output_kbn_30          CONSTANT VARCHAR2(2)  :=  '30';
  cv_output_kbn_40          CONSTANT VARCHAR2(2)  :=  '40';
  cv_output_kbn_50          CONSTANT VARCHAR2(2)  :=  '50';
  cv_output_kbn_60          CONSTANT VARCHAR2(2)  :=  '60';
  cv_output_kbn_70          CONSTANT VARCHAR2(2)  :=  '70';
  cv_output_kbn_80          CONSTANT VARCHAR2(2)  :=  '80';
  cv_output_kbn_90          CONSTANT VARCHAR2(2)  :=  '90';
  -- LOOKUP_TYPE
  cv_xxcoi1_output_div      CONSTANT VARCHAR2(30) :=  'XXCOI1_IN_OUT_LIST_OUTPUT_DIV';  -- LOOKUP_TYPE�i�o�͋敪�j
  cv_xxcoi_cost_price_div   CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';          -- LOOKUP_TYPE�i�����敪�j
  -- �ۊǏꏊ�敪�i4:���X�j
  cv_subinv_type_4          CONSTANT VARCHAR2(1)  :=  '4';
  -- �I���敪�i1:����  2:�����j
  cv_inv_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  -- �ڋq�敪�i1:���_�j
  cv_cust_cls_1             CONSTANT VARCHAR2(1)  :=  '1';
  -- �ڋq�}�X�^�D�X�e�[�^�X
  cv_status_a               CONSTANT VARCHAR2(1)  :=  'A';
  -- ���̑�
  cv_type_month             CONSTANT VARCHAR2(6)  :=  'YYYYMM';                -- DATE�^ �N���iYYYYMM�j
  cv_type_date              CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';              -- DATE�^ �N�����iYYYYMMDD�j
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                   -- �R���J�����g�w�b�_�o�͐�
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                     -- ���p�X�y�[�X
  --�J�[�\������敪
  cv_cur_kbn_1              CONSTANT VARCHAR2(1)  :=  '1';
  cv_cur_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  cv_cur_kbn_3              CONSTANT VARCHAR2(1)  :=  '3';
  cv_cur_kbn_4              CONSTANT VARCHAR2(1)  :=  '4';
  -- SVF�N���֐��p�����[�^�p
  cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A18R';          -- �R���J�����g��
  cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                  -- �g���q�iPDF�j
  cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A18R';          -- ���[ID
  cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                     -- �o�͋敪
  cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A18S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A18S.vrq';      -- �N�G���[�l���t�@�C����
-- == 2009/05/13 V1.1 Modified START ===============================================================
--  gv_item_category          VARCHAR2(10);                       -- �J�e�S���[��
  gv_item_category          VARCHAR2(12);                       -- �J�e�S���[��
-- == 2009/05/13 V1.1 Modified END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_param_output_kbn       VARCHAR2(2);                        -- �o�͋敪�i30:���_�� 40:���X�� 50:�S�ݓX�� 60:���X�v 70:�S�ݓX�v 80:���c�X�v 90:�S�Ќv�j
  gv_param_reception_date   VARCHAR2(6);                        -- �󕥔N���iYYYYMM�j
  gv_param_cost_type        VARCHAR2(2);                        -- �����敪�i10:�c�ƌ����A20:�W�������j
  gv_param_base_code        VARCHAR2(4);                        -- ���_
  -- ���������ݒ�l
  gd_f_process_date         DATE;                               -- �Ɩ����t
  gv_user_basecode          VARCHAR2(4);                        -- �������_
  gt_output_kbn_type_name   fnd_lookup_values.meaning%TYPE;     -- �o�͋敪��
  gt_cost_type_name         fnd_lookup_values.meaning%TYPE;     -- �����敪��
  gv_item_dept_base_code    VARCHAR2(4);                        -- ���i�����_�R�[�h
-- == 2009/07/14 V1.4 Added START ===============================================================
  gd_target_date            DATE;
-- == 2009/07/14 V1.4 Added END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  -- ���_�ʁA���X�ʁA�S�ݓX�ʂ̂��Âꂩ�A���A���_���ݒ肳��Ă���ꍇ
  CURSOR  svf_data_cur1
  IS
    SELECT  xirm.base_code                      base_code                 -- ���_�R�[�h
           ,SUBSTRB(sca.account_name, 1, 8)     account_name              -- ���_����
           ,mcb.segment1                        item_type                 -- ���i���i�敪�i�J�e�S���R�[�h�j
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                   policy_group              -- �Q�R�[�h
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- �i�ڃR�[�h
           ,xsib.item_short_name                item_short_name           -- ���i���́i���́j
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- ����
           ,xirm.sales_shipped                  sales_shipped             -- ����o��
           ,xirm.sales_shipped_b                sales_shipped_b           -- ����o�ɐU��
           ,xirm.return_goods                   return_goods              -- �ԕi
           ,xirm.return_goods_b                 return_goods_b            -- �ԕi�U��
           ,xirm.change_ship                    change_ship               -- �q�֏o��
           ,xirm.goods_transfer_old             goods_transfer_old        -- ���i�U��(�����i)
           ,xirm.sample_quantity                sample_quantity           -- ���{�o��
           ,xirm.sample_quantity_b              sample_quantity_b         -- ���{�o�ɐU��
           ,xirm.customer_sample_ship           customer_sample_ship      -- �ڋq���{�o��
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           ,xirm.customer_support_ss            customer_support_ss       -- �ڋq���^���{�o��
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           ,xirm.inventory_change_out           inventory_change_out      -- ��݌ɕύX�o��
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- ��݌ɕύX����
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- �H��ԕi
           ,xirm.factory_return_b               factory_return_b          -- �H��ԕi�U��
           ,xirm.factory_change                 factory_change            -- �H��q��
           ,xirm.factory_change_b               factory_change_b          -- �H��q�֐U��
           ,xirm.removed_goods                  removed_goods             -- �p�p
           ,xirm.removed_goods_b                removed_goods_b           -- �p�p�U��
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- �I�����Ռ�
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- �����݌Ɏ󕥕\�i�����j
           ,mtl_categories_b                    mcb                       -- �J�e�S��
           ,mtl_item_categories                 mic                       -- �i�ڃJ�e�S������
           ,ic_item_mst_b                       iimb                      -- OPM�i��
           ,xxcmn_item_mst_b                    xsib                      -- OPM�i�ڃA�h�I��
           ,mtl_system_items_b                  msib                      -- Disc�i��
           ,(SELECT   CASE  WHEN  xca.customer_id IS NULL THEN  hca1.account_number
                      ELSE  hca2.account_number
                      END   base_code
                     ,CASE  WHEN  xca.customer_id IS NULL THEN  hca1.account_name
                      ELSE  hca2.account_name
                      END   account_name
             FROM     hz_cust_accounts      hca1
                     ,hz_cust_accounts      hca2
                     ,xxcmm_cust_accounts   xca
             WHERE    hca1.account_number           =   gv_param_base_code
             AND      hca1.account_number           =   xca.management_base_code(+)
             AND      xca.customer_id               =   hca2.cust_account_id(+)
             AND      hca1.customer_class_code      =   cv_cust_cls_1
             AND      hca1.status                   =   cv_status_a
             AND      hca2.customer_class_code(+)   =   cv_cust_cls_1
             AND      hca2.status(+)                =   cv_status_a
            )         sca                                                 -- �ڋq���
    WHERE   xirm.base_code          =   sca.base_code
    AND     xirm.practice_month     =   gv_param_reception_date           -- �p�����[�^.�󕥔N��
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- �I���敪='2'�i�����j
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- ���c�X�v�̏ꍇ
  CURSOR  svf_data_cur2
  IS
    SELECT  xirm.base_code                      base_code                 -- ���_�R�[�h
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- ���_����
           ,mcb.segment1                        item_type                 -- ���i���i�敪�i�J�e�S���R�[�h�j
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                   policy_group              -- �Q�R�[�h
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- �i�ڃR�[�h
           ,xsib.item_short_name                item_short_name           -- ���i���́i���́j
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- ����
           ,xirm.sales_shipped                  sales_shipped             -- ����o��
           ,xirm.sales_shipped_b                sales_shipped_b           -- ����o�ɐU��
           ,xirm.return_goods                   return_goods              -- �ԕi
           ,xirm.return_goods_b                 return_goods_b            -- �ԕi�U��
           ,xirm.change_ship                    change_ship               -- �q�֏o��
           ,xirm.goods_transfer_old             goods_transfer_old        -- ���i�U��(�����i)
           ,xirm.sample_quantity                sample_quantity           -- ���{�o��
           ,xirm.sample_quantity_b              sample_quantity_b         -- ���{�o�ɐU��
           ,xirm.customer_sample_ship           customer_sample_ship      -- �ڋq���{�o��
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           ,xirm.customer_support_ss            customer_support_ss       -- �ڋq���^���{�o��
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           ,xirm.inventory_change_out           inventory_change_out      -- ��݌ɕύX�o��
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- ��݌ɕύX����
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- �H��ԕi
           ,xirm.factory_return_b               factory_return_b          -- �H��ԕi�U��
           ,xirm.factory_change                 factory_change            -- �H��q��
           ,xirm.factory_change_b               factory_change_b          -- �H��q�֐U��
           ,xirm.removed_goods                  removed_goods             -- �p�p
           ,xirm.removed_goods_b                removed_goods_b           -- �p�p�U��
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- �I�����Ռ�
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- �����݌Ɏ󕥕\�i�����j
           ,hz_cust_accounts                    hca                       -- �ڋq�}�X�^
           ,mtl_categories_b                    mcb                       -- �J�e�S��
           ,mtl_item_categories                 mic                       -- �i�ڃJ�e�S������
           ,ic_item_mst_b                       iimb                      -- OPM�i��
           ,xxcmn_item_mst_b                    xsib                      -- OPM�i�ڃA�h�I��
           ,mtl_system_items_b                  msib                      -- Disc�i��
    WHERE   xirm.subinventory_type  =   cv_subinv_type_4                  -- �ۊǏꏊ�}�X�^.�ۊǏꏊ�敪='4'�i���X�j
    AND     xirm.practice_month     =   gv_param_reception_date           -- �p�����[�^.�󕥔N��
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- �I���敪='2'�i�����j
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1                     -- �ڋq�敪='1'�i���_�j
    AND     hca.status              =   cv_status_a                       -- �X�e�[�^�X='A'
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- ���X�v�A�S�ݓX�v�A���́A
  -- ���_�ʁi���i���ȊO�j�A���X�ʁA�S�ݓX�ʂ̂��Âꂩ�A���A���_���ݒ肳��Ă��Ȃ��ꍇ
  CURSOR  svf_data_cur3
  IS
    SELECT  xirm.base_code                      base_code                 -- ���_�R�[�h
           ,SUBSTRB(sca.account_name, 1, 8)     account_name              -- ���_����
           ,mcb.segment1                        item_type                 -- ���i���i�敪�i�J�e�S���R�[�h�j
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                   policy_group              -- �Q�R�[�h
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- �i�ڃR�[�h
           ,xsib.item_short_name                item_short_name           -- ���i���́i���́j
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- ����
           ,xirm.sales_shipped                  sales_shipped             -- ����o��
           ,xirm.sales_shipped_b                sales_shipped_b           -- ����o�ɐU��
           ,xirm.return_goods                   return_goods              -- �ԕi
           ,xirm.return_goods_b                 return_goods_b            -- �ԕi�U��
           ,xirm.change_ship                    change_ship               -- �q�֏o��
           ,xirm.goods_transfer_old             goods_transfer_old        -- ���i�U��(�����i)
           ,xirm.sample_quantity                sample_quantity           -- ���{�o��
           ,xirm.sample_quantity_b              sample_quantity_b         -- ���{�o�ɐU��
           ,xirm.customer_sample_ship           customer_sample_ship      -- �ڋq���{�o��
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           ,xirm.customer_support_ss            customer_support_ss       -- �ڋq���^���{�o��
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           ,xirm.inventory_change_out           inventory_change_out      -- ��݌ɕύX�o��
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- ��݌ɕύX����
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- �H��ԕi
           ,xirm.factory_return_b               factory_return_b          -- �H��ԕi�U��
           ,xirm.factory_change                 factory_change            -- �H��q��
           ,xirm.factory_change_b               factory_change_b          -- �H��q�֐U��
           ,xirm.removed_goods                  removed_goods             -- �p�p
           ,xirm.removed_goods_b                removed_goods_b           -- �p�p�U��
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- �I�����Ռ�
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- �����݌Ɏ󕥕\�i�����j
           ,mtl_categories_b                    mcb                       -- �J�e�S��
           ,mtl_item_categories                 mic                       -- �i�ڃJ�e�S������
           ,ic_item_mst_b                       iimb                      -- OPM�i��
           ,xxcmn_item_mst_b                    xsib                      -- OPM�i�ڃA�h�I��
           ,mtl_system_items_b                  msib                      -- Disc�i��
           ,(SELECT   hca2.account_number   base_code
                     ,hca2.account_name     account_name
             FROM     hz_cust_accounts      hca1
                     ,hz_cust_accounts      hca2
                     ,xxcmm_cust_accounts   xca
             WHERE    hca1.account_number       =   CASE  WHEN  gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70)  THEN  gv_param_base_code
                                                          ELSE  gv_user_basecode
                                                    END
             AND      hca1.account_number       =   xca.management_base_code
             AND      xca.customer_id           =   hca2.cust_account_id
             AND      hca1.customer_class_code  =   cv_cust_cls_1
             AND      hca1.status               =   cv_status_a
             AND      hca2.customer_class_code  =   cv_cust_cls_1
             AND      hca2.status               =   cv_status_a
            )         sca                                                 -- �ڋq���
    WHERE   xirm.practice_month       =   gv_param_reception_date         -- �p�����[�^.�󕥔N��
    AND     xirm.inventory_item_id    =   msib.inventory_item_id
    AND     xirm.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id    =   mic.inventory_item_id
    AND     xirm.organization_id      =   mic.organization_id
    AND     mic.category_id           =   mcb.category_id
    AND     mcb.attribute_category    =   gv_item_category
    AND     xirm.base_code            =   sca.base_code
    AND     xirm.inventory_kbn        =   cv_inv_kbn_2                    -- �I���敪='2'�i�����j
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
  -- �S�Ќv�A����
  -- ���_�ʁi���i���j�A���A���_���ݒ肳��Ă��Ȃ��ꍇ
  CURSOR  svf_data_cur4
  IS
    SELECT  xirm.base_code                      base_code                 -- ���_�R�[�h
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- ���_����
           ,mcb.segment1                        item_type                 -- ���i���i�敪�i�J�e�S���R�[�h�j
-- == 2009/07/14 V1.4 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)       policy_group              -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                   policy_group              -- �Q�R�[�h
-- == 2009/07/14 V1.4 Modified END   ===============================================================
           ,msib.segment1                       item_code                 -- �i�ڃR�[�h
           ,xsib.item_short_name                item_short_name           -- ���i���́i���́j
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- ����
           ,xirm.sales_shipped                  sales_shipped             -- ����o��
           ,xirm.sales_shipped_b                sales_shipped_b           -- ����o�ɐU��
           ,xirm.return_goods                   return_goods              -- �ԕi
           ,xirm.return_goods_b                 return_goods_b            -- �ԕi�U��
           ,xirm.change_ship                    change_ship               -- �q�֏o��
           ,xirm.goods_transfer_old             goods_transfer_old        -- ���i�U��(�����i)
           ,xirm.sample_quantity                sample_quantity           -- ���{�o��
           ,xirm.sample_quantity_b              sample_quantity_b         -- ���{�o�ɐU��
           ,xirm.customer_sample_ship           customer_sample_ship      -- �ڋq���{�o��
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           ,xirm.customer_support_ss            customer_support_ss       -- �ڋq���^���{�o��
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           ,xirm.inventory_change_out           inventory_change_out      -- ��݌ɕύX�o��
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- ��݌ɕύX����
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- �H��ԕi
           ,xirm.factory_return_b               factory_return_b          -- �H��ԕi�U��
           ,xirm.factory_change                 factory_change            -- �H��q��
           ,xirm.factory_change_b               factory_change_b          -- �H��q�֐U��
           ,xirm.removed_goods                  removed_goods             -- �p�p
           ,xirm.removed_goods_b                removed_goods_b           -- �p�p�U��
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- �I�����Ռ�
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- �����݌Ɏ󕥕\�i�����j
           ,hz_cust_accounts                    hca                       -- �ڋq�}�X�^
           ,mtl_categories_b                    mcb                       -- �J�e�S��
           ,mtl_item_categories                 mic                       -- �i�ڃJ�e�S������
           ,ic_item_mst_b                       iimb                      -- OPM�i��
           ,xxcmn_item_mst_b                    xsib                      -- OPM�i�ڃA�h�I��
           ,mtl_system_items_b                  msib                      -- Disc�i��
    WHERE   xirm.practice_month     =   gv_param_reception_date           -- �p�����[�^.�󕥔N��
    AND     xirm.inventory_item_id  =   msib.inventory_item_id
    AND     xirm.organization_id    =   msib.organization_id
    AND     msib.segment1           =   iimb.item_no
    AND     iimb.item_id            =   xsib.item_id
-- == 2009/09/11 V1.6 Added START ===============================================================
    AND     TRUNC(gd_target_date) BETWEEN TRUNC(xsib.start_date_active)
                                  AND     TRUNC(xsib.end_date_active)
-- == 2009/09/11 V1.6 Added END   ===============================================================
    AND     xirm.inventory_item_id  =   mic.inventory_item_id
    AND     xirm.organization_id    =   mic.organization_id
    AND     mic.category_id         =   mcb.category_id
    AND     mcb.attribute_category  =   gv_item_category
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2                      -- �I���敪='2'�i�����j
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1                     -- �ڋq�敪='1'�i���_�j
    AND     hca.status              =   cv_status_a                       -- �X�e�[�^�X='A'
    ORDER BY  xirm.base_code
             ,mcb.segment1
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,msib.segment1;
  --
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_svf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_svf_data'; -- �v���O������
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
    -- ===============================
    --  1.���[�N�e�[�u���폜
    -- ===============================
    DELETE  FROM xxcoi_rep_base_detail_expend
    WHERE   request_id  = cn_request_id;
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : call_output_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE call_output_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_output_svf'; -- �v���O������
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
    -- ===============================
    --  1.SVF�N��
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>  cv_conc_name            -- �R���J�����g��
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_type_date) || TO_CHAR(cn_request_id) || cv_type_pdf     -- �o�̓t�@�C����
      ,iv_file_id           =>  cv_file_id              -- ���[ID
      ,iv_output_mode       =>  cv_output_mode          -- �o�͋敪
      ,iv_frm_file          =>  cv_frm_file             -- �t�H�[���l���t�@�C����
      ,iv_vrq_file          =>  cv_vrq_file             -- �N�G���[�l���t�@�C����
      ,iv_org_id            =>  fnd_global.org_id       -- ORG_ID
      ,iv_user_name         =>  fnd_global.user_name    -- ���O�C���E���[�U��
      ,iv_resp_name         =>  fnd_global.resp_name    -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name          =>  NULL                    -- ������
      ,iv_printer_name      =>  NULL                    -- �v�����^��
      ,iv_request_id        =>  cn_request_id           -- �v��ID
      ,iv_nodata_msg        =>  NULL                    -- �f�[�^�Ȃ����b�Z�[�W
      ,ov_retcode           =>  lv_retcode              -- ���^�[���R�[�h
      ,ov_errbuf            =>  lv_errbuf               -- �G���[���b�Z�[�W
      ,ov_errmsg            =>  lv_errmsg               -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �I���p�����[�^����
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- SVF�N��API�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10119
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data   IN  svf_data_cur1%ROWTYPE,   -- 1.CSV�o�͑Ώۃf�[�^
    in_slit_id    IN  NUMBER,                 -- 2.�����A��
    iv_message    IN  VARCHAR2,               -- 3.�O�����b�Z�[�W
    ov_errbuf     OUT VARCHAR2,               -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,               -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)               -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_svf_data'; -- �v���O������
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
    lv_base_code              VARCHAR2(4);                                -- ���_�R�[�h
    lv_base_name              VARCHAR2(8);                                -- ���_����
    lt_item_type              mtl_categories_b.segment1%TYPE;             -- ���i�敪
    lt_policy_group           ic_item_mst_b.attribute2%TYPE;              -- �Q�R�[�h
    lt_item_code              mtl_system_items_b.segment1%TYPE;           -- ���i�R�[�h
    lt_item_short_name        xxcmn_item_mst_b.item_short_name%TYPE;      -- ���i����
    ln_sales_ship_qty         NUMBER;                                     -- ����o�ɐ���
    ln_sales_ship_money       NUMBER;                                     -- ����o�ɋ��z
    ln_vd_ship_qty            NUMBER;                                     -- VD�o�ɐ���
    ln_vd_ship_money          NUMBER;                                     -- VD�o�ɋ��z
    ln_support_qty            NUMBER;                                     -- ���^���{����
    ln_support_money          NUMBER;                                     -- ���^���{���z
    ln_sample_qty             NUMBER;                                     -- ���{�o�ɐ���
    ln_sample_money           NUMBER;                                     -- ���{�o�ɋ��z
    ln_disposal_qty           NUMBER;                                     -- �p�p�o�ɐ���
    ln_disposal_money         NUMBER;                                     -- �p�p�o�ɋ��z
    ln_kuragae_ship_qty       NUMBER;                                     -- �q�֏o�ɐ���
    ln_kuragae_ship_money     NUMBER;                                     -- �q�֏o�ɋ��z
    ln_hurikae_ship_qty       NUMBER;                                     -- �U�֏o�ɐ���
    ln_hurikae_ship_money     NUMBER;                                     -- �U�֏o�ɋ��z
    ln_factry_change_qty      NUMBER;                                     -- �H��q�֐���
    ln_factry_change_money    NUMBER;                                     -- �H��q�֋��z
    ln_factry_return_qty      NUMBER;                                     -- �H��ԕi����
    ln_factry_return_money    NUMBER;                                     -- �H��ԕi���z
    ln_payment_total_qty      NUMBER;                                     -- ���o���v����
    ln_payment_total_money    NUMBER;                                     -- ���o���v���z
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
    -- ===============================
    --  1.���[�N�e�[�u���쐬
    -- ===============================
    -- �f�[�^�ݒ�
    -- 06.���_�R�[�h
    IF (gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70)) THEN
      -- ���X�v�A�S�ݓX�v�̏ꍇ
      lv_base_code  :=  SUBSTRB(gv_param_base_code, 1, 4);
    ELSIF (gv_param_output_kbn IN(cv_output_kbn_80, cv_output_kbn_90)) THEN
      -- ���c�X�v�A�S�Ќv
      lv_base_code  :=  NULL;
    ELSE
      lv_base_code  :=  SUBSTRB(ir_svf_data.base_code, 1, 4);
    END IF;
    --
    -- 06.���_����
-- == 2009/07/13 V1.3 Modified START ===============================================================
--    IF (gv_param_output_kbn IN(cv_output_kbn_80, cv_output_kbn_90)) THEN
    IF (gv_param_output_kbn IN(cv_output_kbn_60, cv_output_kbn_70, cv_output_kbn_80, cv_output_kbn_90)) THEN
-- == 2009/07/13 V1.3 Modified END   ===============================================================
      -- ���c�X�v�A�S�Ќv�A�S�ݓX�v�A���X�v
      lv_base_name  :=  SUBSTRB(gt_output_kbn_type_name, 1, 8);
    ELSE
      lv_base_name  :=  SUBSTRB(ir_svf_data.account_name, 1, 8);
    END IF;
    --
    IF (iv_message IS NOT NULL) THEN
      -- �Ώی����O���̏ꍇ
      lt_policy_group         :=  NULL;                 -- 08.�Q�R�[�h
      lt_item_code            :=  NULL;                 -- 09.���iCD
      lt_item_short_name      :=  NULL;                 -- 10.���i��
      lt_item_type            :=  NULL;                 -- 11.���i�敪
      ln_sales_ship_qty       :=  NULL;                 -- 12.����o�ɐ���
      ln_sales_ship_money     :=  NULL;                 -- 13.����o�ɋ��z
      ln_vd_ship_qty          :=  NULL;                 -- 14.VD�o�ɐ���
      ln_vd_ship_money        :=  NULL;                 -- 15.VD�o�ɋ��z
      ln_support_qty          :=  NULL;                 -- 16.���^���{����
      ln_support_money        :=  NULL;                 -- 17.���^���{���z
      ln_sample_qty           :=  NULL;                 -- 18.���{�o�ɐ���
      ln_sample_money         :=  NULL;                 -- 19.���{�o�ɋ��z
      ln_disposal_qty         :=  NULL;                 -- 20.�p�p�o�ɐ���
      ln_disposal_money       :=  NULL;                 -- 21.�p�p�o�ɋ��z
      ln_kuragae_ship_qty     :=  NULL;                 -- 22.�q�֏o�ɐ���
      ln_kuragae_ship_money   :=  NULL;                 -- 23.�q�֏o�ɋ��z
      ln_hurikae_ship_qty     :=  NULL;                 -- 24.�U�֏o�ɐ���
      ln_hurikae_ship_money   :=  NULL;                 -- 25.�U�֏o�ɋ��z
      ln_factry_change_qty    :=  NULL;                 -- 26.�H��q�֐���
      ln_factry_change_money  :=  NULL;                 -- 27.�H��q�֋��z
      ln_factry_return_qty    :=  NULL;                 -- 28.�H��ԕi����
      ln_factry_return_money  :=  NULL;                 -- 29.�H��ԕi���z
      ln_payment_total_qty    :=  NULL;                 -- 30.���o���v����
      ln_payment_total_money  :=  NULL;                 -- 31.���o���v���z
      --
    ELSE
      lt_policy_group         :=   ir_svf_data.policy_group;                      -- 08.�Q�R�[�h
      lt_item_code            :=   SUBSTRB(ir_svf_data.item_code, 1, 7);          -- 09.���iCD
      lt_item_short_name      :=   SUBSTRB(ir_svf_data.item_short_name, 1, 20);   -- 10.���i��
      lt_item_type            :=   SUBSTRB(ir_svf_data.item_type, 1, 1);          -- 11.���i�敪
      --
      ln_sales_ship_qty       :=   ir_svf_data.sales_shipped
                                 - ir_svf_data.sales_shipped_b
                                 - ir_svf_data.return_goods
                                 + ir_svf_data.return_goods_b;              -- 12.����o�ɐ���
-- == 2009/07/21 V1.5 Modified START ===============================================================
--      ln_vd_ship_qty          :=   ir_svf_data.inventory_change_out;
      ln_vd_ship_qty          :=   ir_svf_data.inventory_change_out
                                 - ir_svf_data.inventory_change_in;         -- 14.VD�o�ɐ���
-- == 2009/07/21 V1.5 Modified END   ===============================================================
      ln_support_qty          :=   ir_svf_data.customer_support_ss
                                 - ir_svf_data.customer_support_ss_b
                                 + ir_svf_data.ccm_sample_ship
                                 - ir_svf_data.ccm_sample_ship_b;           -- 16.���^���{����
      ln_sample_qty           :=   ir_svf_data.sample_quantity
                                 - ir_svf_data.sample_quantity_b
                                 + ir_svf_data.customer_sample_ship
                                 - ir_svf_data.customer_sample_ship_b;      -- 18.���{�o�ɐ���
      ln_disposal_qty         :=   ir_svf_data.removed_goods
                                 - ir_svf_data.removed_goods_b;             -- 20.�p�p�o�ɐ���
-- == 2009/06/26 V1.2 Modified START ===============================================================
--      ln_kuragae_ship_qty     :=   ir_svf_data.change_ship
--                                 + ir_svf_data.wear_increase;
      ln_kuragae_ship_qty     :=   ir_svf_data.change_ship;                 -- 22.�q�֏o�ɐ���
-- == 2009/06/26 V1.2 Modified END ===============================================================
      ln_hurikae_ship_qty     :=   ir_svf_data.goods_transfer_old;          -- 24.�U�֏o�ɐ���
      ln_factry_change_qty    :=   ir_svf_data.factory_change
                                 - ir_svf_data.factory_change_b;            -- 26.�H��q�֐���
      ln_factry_return_qty    :=   ir_svf_data.factory_return
                                 - ir_svf_data.factory_return_b;            -- 28.�H��ԕi����
      ln_payment_total_qty    :=   ir_svf_data.sales_shipped
                                 - ir_svf_data.sales_shipped_b
                                 - ir_svf_data.return_goods
                                 + ir_svf_data.return_goods_b
                                 + ir_svf_data.change_ship
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--                                 + ir_svf_data.wear_increase
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
                                 + ir_svf_data.goods_transfer_old
                                 + ir_svf_data.sample_quantity
                                 - ir_svf_data.sample_quantity_b
                                 + ir_svf_data.customer_sample_ship
                                 - ir_svf_data.customer_sample_ship_b
                                 + ir_svf_data.customer_support_ss
                                 - ir_svf_data.customer_support_ss_b
                                 + ir_svf_data.ccm_sample_ship
                                 - ir_svf_data.ccm_sample_ship_b
                                 + ir_svf_data.inventory_change_out
-- == 2009/06/26 V1.2 Added START ===============================================================
                                 - ir_svf_data.inventory_change_in
-- == 2009/06/26 V1.2 Added END   ===============================================================
                                 + ir_svf_data.factory_return
                                 - ir_svf_data.factory_return_b
                                 + ir_svf_data.factory_change
                                 - ir_svf_data.factory_change_b
                                 + ir_svf_data.removed_goods
                                 - ir_svf_data.removed_goods_b;             -- 30.���o���v����
      --
      ln_sales_ship_money     :=   ROUND(ln_sales_ship_qty     *  ir_svf_data.cost_amt);      -- 13.����o�ɋ��z
      ln_vd_ship_money        :=   ROUND(ln_vd_ship_qty        *  ir_svf_data.cost_amt);      -- 15.VD�o�ɋ��z
      ln_support_money        :=   ROUND(ln_support_qty        *  ir_svf_data.cost_amt);      -- 17.���^���{���z
      ln_sample_money         :=   ROUND(ln_sample_qty         *  ir_svf_data.cost_amt);      -- 19.���{�o�ɋ��z
      ln_disposal_money       :=   ROUND(ln_disposal_qty       *  ir_svf_data.cost_amt);      -- 21.�p�p�o�ɋ��z
      ln_kuragae_ship_money   :=   ROUND(ln_kuragae_ship_qty   *  ir_svf_data.cost_amt);      -- 23.�q�֏o�ɋ��z
      ln_hurikae_ship_money   :=   ROUND(ln_hurikae_ship_qty   *  ir_svf_data.cost_amt);      -- 25.�U�֏o�ɋ��z
      ln_factry_change_money  :=   ROUND(ln_factry_change_qty  *  ir_svf_data.cost_amt);      -- 27.�H��q�֋��z
      ln_factry_return_money  :=   ROUND(ln_factry_return_qty  *  ir_svf_data.cost_amt);      -- 29.�H��ԕi���z
      ln_payment_total_money  :=   ROUND(ln_payment_total_qty  *  ir_svf_data.cost_amt);      -- 31.���o���v���z
    END IF;
    --
    -- �}������
    INSERT INTO xxcoi_rep_base_detail_expend(
       slit_id                                  -- 01.���o�c�����ID
      ,output_kbn                               -- 02.�o�͋敪
      ,in_out_year                              -- 03.�N
      ,in_out_month                             -- 04.��
      ,cost_kbn                                 -- 05.�����敪
      ,base_code                                -- 06.���_�R�[�h
      ,base_name                                -- 07.���_��
      ,gun_code                                 -- 08.�Q�R�[�h
      ,item_code                                -- 09.���iCD
      ,item_name                                -- 10.���i��
      ,item_kbn                                 -- 11.���i�敪
      ,sales_ship_qty                           -- 12.����o�ɐ���
      ,sales_ship_money                         -- 13.����o�ɋ��z
      ,vd_ship_qty                              -- 14.VD�o�ɐ���
      ,vd_ship_money                            -- 15.VD�o�ɋ��z
      ,support_qty                              -- 16.���^���{����
      ,support_money                            -- 17.���^���{���z
      ,sample_qty                               -- 18.���{�o�ɐ���
      ,sample_money                             -- 19.���{�o�ɋ��z
      ,disposal_qty                             -- 20.�p�p�o�ɐ���
      ,disposal_money                           -- 21.�p�p�o�ɋ��z
      ,kuragae_ship_qty                         -- 22.�q�֏o�ɐ���
      ,kuragae_ship_money                       -- 23.�q�֏o�ɋ��z
      ,hurikae_ship_qty                         -- 24.�U�֏o�ɐ���
      ,hurikae_ship_money                       -- 25.�U�֏o�ɋ��z
      ,factry_change_qty                        -- 26.�H��q�֐���
      ,factry_change_money                      -- 27.�H��q�֋��z
      ,factry_return_qty                        -- 28.�H��ԕi����
      ,factry_return_money                      -- 29.�H��ԕi���z
      ,payment_total_qty                        -- 30.���o���v����
      ,payment_total_money                      -- 31.���o���v���z
      ,message                                  -- 32.���b�Z�[�W
      ,created_by                               -- 33.�쐬��
      ,creation_date                            -- 34.�쐬��
      ,last_updated_by                          -- 35.�ŏI�X�V��
      ,last_update_date                         -- 36.�ŏI�X�V��
      ,last_update_login                        -- 37.�ŏI�X�V���O�C��
      ,request_id                               -- 38.�v��ID
      ,program_application_id                   -- 39.�v���O�����A�v���P�[�V����ID
      ,program_id                               -- 40.�v���O����ID
      ,program_update_date                      -- 41.�v���O�����X�V��
    )VALUES(
       in_slit_id                               -- 01
      ,SUBSTRB(gt_output_kbn_type_name, 1, 8)   -- 02
      ,SUBSTRB(gv_param_reception_date, 3, 2)   -- 03
      ,SUBSTRB(gv_param_reception_date, 5, 2)   -- 04
      ,SUBSTRB(gt_cost_type_name, 1, 8)         -- 05
      ,lv_base_code                             -- 06
      ,lv_base_name                             -- 07
      ,lt_policy_group                          -- 08
      ,lt_item_code                             -- 09
      ,lt_item_short_name                       -- 10
      ,lt_item_type                             -- 11
      ,ln_sales_ship_qty                        -- 12
      ,ln_sales_ship_money                      -- 13
      ,ln_vd_ship_qty                           -- 14
      ,ln_vd_ship_money                         -- 15
      ,ln_support_qty                           -- 16
      ,ln_support_money                         -- 17
      ,ln_sample_qty                            -- 18
      ,ln_sample_money                          -- 19
      ,ln_disposal_qty                          -- 20
      ,ln_disposal_money                        -- 21
      ,ln_kuragae_ship_qty                      -- 22
      ,ln_kuragae_ship_money                    -- 23
      ,ln_hurikae_ship_qty                      -- 24
      ,ln_hurikae_ship_money                    -- 25
      ,ln_factry_change_qty                     -- 26
      ,ln_factry_change_money                   -- 27
      ,ln_factry_return_qty                     -- 28
      ,ln_factry_return_money                   -- 29
      ,ln_payment_total_qty                     -- 30
      ,ln_payment_total_money                   -- 31
      ,iv_message                               -- 32
      ,cn_created_by                            -- 33
      ,SYSDATE                                  -- 34
      ,cn_last_updated_by                       -- 35
      ,SYSDATE                                  -- 36
      ,cn_last_update_login                     -- 37
      ,cn_request_id                            -- 38
      ,cn_program_application_id                -- 39
      ,cn_program_id                            -- 40
      ,SYSDATE                                  -- 41
    );
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : valid_param_value
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE valid_param_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'valid_param_value'; -- �v���O������
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
    ld_dummy    DATE;           -- �_�~�[�ϐ�
    ln_dummy    NUMBER;         -- �_�~�[�ϐ�
    ln_cnt      NUMBER;         -- LOOP�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- ===============================
    --  1.�󕥔N���`�F�b�N
    -- ===============================
    BEGIN
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_type_month);
    EXCEPTION
      WHEN OTHERS THEN
        -- �󕥔N���^�`�F�b�N�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10110
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    IF (TO_CHAR(gd_f_process_date, cv_type_month) <= gv_param_reception_date) THEN
      -- �󕥔N�����Ɩ����t�ȍ~�̏ꍇ
      -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10111
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
-- == 2009/07/14 V1.4 Added START ===============================================================
    gd_target_date := LAST_DAY(ld_dummy);
-- == 2009/07/14 V1.4 Added END   ===============================================================
    -- ============================
    --  2.�p�����[�^.���_�`�F�b�N
    -- ============================
    IF  (gv_user_basecode <> gv_item_dept_base_code) THEN
      -- ���[�U�̏������_�����i���ȊO�̏ꍇ
      BEGIN
        SELECT  1
        INTO    ln_dummy
        FROM    hz_cust_accounts      hca                               -- �ڋq�}�X�^
               ,xxcmm_cust_accounts   xca                               -- �ڋq�ǉ����
        WHERE   hca.account_number        =   xca.management_base_code
        AND     hca.customer_class_code   =   cv_cust_cls_1
        AND     hca.status                =   cv_status_a
        AND     hca.account_number        =   gv_user_basecode          -- ���[�U�������_
        AND     ROWNUM  = 1;
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- �Ǘ��ۈȊO�̏ꍇ
          IF (gv_param_base_code IS NULL) THEN
            -- �p�����[�^.���_NULL�`�F�b�N�G���[���b�Z�[�W
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_10115
                           );
            lv_errbuf   := lv_errmsg;
            --
            RAISE global_process_expt;
          END IF;
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
  END valid_param_value;
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
    --  ������
    -- ===============================
    gd_f_process_date          :=  NULL;                 -- �Ɩ����t
    gt_output_kbn_type_name    :=  NULL;                 -- �o�͋敪��
    gt_cost_type_name          :=  NULL;                 -- �����敪��
    --
    -- ===============================
    --  1.�Ɩ����t�擾
    -- ===============================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF  (gd_f_process_date  IS NULL) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_00011
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  2.WHO�J�����ݒ�
    -- ===============================
    -- �O���[�o���萔�Ƃ��āA�錾���Őݒ肵�Ă��܂��B
    --
    -- ===============================
    --  3.���X�v���_�R�[�h�擾
    -- ===============================
    IF (gv_param_output_kbn = cv_output_kbn_60) THEN
      -- �o�͋敪�����X�v�̏ꍇ
      gv_param_base_code  :=  fnd_profile.value(cv_prf_name_sp_manage);
      --
      IF (gv_param_base_code IS NULL) THEN
        -- ���X�v���_�R�[�h�擾�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10117
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ===============================
    --  4.�S�ݓX�v���_�R�[�h�擾
    -- ===============================
    IF (gv_param_output_kbn = cv_output_kbn_70) THEN
      -- �o�͋敪���S�ݓX�v�̏ꍇ
      gv_param_base_code  :=  fnd_profile.value(cv_prf_name_dp_manage);
      --
      IF (gv_param_base_code IS NULL) THEN
        -- �S�ݓX�v���_�R�[�h�擾�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10118
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ===============================
    --  5.���i�����_�R�[�h�擾
    -- ===============================
    -- �o�͋敪�����_�ʂ̏ꍇ
    gv_item_dept_base_code  :=  fnd_profile.value(cv_prf_name_item_dept);
    --
    IF (gv_item_dept_base_code IS NULL) THEN
      -- ���i�����_�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10296
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  6.�p�����[�^���̎擾
    -- ===============================
    --�o�͋敪���̎擾
     gt_output_kbn_type_name   :=  xxcoi_common_pkg.get_meaning(cv_xxcoi1_output_div, gv_param_output_kbn);
    --
    IF  (gt_output_kbn_type_name  IS NULL) THEN
      -- �敪���擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10113
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    --�����敪���̎擾
    gt_cost_type_name   :=  xxcoi_common_pkg.get_meaning(cv_xxcoi_cost_price_div, gv_param_cost_type);
    --
    IF  (gt_cost_type_name  IS NULL) THEN
      -- �����敪���擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10114
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ================================
    --  7.���O�C�����[�U���_�R�[�h�擾
    -- ================================
    gv_user_basecode := xxcoi_common_pkg.get_base_code(cn_created_by,LAST_DAY(TO_DATE(gv_param_reception_date, cv_type_month)));
    IF (gv_user_basecode IS NULL) THEN
      -- ���[�U�[�̏������_�f�[�^���擾�ł��܂���ł����B
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi1_10116
                      );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  8.�N���p�����[�^���O�o��
    -- ===============================
    --�o�͋敪
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10098
                    ,iv_token_name1  => cv_token_10098_1
                    ,iv_token_value1 => gt_output_kbn_type_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �󕥔N��
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10107
                    ,iv_token_name1  => cv_token_10107_1
                    ,iv_token_value1 => gv_param_reception_date
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �����敪
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10108
                    ,iv_token_name1  => cv_token_10108_1
                    ,iv_token_value1 => gt_cost_type_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
     --���_
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10109
                    ,iv_token_name1  => cv_token_10109_1
                    ,iv_token_value1 => gv_param_base_code
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
    -- ===============================
    --  9.�i�ڃJ�e�S�����擾
    -- ===============================
      gv_item_category  :=  fnd_profile.value(cv_prf_name_category);
      --
      IF (gv_item_category IS NULL) THEN
        -- ���i���i�敪�J�e�S���Z�b�g���擾�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
-- == 2009/05/13 V1.1 Modified START ===============================================================
--                        ,iv_name         => cv_msg_xxcoi1_10146
                        ,iv_name         => cv_msg_xxcoi1_10382
-- == 2009/05/13 V1.1 Modified END   ===============================================================
                        ,iv_token_name1  => cv_token_10146_1
                        ,iv_token_value1 => cv_prf_name_category
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
      END IF;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn       IN  VARCHAR2,     -- 1.�o�͋敪
    iv_reception_date   IN  VARCHAR2,     -- 2.�󕥔N��
    iv_cost_type        IN  VARCHAR2,     -- 3.�����敪
    iv_base_code        IN  VARCHAR2,     -- 4.���_�R�[�h
    ov_errbuf           OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_zero_message     VARCHAR2(5000);
    -- �J�[�\������敪�p
    lv_cur_kbn          VARCHAR2(1);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
    svf_data_rec    svf_data_cur1%ROWTYPE;
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
    --  ������
    -- ===============================
    -- ���̓p�����[�^
    gv_param_output_kbn       :=  iv_output_kbn;        -- �o�͋敪
    gv_param_reception_date   :=  iv_reception_date;    -- �󕥔N��
    gv_param_cost_type        :=  iv_cost_type;         -- �����敪
    gv_param_base_code        :=  iv_base_code;         -- ���_
    --
    lv_zero_message   :=  NULL;
    --
    -- ===============================
    --  A-1.��������
    -- ===============================
    init(
       ov_errbuf    =>  lv_errbuf     --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode    --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-2.�p�����[�^�`�F�b�N
    -- ===============================
    valid_param_value(
       ov_errbuf    =>  lv_errbuf     --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode    --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-3.�f�[�^�擾�i�J�[�\���j
    -- ===============================
    -- �J�[�\������
    IF (    (gv_param_output_kbn IN(cv_output_kbn_30, cv_output_kbn_40, cv_output_kbn_50))
        AND (gv_param_base_code  IS NOT NULL)
       )
    THEN
      -- ���_�ʁA���X�ʁA�S�ݓX�ʂ̂��Âꂩ�A���A���_���ݒ肳��Ă���ꍇ
      lv_cur_kbn  :=  cv_cur_kbn_1;
      --
    ELSIF (gv_param_output_kbn  = cv_output_kbn_80) THEN
      -- ���c�X�v�̏ꍇ
      lv_cur_kbn  :=  cv_cur_kbn_2;
      --
    ELSIF (   (gv_param_output_kbn  IN(cv_output_kbn_60, cv_output_kbn_70))
           OR (    (   (gv_param_output_kbn IN(cv_output_kbn_40, cv_output_kbn_50))
                    OR (     gv_param_output_kbn = cv_output_kbn_30
                        AND  gv_user_basecode <> gv_item_dept_base_code
                       )
                   )
               AND (gv_param_base_code  IS NULL)
              )
          )
    THEN
      -- ���X�v�A�S�ݓX�v�A���́A
      -- ���_�ʁi���i���ȊO�j�A���X�ʁA�S�ݓX�ʂ̂��Âꂩ�A���A���_���ݒ肳��Ă��Ȃ��ꍇ
      lv_cur_kbn  :=  cv_cur_kbn_3;
      --
    ELSIF (   (gv_param_output_kbn  = cv_output_kbn_90)
           OR (     gv_param_output_kbn = cv_output_kbn_30
               AND  gv_user_basecode = gv_item_dept_base_code
               AND  gv_param_base_code IS NULL
              )
          )
    THEN
      -- �S�Ќv�A����
      -- ���_�ʁi���i���j�A���A���_���ݒ肳��Ă��Ȃ��ꍇ
      lv_cur_kbn  :=  cv_cur_kbn_4;
      --
    END IF;
    --
    IF (lv_cur_kbn  = cv_cur_kbn_1) THEN      -- �f�[�^�擾�p�^�[���P
      OPEN  svf_data_cur1;
      FETCH svf_data_cur1  INTO  svf_data_rec;
      -- �o�͑Ώۃf�[�^�O��
      IF (svf_data_cur1%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_2) THEN      -- �f�[�^�擾�p�^�[���Q
      OPEN  svf_data_cur2;
      FETCH svf_data_cur2  INTO  svf_data_rec;
      -- �o�͑Ώۃf�[�^�O��
      IF (svf_data_cur2%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_3) THEN      -- �f�[�^�擾�p�^�[���R
      OPEN  svf_data_cur3;
      FETCH svf_data_cur3  INTO  svf_data_rec;
      -- �o�͑Ώۃf�[�^�O��
      IF (svf_data_cur3%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    ELSIF (lv_cur_kbn  = cv_cur_kbn_4) THEN      -- �f�[�^�擾�p�^�[���S
      OPEN  svf_data_cur4;
      FETCH svf_data_cur4  INTO  svf_data_rec;
      -- �o�͑Ώۃf�[�^�O��
      IF (svf_data_cur4%NOTFOUND) THEN
        lv_zero_message := xxccp_common_pkg.get_msg(
                             iv_application  => cv_short_name_xxcoi
                            ,iv_name         => cv_msg_xxcoi1_00008
                           );
      END IF;
      --
    END IF;
    --
    <<work_ins_loop>>
    LOOP
      -- �Ώی����J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- ===============================
      --  A-4.���[�N�e�[�u���f�[�^�o�^
      -- ===============================
      ins_svf_data(
         ir_svf_data  =>  svf_data_rec    -- CSV�o�͗p�f�[�^
        ,in_slit_id   =>  gn_target_cnt   -- �����A��
        ,iv_message   =>  lv_zero_message -- �O�����b�Z�[�W
        ,ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[����
        RAISE global_process_expt;
      END IF;
      --
      -- �Ώۃf�[�^�O���̏ꍇ�A���[�N�e�[�u���쐬�����I��
      EXIT  work_ins_loop WHEN  lv_zero_message IS NOT NULL;
      --
      -- �Ώۃf�[�^�擾
      IF (lv_cur_kbn  =  cv_cur_kbn_1)  THEN
        FETCH svf_data_cur1  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur1%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_2)  THEN
        FETCH svf_data_cur2  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur2%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_3)  THEN
        FETCH svf_data_cur3  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur3%NOTFOUND;
        --
      ELSIF (lv_cur_kbn  =  cv_cur_kbn_4)  THEN
        FETCH svf_data_cur4  INTO  svf_data_rec;
        EXIT  work_ins_loop  WHEN  svf_data_cur4%NOTFOUND;
        --
      END IF;
      --
    END LOOP work_ins_loop;
    --
    -- �J�[�\���N���[�Y
    IF (lv_cur_kbn  =  cv_cur_kbn_1)  THEN
      CLOSE svf_data_cur1;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_2)  THEN
      CLOSE svf_data_cur2;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_3)  THEN
      CLOSE svf_data_cur3;
      --
    ELSIF (lv_cur_kbn  =  cv_cur_kbn_4)  THEN
      CLOSE svf_data_cur4;
      --
    END IF;
    --
    -- �R�~�b�g����
    COMMIT;
    --
    -- ===============================
    --  A-5.SVF�N��
    -- ===============================
    call_output_svf(
       ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  A-6.���[�N�e�[�u���f�[�^�폜
    -- ===============================
    del_svf_data(
       ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ����I������
    IF (lv_zero_message IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
    END IF;
    --
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur1%ISOPEN) THEN
         CLOSE svf_data_cur1;
      ELSIF (svf_data_cur2%ISOPEN) THEN
         CLOSE svf_data_cur2;
      ELSIF (svf_data_cur3%ISOPEN) THEN
         CLOSE svf_data_cur3;
      ELSIF (svf_data_cur4%ISOPEN) THEN
         CLOSE svf_data_cur4;
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
    iv_output_kbn       IN  VARCHAR2,       -- 1.�o�͋敪
    iv_reception_date   IN  VARCHAR2,       -- 2.�󕥔N��
    iv_cost_type        IN  VARCHAR2,       -- 3.�����敪
    iv_base_code        IN  VARCHAR2        -- 4.���_�R�[�h
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
       iv_output_kbn      =>  iv_output_kbn       -- 1.�o�͋敪
      ,iv_reception_date  =>  iv_reception_date   -- 2.�󕥔N��
      ,iv_cost_type       =>  iv_cost_type        -- 3.�����敪
      ,iv_base_code       =>  iv_base_code        -- 4.���_�R�[�h
      ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCOI006A18R;
/
