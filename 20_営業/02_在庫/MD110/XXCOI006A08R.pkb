CREATE OR REPLACE
PACKAGE BODY XXCOI006A08R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A08R(body)
 * Description      : �v���̔��s��ʂ���A�i�ږ��̖��ׂ���ђI�����ʂ𒠕[�ɏo�͂��܂��B
 *                    ���[�ɏo�͂����I�����ʃf�[�^�ɂ͏����σt���O"Y"��ݒ肵�܂��B
 * MD.050           : �I���`�F�b�N���X�g    MD050_COI_006_A08
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  final_svf              SVF�N��                    (A-5)
 *                         ���[�N�e�[�u���f�[�^�폜   (A-6)
 *  get_data               �f�[�^�擾                 (A-2)
 *                         ���[�N�e�[�u���f�[�^�o�^   (A-3)
 *                         �����σt���O�X�V           (A-4)
 *  init                   ��������                   (A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.0   Sai.u            �V�K�쐬
 *  2009/02/16    1.1   N.Abe            [��QCOI_006] ���o�����̕s���Ή�
 *  2009/02/18    1.2   N.Abe            [��QCOI_019] �Ǖi�敪�擾�p�R�[�h�C���Ή�
 *  2009/03/05    1.3   T.Nakamura       [��QCOI_033] �����o�͂̕s��Ή�
 *  2009/03/23    1.4   H.Sasaki         [��QT1_0107] ���o�����̏C��
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
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A08R';     -- �p�b�P�[�W��
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  cv_inv_kbn1        CONSTANT VARCHAR2(3)  := '1';                -- �I���敪�F����
  cv_inv_kbn2        CONSTANT VARCHAR2(3)  := '2';                -- �I���敪�F����
  cv_output_kbn      CONSTANT VARCHAR2(3)  := '0';                -- �o�͋敪�F���o��
  cv_goods_kbn       CONSTANT VARCHAR2(3)  := '1';                -- �Ǖi�敪�F�s�Ǖi
  -- �ۊǏꏊ�敪�i1:�q��  2:�c�Ǝ�  3:�a����  4:���X  5:���̋@  8:�����j
  cv_subinv_1      CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2      CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3      CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4      CONSTANT VARCHAR2(1)  :=  '4';
  cv_subinv_5      CONSTANT VARCHAR2(1)  :=  '5';
  cv_subinv_8      CONSTANT VARCHAR2(1)  :=  '8';
  -- ���b�Z�[�W�֘A
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10088       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10088';
  cv_msg_10091       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10091';
  cv_msg_10092       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10092';
  cv_msg_10093       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10093';
  cv_msg_10362       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10362';
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_xxcoi_inv_kbn   CONSTANT VARCHAR2(30) := 'XXCOI1_INVENTORY_KBN';
  cv_xxcoi_inv_out   CONSTANT VARCHAR2(30) := 'XXCOI1_INVOUT_KBN';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_INVENTORY_TYPE';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_INV_DATE';
  cv_p_token3        CONSTANT VARCHAR2(30) := 'P_YEAR_MONTH';
  cv_p_token4        CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_p_token5        CONSTANT VARCHAR2(30) := 'P_INVENTORY_LOCATION';
  cv_p_token6        CONSTANT VARCHAR2(30) := 'P_OUT_TYPE';
  --�Q�ƃ^�C�v
  cv_qual_good_dv    CONSTANT VARCHAR2(29) := 'XXCOI1_QUALITY_GOODS_DIVISION';
  cv_not_qual_goods  CONSTANT VARCHAR2(1)  := '1';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- �I���敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);                 -- �p�����[�^���b�Z�[�W
  gv_user_basecode            VARCHAR2(4);                    -- �������_
  gv_organization_code        VARCHAR2(30);                   -- �݌ɑg�D�R�[�h
  gn_organization_id          NUMBER;                         -- �݌ɑg�DID
  gn_target_cnt               NUMBER;                         -- �Ώی���
  gn_normal_cnt               NUMBER;                         -- ��������
  gn_error_cnt                NUMBER;                         -- �G���[����
  gn_warn_cnt                 NUMBER;                         -- �X�L�b�v����
  gd_business_date            DATE;                           -- �Ɩ����t
  gd_target_date              DATE;                           -- �Ώۓ�
  gt_goods_name               fnd_lookup_values.meaning%TYPE; -- �Ǖi�敪����(�s�Ǖi)
--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF�N��(A-5)
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
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A08S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A08S.vrq';
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
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-5.SVF�N��
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- A-6.���[�N�e�[�u���f�[�^�폜
    DELETE
    FROM  xxcoi_rep_inv_checklist
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
      ov_retcode := cv_status_error;
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
    iv_inventory_kbn      IN  VARCHAR2,      -- �I���敪
    id_practice_date      IN  DATE,          -- �N����
    iv_practice_month     IN  VARCHAR2,      -- �N��
    iv_base_code          IN  VARCHAR2,      -- ���_
    iv_inventory_place    IN  VARCHAR2,      -- �I���ꏊ
    iv_output_kbn         IN  VARCHAR2,      -- �o�͋敪
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
    lv_base_name              VARCHAR2(200) := NULL;   -- ���_��
    lv_inv_name               VARCHAR2(200) := NULL;   -- �ۊǏꏊ��
    lv_message                VARCHAR2(500) := NULL;   -- ���b�Z�[�W
    ln_check_num              NUMBER        := 0;      -- �`�F�b�N���X�gID
--
    -- *** ���[�J���E�J�[�\��(A-2-2) ***
-- == 2009/03/23 V1.4 Modified START ===============================================================
--    CURSOR pickout_cur
--    IS
--    SELECT xir.ROWID                      xir_row_id                    -- ROWID
--          ,xir.base_code                  xir_base_code                 -- ���_�R�[�h
--          ,biv.base_short_name            biv_base_short_name           -- ���_����
--          ,msi.secondary_inventory_name   msi_secondary_inventory_name  -- �ۊǏꏊ�R�[�h
--          ,msi.description                msi_description               -- �ۊǏꏊ����
--          ,xir.inventory_date             xir_inventory_date            -- �I����
--          ,xir.slip_no                    xir_slip_no                   -- �`�[No
--          ,xir.item_code                  xir_item_code                 -- �i�ڃR�[�h
--          ,imb.item_short_name            imb_item_short_name           -- �i��
--          ,xir.case_in_qty                xir_case_in_qty               -- ����
--          ,xir.case_qty                   xir_case_qty                  -- �P�[�X��
--          ,xir.quantity                   xir_quantity                  -- �{��
--          ,xir.quality_goods_kbn          xir_quality_goods_kbn         -- �Ǖi�敪
--          ,xir.input_order                xir_input_order               -- �捞�ݏ�
--    FROM   xxcoi_inv_result               xir                           -- HHT�I�����ʃe�[�u��(XXCOI)
--          ,xxcoi_inv_control              xic                           -- �I���Ǘ��e�[�u��   (XXCOI)
--          ,mtl_secondary_inventories      msi                           -- �ۊǏꏊ�}�X�^     (INV)
--          ,xxcmn_item_mst_b               imb                           -- OPM�i�ڃA�h�I��    (XXCMN)
--          ,ic_item_mst_b                  iib                           -- OPM�i�ڃ}�X�^      (GMI)
--          ,xxcoi_base_info2_v             biv                           -- ���_���r���[     (XXCOI)
--    WHERE  xir.inventory_kbn            = iv_inventory_kbn              -- �I���敪
--    AND   (   (TO_CHAR(xir.inventory_date, 'YYYYMM') = iv_practice_month)
--           OR (TRUNC(xir.inventory_date)    = TRUNC(id_practice_date))
--          )
--    AND    biv.base_code                = xir.base_code
--    AND    biv.focus_base_code          = NVL(iv_base_code,gv_user_basecode)
--    AND    msi.organization_id          = gn_organization_id
--    AND    xic.inventory_seq            = xir.inventory_seq
--    AND    xic.subinventory_code        = NVL(iv_inventory_place, xic.subinventory_code)
--    AND    msi.secondary_inventory_name = xic.subinventory_code
--    AND    msi.attribute1              <> cv_subinv_5                   -- �ۊǏꏊ�敪�����̋@
--    AND    msi.attribute1              <> cv_subinv_8                   -- �ۊǏꏊ�敪������
--    AND    msi.attribute7               = xir.base_code
--    AND    TRUNC(NVL(msi.disable_date, gd_target_date))  >=  TRUNC(gd_target_date)
--    AND    iib.item_no                  = xir.item_code
--    AND    iib.item_id                  = imb.item_id
--    AND    xir.process_flag             = DECODE(iv_output_kbn,'1','Y','N')
--
    CURSOR pickout_cur(iv_cur_base_code IN  VARCHAR2)
    IS
      SELECT  xir.ROWID                         xir_row_id                    -- ROWID
             ,xir.base_code                     xir_base_code                 -- ���_�R�[�h
             ,SUBSTRB(hca.account_name, 1, 8)   biv_base_short_name           -- ���_����
             ,msi.secondary_inventory_name      msi_secondary_inventory_name  -- �ۊǏꏊ�R�[�h
             ,msi.description                   msi_description               -- �ۊǏꏊ����
             ,xir.inventory_date                xir_inventory_date            -- �I����
             ,xir.slip_no                       xir_slip_no                   -- �`�[No
             ,xir.item_code                     xir_item_code                 -- �i�ڃR�[�h
             ,imb.item_short_name               imb_item_short_name           -- �i��
             ,xir.case_in_qty                   xir_case_in_qty               -- ����
             ,xir.case_qty                      xir_case_qty                  -- �P�[�X��
             ,xir.quantity                      xir_quantity                  -- �{��
             ,xir.quality_goods_kbn             xir_quality_goods_kbn         -- �Ǖi�敪
             ,xir.input_order                   xir_input_order               -- �捞�ݏ�
      FROM    xxcoi_inv_result                  xir                           -- HHT�I�����ʃe�[�u��(XXCOI)
             ,xxcoi_inv_control                 xic                           -- �I���Ǘ��e�[�u��   (XXCOI)
             ,mtl_secondary_inventories         msi                           -- �ۊǏꏊ�}�X�^     (INV)
             ,xxcmn_item_mst_b                  imb                           -- OPM�i�ڃA�h�I��    (XXCMN)
             ,ic_item_mst_b                     iib                           -- OPM�i�ڃ}�X�^      (GMI)
             ,(SELECT   xca.management_base_code    management_base_code
                       ,NVL(xca.dept_hht_div, '2')  dept_hht_div
                       ,hca.account_number          account_number
               FROM     xxcmm_cust_accounts         xca
                       ,hz_cust_accounts            hca
               WHERE    xca.customer_id         =   hca.cust_account_id
               AND      hca.account_number      =   iv_cur_base_code
               AND      hca.customer_class_code =   '1'
               AND      hca.status              =   'A'
              )                                 cai                           -- ���_���
             ,hz_cust_accounts                  hca                           -- �ڋq�}�X�^
      WHERE   xir.inventory_kbn                           = iv_inventory_kbn  -- �I���敪
      AND     (   (TO_CHAR(xir.inventory_date, 'YYYYMM')  = iv_practice_month)
               OR (TRUNC(xir.inventory_date)              = TRUNC(id_practice_date))
              )
      AND     (   (   (   (cai.dept_hht_div         = '1')
                       OR (cai.management_base_code IS NULL)
                      )
                   AND  xir.base_code             = NVL(cai.management_base_code, iv_cur_base_code)
                  )
               OR (     cai.dept_hht_div         <> '1'
                   AND  cai.management_base_code  = cai.account_number
                   AND  xir.base_code            IN (SELECT  hca.account_number
                                                     FROM    xxcmm_cust_accounts         xca
                                                            ,hz_cust_accounts            hca
                                                     WHERE   xca.customer_id          =  hca.cust_account_id
                                                     AND     xca.management_base_code =  cai.management_base_code
                                                     AND     hca.customer_class_code  =  '1'
                                                     AND     hca.status               =  'A'
                                                   )
                  )
               OR (     cai.dept_hht_div         <> '1'
                   AND  cai.management_base_code <> cai.account_number
                   AND  xir.base_code             = NVL(cai.account_number, iv_cur_base_code)
                  )
              )
      AND     msi.organization_id          = gn_organization_id
      AND     xic.inventory_seq            = xir.inventory_seq
      AND     xic.subinventory_code        = NVL(iv_inventory_place, xic.subinventory_code)
      AND     msi.secondary_inventory_name = xic.subinventory_code
      AND     msi.attribute1              <> cv_subinv_5                   -- �ۊǏꏊ�敪�����̋@
      AND     msi.attribute1              <> cv_subinv_8                   -- �ۊǏꏊ�敪������
      AND     (   (cai.management_base_code       = iv_cur_base_code)
               OR (    (cai.management_base_code <> iv_cur_base_code)
                   AND (msi.attribute7            = iv_cur_base_code)
                  )
               OR (    (cai.management_base_code IS NULL)
                   AND (msi.attribute7            = iv_cur_base_code)
                  )
              )
      AND     TRUNC(NVL(msi.disable_date, gd_target_date))  >=  TRUNC(gd_target_date)
      AND     iib.item_no                  = xir.item_code
      AND     iib.item_id                  = imb.item_id
      AND     xir.process_flag             = DECODE(iv_output_kbn, '1', 'Y', 'N')
      AND     (   (    cai.dept_hht_div             = '1'
                   AND hca.account_number           = NVL(cai.management_base_code, iv_cur_base_code)
                  )
               OR (    cai.dept_hht_div            <> '1'
                   AND hca.account_number           = xir.base_code
                  )
              )
      FOR UPDATE OF
             xir.process_flag NOWAIT
      ORDER BY
             xir.base_code                                  -- ���_�R�[�h
            ,msi.secondary_inventory_name                   -- �ۊǏꏊ�R�[�h
            ,xir.slip_no                                    -- �`�[No.
            ,xir.input_order;                               -- ��荞�ݏ�
-- == 2009/03/23 V1.4 Modified END   ===============================================================
--
    -- *** ���[�J���E���R�[�h ***
    pickout_rec pickout_cur%ROWTYPE;
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
-- == 2009/03/23 V1.4 Modified START ===============================================================
--  OPEN pickout_cur;
  OPEN pickout_cur(NVL(iv_base_code, gv_user_basecode));
-- == 2009/03/23 V1.4 Modified END   ===============================================================
  LOOP
    FETCH pickout_cur INTO pickout_rec;
    EXIT WHEN pickout_cur%NOTFOUND;
    -- �`�F�b�N���X�gID���J�E���g
    ln_check_num  := ln_check_num  + 1;
    -- �Ώی������J�E���g
    gn_target_cnt := gn_target_cnt + 1;
    -- A-3.���[�N�e�[�u���f�[�^�o�^
    INSERT INTO xxcoi_rep_inv_checklist(
            check_list_id
           ,check_year
           ,check_month
           ,inventory_kbn
           ,base_code
           ,base_name
           ,subinventory_code
           ,subinventory_name
           ,inventory_date
           ,inventory_slipno
           ,item_code
           ,item_name
           ,case_in_qty
           ,case_qty
           ,singly_qty
           ,inventory_qty
           ,quality_goods_kbn
           ,last_update_date
           ,last_updated_by
           ,creation_date
           ,created_by
           ,last_update_login
           ,request_id
           ,program_application_id
           ,program_id
           ,program_update_date
           ,message)
    VALUES (ln_check_num                                              -- �`�F�b�N���X�gID
           ,TO_CHAR(pickout_rec.xir_inventory_date,'YYYY')            -- �N
           ,TO_CHAR(pickout_rec.xir_inventory_date,'MM')              -- ��
           ,cv_inv_kbn                                                -- �I���敪
           ,pickout_rec.xir_base_code                                 -- ���_�R�[�h
           ,pickout_rec.biv_base_short_name                           -- ���_��(����)
           ,pickout_rec.msi_secondary_inventory_name                  -- �ۊǏꏊ�R�[�h
           ,pickout_rec.msi_description                               -- �ۊǏꏊ��
           ,pickout_rec.xir_inventory_date                            -- �I����
           ,pickout_rec.xir_slip_no                                   -- �I���`�[No
           ,pickout_rec.xir_item_code                                 -- �i�ڃR�[�h
           ,pickout_rec.imb_item_short_name                           -- �i��
           ,pickout_rec.xir_case_in_qty                               -- ����
           ,pickout_rec.xir_case_qty                                  -- �P�[�X��
           ,pickout_rec.xir_quantity                                  -- �o����
           ,pickout_rec.xir_case_in_qty * pickout_rec.xir_case_qty
                                        + pickout_rec.xir_quantity    -- �I����
           ,DECODE(pickout_rec.xir_quality_goods_kbn,cv_goods_kbn
                                                    ,gt_goods_name,NULL)
                                                                      -- �Ǖi�敪
           ,SYSDATE                                                   -- �ŏI�X�V��
           ,cn_last_updated_by                                        -- �ŏI�X�V��
           ,SYSDATE                                                   -- �쐬��
           ,cn_created_by                                             -- �쐬��
           ,cn_last_update_login                                      -- �ŏI�X�V���[�U
           ,cn_request_id                                             -- �v��ID
           ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
           ,cn_program_id                                             -- �v���O����ID
           ,SYSDATE                                                   -- �v���O�����X�V��
           ,NULL);                                                    -- ���b�Z�[�W
    -- A-4.�����σt���O�X�V
    IF (iv_output_kbn = cv_output_kbn) THEN
      BEGIN
        UPDATE xxcoi_inv_result
        SET    process_flag           = 'Y'                           -- �����σt���O
              ,last_update_date       = SYSDATE                       -- �ŏI�X�V��
              ,last_updated_by        = cn_last_updated_by            -- �ŏI�X�V��
              ,last_update_login      = cn_last_update_login          -- �ŏI�X�V���[�U
              ,request_id             = cn_request_id                 -- �v��ID
              ,program_application_id = cn_program_application_id     -- �v���O�����A�v���P�[�V����ID
              ,program_id             = cn_program_id                 -- �v���O����ID
              ,program_update_date    = SYSDATE                       -- �v���O�����X�V��
        WHERE  ROWID                  = pickout_rec.xir_row_id;
      -- �X�V��O����
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcoi_sn
                      ,iv_name        => cv_msg_10091
                      );
          lv_errbuf := lv_errmsg;
          lv_retcode := cv_status_error;    -- �ُ�:2
          gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END;
    END IF;
  --
  END LOOP;
  CLOSE pickout_cur;
  -- ����0���̏ꍇ
  IF (ln_check_num = 0) THEN
    -- ���_���擾
    IF (iv_base_code IS NOT NULL) THEN
      BEGIN
        SELECT base_short_name
        INTO   lv_base_name
        FROM   xxcoi_base_info2_v       -- ���_���r���[
        WHERE  base_code       = iv_base_code
        AND    focus_base_code = gv_user_basecode;
      EXCEPTION
        WHEN OTHERS THEN
          lv_base_name := NULL;
      END;
    END IF;
    -- �ۊǏꏊ���擾
    IF (iv_inventory_place IS NOT NULL) THEN
      BEGIN
        SELECT description
        INTO   lv_inv_name
        FROM   mtl_secondary_inventories
        WHERE  organization_id          = gn_organization_id
        AND    secondary_inventory_name = iv_inventory_place
        AND    TRUNC(NVL(disable_date,gd_target_date))
                                       >= TRUNC(gd_target_date)
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_inv_name := NULL;
      END;
    END IF;
    -- ����0�����b�Z�[�W�擾
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    -- ����0�����b�Z�[�W�o��
    INSERT INTO xxcoi_rep_inv_checklist(
                check_list_id
               ,check_year
               ,check_month
               ,inventory_kbn
               ,base_code
               ,base_name
               ,subinventory_code
               ,subinventory_name
               ,last_update_date
               ,last_updated_by
               ,creation_date
               ,created_by
               ,last_update_login
               ,request_id
               ,program_application_id
               ,program_id
               ,program_update_date
               ,message)
    VALUES     (ln_check_num                                          -- �`�F�b�N���X�gID
               ,TO_CHAR(gd_target_date,'YYYY')                        -- �N
               ,TO_CHAR(gd_target_date,'MM')                          -- ��
               ,cv_inv_kbn                                            -- �I���敪
               ,iv_base_code                                          -- ���_�R�[�h
               ,lv_base_name                                          -- ���_��(����)
               ,iv_inventory_place                                    -- �ۊǏꏊ�R�[�h
               ,lv_inv_name                                           -- �ۊǏꏊ��
               ,SYSDATE                                               -- �ŏI�X�V��
               ,cn_last_updated_by                                    -- �ŏI�X�V��
               ,SYSDATE                                               -- �쐬��
               ,cn_created_by                                         -- �쐬��
               ,cn_last_update_login                                  -- �ŏI�X�V���[�U
               ,cn_request_id                                         -- �v��ID
               ,cn_program_application_id                             -- �v���O�����A�v���P�[�V����ID
               ,cn_program_id                                         -- �v���O����ID
               ,SYSDATE                                               -- �v���O�����X�V��
               ,lv_message);                                          -- ���b�Z�[�W
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
    iv_inventory_kbn      IN  VARCHAR2,    -- �I���敪
    iv_practice_date      IN  VARCHAR2,    -- �N����
    iv_practice_month     IN  VARCHAR2,    -- �N��
    iv_base_code          IN  VARCHAR2,    -- ���_
    iv_inventory_place    IN  VARCHAR2,    -- �I���ꏊ
    iv_output_kbn         IN  VARCHAR2,    -- �o�͋敪
    ov_practice_date      OUT DATE,        -- �N����(DATE)
    ov_practice_month     OUT DATE,        -- �N��  (DATE)
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ov_practice_date  := TO_DATE(iv_practice_date,'YYYYMMDD');
    ov_practice_month := TO_DATE(iv_practice_month,'YYYYMM');
    -- �I���敪���e���擾
    cv_inv_kbn := xxcoi_common_pkg.get_meaning(cv_xxcoi_inv_kbn,iv_inventory_kbn);
    -- A-1-1.�R���J�����g���̓p�����[�^�����O�ɏo��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10093
                    ,iv_token_name1  => cv_p_token1   -- �I���敪
                    ,iv_token_value1 => cv_inv_kbn
                    ,iv_token_name2  => cv_p_token2   -- �N����
                    ,iv_token_value2 => TO_CHAR(ov_practice_date,'YYYY/MM/DD')
                    ,iv_token_name3  => cv_p_token3   -- �N��
                    ,iv_token_value3 => TO_CHAR(ov_practice_month,'YYYY/MM')
                    ,iv_token_name4  => cv_p_token4   -- ���_
                    ,iv_token_value4 => iv_base_code
                    ,iv_token_name5  => cv_p_token5   -- �I���ꏊ
                    ,iv_token_value5 => iv_inventory_place
                    ,iv_token_name6  => cv_p_token6   -- �o�͋敪
                    ,iv_token_value6 => xxcoi_common_pkg.get_meaning(cv_xxcoi_inv_out,iv_output_kbn)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- A-1-5.���ʊ֐�(�Ɩ��������t�擾)���Ɩ����t���擾���܂��B
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
    -- A-1-6.�Ώۓ����Z�o���܂��B
    IF (iv_inventory_kbn = cv_inv_kbn1) THEN      -- ����
      IF (ov_practice_date > gd_business_date) THEN
        gd_target_date := gd_business_date;
      ELSE
        gd_target_date := ov_practice_date;
      END IF;
    ELSIF (iv_inventory_kbn = cv_inv_kbn2) THEN   -- ����
      IF (LAST_DAY(ov_practice_month) > gd_business_date) THEN
        gd_target_date := gd_business_date;
      ELSE
        gd_target_date := LAST_DAY(ov_practice_month);
      END IF;
    END IF;
    -- A-1-3.���ʊ֐�(�݌ɑg�D�R�[�h�擾)���g�p���v���t�@�C�����݌ɑg�D�R�[�h���擾���܂��B
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
    -- A-1-4.��L3.�Ŏ擾�����݌ɑg�D�R�[�h�����Ƃɋ��ʕ��i(�݌ɑg�DID�擾)���݌ɑg�DID�擾���܂��B
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
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
    -- A-2-1.�������_�̎擾
    gv_user_basecode := xxcoi_common_pkg.get_base_code(cn_created_by,gd_target_date);
    IF (gv_user_basecode IS NULL) THEN
      -- ���[�U�[�̏������_�f�[�^���擾�ł��܂���ł����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10092
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    --�s�Ǖi���̂̎擾
    gt_goods_name  :=  xxcoi_common_pkg.get_meaning(
                      cv_qual_good_dv
                     ,cv_not_qual_goods
                   );
    IF (gt_goods_name IS NULL) THEN
      --�Ǖi�敪���̎擾���s
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10362
                   );
      lv_errbuf := lv_errmsg;
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_inventory_kbn      IN  VARCHAR2,     -- �I���敪
    iv_practice_date      IN  VARCHAR2,     -- �N����
    iv_practice_month     IN  VARCHAR2,     -- �N��
    iv_base_code          IN  VARCHAR2,     -- ���_
    iv_inventory_place    IN  VARCHAR2,     -- �I���ꏊ
    iv_output_kbn         IN  VARCHAR2,     -- �o�͋敪
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
    ld_practice_date          DATE;     -- �N����
    ld_practice_month         DATE;     -- �N��
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
      iv_inventory_kbn   => iv_inventory_kbn      -- �I���敪
     ,iv_practice_date   => iv_practice_date      -- �N����
     ,iv_practice_month  => iv_practice_month     -- �N��
     ,iv_base_code       => iv_base_code          -- ���_
     ,iv_inventory_place => iv_inventory_place    -- �I���ꏊ
     ,iv_output_kbn      => iv_output_kbn         -- �o�͋敪
     ,ov_practice_date   => ld_practice_date      -- �N����(DATE)
     ,ov_practice_month  => ld_practice_month     -- �N��  (DATE)
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
      iv_inventory_kbn   => iv_inventory_kbn                     -- �I���敪
     ,id_practice_date   => ld_practice_date                     -- �N����
     ,iv_practice_month  => TO_CHAR(ld_practice_month,'YYYYMM')  -- �N��
     ,iv_base_code       => iv_base_code                         -- ���_
     ,iv_inventory_place => iv_inventory_place                   -- �I���ꏊ
     ,iv_output_kbn      => iv_output_kbn                        -- �o�͋敪
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
    iv_inventory_kbn      IN  VARCHAR2,           -- �I���敪
    iv_practice_date      IN  VARCHAR2,           -- �N����
    iv_practice_month     IN  VARCHAR2,           -- �N��
    iv_base_code          IN  VARCHAR2,           -- ���_
    iv_inventory_place    IN  VARCHAR2,           -- �I���ꏊ
    iv_output_kbn         IN  VARCHAR2            -- �o�͋敪
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
       iv_inventory_kbn   => iv_inventory_kbn     -- �I���敪
      ,iv_practice_date   => iv_practice_date     -- �N����
      ,iv_practice_month  => iv_practice_month    -- �N��
      ,iv_base_code       => iv_base_code         -- ���_
      ,iv_inventory_place => iv_inventory_place   -- �I���ꏊ
      ,iv_output_kbn      => iv_output_kbn        -- �o�͋敪
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
END XXCOI006A08R;