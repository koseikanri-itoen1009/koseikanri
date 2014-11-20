CREATE OR REPLACE PACKAGE BODY XXCOI006A23C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A23C(body)
 * Description      : VD�󕥏������ɁACSV�f�[�^���쐬���܂��B
 * MD.050           : VD��CSV�쐬<MD050_COI_006_A23>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  out_csv_company_total  VD��CSV�f�[�^���o                  (A-3)
 *                         VD��CSV�ҏW�E�v���o��              (A-4)
 *  out_csv_base_total     VD��CSV�f�[�^���o                  (A-3)
 *                         VD��CSV�ҏW�E�v���o��              (A-4)
 *  out_csv_base           VD��CSV�f�[�^���o                  (A-3)
 *                         VD��CSV�ҏW�E�v���o��              (A-4)
 *  chk_parameter          �p�����[�^�`�F�b�N                   (A-2)
 *  init                   ��������                             (A-1)
 *  submain                ���C�������v���V�[�W��
 *                         �I������                             (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/10    1.0   H.Sasaki         ���ō쐬
 *  2009/07/14    1.1   N.Abe            [0000462]�Q�R�[�h�擾���@�C��
 *  2009/09/08    1.2   H.Sasaki         [0001266]OPM�i�ڃA�h�I���̔ŊǗ��Ή�
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
  csv_no_data_expt          EXCEPTION;      -- CSV�Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A23C'; -- �p�b�P�[�W��
  -- ���t�^
  cv_date               CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  -- �Q�ƃ^�C�v
  cv_type_output_div    CONSTANT VARCHAR2(30) :=  'XXCOI1_VD_REP_OUTPUT_DIV';       -- VD�󕥕\�o�͋敪
  cv_type_cost_price    CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';          -- �����敪
  cv_type_list_header   CONSTANT VARCHAR2(30) :=  'XXCOI1_VD_IN_OUT_LIST_HEADER';   -- VD�󕥕\���o��
  -- VD�󕥕\�o�͋敪�i1:���_�ʁA2�F���_�ʌv�A3�F�S�Ќv�j
  cv_output_div_1       CONSTANT VARCHAR2(3)  :=  '1';
  cv_output_div_2       CONSTANT VARCHAR2(3)  :=  '2';
  cv_output_div_3       CONSTANT VARCHAR2(3)  :=  '3';
  -- �����敪�i10:�c�ƌ����A20�F�W�������j
  cv_cost_price_10      CONSTANT VARCHAR2(2)  :=  '10';
  cv_cost_price_20      CONSTANT VARCHAR2(2)  :=  '20';
  -- VD�󕥕\���o��
  cv_list_header_1      CONSTANT VARCHAR2(1)  :=  '1';
  -- ���b�Z�[�W�֘A
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00008   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00008';     -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10098   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10098';     -- �p�����[�^�o�͋敪�l���b�Z�[�W
  cv_msg_xxcoi1_10107   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10107';     -- �p�����[�^�󕥔N���l���b�Z�[�W
  cv_msg_xxcoi1_10108   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10108';     -- �p�����[�^�����敪�l���b�Z�[�W
  cv_msg_xxcoi1_10109   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10109';     -- �p�����[�^���_�l���b�Z�[�W
  cv_msg_xxcoi1_10110   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10110';     -- �󕥔N���̌^�iYYYYMM�j�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10111   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10111';     -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10113   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10113';     -- �p�����[�^.�o�͋敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10114   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10114';     -- �p�����[�^.�����敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10370   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10370';     -- ���o�����擾�G���[���b�Z�[�W
  cv_token_10098_1      CONSTANT VARCHAR2(30) :=  'P_OUT_TYPE';
  cv_token_10107_1      CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';
  cv_token_10108_1      CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';
  cv_token_10109_1      CONSTANT VARCHAR2(30) :=  'P_BASE_CODE';
  -- ���̑�
  cv_log                CONSTANT VARCHAR2(3)  :=  'LOG';                  -- �R���J�����g�w�b�_�o�͐�
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                    -- ���p�X�y�[�X�P��
  cv_class_base         CONSTANT VARCHAR2(1)  :=  '1';                    -- �ڋq�敪�F���_
  cv_status_active      CONSTANT VARCHAR2(1)  :=  'A';                    -- �ڋq�X�e�[�^�X�FActive
  cv_separate_code      CONSTANT VARCHAR2(1)  :=  ',';                    -- ��؂蕶���i�J���}�j
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE csv_data_type  IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
  gt_csv_data         csv_data_type;                  -- CSV�f�[�^
  TYPE csv_total_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_key_total        csv_total_type;                 -- �L�[���ڌv
  gt_key2_total       csv_total_type;                 -- �L�[���ڌv2
  gt_total            csv_total_type;                 -- ���v
  gr_lookup_values   xxcoi_common_pkg.lookup_rec;     -- �N�C�b�N�R�[�h�}�X�^���i�[���R�[�h
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_param_output_kbn         VARCHAR2(3);        -- �󕥕\�o�͋敪
  gv_param_reception_date     VARCHAR2(6);        -- �󕥔N��
  gv_param_cost_kbn           VARCHAR2(2);        -- �����敪
  gv_param_base_code          VARCHAR2(4);        -- ���_
  -- ���������ݒ�l
  gd_f_process_date           DATE;               -- �Ɩ��������t
  gt_output_name              fnd_lookup_values.meaning%TYPE;     -- �󕥕\�o�͋敪��
  gt_cost_kbn_name            fnd_lookup_values.meaning%TYPE;     -- �����敪��
-- == 2009/07/13 V1.1 Added START ===============================================================
  gd_target_date              DATE;
-- == 2009/07/13 V1.1 Added END   ===============================================================
--
  -- ===============================
  -- �J�[�\����`
  -- ===============================
  -- VD��CSV�f�[�^���o�i���_�ʁA���_�ʌv�j
  CURSOR  base_cur
  IS
    SELECT  xvri.base_code                    base_code                         -- ���_�R�[�h
           ,xvri.practice_date                practice_date                     -- �N��
           ,xvri.month_begin_quantity         month_begin_quantity              -- ����݌�
           ,xvri.vd_stock                     vd_stock                          -- �x���_����
           ,xvri.vd_move_stock                vd_move_stock                     -- �x���_�ړ�����
           ,xvri.vd_ship                      vd_ship                           -- �x���_�o��
           ,xvri.vd_move_ship                 vd_move_ship                      -- �x���_�ړ��o��
           ,xvri.month_end_book_remain_qty    month_end_book_remain_qty         -- ��������c
           ,xvri.month_end_quantity           month_end_quantity                -- �����݌�
           ,xvri.inv_wear_account             inv_wear_account                  -- �I�����Ք�
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_begin_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_begin_quantity)
            END                               month_begin_money                 -- ����݌Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_stock)
            END                               vd_stock_money                    -- �x���_���Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_stock)
            END                               vd_move_stock_money               -- �x���_�ړ����Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_ship)
            END                               vd_ship_money                     -- �x���_�o�Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_ship)
            END                               vd_move_ship_money                -- �x���_�ړ��o�Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_book_remain_qty)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_book_remain_qty)
            END                               month_end_book_remain_money       -- ��������c�i���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_quantity)
            END                               month_end_money                   -- �����݌Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.inv_wear_account)
              ELSE ROUND(xvri.standard_cost  * xvri.inv_wear_account)
            END                               inv_wear_account_money            -- �I�����Ք�i���z�j
           ,hca.account_name                  account_name                      -- ���_��
