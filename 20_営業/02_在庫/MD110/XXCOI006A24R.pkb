CREATE OR REPLACE PACKAGE BODY XXCOI006A24R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI006A24R(body)
 * Description      : �󕥎c���\�i�c�ƈ��ʌv�j
 * MD.050           : �󕥎c���\�i�c�ƈ��ʌv�j <MD050_COI_A24>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_work_data          ���[�N�e�[�u���f�[�^�o�^(A-3)
 *  ins_svf_data           ���[�p���[�N�e�[�u���f�[�^�o�^(A-4)
 *  call_output_svf        SVF�N��(A-5)
 *  del_svf_data           ���[�N�e�[�u���f�[�^�폜(A-6)
 *  submain                ���C�������v���V�[�W��
 *                         ���[�N�f�[�^�擾(A-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/04/08    1.0   SCSK ����        �V�K�쐬
 *  2021/02/05    1.1   SCSK ��        [E_�{�ғ�_16026]���v�F��
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
  select_expt               EXCEPTION;  -- �f�[�^���o��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOI006A24R'; -- �p�b�P�[�W��
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�h�I���F�̕��E�݌ɗ̈�
  --���t�ϊ��p
  cv_ymd              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_ymd_sla          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_ym_sla           CONSTANT VARCHAR2(7)   := 'YYYY/MM';
  cv_ym               CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_replace_sign     CONSTANT VARCHAR2(1)   := '/';
  --�ڋq�敪�p
  cv_class_code_1     CONSTANT VARCHAR2(1)   := '1';  --���_
  --�ۊǏꏊ�敪�p
  cv_hkn_kbn_car      CONSTANT VARCHAR2(1)   := '2';  --�c�Ǝ�
  --�I���敪�p
  cv_1                CONSTANT VARCHAR2(1)   := '1';  --����
  cv_2                CONSTANT VARCHAR2(1)   := '2';  --����
  --�I���敪�p
  cv_10               CONSTANT VARCHAR2(2)   := '10'; --����
  cv_20               CONSTANT VARCHAR2(2)   := '20'; --����
  cv_30               CONSTANT VARCHAR2(2)   := '30'; --����
  --���b�Z�[�W
  cv_xxcoi1_msg_00008 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00008';  --�Ώۃf�[�^�Ȃ�
  cv_xxcoi1_msg_10330 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10330';  --�p�����[�^�I���敪
  cv_xxcoi1_msg_10099 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10099';  --�p�����[�^�I����
  cv_xxcoi1_msg_10100 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10100';  --�p�����[�^�I����
  cv_xxcoi1_msg_10096 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10096';  --�p�����[�^���_
  cv_xxcoi1_msg_00011 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00011';  --�Ɩ��������t
  cv_xxcoi1_msg_10105 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10105';  --�I�����̌^�`�F�b�N
  cv_xxcoi1_msg_10106 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10106';  --���_�L���`�F�b�N
  cv_xxcoi1_msg_00005 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00005';  --�݌ɑg�D�R�[�h
  cv_xxcoi1_msg_00006 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00006';  --�݌ɑg�DID
  cv_xxcoi1_msg_10197 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10197';  --�I�����������`�F�b�N�G���[���b�Z�[�W
  cv_xxcoi1_msg_10198 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10198';  --�I�����������`�F�b�N�G���[���b�Z�[�W
  cv_xxcoi1_msg_00026 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00026';  --�݌ɉ�v���Ԏ擾�G���[���b�Z�[�W
  cv_xxcoi1_msg_10451 CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-10451';  --�݌Ɋm��󎚕����擾�G���[���b�Z�[�W
  cv_xxcoi1_msg_10088 CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10088';  --���[�o�̓G���[
  --�Q�ƃ^�C�v
  cv_lk_list_out_div  CONSTANT VARCHAR2(20)  := 'XXCOI1_INVENTORY_DIV';      --�󕥕\�I���敪
  --�v���t�@�C��
  cv_prf_org_code     CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  --�݌ɑg�D�R�[�h
  cv_inv_cl_char      CONSTANT VARCHAR2(24)  := 'XXCOI1_INV_CL_CHARACTER';   --�݌Ɋm��󎚕���
  -- SVF�N���֐��p�����[�^�p
  cv_conc_name        CONSTANT VARCHAR2(30)  := 'XXCOI006A24R';              --�R���J�����g��
  cv_type_pdf         CONSTANT VARCHAR2(4)   := '.pdf';                      --�g���q�iPDF�j
  cv_file_id          CONSTANT VARCHAR2(30)  := 'XXCOI006A24R';              --���[ID
  cv_output_mode      CONSTANT VARCHAR2(30)  := '1';                         --�o�͋敪
  cv_frm_file         CONSTANT VARCHAR2(30)  := 'XXCOI006A24S.xml';          --�t�H�[���l���t�@�C����
  cv_vrq_file         CONSTANT VARCHAR2(30)  := 'XXCOI006A24S.vrq';          --�N�G���[�l���t�@�C����
  --�g�[�N��
  cv_tkn_inv_type     CONSTANT VARCHAR2(16)  := 'P_INVENTORY_TYPE';          --�g�[�N���I���敪
  cv_tkn_inv_date     CONSTANT VARCHAR2(16)  := 'P_INVENTORY_DATE';          --�g�[�N���I����
  cv_tkn_inv_month    CONSTANT VARCHAR2(17)  := 'P_INVENTORY_MONTH';         --�g�[�N���I����
  cv_tkn_base_code    CONSTANT VARCHAR2(11)  := 'P_BASE_CODE';               --�g�[�N�����_
  cv_tkn_pro          CONSTANT VARCHAR2(7)   := 'PRO_TOK';                   --�g�[�N���v���t�@�C����
  cv_tkn_org_code     CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';              --�g�[�N���݌ɑg�D�R�[�h
  cv_tkn_target       CONSTANT VARCHAR2(11)  := 'TARGET_DATE';               --�g�[�N���Ώۓ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                   -- �Ɩ��������t
  gd_target_date        DATE;                                   -- �擾�Ώۓ��t
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --�󕥎c���\�i�����j
  CURSOR daily_cur(
            iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
              /*+ leading(msi papf xird) */
              papf.employee_number                emp_no              -- �c�ƈ��R�[�h
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
                                                  emp_name            -- �c�ƈ����́i�������{�������j
             ,xird.operation_cost                 operation_cost      -- �c�ƌ���
             ,xird.previous_inventory_quantity    month_begin_qty     -- ����I����
             ,xird.warehouse_stock          +                         -- �q�ɂ�����
              xird.vd_supplement_stock                                -- ����VD��[����
                                                  vd_sp_stock         -- �q�ɂ�����
             ,xird.sales_shipped            -                         -- ����o��
-- == 2021/02/05 V1.1 Modified START ==============================================================
--              xird.sales_shipped_b                                    -- ����o�ɐU��
              xird.sales_shipped_b          +                         -- ����o�ɐU��
              xird.customer_support_ss      -                         -- �ڋq���^���{�o��
              xird.customer_support_ss_b                              -- �ڋq���^���{�o�ɐU��
-- == 2021/02/05 V1.1 Modified END   ==============================================================
                                                  sales_shipped       -- ����o��
             ,xird.return_goods             -                         -- �ԕi
              xird.return_goods_b                                     -- �ԕi�U��
                                                  customer_return     -- �ڋq�ԕi
             ,xird.customer_sample_ship     -                         -- �ڋq���{�o��
              xird.customer_sample_ship_b   +                         -- �ڋq���{�o�ɐU��
-- == 2021/02/05 V1.1 Deleted START ===============================================================
--              xird.customer_support_ss      -                         -- �ڋq���^���{�o��
--              xird.customer_support_ss_b    +                         -- �ڋq���^���{�o�ɐU��
-- == 2021/02/05 V1.1 Deleted END   ===============================================================
              xird.sample_quantity          -                         -- ���{�o��
              xird.sample_quantity_b        +                         -- ���{�o�ɐU��
              xird.ccm_sample_ship          -                         -- �ڋq�L����`��A���Џ��i
              xird.ccm_sample_ship_b                                  -- �ڋq�L����`��A���Џ��i�U��
                                                  support_sample      -- ���^���{
             ,xird.inventory_change_out           inv_change_out      -- VD�o��
             ,xird.inventory_change_in            inv_change_in       -- VD����
             ,xird.warehouse_ship           +                         -- �q�ɂ֕Ԍ�
              xird.vd_supplement_ship                                 -- ����VD��[�o��
                                                  warehouse_ship      -- �q�ɂ֕Ԍ�
             ,xird.book_inventory_quantity        tyoubo_stock        -- ����݌�
             ,0                                   inventory           -- �I����
             ,0                                   inv_wear            -- �I������
    FROM      xxcoi_inv_reception_daily   xird                    -- �����݌Ɏ󕥕\�i�����j
             ,mtl_secondary_inventories   msi                     -- �ۊǏꏊ�}�X�^
             ,per_all_people_f            papf                    -- �]�ƈ��}�X�^
    WHERE     papf.effective_start_date  <= gd_process_date
    AND       papf.effective_end_date    >= gd_process_date
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_hkn_kbn_car
    AND       msi.organization_id         = in_organization_id
    AND       xird.subinventory_code      = msi.secondary_inventory_name
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xird.base_code
    AND       msi.organization_id         = xird.organization_id
    AND       xird.subinventory_type      = cv_hkn_kbn_car
    AND       xird.practice_date          = TO_DATE(iv_inventory_date, cv_ymd)
    ;
--
  --�󕥎c���\�i�����j
  CURSOR monthly_cur(
            iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,iv_inventory_month  IN VARCHAR2
           ,iv_inventory_kbn    IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT
              /*+ leading(msi papf xirm) */
              papf.employee_number                emp_no              -- �c�ƈ��R�[�h
             ,SUBSTRB(papf.per_information18, 1, 10) || SUBSTRB(papf.per_information19, 1, 10)
                                                  emp_name            -- �c�ƈ����́i�������{�������j
             ,xirm.operation_cost                 operation_cost      -- �c�ƌ���
             ,xirm.month_begin_quantity           month_begin_qty     -- ����I����
             ,xirm.warehouse_stock          +                         -- �q�ɂ�����
              xirm.vd_supplement_stock                                -- ����VD��[����
                                                  vd_sp_stock         -- �q�ɂ�����
             ,xirm.sales_shipped            -                         -- ����o��
-- == 2021/02/05 V1.1 Modified START ==============================================================
--              xirm.sales_shipped_b                                    -- ����o�ɐU��
              xirm.sales_shipped_b          +                         -- ����o�ɐU��
              xirm.customer_support_ss      -                         -- �ڋq���^���{�o��
              xirm.customer_support_ss_b                              -- �ڋq���^���{�o�ɐU��
-- == 2021/02/05 V1.1 Modified END   ==============================================================
                                                  sales_shipped       -- ����o��
             ,xirm.return_goods             -                         -- �ԕi
              xirm.return_goods_b                                     -- �ԕi�U��
                                                  customer_return     -- �ڋq�ԕi
             ,xirm.customer_sample_ship     -                         -- �ڋq���{�o��
              xirm.customer_sample_ship_b   +                         -- �ڋq���{�o�ɐU��
-- == 2021/02/05 V1.1 Deleted START ===============================================================
--              xirm.customer_support_ss      -                         -- �ڋq���^���{�o��
--              xirm.customer_support_ss_b    +                         -- �ڋq���^���{�o�ɐU��
-- == 2021/02/05 V1.1 Deleted END   ===============================================================
              xirm.sample_quantity          -                         -- ���{�o��
              xirm.sample_quantity_b        +                         -- ���{�o�ɐU��
              xirm.ccm_sample_ship          -                         -- �ڋq�L����`��A���Џ��i
              xirm.ccm_sample_ship_b                                  -- �ڋq�L����`��A���Џ��i�U��
                                                  support_sample      -- ���^���{
             ,xirm.inventory_change_out           inv_change_out      -- VD�o��
             ,xirm.inventory_change_in            inv_change_in       -- VD����
             ,xirm.warehouse_ship           +                         -- �q�ɂ֕Ԍ�
              xirm.vd_supplement_ship                                 -- ����VD��[�o��
                                                  warehouse_ship      -- �q�ɂ֕Ԍ�
             ,xirm.inv_result               +                         -- �I������
              xirm.inv_result_bad           +                         -- �I�����ʁi�s�Ǖi�j
              xirm.inv_wear                                           -- �I������
                                                  tyoubo_stock        -- ����݌�
             ,xirm.inv_result               +                         -- �I������
              xirm.inv_result_bad                                     -- �I�����ʁi�s�Ǖi�j
                                                  inventory           -- �I����
             ,xirm.inv_wear                       inv_wear            -- �I������
    FROM      xxcoi_inv_reception_monthly xirm                    --�����݌Ɏ󕥕\�i�����j
             ,mtl_secondary_inventories   msi                     --�ۊǏꏊ�}�X�^
             ,per_all_people_f            papf                    --�]�ƈ��}�X�^
    WHERE     papf.effective_start_date  <= gd_process_date
    AND       papf.effective_end_date    >= gd_process_date
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_hkn_kbn_car
    AND       msi.organization_id         = in_organization_id
    AND       xirm.subinventory_code      = msi.secondary_inventory_name
    AND       msi.attribute7              = iv_base_code
    AND       msi.attribute7              = xirm.base_code
    AND       msi.organization_id         = xirm.organization_id
    AND       xirm.subinventory_type      = cv_hkn_kbn_car
    AND       (xirm.practice_date         = TO_DATE(iv_inventory_date, cv_ymd)
    OR        xirm.practice_month         = iv_inventory_month)
    AND       xirm.inventory_kbn          = DECODE(iv_inventory_kbn, cv_20, cv_1, cv_2)
    ;
  --
  --SVF�o�͗p�󕥎c���\
  CURSOR svf_data_cur
  IS
    SELECT
              xret.employee_code                emp_no                  --�c�ƈ��R�[�h
             ,xret.employee_name                emp_name                --�c�ƈ�����
             ,SUM(xret.first_inventory_qty)   first_inv_qty_amt         --����I��������
             ,SUM(xret.first_inventory_qty * xret.operation_cost)
                                                first_inv_qty_pr        --����I�������z
             ,SUM(xret.warehouse_stock)         warehouse_stock_amt     --�q�ɂ����ɐ���
             ,SUM(xret.warehouse_stock     * xret.operation_cost)
                                                warehouse_stock_pr      --�q�ɂ����ɋ��z
             ,SUM(xret.sales_qty)               sales_qty_amt           --����o�ɐ���
             ,SUM(xret.sales_qty           * xret.operation_cost)
                                                sales_qty_pr            --����o�ɋ��z
             ,SUM(xret.customer_return)         customer_return_amt     --�ڋq�ԕi����
             ,SUM(xret.customer_return     * xret.operation_cost)
                                                customer_return_pr      --�ڋq�ԕi���z
             ,SUM(xret.support_qty)             support_qty_amt         --���^���{����
             ,SUM(xret.support_qty         * xret.operation_cost)
                                                support_qty_pr          --���^���{���z
             ,SUM(xret.vd_ship_qty)             vd_ship_qty_amt         --VD�o�ɐ���
             ,SUM(xret.vd_ship_qty         * xret.operation_cost)
                                                vd_ship_qty_pr          --VD�o�ɋ��z
             ,SUM(xret.vd_in_qty)               vd_in_qty_amt           --VD���ɐ���
             ,SUM(xret.vd_in_qty           * xret.operation_cost)
                                                vd_in_qty_pr            --VD���ɋ��z
             ,SUM(xret.warehouse_ship)          warehouse_ship_amt      --�q�ɂ֕Ԍɐ���
             ,SUM(xret.warehouse_ship      * xret.operation_cost)
                                                warehouse_ship_pr       --�q�ɂ֕Ԍɋ��z
             ,SUM(xret.tyoubo_stock_qty)        tyb_stock_qty_amt       --����݌ɐ���
             ,SUM(xret.tyoubo_stock_qty    * xret.operation_cost)
                                                tyb_stock_qty_pr        --����݌ɋ��z
             ,SUM(xret.inventory_qty)           inventory_qty_amt       --�I��������
             ,SUM(xret.inventory_qty       * xret.operation_cost)
                                                inventory_qty_pr        --�I�������z
             ,SUM(xret.genmou_qty)              genmou_qty_amt          --�I�����Ր���
             ,SUM(xret.genmou_qty          * xret.operation_cost)
                                                genmou_qty_pr           --�I�����Ջ��z
    FROM      xxcoi_tmp_rep_by_employee_rcpt  xret
    GROUP BY
              xret.employee_code
             ,xret.employee_name
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_inventory_kbn    IN  VARCHAR2,                                       -- 1.�I���敪
    iv_inventory_date   IN  VARCHAR2,                                       -- 2.�I����
    iv_inventory_month  IN  VARCHAR2,                                       -- 3.�I����
    iv_base_code        IN  VARCHAR2,                                       -- 4.���_�R�[�h
    ov_account_name     OUT VARCHAR2,                                       -- 6.���_����
    on_organization_id  OUT NUMBER,                                         -- 7.�݌ɑg�DID
    ot_inv_kbn_name     OUT fnd_lookup_values.meaning%TYPE,                 -- 8.�I���敪����
    ov_inv_cl_char      OUT VARCHAR2,                                       -- 9.�݌Ɋm��󎚕���
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'init';             -- �v���O������
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
    lv_organization_code  VARCHAR2(4);                                            --�݌ɑg�D�R�[�h
    ln_organization_id    NUMBER;                                                 --�݌ɑg�DID
    lt_meaning            fnd_lookup_values.meaning%TYPE;                         --���ږ�
    ld_inv_date           DATE;                                                   --���t�`�F�b�N�p
    lv_short_account_name VARCHAR2(20);                                           --���_����
    lb_chk_result         BOOLEAN;                                                --�݌ɉ�v���ԃ`�F�b�N����
    lv_inv_cl_char        VARCHAR2(4);                                            --�݌Ɋm��󎚕���
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
    -- ���[�J���ϐ��̏�����
    lv_inv_cl_char := NULL;
    --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --===================================
    --���̓p�����[�^�o��
    --===================================
    --�I���敪���e�擾
    lt_meaning := xxcoi_common_pkg.get_meaning(
                    cv_lk_list_out_div
                   ,iv_inventory_kbn
                  );
    --�I���敪�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10330
                   ,iv_token_name1  => cv_tkn_inv_type
                   ,iv_token_value1 => lt_meaning
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => gv_out_msg
    );
    --�I����
    IF (iv_inventory_date IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10099
                     ,iv_token_name1  => cv_tkn_inv_date
                     ,iv_token_value1 => iv_inventory_date
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => gv_out_msg
      );
    END IF;
    --�I����
    IF (iv_inventory_month IS NOT NULL) THEN
      BEGIN
        ld_inv_date := TO_DATE(iv_inventory_month, cv_ym);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_10105
                         )
                      ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      --
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10100
                     ,iv_token_name1  => cv_tkn_inv_month
                     ,iv_token_value1 => iv_inventory_month
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => gv_out_msg
      );
    END IF;
    --���_
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_short_name
                   ,iv_name         => cv_xxcoi1_msg_10096
                   ,iv_token_name1  => cv_tkn_base_code
                   ,iv_token_value1 => iv_base_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => gv_out_msg
    );
--
    --====================================
    --�Ɩ��������t�擾
    --====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00011
                     )
                   ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --�������`�F�b�N
    --====================================
    --�I���敪��10:�����A20:����
    IF (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      ld_inv_date := TO_DATE(iv_inventory_date, cv_ymd);
      IF (ld_inv_date > gd_process_date) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10197
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      gd_target_date := ld_inv_date;
    --
    --�I���敪��30:����
    ELSIF (iv_inventory_kbn = cv_30) THEN
      IF (ld_inv_date > gd_process_date) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10198
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      gd_target_date := LAST_DAY(TO_DATE(iv_inventory_month, cv_ym_sla));
    END IF;
--
    --====================================
    --���_���̎擾
    --====================================
    BEGIN
      SELECT  SUBSTRB(hca.account_name, 1, 8)  account_name
      INTO    lv_short_account_name
      FROM    hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_class_code_1
      AND     hca.account_number      = iv_base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10106
                      ,iv_token_name1  => cv_tkn_base_code
                      ,iv_token_value1 => iv_base_code
                       )
                    ,1,5000);
      RAISE select_expt;
    END;
--
    --====================================
    --�݌ɑg�D�R�[�h�擾
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
    --
    IF (lv_organization_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00005
                    ,iv_token_name1  => cv_tkn_pro
                    ,iv_token_value1 => cv_prf_org_code
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --�݌ɑg�DID�擾
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
    --
    IF (ln_organization_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00006
                    ,iv_token_name1  => cv_tkn_org_code
                    ,iv_token_value1 => lv_organization_code
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --�݌ɉ�v���ԃ`�F�b�N
    --====================================
    xxcoi_common_pkg.org_acct_period_chk(
      in_organization_id    => ln_organization_id  -- �g�DID
     ,id_target_date        => gd_target_date      -- �擾�Ώۓ��t
     ,ob_chk_result         => lb_chk_result       -- �`�F�b�N����
     ,ov_errbuf             => lv_errbuf
     ,ov_retcode            => lv_retcode
     ,ov_errmsg             => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_00026
                    ,iv_token_name1  => cv_tkn_target
                    ,iv_token_value1 => TO_CHAR(gd_target_date, cv_ymd_sla)
                     )
                  ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --====================================
    --���[�󎚕����擾
    --====================================
    IF NOT(lb_chk_result) THEN
      lv_inv_cl_char := fnd_profile.value(cv_inv_cl_char);
      --
      IF (lv_inv_cl_char IS NULL) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10451
                      ,iv_token_name1  => cv_tkn_pro
                      ,iv_token_value1 => cv_inv_cl_char
                       )
                    ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --OUT�p�����[�^�ɐݒ�
    ov_account_name     := lv_short_account_name;
    on_organization_id  := ln_organization_id;
    ot_inv_kbn_name     := lt_meaning;
    ov_inv_cl_char      := lv_inv_cl_char;
--
  EXCEPTION
    -- *** �f�[�^���o��O ***
    WHEN select_expt THEN
      -- ���b�Z�[�W�擾
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_work_data(
    ir_work_data        IN  daily_cur%ROWTYPE,              -- CSV�o�͑Ώۃf�[�^
    ov_errbuf           OUT VARCHAR2,                       -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,                       -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_data'; -- �v���O������
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
    -- ===============================
    --  1.���[�N�e�[�u���쐬
    -- ===============================
    --
    -- �󕥎c���\�i�c�ƈ��ʌv�j�ꎞ�\�֑}��
    INSERT INTO xxcoi_tmp_rep_by_employee_rcpt(
       employee_code                    -- �c�ƈ��R�[�h
      ,employee_name                    -- �c�ƈ�����
      ,operation_cost                   -- �c�ƌ���
      ,first_inventory_qty              -- ����I����
      ,warehouse_stock                  -- �q�ɂ�����
      ,sales_qty                        -- ����o��
      ,customer_return                  -- �ڋq�ԕi
      ,support_qty                      -- ���^���{
      ,vd_ship_qty                      -- VD�o��
      ,vd_in_qty                        -- VD����
      ,warehouse_ship                   -- �q�ɂ֕Ԍ�
      ,tyoubo_stock_qty                 -- ����݌�
      ,inventory_qty                    -- �I����
      ,genmou_qty                       -- �I������
    )VALUES(
       ir_work_data.emp_no              -- �c�ƈ��R�[�h
      ,ir_work_data.emp_name            -- �c�ƈ�����
      ,ir_work_data.operation_cost      -- �c�ƌ���
      ,ir_work_data.month_begin_qty     -- ����I����
      ,ir_work_data.vd_sp_stock         -- �q�ɂ�����
      ,ir_work_data.sales_shipped       -- ����o��
      ,ir_work_data.customer_return     -- �ڋq�ԕi
      ,ir_work_data.support_sample      -- ���^���{
      ,ir_work_data.inv_change_out      -- VD�o��
      ,ir_work_data.inv_change_in       -- VD����
      ,ir_work_data.warehouse_ship      -- �q�ɂ֕Ԍ�
      ,ir_work_data.tyoubo_stock        -- ����݌�
      ,ir_work_data.inventory           -- �I����
      ,ir_work_data.inv_wear            -- �I������
    );
--
  EXCEPTION
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
   * Procedure Name   : ins_svf_data
   * Description      : ���[�p���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data         IN  svf_data_cur%ROWTYPE,           -- 1.CSV�o�͑Ώۃf�[�^
    in_slit_id          IN  NUMBER,                         -- 2.�����A��
    iv_message          IN  VARCHAR2,                       -- 3.�O�����b�Z�[�W
    iv_inventory_kbn    IN  VARCHAR2,                       -- 4.�I���敪
    it_inv_kbn_name     IN  fnd_lookup_values.meaning%TYPE, -- 5.�I���敪����
    iv_account_name     IN  VARCHAR2,                       -- 6.���_����
    iv_inventory_date   IN  VARCHAR2,                       -- 7.�I����
    iv_inventory_month  IN  VARCHAR2,                       -- 8.�I����
    iv_base_code        IN  VARCHAR2,                       -- 9.���_�R�[�h
    iv_inv_cl_char      IN  VARCHAR2,                       -- 10.�݌Ɋm��󎚕���
    ov_errbuf           OUT VARCHAR2,                       -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,                       -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                       -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    lv_year                   VARCHAR2(4);    -- �N
    lv_month                  VARCHAR2(2);    -- ��
    lv_day                    VARCHAR2(2);    -- ��
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
--
    -- ===============================
    --  1.���[�N�e�[�u���쐬
    -- ===============================
    -- �N�����ݒ�
    -- �I���敪 = �����A����
    IF (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      lv_year   := SUBSTRB(iv_inventory_date, 3, 2);
      lv_month  := SUBSTRB(iv_inventory_date, 5, 2);
      lv_day    := SUBSTRB(iv_inventory_date, 7, 2);
    -- �I���敪 = ����
    ELSIF (iv_inventory_kbn = cv_30) THEN
      lv_year   := SUBSTRB(iv_inventory_month, 3, 2);
      lv_month  := SUBSTRB(iv_inventory_month, 5, 2);
      lv_day    :=  NULL;
    END IF;
    --
    -- �󕥎c���\�i�c�ƈ��ʌv�j���[���[�N�e�[�u���֑}��
    INSERT INTO xxcoi_rep_by_employee_rcpt(
       slit_id                         -- 1.ID
      ,inventory_kbn                   -- 2.�I���敪�i���e�j
      ,in_out_year                     -- 3.�N
      ,in_out_month                    -- 4.��
      ,in_out_date                     -- 5.��
      ,base_code                       -- 6.���_�R�[�h
      ,base_name                       -- 7.���_����
      ,inv_cl_char                     -- 8.�݌Ɋm��󎚕���
      ,employee_code                   -- 9.�c�ƈ��R�[�h
      ,employee_name                   -- 10.�c�ƈ�����
      ,first_inv_qty_amt               -- 11.����I��������
      ,first_inv_qty_pr                -- 12.����I�������z
      ,warehouse_stock_amt             -- 13.�q�ɂ����ɐ���
      ,warehouse_stock_pr              -- 14.�q�ɂ����ɋ��z
      ,sales_qty_amt                   -- 15.����o�ɐ���
      ,sales_qty_pr                    -- 16.����o�ɋ��z
      ,customer_return_amt             -- 17.�ڋq�ԕi����
      ,customer_return_pr              -- 18.�ڋq�ԕi���z
      ,support_qty_amt                 -- 19.���^���{����
      ,support_qty_pr                  -- 20.���^���{���z
      ,vd_ship_qty_amt                 -- 21.VD�o�ɐ���
      ,vd_ship_qty_pr                  -- 22.VD�o�ɋ��z
      ,vd_in_qty_amt                   -- 23.VD���ɐ���
      ,vd_in_qty_pr                    -- 24.VD���ɋ��z
      ,warehouse_ship_amt              -- 25.�q�ɂ֕Ԍɐ���
      ,warehouse_ship_pr               -- 26.�q�ɂ֕Ԍɋ��z
      ,tyb_stock_qty_amt               -- 27.����݌ɐ���
      ,tyb_stock_qty_pr                -- 28.����݌ɋ��z
      ,inventory_qty_amt               -- 29.�I��������
      ,inventory_qty_pr                -- 30.�I�������z
      ,genmou_qty_amt                  -- 31.�I�����Ր���
      ,genmou_qty_pr                   -- 32.�I�����Ջ��z
      ,message                         -- 33.���b�Z�[�W ���O���p
      ,last_update_date                -- 34.�ŏI�X�V��
      ,last_updated_by                 -- 35.�ŏI�X�V��
      ,creation_date                   -- 36.�쐬��
      ,created_by                      -- 37.�쐬��
      ,last_update_login               -- 38.�ŏI�X�V���[�U
      ,request_id                      -- 39.�v��ID
      ,program_application_id          -- 40.�v���O�����A�v���P�[�V����ID
      ,program_id                      -- 41.�v���O����ID
      ,program_update_date             -- 42.�v���O�����X�V��
    )VALUES(
       in_slit_id                      -- 1.ID
      ,it_inv_kbn_name                 -- 2.�I���敪
      ,lv_year                         -- 3.�N
      ,lv_month                        -- 4.��
      ,lv_day                          -- 5.��
      ,iv_base_code                    -- 6.���_�R�[�h
      ,iv_account_name                 -- 7.���_����
      ,iv_inv_cl_char                  -- 8.�݌Ɋm��󎚕���
      ,ir_svf_data.emp_no              -- 9.�c�ƈ��R�[�h
      ,ir_svf_data.emp_name            -- 10.�c�ƈ�����
      ,ir_svf_data.first_inv_qty_amt   -- 11.����I��������
      ,ir_svf_data.first_inv_qty_pr    -- 12.����I�������z
      ,ir_svf_data.warehouse_stock_amt -- 13.�q�ɂ����ɐ���
      ,ir_svf_data.warehouse_stock_pr  -- 14.�q�ɂ����ɋ��z
      ,ir_svf_data.sales_qty_amt       -- 15.����o�ɐ���
      ,ir_svf_data.sales_qty_pr        -- 16.����o�ɋ��z
      ,ir_svf_data.customer_return_amt -- 17.�ڋq�ԕi����
      ,ir_svf_data.customer_return_pr  -- 18.�ڋq�ԕi���z
      ,ir_svf_data.support_qty_amt     -- 19.���^���{����
      ,ir_svf_data.support_qty_pr      -- 20.���^���{���z
      ,ir_svf_data.vd_ship_qty_amt     -- 21.VD�o�ɐ���
      ,ir_svf_data.vd_ship_qty_pr      -- 22.VD�o�ɋ��z
      ,ir_svf_data.vd_in_qty_amt       -- 23.VD���ɐ���
      ,ir_svf_data.vd_in_qty_pr        -- 24.VD���ɋ��z
      ,ir_svf_data.warehouse_ship_amt  -- 25.�q�ɂ֕Ԍɐ���
      ,ir_svf_data.warehouse_ship_pr   -- 26.�q�ɂ֕Ԍɋ��z
      ,ir_svf_data.tyb_stock_qty_amt   -- 27.����݌ɐ���
      ,ir_svf_data.tyb_stock_qty_pr    -- 28.����݌ɋ��z
      ,ir_svf_data.inventory_qty_amt   -- 29.�I��������
      ,ir_svf_data.inventory_qty_pr    -- 30.�I�������z
      ,ir_svf_data.genmou_qty_amt      -- 31.�I�����Ր���
      ,ir_svf_data.genmou_qty_pr       -- 32.�I�����Ջ��z
      ,iv_message                      -- 33.���b�Z�[�W ���O���p
      ,SYSDATE                         -- 34.�ŏI�X�V��
      ,cn_last_updated_by              -- 35.�ŏI�X�V��
      ,SYSDATE                         -- 36.�쐬��
      ,cn_created_by                   -- 37.�쐬��
      ,cn_last_update_login            -- 38.�ŏI�X�V���[�U
      ,cn_request_id                   -- 39.�v��ID
      ,cn_program_application_id       -- 40.�v���O�����A�v���P�[�V����ID
      ,cn_program_id                   -- 41.�v���O����ID
      ,SYSDATE                         -- 42.�v���O�����X�V��
    );
--
  EXCEPTION
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
  END ins_svf_data;
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
    -- ===============================
    --  1.SVF�N��
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>  cv_conc_name            -- �R���J�����g��
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_ymd) || TO_CHAR(cn_request_id) || cv_type_pdf
                                                        -- �o�̓t�@�C����
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
    IF (lv_retcode  <>  cv_status_normal) THEN
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10088
                      )
                   ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF; 
--
  EXCEPTION
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
  END call_output_svf;
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
    -- ===============================
    --  ���[�N�e�[�u���폜
    -- ===============================
    --�󕥎c���\�i�c�ƈ��ʌv�j���[���[�N�e�[�u��
    DELETE  FROM xxcoi_rep_by_employee_rcpt
    WHERE   request_id  = cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn    IN  VARCHAR2,   -- 1.�I���敪
    iv_inventory_date   IN  VARCHAR2,   -- 2.�I����
    iv_inventory_month  IN  VARCHAR2,   -- 3.�I����
    iv_base_code        IN  VARCHAR2,   -- 4.���_
    ov_errbuf           OUT VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_zero_msg           VARCHAR2(5000);
    --
    lv_account_name       VARCHAR2(16);
    ln_organization_id    NUMBER;
    lt_inv_kbn_name       fnd_lookup_values.meaning%TYPE;
    lv_inv_cl_char        VARCHAR2(4);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���R�[�h�^
    inv_data_rec  daily_cur%ROWTYPE;
    svf_data_rec  svf_data_cur%ROWTYPE;
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
    -- ���[�J���ϐ��̏�����
    lv_zero_msg   := NULL;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� A-1
    -- ===============================
    init(
      iv_inventory_kbn    =>  iv_inventory_kbn    -- 1.�I���敪
     ,iv_inventory_date   =>  iv_inventory_date   -- 2.�I����
     ,iv_inventory_month  =>  iv_inventory_month  -- 3.�I����
     ,iv_base_code        =>  iv_base_code        -- 4.���_�R�[�h
     ,ov_account_name     =>  lv_account_name     -- 6.���_����
     ,on_organization_id  =>  ln_organization_id  -- 7.�݌ɑg�D�R�[�h
     ,ot_inv_kbn_name     =>  lt_inv_kbn_name     -- 8.�I���敪����
     ,ov_inv_cl_char      =>  lv_inv_cl_char      -- 9.�݌Ɋm��󎚕���
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�N�f�[�^�擾 A-2
    -- ===============================
    --�I���敪������
    IF (iv_inventory_kbn = cv_10) THEN
      OPEN  daily_cur(
              iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,in_organization_id  => ln_organization_id);
      FETCH daily_cur INTO inv_data_rec;
      --�Ώۃf�[�^�O��
      IF (daily_cur%NOTFOUND) THEN
        lv_zero_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                         )
                      ,1,5000);
      END IF;
    --�I���敪���������́A����
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      OPEN  monthly_cur(
              iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,iv_inventory_month  => iv_inventory_month
             ,iv_inventory_kbn    => iv_inventory_kbn
             ,in_organization_id  => ln_organization_id);
      FETCH monthly_cur INTO inv_data_rec;
      --�Ώۃf�[�^�O��
      IF (monthly_cur%NOTFOUND) THEN
        lv_zero_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                         )
                      ,1,5000);
      END IF;
    END IF;
--
    -- �Ώۃf�[�^�O���̏ꍇ�A���[�N�e�[�u���쐬�����͂Ȃ�
    IF (lv_zero_msg IS NULL) THEN
      --
      <<ins_work_loop>>
      LOOP
        -- ===============================
        --  A-3.���[�N�e�[�u���f�[�^�o�^
        -- ===============================
        ins_work_data(
           ir_work_data       =>  inv_data_rec        -- CSV�o�͗p�f�[�^
          ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- �Ώۃf�[�^�擾
        IF (iv_inventory_kbn =  cv_10)  THEN
          FETCH daily_cur INTO inv_data_rec;
          EXIT WHEN daily_cur%NOTFOUND;
        ELSIF (iv_inventory_kbn IN (cv_20, cv_30))  THEN
          FETCH monthly_cur INTO inv_data_rec;
          EXIT WHEN monthly_cur%NOTFOUND;
        END IF;
        --
      END LOOP ins_work_loop;
    --
    END IF;
    -- �J�[�\���N���[�Y
    IF (iv_inventory_kbn = cv_10) THEN
      CLOSE daily_cur;
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      CLOSE monthly_cur;
    END IF;
--
    --���[�p�f�[�^�擾
    OPEN  svf_data_cur;
    FETCH svf_data_cur INTO svf_data_rec;
    --
    <<ins_svf_loop>>
    LOOP
      --
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- ===============================
      --  A-4.���[�p���[�N�e�[�u���f�[�^�o�^
      -- ===============================
      ins_svf_data(
         ir_svf_data        =>  svf_data_rec        -- 1.CSV�o�͗p�f�[�^
        ,in_slit_id         =>  gn_target_cnt       -- 2.�����A��
        ,iv_message         =>  lv_zero_msg         -- 3.�O�����b�Z�[�W
        ,iv_inventory_kbn   =>  iv_inventory_kbn    -- 4.�I���敪
        ,it_inv_kbn_name    =>  lt_inv_kbn_name     -- 5.�I���敪����
        ,iv_account_name    =>  lv_account_name     -- 6.���_����
        ,iv_inventory_date  =>  iv_inventory_date   -- 7.�I����
        ,iv_inventory_month =>  iv_inventory_month  -- 8.�I����
        ,iv_base_code       =>  iv_base_code        -- 9.���_�R�[�h
        ,iv_inv_cl_char     =>  lv_inv_cl_char      -- 10.�݌Ɋm��󎚕���
        ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- �Ώۃf�[�^�O���̏ꍇ�A���[�p���[�N�e�[�u���쐬�����I��
      EXIT WHEN lv_zero_msg IS NOT NULL;
      -- �Ώۃf�[�^�擾
      FETCH svf_data_cur INTO svf_data_rec;
      EXIT WHEN svf_data_cur%NOTFOUND;
      --
    END LOOP ins_svf_loop;
    -- �J�[�\���N���[�Y
    CLOSE svf_data_cur;
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    --  A-6.���[�N�e�[�u���f�[�^�폜
    -- ===============================
    del_svf_data(
       ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����I������
    IF (lv_zero_msg IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt;
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
      -- �J�[�\���N���[�Y
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
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
    errbuf             OUT  VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT  VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_inventory_kbn   IN   VARCHAR2,      -- 1.�I���敪
    iv_inventory_date  IN   VARCHAR2,      -- 2.�I����
    iv_inventory_month IN   VARCHAR2,      -- 3.�I����
    iv_base_code       IN   VARCHAR2       -- 4.���_
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
    --
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';              -- �R���J�����g�w�b�_�o�͐�
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
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
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
       iv_inventory_kbn   =>  iv_inventory_kbn           -- 1.�I���敪
      ,iv_inventory_date  =>  REPLACE(SUBSTRB(iv_inventory_date, 1, 10)
                                      ,cv_replace_sign)  -- 2.�I����
      ,iv_inventory_month =>  iv_inventory_month         -- 3.�I����
      ,iv_base_code       =>  iv_base_code               -- 4.���_
      ,ov_errbuf          =>  lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�̏ꍇ�A�G���[�����̃Z�b�g
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_warn_cnt   := 0;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCOI006A24R;
/
