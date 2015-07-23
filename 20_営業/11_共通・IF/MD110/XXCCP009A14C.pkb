CREATE OR REPLACE PACKAGE BODY XXCCP009A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A14C(body)
 * Description      : ������ڋq���CSV�o��
 * MD.070           : ������ڋq���CSV�o�� (MD070_IPO_CCP_009_A14)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/03/26     1.0  SCSK H.Wajima   [E_�{�ғ�_12936]�V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP009A14C'; -- �p�b�P�[�W��
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,                               --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,                               --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)                               --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
    cv_msg_no_parameter     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- �p�����[�^�Ȃ�
    cv_org_id               CONSTANT VARCHAR2(6)   := 'ORG_ID';            -- �c�ƒP��ID
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
    ln_org_id               NUMBER;    -- ���O�C�����[�U�̉c�ƒP��ID
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ������ڋq�r���[���擾
    CURSOR get_hz_cust_accounts_cur( in_org_id NUMBER )
      IS
        SELECT  NVL(chcar.cust_account_id,bcus.cust_account_id)    pay_customer_id,      -- ������ڋqID
                NVL(chca.account_number,bcus.customer_code)        pay_customer_number,  -- ������ڋq�R�[�h
                NVL(chp.party_name,bcus.customer_name)             pay_customer_name,    -- ������ڋq��
                bcus.cust_account_id                               cust_account_id,      -- ������ڋqID
                bcus.customer_code                                 bill_customer_code,   -- ������ڋq�R�[�h
                bcus.customer_name                                 bill_customer_name    -- ������ڋq��
        FROM    apps.hz_cust_acct_relate_all     chcar,     -- �ڋq�֘A�i������-������j
                apps.hz_cust_accounts            chca,      -- �ڋq�i������j
                apps.hz_parties                  chp,       -- �p�[�e�B�i������j
                xxcmm.xxcmm_cust_accounts        cxca,      -- �ڋq�A�h�I���i������j
                (SELECT  lookup_code              receiv_code1,              -- ���|�R�[�h1�i������j
                         meaning                  receiv_code1_name          -- ���|�R�[�h1�i������j��
                 FROM    apps.fnd_lookup_values_vl
                 WHERE   lookup_type        =  'XXCMM_INVOICE_GRP_CODE'      -- ���|�R�[�h1�o�^ �Q�ƃ^�C�v
                 AND     enabled_flag       =  'Y'
                 AND     NVL(start_date_active,TO_DATE('19000101','YYYYMMDD'))  <= SYSDATE
                 AND     NVL(end_date_active,TO_DATE('22001231','YYYYMMDD'))    >= SYSDATE ) xigc, -- ���|�R�[�h�P
                (SELECT  flex_value,
                         description
                 FROM    apps.fnd_flex_values_vl ffv
                 WHERE   EXISTS
                         (SELECT  'X'
                          FROM    applsys.fnd_flex_value_sets
                          WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                          AND     flex_value_set_id   = ffv.flex_value_set_id)) cffvv,  --�l�Z�b�g�l�i��������j
                (
                 --������
                 SELECT  xhca.cust_account_id,        -- ������ڋqID
                         xhcp.cust_account_profile_id,
                         xhcas.cust_acct_site_id,
                         xhcsu.site_use_id,
                         xhca.party_id,
                         xhp.party_number,
                         xhcsu.attribute4          receiv_code1,             -- ���|�R�[�h1�i������j
                         xhca.account_number       customer_code,            -- ������ڋq�R�[�h
                         xhp.party_name            customer_name,            -- ������ڋq��
                         xhca.status               status,                   -- �ڋq�X�e�[�^�X
                         xhca.customer_type        customer_type,            -- �ڋq�^�C�v
                         xhca.customer_class_code  customer_class_code,      -- �ڋq�敪
                         xxca.bill_base_code       bill_base_code,           -- �������_�R�[�h
                         xffvv.description         bill_base_name,           -- �������_��
                         xxca.store_code           store_code,               -- �X�܃R�[�h
                         xxca.tax_div              tax_div,                  -- ����ŋ敪
                         xhcsu.tax_rounding_rule   tax_rounding_rule,        -- �ŋ��|�[������
                         xhcsu.attribute7          inv_prt_type,             -- �������o�͌`��
                         xhcp.cons_inv_flag        cons_inv_flag,            -- �ꊇ���������s�敪
                         xhcas.org_id              org_id                    -- �g�DID
                 FROM    apps.hz_cust_accounts        xhca,                       -- �ڋq�A�J�E���g�i������j
                         apps.hz_parties              xhp,                        -- �p�[�e�B�i������j
                         apps.hz_cust_acct_sites_all  xhcas,                      -- �ڋq�T�C�g�i������j
                         apps.hz_cust_site_uses_all   xhcsu,                      -- �ڋq�g�p�ړI�i������j
                         apps.hz_customer_profiles    xhcp,                       -- �ڋq�v���t�@�C���i������j
                         xxcmm.xxcmm_cust_accounts    xxca,                       -- �ڋq�A�h�I���i������j
                         (SELECT flex_value,
                                 description
                          FROM   apps.fnd_flex_values_vl ffv
                          WHERE  EXISTS
                                 (SELECT  'X'
                                  FROM    applsys.fnd_flex_value_sets
                                  WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                                  AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  -- �l�Z�b�g�l�i��������j
                 WHERE   xhcas.org_id = in_org_id
                 AND     xhcsu.org_id = in_org_id
                 AND     xhca.party_id            = xhp.party_id
                 AND     xhca.customer_class_code = '14'
                 AND     xhca.cust_account_id     = xhcas.cust_account_id
                 AND     xhcas.bill_to_flag       IS NOT NULL
                 AND     xhcas.cust_acct_site_id  = xhcsu.cust_acct_site_id
                 AND     xhcsu.site_use_code      = 'BILL_TO'                 --�g�p�ړI
                 AND     xhcsu.primary_flag       = 'Y'
                 AND     xhcsu.status             = 'A'                       --�X�e�[�^�X
                 AND     xhca.cust_account_id     = xhcp.cust_account_id
                 AND     xhcsu.site_use_id       = xhcp.site_use_id
                 AND     xhca.cust_account_id     = xxca.customer_id(+)
                 AND     xxca.bill_base_code      = xffvv.flex_value(+)
                 AND     EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all     hcar
                          WHERE    hcar.org_id = in_org_id
                          AND      hcar.attribute1  = '1'
                          AND      hcar.status      = 'A'
                          AND      hcar.cust_account_id = xhca.cust_account_id
                          )
                 AND     NOT EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all  hcar
                          WHERE    hcar.org_id                   = in_org_id
                          AND      hcar.attribute1               = '1'
                          AND      hcar.status                   = 'A'
                          AND      hcar.customer_reciprocal_flag = 'Y'
                          AND      hcar.cust_account_id          = xhca.cust_account_id
                          )
               UNION ALL
                 -- �[�i�� AND ������
                 SELECT  yhca.cust_account_id,                               -- ������ڋqID
                         yhcp.cust_account_profile_id,
                         yhcas.cust_acct_site_id,
                         yhcsu.site_use_id,
                         yhca.party_id,
                         yhp.party_number,
                         yhcsu.attribute4          receiv_code1,             -- ���|�R�[�h1�i������j
                         yhca.account_number       customer_code,            -- ������ڋq�R�[�h
                         yhp.party_name            customer_name,            -- ������ڋq����
                         yhca.status               status,                   -- �ڋq�X�e�[�^�X
                         yhca.customer_type        customer_type,            -- �ڋq�^�C�v
                         yhca.customer_class_code  customer_class_code,      -- �ڋq�敪
                         yxca.bill_base_code       bill_base_code,           -- �������_�R�[�h
                         yffvv.description         bill_base_name,           -- �������_��
                         yxca.store_code           store_code,               -- �X�܃R�[�h
                         yxca.tax_div              tax_div,                  -- ����ŋ敪
                         yhcsu.tax_rounding_rule   tax_rounding_rule,        -- �ŋ��|�[������
                         yhcsu.attribute7          inv_prt_type,             -- �������o�͌`��
                         yhcp.cons_inv_flag        cons_inv_flag,            -- �ꊇ���������s�敪
                         yhcas.org_id              org_id                    -- �g�DID
                 FROM    apps.hz_cust_accounts        yhca,                    -- �ڋq�A�J�E���g�i������j
                         apps.hz_parties              yhp,                     -- �p�[�e�B�i������j
                         apps.hz_cust_acct_sites_all  yhcas,                   -- �ڋq�T�C�g�i������j
                         apps.hz_cust_site_uses_all   yhcsu,                   -- �ڋq�g�p�ړI�i������j
                         apps.hz_customer_profiles    yhcp,                    -- �ڋq�v���t�@�C���i������j
                         xxcmm.xxcmm_cust_accounts     yxca,                   -- �ڋq�A�h�I���i������j
                         (SELECT  flex_value,
                                 description
                          FROM   apps.fnd_flex_values_vl ffv
                          WHERE  EXISTS
                                 (SELECT   'X'
                                  FROM     applsys.fnd_flex_value_sets
                                  WHERE    flex_value_set_name = 'XX03_DEPARTMENT'
                                  AND      flex_value_set_id = ffv.flex_value_set_id)) yffvv  -- �l�Z�b�g�l�i��������j
                 WHERE   yhcas.org_id = in_org_id
                 AND     yhcsu.org_id = in_org_id
                 AND     yhca.party_id            = yhp.party_id
                 AND     yhca.customer_class_code = '10'
                 AND     yhca.cust_account_id     = yhcas.cust_account_id
                 AND     yhcas.bill_to_flag       IS NOT NULL
                 AND     yhcas.cust_acct_site_id  = yhcsu.cust_acct_site_id
                 AND     yhcsu.site_use_code      = 'BILL_TO'                 --�g�p�ړI
                 AND     yhcsu.primary_flag       = 'Y'
                 AND     yhcsu.status             = 'A'                       --�X�e�[�^�X
                 AND     yhca.cust_account_id     = yhcp.cust_account_id
                 AND     yhcsu.site_use_id        = yhcp.site_use_id
                 AND     yhca.cust_account_id     = yxca.customer_id(+)
                 AND     yxca.bill_base_code      = yffvv.flex_value(+)
                 AND     NOT EXISTS
                         (SELECT   'X'
                          FROM     apps.hz_cust_acct_relate_all     hcar
                          WHERE    hcar.org_id = in_org_id
                          AND      hcar.attribute1  = '1'
                          AND      hcar.status      = 'A'
                          AND      hcar.related_cust_account_id = yhca.cust_account_id
                         )
                ) bcus
        WHERE   chcar.related_cust_account_id(+) = bcus.cust_account_id
        AND     chcar.org_id(+)                  = bcus.org_id
        AND     chcar.cust_account_id            = chca.cust_account_id(+)
        AND     chca.party_id                    = chp.party_id(+)
        AND     chca.cust_account_id             = cxca.customer_id(+)
        AND     cxca.receiv_base_code            = cffvv.flex_value(+)
        AND     chcar.status(+)                  = 'A'
        AND     bcus.receiv_code1                = xigc.receiv_code1(+)
    ;
    -- ���R�[�h�^
    get_hz_cust_accounts_rec  get_hz_cust_accounts_cur%ROWTYPE;
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
    -- ===============================
    -- init��
    -- ===============================
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_msg_no_parameter
                                          );
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
    -- ��s�o��
    FND_FILE.PUT_LINE(which  => FND_FILE.LOG
                     ,buff   => NULL
                     );
--
    --==============================================================
    -- ���O�C�����[�U�̉c�ƒP��ID�擾
    --==============================================================
    ln_org_id := FND_PROFILE.VALUE(cv_org_id);
--
    -- ===============================
    -- ������
    -- ===============================
--
    -- ���ږ��o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '"������ڋqID","������ڋq�R�[�h","������ڋq��","������ڋqID","������ڋq�R�[�h","������ڋq��"'
    );
    -- �f�[�^���o��(CSV)
    FOR get_hz_cust_accounts_rec IN get_hz_cust_accounts_cur(ln_org_id)
     LOOP
       --�����Z�b�g
       gn_target_cnt := gn_target_cnt + 1;
       --�ύX���鍀�ڋy�уL�[�����o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| get_hz_cust_accounts_rec.pay_customer_id     || '","'
                       || get_hz_cust_accounts_rec.pay_customer_number || '","'
                       || get_hz_cust_accounts_rec.pay_customer_name   || '","'
                       || get_hz_cust_accounts_rec.cust_account_id     || '","'
                       || get_hz_cust_accounts_rec.bill_customer_code  || '","'
                       || get_hz_cust_accounts_rec.bill_customer_name  || '"'
       );
    END LOOP;
--
    -- �����������Ώی���
    gn_normal_cnt  := gn_target_cnt;
    -- �Ώی���=0�ł���Όx��
    IF (gn_target_cnt = 0) THEN
      gn_warn_cnt    := 1;
      ov_retcode     := cv_status_warn;
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
    errbuf          OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
       iv_which   => 'LOG'
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt := 1;
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
END XXCCP009A14C;
/