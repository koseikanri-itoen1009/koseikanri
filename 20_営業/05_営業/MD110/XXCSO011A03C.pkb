CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A03C (body)
 * Description      : ���������X�g�쐬
 * MD.050           : ���������X�g�쐬 (MD050_CSO_011A03)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             ���������擾(A-2)�ACSV�t�@�C���o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/05/15    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  init_err_expt               EXCEPTION;      -- ���������G���[
  no_data_warn_expt           EXCEPTION;      -- �Ώۃf�[�^�Ȃ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO011A03C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- ���t����
  cv_format_std               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- ���蕶��
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00014            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00014';          -- �v���t�@�C���擾�G���[
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- ���o�Ώۊ��ԑ召�`�F�b�N�G���[���b�Z�[�W
  cv_msg_cso_00664            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00664';          -- ���b�Z�[�W�p������(�����쐬����)
  cv_msg_cso_00665            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00665';          -- ���b�Z�[�W�p������(�����쐬��)
  cv_msg_cso_00666            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00666';          -- ���b�Z�[�W�p������(�d����)
  cv_msg_cso_00667            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00667';          -- ���b�Z�[�W�p������(�����ԍ�)
  cv_msg_cso_00668            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00668';          -- ���b�Z�[�W�p������(�����쐬��FROM)
  cv_msg_cso_00669            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00669';          -- ���b�Z�[�W�p������(�����쐬��TO)
  cv_msg_cso_00670            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00670';          -- ���b�Z�[�W�p������(���[�X�敪)
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- ���̓p�����[�^�p������
  cv_msg_cso_00672            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00672';          -- ���������X�g�w�b�_�m�[�g
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���̓p�����[�^��
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���̓p�����[�^�l
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- �v���t�@�C����
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- ���o�Ώۓ�(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- ���o�Ώۓ�(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
  -- �v���t�@�C����
  cv_prof_org_id              CONSTANT VARCHAR2(30)  := 'ORG_ID';                    -- MO: �c�ƒP��
  -- �Q�ƃ^�C�v��
  cv_lkup_lease_kbn           CONSTANT VARCHAR2(30)  := 'XXCSO1_LEASE_KBN';          -- ���[�X�敪
  -- �l�Z�b�g��
  cv_flex_dclr_place          CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';          -- �\���n
  -- ���e���v���[�g������
  cv_attr_inst_cust_nm        CONSTANT VARCHAR2(30)  := 'INSTALL_AT_CUSTOMER_NAME';  -- �ݒu��ڋq��
  cv_attr_lease_type          CONSTANT VARCHAR2(30)  := 'LEASE_TYPE';                -- ���[�X�敪
  cv_attr_dclr_place          CONSTANT VARCHAR2(30)  := 'DECLARATION_PLACE';         -- �\���n
  cv_attr_inst_cust_cd        CONSTANT VARCHAR2(30)  := 'INSTALL_AT_CUSTOMER_CODE';  -- �ݒu��ڋq
  -- �t���O
  cv_dummy                    CONSTANT VARCHAR2(2)   := 'XX';                        -- �_�~�[�l
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �L��
  cv_flag_a                   CONSTANT VARCHAR2(1)   := 'A';                         -- �L��
  cv_interface_no             CONSTANT VARCHAR2(1)   := 'N';                         -- ���A�g
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                        -- ���{��
  cv_aprv_status              CONSTANT VARCHAR2(8)   := 'APPROVED';                  -- ���F��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;  -- �����쐬����
  gt_created_by               per_all_people_f.employee_number%TYPE;    -- �����쐬��
  gt_vendor_code              po_vendors.segment1%TYPE;                 -- �d����
  gt_po_num                   po_headers_all.segment1%TYPE;             -- �����ԍ�
  gd_date_from                DATE;                                     -- �����쐬��FROM
  gd_date_to                  DATE;                                     -- �����쐬��TO
  gv_lease_kbn                VARCHAR2(1);                              -- ���[�X�敪
  gn_org_id                   NUMBER;                                   -- �c�Ƒg�DID
  gd_process_date             DATE;                                     -- �Ɩ����t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ���������擾�J�[�\��
  CURSOR get_po_info_cur
  IS
    SELECT  po_info.po_num               AS po_num              -- �����ԍ�
           ,po_info.po_line_num          AS po_line_num         -- �������הԍ�
           ,po_info.pr_num               AS pr_num              -- �w���˗��ԍ�
           ,po_info.pr_line_num          AS pr_line_num         -- �w���˗����הԍ�
           ,po_info.un_num               AS un_num              -- �@��R�[�h
           ,po_info.un_lease_kbn         AS un_lease_kbn        -- �@�탊�[�X�敪
           ,po_info.un_lease_kbn_name    AS un_lease_kbn_name   -- �@�탊�[�X�敪����
           ,po_info.un_get_price         AS un_get_price        -- �@��擾���i
           ,po_info.customer_code        AS customer_code       -- �ڋq�R�[�h
           ,po_info.customer_name        AS customer_name       -- �ڋq��
           ,po_info.address              AS address             -- �s�撬��
           ,po_info.lease_kbn            AS lease_kbn           -- ���[�X�敪
           ,po_info.get_price            AS get_price           -- �擾���i
           ,po_info.dclr_place           AS dclr_place          -- �\���n
    FROM   (SELECT ph.segment1                       AS po_num             -- �����ԍ�
                  ,pl.line_num                       AS po_line_num        -- �������הԍ�
                  ,prh.segment1                      AS pr_num             -- �w���˗��ԍ�
                  ,prl.line_num                      AS pr_line_num        -- �w���˗����הԍ�
                  ,pun.un_number                     AS un_num             -- �@��R�[�h
                  ,pun.attribute13                   AS un_lease_kbn       -- �@�탊�[�X�敪
                  ,( SELECT flvv.meaning AS un_lease_kbn_name
                     FROM   fnd_lookup_values_vl flvv
                     WHERE  flvv.lookup_type  = cv_lkup_lease_kbn  -- ���[�X�敪
                     AND    flvv.enabled_flag = cv_flag_y
                     AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
                     AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
                     AND    flvv.lookup_code  = pun.attribute13
                   )                                 AS un_lease_kbn_name  -- �@�탊�[�X�敪����
                  ,pun.attribute14                   AS un_get_price       -- �@��擾���i
                  ,hca.account_number                AS customer_code      -- �ڋq�R�[�h
                  ,xxcso_ipro_common_pkg.get_temp_info(
                     prl.requisition_line_id
                   , cv_attr_inst_cust_nm )  -- ���e���v���[�g�F�ݒu��ڋq��
                                                     AS customer_name      -- �ڋq��
                  ,hl.state || hl.city               AS address            -- �s�撬��
                  ,NVL(
                     NVL( pd.attribute1
                         ,NVL( pun.attribute13
                              ,( SELECT flvv.lookup_code AS lease_kbn
                                 FROM   apps.fnd_lookup_values_vl flvv
                                 WHERE  flvv.lookup_type  = cv_lkup_lease_kbn  -- ���[�X�敪
                                 AND    flvv.enabled_flag = cv_flag_y
                                 AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
                                 AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
                                 AND    flvv.attribute1   = xxcso_ipro_common_pkg.get_temp_info(
                                                              prl.requisition_line_id
                                                            , cv_attr_lease_type )  -- ���e���v���[�g�F���[�X�敪
                                 AND    ROWNUM            = 1
                               )
                          )
                     )
                     ,cv_dummy
                   )                                 AS lease_kbn          -- ���[�X�敪
                  ,NVL( pd.attribute2
                      , pun.attribute14
                   )                                 AS get_price          -- �擾���i
                  ,NVL( pd.attribute3
                       ,( xxcso_ipro_common_pkg.get_temp_info(
                            prl.requisition_line_id
                          , cv_attr_dclr_place ) )  -- ���e���v���[�g�F�\���n
                   )                                 AS dclr_place         -- �\���n
                  ,papf.attribute28                  AS base_code          -- �����쐬����
                  ,papf.person_id                    AS created_by         -- �����쐬��
                  ,TRUNC(ph.creation_date)           AS creation_date      -- �����쐬��
                  ,pv.segment1                       AS vendor_code        -- �d����
            FROM   po_headers_all             ph    -- �����w�b�_
                  ,po_lines_all               pl    -- ��������
                  ,po_distributions_all       pd    -- ��������
                  ,po_requisition_headers_all prh   -- �w���˗��w�b�_
                  ,po_requisition_lines_all   prl   -- �w���˗�����
                  ,po_req_distributions_all   prd   -- �w���˗�����
                  ,po_un_numbers_vl           pun   -- �@��}�X�^
                  ,xxcso_wk_requisition_proc  xwrp  -- ��ƈ˗��^�������A�g�Ώۃe�[�u��
                  ,hz_cust_accounts           hca   -- �ڋq�}�X�^
                  ,hz_parties                 hp    -- �p�[�e�B�}�X�^
                  ,hz_cust_acct_sites_all     hcas  -- �ڋq�T�C�g
                  ,hz_party_sites             hps   -- �p�[�e�B�T�C�h�}�X�^
                  ,hz_locations               hl    -- �ڋq���Ə��}�X�^
                  ,per_all_people_f           papf  -- �]�ƈ��}�X�^
                  ,po_vendors                 pv    -- �d����}�X�^
            WHERE ph.po_header_id              = pl.po_header_id
            AND   ph.po_header_id              = pd.po_header_id
            AND   pl.po_line_id                = pd.po_line_id
            AND   pd.req_distribution_id       = prd.distribution_id
            AND   prd.requisition_line_id      = prl.requisition_line_id
            AND   prl.requisition_header_id    = prh.requisition_header_id
            AND   pl.un_number_id              = pun.un_number_id
            AND   prl.requisition_line_id      = xwrp.requisition_line_id
            AND   xwrp.interface_flag          = cv_interface_no -- ���̋@�V�X�e�����A�g
            AND   hca.account_number           = xxcso_ipro_common_pkg.get_temp_info(
                                                   prl.requisition_line_id
                                                 , cv_attr_inst_cust_cd ) -- ���e���v���[�g�F�ݒu��ڋq
            AND   hca.party_id                 = hp.party_id
            AND   hca.cust_account_id          = hcas.cust_account_id
            AND   hcas.org_id                  = gn_org_id -- �c�Ƒg�DID
            AND   hcas.party_site_id           = hps.party_site_id
            AND   hcas.status                  = cv_flag_a -- �L��
            AND   hps.status                   = cv_flag_a -- �L��
            AND   hps.location_id              = hl.location_id
            AND   ph.agent_id                  = papf.person_id
            AND   gd_process_date             >= papf.effective_start_date
            AND   gd_process_date             <= papf.effective_end_date
            AND   ph.vendor_id                 = pv.vendor_id
            AND  (ph.authorization_status IS NULL
             OR   ph.authorization_status      <> cv_aprv_status
                 )                                    -- ���F�ψȊO
            ) po_info
    WHERE po_info.base_code        = gt_base_code                               -- 1.�����쐬����
    AND   po_info.created_by       = NVL(gt_created_by  ,po_info.created_by)    -- 2.�����쐬��
    AND   po_info.vendor_code      = NVL(gt_vendor_code ,po_info.vendor_code)   -- 3.�d����
    AND   po_info.po_num           = NVL(gt_po_num      ,po_info.po_num)        -- 4.�����ԍ�
    AND   po_info.creation_date   >= NVL(gd_date_from   ,po_info.creation_date) -- 5.�����쐬��FROM
    AND   po_info.creation_date   <= NVL(gd_date_to     ,po_info.creation_date) -- 6.�����쐬��TO
    AND   po_info.lease_kbn        = NVL(gv_lease_kbn   ,po_info.lease_kbn)     -- 7.���[�X�敪
    ORDER BY po_info.po_num         -- �����ԍ�
            ,po_info.po_line_num    -- �������הԍ�
            ,po_info.pr_num         -- �w���˗��ԍ�
            ,po_info.pr_line_num    -- �w���˗����הԍ�
    ;
    -- ���������J�[�\�����R�[�h�^
    get_po_info_rec get_po_info_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code    IN  VARCHAR2      -- 1.�����쐬����
   ,iv_created_by   IN  VARCHAR2      -- 2.�����쐬��
   ,iv_vendor_code  IN  VARCHAR2      -- 3.�d����
   ,iv_po_num       IN  VARCHAR2      -- 4.�����ԍ�
   ,iv_date_from    IN  VARCHAR2      -- 5.�����쐬��FROM
   ,iv_date_to      IN  VARCHAR2      -- 6.�����쐬��TO
   ,iv_lease_kbn    IN  VARCHAR2      -- 7.���[�X�敪
   ,ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg       OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_param_name1     VARCHAR2(1000);  -- ���̓p�����[�^��1
    lv_param_name2     VARCHAR2(1000);  -- ���̓p�����[�^��2
    lv_param_name3     VARCHAR2(1000);  -- ���̓p�����[�^��3
    lv_param_name4     VARCHAR2(1000);  -- ���̓p�����[�^��4
    lv_param_name5     VARCHAR2(1000);  -- ���̓p�����[�^��5
    lv_param_name6     VARCHAR2(1000);  -- ���̓p�����[�^��6
    lv_param_name7     VARCHAR2(1000);  -- ���̓p�����[�^��7
    lv_base_code       VARCHAR2(1000);  -- 1.�����쐬����
    lv_created_by      VARCHAR2(1000);  -- 2.�����쐬��
    lv_vendor_code     VARCHAR2(1000);  -- 3.�d����
    lv_po_num          VARCHAR2(1000);  -- 4.�����ԍ�
    lv_date_from       VARCHAR2(1000);  -- 5.�����쐬��FROM
    lv_date_to         VARCHAR2(1000);  -- 6.�����쐬��TO
    lv_lease_kbn       VARCHAR2(1000);  -- 7.���[�X�敪
    lv_csv_header      VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
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
    -- 0.���̓p�����[�^�i�[
    --==============================================================
    gt_base_code   := iv_base_code;                         -- 1.�����쐬����
    gt_created_by  := iv_created_by;                        -- 2.�����쐬��
    gt_vendor_code := iv_vendor_code;                       -- 3.�d����
    gt_po_num      := iv_po_num;                            -- 4.�����ԍ�
    gd_date_from   := TO_DATE(iv_date_from ,cv_format_std); -- 5.�����쐬��FROM
    gd_date_to     := TO_DATE(iv_date_to   ,cv_format_std); -- 6.�����쐬��TO
    gv_lease_kbn   := iv_lease_kbn;                         -- 7.���[�X�敪
--
    --==============================================================
    -- 1.���̓p�����[�^�o��
    --==============================================================
    -- 1.�����쐬����
    lv_param_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00664              -- ���b�Z�[�W�R�[�h
                      );
    lv_base_code   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name1                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_base_code                  -- �g�[�N���l2
                      );
    -- 2.�����쐬��
    lv_param_name2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00665              -- ���b�Z�[�W�R�[�h
                      );
    lv_created_by  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name2                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_created_by                 -- �g�[�N���l2
                      );
    -- 3.�d����
    lv_param_name3 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00666              -- ���b�Z�[�W�R�[�h
                      );
    lv_vendor_code := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name3                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_vendor_code                -- �g�[�N���l2
                      );
    -- 4.�����ԍ�
    lv_param_name4 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00667              -- ���b�Z�[�W�R�[�h
                      );
    lv_po_num      := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name4                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_po_num                     -- �g�[�N���l2
                      );
    -- 5.�����쐬��FROM
    lv_param_name5 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00668              -- ���b�Z�[�W�R�[�h
                      );
    lv_date_from   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name5                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_date_from                  -- �g�[�N���l2
                      );
    -- 6.�����쐬��TO
    lv_param_name6 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00669              -- ���b�Z�[�W�R�[�h
                      );
    lv_date_to     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name6                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_date_to                    -- �g�[�N���l2
                      );
    -- 7.���[�X�敪
    lv_param_name7 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00670              -- ���b�Z�[�W�R�[�h
                      );
    lv_lease_kbn   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_param_name7                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_lease_kbn                  -- �g�[�N���l2
                      );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''             || CHR(10) ||
                 lv_base_code   || CHR(10) ||      -- 1.�����쐬����
                 lv_created_by  || CHR(10) ||      -- 2.�����쐬��
                 lv_vendor_code || CHR(10) ||      -- 3.�d����
                 lv_po_num      || CHR(10) ||      -- 4.�����ԍ�
                 lv_date_from   || CHR(10) ||      -- 5.�����쐬��FROM
                 lv_date_to     || CHR(10) ||      -- 6.�����쐬��TO
                 lv_lease_kbn   || CHR(10)         -- 7.���[�X�敪
    );
--
    --==================================================
    -- 2.�v���t�@�C���l�擾
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    -- �v���t�@�C���̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gn_org_id IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso      -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00014        -- ���b�Z�[�W�R�[�h
         ,iv_token_name1  => cv_tkn_prof_name        -- �g�[�N���R�[�h1
         ,iv_token_value1 => cv_prof_org_id          -- �g�[�N���l1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.�Ɩ����t�擾
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date ;
    -- �Ɩ����t�̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gd_process_date IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00011     -- ���b�Z�[�W�R�[�h
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 4.���̓p�����[�^�̑Ó����`�F�b�N
    --==================================================
    -- �����쐬��FROM�ATO���Ƃ��Ɏw�肳��Ă����ꍇ�Ƀ`�F�b�N
    IF ( gd_date_from IS NOT NULL )
      AND ( gd_date_to IS NOT NULL )
    THEN
      -- �����쐬��FROM��TO�̏ꍇ�̓G���[
      IF ( gd_date_from > gd_date_to )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso      -- �A�v���P�[�V�����Z�k��
         ,iv_name         => cv_msg_cso_00644        -- ���b�Z�[�W�R�[�h
         ,iv_token_name1  => cv_tkn_date_from        -- �g�[�N���R�[�h1
         ,iv_token_value1 => lv_param_name5          -- �g�[�N���l1
         ,iv_token_name2  => cv_tkn_date_to          -- �g�[�N���R�[�h2
         ,iv_token_value2 => lv_param_name6          -- �g�[�N���l2
        );
        lv_errbuf  := lv_errmsg;
        RAISE init_err_expt;
      END IF;
    END IF;
--
    --==================================================
    -- 5.CSV�w�b�_���ڏo��
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso   -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cso_00672     -- ���b�Z�[�W�R�[�h
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : ���������擾(A-2)�ACSV�t�@�C���o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    lv_op_str            VARCHAR2(5000)  := NULL;   -- �o�͕�����i�[�p�ϐ�
    lv_lease_kbn         VARCHAR2(1)     := NULL;   -- ���[�X�敪
    lv_lease_kbn_name    VARCHAR2(100)   := NULL;   -- ���[�X�敪����
    lv_dclr_place_name   VARCHAR2(500)   := NULL;   -- �\���n����
--
    -- ===============================
    -- ���[�U�[��`��O
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
    -- ===============================
    -- ���������擾(A-2)
    -- ===============================
    << po_info_loop >>
    FOR get_po_info_rec IN get_po_info_cur
    LOOP
      -- ===============================
      -- CSV�t�@�C���o��(A-3)
      -- ===============================
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
      -- ===============================
      -- 1-(1).���[�X�敪�擾
      -- ===============================
      IF (get_po_info_rec.lease_kbn = cv_dummy)
      THEN
        lv_lease_kbn := NULL;
      ELSE
        lv_lease_kbn := get_po_info_rec.lease_kbn;
      END IF;
      -- ===============================
      -- 1-(2).���[�X�敪���̎擾
      -- ===============================
      IF (lv_lease_kbn IS NOT NULL)
      THEN
        BEGIN
          SELECT flvv.meaning AS lease_kbn_name
          INTO   lv_lease_kbn_name
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lkup_lease_kbn -- ���[�X�敪
          AND    flvv.enabled_flag = cv_flag_y
          AND    gd_process_date  >= NVL(flvv.start_date_active ,gd_process_date)
          AND    gd_process_date  <= NVL(flvv.end_date_active   ,gd_process_date)
          AND    flvv.lookup_code  = lv_lease_kbn -- ��L�Őݒ肵�����[�X�敪
          ;
        EXCEPTION
          --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
          WHEN NO_DATA_FOUND THEN
            lv_lease_kbn_name := NULL;
        END;
      END IF;
--
      -- ===============================
      -- 1-(3).�\���n���̎擾
      -- ===============================
      IF (get_po_info_rec.dclr_place IS NOT NULL)
      THEN
        BEGIN
          SELECT ffvt.description AS dclr_place_name
          INTO   lv_dclr_place_name
          FROM   fnd_flex_values      ffv
               , fnd_flex_values_tl   ffvt
               , fnd_flex_value_sets  ffvs
          WHERE  ffv.flex_value_id        = ffvt.flex_value_id
          AND    ffvt.language            = cv_language_ja
          AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
          AND    ffvs.flex_value_set_name = cv_flex_dclr_place  -- �\���n
          AND    ffv.enabled_flag         = cv_flag_y
          AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
          AND    gd_process_date         <= NVL(ffv.end_date_active   ,gd_process_date)
          AND    ffv.flex_value           = get_po_info_rec.dclr_place
          ;
        EXCEPTION
          --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
          WHEN NO_DATA_FOUND THEN
            lv_dclr_place_name := NULL;
        END;
      END IF;
--
      --�o�͕�����쐬
      lv_op_str :=                          cv_dqu || get_po_info_rec.po_num            || cv_dqu ;   -- �����ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.po_line_num       || cv_dqu ;   -- �������הԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.pr_num            || cv_dqu ;   -- �w���˗��ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.pr_line_num       || cv_dqu ;   -- �w���˗����הԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_num            || cv_dqu ;   -- �@��R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_lease_kbn      || cv_dqu ;   -- �@�탊�[�X�敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_lease_kbn_name || cv_dqu ;   -- �@�탊�[�X�敪����
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.un_get_price      || cv_dqu ;   -- �@��擾���i
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.customer_code     || cv_dqu ;   -- �ڋq�R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.customer_name     || cv_dqu ;   -- �ڋq��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.address           || cv_dqu ;   -- �s�撬��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_lease_kbn                      || cv_dqu ;   -- ���[�X�敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_lease_kbn_name                 || cv_dqu ;   -- ���[�X�敪����
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.get_price         || cv_dqu ;   -- �擾���i
      lv_op_str := lv_op_str || cv_comma || cv_dqu || get_po_info_rec.dclr_place        || cv_dqu ;   -- �\���n
      lv_op_str := lv_op_str || cv_comma || cv_dqu || lv_dclr_place_name                || cv_dqu ;   -- �\���n����
--
      -- ===============================
      -- 2.CSV�t�@�C���o��
      -- ===============================
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
      -- �ϐ�������
      lv_lease_kbn       := NULL;
      lv_lease_kbn_name  := NULL;
      lv_dclr_place_name := NULL;
--
    END LOOP po_info_loop;
--
    -- �Ώۃf�[�^�Ȃ��x��
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- 1.�����쐬����
   ,iv_created_by      IN  VARCHAR2     -- 2.�����쐬��
   ,iv_vendor_code     IN  VARCHAR2     -- 3.�d����
   ,iv_po_num          IN  VARCHAR2     -- 4.�����ԍ�
   ,iv_date_from       IN  VARCHAR2     -- 5.�����쐬��FROM
   ,iv_date_to         IN  VARCHAR2     -- 6.�����쐬��TO
   ,iv_lease_kbn       IN  VARCHAR2     -- 7.���[�X�敪
   ,ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      iv_base_code       => iv_base_code     -- 1.�����쐬����
     ,iv_created_by      => iv_created_by    -- 2.�����쐬��
     ,iv_vendor_code     => iv_vendor_code   -- 3.�d����
     ,iv_po_num          => iv_po_num        -- 4.�����ԍ�
     ,iv_date_from       => iv_date_from     -- 5.�����쐬��FROM
     ,iv_date_to         => iv_date_to       -- 6.�����쐬��TO
     ,iv_lease_kbn       => iv_lease_kbn     -- 7.���[�X�敪
     ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���������擾(A-2)�ACSV�t�@�C���o��(A-3)
    -- ===============================
    output_csv(
      ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- 
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn)
    THEN
      RAISE no_data_warn_expt;
    END IF;
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ��x��
    WHEN no_data_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
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
    errbuf             OUT VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode            OUT VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_base_code       IN  VARCHAR2     -- 1.�����쐬����
   ,iv_created_by      IN  VARCHAR2     -- 2.�����쐬��
   ,iv_vendor_code     IN  VARCHAR2     -- 3.�d����
   ,iv_po_num          IN  VARCHAR2     -- 4.�����ԍ�
   ,iv_date_from       IN  VARCHAR2     -- 5.�����쐬��FROM
   ,iv_date_to         IN  VARCHAR2     -- 6.�����쐬��TO
   ,iv_lease_kbn       IN  VARCHAR2     -- 7.���[�X�敪
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error)
    THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code    => iv_base_code     -- 1.�����쐬����
      ,iv_created_by   => iv_created_by    -- 2.�����쐬��
      ,iv_vendor_code  => iv_vendor_code   -- 3.�d����
      ,iv_po_num       => iv_po_num        -- 4.�����ԍ�
      ,iv_date_from    => iv_date_from     -- 5.�����쐬��FROM
      ,iv_date_to      => iv_date_to       -- 6.�����쐬��TO
      ,iv_lease_kbn    => iv_lease_kbn     -- 7.���[�X�敪
      ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error)
    THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    IF( lv_retcode = cv_status_error )
    THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal)
    THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)
    THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)
    THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error)
    THEN
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
END XXCSO011A03C;
/
