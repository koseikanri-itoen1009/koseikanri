CREATE OR REPLACE PACKAGE BODY XXCOI006A14R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A14R(body)
 * Description      : �󕥎c���\�i�c�ƈ��j
 * MD.050           : �󕥎c���\�i�c�ƈ��j <MD050_COI_A14>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_svf_data           ���[�N�e�[�u���f�[�^�o�^(A-3)
 *  call_output_svf        SVF�N��(A-4)
 *  del_svf_data           ���[�N�e�[�u���f�[�^�폜(A-5)
 *  submain                ���C�������v���V�[�W��
 *                         �f�[�^�擾(A-2)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/26    1.0   N.Abe            �V�K�쐬
 *  2009/07/14    1.1   N.Abe            [0000462]�Q�R�[�h�擾���@�C��
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
  process_date_expt        EXCEPTION;     -- �Ɩ����t�擾�G���[
  inv_date_null_expt       EXCEPTION;     -- �I����NULL�`�F�b�N�G���[
  inv_date_type_expt       EXCEPTION;     -- �I�����̌^�`�F�b�N�G���[
  inv_month_null_expt      EXCEPTION;     -- �I����NULL�`�F�b�N�G���[
  inv_month_type_expt      EXCEPTION;     -- �I�����̌^�`�F�b�N�G���[
  get_base_expt            EXCEPTION;     -- ���_�L���`�F�b�N�G���[
  get_employee_expt        EXCEPTION;     -- �c�ƈ����݃`�F�b�N�G���[
  org_code_expt            EXCEPTION;     -- �݌ɑg�D�R�[�h�擾�G���[
  org_id_expt              EXCEPTION;     -- �݌ɑg�DID�擾�G���[
  output_expt              EXCEPTION;     -- ���[�o�̓G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOI006A14R'; -- �p�b�P�[�W��
--
  cv_xxcoi_short_name CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�h�I���F�̕��E�݌ɗ̈�
--
  --�I���敪(10:���� 20:���� 30:����)
  cv_10               CONSTANT VARCHAR2(2)   := '10';
  cv_20               CONSTANT VARCHAR2(2)   := '20';
  cv_30               CONSTANT VARCHAR2(2)   := '30';
  --���t�ϊ�
  cv_ymd              CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  --
  cv_1                CONSTANT VARCHAR2(1)   := '1';
  cv_2                CONSTANT VARCHAR2(1)   := '2';
  cv_y                CONSTANT VARCHAR2(1)   := 'Y';
  cv_type_emp         CONSTANT VARCHAR2(3)   := 'EMP';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;                                   -- �Ɩ��������t
-- == 2009/07/14 V1.1 Added START ===============================================================
  gd_target_date        DATE;
-- == 2009/07/14 V1.1 Added END   ===============================================================
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --�󕥎c���\�i�����j
  CURSOR daily_cur(
            iv_business         IN VARCHAR2
           ,iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT    papf.employee_number                emp_no              -- 1.�c�ƈ��R�[�h
             ,papf.per_information18 || papf.per_information19
                                                  emp_name            -- 2.�c�ƈ����́i�������{�������j
-- == 2009/07/14 V1.1 Modified START ===============================================================
--             ,SUBSTR(iimb.attribute2, 1, 3)       policy_group        -- 3.�Q�R�[�h
             ,SUBSTR(
                (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                        THEN iimb.attribute1                          --   �Q�R�[�h(��)
                        ELSE iimb.attribute2                          --   �Q�R�[�h(�V)
                      END
                ), 1, 3
              )                                   policy_group        -- 3.�Q�R�[�h
-- == 2009/07/14 V1.1 Modified END   ===============================================================
             ,iimb.item_no                        item_no             -- 4.�i�ڃR�[�h
             ,ximb.item_short_name                item_short_name     -- 5.���́i���i�j
             ,xird.operation_cost                 operation_cost      -- 6.�c�ƌ���
             ,xird.previous_inventory_quantity    month_begin_qty     -- 7.����I����
             ,xird.warehouse_stock          +                         --   �q�ɂ�����
              xird.vd_supplement_stock                                --   ����VD��[����
                                                  vd_sp_stock         -- 8.�q�ɂ�����
             ,xird.sales_shipped            -                         --   ����o��
              xird.sales_shipped_b                                    --   ����o�ɐU��
                                                  sales_shipped       -- 9.����o��
             ,xird.return_goods             -                         --   �ԕi
              xird.return_goods_b                                     --   �ԕi�U��
                                                  customer_return     --10.�ڋq�ԕi
             ,xird.customer_sample_ship     -                         --   �ڋq���{�o��
              xird.customer_sample_ship_b   +                         --   �ڋq���{�o�ɐU��
              xird.customer_support_ss      -                         --   �ڋq���^���{�o��
              xird.customer_support_ss_b    +                         --   �ڋq���^���{�o�ɐU��
              xird.sample_quantity          -                         --   ���{�o��
              xird.sample_quantity_b        +                         --   ���{�o�ɐU��
              xird.ccm_sample_ship          -                         --   �ڋq�L����`��A���Џ��i
              xird.ccm_sample_ship_b                                  --   �ڋq�L����`��A���Џ��i�U��
                                                  support_sample      --11.���^���{
             ,xird.inventory_change_out           inv_change_out      --12.VD�o��
             ,xird.inventory_change_in            inv_change_in       --13.VD����
             ,xird.warehouse_ship           +                         --   �q�ɂ֕Ԍ�
              xird.vd_supplement_ship                                 --   ����VD��[�o��
                                                  warehouse_ship      --14.�q�ɂ֕Ԍ�
             ,xird.book_inventory_quantity        tyoubo_stock        --15.����݌�
             ,0                                   inventory           --16.�I����
             ,0                                   inv_wear            --17.�I������
    FROM      xxcoi_inv_reception_daily   xird                        --�����݌Ɏ󕥕\�i�����j
             ,mtl_secondary_inventories   msi                         --�ۊǏꏊ�}�X�^
             ,per_all_people_f            papf                        --�]�ƈ��}�X�^
             ,mtl_system_items_b          msib                        --Disc�i��
             ,ic_item_mst_b               iimb                        --OPM�i��
             ,xxcmn_item_mst_b            ximb                        --OPM�i�ڃA�h�I��
    WHERE     papf.employee_number        = NVL(iv_business, msi.attribute3)
    AND       papf.effective_start_date  <= gd_process_date
    AND       (papf.effective_end_date   >= gd_process_date
    OR        (papf.effective_end_date   IS NULL))
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_2
    AND       msi.organization_id         = in_organization_id
    AND       xird.subinventory_code      = msi.secondary_inventory_name
    AND       xird.base_code              = iv_base_code
    AND       xird.subinventory_type      = cv_2
    AND       xird.practice_date          = TO_DATE(iv_inventory_date, cv_ymd)
    AND       xird.organization_id        = msib.organization_id
    AND       xird.inventory_item_id      = msib.inventory_item_id
    AND       msib.segment1               = iimb.item_no
    AND       iimb.item_id                = ximb.item_id
    ORDER BY  papf.employee_number
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,iimb.item_no
    ;
--
  --�󕥎c���\�i�����j
  CURSOR monthly_cur(
            iv_business         IN VARCHAR2
           ,iv_base_code        IN VARCHAR2
           ,iv_inventory_date   IN VARCHAR2
           ,iv_inventory_month  IN VARCHAR2
           ,iv_inventory_kbn    IN VARCHAR2
           ,in_organization_id  IN NUMBER)
  IS
    SELECT    papf.employee_number                emp_no              -- 1.�c�ƈ��R�[�h
             ,papf.per_information18 || papf.per_information19
                                                  emp_name            -- 2.�c�ƈ����́i�������{�������j
-- == 2009/07/14 V1.1 Modified START ===============================================================
--             ,SUBSTR(iimb.attribute2, 1, 3)       policy_group        -- 3.�Q�R�[�h
             ,SUBSTR(
                (CASE WHEN  TRUNC(TO_DATE(iimb.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                        THEN iimb.attribute1                          --   �Q�R�[�h(��)
                        ELSE iimb.attribute2                          --   �Q�R�[�h(�V)
                      END
                ), 1, 3
              )                                   policy_group        -- 3.�Q�R�[�h
-- == 2009/07/14 V1.1 Modified END   ===============================================================
             ,iimb.item_no                        item_no             -- 4.�i�ڃR�[�h
             ,ximb.item_short_name                item_short_name     -- 5.���́i���i�j
             ,xirm.operation_cost                 operation_cost      -- 6.�c�ƌ���
             ,xirm.month_begin_quantity           month_begin_qty     -- 7.����I����
             ,xirm.warehouse_stock          +                         --   �q�ɂ�����
              xirm.vd_supplement_stock                                --   ����VD��[����
                                                  vd_sp_stock         -- 8.�q�ɂ�����
             ,xirm.sales_shipped            -                         --   ����o��
              xirm.sales_shipped_b                                    --   ����o�ɐU��
                                                  sales_shipped       -- 9.����o��
             ,xirm.return_goods             -                         --   �ԕi
              xirm.return_goods_b                                     --   �ԕi�U��
                                                  customer_retuen     --10.�ڋq�ԕi
             ,xirm.customer_sample_ship     -                         --   �ڋq���{�o��
              xirm.customer_sample_ship_b   +                         --   �ڋq���{�o�ɐU��
              xirm.customer_support_ss      -                         --   �ڋq���^���{�o��
              xirm.customer_support_ss_b    +                         --   �ڋq���^���{�o�ɐU��
              xirm.sample_quantity          -                         --   ���{�o��
              xirm.sample_quantity_b        +                         --   ���{�o�ɐU��
              xirm.ccm_sample_ship          -                         --   �ڋq�L����`��A���Џ��i
              xirm.ccm_sample_ship_b                                  --   �ڋq�L����`��A���Џ��i�U��
                                                  support_sample      --11.���^���{
             ,xirm.inventory_change_out                               --12.VD�o��
             ,xirm.inventory_change_in                                --13.VD����
             ,xirm.warehouse_ship           +                         --   �q�ɂ֕Ԍ�
              xirm.vd_supplement_ship                                 --   ����VD��[�o��
                                                  warehouse_ship      --14.�q�ɂ֕Ԍ�
             ,xirm.inv_result               +                         --   �I������
              xirm.inv_result_bad           +                         --   �I�����ʁi�s�Ǖi�j
              xirm.inv_wear                                           --   �I������
                                                  tyoubo_stock        --15.����݌�
             ,xirm.inv_result               +                         --   �I������
              xirm.inv_result_bad                                     --   �I�����ʁi�s�Ǖi�j
                                                  inventory           --16.�I����
             ,xirm.inv_wear                       inv_wear            --17.�I������
    FROM      xxcoi_inv_reception_monthly xirm                        --�����݌Ɏ󕥕\�i�����j
             ,mtl_secondary_inventories   msi                         --�ۊǏꏊ�}�X�^
             ,per_all_people_f            papf                        --�]�ƈ��}�X�^
             ,mtl_system_items_b          msib                        --Disc�i��
             ,ic_item_mst_b               iimb                        --OPM�i��
             ,xxcmn_item_mst_b            ximb                        --OPM�i�ڃA�h�I��
    WHERE     papf.employee_number        = NVL(iv_business, msi.attribute3)
    AND       papf.effective_start_date  <= gd_process_date
    AND       (papf.effective_end_date   >= gd_process_date
    OR        (papf.effective_end_date   IS NULL))
    AND       msi.attribute3              = papf.employee_number
    AND       msi.attribute1              = cv_2
    AND       msi.organization_id         = in_organization_id
    AND       xirm.subinventory_code      = msi.secondary_inventory_name
    AND       xirm.base_code              = iv_base_code
    AND       xirm.subinventory_type      = cv_2
    AND       (xirm.practice_date         = TO_DATE(iv_inventory_date, cv_ymd)
    OR        xirm.practice_month         = iv_inventory_month)
    AND       xirm.inventory_kbn          = DECODE(iv_inventory_kbn, cv_20, cv_1, cv_2)
    AND       xirm.organization_id        = msib.organization_id
    AND       xirm.inventory_item_id      = msib.inventory_item_id
    AND       msib.segment1               = iimb.item_no
    AND       iimb.item_id                = ximb.item_id
    ORDER BY  papf.employee_number
             ,SUBSTR(iimb.attribute2, 1, 3)
             ,iimb.item_no
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
    iv_business         IN  VARCHAR2,                                       -- 5.�c�ƈ�
    ov_account_name     OUT VARCHAR2,                                       -- 6.���_����
    ov_emp_name         OUT VARCHAR2,                                       -- 7.�]�ƈ���
    on_organization_id  OUT NUMBER,                                         -- 8.�݌ɑg�DID
    ot_inv_kbn_name     OUT fnd_lookup_values.meaning%TYPE,                 -- 9.�I���敪����
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
    --LOOKUP
    cv_lk_list_out_div    CONSTANT  VARCHAR2(20)  := 'XXCOI1_INVENTORY_DIV';      --�󕥕\�o�͋敪
    --���b�Z�[�W
    cv_xxcoi1_msg_10330   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10330';          --�p�����[�^�I���敪
    cv_xxcoi1_msg_10099   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10099';          --�p�����[�^�I����
    cv_xxcoi1_msg_10100   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10100';          --�p�����[�^�I����
    cv_xxcoi1_msg_10096   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10096';          --�p�����[�^���_
    cv_xxcoi1_msg_10101   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10101';          --�p�����[�^�c�ƈ�
    cv_xxcoi1_msg_00011   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00011';          --�Ɩ��������t
    cv_xxcoi1_msg_10102   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10102';          --�I����NULL�`�F�b�N
    cv_xxcoi1_msg_10103   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10103';          --�I����NULL�`�F�b�N
    cv_xxcoi1_msg_10104   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10104';          --�I�����̌^�`�F�b�N
    cv_xxcoi1_msg_10105   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10105';          --�I�����̌^�`�F�b�N
    cv_xxcoi1_msg_10106   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10106';          --���_�L���`�F�b�N
    cv_xxcoi1_msg_10203   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-10203';          --�c�ƈ����݃`�F�b�N
    cv_xxcoi1_msg_00005   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00005';          --�݌ɑg�D�R�[�h
    cv_xxcoi1_msg_00006   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00006';          --�݌ɑg�DID
    --�g�[�N��
    cv_tkn_inv_type       CONSTANT  VARCHAR2(16)  := 'P_INVENTORY_TYPE';          --�g�[�N���I���敪
    cv_tkn_inv_date       CONSTANT  VARCHAR2(16)  := 'P_INVENTORY_DATE';          --�g�[�N���I����
    cv_tkn_inv_month      CONSTANT  VARCHAR2(17)  := 'P_INVENTORY_MONTH';         --�g�[�N���I����
    cv_tkn_base_code      CONSTANT  VARCHAR2(11)  := 'P_BASE_CODE';               --�g�[�N�����_
    cv_tkn_sales_staff    CONSTANT  VARCHAR2(18)  := 'P_SALES_STAFF_CODE';        --�g�[�N���c�ƈ�
    cv_tkn_pro            CONSTANT  VARCHAR2(7)   := 'PRO_TOK';                   --�g�[�N���v���t�@�C����
    cv_tkn_org_code       CONSTANT  VARCHAR2(12)  := 'ORG_CODE_TOK';              --�g�[�N���݌ɑg�D�R�[�h
    --�v���t�@�C��
    cv_prf_org_code       CONSTANT  VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  --�݌ɑg�D�R�[�h
    --���t�ϊ�
    cv_ymd_sla            CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';                --���t�ϊ��p
    cv_ym_sla             CONSTANT  VARCHAR2(7)   := 'YYYY/MM';                   --�N���ϊ��p
    cv_ym                 CONSTANT  VARCHAR2(6)   := 'YYYYMM';                    --�N���ω��p�i��؂�Ȃ��j
    -- *** ���[�J���ϐ� ***
    lv_organization_code  VARCHAR2(4);                                            --�݌ɑg�D�R�[�h
    ln_organization_id    NUMBER;                                                 --�݌ɑg�DID
--
    lt_meaning            fnd_lookup_values.meaning%TYPE;                         --���ږ�
    ld_inv_date           DATE;                                                   --���t�`�F�b�N�p
    lv_short_account_name VARCHAR2(20);                                           --���_����
    lv_emp_name           VARCHAR2(300);                                          --�]�ƈ�����
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
    --===================================
    --1.���̓p�����[�^�o��
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
    --�I�����o��
    IF (iv_inventory_date IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10099
                      ,iv_token_name1  => cv_tkn_inv_date
                      ,iv_token_value1 => TO_CHAR(TO_DATE(iv_inventory_date, cv_ymd), cv_ymd_sla)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    END IF;
--
    --�s���ȒI�����̏ꍇ�A
    --���O�o�͎���ORACLE�G���[�ƂȂ邽��
    --���O�o�͑O�Ƀ`�F�b�N
    --====================================
    --4.�I�����`�F�b�N�i�^�`�F�b�N�j
    --====================================
    --�I���敪��30:����
    IF (iv_inventory_kbn = cv_30) THEN
      --�I�������t�^�`�F�b�N
      BEGIN
        --YYYYMM�^�ɕϊ�
        ld_inv_date := TO_DATE(iv_inventory_month, cv_ym);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE inv_month_type_expt;
      END;
    END IF;
--
    --�I����
    IF (iv_inventory_month IS NOT NULL) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_short_name
                      ,iv_name         => cv_xxcoi1_msg_10100
                      ,iv_token_name1  => cv_tkn_inv_month
                      ,iv_token_value1 => TO_CHAR(TO_DATE(iv_inventory_month, cv_ym), cv_ym_sla)
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
    --�c�ƈ�
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_short_name
                    ,iv_name         => cv_xxcoi1_msg_10101
                    ,iv_token_name1  => cv_tkn_sales_staff
                    ,iv_token_value1 => iv_business
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --====================================
    --2.�Ɩ��������t�擾
    --====================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF (gd_process_date IS NULL) THEN
      RAISE process_date_expt;
    END IF;
--
    --====================================
    --3.�I�����`�F�b�N
    --====================================
    --�I���敪��10:�����A20:����
    IF    (iv_inventory_kbn IN (cv_10, cv_20)) THEN
      --�I����NULL�`�F�b�N
      IF (iv_inventory_date IS NULL) THEN
        RAISE inv_date_null_expt;
      END IF;
      --�I�������t�^�`�F�b�N
      BEGIN
        --YYYYMMDD�^�ɕϊ�
        ld_inv_date := TO_DATE(iv_inventory_date, cv_ymd);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE inv_date_type_expt;
      END;
-- == 2009/07/14 V1.1 Added START ===============================================================
      gd_target_date := ld_inv_date;
-- == 2009/07/14 V1.1 Added END   ===============================================================
    END IF;
    --====================================
    --4.�I�����`�F�b�N�iNULL�`�F�b�N�j
    --====================================
    --�I���敪��30:����
    IF (iv_inventory_kbn = cv_30) THEN
      --�I����NULL�`�F�b�N
      IF (iv_inventory_month IS NULL) THEN
        RAISE inv_month_null_expt;
      END IF;
-- == 2009/07/14 V1.1 Added START ===============================================================
      gd_target_date := LAST_DAY(TO_DATE(iv_inventory_month, cv_ym_sla));
-- == 2009/07/14 V1.1 Added END   ===============================================================
    END IF;
    --====================================
    --5.���_���̎擾
    --====================================
    BEGIN
      SELECT  SUBSTRB(hca.account_name, 1, 8)  account_name
      INTO    lv_short_account_name
      FROM    hz_cust_accounts hca
      WHERE   hca.customer_class_code = cv_1
      AND     hca.account_number      = iv_base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_base_expt;
    END;
    --====================================
    --6.�]�ƈ����̎擾
    --====================================
    IF (iv_business IS NOT NULL) THEN
      BEGIN
        SELECT  papf.per_information18 || papf.per_information19  emp_name
        INTO    lv_emp_name
        FROM    per_all_people_f  papf
        WHERE   papf.employee_number       = iv_business
        AND     papf.effective_start_date <= gd_process_date
        AND     ((papf.effective_end_date >= gd_process_date)
        OR      (papf.effective_end_date  IS NULL))
        AND     ROWNUM  = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE get_employee_expt;
      END;
    END IF;
    --====================================
    --7.�v���t�@�C������݌ɑg�D�R�[�h���擾
    --====================================
    lv_organization_code := fnd_profile.value(cv_prf_org_code);
--
    IF (lv_organization_code IS NULL) THEN
      RAISE org_code_expt;
    END IF;
--
    --====================================
    --8.�݌ɑg�D�R�[�h����݌ɑg�DID���擾
    --====================================
    ln_organization_id := xxcoi_common_pkg.get_organization_id(lv_organization_code);
--
    IF (ln_organization_id IS NULL) THEN
      RAISE org_id_expt;
    END IF;
--
    --OUT�p�����[�^�ɐݒ�
    ov_account_name     := lv_short_account_name;
    ov_emp_name         := lv_emp_name;
    on_organization_id  := ln_organization_id;
    ot_inv_kbn_name     := lt_meaning;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --*** �Ɩ����t�擾�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00011
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I����NULL�`�F�b�N�G���[ ***
    WHEN inv_date_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10102
                 ,iv_token_name1  => cv_tkn_inv_type
                 ,iv_token_value1 => lt_meaning
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I�����̌^�`�F�b�N�G���[ ***
    WHEN inv_date_type_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10104
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I����NULL�`�F�b�N�G���[ ***
    WHEN inv_month_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10103
                 ,iv_token_name1  => cv_tkn_inv_type
                 ,iv_token_value1 => lt_meaning
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �I�����̌^�`�F�b�N�G���[ ***
    WHEN inv_month_type_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10105
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** ���_�L���`�F�b�N�G���[ ***
    WHEN get_base_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10106
                 ,iv_token_name1  => cv_tkn_base_code
                 ,iv_token_value1 => iv_base_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �c�ƈ����݃`�F�b�N�G���[ ***
    WHEN get_employee_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_10203
                 ,iv_token_name1  => cv_tkn_sales_staff
                 ,iv_token_value1 => iv_business
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �݌ɑg�D�R�[�h�擾�G���[ ***
    WHEN org_code_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00005
                 ,iv_token_name1  => cv_tkn_pro
                 ,iv_token_value1 => cv_prf_org_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
    --*** �݌ɑg�DID�擾�G���[ ***
    WHEN org_id_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcoi_short_name
                 ,iv_name         => cv_xxcoi1_msg_00006
                 ,iv_token_name1  => cv_tkn_org_code
                 ,iv_token_value1 => lv_organization_code
                );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
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
   * Procedure Name   : ins_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data         IN  daily_cur%ROWTYPE,              -- 1.CSV�o�͑Ώۃf�[�^
    in_slit_id          IN  NUMBER,                         -- 2.�����A��
    iv_message          IN  VARCHAR2,                       -- 3.�O�����b�Z�[�W
    iv_inventory_kbn    IN  VARCHAR2,                       -- 4.�I���敪
    it_inv_kbn_name     IN  fnd_lookup_values.meaning%TYPE, -- 5.�I���敪����
    iv_account_name     IN  VARCHAR2,                       -- 6.���_����
    iv_emp_name         IN  VARCHAR2,                       -- 7.�]�ƈ���
    iv_inventory_date   IN  VARCHAR2,                       -- 8.�I����
    iv_inventory_month  IN  VARCHAR2,                       -- 9.�I����
    iv_base_code        IN  VARCHAR2,                       --10.���_�R�[�h
    iv_emp_no           IN  VARCHAR2,                       --11.�c�ƈ��R�[�h
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
    lv_year                   VARCHAR2(4);                                -- �N
    lv_month                  VARCHAR2(2);                                -- ��
    lv_day                    VARCHAR2(2);                                -- ��
    lv_base_code              VARCHAR2(4);                                -- ���_�R�[�h
    lt_emp_no                 per_all_people_f.employee_number%TYPE;      -- �c�ƈ��R�[�h
    lv_emp_name               VARCHAR2(300);                              -- �c�ƈ�����
    lt_policy_group           ic_item_mst_b.attribute2%TYPE;              -- �Q�R�[�h
    lt_item_code              ic_item_mst_b.item_no%TYPE;                 -- ���i�R�[�h
    lt_item_short_name        xxcmn_item_mst_b.item_short_name%TYPE;      -- ���́i���i�j
    ln_operation_cost         NUMBER;                                     -- �c�ƌ���
    ln_month_begin_qty        NUMBER;                                     -- ����I����
    ln_vd_sp_stock            NUMBER;                                     -- �q�ɂ�����
    ln_sales_shipped          NUMBER;                                     -- ����o��
    ln_customer_return        NUMBER;                                     -- �ڋq�ԕi
    ln_support_sample         NUMBER;                                     -- ���^���{
    ln_inv_change_out         NUMBER;                                     -- VD�o��
    ln_inv_change_in          NUMBER;                                     -- VD����
    ln_warehouse_ship         NUMBER;                                     -- �q�ɂ֕Ԍ�
    ln_tyoubo_stock           NUMBER;                                     -- ����݌�
    ln_inventory              NUMBER;                                     -- �I����
    ln_wear                   NUMBER;                                     -- �I������
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
    IF (iv_message IS NOT NULL) THEN
      -- �Ώی����O���̏ꍇ
      lt_emp_no           :=  iv_emp_no;                    --�c�ƈ��R�[�h
      lv_emp_name         :=  iv_emp_name;                  --�c�ƈ�����
      lt_policy_group     :=  NULL;                         --�Q�R�[�h
      lt_item_code        :=  NULL;                         --���i�R�[�h
      lt_item_short_name  :=  NULL;                         --���i����
      ln_operation_cost   :=  NULL;                         --�c�ƌ���
      ln_month_begin_qty  :=  NULL;                         --����I����
      ln_vd_sp_stock      :=  NULL;                         --�q�ɂ�����
      ln_sales_shipped    :=  NULL;                         --����o��
      ln_customer_return  :=  NULL;                         --�ڋq�ԕi
      ln_support_sample   :=  NULL;                         --���^���{
      ln_inv_change_out   :=  NULL;                         --VD�o��
      ln_inv_change_in    :=  NULL;                         --VD����
      ln_warehouse_ship   :=  NULL;                         --�q�ɂ֕Ԍ�
      ln_tyoubo_stock     :=  NULL;                         --����݌�
      ln_inventory        :=  NULL;                         --�I����
      ln_wear             :=  NULL;                         --�I������
    ELSE
      lt_emp_no           :=  ir_svf_data.emp_no;           --�c�ƈ��R�[�h
      lv_emp_name         :=  ir_svf_data.emp_name;         --�c�ƈ�����
      lt_policy_group     :=  ir_svf_data.policy_group;     --�Q�R�[�h
      lt_item_code        :=  ir_svf_data.item_no;          --���i�R�[�h
      lt_item_short_name  :=  ir_svf_data.item_short_name;  --���i����
      ln_operation_cost   :=  ir_svf_data.operation_cost;   --�c�ƌ���
      ln_month_begin_qty  :=  ir_svf_data.month_begin_qty;  --����I����
      ln_vd_sp_stock      :=  ir_svf_data.vd_sp_stock;      --�q�ɂ�����
      ln_sales_shipped    :=  ir_svf_data.sales_shipped;    --����o��
      ln_customer_return  :=  ir_svf_data.customer_return;  --�ڋq�ԕi
      ln_support_sample   :=  ir_svf_data.support_sample;   --���^���{
      ln_inv_change_out   :=  ir_svf_data.inv_change_out;   --VD�o��
      ln_inv_change_in    :=  ir_svf_data.inv_change_in;    --VD����
      ln_warehouse_ship   :=  ir_svf_data.warehouse_ship;   --�q�ɂ֕Ԍ�
      ln_tyoubo_stock     :=  ir_svf_data.tyoubo_stock;     --����݌�
      ln_inventory        :=  ir_svf_data.inventory;        --�I����
      ln_wear             :=  ir_svf_data.inv_wear;         --�I������
    END IF;
    --
    -- �󕥎c���\���[�i�c�ƈ��j���[���[�N�e�[�u���֑}��
    INSERT INTO xxcoi_rep_employee_rcpt(
       slit_id                    -- 1.�󕥎c�����ID
      ,inventory_kbn              -- 2.�I���敪�i���e�j
      ,in_out_year                -- 3.�N
      ,in_out_month               -- 4.��
      ,in_out_dat                 -- 5.��
      ,base_code                  -- 6.���_�R�[�h
      ,base_name                  -- 7.���_����
      ,employee_code              -- 8.�c�ƈ��R�[�h
      ,employee_name              -- 9.�c�ƈ�����
      ,gun_code                   --10.�Q�R�[�h
      ,item_code                  --11.���i�R�[�h
      ,item_name                  --12.���i����
      ,operation_cost             --13.�c�ƌ���
      ,first_inventory_qty        --14.����I����
      ,warehouse_stock            --15.�q�ɂ�����
      ,sales_qty                  --16.����o��
      ,customer_return            --17.�ڋq�ԕi
      ,support_qty                --18.���^���{
      ,vd_ship_qty                --19.VD�o��
      ,vd_in_qty                  --20.VD����
      ,warehouse_ship             --21.�q�ɂ֕Ԍ�
      ,tyoubo_stock_qty           --22.����݌�
      ,inventory_qty              --23.�I����
      ,genmou_qty                 --24.�I������
      ,message                    --25.���b�Z�[�W ���O���p
      ,last_update_date           --26.�ŏI�X�V��
      ,last_updated_by            --27.�ŏI�X�V��
      ,creation_date              --28.�쐬��
      ,created_by                 --29.�쐬��
      ,last_update_login          --30.�ŏI�X�V���[�U
      ,request_id                 --31.�v��ID
      ,program_application_id     --32.�v���O�����A�v���P�[�V����ID
      ,program_id                 --33.�v���O����ID
      ,program_update_date        --34.�v���O�����X�V��
    )VALUES(
       in_slit_id                 -- 1.�󕥎c�����ID
      ,it_inv_kbn_name            -- 2.�I���敪
      ,lv_year                    -- 3.�N
      ,lv_month                   -- 4.��
      ,lv_day                     -- 5.��
      ,iv_base_code               -- 6.���_�R�[�h
      ,iv_account_name            -- 7.���_����
      ,lt_emp_no                  -- 8.�c�ƈ��R�[�h
      ,lv_emp_name                -- 9.�c�ƈ�����
      ,lt_policy_group            --10.�Q�R�[�h
      ,lt_item_code               --11.���i�R�[�h
      ,lt_item_short_name         --12.���i����
      ,ln_operation_cost          --13.�c�ƌ���
      ,ln_month_begin_qty         --14.����I����
      ,ln_vd_sp_stock             --15.�q�ɂ�����
      ,ln_sales_shipped           --16.����o��
      ,ln_customer_return         --17.�ڋq�ԕi
      ,ln_support_sample          --18.���^���{
      ,ln_inv_change_out          --19.VD�o��
      ,ln_inv_change_in           --20.VD����
      ,ln_warehouse_ship          --21.�q�ɂ֕Ԍ�
      ,ln_tyoubo_stock            --22.����݌�
      ,ln_inventory               --23.�I����
      ,ln_wear                    --24.�I������
      ,iv_message                 --25.���b�Z�[�W ���O���p
      ,SYSDATE                    --26.�ŏI�X�V��
      ,cn_last_updated_by         --27.�ŏI�X�V��
      ,SYSDATE                    --28.�쐬��
      ,cn_created_by              --29.�쐬��
      ,cn_last_update_login       --30.�ŏI�X�V���[�U
      ,cn_request_id              --31.�v��ID
      ,cn_program_application_id  --32.�v���O�����A�v���P�[�V����ID
      ,cn_program_id              --33.�v���O����ID
      ,SYSDATE                    --34.�v���O�����X�V��
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
   * Description      : SVF�N��(A-4)
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
    --���b�Z�[�W
    cv_xxcoi1_msg_10088       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10088';       --���[�o�̓G���[
    -- SVF�N���֐��p�����[�^�p
    cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A14R';           -- �R���J�����g��
    cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                   -- �g���q�iPDF�j
    cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A14R';           -- ���[ID
    cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                      -- �o�͋敪
    cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A14S.xml';       -- �t�H�[���l���t�@�C����
    cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A14S.vrq';       -- �N�G���[�l���t�@�C����
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
    -- �I���p�����[�^����
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- ���[�o�̓G���[
      RAISE output_expt;
    END IF; 
--
  EXCEPTION
    --*** ���[�o�̓G���[ ***
    WHEN output_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_short_name
                     ,iv_name         => cv_xxcoi1_msg_10088
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-5)
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
    DELETE  FROM xxcoi_rep_employee_rcpt
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
    iv_business         IN  VARCHAR2,   -- 5.�c�ƈ�
    ov_errbuf           OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W
    cv_xxcoi1_msg_00008   CONSTANT  VARCHAR2(16)  := 'APP-XXCOI1-00008';  --�Ώۃf�[�^�Ȃ�
--
    -- *** ���[�J���ϐ� ***
--
    lv_zero_msg           VARCHAR2(5000);
    --
    lv_account_name       VARCHAR2(16);
    lv_emp_name           VARCHAR2(300);
    ln_organization_id    NUMBER;
    lt_inv_kbn_name       fnd_lookup_values.meaning%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
    inv_data_rec daily_cur%ROWTYPE;
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
    lv_zero_msg   := NULL;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <�������� A-1>
    -- ===============================
    init(
      iv_inventory_kbn    =>  iv_inventory_kbn    -- 1.�I���敪
     ,iv_inventory_date   =>  iv_inventory_date   -- 2.�I����
     ,iv_inventory_month  =>  iv_inventory_month  -- 3.�I����
     ,iv_base_code        =>  iv_base_code        -- 4.���_�R�[�h
     ,iv_business         =>  iv_business         -- 5.�c�ƈ�
     ,ov_account_name     =>  lv_account_name     -- 6.���_����
     ,ov_emp_name         =>  lv_emp_name         -- 7.�]�ƈ���
     ,on_organization_id  =>  ln_organization_id  -- 8.�݌ɑg�D�R�[�h
     ,ot_inv_kbn_name     =>  lt_inv_kbn_name     -- 9.�I���敪����
     ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <�f�[�^�擾 A-2>
    -- ===============================
    --�I���敪������
    IF (iv_inventory_kbn = cv_10) THEN
      OPEN  daily_cur(
              iv_business         => iv_business
             ,iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,in_organization_id  => ln_organization_id);
      FETCH daily_cur INTO inv_data_rec;
      --�Ώۃf�[�^�O��
      IF (daily_cur%NOTFOUND) THEN
        lv_zero_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                       );
      END IF;
    --�I���敪���������́A����
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      OPEN  monthly_cur(
              iv_business         => iv_business
             ,iv_base_code        => iv_base_code
             ,iv_inventory_date   => iv_inventory_date
             ,iv_inventory_month  => iv_inventory_month
             ,iv_inventory_kbn    => iv_inventory_kbn
             ,in_organization_id  => ln_organization_id);
      FETCH monthly_cur INTO inv_data_rec;
      --�Ώۃf�[�^�O��
      IF (monthly_cur%NOTFOUND) THEN
        lv_zero_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_short_name
                        ,iv_name         => cv_xxcoi1_msg_00008
                       );
      END IF;
    END IF;
--
    <<ins_work_loop>>
    LOOP
      -- �Ώی����J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      -- ===============================
      --  A-3.���[�N�e�[�u���f�[�^�o�^
      -- ===============================
      ins_svf_data(
         ir_svf_data        =>  inv_data_rec        -- 1.CSV�o�͗p�f�[�^
        ,in_slit_id         =>  gn_target_cnt       -- 2.�����A��
        ,iv_message         =>  lv_zero_msg         -- 3.�O�����b�Z�[�W
        ,iv_inventory_kbn   =>  iv_inventory_kbn    -- 4.�I���敪
        ,it_inv_kbn_name    =>  lt_inv_kbn_name     -- 5.�I���敪����
        ,iv_account_name    =>  lv_account_name     -- 6.���_����
        ,iv_emp_name        =>  lv_emp_name         -- 7.�c�ƈ�����
        ,iv_inventory_date  =>  iv_inventory_date   -- 8.�I����
        ,iv_inventory_month =>  iv_inventory_month  -- 9.�I����
        ,iv_base_code       =>  iv_base_code        --10.���_�R�[�h
        ,iv_emp_no          =>  iv_business         --11.�c�ƈ��R�[�h
        ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[����
        RAISE global_process_expt;
      END IF;
      -- �Ώۃf�[�^�O���̏ꍇ�A���[�N�e�[�u���쐬�����I��
      EXIT WHEN lv_zero_msg IS NOT NULL;
      -- �Ώۃf�[�^�擾
      --�I���敪 = ����
      IF (iv_inventory_kbn =  cv_10)  THEN
        FETCH daily_cur INTO inv_data_rec;
        EXIT WHEN daily_cur%NOTFOUND;
      --�I���敪 = �����A����
      ELSIF (iv_inventory_kbn IN (cv_20, cv_30))
      THEN
        FETCH monthly_cur INTO inv_data_rec;
        EXIT WHEN monthly_cur%NOTFOUND;
      END IF;
      --
    END LOOP ins_work_loop;
    -- �J�[�\���N���[�Y
      --�I���敪 = ����
    IF (iv_inventory_kbn = cv_10) THEN
      CLOSE daily_cur;
      --�I���敪 = �����A����
    ELSIF (iv_inventory_kbn IN (cv_20, cv_30)) THEN
      CLOSE monthly_cur;
    END IF;
    -- �R�~�b�g����
    COMMIT;
    -- ===============================
    --  A-4.SVF�N��
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
    --  A-5.���[�N�e�[�u���f�[�^�폜
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
    IF (lv_zero_msg IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      ELSIF (monthly_cur%ISOPEN) THEN
        CLOSE monthly_cur;
      END IF;
      --�G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf            OUT   VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT   VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_inventory_kbn   IN   VARCHAR2,      -- 1.�I���敪
    iv_inventory_date  IN   VARCHAR2,      -- 2.�I����
    iv_inventory_month IN   VARCHAR2,      -- 3.�I����
    iv_base_code       IN   VARCHAR2,      -- 4.���_
    iv_business        IN   VARCHAR2       -- 5.�c�ƈ�
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
       iv_inventory_kbn   =>  iv_inventory_kbn    -- 1.�I���敪
      ,iv_inventory_date  =>  iv_inventory_date   -- 2.�I����
      ,iv_inventory_month =>  iv_inventory_month  -- 3.�I����
      ,iv_base_code       =>  iv_base_code        -- 4.���_
      ,iv_business        =>  iv_business         -- 5.�c�ƈ�
      ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NOT NULL) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCOI006A14R;
/
