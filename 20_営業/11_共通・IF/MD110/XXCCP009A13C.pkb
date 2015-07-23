CREATE OR REPLACE PACKAGE BODY XXCCP009A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A13C(body)
 * Description      : �ڋq�K�w���CSV�o��
 * MD.070           : �ڋq�K�w���CSV�o�� (MD070_IPO_CCP_009_A13)
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
 *  2015/01/13     1.0  SCSK H.Wajima   [E_�{�ғ�_12836]�V�K�쐬
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP009A13C'; -- �p�b�P�[�W��
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
    -- �ڋq�K�w�r���[���擾
    CURSOR get_hz_cust_accounts_cur( in_org_id NUMBER )
      IS
        SELECT
            customer_v.cash_account_id     --������ڋqID
          , customer_v.cash_account_number --������ڋq�R�[�h
          , customer_v.cash_account_name   --������ڋq����
          , customer_v.bill_account_id     --������ڋqID
          , customer_v.bill_account_number --������ڋq�R�[�h
          , customer_v.bill_account_name   --������ڋq����
          , customer_v.ship_account_id     --�o�א�ڋqID
          , customer_v.ship_account_number --�o�א�ڋq�R�[�h
          , customer_v.ship_account_name   --�o�א�ڋq����
        FROM
          (
            SELECT
                     temp.cash_account_id                          AS cash_account_id        --������ڋqID
                    ,temp.cash_account_number                      AS cash_account_number    --������ڋq�R�[�h
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.cash_account_number
                     )                                             AS cash_account_name      --������ڋq����
                    ,temp.bill_account_id                          AS bill_account_id        --������ڋqID
                    ,temp.bill_account_number                      AS bill_account_number    --������ڋq�R�[�h
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.bill_account_number
                     )                                             AS bill_account_name      --������ڋq����
                    ,temp.ship_account_id                          AS ship_account_id        --�o�א�ڋqID
                    ,temp.ship_account_number                      AS ship_account_number    --�o�א�ڋq�R�[�h
                    ,(SELECT hzpt.party_name AS party_name
                      FROM   apps.hz_parties       hzpt,
                             apps.hz_cust_accounts hzca
                      WHERE  hzca.party_id = hzpt.party_id
                      AND    hzca.account_number = temp.ship_account_number
                     )                                             AS ship_account_name      --�o�א�ڋq����
                    ,temp.cash_receiv_base_code                    AS cash_receiv_base_code  --�������_�R�[�h
                    ,temp.bill_party_id                            AS bill_party_id          --�p�[�e�BID
                    ,temp.bill_bill_base_code                      AS bill_bill_base_code    --�������_�R�[�h
                    ,temp.bill_postal_code                         AS bill_postal_code       --�X�֔ԍ�
                    ,temp.bill_state                               AS bill_state             --�s���{��
                    ,temp.bill_city                                AS bill_city              --�s�E��
                    ,temp.bill_address1                            AS bill_address1          --�Z��1
                    ,temp.bill_address2                            AS bill_address2          --�Z��2
                    ,temp.bill_tel_num                             AS bill_tel_num           --�d�b�ԍ�
                    ,temp.bill_cons_inv_flag                       AS bill_cons_inv_flag     --�ꊇ���������s�t���O
                    ,temp.bill_torihikisaki_code                   AS bill_torihikisaki_code --�����R�[�h
                    ,temp.bill_store_code                          AS bill_store_code        --�X�܃R�[�h
                    ,temp.bill_cust_store_name                     AS bill_cust_store_name   --�ڋq�X�ܖ���
                    ,temp.bill_tax_div                             AS bill_tax_div           --����ŋ敪
                    ,temp.bill_cred_rec_code1                      AS bill_cred_rec_code1    --���|�R�[�h1(������)
                    ,temp.bill_cred_rec_code2                      AS bill_cred_rec_code2    --���|�R�[�h2(���Ə�)
                    ,temp.bill_cred_rec_code3                      AS bill_cred_rec_code3    --���|�R�[�h3(���̑�)
                    ,temp.bill_invoice_type                        AS bill_invoice_type      --�������o�͌`��
                    ,temp.bill_payment_term_id                     AS bill_payment_term_id   --�x������
                    ,TO_NUMBER(temp.bill_payment_term2)            AS bill_payment_term2     --��2�x������
                    ,TO_NUMBER(temp.bill_payment_term3)            AS bill_payment_term3     --��3�x������
                    ,temp.bill_tax_round_rule                      AS bill_tax_round_rule    --�ŋ��|�[������
                    ,temp.ship_sale_base_code                      AS ship_sale_base_code    --���㋒�_�R�[�h
                    ,temp.bill_attribute4                          AS bill_attribute4        -- ���s�T�C�N��(������)
                    ,temp.bill_attribute7                          AS bill_attribute7        -- ���|�R�[�h1(������)
                    ,temp.bill_attribute8                          AS bill_attribute8        -- �������o�͌`��(������)
                    ,temp.bill_site_use_id                         AS bill_site_use_id       -- �g�p�ړI����ID(������)
                    ,temp.ship_attribute4                          AS ship_attribute4        -- ���s�T�C�N��(�o�א�)
                    ,temp.ship_attribute7                          AS ship_attribute7        -- ���|�R�[�h1(�o�א�)
                    ,temp.ship_attribute8                          AS ship_attribute8        -- �������o�͌`��(�o�א�)
                    ,temp.ship_site_use_id                         AS ship_site_use_id       -- �g�p�ړI����ID(�o�א�)
                    ,temp.ship_payment_term_id                     AS ship_payment_term_id   -- �x������
              FROM   (  --�@������ڋq��������ڋq�|�o�א�ڋq
                      SELECT /*+ LEADING(bill_hsua_1)
                                 USE_NL( bill_hzca_1 bill_hasa_1 bill_hsua_1 bill_hzad_1 bill_hzps_1 bill_hzlo_1 bill_hzcp_1 bill_hcar_1)
                                 USE_NL( ship_hzca_1 ship_hasa_1 ship_hsua_1 ship_hzad_1)
                             */
                             bill_hzca_1.cust_account_id         AS cash_account_id         --������ڋqID
                            ,bill_hzca_1.account_number          AS cash_account_number     --������ڋq�R�[�h
                            ,bill_hzca_1.cust_account_id         AS bill_account_id         --������ڋqID
                            ,bill_hzca_1.account_number          AS bill_account_number     --������ڋq�R�[�h
                            ,ship_hzca_1.cust_account_id         AS ship_account_id         --�o�א�ڋqID
                            ,ship_hzca_1.account_number          AS ship_account_number     --�o�א�ڋq�R�[�h
                            ,bill_hzad_1.receiv_base_code        AS cash_receiv_base_code   --�������_�R�[�h
                            ,bill_hzca_1.party_id                AS bill_party_id           --�p�[�e�BID
                            ,bill_hzad_1.bill_base_code          AS bill_bill_base_code     --�������_�R�[�h
                            ,bill_hzlo_1.postal_code             AS bill_postal_code        --�X�֔ԍ�
                            ,bill_hzlo_1.state                   AS bill_state              --�s���{��
                            ,bill_hzlo_1.city                    AS bill_city               --�s�E��
                            ,bill_hzlo_1.address1                AS bill_address1           --�Z��1
                            ,bill_hzlo_1.address2                AS bill_address2           --�Z��2
                            ,bill_hzlo_1.address_lines_phonetic  AS bill_tel_num            --�d�b�ԍ�
                            ,bill_hzcp_1.cons_inv_flag           AS bill_cons_inv_flag      --�ꊇ���������s�t���O
                            ,bill_hzad_1.torihikisaki_code       AS bill_torihikisaki_code  --�����R�[�h
                            ,bill_hzad_1.store_code              AS bill_store_code         --�X�܃R�[�h
                            ,bill_hzad_1.cust_store_name         AS bill_cust_store_name    --�ڋq�X�ܖ���
                            ,bill_hzad_1.tax_div                 AS bill_tax_div            --����ŋ敪
                            ,bill_hsua_1.attribute4              AS bill_cred_rec_code1     --���|�R�[�h1(������)
                            ,bill_hsua_1.attribute5              AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�)
                            ,bill_hsua_1.attribute6              AS bill_cred_rec_code3     --���|�R�[�h3(���̑�)
                            ,bill_hsua_1.attribute7              AS bill_invoice_type       --�������o�͌`��
                            ,bill_hsua_1.payment_term_id         AS bill_payment_term_id    --�x������
                            ,bill_hsua_1.attribute2              AS bill_payment_term2      --��2�x������
                            ,bill_hsua_1.attribute3              AS bill_payment_term3      --��3�x������
                            ,bill_hsua_1.tax_rounding_rule       AS bill_tax_round_rule     --�ŋ��|�[������
                            ,ship_hzad_1.sale_base_code          AS ship_sale_base_code     --���㋒�_�R�[�h
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_1.attribute4              AS bill_attribute4         -- ���s�T�C�N��(������)
                            ,bill_hsua_1.attribute7              AS bill_attribute7         -- ���|�R�[�h1(������)
                            ,bill_hsua_1.attribute8              AS bill_attribute8         -- �������o�͌`��(������)
                            ,bill_hsua_1.site_use_id             AS bill_site_use_id        -- �g�p�ړI����ID(������)
                            ,ship_hsua_1.attribute4              AS ship_attribute4         -- ���s�T�C�N��(�o�א�)
                            ,ship_hsua_1.attribute7              AS ship_attribute7         -- ���|�R�[�h1(�o�א�)
                            ,ship_hsua_1.attribute8              AS ship_attribute8         -- �������o�͌`��(�o�א�)
                            ,ship_hsua_1.site_use_id             AS ship_site_use_id        -- �g�p�ړI����ID(�o�א�)
                            ,ship_hsua_1.payment_term_id         AS ship_payment_term_id    -- �x������
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          bill_hzca_1              --������ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    bill_hasa_1              --������ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     bill_hsua_1              --������ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       bill_hzad_1              --������ڋq�ǉ����
                            ,apps.hz_party_sites            bill_hzps_1              --������p�[�e�B�T�C�g
                            ,apps.hz_locations              bill_hzlo_1              --������ڋq���Ə�
                            ,apps.hz_customer_profiles      bill_hzcp_1              --������ڋq�v���t�@�C��
                            ,apps.hz_cust_accounts          ship_hzca_1              --�o�א�ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    ship_hasa_1              --�o�א�ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     ship_hsua_1              --�o�א�ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       ship_hzad_1              --�o�א�ڋq�ǉ����
                            ,apps.hz_cust_acct_relate_all   bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
                      WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
                      AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                      AND    bill_hzca_1.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
                      AND    bill_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
                      AND    bill_hcar_1.attribute1 = '1'                                      --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
                      AND    bill_hasa_1.org_id = in_org_id                                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hasa_1.org_id = in_org_id                                    --�o�א�ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hcar_1.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hsua_1.org_id = in_org_id                                    --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hsua_1.org_id = in_org_id                                    --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
                      AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
                      AND    bill_hsua_1.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
                      AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    ship_hsua_1.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
                      AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
                      AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
                      AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
                      AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
                      AND NOT EXISTS (
                                  SELECT 'X'
                                  FROM   apps.hz_cust_acct_relate_all   cash_hcar_1                        --�ڋq�֘A�}�X�^(�����֘A)
                                  WHERE  cash_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                                  AND    cash_hcar_1.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                                  AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
                                  AND    cash_hcar_1.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                                       )
                        UNION ALL
                      --�A������ڋq�|������ڋq�|�o�א�ڋq
                      SELECT /*+ LEADING(bill_hsua_2)
                                 USE_NL( cash_hzca_2 cash_hasa_2 cash_hzad_2 cash_hcar_2)
                                 USE_NL( bill_hzca_2 bill_hasa_2 bill_hsua_2 bill_hzad_2 bill_hzps_2 bill_hzlo_2 bill_hzcp_2 bill_hcar_2)
                                 USE_NL( ship_hzca_2 ship_hasa_2 ship_hsua_2 ship_hzad_2)
                             */
                             cash_hzca_2.cust_account_id           AS cash_account_id         --������ڋqID
                            ,cash_hzca_2.account_number            AS cash_account_number     --������ڋq�R�[�h
                            ,bill_hzca_2.cust_account_id           AS bill_account_id         --������ڋqID
                            ,bill_hzca_2.account_number            AS bill_account_number     --������ڋq�R�[�h
                            ,ship_hzca_2.cust_account_id           AS ship_account_id         --�o�א�ڋqID
                            ,ship_hzca_2.account_number            AS ship_account_number     --�o�א�ڋq�R�[�h
                            ,cash_hzad_2.receiv_base_code          AS cash_receiv_base_code   --�������_�R�[�h
                            ,bill_hzca_2.party_id                  AS bill_party_id           --�p�[�e�BID
                            ,bill_hzad_2.bill_base_code            AS bill_bill_base_code     --�������_�R�[�h
                            ,bill_hzlo_2.postal_code               AS bill_postal_code        --�X�֔ԍ�
                            ,bill_hzlo_2.state                     AS bill_state              --�s���{��
                            ,bill_hzlo_2.city                      AS bill_city               --�s�E��
                            ,bill_hzlo_2.address1                  AS bill_address1           --�Z��1
                            ,bill_hzlo_2.address2                  AS bill_address2           --�Z��2
                            ,bill_hzlo_2.address_lines_phonetic    AS bill_tel_num            --�d�b�ԍ�
                            ,bill_hzcp_2.cons_inv_flag             AS bill_cons_inv_flag      --�ꊇ���������s�t���O
                            ,bill_hzad_2.torihikisaki_code         AS bill_torihikisaki_code  --�����R�[�h
                            ,bill_hzad_2.store_code                AS bill_store_code         --�X�܃R�[�h
                            ,bill_hzad_2.cust_store_name           AS bill_cust_store_name    --�ڋq�X�ܖ���
                            ,bill_hzad_2.tax_div                   AS bill_tax_div            --����ŋ敪
                            ,bill_hsua_2.attribute4                AS bill_cred_rec_code1     --���|�R�[�h1(������)
                            ,bill_hsua_2.attribute5                AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�)
                            ,bill_hsua_2.attribute6                AS bill_cred_rec_code3     --���|�R�[�h3(���̑�)
                            ,bill_hsua_2.attribute7                AS bill_invoice_type       --�������o�͌`��
                            ,bill_hsua_2.payment_term_id           AS bill_payment_term_id    --�x������
                            ,bill_hsua_2.attribute2                AS bill_payment_term2      --��2�x������
                            ,bill_hsua_2.attribute3                AS bill_payment_term3      --��3�x������
                            ,bill_hsua_2.tax_rounding_rule         AS bill_tax_round_rule     --�ŋ��|�[������
                            ,ship_hzad_2.sale_base_code            AS ship_sale_base_code     --���㋒�_�R�[�h
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_2.attribute4              AS bill_attribute4         -- ���s�T�C�N��(������)
                            ,bill_hsua_2.attribute7              AS bill_attribute7         -- ���|�R�[�h1(������)
                            ,bill_hsua_2.attribute8              AS bill_attribute8         -- �������o�͌`��(������)
                            ,bill_hsua_2.site_use_id             AS bill_site_use_id        -- �g�p�ړI����ID(������)
                            ,ship_hsua_2.attribute4              AS ship_attribute4         -- ���s�T�C�N��(�o�א�)
                            ,ship_hsua_2.attribute7              AS ship_attribute7         -- ���|�R�[�h1(�o�א�)
                            ,ship_hsua_2.attribute8              AS ship_attribute8         -- �������o�͌`��(�o�א�)
                            ,ship_hsua_2.site_use_id             AS ship_site_use_id        -- �g�p�ړI����ID(�o�א�)
                            ,ship_hsua_2.payment_term_id         AS ship_payment_term_id    -- �x������
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          cash_hzca_2              --������ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    cash_hasa_2              --������ڋq���ݒn
                            ,apps.xxcmm_cust_accounts       cash_hzad_2              --������ڋq�ǉ����
                            ,apps.hz_cust_accounts          bill_hzca_2              --������ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    bill_hasa_2              --������ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     bill_hsua_2              --������ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       bill_hzad_2              --������ڋq�ǉ����
                            ,apps.hz_party_sites            bill_hzps_2              --������p�[�e�B�T�C�g
                            ,apps.hz_locations              bill_hzlo_2              --������ڋq���Ə�
                            ,apps.hz_customer_profiles      bill_hzcp_2              --������ڋq�v���t�@�C��
                            ,apps.hz_cust_accounts          ship_hzca_2              --�o�א�ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    ship_hasa_2              --�o�א�ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     ship_hsua_2              --�o�א�ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       ship_hzad_2              --�o�א�ڋq�ǉ����
                            ,apps.hz_cust_acct_relate_all   cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
                            ,apps.hz_cust_acct_relate_all   bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
                      WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
                      AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
                      AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
                      AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
                      AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                      AND    cash_hzca_2.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
                      AND    ship_hzca_2.customer_class_code = '10'                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
                      AND    cash_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                      AND    cash_hcar_2.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                      AND    bill_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                      AND    bill_hcar_2.attribute1 = '1'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e1�f (����)
                      AND    cash_hasa_2.org_id = in_org_id                                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hasa_2.org_id = in_org_id                                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hasa_2.org_id = in_org_id                                    --�o�א�ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    cash_hcar_2.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hcar_2.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hsua_2.org_id = in_org_id                                    --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hsua_2.org_id = in_org_id                                    --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
                      AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
                      AND    bill_hsua_2.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
                      AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
                      AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    ship_hsua_2.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
                      AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
                      AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
                      AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
                        UNION ALL
                      --�B������ڋq�|������ڋq���o�א�ڋq
                      SELECT /*+ LEADING(bill_hsua_3)
                                 USE_NL( cash_hzca_3 cash_hasa_3 cash_hzad_3 cash_hcar_3 )
                                 USE_NL( bill_hasa_3 bill_hsua_3 bill_hzad_3 bill_hzps_3 bill_hzlo_3 bill_hzcp_3 )
                                 USE_NL( ship_hzca_3 ship_hsua_3 )
                             */
                             cash_hzca_3.cust_account_id             AS cash_account_id         --������ڋqID
                            ,cash_hzca_3.account_number              AS cash_account_number     --������ڋq�R�[�h
                            ,ship_hzca_3.cust_account_id             AS bill_account_id         --������ڋqID
                            ,ship_hzca_3.account_number              AS bill_account_number     --������ڋq�R�[�h
                            ,ship_hzca_3.cust_account_id             AS ship_account_id         --�o�א�ڋqID
                            ,ship_hzca_3.account_number              AS ship_account_number     --�o�א�ڋq�R�[�h
                            ,cash_hzad_3.receiv_base_code            AS cash_receiv_base_code   --�������_�R�[�h
                            ,ship_hzca_3.party_id                    AS bill_party_id           --�p�[�e�BID
                            ,bill_hzad_3.bill_base_code              AS bill_bill_base_code     --�������_�R�[�h
                            ,bill_hzlo_3.postal_code                 AS bill_postal_code        --�X�֔ԍ�
                            ,bill_hzlo_3.state                       AS bill_state              --�s���{��
                            ,bill_hzlo_3.city                        AS bill_city               --�s�E��
                            ,bill_hzlo_3.address1                    AS bill_address1           --�Z��1
                            ,bill_hzlo_3.address2                    AS bill_address2           --�Z��2
                            ,bill_hzlo_3.address_lines_phonetic      AS bill_tel_num            --�d�b�ԍ�
                            ,bill_hzcp_3.cons_inv_flag               AS bill_cons_inv_flag      --�ꊇ���������s�t���O
                            ,bill_hzad_3.torihikisaki_code           AS bill_torihikisaki_code  --�����R�[�h
                            ,bill_hzad_3.store_code                  AS bill_store_code         --�X�܃R�[�h
                            ,bill_hzad_3.cust_store_name             AS bill_cust_store_name    --�ڋq�X�ܖ���
                            ,bill_hzad_3.tax_div                     AS bill_tax_div            --����ŋ敪
                            ,bill_hsua_3.attribute4                  AS bill_cred_rec_code1     --���|�R�[�h1(������)
                            ,bill_hsua_3.attribute5                  AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�)
                            ,bill_hsua_3.attribute6                  AS bill_cred_rec_code3     --���|�R�[�h3(���̑�)
                            ,bill_hsua_3.attribute7                  AS bill_invoice_type       --�������o�͌`��
                            ,bill_hsua_3.payment_term_id             AS bill_payment_term_id    --�x������
                            ,bill_hsua_3.attribute2                  AS bill_payment_term2      --��2�x������
                            ,bill_hsua_3.attribute3                  AS bill_payment_term3      --��3�x������
                            ,bill_hsua_3.tax_rounding_rule           AS bill_tax_round_rule     --�ŋ��|�[������
                            ,bill_hzad_3.sale_base_code              AS ship_sale_base_code     --���㋒�_�R�[�h
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_3.attribute4                  AS bill_attribute4         -- ���s�T�C�N��(������)
                            ,bill_hsua_3.attribute7                  AS bill_attribute7         -- ���|�R�[�h1(������)
                            ,bill_hsua_3.attribute8                  AS bill_attribute8         -- �������o�͌`��(������)
                            ,bill_hsua_3.site_use_id                 AS bill_site_use_id        -- �g�p�ړI����ID(������)
                            ,ship_hsua_3.attribute4                  AS ship_attribute4         -- ���s�T�C�N��(�o�א�)
                            ,ship_hsua_3.attribute7                  AS ship_attribute7         -- ���|�R�[�h1(�o�א�)
                            ,ship_hsua_3.attribute8                  AS ship_attribute8         -- �������o�͌`��(�o�א�)
                            ,ship_hsua_3.site_use_id                 AS ship_site_use_id        -- �g�p�ړI����ID(�o�א�)
                            ,ship_hsua_3.payment_term_id             AS ship_payment_term_id    -- �x������
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          cash_hzca_3              --������ڋq�}�X�^
                            ,apps.hz_cust_acct_sites_all    cash_hasa_3              --������ڋq���ݒn
                            ,apps.xxcmm_cust_accounts       cash_hzad_3              --������ڋq�ǉ����
                            ,apps.hz_cust_accounts          ship_hzca_3              --�o�א�ڋq�}�X�^  ��������܂�
                            ,apps.hz_cust_acct_sites_all    bill_hasa_3              --������ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     bill_hsua_3              --������ڋq�g�p�ړI
                            ,apps.hz_cust_site_uses_all     ship_hsua_3              --�o�א�ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       bill_hzad_3              --������ڋq�ǉ����
                            ,apps.hz_party_sites            bill_hzps_3              --������p�[�e�B�T�C�g
                            ,apps.hz_locations              bill_hzlo_3              --������ڋq���Ə�
                            ,apps.hz_customer_profiles      bill_hzcp_3              --������ڋq�v���t�@�C��
                            ,apps.hz_cust_acct_relate_all   cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
                      WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
                      AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
                      AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                      AND    cash_hzca_3.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
                      AND    ship_hzca_3.customer_class_code = '10'                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
                      AND    cash_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                      AND    cash_hcar_3.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                      AND    cash_hasa_3.org_id = in_org_id                                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hasa_3.org_id = in_org_id                                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    cash_hcar_3.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hsua_3.org_id = in_org_id                                    --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hsua_3.org_id = in_org_id                                    --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    NOT EXISTS (
                                 SELECT ROWNUM
                                 FROM   apps.hz_cust_acct_relate_all ex_hcar_3                          --�ڋq�֘A�}�X�^(�����֘A)
                                 WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                                 AND    ex_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                                 AND    ex_hcar_3.org_id = in_org_id                                    --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
                                      )
                      AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id                      --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
                      AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id                  --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id              --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id              --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hsua_3.site_use_code = 'BILL_TO'                                      --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
                      AND    bill_hsua_3.status = 'A'                                                   --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hsua_3.status = 'A'                                                   --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id                  --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
                      AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id                  --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id                      --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
                      AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                          --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
                      AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)                       --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
                      UNION ALL
                      --�C������ڋq��������ڋq���o�א�ڋq
                      SELECT /*+ LEADING(bill_hsua_4)
                                 USE_NL( bill_hasa_4 bill_hsua_4 bill_hzad_4 bill_hzps_4 bill_hzlo_4 bill_hzcp_4 )
                                 USE_NL( ship_hzca_4 ship_hsua_4 )
                             */
                             ship_hzca_4.cust_account_id               AS cash_account_id         --������ڋqID
                            ,ship_hzca_4.account_number                AS cash_account_number     --������ڋq�R�[�h
                            ,ship_hzca_4.cust_account_id               AS bill_account_id         --������ڋqID
                            ,ship_hzca_4.account_number                AS bill_account_number     --������ڋq�R�[�h
                            ,ship_hzca_4.cust_account_id               AS ship_account_id         --�o�א�ڋqID
                            ,ship_hzca_4.account_number                AS ship_account_number     --�o�א�ڋq�R�[�h
                            ,bill_hzad_4.receiv_base_code              AS cash_receiv_base_code   --�������_�R�[�h
                            ,ship_hzca_4.party_id                      AS bill_party_id           --�p�[�e�BID
                            ,bill_hzad_4.bill_base_code                AS bill_bill_base_code     --�������_�R�[�h
                            ,bill_hzlo_4.postal_code                   AS bill_postal_code        --�X�֔ԍ�
                            ,bill_hzlo_4.state                         AS bill_state              --�s���{��
                            ,bill_hzlo_4.city                          AS bill_city               --�s�E��
                            ,bill_hzlo_4.address1                      AS bill_address1           --�Z��1
                            ,bill_hzlo_4.address2                      AS bill_address2           --�Z��2
                            ,bill_hzlo_4.address_lines_phonetic        AS bill_tel_num            --�d�b�ԍ�
                            ,bill_hzcp_4.cons_inv_flag                 AS bill_cons_inv_flag      --�ꊇ���������s�t���O
                            ,bill_hzad_4.torihikisaki_code             AS bill_torihikisaki_code  --�����R�[�h
                            ,bill_hzad_4.store_code                    AS bill_store_code         --�X�܃R�[�h
                            ,bill_hzad_4.cust_store_name               AS bill_cust_store_name    --�ڋq�X�ܖ���
                            ,bill_hzad_4.tax_div                       AS bill_tax_div            --����ŋ敪
                            ,bill_hsua_4.attribute4                    AS bill_cred_rec_code1     --���|�R�[�h1(������)
                            ,bill_hsua_4.attribute5                    AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�)
                            ,bill_hsua_4.attribute6                    AS bill_cred_rec_code3     --���|�R�[�h3(���̑�)
                            ,bill_hsua_4.attribute7                    AS bill_invoice_type       --�������o�͌`��
                            ,bill_hsua_4.payment_term_id               AS bill_payment_term_id    --�x������
                            ,bill_hsua_4.attribute2                    AS bill_payment_term2      --��2�x������
                            ,bill_hsua_4.attribute3                    AS bill_payment_term3      --��3�x������
                            ,bill_hsua_4.tax_rounding_rule             AS bill_tax_round_rule     --�ŋ��|�[������
                            ,bill_hzad_4.sale_base_code                AS ship_sale_base_code     --���㋒�_�R�[�h
            -----------------------------------------------------------------------------------------------------------
                            ,bill_hsua_4.attribute4                    AS bill_attribute4         -- ���s�T�C�N��(������)
                            ,bill_hsua_4.attribute7                    AS bill_attribute7         -- ���|�R�[�h1(������)
                            ,bill_hsua_4.attribute8                    AS bill_attribute8         -- �������o�͌`��(������)
                            ,bill_hsua_4.site_use_id                   AS bill_site_use_id        -- �g�p�ړI����ID(������)
                            ,ship_hsua_4.attribute4                    AS ship_attribute4         -- ���s�T�C�N��(�o�א�)
                            ,ship_hsua_4.attribute7                    AS ship_attribute7         -- ���|�R�[�h1(�o�א�)
                            ,ship_hsua_4.attribute8                    AS ship_attribute8         -- �������o�͌`��(�o�א�)
                            ,ship_hsua_4.site_use_id                   AS ship_site_use_id        -- �g�p�ړI����ID(�o�א�)
                            ,ship_hsua_4.payment_term_id               AS ship_payment_term_id    -- �x������
            -----------------------------------------------------------------------------------------------------------
                      FROM   apps.hz_cust_accounts          ship_hzca_4              --�o�א�ڋq�}�X�^�@��������E������܂�
                            ,apps.hz_cust_acct_sites_all    bill_hasa_4              --������ڋq���ݒn
                            ,apps.hz_cust_site_uses_all     bill_hsua_4              --������ڋq�g�p�ړI
                            ,apps.hz_cust_site_uses_all     ship_hsua_4              --�o�א�ڋq�g�p�ړI
                            ,apps.xxcmm_cust_accounts       bill_hzad_4              --������ڋq�ǉ����
                            ,apps.hz_party_sites            bill_hzps_4              --������p�[�e�B�T�C�g
                            ,apps.hz_locations              bill_hzlo_4              --������ڋq���Ə�
                            ,apps.hz_customer_profiles      bill_hzcp_4              --������ڋq�v���t�@�C��
                      WHERE  ship_hzca_4.customer_class_code = '10'             --������ڋq.�ڋq�敪 = '10'(�ڋq)
                      AND    bill_hasa_4.org_id = in_org_id                     --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    bill_hsua_4.org_id = in_org_id                     --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    ship_hsua_4.org_id = in_org_id                     --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
                      AND    NOT EXISTS (
                                 SELECT ROWNUM
                                 FROM   apps.hz_cust_acct_relate_all ex_hcar_4                            --�ڋq�֘A�}�X�^
                                 WHERE
                                       (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                                 OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                                 AND    ex_hcar_4.status = 'A'                                            --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                                 AND    ex_hcar_4.org_id = in_org_id                                      --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
                                 AND    ex_hcar_4.attribute1 = '2'                                        --�ڋq�֘A�}�X�^(�����֘A).�֘A�敪 = �e2�f(����)
                                      )
                      AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
                      AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
                      AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
                      AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
                      AND    bill_hsua_4.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
                      AND    ship_hsua_4.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
                      AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
                      AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
                      AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
                     ) temp
          ) customer_v
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
      ,buff   => '"������ڋqID","������ڋq�R�[�h","������ڋq����","������ڋqID","������ڋq�R�[�h","������ڋq����","�o�א�ڋqID","�o�א�ڋq�R�[�h","�o�א�ڋq����"'
    );
    -- �f�[�^���o��(CSV)
    FOR get_hz_cust_accounts_rec IN get_hz_cust_accounts_cur(ln_org_id)
     LOOP
       --�����Z�b�g
       gn_target_cnt := gn_target_cnt + 1;
       --�ύX���鍀�ڋy�уL�[�����o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| get_hz_cust_accounts_rec.cash_account_id     || '","'
                       || get_hz_cust_accounts_rec.cash_account_number || '","'
                       || get_hz_cust_accounts_rec.cash_account_name   || '","'
                       || get_hz_cust_accounts_rec.bill_account_id     || '","'
                       || get_hz_cust_accounts_rec.bill_account_number || '","'
                       || get_hz_cust_accounts_rec.bill_account_name   || '","'
                       || get_hz_cust_accounts_rec.ship_account_id     || '","'
                       || get_hz_cust_accounts_rec.ship_account_number || '","'
                       || get_hz_cust_accounts_rec.ship_account_name   || '"'
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
END XXCCP009A13C;
/