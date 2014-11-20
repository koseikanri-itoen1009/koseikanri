CREATE OR REPLACE PACKAGE BODY xxwip740001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740001C(body)
 * Description      : �����X�V����
 * MD.050           : �^���v�Z�i�����j   T_MD050_BPO_740
 * MD.070           : �����X�V           T_MD070_BPO_74B
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_related_date       �֘A�f�[�^�擾(B-1)
 *  get_deliverys          �^���w�b�_�[�A�h�I���f�[�^�擾(B-2�AB-8)
 *  get_adj_charges        �^�������A�h�I���f�[�^�擾(B-3�AB-9)
 *  get_billing            ������A�h�I���}�X�^�f�[�^�擾(B-4�AB-10)
 *  get_before             �O�X���A�O���f�[�^�擾(B-5�AB-11)
 *  set_ins_date           �o�^�f�[�^�ݒ�(B-6�AB-12)
 *  init_plsql             PL/SQL�\������(B-7)
 *  ins_billing            ������A�h�I���}�X�^�ꊇ�o�^����(B-13)
 *  upd_billing            ������A�h�I���}�X�^�ꊇ�X�V����(B-14)
 *  sub_submain            �T�u���C�������v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0  Oracle �a�c ��P  ����쐬
 *  2008/09/29    1.1  Oracle �g�c �Ď�  T_S_614�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lock_expt                  EXCEPTION;  -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name           CONSTANT VARCHAR2(100) := 'xxwip740001c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_wip_msg_kbn        CONSTANT VARCHAR2(5) := 'XXWIP';
  gv_cmn_msg_kbn        CONSTANT VARCHAR2(5) := 'XXCMN';
--
  -- ���b�Z�[�W�ԍ�(XXWIP)
  gv_wip_msg_74b_005    CONSTANT VARCHAR2(15) := 'APP-XXWIP-10067'; -- �v���t�@�C���擾�G���[
  gv_wip_msg_74b_004    CONSTANT VARCHAR2(15) := 'APP-XXWIP-10004'; -- ���b�N�G���[�ڍ׃��b�Z�[�W
  gv_cmn_msg_notfnd     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
  gv_cmn_msg_toomny     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10137'; -- �Ώۃf�[�^������
--
  -- �g�[�N��
  gv_tkn_ng_profile     CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  gv_tkn_table          CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_key            CONSTANT VARCHAR2(10) := 'KEY';
--
  -- �g�[�N���l
  gv_billing_dummy_name CONSTANT VARCHAR2(30) := '�����N���_�~�[�L�[';
  gv_billing_mst_name   CONSTANT VARCHAR2(30) := '������A�h�I���}�X�^';
--
  -- �v���t�@�C���E�I�v�V����
  gv_charge_dmy         CONSTANT VARCHAR2(23) := 'XXWIP_CHARGE_YYYYMM_DMY';  -- �����N���_�~�[�L�[
--
  -- ����ŋ敪
  gv_cons_tax_cls_month    CONSTANT VARCHAR2(1) := '1'; -- ��
  gv_cons_tax_cls_detail   CONSTANT VARCHAR2(1) := '2'; -- ����
--
  -- ����ŗ��^�C�v
  gv_cons_tax_rate_type    CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE';
--
  -- �l�̌ܓ��敪
  gv_half_adjust_cls_up    CONSTANT VARCHAR2(1) := '1';   -- �؂�グ
  gv_half_adjust_cls_down  CONSTANT VARCHAR2(1) := '2';   -- �؂�̂�
  gv_half_adjust_cls_rnd   CONSTANT VARCHAR2(1) := '3';   -- �l�̌ܓ�
--
  -- �x�������敪
  gv_p_b_cls_bil           CONSTANT VARCHAR2(1) := '2';    -- ����
--
  -- ������ې�
  gv_tax_free_bil_off      CONSTANT VARCHAR2(1) := '0';    -- OFF
  gv_tax_free_bil_on       CONSTANT VARCHAR2(1) := '1';    -- ON
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ������A�h�I���}�X�^�ݒ�p�}�X�^���R�[�h
  TYPE masters_rec IS RECORD(
    billing_code           xxwip_billing_mst.billing_code%TYPE,             -- ������R�[�h
    billing_date           VARCHAR2(6),                                     -- �����N��
    charged_amt_sum        NUMBER,                                          -- ��������z
    consumption_tax        NUMBER,                                          -- �����
    cong_charge_sum        NUMBER,                                          -- �ʍs����
    amount_bil_sum         NUMBER,                                          -- �����������v�z
    tax_bil_sum            NUMBER,                                          -- �ېŒ������v
    tax_free_bil_sum       NUMBER,                                          -- ��ېŒ������v
    adj_tax_extra_sum      NUMBER,                                          -- ����Œ������v
--
    billing_name           xxwip_billing_mst.billing_name%TYPE,             -- �����於
    post_no                xxwip_billing_mst.post_no%TYPE,                  -- �X�֔ԍ�
    address                xxwip_billing_mst.address%TYPE,                  -- �Z��
    telephone_no           xxwip_billing_mst.telephone_no%TYPE,             -- �d�b�ԍ�
    fax_no                 xxwip_billing_mst.fax_no%TYPE,                   -- FAX�ԍ�
    money_transfer_date    xxwip_billing_mst.money_transfer_date%TYPE,      -- �U����
    amount_receipt_money   xxwip_billing_mst.amount_receipt_money%TYPE,     -- ��������z
    amount_adjustment      xxwip_billing_mst.amount_adjustment%TYPE,        -- �����z
    condition_setting_date xxwip_billing_mst.condition_setting_date%TYPE,   -- �x�������ݒ��
    charged_amount         xxwip_billing_mst.charged_amount%TYPE            -- ���񐿋����z
  );
--
  -- �l�̌ܓ��敪�ʐݒ�p���R�[�h
  TYPE billing_rec IS RECORD(
    billing_code           xxwip_billing_mst.billing_code%TYPE,             -- ������R�[�h
    judgement_yyyymm       VARCHAR2(6),                                     -- �����N��
    consumption_tax_classe xxwip_delivery_company.consumption_tax_classe%TYPE, -- ����ŋ敪
    charged_amt_sum        NUMBER,                                          -- ��������z
    detail_tax             NUMBER,                                          -- ����Łi���ׁj
    month_tax              NUMBER,                                          -- ����Łi���j
    cong_charge_sum        NUMBER,                                          -- �ʍs����
    amount_bil_sum         NUMBER,                                          -- �����������v�z
    tax_bil_sum            NUMBER,                                          -- �ېŒ������v
    adj_tax_extra_sum      NUMBER                                           -- ����Œ������v
  );
--
  -- �Ώۃf�[�^�����i�[����e�[�u���^�̒�`
  TYPE masters_tbl   IS TABLE OF masters_rec     INDEX BY PLS_INTEGER;
  TYPE billing_tbl   IS TABLE OF billing_rec     INDEX BY PLS_INTEGER;
--
  gt_masters_tbl     masters_tbl;
  gt_billing_tbl     billing_tbl;
--
  -- *********************************************************************
  -- * ������A�h�I���}�X�^
  -- *********************************************************************
  -- �o�^PL/SQL�\�^
  -- ������A�h�I���}�X�^ID
  TYPE i_bil_bil_mst_id_type       IS TABLE OF xxwip_billing_mst.billing_mst_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������R�[�h
  TYPE i_bil_bil_code_type         IS TABLE OF xxwip_billing_mst.billing_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����於
  TYPE i_bil_bil_name_type         IS TABLE OF xxwip_billing_mst.billing_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����N��
  TYPE i_bil_bil_date_type         IS TABLE OF xxwip_billing_mst.billing_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �X�֔ԍ�
  TYPE i_bil_post_no_type          IS TABLE OF xxwip_billing_mst.post_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Z��
  TYPE i_bil_address_type          IS TABLE OF xxwip_billing_mst.address%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�b�ԍ�
  TYPE i_bil_tel_no_type           IS TABLE OF xxwip_billing_mst.telephone_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- FAX�ԍ�
  TYPE i_bil_fax_no_type           IS TABLE OF xxwip_billing_mst.fax_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U����
  TYPE i_bil_my_tran_dt_type       IS TABLE OF xxwip_billing_mst.money_transfer_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�������ݒ��
  TYPE i_bil_cn_set_dt_type        IS TABLE OF xxwip_billing_mst.condition_setting_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �O�������z
  TYPE i_bil_lt_mt_chrg_amt_type   IS TABLE OF xxwip_billing_mst.last_month_charge_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��������z
  TYPE i_bil_amt_rcp_my_type       IS TABLE OF xxwip_billing_mst.amount_receipt_money%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����z
  TYPE i_bil_amt_adjt_type         IS TABLE OF xxwip_billing_mst.amount_adjustment%TYPE
  INDEX BY BINARY_INTEGER;
  -- �J�z�z
  TYPE i_bil_blc_crd_fw_type       IS TABLE OF xxwip_billing_mst.balance_carried_forward%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���񐿋����z
  TYPE i_bil_chrg_amt_type         IS TABLE OF xxwip_billing_mst.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �������z���v
  TYPE i_bil_chrg_amt_ttl_type     IS TABLE OF xxwip_billing_mst.charged_amount_total%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��������z
  TYPE i_bil_month_sales_type      IS TABLE OF xxwip_billing_mst.month_sales%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����
  TYPE i_bil_consumption_tax_type  IS TABLE OF xxwip_billing_mst.consumption_tax%TYPE
  INDEX BY BINARY_INTEGER;
  -- �ʍs����
  TYPE i_bil_cn_chrg_type          IS TABLE OF xxwip_billing_mst.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  i_bil_bil_mst_id_tab             i_bil_bil_mst_id_type;           -- ������A�h�I���}�X�^ID
  i_bil_bil_code_tab               i_bil_bil_code_type;             -- ������R�[�h
  i_bil_bil_name_tab               i_bil_bil_name_type;             -- �����於
  i_bil_bil_date_tab               i_bil_bil_date_type;             -- �����N��
  i_bil_post_no_tab                i_bil_post_no_type;              -- �X�֔ԍ�
  i_bil_address_tab                i_bil_address_type;              -- �Z��
  i_bil_tel_no_tab                 i_bil_tel_no_type;               -- �d�b�ԍ�
  i_bil_fax_no_tab                 i_bil_fax_no_type;               -- FAX�ԍ�
  i_bil_my_tran_dt_tab             i_bil_my_tran_dt_type;           -- �U����
  i_bil_cn_set_dt_tab              i_bil_cn_set_dt_type;            -- �x�������ݒ��
  i_bil_lt_mt_chrg_amt_tab         i_bil_lt_mt_chrg_amt_type;       -- �O�������z
  i_bil_amt_adjt_tab               i_bil_amt_adjt_type;             -- �����z
  i_bil_amt_rcp_my_tab             i_bil_amt_rcp_my_type;           -- ��������z
  i_bil_blc_crd_fw_tab             i_bil_blc_crd_fw_type;           -- �J�z�z
  i_bil_chrg_amt_tab               i_bil_chrg_amt_type;             -- ���񐿋����z
  i_bil_chrg_amt_ttl_tab           i_bil_chrg_amt_ttl_type;         -- �������z���v
  i_bil_month_sales_tab            i_bil_month_sales_type;          -- ��������z
  i_bil_consumption_tax_tab        i_bil_consumption_tax_type;      -- �����
  i_bil_cn_chrg_tab                i_bil_cn_chrg_type;              -- �ʍs����
--
  -- �X�VPL/SQL�\�^
  -- ������A�h�I���}�X�^ID
  TYPE u_bil_bil_mst_id_type       IS TABLE OF xxwip_billing_mst.billing_mst_id%TYPE
  INDEX BY BINARY_INTEGER;
  -- ������R�[�h
  TYPE u_bil_bil_code_type         IS TABLE OF xxwip_billing_mst.billing_code%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����於
  TYPE u_bil_bil_name_type         IS TABLE OF xxwip_billing_mst.billing_name%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����N��
  TYPE u_bil_bil_date_type         IS TABLE OF xxwip_billing_mst.billing_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �X�֔ԍ�
  TYPE u_bil_post_no_type          IS TABLE OF xxwip_billing_mst.post_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �Z��
  TYPE u_bil_address_type          IS TABLE OF xxwip_billing_mst.address%TYPE
  INDEX BY BINARY_INTEGER;
  -- �d�b�ԍ�
  TYPE u_bil_tel_no_type           IS TABLE OF xxwip_billing_mst.telephone_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- FAX�ԍ�
  TYPE u_bil_fax_no_type           IS TABLE OF xxwip_billing_mst.fax_no%TYPE
  INDEX BY BINARY_INTEGER;
  -- �U����
  TYPE u_bil_my_tran_dt_type       IS TABLE OF xxwip_billing_mst.money_transfer_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �x�������ݒ��
  TYPE u_bil_cn_set_dt_type        IS TABLE OF xxwip_billing_mst.condition_setting_date%TYPE
  INDEX BY BINARY_INTEGER;
  -- �O�������z
  TYPE u_bil_lt_mt_chrg_amt_type   IS TABLE OF xxwip_billing_mst.last_month_charge_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��������z
  TYPE u_bil_amt_rcp_my_type       IS TABLE OF xxwip_billing_mst.amount_receipt_money%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����z
  TYPE u_bil_amt_adjt_type         IS TABLE OF xxwip_billing_mst.amount_adjustment%TYPE
  INDEX BY BINARY_INTEGER;
  -- �J�z�z
  TYPE u_bil_blc_crd_fw_type       IS TABLE OF xxwip_billing_mst.balance_carried_forward%TYPE
  INDEX BY BINARY_INTEGER;
  -- ���񐿋����z
  TYPE u_bil_chrg_amt_type         IS TABLE OF xxwip_billing_mst.charged_amount%TYPE
  INDEX BY BINARY_INTEGER;
  -- �������z���v
  TYPE u_bil_chrg_amt_ttl_type     IS TABLE OF xxwip_billing_mst.charged_amount_total%TYPE
  INDEX BY BINARY_INTEGER;
  -- ��������z
  TYPE u_bil_month_sales_type      IS TABLE OF xxwip_billing_mst.month_sales%TYPE
  INDEX BY BINARY_INTEGER;
  -- �����
  TYPE u_bil_consumption_tax_type  IS TABLE OF xxwip_billing_mst.consumption_tax%TYPE
  INDEX BY BINARY_INTEGER;
  -- �ʍs����
  TYPE u_bil_cn_chrg_type          IS TABLE OF xxwip_billing_mst.congestion_charge%TYPE
  INDEX BY BINARY_INTEGER;
--
  u_bil_bil_mst_id_tab             u_bil_bil_mst_id_type;           -- ������A�h�I���}�X�^ID
  u_bil_bil_code_tab               u_bil_bil_code_type;             -- ������R�[�h
  u_bil_bil_name_tab               u_bil_bil_name_type;             -- �����於
  u_bil_bil_date_tab               u_bil_bil_date_type;             -- �����N��
  u_bil_post_no_tab                u_bil_post_no_type;              -- �X�֔ԍ�
  u_bil_address_tab                u_bil_address_type;              -- �Z��
  u_bil_tel_no_tab                 u_bil_tel_no_type;               -- �d�b�ԍ�
  u_bil_fax_no_tab                 u_bil_fax_no_type;               -- FAX�ԍ�
  u_bil_my_tran_dt_tab             u_bil_my_tran_dt_type;           -- �U����
  u_bil_cn_set_dt_tab              u_bil_cn_set_dt_type;            -- �x�������ݒ��
  u_bil_lt_mt_chrg_amt_tab         u_bil_lt_mt_chrg_amt_type;       -- �O�������z
  u_bil_amt_rcp_my_tab             u_bil_amt_rcp_my_type;           -- ��������z
  u_bil_amt_adjt_tab               u_bil_amt_adjt_type;             -- �����z
  u_bil_blc_crd_fw_tab             u_bil_blc_crd_fw_type;           -- �J�z�z
  u_bil_chrg_amt_tab               u_bil_chrg_amt_type;             -- ���񐿋����z
  u_bil_chrg_amt_ttl_tab           u_bil_chrg_amt_ttl_type;         -- �������z���v
  u_bil_month_sales_tab            u_bil_month_sales_type;          -- ��������z
  u_bil_consumption_tax_tab        u_bil_consumption_tax_type;      -- �����
  u_bil_cn_chrg_tab                u_bil_cn_chrg_type;              -- �ʍs����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_sysdate               DATE;            -- �V�X�e�����t
  gn_user_id               NUMBER;          -- ���[�UID
  gn_login_id              NUMBER;          -- ���O�C��ID
  gn_conc_request_id       NUMBER;          -- �R���J�����g�v��ID
  gn_prog_appl_id          NUMBER;          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_conc_program_id       NUMBER;          -- �R���J�����g�E�v���O����ID
--
  gv_close_type            VARCHAR2(1);     -- ���ߋ敪
  gv_charge_dmy_key        VARCHAR2(6);     -- �����N���_�~�[�L�[
  gv_consumption_tax       VARCHAR2(2);     -- ����ŗ��i�P�� %�j
--
  gn_i_bil_tab_cnt         NUMBER;          -- ������A�h�I���}�X�^ �o�^PL/SQL�\�J�E���^�[
  gn_u_bil_tab_cnt         NUMBER;          -- ������A�h�I���}�X�^ �X�VPL/SQL�\�J�E���^�[
--
  /**********************************************************************************
   * Procedure Name   : get_related_date
   * Description      : �֘A�f�[�^�擾(B-1)
   ***********************************************************************************/
  PROCEDURE get_related_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_related_date'; -- �v���O������
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
    lv_charge_dmy_key        VARCHAR2(6);      -- �����N���_�~�[�L�[
    lv_close_type            VARCHAR2(1);      -- ���ߋ敪�iY�F���ߑO�AN�F���ߌ�j
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    gd_sysdate          := SYSDATE;                    -- �V�X�e������
    gn_user_id          := FND_GLOBAL.USER_ID;         -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;        -- ���O�C��ID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �R���J�����g�v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �ݶ��āE��۸��сE���ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- ***********************************************
    -- �v���t�@�C���F�����N���_�~�[�L�[ �擾
    -- ***********************************************
    lv_charge_dmy_key := FND_PROFILE.VALUE(gv_charge_dmy);
--
    IF (lv_charge_dmy_key IS NULL) THEN -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,
                                            gv_wip_msg_74b_005,
                                            gv_tkn_ng_profile,
                                            gv_billing_dummy_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gv_charge_dmy_key := lv_charge_dmy_key;   -- �O���[�o���ϐ��ɐݒ�
--
    -- ***********************************************
    -- �����擾
    -- ***********************************************
    xxwip_common3_pkg.check_lastmonth_close(
      lv_close_type  -- ���ߋ敪
     ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> gv_status_normal) THEN -- ���ʊ֐��G���[
      RAISE global_api_expt;
    END IF;
--
    gv_close_type := lv_close_type;   -- �O���[�o���ϐ��ɐݒ�
--
    -- ***********************************************
    -- ����ŗ����擾�i�P�ʂ�%�j
    -- ***********************************************
    BEGIN 
      SELECT  xlvv.lookup_code
      INTO    gv_consumption_tax
      FROM    xxcmn_lookup_values_v  xlvv      -- ���b�N�A�b�v�i����ŗ��p�j
      WHERE   xlvv.lookup_type  = gv_cons_tax_rate_type;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN   --*** �f�[�^�擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                              gv_cmn_msg_notfnd,
                                              gv_tkn_table,
                                              'xxcmn_lookup_values_v',
                                              gv_tkn_key,
                                              gv_cons_tax_rate_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN TOO_MANY_ROWS THEN   --*** �f�[�^�����擾�G���[ ***
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cmn_msg_kbn,
                                              gv_cmn_msg_toomny,
                                              gv_tkn_table,
                                              'xxcmn_lookup_values_v',
                                              gv_tkn_key,
                                              gv_cons_tax_rate_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_related_date;
--
  /**********************************************************************************
   * Procedure Name   : get_deliverys
   * Description      : �^���w�b�_�[�A�h�I���f�[�^�擾(B-2�AB-8)
   ***********************************************************************************/
  PROCEDURE get_deliverys(
    id_sysdate    IN  DATE,         --   ���t
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deliverys'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ==============================================================
    -- ���i�敪�A�^���ƎҁA����ŋ敪�A������R�[�h�A�����N���P�ʂ�
    -- �^���w�b�_�A�h�I�����W�v
    --  �����̎��_�ł͖��ז��̏���ł̂ݎZ�o����
    -- ==============================================================
--
    SELECT
        dhc.billing_code              -- ������R�[�h
      , dhc.judgement_yyyymm          -- �����N��
      , dhc.consumption_tax_classe    -- ����ŋ敪
      , SUM(dhc.charged_amount)       -- ��������z
-- 2008/09/29 1.1 N.Yoshida start
      --, SUM(dhc.line_tax)             -- ����Łi���ׁj
      , NULL                          -- ����Łi���ׁj
      , NULL                          -- ����Łi���j   (�����ł� NULL ��ݒ�)
      , SUM(dhc.congestion_charge)    -- �ʍs����
      , NULL                          -- �����������v�z (�����ł� NULL ��ݒ�)
      , NULL                          -- �ېŒ����z     (�����ł� NULL ��ݒ�)
      , NULL                          -- ����Œ����z   (�����ł� NULL ��ݒ�)
-- 2008/09/29 1.1 N.Yoshida end
    BULK COLLECT INTO gt_billing_tbl
    FROM
        (
          SELECT   xd.goods_classe                        AS  goods_classe          -- ���i�敪
                 , xd.delivery_company_code               AS  delivery_company_code -- �^���Ǝ�
                 , xdc.consumption_tax_classe             AS  consumption_tax_classe -- ����ŋ敪
                 , xdc.billing_code                       AS  billing_code        -- ������R�[�h
                 , TO_CHAR(xd.judgement_date, 'YYYYMM')   AS  judgement_yyyymm    -- �����N��
                 , NVL(xd.charged_amount, 0)              AS  charged_amount      -- ��������z
                 , NVL(xd.congestion_charge, 0)           AS  congestion_charge   -- �ʍs����
                 , NVL(xd.picking_charge, 0)              AS  picking_charge      -- �s�b�L���O��
                 , NVL(xd.many_rate, 0)                   AS  many_rate           -- ������
                 , xdc.half_adjust_classe                 AS  half_adjust_classe  -- �l�̌ܓ��敪
-- 2008/09/29 1.1 N.Yoshida start
                 , NULL                                   AS  line_tax            -- ���גP�ʂ̏����
                 /*, CASE                                                           -- ���גP�ʂ̏����
                    -- �l�̌ܓ��敪���؂�グ
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN
                      TRUNC(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    -- �l�̌ܓ��敪���؂�̂�
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN
                      TRUNC(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    -- �l�̌ܓ��敪���l�̌ܓ�
                    WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN
                      ROUND(
                        (NVL(xd.charged_amount, 0) +
                         NVL(xd.picking_charge, 0) +
                         NVL(xd.many_rate, 0))
                       * (TO_NUMBER(gv_consumption_tax) * 0.01)
                      )
                    END line_tax*/
-- 2008/09/29 1.1 N.Yoshida end
          FROM    xxwip_deliverys        xd        -- �^���w�b�_�[�A�h�I��
                , xxwip_delivery_company xdc       -- �^���p�^���Ǝ҃}�X�^
          WHERE     TO_CHAR(xd.judgement_date, 'YYYYMM') = TO_CHAR(id_sysdate, 'YYYYMM')
          AND       xd.p_b_classe                        = gv_p_b_cls_bil
          AND       xdc.delivery_company_code            = xd.delivery_company_code
          AND       xd.goods_classe                      = xdc.goods_classe
          AND       xdc.start_date_active                <= xd.judgement_date
          AND       xd.judgement_date                    <= xdc.end_date_active
          AND       EXISTS(
                      SELECT 'X'
                      FROM   xxwip_billing_mst  xbm
                      WHERE  xbm.billing_code = xdc.billing_code
                    )
        )  dhc
        GROUP BY    dhc.goods_classe            -- ���i�敪
                  , dhc.delivery_company_code   -- �^���Ǝ�
                  , dhc.consumption_tax_classe  -- ����ŋ敪
                  , dhc.billing_code            -- ������R�[�h
                  , dhc.judgement_yyyymm        -- �����N��
        ORDER BY    dhc.billing_code 
                  , dhc.judgement_yyyymm;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_deliverys;
--
  /**********************************************************************************
   * Procedure Name   : get_adj_charges
   * Description      : �^�������A�h�I���f�[�^�擾(B-3�AB-9)
   ***********************************************************************************/
  PROCEDURE get_adj_charges(
    id_sysdate    IN  DATE,         --   ���t
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_adj_charges'; -- �v���O������
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
    ln_mas_cnt   NUMBER;               -- ������A�h�I���}�X�^�ݒ�p�J�E���^�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�E���^�[�̏�����
    ln_mas_cnt := 1;
--
    -- *********************************************
    -- ������R�[�h�Ɛ����N���ŃO���[�v��
    -- *********************************************
    <<gt_billing_tbl_loop>>
    FOR ln_index IN gt_billing_tbl.FIRST .. gt_billing_tbl.LAST LOOP
--
      -- ==================================================
      -- ����Łi���j�̎Z�o �i��������z �~ ����Łj
      -- ==================================================
-- 2008/09/29 1.1 N.Yoshida start
      --gt_billing_tbl(ln_index).month_tax :=
      --    (gt_billing_tbl(ln_index).charged_amt_sum * (TO_NUMBER(gv_consumption_tax) * 0.01));
-- 2008/09/29 1.1 N.Yoshida end
--
      -- ==============================
      -- ���� �ݒ�
      -- ==============================
      IF (gt_masters_tbl.EXISTS(ln_mas_cnt) = FALSE) THEN
        -- *** ������R�[�h ***
        gt_masters_tbl(ln_mas_cnt).billing_code     := gt_billing_tbl(ln_index).billing_code;
        -- *** �����N�� ***
        gt_masters_tbl(ln_mas_cnt).billing_date     := gt_billing_tbl(ln_index).judgement_yyyymm;
        -- *** ��������z ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  := gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** ����� ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- ����ŋ敪���u���v�̏ꍇ
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).month_tax;
--
        -- ����ŋ敪���u���ׁv�̏ꍇ
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).detail_tax;
--
        -- ��L�ȊO�̏ꍇ
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** �ʍs���� ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  := gt_billing_tbl(ln_index).cong_charge_sum;
--
      -- ==============================
      -- ������R�[�h�Ɛ����N���������ꍇ
      -- ==============================
      ELSIF ((gt_masters_tbl(ln_mas_cnt).billing_code = gt_billing_tbl(ln_index).billing_code) AND
             (gt_masters_tbl(ln_mas_cnt).billing_date = gt_billing_tbl(ln_index).judgement_yyyymm))
      THEN
        -- *** ��������z ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  :=
          gt_masters_tbl(ln_mas_cnt).charged_amt_sum + gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** ����� ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- ����ŋ敪 ���u���v �̏ꍇ
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 
            gt_masters_tbl(ln_mas_cnt).consumption_tax + gt_billing_tbl(ln_index).month_tax;
--
        -- ����ŋ敪 ���u���ׁv �̏ꍇ
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 
            gt_masters_tbl(ln_mas_cnt).consumption_tax + gt_billing_tbl(ln_index).detail_tax;
--
        -- ��L�ȊO�̏ꍇ
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** �ʍs���� ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  :=
          gt_masters_tbl(ln_mas_cnt).cong_charge_sum + gt_billing_tbl(ln_index).cong_charge_sum;
--
      -- ==============================
      -- ������R�[�h�������N�����Ⴄ�ꍇ
      -- ==============================
      ELSE
--
        -- �J�E���g�A�b�v
        ln_mas_cnt := ln_mas_cnt + 1;
        -- *** ������R�[�h ***
        gt_masters_tbl(ln_mas_cnt).billing_code     := gt_billing_tbl(ln_index).billing_code;
        -- *** �����N�� ***
        gt_masters_tbl(ln_mas_cnt).billing_date     := gt_billing_tbl(ln_index).judgement_yyyymm;
        -- *** ��������z ***
        gt_masters_tbl(ln_mas_cnt).charged_amt_sum  := gt_billing_tbl(ln_index).charged_amt_sum;
--
        -- *** ����� ***
-- 2008/09/29 1.1 N.Yoshida start
        /*-- ����ŋ敪 ���u���v�̏ꍇ
        IF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_month) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).month_tax;
--
        -- ����ŋ敪 ���u���ׁv�̏ꍇ
        ELSIF (gt_billing_tbl(ln_index).consumption_tax_classe = gv_cons_tax_cls_detail) THEN
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := gt_billing_tbl(ln_index).detail_tax;
--
        -- ��L�ȊO�̏ꍇ
        ELSE 
          gt_masters_tbl(ln_mas_cnt).consumption_tax  := 0;
        END IF;*/
-- 2008/09/29 1.1 N.Yoshida end
--
        -- *** �ʍs���� ***
        gt_masters_tbl(ln_mas_cnt).cong_charge_sum  := gt_billing_tbl(ln_index).cong_charge_sum;
      END IF;
--
    END LOOP gt_billing_tbl_loop;
--
    -- *********************************************
    -- �^�������A�h�I����蒊�o
    --     ������R�[�h�A�����N���ŏW�v
    -- *********************************************
    <<gt_billing_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
--
      BEGIN
-- 2008/09/29 1.1 N.Yoshida start
        -- �^�������A�h�I���}�X�^�����z�擾
        SELECT    SUM(adj_charges.billing_sum)
                , SUM(adj_charges.billing_tax_sum)
                , SUM(adj_charges.adj_tax_extra)
        INTO      gt_masters_tbl(ln_index).amount_bil_sum       -- �����������v�z
                , gt_masters_tbl(ln_index).tax_bil_sum          -- �ېŒ������v
                , gt_masters_tbl(ln_index).adj_tax_extra_sum    -- ����Œ������v
        FROM
          (
            SELECT    xac.billing_code AS billing_code
                    , xac.billing_date AS billing_date
                    ,(
                      NVL(amount_billing1, 0) + 
                      NVL(amount_billing2, 0) + 
                      NVL(amount_billing3, 0) + 
                      NVL(amount_billing4, 0) + 
                      NVL(amount_billing5, 0)
                    ) AS billing_sum             -- �������z�v�i�������z�P�`�T�����Z�j
                    ,(
                      CASE    -- �������z1
                        WHEN (NVL(xac.tax_free_billing1, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing1, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- �؏�
                              CEIL(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- �؎�
                              TRUNC(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- �l�̌ܓ�
                              ROUND(NVL(amount_billing1, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- �������z2
                        WHEN (NVL(xac.tax_free_billing2, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing2, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- �؏�
                              CEIL(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- �؎�
                              TRUNC(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- �l�̌ܓ�
                              ROUND(NVL(amount_billing2, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- �������z3
                        WHEN (NVL(xac.tax_free_billing3, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing3, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- �؏�
                              CEIL(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- �؎�
                              TRUNC(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- �l�̌ܓ�
                              ROUND(NVL(amount_billing3, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- �������z4
                        WHEN (NVL(xac.tax_free_billing4, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing4, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- �؏�
                              CEIL(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- �؎�
                              TRUNC(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- �l�̌ܓ�
                              ROUND(NVL(amount_billing4, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END +
                      CASE    -- �������z5
                        WHEN (NVL(xac.tax_free_billing5, gv_tax_free_bil_off) <> gv_tax_free_bil_on) THEN
                          NVL(amount_billing5, 0)
                          /*CASE
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_up) THEN    -- �؏�
                              CEIL(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_down) THEN  -- �؎�
                              TRUNC(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            WHEN (xdc.half_adjust_classe = gv_half_adjust_cls_rnd) THEN   -- �l�̌ܓ�
                              ROUND(NVL(amount_billing5, 0) * (TO_NUMBER(gv_consumption_tax) * 0.01))
                            ELSE 0
                          END*/
                        ELSE 0
                      END
                    ) AS billing_tax_sum
                    , NVL(adj_tax_extra, 0) AS adj_tax_extra  -- ����Œ���
            FROM    xxwip_adj_charges       xac   -- �^�������A�h�I��
                  , xxwip_delivery_company  xdc   -- �^���p�^���Ǝ҃}�X�^
            WHERE   xac.goods_classe            =   xdc.goods_classe
            AND     xac.delivery_company_code   =   xdc.delivery_company_code
            AND     xdc.start_date_active       <=  TO_DATE(xac.billing_date || '01','YYYYMMDD')
            AND     xdc.end_date_active         >=  TO_DATE(xac.billing_date || '01','YYYYMMDD')
            AND     xac.billing_code            =   gt_masters_tbl(ln_index).billing_code
            AND     xac.billing_date            =   gt_masters_tbl(ln_index).billing_date
          ) adj_charges
        GROUP BY   adj_charges.billing_code
                 , adj_charges.billing_date;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_masters_tbl(ln_index).amount_bil_sum   := 0;    -- �����������v�z
          gt_masters_tbl(ln_index).tax_bil_sum := 0;         -- �ېŒ������v
          gt_masters_tbl(ln_index).adj_tax_extra_sum := 0;   -- ����Œ������v
      END;
-- 2008/09/29 1.1 N.Yoshida end
--
    END LOOP gt_billing_tbl_loop;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_adj_charges;
--
  /**********************************************************************************
   * Procedure Name   : get_billing
   * Description      : ������A�h�I���}�X�^�f�[�^�擾(B-4�AB-10)
   ***********************************************************************************/
  PROCEDURE get_billing(
    id_sysdate    IN  DATE,         --   ���t
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_billing'; -- �v���O������
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
    ln_count            NUMBER;                                -- �J�E���^�[
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�J���ϐ��̏�����
    ln_count := 0;
--
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP

      SELECT xbm1.billing_name,                   -- �����於
             xbm1.post_no,                        -- �X�֔ԍ�
             xbm1.address,                        -- �Z��
             xbm1.telephone_no,                   -- �d�b�ԍ�
             xbm1.fax_no,                         -- FAX�ԍ�
             xbm1.money_transfer_date,            -- �U����
             NVL(xbm1.amount_receipt_money, 0),   -- ��������z
             NVL(xbm1.amount_adjustment, 0)       -- �����z
      INTO   gt_masters_tbl(ln_index).billing_name,
             gt_masters_tbl(ln_index).post_no,
             gt_masters_tbl(ln_index).address,
             gt_masters_tbl(ln_index).telephone_no,
             gt_masters_tbl(ln_index).fax_no,
             gt_masters_tbl(ln_index).money_transfer_date,
             gt_masters_tbl(ln_index).amount_receipt_money,
             gt_masters_tbl(ln_index).amount_adjustment
      FROM   xxwip_billing_mst   xbm1   -- ������A�h�I���}�X�^
      WHERE  xbm1.billing_code = gt_masters_tbl(ln_index).billing_code
      AND    DECODE(xbm1.billing_date, gv_charge_dmy_key,
                    '000000',          xbm1.billing_date) =
             (SELECT MAX(DECODE(xbm2.billing_date, gv_charge_dmy_key,
                                '000000',          xbm2.billing_date))
              FROM   xxwip_billing_mst xbm2
              WHERE  xbm2.billing_code = gt_masters_tbl(ln_index).billing_code);
--
      -- *********************************************
      -- �x�������ݒ���̎擾
      -- �i�V�X�e�����t�̗����{�U�����̉c�Ɠ��j
      -- *********************************************
      xxwip_common_pkg.get_business_date(
        NVL(FND_DATE.STRING_TO_DATE(TO_CHAR(ADD_MONTHS(id_sysdate,1), 'YYYYMM') ||
                                    gt_masters_tbl(ln_index).money_transfer_date
                                   ,'YYYYMMDD'),TRUNC(LAST_DAY(id_sysdate))),      -- ���t
        0,                                                   -- ����
        gt_masters_tbl(ln_index).condition_setting_date,   -- �x�������ݒ��
        lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> gv_status_normal) THEN -- ���ʊ֐��G���[
        RAISE global_api_expt;
      END IF;
--
    END LOOP gt_masters_tbl_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_billing;
--
  /**********************************************************************************
   * Procedure Name   : get_before
   * Description      : �O�X���A�O���f�[�^�擾(B-5�AB-11)
   ***********************************************************************************/
  PROCEDURE get_before(
    id_sysdate    IN  DATE,         --   ���t
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_before'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
      BEGIN
        SELECT NVL(xbm.charged_amount, 0)        -- ���񐿋����z
        INTO   gt_masters_tbl(ln_index).charged_amount
        FROM   xxwip_billing_mst   xbm   -- ������A�h�I���}�X�^
        WHERE  xbm.billing_code = gt_masters_tbl(ln_index).billing_code
        AND    xbm.billing_date = TO_CHAR(ADD_MONTHS(id_sysdate, -1), 'YYYYMM');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_masters_tbl(ln_index).charged_amount := 0;
      END;
    END LOOP gt_masters_tbl_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_before;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_date
   * Description      : �o�^�f�[�^�ݒ�(B-6�AB-12)
   ***********************************************************************************/
  PROCEDURE set_ins_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_date'; -- �v���O������
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
    lt_billing_id   xxwip_billing_mst.billing_mst_id%TYPE; -- ������A�h�I���}�X�^ID(�X�V�p)
-- 2008/09/29 1.1 N.Yoshida start
    ln_consumption_tax                             NUMBER; -- �����(�v�Z�p)
-- 2008/09/29 1.1 N.Yoshida end
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<gt_masters_tbl_loop>>
    FOR ln_index IN gt_masters_tbl.FIRST .. gt_masters_tbl.LAST LOOP
     -- ���݃`�F�b�N���s���A���݂���ꍇ�̓��b�N�������s��
      BEGIN
        SELECT xbm.billing_mst_id   -- ������A�h�I���}�X�^ID
        INTO   lt_billing_id
        FROM   xxwip_billing_mst   xbm   -- ������A�h�I���}�X�^
        WHERE  xbm.billing_code = gt_masters_tbl(ln_index).billing_code
        AND    xbm.billing_date = gt_masters_tbl(ln_index).billing_date
        FOR UPDATE NOWAIT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_billing_id := NULL;
        WHEN lock_expt THEN   -- *** ���b�N�擾�G���[ ***
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_wip_msg_kbn,   gv_wip_msg_74b_004,
                                                gv_tkn_table,     gv_billing_mst_name);
          RAISE global_api_expt;
      END;
--
-- 2008/09/29 1.1 N.Yoshida start
      -- ����ł̌v�Z�F((��������z(�^���w�b�_��)�{�ېŒ������v)�~����ŗ��~0.01)�{����Œ������v
      ln_consumption_tax := TRUNC((NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) + 
                                     NVL(gt_masters_tbl(ln_index).tax_bil_sum, 0)) * 
                                       (TO_NUMBER(gv_consumption_tax) * 0.01))      +
                            NVL(gt_masters_tbl(ln_index).adj_tax_extra_sum, 0);
-- 2008/09/29 1.1 N.Yoshida end
--
      -- �f�[�^�����݂��Ȃ��ꍇ
      IF (lt_billing_id IS NULL) THEN
        -- �J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
        gn_i_bil_tab_cnt := gn_i_bil_tab_cnt + 1;
--
        -- �o�^�pPL/SQL�\�Ƀf�[�^��ݒ�
        -- ������A�h�I���}�X�^ID
        SELECT xxwip_billing_mst_id_s1.NEXTVAL
        INTO   i_bil_bil_mst_id_tab(gn_i_bil_tab_cnt)
        FROM   dual;
        -- ������R�[�h
        i_bil_bil_code_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_code;
        -- �����於
        i_bil_bil_name_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_name;
        -- �����N��
        i_bil_bil_date_tab(gn_i_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_date;
        -- �X�֔ԍ�
        i_bil_post_no_tab(gn_i_bil_tab_cnt)   := gt_masters_tbl(ln_index).post_no;
        -- �Z��
        i_bil_address_tab(gn_i_bil_tab_cnt)   := gt_masters_tbl(ln_index).address;
        -- �d�b�ԍ�
        i_bil_tel_no_tab(gn_i_bil_tab_cnt)    := gt_masters_tbl(ln_index).telephone_no;
        -- FAX�ԍ�
        i_bil_fax_no_tab(gn_i_bil_tab_cnt)    := gt_masters_tbl(ln_index).fax_no;
        -- �U����
        i_bil_my_tran_dt_tab(gn_i_bil_tab_cnt) :=
           gt_masters_tbl(ln_index).money_transfer_date;
        -- �x�������ݒ��
        i_bil_cn_set_dt_tab(gn_i_bil_tab_cnt) :=
          gt_masters_tbl(ln_index).condition_setting_date;
        -- �O�������z
        i_bil_lt_mt_chrg_amt_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount, 0);
        -- �J�z�z
        i_bil_blc_crd_fw_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount,       0) -
          NVL(gt_masters_tbl(ln_index).amount_receipt_money, 0) -
          NVL(gt_masters_tbl(ln_index).amount_adjustment,    0);
        -- ���񐿋����z
-- 2008/09/29 1.1 N.Yoshida start
        i_bil_chrg_amt_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum,  0) +
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          NVL(gt_masters_tbl(ln_index).cong_charge_sum,  0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- �������z���v
        i_bil_chrg_amt_ttl_tab(gn_i_bil_tab_cnt) :=
          NVL(i_bil_chrg_amt_tab(gn_i_bil_tab_cnt),   0) +
          NVL(i_bil_blc_crd_fw_tab(gn_i_bil_tab_cnt), 0);
        -- ��������z
        i_bil_month_sales_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0);
        -- �����
-- 2008/09/29 1.1 N.Yoshida start
        i_bil_consumption_tax_tab(gn_i_bil_tab_cnt) := 
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- �ʍs����
        i_bil_cn_chrg_tab(gn_i_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0);
--
      -- �f�[�^�����݂���ꍇ
      ELSIF (lt_billing_id IS NOT NULL) THEN
        -- �J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
        gn_u_bil_tab_cnt := gn_u_bil_tab_cnt + 1;
--
        -- �X�V�pPL/SQL�\�Ƀf�[�^��ݒ�
        -- ������A�h�I���}�X�^ID�̊i�[
        u_bil_bil_mst_id_tab(gn_u_bil_tab_cnt) := lt_billing_id;
        -- ������R�[�h
        u_bil_bil_code_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_code;
        -- �����於
        u_bil_bil_name_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_name;
        -- �����N��
        u_bil_bil_date_tab(gn_u_bil_tab_cnt)  := gt_masters_tbl(ln_index).billing_date;
        -- �X�֔ԍ�
        u_bil_post_no_tab(gn_u_bil_tab_cnt)   := gt_masters_tbl(ln_index).post_no;
        -- �Z��
        u_bil_address_tab(gn_u_bil_tab_cnt)   := gt_masters_tbl(ln_index).address;
        -- �d�b�ԍ�
        u_bil_tel_no_tab(gn_u_bil_tab_cnt)    := gt_masters_tbl(ln_index).telephone_no;
        -- FAX�ԍ�
        u_bil_fax_no_tab(gn_u_bil_tab_cnt)    := gt_masters_tbl(ln_index).fax_no;
        -- �U����
        u_bil_my_tran_dt_tab(gn_u_bil_tab_cnt) :=
           gt_masters_tbl(ln_index).money_transfer_date;
        -- �x�������ݒ��
        u_bil_cn_set_dt_tab(gn_u_bil_tab_cnt) :=
          gt_masters_tbl(ln_index).condition_setting_date;
        -- �O�������z
        u_bil_lt_mt_chrg_amt_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount, 0);
        -- �J�z�z
        u_bil_blc_crd_fw_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amount,       0) -
          NVL(gt_masters_tbl(ln_index).amount_receipt_money, 0) -
          NVL(gt_masters_tbl(ln_index).amount_adjustment,    0);
        -- ���񐿋����z
-- 2008/09/29 1.1 N.Yoshida start
        u_bil_chrg_amt_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum,  0) +
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          NVL(gt_masters_tbl(ln_index).cong_charge_sum,  0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- �������z���v
        u_bil_chrg_amt_ttl_tab(gn_u_bil_tab_cnt) :=
          NVL(u_bil_chrg_amt_tab(gn_u_bil_tab_cnt),   0) +
          NVL(u_bil_blc_crd_fw_tab(gn_u_bil_tab_cnt), 0);
        -- ��������z
        u_bil_month_sales_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).charged_amt_sum, 0) +
          NVL(gt_masters_tbl(ln_index).amount_bil_sum,   0);
        -- �����
-- 2008/09/29 1.1 N.Yoshida start
        u_bil_consumption_tax_tab(gn_u_bil_tab_cnt) :=
          --NVL(gt_masters_tbl(ln_index).consumption_tax,  0) +
          ln_consumption_tax;
-- 2008/09/29 1.1 N.Yoshida end
        -- �ʍs����
        u_bil_cn_chrg_tab(gn_u_bil_tab_cnt) :=
          NVL(gt_masters_tbl(ln_index).cong_charge_sum, 0);
      END IF;
--
    END LOOP gt_masters_tbl_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_ins_date;
--
  /**********************************************************************************
   * Procedure Name   : ins_billing
   * Description      : ������A�h�I���}�X�^�ꊇ�o�^����(B-13)
   ***********************************************************************************/
  PROCEDURE ins_billing(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_billing'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ***************************
    -- * ������A�h�I���}�X�^ �o�^
    -- ***************************
    FORALL ln_index IN i_bil_bil_mst_id_tab.FIRST .. i_bil_bil_mst_id_tab.LAST
      INSERT INTO xxwip_billing_mst                    -- ������A�h�I���}�X�^
      (billing_mst_id,                                 -- 1.������A�h�I���}�X�^ID
       billing_code,                                   -- 2.������R�[�h
       billing_name,                                   -- 3.�����於
       billing_date,                                   -- 4.�����N��
       post_no,                                        -- 5.�X�֔ԍ�
       address,                                        -- 6.�Z��
       telephone_no,                                   -- 7.�d�b�ԍ�
       fax_no,                                         -- 8.FAX�ԍ�
       money_transfer_date,                            -- 9.�U����
       condition_setting_date,                         -- 10.�x�������ݒ��
       last_month_charge_amount,                       -- 11.�O�������z
       amount_receipt_money,                           -- 12.��������z
       amount_adjustment,                              -- 13.������
       balance_carried_forward,                        -- 14.�J�z�z
       charged_amount,                                 -- 15.���񐿋����z
       charged_amount_total,                           -- 16.�������z���v
       month_sales,                                    -- 17.��������z
       consumption_tax,                                -- 18.�����
       congestion_charge,                              -- 19.�ʍs����
       created_by,                                     -- 20.�쐬��
       creation_date,                                  -- 21.�쐬��
       last_updated_by,                                -- 22.�ŏI�X�V��
       last_update_date,                               -- 23.�ŏI�X�V��
       last_update_login,                              -- 24.�ŏI�X�V���O�C��
       request_id,                                     -- 25.�v��ID
       program_application_id,                         -- 26.�ݶ��āE��۸��сE���ع����ID
       program_id,                                     -- 27.�R���J�����g�E�v���O����ID
       program_update_date)                            -- 28.�v���O�����X�V��
      VALUES
      (i_bil_bil_mst_id_tab(ln_index),                 -- 1.������A�h�I���}�X�^ID
       i_bil_bil_code_tab(ln_index),                   -- 2.������R�[�h
       i_bil_bil_name_tab(ln_index),                   -- 3.�����於
       i_bil_bil_date_tab(ln_index),                   -- 4.�����N��
       i_bil_post_no_tab(ln_index),                    -- 5.�X�֔ԍ�
       i_bil_address_tab(ln_index),                    -- 6.�Z��
       i_bil_tel_no_tab(ln_index),                     -- 7.�d�b�ԍ�
       i_bil_fax_no_tab(ln_index),                     -- 8.FAX�ԍ�
       i_bil_my_tran_dt_tab(ln_index),                 -- 9.�U����
       i_bil_cn_set_dt_tab(ln_index),                  -- 10.�x�������ݒ��
       i_bil_lt_mt_chrg_amt_tab(ln_index),             -- 11.�O�������z
       NULL,                                           -- 12.��������z
       NULL,                                           -- 13.������
       i_bil_blc_crd_fw_tab(ln_index),                 -- 14.�J�z�z
       i_bil_chrg_amt_tab(ln_index),                   -- 15.���񐿋����z
       i_bil_chrg_amt_ttl_tab(ln_index),               -- 16.�������z���v
       i_bil_month_sales_tab(ln_index),                -- 17.��������z
       i_bil_consumption_tax_tab(ln_index),            -- 18.�����
       i_bil_cn_chrg_tab(ln_index),                    -- 19.�ʍs����
       gn_user_id,                                     -- 20.�쐬��
       gd_sysdate,                                     -- 21.�쐬��
       gn_user_id,                                     -- 22.�ŏI�X�V��
       gd_sysdate,                                     -- 23.�ŏI�X�V��
       gn_login_id,                                    -- 24.�ŏI�X�V���O�C��
       gn_conc_request_id,                             -- 25.�v��ID
       gn_prog_appl_id,                                -- 26.�ݶ��āE��۸��сE���ع����ID
       gn_conc_program_id,                             -- 27.�R���J�����g�E�v���O����ID
       gd_sysdate);                                    -- 28.�v���O�����X�V��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_billing;
--
  /**********************************************************************************
   * Procedure Name   : upd_billing
   * Description      : ������A�h�I���}�X�^�ꊇ�X�V����(B-14)
   ***********************************************************************************/
  PROCEDURE upd_billing(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_billing'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ***************************
    -- * ������A�h�I���}�X�^ �o�^
    -- ***************************
    FORALL ln_index IN u_bil_bil_mst_id_tab.FIRST .. u_bil_bil_mst_id_tab.LAST
      UPDATE xxwip_billing_mst xbm    -- ������A�h�I���}�X�^
      SET    billing_name             = u_bil_bil_name_tab(ln_index),        -- �����於
             post_no                  = u_bil_post_no_tab(ln_index),         -- �X�֔ԍ�
             address                  = u_bil_address_tab(ln_index),         -- �Z��
             telephone_no             = u_bil_tel_no_tab(ln_index),          -- �d�b�ԍ�
             fax_no                   = u_bil_fax_no_tab(ln_index),          -- FAX�ԍ�
             money_transfer_date      = u_bil_my_tran_dt_tab(ln_index),      -- �U����
             condition_setting_date   = u_bil_cn_set_dt_tab(ln_index),       -- �x�������ݒ��
             last_month_charge_amount = u_bil_lt_mt_chrg_amt_tab(ln_index),  -- �O�������z
             balance_carried_forward  = u_bil_blc_crd_fw_tab(ln_index),      -- �J�z�z
             charged_amount           = u_bil_chrg_amt_tab(ln_index),        -- ���񐿋����z
             charged_amount_total     = u_bil_chrg_amt_ttl_tab(ln_index),    -- �������z���v
             month_sales              = u_bil_month_sales_tab(ln_index),     -- ��������z
             consumption_tax          = u_bil_consumption_tax_tab(ln_index), -- �����
             congestion_charge        = u_bil_cn_chrg_tab(ln_index),         -- �ʍs����
             last_updated_by          = gn_user_id,                 -- �ŏI�X�V��
             last_update_date         = gd_sysdate,                 -- �ŏI�X�V��
             last_update_login        = gn_login_id,                -- �ŏI�X�V۸޲�
             request_id               = gn_conc_request_id,         -- �v��ID
             program_application_id   = gn_prog_appl_id,            -- �ݶ��āE��۸��сE���ع����ID
             program_id               = gn_conc_program_id,         -- �ݶ��āE��۸���ID
             program_update_date      = gd_sysdate                  -- ��۸��эX�V��
      WHERE  xbm.billing_mst_id       = u_bil_bil_mst_id_tab(ln_index);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_billing;
--
  /**********************************************************************************
   * Procedure Name   : init_plsql
   * Description      : PL/SQL�\������(B-7)
   ***********************************************************************************/
  PROCEDURE init_plsql(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_plsql'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- PL/SQL�\�̏�����
    gt_masters_tbl.DELETE;
    gt_billing_tbl.DELETE;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init_plsql;
--
  /**********************************************************************************
   * Procedure Name   : sub_submain
   * Description      : �T�u���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE sub_submain(
    id_param_date IN  DATE,         --   1.���t�i�����A�O���j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sub_submain'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�U��`�O���[�o���ϐ��̏�����
    gn_i_bil_tab_cnt   := 0;
    gn_u_bil_tab_cnt   := 0;
--
    -- ===========================================
    -- �^���w�b�_�[�A�h�I���f�[�^�擾(B-2�AB-8)
    -- ===========================================
    get_deliverys(
      id_param_date,     -- ���t
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �Ώۃf�[�^�Ȃ��̏ꍇ
    IF (gt_billing_tbl.COUNT = 0) THEN
      RETURN;
    END IF;
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- �^�������A�h�I���f�[�^�擾(B-3�AB-9)
    -- ===========================================
    get_adj_charges(
      id_param_date,     -- ���t
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- ������A�h�I���}�X�^�f�[�^�擾(B-4�AB-10)
    -- ===========================================
    get_billing(
      id_param_date,     -- ���t
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- �O�X���A�O���f�[�^�擾(B-5�AB-11)
    -- ===========================================
    get_before(
      id_param_date,     -- ���t
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- �o�^�f�[�^�ݒ�(B-6�AB-12)
    -- ===========================================
    set_ins_date(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- ������A�h�I���}�X�^�ꊇ�o�^����(B-13)
    -- ===========================================
    ins_billing(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- ������A�h�I���}�X�^�ꊇ�X�V����(B-14)
    -- ===========================================
    upd_billing(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sub_submain;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    -- ===========================================
    -- �֘A�f�[�^�擾(B-1)
    -- ===========================================
    get_related_date(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �����O�̏ꍇ
    IF (gv_close_type = 'Y') THEN
      -- ===========================================
      -- �T�u���C�������v���V�[�W��
      -- ===========================================
      sub_submain(
        ADD_MONTHS(gd_sysdate, -1), -- �O��
        lv_errbuf,                  -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,                 -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===========================================
      -- PL/SQL�\������(B-7)
      -- ===========================================
      init_plsql(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE global_process_expt;
      -- �����������̏ꍇ
      ELSIF (lv_retcode = gv_status_normal) THEN
        -- �R�~�b�g
        COMMIT;
      END IF;
--
    END IF;
--
    -- ������̏ꍇ
    -- ===========================================
    -- �T�u���C�������v���V�[�W��
    -- ===========================================
    sub_submain(
      gd_sysdate,        -- ����
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwip740001c;
/