-- == 2009/07/13 V1.1 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)     gun_code                          -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                      -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                      -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                 gun_code                          -- �Q�R�[�h
-- == 2009/07/13 V1.1 Modified END   ===============================================================
           ,msib.segment1                     segment1                          -- ���i�R�[�h
           ,ximb.item_short_name              item_short_name                   -- �i��
    FROM    xxcoi_vd_reception_info       xvri                                  -- VD�󕥏��e�[�u��
           ,hz_cust_accounts              hca                                   -- �ڋq�}�X�^
           ,mtl_system_items_b            msib                                  -- Disc�i�ڃ}�X�^
           ,ic_item_mst_b                 iimb                                  -- OPM�i��
           ,xxcmn_item_mst_b              ximb                                  -- OPM�i�ڃA�h�I��
    WHERE   ((    (gv_param_base_code IS NOT NULL)
              AND (xvri.base_code = gv_param_base_code)
             )
             OR
             (gv_param_base_code IS NULL)
            )
    AND     xvri.practice_date        =   gv_param_reception_date
    AND     xvri.base_code            =   hca.account_number
    AND     hca.customer_class_code   =   cv_class_base
    AND     hca.status                =   cv_status_active
    AND     xvri.inventory_item_id    =   msib.inventory_item_id
    AND     xvri.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   ximb.item_id
-- == 2009/09/08 V1.2 Added START ===============================================================
    AND     gd_target_date  BETWEEN ximb.start_date_active
                            AND     NVL(ximb.end_date_active, gd_target_date)
-- == 2009/09/08 V1.2 Added END   ===============================================================
    ORDER BY  xvri.base_code
             ,iimb.attribute2
             ,msib.segment1;
  --
  -- VD��CSV�f�[�^���o�i�S�Ќv�j
  CURSOR  company_cur
  IS
    SELECT  xvri.base_code                    base_code                         -- ���_�R�[�h
           ,xvri.practice_date                practice_date                     -- �N��
           ,xvri.month_begin_quantity         month_begin_quantity              -- ����݌�
           ,xvri.vd_stock                     vd_stock                          -- �x���_����
           ,xvri.vd_move_stock                vd_move_stock                     -- �x���_�ړ�����
           ,xvri.vd_ship                      vd_ship                           -- �x���_�o��
           ,xvri.vd_move_ship                 vd_move_ship                      -- �x���_�ړ��o��
           ,xvri.month_end_book_remain_qty    month_end_book_remain_qty         -- ��������c
           ,xvri.month_end_quantity           month_end_quantity                -- �����݌�
           ,xvri.inv_wear_account             inv_wear_account                  -- �I�����Ք�
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_begin_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_begin_quantity)
            END                               month_begin_money                 -- ����݌Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_stock)
            END                               vd_stock_money                    -- �x���_���Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_stock)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_stock)
            END                               vd_move_stock_money               -- �x���_�ړ����Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_ship)
            END                               vd_ship_money                     -- �x���_�o�Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.vd_move_ship)
              ELSE ROUND(xvri.standard_cost  * xvri.vd_move_ship)
            END                               vd_move_ship_money                -- �x���_�ړ��o�Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_book_remain_qty)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_book_remain_qty)
            END                               month_end_book_remain_money       -- ��������c�i���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.month_end_quantity)
              ELSE ROUND(xvri.standard_cost  * xvri.month_end_quantity)
            END                               month_end_money                   -- �����݌Ɂi���z�j
           ,CASE gv_param_cost_kbn WHEN cv_cost_price_10
              THEN ROUND(xvri.operation_cost * xvri.inv_wear_account)
              ELSE ROUND(xvri.standard_cost  * xvri.inv_wear_account)
            END                               inv_wear_account_money            -- �I�����Ք�i���z�j
           ,hca.account_name                  account_name                      -- ���_��
