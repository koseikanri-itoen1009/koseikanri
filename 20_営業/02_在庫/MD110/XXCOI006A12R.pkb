CREATE OR REPLACE
PACKAGE BODY XXCOI006A12R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A12R(body)
 * Description      : �p�����[�^�œ��͂��ꂽ�N������уe�i���g(�g�g�s�^�p�Ȃ��̕ۊǏꏊ)
 *                    �����Ɍ����݌Ɏ󕥕\�ɑ��݂���i�ڋy�сA�莝�����ʂɑ��݂���i�ڂ̈�
 *                    �����쐬���܂��B
 * MD.050           : ���i���n�I���[    MD050_COI_006_A12
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  final_svf              SVF�N��                    (A-4)
 *                         ���[�N�e�[�u���f�[�^�폜   (A-5)
 *  get_data               �f�[�^�擾                 (A-2)
 *                         ���[�N�e�[�u���f�[�^�o�^   (A-3)
 *  init                   ��������                   (A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   Sai.u            �V�K�쐬
 *  2009/03/05    1.1   T.Nakamura       [��QCOI_035] �����o�͂̕s��Ή�
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
  ov_cost_errbuf              VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
  ov_cost_retcode             VARCHAR2(1);                  -- ���^�[���R�[�h
  ov_cost_errmsg              VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A12R';     -- �p�b�P�[�W��
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  cv_subinv_4        CONSTANT VARCHAR2(1)  := '4';                -- �ۊǏꏊ�敪(4:���X)
  cv_inv_kbn2        CONSTANT VARCHAR2(3)  := '2';                -- �I���敪�F����
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10084       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10084';
  cv_msg_10085       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10085';
  cv_msg_10086       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10086';
  cv_msg_10088       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10088';
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_YEAR_MONTH';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_TENANT';
  cv_yyyymmdd        CONSTANT VARCHAR2(10) := 'YYYYMMDD';
  cv_yyyymm          CONSTANT VARCHAR2(10) := 'YYYYMM';
  cv_yymm            CONSTANT VARCHAR2(10) := 'YYMM';
  cv_type_date       CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_type_month      CONSTANT VARCHAR2(10) := 'YYYY/MM';


--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- �I���敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);               -- �p�����[�^���b�Z�[�W
  gv_organization_code        VARCHAR2(30);                 -- �݌ɑg�D�R�[�h
  gn_organization_id          NUMBER;                       -- �݌ɑg�DID
  gn_target_cnt               NUMBER;                       -- �Ώی���
  gn_normal_cnt               NUMBER;                       -- ��������
  gn_error_cnt                NUMBER;                       -- �G���[����
  gn_warn_cnt                 NUMBER;                       -- �X�L�b�v����
  gd_business_date            DATE;                         -- �Ɩ����t
  gd_target_date              DATE;                         -- �Ώۓ�
--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE final_svf(
    ov_errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'final_svf'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);        -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);     -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A12S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A12S.vrq';
    lv_output_mode   CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    lv_file_name              VARCHAR2(100);      -- ���[�t�@�C����
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
    lv_file_name := cv_pkg_name
                 || TO_CHAR(SYSDATE, cv_yyyymmdd)
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-4.SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
         ov_retcode      => lv_retcode              -- ���^�[���R�[�h
        ,ov_errbuf       => lv_errbuf               -- �G���[���b�Z�[�W
        ,ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[���b�Z�[�W
        ,iv_conc_name    => cv_pkg_name             -- �R���J�����g��
        ,iv_file_name    => lv_file_name            -- �o�̓t�@�C����
        ,iv_file_id      => cv_pkg_name             -- ���[ID
        ,iv_output_mode  => lv_output_mode          -- �o�͋敪
        ,iv_frm_file     => lv_frm_file             -- �t�H�[���l���t�@�C����
        ,iv_vrq_file     => lv_vrq_file             -- �N�G���[�l���t�@�C����
        ,iv_org_id       =>  fnd_global.org_id      -- ORG_ID
        ,iv_user_name    =>  fnd_global.user_name   -- ���O�C���E���[�U��
        ,iv_resp_name    =>  fnd_global.resp_name   -- ���O�C���E���[�U�̐E�Ӗ�
        ,iv_doc_name     => NULL                    -- ������
        ,iv_printer_name => NULL                    -- �v�����^��
        ,iv_request_id   => cn_request_id           -- �v��ID
        ,iv_nodata_msg   => NULL);                  -- �f�[�^�Ȃ����b�Z�[�W
    -- �߂�l����
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10088
                       );
      lv_errbuf  := lv_errmsg;
      ov_retcode := lv_retcode;
      RAISE global_api_expt;
    END IF;
    -- A-5.���[�N�e�[�u���f�[�^�폜
    DELETE
    FROM  xxcoi_rep_practice_inventory
    WHERE request_id = cn_request_id;
    IF (gn_target_cnt <> 0) THEN
      gn_normal_cnt := SQL%ROWCOUNT;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END final_svf;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    id_practice_month     IN  VARCHAR2,      -- �N��
    iv_practice_month     IN  VARCHAR2,      -- �N��(YYMM)
    iv_tenant             IN  VARCHAR2,      -- �e�i���g
    iv_inv_name           IN  VARCHAR2,      -- �ۊǏꏊ��
    iv_base_code          IN  VARCHAR2,      -- ���_�R�[�h
    ov_errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message                VARCHAR2(500) := NULL;   -- ���b�Z�[�W
    ln_check_num              NUMBER        := 0;      -- �I���[ID
--
    -- *** ���[�J���E�J�[�\��(A-2-2) ***
    CURSOR pickout_cur
    IS
      SELECT  msi.description                 description                   -- �ۊǏꏊ����
             ,msi.attribute7                  base_code                     -- ���_�R�[�h
             ,sib.sp_supplier_code            sp_supplier_code              -- ���X�d����R�[�h
             ,sib.item_code                   item_code                     -- �i���R�[�h
             ,SUBSTR(
                 (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, cv_type_date)) > TRUNC(gd_target_date)
                        THEN  iib.attribute1                                -- �Q�R�[�h(��)
                        ELSE  iib.attribute2                                -- �Q�R�[�h(�V)
                  END
                 ), 1, 3
              )                               gun_code                      -- �Q�R�[�h
             ,imb.item_short_name             item_short_name               -- ����
             ,xirm.month_begin_quantity       month_begin_quantity          -- ����c���i���v�j
      FROM    (SELECT   sub_xirm.subinventory_code              subinventory_code
                       ,sub_xirm.inventory_item_id              inventory_item_id
                       ,sub_xirm.organization_id                organization_id
                       ,SUM(sub_xirm.month_begin_quantity)      month_begin_quantity
               FROM     xxcoi_inv_reception_monthly     sub_xirm            -- �����݌Ɏ󕥕\(����)
               WHERE    sub_xirm.subinventory_code      =   NVL(iv_tenant, sub_xirm.subinventory_code)
               AND      sub_xirm.organization_id        =   gn_organization_id
               AND      sub_xirm.subinventory_type      =   cv_subinv_4
               AND      sub_xirm.practice_month         =   TO_CHAR(ADD_MONTHS(id_practice_month, -1), cv_yyyymm)
               AND      sub_xirm.inventory_kbn          =   cv_inv_kbn2     -- �I���敪(����)
               GROUP BY sub_xirm.subinventory_code
                       ,sub_xirm.inventory_item_id
                       ,sub_xirm.organization_id
              )                               xirm
             ,mtl_secondary_inventories       msi                           -- �ۊǏꏊ�}�X�^(INV)
             ,mtl_system_items_b              msib                          -- Disc�i��        (INV)
             ,ic_item_mst_b                   iib                           -- OPM�i��         (GMI)
             ,xxcmn_item_mst_b                imb                           -- OPM�i�ڃA�h�I�� (XXCMN)
             ,xxcmm_system_items_b            sib                           -- Disc�i�ڃA�h�I��(XXCMM)
      WHERE   xirm.subinventory_code      =   msi.secondary_inventory_name
      AND     xirm.organization_id        =   msi.organization_id
      AND     msi.attribute1              =   cv_subinv_4                   -- �ۊǏꏊ�敪(���X)
      AND     TRUNC(NVL(msi.disable_date, gd_target_date)) >= TRUNC(gd_target_date)
      AND     xirm.inventory_item_id      =   msib.inventory_item_id
      AND     xirm.organization_id        =   msib.organization_id
      AND     msib.segment1               =   iib.item_no
      AND     iib.item_id                 =   imb.item_id
      AND     imb.item_id                 =   sib.item_id;
    --
    CURSOR onhand_cur
    IS
      SELECT  msi.description                 description                   -- �ۊǏꏊ����
             ,msi.attribute7                  base_code                     -- ���_�R�[�h
             ,sib.sp_supplier_code            sp_supplier_code              -- ���X�d����R�[�h
             ,sib.item_code                   item_code                     -- �i���R�[�h
             ,SUBSTR(
                 (CASE  WHEN  TRUNC(TO_DATE(iib.attribute3, cv_type_date)) > TRUNC(gd_target_date)
                        THEN  iib.attribute1                                -- �Q�R�[�h(��)
                        ELSE  iib.attribute2                                -- �Q�R�[�h(�V)
                  END
                 ), 1, 3
              )                               gun_code                      -- �Q�R�[�h
             ,imb.item_short_name             item_short_name               -- ����
             ,0                               month_begin_quantity          -- ����c���i���v�j
      FROM    (SELECT DISTINCT
                      sub_oqd.inventory_item_id
                     ,sub_oqd.subinventory_code
                     ,sub_oqd.organization_id
               FROM   mtl_onhand_quantities_detail    sub_oqd               -- �莝����        (INV)
               WHERE  sub_oqd.subinventory_code   =   NVL(iv_tenant, sub_oqd.subinventory_code)
               AND    sub_oqd.organization_id     =   gn_organization_id
              )                               oqd                           -- �莝���ʏ��
             ,mtl_secondary_inventories       msi                           -- �ۊǏꏊ�}�X�^  (INV)
             ,mtl_system_items_b              msib                          -- Disc�i��        (INV)
             ,ic_item_mst_b                   iib                           -- OPM�i��         (GMI)
             ,xxcmn_item_mst_b                imb                           -- OPM�i�ڃA�h�I�� (XXCMN)
             ,xxcmm_system_items_b            sib                           -- Disc�i�ڃA�h�I��(XXCMM)
      WHERE   oqd.subinventory_code       =   msi.secondary_inventory_name
      AND     oqd.organization_id         =   msi.organization_id
      AND     msi.attribute1              =   cv_subinv_4                     -- �ۊǏꏊ�敪(���X)
      AND     TRUNC(NVL(msi.disable_date, gd_target_date)) >= TRUNC(gd_target_date)
      AND     oqd.inventory_item_id       =   msib.inventory_item_id
      AND     oqd.organization_id         =   msib.organization_id
      AND     msib.segment1               =   iib.item_no
      AND     iib.item_id                 =   imb.item_id
      AND     imb.item_id                 =   sib.item_id
      AND NOT EXISTS(
                SELECT  1
                FROM    xxcoi_rep_practice_inventory    xrpi
                WHERE   xrpi.request_id         =   cn_request_id
                AND     xrpi.base_code          =   msi.attribute7
                AND     xrpi.subinventory_name  =   msi.description
                AND     xrpi.item_code          =   sib.item_code
      );
    -- *** ���[�J���E���R�[�h ***
    pickout_rec   pickout_cur%ROWTYPE;
    onhand_rec    onhand_cur%ROWTYPE;
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
  OPEN pickout_cur;
  LOOP
    FETCH pickout_cur INTO pickout_rec;
    EXIT WHEN pickout_cur%NOTFOUND;
    -- �I���[ID���J�E���g
    ln_check_num  := ln_check_num  + 1;
    -- �Ώی������J�E���g
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.���[�N�e�[�u���f�[�^�o�^�i�����݌ɂ��j
    INSERT INTO xxcoi_rep_practice_inventory(
            slit_id                                                   -- �I���[ID
           ,inventory_year                                            -- �N
           ,inventory_month                                           -- ��
           ,base_code                                                 -- ���_�R�[�h
           ,subinventory_name                                         -- �I���ꏊ��
           ,stockplace_code                                           -- �d����R�[�h
           ,gun_code                                                  -- �Q�R�[�h
           ,item_code                                                 -- �i���R�[�h
           ,item_name                                                 -- �i��
           ,first_inventory_qty                                       -- ����c��
           ,message                                                   -- ���b�Z�[�W
           ,last_update_date                                          -- �ŏI�X�V��
           ,last_updated_by                                           -- �ŏI�X�V��
           ,creation_date                                             -- �쐬��
           ,created_by                                                -- �쐬��
           ,last_update_login                                         -- �ŏI�X�V���[�U
           ,request_id                                                -- �v��ID
           ,program_application_id                                    -- �v���O�����A�v���P�[�V����ID
           ,program_id                                                -- �v���O����ID
           ,program_update_date)                                      -- �v���O�����X�V��
    VALUES (ln_check_num                                              -- �I���[ID
           ,SUBSTR(iv_practice_month,1,2)                             -- �N
           ,SUBSTR(iv_practice_month,3,2)                             -- ��
           ,pickout_rec.base_code                                     -- ���_�R�[�h
           ,pickout_rec.description                                   -- �I���ꏊ��
           ,SUBSTR(pickout_rec.sp_supplier_code, 1, 4)                -- �d����R�[�h
           ,pickout_rec.gun_code                                      -- �Q�R�[�h
           ,SUBSTR(pickout_rec.item_code, 1, 7)                       -- �i���R�[�h
           ,pickout_rec.item_short_name                               -- �i��
           ,pickout_rec.month_begin_quantity                          -- ����c��
           ,NULL                                                      -- ���b�Z�[�W
           ,SYSDATE                                                   -- �ŏI�X�V��
           ,cn_last_updated_by                                        -- �ŏI�X�V��
           ,SYSDATE                                                   -- �쐬��
           ,cn_created_by                                             -- �쐬��
           ,cn_last_update_login                                      -- �ŏI�X�V���[�U
           ,cn_request_id                                             -- �v��ID
           ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
           ,cn_program_id                                             -- �v���O����ID
           ,SYSDATE);                                                 -- �v���O�����X�V��
  --
  END LOOP;
  CLOSE pickout_cur;
  --
  OPEN  onhand_cur;
  LOOP
    FETCH onhand_cur INTO onhand_rec;
    EXIT WHEN onhand_cur%NOTFOUND;
    -- �I���[ID���J�E���g
    ln_check_num  := ln_check_num  + 1;
    -- �Ώی������J�E���g
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.���[�N�e�[�u���f�[�^�o�^�i�莝���ʂ��j
    INSERT INTO xxcoi_rep_practice_inventory(
            slit_id                                                   -- �I���[ID
           ,inventory_year                                            -- �N
           ,inventory_month                                           -- ��
           ,base_code                                                 -- ���_�R�[�h
           ,subinventory_name                                         -- �I���ꏊ��
           ,stockplace_code                                           -- �d����R�[�h
           ,gun_code                                                  -- �Q�R�[�h
           ,item_code                                                 -- �i���R�[�h
           ,item_name                                                 -- �i��
           ,first_inventory_qty                                       -- ����c��
           ,message                                                   -- ���b�Z�[�W
           ,last_update_date                                          -- �ŏI�X�V��
           ,last_updated_by                                           -- �ŏI�X�V��
           ,creation_date                                             -- �쐬��
           ,created_by                                                -- �쐬��
           ,last_update_login                                         -- �ŏI�X�V���[�U
           ,request_id                                                -- �v��ID
           ,program_application_id                                    -- �v���O�����A�v���P�[�V����ID
           ,program_id                                                -- �v���O����ID
           ,program_update_date)                                      -- �v���O�����X�V��
    VALUES (ln_check_num                                              -- �I���[ID
           ,SUBSTR(iv_practice_month,1,2)                             -- �N
           ,SUBSTR(iv_practice_month,3,2)                             -- ��
           ,onhand_rec.base_code                                      -- ���_�R�[�h
           ,onhand_rec.description                                    -- �I���ꏊ��
           ,SUBSTR(onhand_rec.sp_supplier_code, 1, 4)                 -- �d����R�[�h
           ,onhand_rec.gun_code                                       -- �Q�R�[�h
           ,SUBSTR(onhand_rec.item_code, 1, 7)                        -- �i���R�[�h
           ,onhand_rec.item_short_name                                -- �i��
           ,onhand_rec.month_begin_quantity                           -- ����c��
           ,NULL                                                      -- ���b�Z�[�W
           ,SYSDATE                                                   -- �ŏI�X�V��
           ,cn_last_updated_by                                        -- �ŏI�X�V��
           ,SYSDATE                                                   -- �쐬��
           ,cn_created_by                                             -- �쐬��
           ,cn_last_update_login                                      -- �ŏI�X�V���[�U
           ,cn_request_id                                             -- �v��ID
           ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
           ,cn_program_id                                             -- �v���O����ID
           ,SYSDATE);                                                 -- �v���O�����X�V��
  --
  END LOOP;
  CLOSE onhand_cur;
  --
  -- ����0���̏ꍇ
  IF (ln_check_num = 0) THEN
    -- ����0�����b�Z�[�W�擾
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    -- ����0�����b�Z�[�W�o��
    INSERT INTO xxcoi_rep_practice_inventory(
            slit_id                                                   -- �I���[ID
           ,inventory_year                                            -- �N
           ,inventory_month                                           -- ��
           ,base_code                                                 -- ���_�R�[�h
           ,subinventory_name                                         -- �I���ꏊ��
           ,stockplace_code                                           -- �d����R�[�h
           ,gun_code                                                  -- �Q�R�[�h
           ,item_code                                                 -- �i���R�[�h
           ,item_name                                                 -- �i��
           ,first_inventory_qty                                       -- ����c��
           ,message                                                   -- ���b�Z�[�W
           ,last_update_date                                          -- �ŏI�X�V��
           ,last_updated_by                                           -- �ŏI�X�V��
           ,creation_date                                             -- �쐬��
           ,created_by                                                -- �쐬��
           ,last_update_login                                         -- �ŏI�X�V���[�U
           ,request_id                                                -- �v��ID
           ,program_application_id                                    -- �v���O�����A�v���P�[�V����ID
           ,program_id                                                -- �v���O����ID
           ,program_update_date)                                      -- �v���O�����X�V��
    VALUES (ln_check_num                                              -- �I���[ID
           ,SUBSTR(iv_practice_month,1,2)                             -- �N
           ,SUBSTR(iv_practice_month,3,2)                             -- ��
           ,iv_base_code                                              -- ���_�R�[�h
           ,iv_inv_name                                               -- �I���ꏊ��
           ,NULL                                                      -- �d����R�[�h
           ,NULL                                                      -- �Q�R�[�h
           ,NULL                                                      -- �i���R�[�h
           ,NULL                                                      -- �i��
           ,NULL                                                      -- ����c��
           ,lv_message                                                -- ���b�Z�[�W
           ,SYSDATE                                                   -- �ŏI�X�V��
           ,cn_last_updated_by                                        -- �ŏI�X�V��
           ,SYSDATE                                                   -- �쐬��
           ,cn_created_by                                             -- �쐬��
           ,cn_last_update_login                                      -- �ŏI�X�V���[�U
           ,cn_request_id                                             -- �v��ID
           ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
           ,cn_program_id                                             -- �v���O����ID
           ,SYSDATE);                                                 -- �v���O�����X�V��
  END IF;
  -- �R�~�b�g
  COMMIT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      IF (pickout_cur%ISOPEN) THEN
        CLOSE pickout_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (pickout_cur%ISOPEN) THEN
        CLOSE pickout_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   **********************************************************************************/
  PROCEDURE init(
    iv_practice_month     IN  VARCHAR2,    -- �N��
    iv_tenant             IN  VARCHAR2,    -- �e�i���g
    ov_practice_month     OUT VARCHAR2,    -- �N��(YYMM)
    od_practice_month     OUT DATE,        -- �N��(DATE)
    ov_inv_name           OUT VARCHAR2,    -- �I���ꏊ��
    ov_base_code          OUT VARCHAR2,    -- ���_�R�[�h
    ov_errbuf             OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    ld_practice_month    DATE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    BEGIN
      ld_practice_month := TO_DATE(iv_practice_month, cv_yyyymm);
      ov_practice_month := TO_CHAR(ld_practice_month, cv_yymm);
    EXCEPTION
      WHEN OTHERS THEN
        ld_practice_month := TO_DATE(iv_practice_month, cv_type_month);
        ov_practice_month := TO_CHAR(ld_practice_month, cv_yymm);
    END;
--
    -- A-1-1.�R���J�����g���̓p�����[�^�����O�ɏo��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10084
                    ,iv_token_name1  => cv_p_token1   -- �N��
                    ,iv_token_value1 => TO_CHAR(ld_practice_month, cv_type_month)
                    ,iv_token_name2  => cv_p_token2   -- �e�i���g
                    ,iv_token_value2 => iv_tenant
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    od_practice_month := ld_practice_month;
    -- A-1-2.���ʊ֐�(�݌ɑg�D�R�[�h�擾)���g�p���v���t�@�C�����݌ɑg�D�R�[�h���擾���܂��B
    gv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    --
    IF (gv_organization_code IS NULL) THEN
      -- �v���t�@�C��:�݌ɑg�D�R�[�h( &PRO_TOK )�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00005
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-3.��L2.�Ŏ擾�����݌ɑg�D�R�[�h�����Ƃɋ��ʕ��i(�݌ɑg�DID�擾)���݌ɑg�DID�擾���܂��B
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    --
    IF (gn_organization_id IS NULL) THEN
      -- �݌ɑg�D�R�[�h( &ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00006
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-4.���ʊ֐�(�Ɩ��������t�擾)���Ɩ����t���擾���܂��B
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_business_date IS NULL) THEN
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00011
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-5.�N���p�����[�^�`�F�b�N
    IF (TO_CHAR(ld_practice_month, cv_yyyymm) > TO_CHAR(gd_business_date, cv_yyyymm)) THEN
      -- �N���p�����[�^.�N���͖�����
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10085
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-6.�Ώۓ��̐ݒ�
    IF (LAST_DAY(ld_practice_month) > gd_business_date) THEN
      gd_target_date := gd_business_date;
    ELSE
      gd_target_date := LAST_DAY(ld_practice_month);   -- �N���̖���
    END IF;
    -- A-1-7.�I���ꏊ������ы��_�R�[�h�̎擾
    BEGIN
      IF (iv_tenant IS NOT NULL) THEN
        SELECT description
              ,attribute7
        INTO   ov_inv_name
              ,ov_base_code
        FROM   mtl_secondary_inventories
        WHERE  organization_id          = gn_organization_id
        AND    secondary_inventory_name = iv_tenant
        AND    attribute1               = cv_subinv_4
        AND    TRUNC(NVL(disable_date,gd_target_date))
                                       >= TRUNC(gd_target_date)
        AND    ROWNUM = 1;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �e�i���g����
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10086
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_practice_month     IN  VARCHAR2,     -- �N��
    iv_tenant             IN  VARCHAR2,     -- �e�i���g
    ov_errbuf             OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_practice_month    DATE;                    -- �N��
    lv_practice_month    VARCHAR2(4)   := NULL;   -- �N��(YYMM)
    lv_inv_name          VARCHAR2(200) := NULL;   -- �I���ꏊ��
    lv_base_code         VARCHAR2(200) := NULL;   -- ���_�R�[�h
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
    -- ��������(init)
    -- ===============================
    init(
      iv_practice_month  => iv_practice_month     -- �N��
     ,iv_tenant          => iv_tenant             -- �e�i���g
     ,ov_practice_month  => lv_practice_month     -- �N��(YYMM)
     ,od_practice_month  => ld_practice_month     -- �N��(DATE)
     ,ov_inv_name        => lv_inv_name           -- �I���ꏊ��
     ,ov_base_code       => lv_base_code          -- ���_�R�[�h
     ,ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- �f�[�^�擾(get_data)
    -- ===============================
    get_data(
      id_practice_month  => ld_practice_month     -- �N��(DATE)
     ,iv_practice_month  => lv_practice_month     -- �N��(YYMM)
     ,iv_tenant          => iv_tenant             -- �e�i���g
     ,iv_inv_name        => lv_inv_name           -- �I���ꏊ��
     ,iv_base_code       => lv_base_code          -- ���_�R�[�h
     ,ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
    -- ===============================
    -- SVF�N���������ďo��(final_svf)
    -- ===============================
    final_svf(
        ov_errbuf  => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    errbuf                OUT VARCHAR2,           -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT VARCHAR2,           -- �G���[�R�[�h     #�Œ�#
    iv_practice_month     IN  VARCHAR2,           -- �N��
    iv_tenant             IN  VARCHAR2            -- �e�i���g
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
    cv_log_name        CONSTANT VARCHAR2(100) := 'LOG';               -- �w�b�_���b�Z�[�W�o�͊֐��p�����[�^
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);        -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);     -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code           VARCHAR2(100);
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_name
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       iv_practice_month  => iv_practice_month    -- �N��
      ,iv_tenant          => iv_tenant            -- �e�i���g
      ,ov_errbuf          => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
END XXCOI006A12R;
/