-- == 2009/07/14 V1.1 Modified START ===============================================================
--           ,SUBSTR(iimb.attribute2, 1, 3)     gun_code                          -- �Q�R�[�h
           ,SUBSTR(
              (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                      THEN iimb.attribute1                                      -- �Q�R�[�h(��)
                      ELSE iimb.attribute2                                      -- �Q�R�[�h(�V)
                    END
              ), 1, 3
            )                                 gun_code                          -- �Q�R�[�h
-- == 2009/07/14 V1.1 Modified END   ===============================================================
           ,msib.segment1                     segment1                          -- ���i�R�[�h
           ,ximb.item_short_name              item_short_name                   -- �i��
    FROM    xxcoi_vd_reception_info       xvri                                  -- VD�󕥏��e�[�u��
           ,hz_cust_accounts              hca                                   -- �ڋq�}�X�^
           ,mtl_system_items_b            msib                                  -- Disc�i�ڃ}�X�^
           ,ic_item_mst_b                 iimb                                  -- OPM�i��
           ,xxcmn_item_mst_b              ximb                                  -- OPM�i�ڃA�h�I��
    WHERE   ((    (gv_param_base_code IS NOT NULL)
              AND (xvri.base_code = gv_param_base_code)
             )
             OR
             (gv_param_base_code IS NULL)
            )
    AND     xvri.practice_date        =   gv_param_reception_date
    AND     xvri.base_code            =   hca.account_number
    AND     hca.customer_class_code   =   cv_class_base
    AND     hca.status                =   cv_status_active
    AND     xvri.inventory_item_id    =   msib.inventory_item_id
    AND     xvri.organization_id      =   msib.organization_id
    AND     msib.segment1             =   iimb.item_no
    AND     iimb.item_id              =   ximb.item_id
-- == 2009/09/08 V1.2 Added START ===============================================================
    AND     gd_target_date  BETWEEN ximb.start_date_active
                            AND     NVL(ximb.end_date_active, gd_target_date)
-- == 2009/09/08 V1.2 Added END   ===============================================================
    ORDER BY  iimb.attribute2
             ,msib.segment1;
    --
    --
  vd_data_rec      base_cur%ROWTYPE;
  --
  --
  /**********************************************************************************
   * Procedure Name   : out_csv_company_total
   * Description      : VD��CSV�ҏW�E�v���o�́i�S�Ќv�j(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_company_total(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_company_total'; -- �v���O������
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
    ln_cnt              NUMBER;                                 -- CSV���R�[�h�s�ԍ�
    lt_segment1         mtl_system_items_b.segment1%TYPE;       -- ���R�[�h�ύX�`�F�b�N�L�[���ځi�i�ڃR�[�h�j
    lv_gun_code         VARCHAR2(3);                            -- ���R�[�h�ύX�`�F�b�N�L�[���ځi�Q�R�[�h�j
    lt_item_short_name  xxcmn_item_mst_b.item_short_name%TYPE;  -- �i��
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
    OPEN  company_cur;
    FETCH company_cur  INTO  vd_data_rec;
    --
    IF (company_cur%NOTFOUND) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- �Ώۃf�[�^���擾����Ȃ������ꍇ�A�������I��
      CLOSE company_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  �P�s�ڕҏW�i�w�b�_���j
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- �󕥔N���i�N�j
                        || gr_lookup_values.attribute1                -- ���o���P
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- �󕥔N���i���j
                        || gr_lookup_values.attribute2                -- ���o���Q
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- ���o���R
                        || cv_separate_code
                        || gt_output_name                             -- �󕥏o�͋敪��
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- �����敪��
    --
    -- ===================================
    --  �Q�s�ڕҏW�i���ږ��j
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute8               -- ���o���W
                        ||  gr_lookup_values.attribute9               -- ���o���X
                        ||  gr_lookup_values.attribute10              -- ���o���P�O
                        ||  gr_lookup_values.attribute11;             -- ���o���P�P
    --
    -- ===================================
    --  �R�s�ڈȍ~�ҏW�i���l�f�[�^�j
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- �i�ڌv�ݒ�
      IF (    (lt_segment1 IS NOT NULL)
          AND (    (vd_data_rec.segment1 <>  lt_segment1)
               OR  (company_cur%NOTFOUND)
              )
         )
      THEN
        -- �i�ڃR�[�h���ς����ꍇ�A���͍ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     lv_gun_code                      -- �Q�R�[�h
                                || cv_separate_code
                                || lt_segment1                      -- �i�ڃR�[�h
                                || cv_separate_code
                                || lt_item_short_name               -- �i��
                                || cv_separate_code
                                || gt_key_total(1)                  -- ����݌�
                                || cv_separate_code
                                || gt_key_total(2)                  -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(3)                  -- �x���_����
                                || cv_separate_code
                                || gt_key_total(4)                  -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(5)                  -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_key_total(6)                  -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(7)                  -- �x���_�o��
                                || cv_separate_code
                                || gt_key_total(8)                  -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(9)                  -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_key_total(10)                 -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(11)                 -- ��������c
                                || cv_separate_code
                                || gt_key_total(12)                 -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_key_total(13)                 -- �����݌�
                                || cv_separate_code
                                || gt_key_total(14)                 -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(15)                 -- �I�����Ք�
                                || cv_separate_code
                                || gt_key_total(16);                -- �I�����Ք�i���z�j
        --
        -- �ϐ��J�E���g�A�b�v
        ln_cnt  :=  ln_cnt + 1;
        --
        -- ���_�v������
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- �Q�v�ݒ�
      IF (    (lv_gun_code IS NOT NULL)
          AND (    (vd_data_rec.gun_code <>  lv_gun_code)
               OR  (company_cur%NOTFOUND)
              )
         )
      THEN
        -- �Q�R�[�h���ς����ꍇ�A���͍ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute4      -- ���o���S
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_key2_total(1)                 -- ����݌�
                                || cv_separate_code
                                || gt_key2_total(2)                 -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(3)                 -- �x���_����
                                || cv_separate_code
                                || gt_key2_total(4)                 -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(5)                 -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_key2_total(6)                 -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(7)                 -- �x���_�o��
                                || cv_separate_code
                                || gt_key2_total(8)                 -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(9)                 -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_key2_total(10)                -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(11)                -- ��������c
                                || cv_separate_code
                                || gt_key2_total(12)                -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_key2_total(13)                -- �����݌�
                                || cv_separate_code
                                || gt_key2_total(14)                -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key2_total(15)                -- �I�����Ք�
                                || cv_separate_code
                                || gt_key2_total(16);               -- �I�����Ք�i���z�j
        --
        -- �ϐ��J�E���g�A�b�v
        ln_cnt  :=  ln_cnt + 1;
        --
        -- ���_�v������
        FOR i IN 1 .. 16 LOOP
          gt_key2_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- ���v�ݒ�
      IF (company_cur%NOTFOUND) THEN
        -- �ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- ���o���T
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- ����݌�
                                || cv_separate_code
                                || gt_total(2)                      -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(3)                      -- �x���_����
                                || cv_separate_code
                                || gt_total(4)                      -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_total(5)                      -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_total(6)                      -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_total(7)                      -- �x���_�o��
                                || cv_separate_code
                                || gt_total(8)                      -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(9)                      -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_total(10)                     -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(11)                     -- ��������c
                                || cv_separate_code
                                || gt_total(12)                     -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_total(13)                     -- �����݌�
                                || cv_separate_code
                                || gt_total(14)                     -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(15)                     -- �I�����Ք�
                                || cv_separate_code
                                || gt_total(16);                    -- �I�����Ք�i���z�j
        --
      END IF;
      --
      -- �I������
      EXIT set_csv_base_loop  WHEN  company_cur%NOTFOUND;
      --
      -- �i�ڌv�擾
      gt_key_total(1)   :=  gt_key_total(1)   +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_key_total(2)   :=  gt_key_total(2)   +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_key_total(3)   :=  gt_key_total(3)   +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_key_total(4)   :=  gt_key_total(4)   +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_key_total(5)   :=  gt_key_total(5)   +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_key_total(6)   :=  gt_key_total(6)   +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_key_total(7)   :=  gt_key_total(7)   +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_key_total(8)   :=  gt_key_total(8)   +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_key_total(9)   :=  gt_key_total(9)   +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_key_total(10)  :=  gt_key_total(10)  +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_key_total(11)  :=  gt_key_total(11)  +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_key_total(12)  :=  gt_key_total(12)  +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_key_total(13)  :=  gt_key_total(13)  +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_key_total(14)  :=  gt_key_total(14)  +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_key_total(15)  :=  gt_key_total(15)  +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_key_total(16)  :=  gt_key_total(16)  +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- �Q�v�擾
      gt_key2_total(1)  :=  gt_key2_total(1)  +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_key2_total(2)  :=  gt_key2_total(2)  +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_key2_total(3)  :=  gt_key2_total(3)  +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_key2_total(4)  :=  gt_key2_total(4)  +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_key2_total(5)  :=  gt_key2_total(5)  +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_key2_total(6)  :=  gt_key2_total(6)  +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_key2_total(7)  :=  gt_key2_total(7)  +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_key2_total(8)  :=  gt_key2_total(8)  +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_key2_total(9)  :=  gt_key2_total(9)  +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_key2_total(10) :=  gt_key2_total(10) +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_key2_total(11) :=  gt_key2_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_key2_total(12) :=  gt_key2_total(12) +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_key2_total(13) :=  gt_key2_total(13) +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_key2_total(14) :=  gt_key2_total(14) +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_key2_total(15) :=  gt_key2_total(15) +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_key2_total(16) :=  gt_key2_total(16) +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���v�擾
      gt_total(1)       :=  gt_total(1)       +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_total(2)       :=  gt_total(2)       +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_total(3)       :=  gt_total(3)       +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_total(4)       :=  gt_total(4)       +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_total(5)       :=  gt_total(5)       +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_total(6)       :=  gt_total(6)       +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_total(7)       :=  gt_total(7)       +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_total(8)       :=  gt_total(8)       +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_total(9)       :=  gt_total(9)       +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_total(10)      :=  gt_total(10)      +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_total(11)      :=  gt_total(11)      +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_total(12)      :=  gt_total(12)      +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_total(13)      :=  gt_total(13)      +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_total(14)      :=  gt_total(14)      +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_total(15)      :=  gt_total(15)      +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_total(16)      :=  gt_total(16)      +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���R�[�h�ύX�`�F�b�N�p�ϐ��ێ�
      lt_segment1         :=  vd_data_rec.segment1;
      lv_gun_code         :=  vd_data_rec.gun_code;
      lt_item_short_name  :=  vd_data_rec.item_short_name;
      --
      -- ���������J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- �f�[�^�擾
      FETCH company_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE company_cur;
    --
    -- ===================================
    --  CSV�o��
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** CSV�Ώۃf�[�^�Ȃ���O ***
    WHEN csv_no_data_expt THEN
      -- ����ŁA�{�v���V�[�W�����I��
      NULL;
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
      IF (company_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_company_total;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base_total
   * Description      : VD��CSV�ҏW�E�v���o�́i���_�ʌv�j(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base_total(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base_total'; -- �v���O������
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
    ln_cnt        NUMBER;                                 -- CSV���R�[�h�s�ԍ�
    lt_base_code  xxcoi_vd_reception_info.base_code%TYPE; -- ���R�[�h�ύX�`�F�b�N�L�[���ځi���_�R�[�h�j
    lt_base_name  hz_cust_accounts.account_name%TYPE;     -- ���_��
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
    OPEN  base_cur;
    FETCH base_cur  INTO  vd_data_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- �Ώۃf�[�^���擾����Ȃ������ꍇ�A�������I��
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  �P�s�ڕҏW�i�w�b�_���j
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- �󕥔N���i�N�j
                        || gr_lookup_values.attribute1                -- ���o���P
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- �󕥔N���i���j
                        || gr_lookup_values.attribute2                -- ���o���Q
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- ���o���R
                        || cv_separate_code
                        || gt_output_name                             -- �󕥏o�͋敪��
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- �����敪��
    --
    -- ===================================
    --  �Q�s�ڕҏW�i���ږ��j
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute7               -- ���o���V
                        ||  gr_lookup_values.attribute9               -- ���o���X
                        ||  gr_lookup_values.attribute10              -- ���o���P�O
                        ||  gr_lookup_values.attribute11;             -- ���o���P�P
    --
    -- ===================================
    --  �R�s�ڈȍ~�ҏW�i���l�f�[�^�j
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- ���_�v�ݒ�
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- ���_�R�[�h���ς����ꍇ�A���͍ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     lt_base_code                     -- ���_�R�[�h
                                || cv_separate_code
                                || lt_base_name                     -- ���_��
                                || cv_separate_code
                                || gt_key_total(1)                  -- ����݌�
                                || cv_separate_code
                                || gt_key_total(2)                  -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(3)                  -- �x���_����
                                || cv_separate_code
                                || gt_key_total(4)                  -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(5)                  -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_key_total(6)                  -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(7)                  -- �x���_�o��
                                || cv_separate_code
                                || gt_key_total(8)                  -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(9)                  -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_key_total(10)                 -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(11)                 -- ��������c
                                || cv_separate_code
                                || gt_key_total(12)                 -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_key_total(13)                 -- �����݌�
                                || cv_separate_code
                                || gt_key_total(14)                 -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(15)                 -- �I�����Ք�
                                || cv_separate_code
                                || gt_key_total(16);                -- �I�����Ք�i���z�j
        --
        -- �ϐ��J�E���g�A�b�v
        ln_cnt  :=  ln_cnt + 1;
        --
        -- ���_�v������
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- ���v�ݒ�
      IF (base_cur%NOTFOUND) THEN
        -- �ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- ���o���T
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- ����݌�
                                || cv_separate_code
                                || gt_total(2)                      -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(3)                      -- �x���_����
                                || cv_separate_code
                                || gt_total(4)                      -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_total(5)                      -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_total(6)                      -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_total(7)                      -- �x���_�o��
                                || cv_separate_code
                                || gt_total(8)                      -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(9)                      -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_total(10)                     -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(11)                     -- ��������c
                                || cv_separate_code
                                || gt_total(12)                     -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_total(13)                     -- �����݌�
                                || cv_separate_code
                                || gt_total(14)                     -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(15)                     -- �I�����Ք�
                                || cv_separate_code
                                || gt_total(16);                    -- �I�����Ք�i���z�j
        --
      END IF;
      --
      -- �I������
      EXIT set_csv_base_loop  WHEN  base_cur%NOTFOUND;
      --
      -- ���_�v�擾
      gt_key_total(1)   :=  gt_key_total(1)  +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_key_total(2)   :=  gt_key_total(2)  +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_key_total(3)   :=  gt_key_total(3)  +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_key_total(4)   :=  gt_key_total(4)  +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_key_total(5)   :=  gt_key_total(5)  +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_key_total(6)   :=  gt_key_total(6)  +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_key_total(7)   :=  gt_key_total(7)  +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_key_total(8)   :=  gt_key_total(8)  +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_key_total(9)   :=  gt_key_total(9)  +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_key_total(10)  :=  gt_key_total(10) +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_key_total(11)  :=  gt_key_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_key_total(12)  :=  gt_key_total(12) +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_key_total(13)  :=  gt_key_total(13) +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_key_total(14)  :=  gt_key_total(14) +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_key_total(15)  :=  gt_key_total(15) +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_key_total(16)  :=  gt_key_total(16) +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���v�擾
      gt_total(1)       :=  gt_total(1)      +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_total(2)       :=  gt_total(2)      +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_total(3)       :=  gt_total(3)      +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_total(4)       :=  gt_total(4)      +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_total(5)       :=  gt_total(5)      +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_total(6)       :=  gt_total(6)      +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_total(7)       :=  gt_total(7)      +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_total(8)       :=  gt_total(8)      +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_total(9)       :=  gt_total(9)      +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_total(10)      :=  gt_total(10)     +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_total(11)      :=  gt_total(11)     +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_total(12)      :=  gt_total(12)     +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_total(13)      :=  gt_total(13)     +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_total(14)      :=  gt_total(14)     +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_total(15)      :=  gt_total(15)     +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_total(16)      :=  gt_total(16)     +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���R�[�h�ύX�`�F�b�N�p�ϐ��ێ�
      lt_base_code  :=  vd_data_rec.base_code;
      lt_base_name  :=  vd_data_rec.account_name;
      --
      -- ���������J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- �f�[�^�擾
      FETCH base_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV�o��
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** CSV�Ώۃf�[�^�Ȃ���O ***
    WHEN csv_no_data_expt THEN
      -- ����ŁA�{�v���V�[�W�����I��
      NULL;
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_base_total;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_base
   * Description      : VD��CSV�ҏW�E�v���o�́i���_�ʁj(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_base(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_base'; -- �v���O������
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
    ln_cnt        NUMBER;                                 -- CSV���R�[�h�s�ԍ�
    lt_base_code  xxcoi_vd_reception_info.base_code%TYPE; -- ���R�[�h�ύX�`�F�b�N�L�[���ځi���_�R�[�h�j
    lv_gun_code   VARCHAR2(3);                            -- ���R�[�h�ύX�`�F�b�N�L�[���ځi�Q�R�[�h�j
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
    OPEN  base_cur;
    FETCH base_cur  INTO  vd_data_rec;
    --
    IF (base_cur%NOTFOUND) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      gv_out_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00008
                     );
      --
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
      --
      -- �Ώۃf�[�^���擾����Ȃ������ꍇ�A�������I��
      CLOSE base_cur;
      RAISE csv_no_data_expt;
    END IF;
    --
    -- ===================================
    --  �P�s�ڕҏW�i�w�b�_���j
    -- ===================================
    gt_csv_data(1)  :=     SUBSTRB(gv_param_reception_date, 3, 2)     -- �󕥔N���i�N�j
                        || gr_lookup_values.attribute1                -- ���o���P
                        || SUBSTRB(gv_param_reception_date, 5, 2)     -- �󕥔N���i���j
                        || gr_lookup_values.attribute2                -- ���o���Q
                        || cv_separate_code
                        || gr_lookup_values.attribute3                -- ���o���R
                        || cv_separate_code
                        || gt_output_name                             -- �󕥏o�͋敪��
                        || cv_separate_code
                        || gt_cost_kbn_name;                          -- �����敪��
    --
    -- ===================================
    --  �Q�s�ڕҏW�i���ږ��j
    -- ===================================
    gt_csv_data(2)  :=      gr_lookup_values.attribute6               -- ���o���U
                        ||  gr_lookup_values.attribute9               -- ���o���X
                        ||  gr_lookup_values.attribute10              -- ���o���P�O
                        ||  gr_lookup_values.attribute11;             -- ���o���P�P
    --
    -- ===================================
    --  �R�s�ڈȍ~�ҏW�i���l�f�[�^�j
    -- ===================================
    ln_cnt  :=  3;
    --
    <<set_csv_base_loop>>
    LOOP
      -- �Q�v�ݒ�
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (vd_data_rec.gun_code  <>  lv_gun_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- ���_�A�Q�R�[�h�̉��ꂩ���ς����ꍇ�A���͍ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute4      -- ���o���S
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_key_total(1)                  -- ����݌�
                                || cv_separate_code
                                || gt_key_total(2)                  -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(3)                  -- �x���_����
                                || cv_separate_code
                                || gt_key_total(4)                  -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(5)                  -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_key_total(6)                  -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(7)                  -- �x���_�o��
                                || cv_separate_code
                                || gt_key_total(8)                  -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(9)                  -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_key_total(10)                 -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(11)                 -- ��������c
                                || cv_separate_code
                                || gt_key_total(12)                 -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_key_total(13)                 -- �����݌�
                                || cv_separate_code
                                || gt_key_total(14)                 -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_key_total(15)                 -- �I�����Ք�
                                || cv_separate_code
                                || gt_key_total(16);                -- �I�����Ք�i���z�j
        --
        -- �ϐ��J�E���g�A�b�v
        ln_cnt  :=  ln_cnt + 1;
        --
        -- �Q�v������
        FOR i IN 1 .. 16 LOOP
          gt_key_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- ���v�ݒ�
      IF (    (lt_base_code IS NOT NULL)
          AND (    (vd_data_rec.base_code <>  lt_base_code)
               OR  (base_cur%NOTFOUND)
              )
         )
      THEN
        -- ���_�R�[�h���ς����ꍇ�A���͍ŏI���R�[�h�̏ꍇ
        gt_csv_data(ln_cnt) :=     gr_lookup_values.attribute5      -- ���o���T
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || cv_separate_code
                                || gt_total(1)                      -- ����݌�
                                || cv_separate_code
                                || gt_total(2)                      -- ����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(3)                      -- �x���_����
                                || cv_separate_code
                                || gt_total(4)                      -- �x���_���Ɂi���z�j
                                || cv_separate_code
                                || gt_total(5)                      -- �x���_�ړ�����
                                || cv_separate_code
                                || gt_total(6)                      -- �x���_�ړ����Ɂi���z�j
                                || cv_separate_code
                                || gt_total(7)                      -- �x���_�o��
                                || cv_separate_code
                                || gt_total(8)                      -- �x���_�o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(9)                      -- �x���_�ړ��o��
                                || cv_separate_code
                                || gt_total(10)                     -- �x���_�ړ��o�Ɂi���z�j
                                || cv_separate_code
                                || gt_total(11)                     -- ��������c
                                || cv_separate_code
                                || gt_total(12)                     -- ��������c�i���z�j
                                || cv_separate_code
                                || gt_total(13)                     -- �����݌�
                                || cv_separate_code
                                || gt_total(14)                     -- �����݌Ɂi���z�j
                                || cv_separate_code
                                || gt_total(15)                     -- �I�����Ք�
                                || cv_separate_code
                                || gt_total(16);                    -- �I�����Ք�i���z�j
        --
        -- �ϐ��J�E���g�A�b�v
        ln_cnt  :=  ln_cnt + 1;
        --
        -- ���v������
        FOR i IN 1 .. 16 LOOP
          gt_total(i) :=  0;
        END LOOP;
        --
      END IF;
      --
      -- �I������
      EXIT set_csv_base_loop  WHEN  base_cur%NOTFOUND;
      --
      -- ���׃��R�[�h�ݒ�
      gt_csv_data(ln_cnt) :=     vd_data_rec.base_code                    -- ���_�R�[�h
                              || cv_separate_code
                              || vd_data_rec.account_name                 -- ���_����
                              || cv_separate_code
                              || vd_data_rec.gun_code                     -- �Q�R�[�h
                              || cv_separate_code
                              || vd_data_rec.segment1                     -- �i�ڃR�[�h
                              || cv_separate_code
                              || vd_data_rec.item_short_name              -- �i��
                              || cv_separate_code
                              || vd_data_rec.month_begin_quantity         -- ����݌�
                              || cv_separate_code
                              || vd_data_rec.month_begin_money            -- ����݌Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.vd_stock                     -- �x���_����
                              || cv_separate_code
                              || vd_data_rec.vd_stock_money               -- �x���_���Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.vd_move_stock                -- �x���_�ړ�����
                              || cv_separate_code
                              || vd_data_rec.vd_move_stock_money          -- �x���_�ړ����Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.vd_ship                      -- �x���_�o��
                              || cv_separate_code
                              || vd_data_rec.vd_ship_money                -- �x���_�o�Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.vd_move_ship                 -- �x���_�ړ��o��
                              || cv_separate_code
                              || vd_data_rec.vd_move_ship_money           -- �x���_�ړ��o�Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.month_end_book_remain_qty    -- ��������c
                              || cv_separate_code
                              || vd_data_rec.month_end_book_remain_money  -- ��������c�i���z�j
                              || cv_separate_code
                              || vd_data_rec.month_end_quantity           -- �����݌�
                              || cv_separate_code
                              || vd_data_rec.month_end_money              -- �����݌Ɂi���z�j
                              || cv_separate_code
                              || vd_data_rec.inv_wear_account             -- �I�����Ք�
                              || cv_separate_code
                              || vd_data_rec.inv_wear_account_money;      -- �I�����Ք�i���z�j
      --
      -- �Q�v�擾
      gt_key_total(1)   :=  gt_key_total(1)  +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_key_total(2)   :=  gt_key_total(2)  +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_key_total(3)   :=  gt_key_total(3)  +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_key_total(4)   :=  gt_key_total(4)  +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_key_total(5)   :=  gt_key_total(5)  +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_key_total(6)   :=  gt_key_total(6)  +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_key_total(7)   :=  gt_key_total(7)  +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_key_total(8)   :=  gt_key_total(8)  +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_key_total(9)   :=  gt_key_total(9)  +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_key_total(10)  :=  gt_key_total(10) +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_key_total(11)  :=  gt_key_total(11) +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_key_total(12)  :=  gt_key_total(12) +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_key_total(13)  :=  gt_key_total(13) +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_key_total(14)  :=  gt_key_total(14) +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_key_total(15)  :=  gt_key_total(15) +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_key_total(16)  :=  gt_key_total(16) +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���v�擾
      gt_total(1)       :=  gt_total(1)      +  vd_data_rec.month_begin_quantity;           -- ����݌�
      gt_total(2)       :=  gt_total(2)      +  vd_data_rec.month_begin_money;              -- ����݌Ɂi���z�j
      gt_total(3)       :=  gt_total(3)      +  vd_data_rec.vd_stock;                       -- �x���_����
      gt_total(4)       :=  gt_total(4)      +  vd_data_rec.vd_stock_money;                 -- �x���_���Ɂi���z�j
      gt_total(5)       :=  gt_total(5)      +  vd_data_rec.vd_move_stock;                  -- �x���_�ړ�����
      gt_total(6)       :=  gt_total(6)      +  vd_data_rec.vd_move_stock_money;            -- �x���_�ړ����Ɂi���z�j
      gt_total(7)       :=  gt_total(7)      +  vd_data_rec.vd_ship;                        -- �x���_�o��
      gt_total(8)       :=  gt_total(8)      +  vd_data_rec.vd_ship_money;                  -- �x���_�o�Ɂi���z�j
      gt_total(9)       :=  gt_total(9)      +  vd_data_rec.vd_move_ship;                   -- �x���_�ړ��o��
      gt_total(10)      :=  gt_total(10)     +  vd_data_rec.vd_move_ship_money;             -- �x���_�ړ��o�Ɂi���z�j
      gt_total(11)      :=  gt_total(11)     +  vd_data_rec.month_end_book_remain_qty;      -- ��������c
      gt_total(12)      :=  gt_total(12)     +  vd_data_rec.month_end_book_remain_money;    -- ��������c�i���z�j
      gt_total(13)      :=  gt_total(13)     +  vd_data_rec.month_end_quantity;             -- �����݌�
      gt_total(14)      :=  gt_total(14)     +  vd_data_rec.month_end_money;                -- �����݌Ɂi���z�j
      gt_total(15)      :=  gt_total(15)     +  vd_data_rec.inv_wear_account;               -- �I�����Ք�
      gt_total(16)      :=  gt_total(16)     +  vd_data_rec.inv_wear_account_money;         -- �I�����Ք�i���z�j
      --
      -- ���R�[�h�ύX�`�F�b�N�p�ϐ��ێ�
      lt_base_code  :=  vd_data_rec.base_code;
      lv_gun_code   :=  vd_data_rec.gun_code;
      --
      -- �ϐ��J�E���g�A�b�v
      ln_cnt  :=  ln_cnt + 1;
      --
      -- ���������J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- �f�[�^�擾
      FETCH base_cur  INTO  vd_data_rec;
      --
    END LOOP  set_csv_base_loop;
    --
    CLOSE base_cur;
    --
    -- ===================================
    --  CSV�o��
    -- ===================================
    <<output_loop>>
    FOR csv_cnt IN  1 .. gt_csv_data.COUNT  LOOP
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_csv_data(csv_cnt)
      );
    END LOOP output_loop;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** CSV�Ώۃf�[�^�Ȃ���O ***
    WHEN csv_no_data_expt THEN
      -- ����ŁA�{�v���V�[�W�����I��
      NULL;
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
      IF (base_cur%ISOPEN) THEN
        CLOSE base_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_base;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf         OUT VARCHAR2,                     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode        OUT VARCHAR2,                     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg         OUT VARCHAR2)                     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter'; -- �v���O������
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
    ld_dummy    DATE;       -- DATE�^�_�~�[�ϐ�
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
    --  1.���t�^�`�F�b�N
    -- ===================================
    BEGIN
      -- ���t�^�`�F�b�N
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_month);
    EXCEPTION
      WHEN  OTHERS  THEN
        -- �Ɩ��������t�擾�G���[���b�Z�[�W
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_short_name
                         ,iv_name         => cv_msg_xxcoi1_10110
                        );
        lv_errbuf   :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- ===================================
    --  2.�������`�F�b�N
    -- ===================================
    IF(gv_param_reception_date  >=  TO_CHAR(gd_f_process_date, cv_month)) THEN
      -- �p�����[�^.�󕥓����A�Ɩ��������t�ȍ~�̏ꍇ
      -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10111
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- == 2009/07/14 V1.1 Added START ===============================================================
    gd_target_date := LAST_DAY(ld_dummy);
-- == 2009/07/14 V1.1 Added END   ===============================================================
    --
    -- ===================================
    --  3.���_�R�[�h�u��
    -- ===================================
    IF (gv_param_output_kbn IN(cv_output_div_2, cv_output_div_3)) THEN
      -- �o�͋敪�����_�ʌv�A�S�Ќv�̏ꍇ�A�p�����[�^.���_��NULL�Ƃ��܂�
      gv_param_base_code  :=  NULL;
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
  END chk_parameter;
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
    -- ===================================
    --  1.�Ɩ��������t�擾
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_f_process_date IS NULL) THEN
      -- �Ɩ��������t�擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  2.�N���p�����[�^���擾
    -- ===================================
    -- �󕥏o�͋敪��
    gt_output_name  :=  xxcoi_common_pkg.get_meaning(cv_type_output_div, gv_param_output_kbn);
    --
    IF (gt_output_name IS NULL) THEN
      -- �p�����[�^.�o�͋敪���擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10113
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �����敪��
    gt_cost_kbn_name  :=  xxcoi_common_pkg.get_meaning(cv_type_cost_price, gv_param_cost_kbn);
    --
    IF (gt_cost_kbn_name IS NULL) THEN
      -- �p�����[�^.�����敪���擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10114
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.�p�����[�^���O�o��
    -- ===================================
    -- �p�����[�^�o�͋敪�l���b�Z�[�W
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10098
                    ,iv_token_name1  => cv_token_10098_1
                    ,iv_token_value1 => gt_output_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �p�����[�^�󕥔N���l���b�Z�[�W
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10107
                    ,iv_token_name1  => cv_token_10107_1
                    ,iv_token_value1 => gv_param_reception_date
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �p�����[�^�����敪�l���b�Z�[�W
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10108
                    ,iv_token_name1  => cv_token_10108_1
                    ,iv_token_value1 => gt_cost_kbn_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �p�����[�^���_�l���b�Z�[�W
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name
                    ,iv_name         => cv_msg_xxcoi1_10109
                    ,iv_token_name1  => cv_token_10109_1
                    ,iv_token_value1 => gv_param_base_code
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
    --
    -- ===================================
    --  4.���o�����擾
    -- ===================================
    gr_lookup_values  :=  xxcoi_common_pkg.get_lookup_values(
                            iv_lookup_type    =>  cv_type_list_header
                           ,iv_lookup_code    =>  cv_list_header_1
                           ,id_enabled_date   =>  SYSDATE
                          );
    --
    IF (gr_lookup_values.meaning IS NULL) THEN
      -- ���o�����擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10370
                      );
      lv_errbuf   :=  lv_errmsg;
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
    iv_output_kbn     IN  VARCHAR2,     -- �o�͋敪
    iv_reception_date IN  VARCHAR2,     -- �󕥔N��
    iv_cost_kbn       IN  VARCHAR2,     -- �����敪
    iv_base_code      IN  VARCHAR2,     -- ���_
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
    --  0.���̓p�����[�^�ݒ�
    -- ===============================
    gv_param_output_kbn     :=  iv_output_kbn;
    gv_param_reception_date :=  iv_reception_date;
    gv_param_cost_kbn       :=  iv_cost_kbn;
    gv_param_base_code      :=  iv_base_code;
    --
    -- ���v������
    FOR i IN 1 .. 16 LOOP
      gt_key_total(i)   :=  0;
    END LOOP;
    FOR i IN 1 .. 16 LOOP
      gt_key2_total(i)  :=  0;
    END LOOP;
    FOR i IN 1 .. 16 LOOP
      gt_total(i)       :=  0;
    END LOOP;
    --
    -- ===============================
    --  1.��������(A-1)
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
    -- ===============================
    --  2.�p�����[�^�`�F�b�N(A-2)
    -- ===============================
    chk_parameter(
      ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    --  3.VD��CSV�ҏW�E�v���o��(A-3, A-4)
    -- ====================================
    IF (gv_param_output_kbn = cv_output_div_1) THEN
      -- �󕥏o�͋敪�u���_�ʁv�̏ꍇ
      out_csv_base(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    ELSIF (gv_param_output_kbn  = cv_output_div_2)  THEN
      -- �󕥏o�͋敪�u���_�ʌv�v�̏ꍇ
      out_csv_base_total(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    ELSE
      -- �󕥏o�͋敪�u�S�Ќv�v�̏ꍇ
      out_csv_company_total(
        ov_errbuf     =>  lv_errbuf       --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.�I������(A-5)
    -- ===============================
    -- ���팏����ݒ�
    gn_normal_cnt := gn_target_cnt;
    --
  EXCEPTION
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
    errbuf              OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_output_kbn       IN  VARCHAR2,       -- �y�K�{�z�o�͋敪
    iv_reception_date   IN  VARCHAR2,       -- �y�K�{�z�󕥔N��
    iv_cost_kbn         IN  VARCHAR2,       -- �y�K�{�z�����敪
    iv_base_code        IN  VARCHAR2        -- �y�C�Ӂz���_
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
        iv_output_kbn       =>  iv_output_kbn       -- �o�͋敪
       ,iv_reception_date   =>  iv_reception_date   -- �󕥔N��
       ,iv_cost_kbn         =>  iv_cost_kbn         -- �����敪
       ,iv_base_code        =>  iv_base_code        -- ���_
       ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- ��������
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
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
    -- ��s���o��
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
END XXCOI006A23C;
/
