CREATE OR REPLACE PACKAGE BODY xxcmn800006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800006c(body)
 * Description      : �z����}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �z����}�X�^�C���^�t�F�[�X T_MD070_BPO_80F
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_ship_mst           �z����}�X�^�擾�v���V�[�W�� (F-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (F-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (F-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (F-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/19    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/05/09    1.1  Oracle �Ŗ� ���\  �ύX�v��#11������ύX�v��#62�#66�Ή�
 *  2008/05/14    1.2  Oracle �Ŗ� ���\  �����ύX�v��#96�Ή�
 *  2008/05/16    1.3  Oracle �ۉ� ����  �x����T�C�g�A�h�I�����̏o�͂�ǉ�
 *  2008/06/12    1.4  Oracle �ۉ�       ���t���ڏ����ύX
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcmn800006c';      -- �p�b�P�[�W��
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
  gv_get_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10036';   -- �f�[�^�擾�G���[
  gv_file_pass_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10113';   -- �t�@�C���p�X�s���G���[
  gv_file_pass_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10119';   -- �t�@�C���p�XNULL�G���[
  gv_file_name_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10114';   -- �t�@�C�����s���G���[
  gv_file_name_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10120';   -- �t�@�C����NULL�G���[
  gv_file_priv_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10115';   -- �t�@�C���A�N�Z�X�����G���[
  gv_last_update_err  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10116';   -- �ŏI�X�V�����X�V�G���[
  gv_wf_start_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10117';   -- Workflow�N���G���[
  gv_wf_ope_div_note  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00013';   -- �����敪
  gv_object_note      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00014';   -- �Ώ�
  gv_address_note     CONSTANT VARCHAR2(100) := 'APP-XXCMN-00015';   -- ����
  gv_last_update_note CONSTANT VARCHAR2(100) := 'APP-XXCMN-00016';   -- �ŏI�X�V����
  gv_ship_type_note   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00022';   -- �o��/�L��
  gv_par_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10083';   -- �p�����[�^���t�^�`�F�b�N
  gv_rep_file         CONSTANT VARCHAR2(1)   := '0';                 -- �������ʃ��|�[�g
  gv_csv_file         CONSTANT VARCHAR2(1)   := '1';                 -- CSV�t�@�C��
  gv_ship             CONSTANT VARCHAR2(1)   := '1';                 -- �o��
  gv_pay              CONSTANT VARCHAR2(1)   := '2';                 -- �L��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �z����}�X�^�����i�[���郌�R�[�h(�o��)
  TYPE ship_mst_rec IS RECORD(
    party_site_id      hz_party_sites.party_site_id%TYPE,        -- �p�[�e�B�T�C�gID
    attribute18        hz_cust_acct_sites_all.attribute18%TYPE,  -- �z����R�[�h
    base_code          xxcmn_party_sites.base_code%TYPE,         -- ���_�R�[�h
    party_site_name    xxcmn_party_sites.party_site_name%TYPE,   -- �z���於��
    address_line1      xxcmn_party_sites.address_line1%TYPE,     -- �Z��1
    address_line2      xxcmn_party_sites.address_line2%TYPE,     -- �Z��2
    phone              xxcmn_party_sites.phone%TYPE,             -- �d�b�ԍ�
    fax                xxcmn_party_sites.fax%TYPE,               -- FAX�ԍ�
    zip                xxcmn_party_sites.zip%TYPE,               -- �X�֔ԍ�
    attribute2         hz_cust_acct_sites_all.attribute2%TYPE,   -- JPR���[�U�[�R�[�h
    attribute3         hz_cust_acct_sites_all.attribute3%TYPE,   -- �s���{���R�[�h
    attribute4         hz_cust_acct_sites_all.attribute4%TYPE,   -- �ő���Ɏԗ�
    attribute5         hz_cust_acct_sites_all.attribute5%TYPE,   -- �w�荀�ڋ敪
    attribute6         hz_cust_acct_sites_all.attribute6%TYPE,   -- �t�ыƖ����t�g�敪
    attribute7         hz_cust_acct_sites_all.attribute7%TYPE,   -- �t�ыƖ���p�`�[�敪
    attribute8         hz_cust_acct_sites_all.attribute8%TYPE,   -- �t�ыƖ��p���b�g�ϑ֋敪
    attribute9         hz_cust_acct_sites_all.attribute9%TYPE,   -- �t�ыƖ��ב��敪
    attribute10        hz_cust_acct_sites_all.attribute10%TYPE,  -- �t�ыƖ���p�p���b�g�J�S�敪
    attribute11        hz_cust_acct_sites_all.attribute11%TYPE,  -- ���[���敪
    attribute12        hz_cust_acct_sites_all.attribute12%TYPE,  -- �i�ϗA���ۋ敪
    attribute13        hz_cust_acct_sites_all.attribute13%TYPE,  -- �ʍs���؋敪
    attribute14        hz_cust_acct_sites_all.attribute14%TYPE,  -- ���ꋖ�؋敪
    attribute15        hz_cust_acct_sites_all.attribute15%TYPE,  -- �ԗ��w��敪
    attribute16        hz_cust_acct_sites_all.attribute16%TYPE,  -- �[�i���A���敪
    start_date_active  xxcmn_party_sites.start_date_active%TYPE, -- �K�p�J�n��-- �K�p�J�n��
    last_update_date   DATE                                      -- �ŏI�X�V����
  );
--
  -- �z����}�X�^�����i�[����e�[�u���^�̒�`(�o��)
  TYPE ship_mst_tbl IS TABLE OF ship_mst_rec INDEX BY PLS_INTEGER;
--
  -- �z����}�X�^�����i�[���郌�R�[�h(�L��)
  TYPE pay_mst_rec IS RECORD(
    vendor_site_id     po_vendor_sites_all.vendor_site_id%TYPE,             -- �d����T�C�gID
    vendor_site_code   po_vendor_sites_all.vendor_site_code%TYPE,           -- �d����T�C�g��
    segment1           po_vendors.segment1%TYPE,                            -- �d����ԍ�
    vendor_site_name   xxcmn_vendor_sites_all.vendor_site_name%TYPE,        -- ������
    vendor_site_short_name   xxcmn_vendor_sites_all.vendor_site_short_name%TYPE,  -- ����
    address_line1      xxcmn_vendor_sites_all.address_line1%TYPE,           -- �Z��1
    address_line2      xxcmn_vendor_sites_all.address_line2%TYPE,           -- �Z��2
    phone              xxcmn_vendor_sites_all.phone%TYPE,                   -- �d�b�ԍ�
    fax                xxcmn_vendor_sites_all.fax%TYPE,                     -- FAX�ԍ�
    zip                xxcmn_vendor_sites_all.zip%TYPE,                     -- �X�֔ԍ�
    start_date_active  xxcmn_vendor_sites_all.start_date_active%TYPE,       -- �K�p�J�n��
    last_update_date   DATE                                                 -- �ŏI�X�V����
  );
--
  -- �z����}�X�^�����i�[����e�[�u���^�̒�`(�L��)
  TYPE pay_mst_tbl IS TABLE OF pay_mst_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_ship_mst_tbl    ship_mst_tbl;                          -- �����z��̒�`(�o��)
  gt_pay_mst_tbl     pay_mst_tbl;                           -- �����z��̒�`(�L��)
  gr_outbound_rec    xxcmn_common_pkg.outbound_rec;         -- �t�@�C�����̃��R�[�h�̒�`
  gd_sysdate         DATE;                                  -- �V�X�e�����ݓ��t
--
  /**********************************************************************************
   * Procedure Name   : get_ship_mst
   * Description      : �z����}�X�^�擾(F-1)
   ***********************************************************************************/
  PROCEDURE get_ship_mst(
    iv_wf_ope_div         IN  VARCHAR2,            -- �����敪
    iv_wf_class           IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification    IN  VARCHAR2,            -- ����
    iv_last_update        IN  VARCHAR2,            -- �ŏI�X�V����
    iv_ship_type          IN  VARCHAR2,            -- �o��/�L��
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_mst'; -- �v���O������
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
    cv_cust_class   CONSTANT VARCHAR2(30) := '11';    -- �x����
--
    -- *** ���[�J���ϐ� ***
    ld_last_update  DATE;               -- �ŏI�X�V����
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
    -- �t�@�C���o�͏��擾�֐��Ăяo��
    xxcmn_common_pkg.get_outbound_info(iv_wf_ope_div,     -- �����敪
                                       iv_wf_class,       -- �Ώ�
                                       iv_wf_notification,-- ����
                                       gr_outbound_rec,   -- �t�@�C�����̃��R�[�h�^�ϐ�
                                       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                                       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                                       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_get_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^'�ŏI�X�V����'��NULL�̏ꍇ
    IF (iv_last_update IS NULL) THEN
      ld_last_update := gr_outbound_rec.file_last_update_date;
    -- �p�����[�^'�ŏI�X�V����'��NULL�łȂ��ꍇ
    ELSE
      ld_last_update := FND_DATE.STRING_TO_DATE(iv_last_update, 'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    -- �p�����[�^'�o��/�L��'��NULL�Ⴕ���͏o�ׂ̏ꍇ
    IF ((iv_ship_type IS NULL) OR
       (iv_ship_type = gv_ship)) THEN
      SELECT hps.party_site_id,          -- �p�[�e�B�T�C�gID
             hcas.attribute18,           -- �z����R�[�h
             xps.base_code,              -- ���_�R�[�h
             xps.party_site_name,        -- ������
             xps.address_line1,          -- �Z��1
             xps.address_line2,          -- �Z��2
             xps.phone,                  -- �d�b�ԍ�
             xps.fax,                    -- FAX�ԍ�
             xps.zip,                    -- �X�֔ԍ�
             hcas.attribute2,            -- JPR���[�U�[�R�[�h
             hcas.attribute3,            -- �s���{���R�[�h
             hcas.attribute4,            -- �ő���Ɏԗ�
             hcas.attribute5,            -- �w�荀�ڋ敪
             hcas.attribute6,            -- �t�ыƖ����t�g�敪
             hcas.attribute7,            -- �t�ыƖ���p�`�[�敪
             hcas.attribute8,            -- �t�ыƖ��p���b�g�ϑ֋敪
             hcas.attribute9,            -- �t�ыƖ��ב��敪
             hcas.attribute10,           -- �t�ыƖ���p�p���b�g�J�S�敪
             hcas.attribute11,           -- ���[���敪
             hcas.attribute12,           -- �i�ϗA���ۋ敪
             hcas.attribute13,           -- �ʍs���؋敪
             hcas.attribute14,           -- ���ꋖ�؋敪
             hcas.attribute15,           -- �ԗ��w��敪
             hcas.attribute16,           -- �[�i���A���敪
             xps.start_date_active,      -- �K�p�J�n��
             CASE
               -- �ŏI�X�V�������p�[�e�B�T�C�g�A�h�I���}�X���p�[�e�B�T�C�g�}�X�^�̕����V�����ꍇ
               WHEN (hps.last_update_date >= xps.last_update_date) THEN
                 hps.last_update_date     -- �p�[�e�B�T�C�g�}�X�^�ŏI�X�V����
               ELSE
                 xps.last_update_date     -- �p�[�e�B�T�C�g�A�h�I���}�X�^�ŏI�X�V����
             END
      BULK COLLECT INTO gt_ship_mst_tbl
      FROM  hz_parties              hp,   -- �p�[�e�B�}�X�^
            hz_party_sites          hps,  -- �p�[�e�B�T�C�g�}�X�^
            xxcmn_party_sites       xps,  -- �p�[�e�B�T�C�g�A�h�I���}�X�^
            hz_cust_accounts        hca,  -- �ڋq�}�X�^
            hz_cust_acct_sites_all  hcas  -- �ڋq���ݒn�}�X�^
      WHERE hca.customer_class_code   <> cv_cust_class
      AND   hps.party_site_id         =  xps.party_site_id
      AND   hps.party_site_id         =  hcas.party_site_id
      AND   hps.party_id              =  hp.party_id
      AND   hp.party_id               =  hca.party_id
      AND   hcas.org_id               =  FND_PROFILE.VALUE('ORG_ID')
      AND   (EXISTS (
              SELECT 1
              FROM   hz_party_sites  hps1
              WHERE  hps1.party_site_id = hps.party_site_id
              AND    hps1.last_update_date >= ld_last_update
              AND    hps1.last_update_date < gd_sysdate
              AND    ROWNUM = 1)
            OR
            EXISTS (
              SELECT 1
              FROM   xxcmn_party_sites xps1
              WHERE  xps1.party_site_id = xps.party_site_id
              AND    xps1.last_update_date >= ld_last_update
              AND    xps1.last_update_date < gd_sysdate
              AND    ROWNUM = 1)
            )
      ORDER BY hcas.attribute18, xps.start_date_active;
--
    END IF;
--
    -- �p�����[�^'�o��/�L��'��NULL�Ⴕ���͗L���̏ꍇ
    IF ((iv_ship_type IS NULL) OR
       (iv_ship_type = gv_pay)) THEN
      SELECT pvsa.vendor_site_id,          -- �d����T�C�gID
             pvsa.vendor_site_code,        -- �d����T�C�g��
             pv.segment1,                  -- �d����ԍ�
             xvsa.vendor_site_name,        -- ������
             xvsa.vendor_site_short_name,  -- ����
             xvsa.address_line1,           -- �Z��1
             xvsa.address_line2,           -- �Z��2
             xvsa.phone,                   -- �d�b�ԍ�
             xvsa.fax,                     -- FAX�ԍ�
             xvsa.zip,                     -- �X�֔ԍ�
             xvsa.start_date_active,       -- �K�p�J�n��
             CASE
               -- �ŏI�X�V�������d����T�C�g�A�h�I���}�X���d����T�C�g�}�X�^�̕����V�����ꍇ
               WHEN (pvsa.last_update_date >= xvsa.last_update_date) THEN
                 pvsa.last_update_date     -- �d����T�C�g�}�X�^�ŏI�X�V����
               ELSE
                 xvsa.last_update_date     -- �d����T�C�g�A�h�I���}�X�^�ŏI�X�V����
             END
      BULK COLLECT INTO gt_pay_mst_tbl
      FROM  po_vendors              pv,   -- �d����}�X�^
            po_vendor_sites_all     pvsa, -- �d����T�C�g�}�X�^
            xxcmn_vendor_sites_all  xvsa  -- �d����T�C�g�A�h�I���}�X�^
      WHERE pv.attribute5             =  cv_cust_class
      AND   pvsa.vendor_site_id       =  xvsa.vendor_site_id
      AND   pvsa.vendor_id            =  pv.vendor_id
      AND   (EXISTS (
              SELECT 1
              FROM   po_vendor_sites_all  pvsa1
              WHERE  pvsa1.vendor_site_id = pvsa.vendor_site_id
              AND    pvsa1.last_update_date >= ld_last_update
              AND    pvsa1.last_update_date < gd_sysdate
              AND    ROWNUM = 1)
            OR
            EXISTS (
              SELECT 1
              FROM   xxcmn_vendor_sites_all xvsa1
              WHERE  xvsa1.vendor_site_id = xvsa.vendor_site_id
              AND    xvsa1.last_update_date >= ld_last_update
              AND    xvsa1.last_update_date < gd_sysdate
              AND    ROWNUM = 1)
            )
      ORDER BY pvsa.vendor_site_code, xvsa.start_date_active;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_ship_mst;
--
  /**********************************************************************************
   * Procedure Name   : output_csv�i���[�v���j
   * Description      : CSV�t�@�C���o��(F-2)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- �t�@�C�����
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    cv_itoen        CONSTANT VARCHAR2(5)  := 'ITOEN';
    cv_xxcmn_d17    CONSTANT VARCHAR2(3)  := '900';     -- �}�X�^�����e�i���X
    cv_b_num_ship   CONSTANT NUMBER       :=  95;       -- �o�הz����
    cv_b_num_pay    CONSTANT NUMBER       :=  96;       -- �L���z����
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot    CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ���[�J���ϐ� ***
    lf_file_hand    UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
    lv_csv_file     VARCHAR2(5000);        -- �o�͏��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    BEGIN
      -- �t�@�C���p�X���w�肳��Ă��Ȃ��ꍇ
      IF (gr_outbound_rec.directory IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- �t�@�C�������w�肳��Ă��Ȃ��ꍇ
      ELSIF (gr_outbound_rec.file_name IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- CSV�t�@�C���֏o�͂���ꍇ
      IF (iv_file_type = gv_csv_file) THEN
        lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                       gr_outbound_rec.file_name,
                                       'w');
      END IF;
      -- �z����}�X�^���(�o��)���擾�ł��Ă���ꍇ
      IF (gt_ship_mst_tbl.COUNT <> 0) THEN
        <<gt_ship_mst_tbl_loop>>
        FOR i IN gt_ship_mst_tbl.FIRST .. gt_ship_mst_tbl.LAST LOOP
          lv_csv_file   := cv_itoen                                 || cv_sep_com   -- ��Ж�
                        || cv_xxcmn_d17                             || cv_sep_com   -- EOS�f�[�^���
                        || cv_b_num_ship                            || cv_sep_com   -- �`�[�p�}��
                        || gt_ship_mst_tbl(i).attribute18           || cv_sep_com   -- �R�[�h1
                        || gt_ship_mst_tbl(i).base_code             || cv_sep_com   -- �R�[�h2
                                                                    || cv_sep_com   -- �R�[�h3
                        || gt_ship_mst_tbl(i).party_site_name       || cv_sep_com   -- ����1
                                                                    || cv_sep_com   -- ����2
                                                                    || cv_sep_com   -- ����3
                        || gt_ship_mst_tbl(i).address_line1         
                        || gt_ship_mst_tbl(i).address_line2         || cv_sep_com   -- ���1
                                                                    || cv_sep_com   -- ���2
                                                                    || cv_sep_com   -- ���3
                                                                    || cv_sep_com   -- ���4
                                                                    || cv_sep_com   -- ���5
                                                                    || cv_sep_com   -- ���6
                                                                    || cv_sep_com   -- ���7
                        || gt_ship_mst_tbl(i).phone                 || cv_sep_com   -- ���8
                        || gt_ship_mst_tbl(i).fax                   || cv_sep_com   -- ���9
                        || gt_ship_mst_tbl(i).zip                   || cv_sep_com   -- ���10
                        || gt_ship_mst_tbl(i).attribute2            || cv_sep_com   -- ���11
                        || gt_ship_mst_tbl(i).attribute3            || cv_sep_com   -- ���12
                                                                    || cv_sep_com   -- ���13
                                                                    || cv_sep_com   -- ���14
                                                                    || cv_sep_com   -- ���15
                                                                    || cv_sep_com   -- ���16
                                                                    || cv_sep_com   -- ���17
                                                                    || cv_sep_com   -- ���18
                                                                    || cv_sep_com   -- ���19
                                                                    || cv_sep_com   -- ���20
                        || gt_ship_mst_tbl(i).attribute4            || cv_sep_com   -- �敪1
                        || gt_ship_mst_tbl(i).attribute5            || cv_sep_com   -- �敪2
                        || gt_ship_mst_tbl(i).attribute6            || cv_sep_com   -- �敪3
                        || gt_ship_mst_tbl(i).attribute7            || cv_sep_com   -- �敪4
                        || gt_ship_mst_tbl(i).attribute8            || cv_sep_com   -- �敪5
                                                                    || cv_sep_com   -- �敪6
                        || gt_ship_mst_tbl(i).attribute9            || cv_sep_com   -- �敪7
                        || gt_ship_mst_tbl(i).attribute10           || cv_sep_com   -- �敪8
                        || gt_ship_mst_tbl(i).attribute11           || cv_sep_com   -- �敪9
                        || gt_ship_mst_tbl(i).attribute12           || cv_sep_com   -- �敪10
                        || gt_ship_mst_tbl(i).attribute13           || cv_sep_com   -- �敪11
                        || gt_ship_mst_tbl(i).attribute14           || cv_sep_com   -- �敪12
                        || gt_ship_mst_tbl(i).attribute15           || cv_sep_com   -- �敪13
                        || gt_ship_mst_tbl(i).attribute16           || cv_sep_com   -- �敪14
                                                                    || cv_sep_com   -- �敪15
                                                                    || cv_sep_com   -- �敪16
                                                                    || cv_sep_com   -- �敪17
                                                                    || cv_sep_com   -- �敪18
                                                                    || cv_sep_com   -- �敪19
                                                                    || cv_sep_com   -- �敪20
                        || TO_CHAR(gt_ship_mst_tbl(i).start_date_active, 'YYYY/MM/DD')
                                                                    || cv_sep_com   -- �K�p�J�n��
                        || TO_CHAR(gt_ship_mst_tbl(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                        ;                                                           -- �X�V����
--
          -- CSV�t�@�C���֏o�͂���ꍇ
          IF (iv_file_type = gv_csv_file) THEN
            UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
          -- �������ʃ��|�[�g�֏o�͂���ꍇ
          ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_csv_file);
          END IF;
--
        END LOOP gt_ship_mst_tbl_loop;
      END IF;
--
      -- �z����}�X�^���(�L��)���擾�ł��Ă���ꍇ
      IF (gt_pay_mst_tbl.COUNT <> 0) THEN
        <<gt_pay_mst_tbl_loop>>
        FOR i IN gt_pay_mst_tbl.FIRST .. gt_pay_mst_tbl.LAST LOOP
          lv_csv_file   := cv_itoen                                 || cv_sep_com   -- ��Ж�
                        || cv_xxcmn_d17                             || cv_sep_com   -- EOS�f�[�^���
                        || cv_b_num_pay                             || cv_sep_com   -- �`�[�p�}��
                        || gt_pay_mst_tbl(i).vendor_site_code       || cv_sep_com   -- �R�[�h1
                        || gt_pay_mst_tbl(i).segment1               || cv_sep_com   -- �R�[�h2
                                                                    || cv_sep_com   -- �R�[�h3
                        || gt_pay_mst_tbl(i).vendor_site_name       || cv_sep_com   -- ����1
                        || gt_pay_mst_tbl(i).vendor_site_short_name || cv_sep_com   -- ����2
                                                                    || cv_sep_com   -- ����3
                        || gt_pay_mst_tbl(i).address_line1         
                        || gt_pay_mst_tbl(i).address_line2          || cv_sep_com   -- ���1
                                                                    || cv_sep_com   -- ���2
                                                                    || cv_sep_com   -- ���3
                                                                    || cv_sep_com   -- ���4
                                                                    || cv_sep_com   -- ���5
                                                                    || cv_sep_com   -- ���6
                                                                    || cv_sep_com   -- ���7
                        || gt_pay_mst_tbl(i).phone                  || cv_sep_com   -- ���8
                        || gt_pay_mst_tbl(i).fax                    || cv_sep_com   -- ���9
                        || gt_pay_mst_tbl(i).zip                    || cv_sep_com   -- ���10
                                                                    || cv_sep_com   -- ���11
                                                                    || cv_sep_com   -- ���12
                                                                    || cv_sep_com   -- ���13
                                                                    || cv_sep_com   -- ���14
                                                                    || cv_sep_com   -- ���15
                                                                    || cv_sep_com   -- ���16
                                                                    || cv_sep_com   -- ���17
                                                                    || cv_sep_com   -- ���18
                                                                    || cv_sep_com   -- ���19
                                                                    || cv_sep_com   -- ���20
                                                                    || cv_sep_com   -- �敪1
                                                                    || cv_sep_com   -- �敪2
                                                                    || cv_sep_com   -- �敪3
                                                                    || cv_sep_com   -- �敪4
                                                                    || cv_sep_com   -- �敪5
                                                                    || cv_sep_com   -- �敪6
                                                                    || cv_sep_com   -- �敪7
                                                                    || cv_sep_com   -- �敪8
                                                                    || cv_sep_com   -- �敪9
                                                                    || cv_sep_com   -- �敪10
                                                                    || cv_sep_com   -- �敪11
                                                                    || cv_sep_com   -- �敪12
                                                                    || cv_sep_com   -- �敪13
                                                                    || cv_sep_com   -- �敪14
                                                                    || cv_sep_com   -- �敪15
                                                                    || cv_sep_com   -- �敪16
                                                                    || cv_sep_com   -- �敪17
                                                                    || cv_sep_com   -- �敪18
                                                                    || cv_sep_com   -- �敪19
                                                                    || cv_sep_com   -- �敪20
                        || TO_CHAR(gt_pay_mst_tbl(i).start_date_active, 'YYYY/MM/DD')
                                                                    || cv_sep_com   -- �K�p�J�n��
                        || TO_CHAR(gt_pay_mst_tbl(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                        ;                                                           -- �X�V����
--
          -- CSV�t�@�C���֏o�͂���ꍇ
          IF (iv_file_type = gv_csv_file) THEN
            UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
          -- �������ʃ��|�[�g�֏o�͂���ꍇ
          ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_csv_file);
          END IF;
--
        END LOOP gt_pay_mst_tbl_loop;
      END IF;
      -- CSV�t�@�C���֏o�͂���ꍇ
      IF (iv_file_type = gv_csv_file) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH THEN       -- �t�@�C���p�X�s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- �t�@�C�����s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED THEN      -- �t�@�C���A�N�Z�X�����G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_priv_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
    END;
--
  --==============================================================
  --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
  --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : upd_last_update
   * Description      : �ŏI�X�V�����t�@�C���X�V(F-3)
   ***********************************************************************************/
  PROCEDURE upd_last_update(
    iv_wf_ope_div       IN  VARCHAR2,            -- �����敪
    iv_wf_class         IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,            -- ����
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_update'; -- �v���O������
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
    -- �t�@�C���o�͏��X�V�֐��Ăяo��
    xxcmn_common_pkg.upd_outbound_info(iv_wf_ope_div,     -- �����敪
                                       iv_wf_class,       -- �Ώ�
                                       iv_wf_notification,-- ����
                                       gd_sysdate,        -- �V�X�e�����ݓ��t
                                       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                                       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                                       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END upd_last_update;
--
  /**********************************************************************************
   * Procedure Name   : wf_notif
   * Description      : Workflow�ʒm(F-4)
   ***********************************************************************************/
  PROCEDURE wf_notif(
    iv_wf_ope_div       IN  VARCHAR2,           -- �����敪
    iv_wf_class         IN  VARCHAR2,           -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,           -- ����
    ov_errbuf           OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_notif'; -- �v���O������
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
    -- ���[�N�t���[�N���֐��Ăяo��
    xxcmn_common_pkg.wf_start(iv_wf_ope_div,     -- �����敪
                              iv_wf_class,       -- �Ώ�
                              iv_wf_notification,-- ����
                              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_start_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END wf_notif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN  VARCHAR2,        -- �����敪
    iv_wf_class          IN  VARCHAR2,        -- �Ώ�
    iv_wf_notification   IN  VARCHAR2,        -- ����
    iv_last_update       IN  VARCHAR2,        -- �ŏI�X�V����
    iv_ship_type         IN  VARCHAR2,        -- �o��/�L��
    ov_errbuf            OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_out_par    VARCHAR2(1000);   -- ���̓p�����[�^�o��
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
    -- ��������
    -- ===============================
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate := SYSDATE;
--
    -- ���̓p�����[�^�̏������ʃ��|�[�g�o��
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_ope_div_note,
                                          'PAR',iv_wf_ope_div);       -- �����敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_object_note,
                                          'PAR',iv_wf_class);         -- �Ώ�
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_address_note,
                                          'PAR',iv_wf_notification);  -- ����
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_note,
                                          'PAR',iv_last_update);      -- �ŏI�X�V����
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_ship_type_note,
                                          'PAR',iv_ship_type);        -- �o��/�L��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    -- �p�����[�^�`�F�b�N���ʊ֐��Ăяo��
    IF ((iv_last_update IS NOT NULL) AND
       (xxcmn_common_pkg.check_param_date_yyyymmdd(iv_last_update) = 1)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_par_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �z����}�X�^�擾 (F-1)
    -- ===============================
    get_ship_mst(
      iv_wf_ope_div,        -- �����敪
      iv_wf_class,          -- �Ώ�
      iv_wf_notification,   -- ����
      iv_last_update,       -- �ŏI�X�V����
      iv_ship_type,         -- �o��/�L��
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���o�f�[�^�̏o��
    -- ===============================
    output_csv(
      gv_rep_file,       -- �������ʃ��|�[�g
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_target_cnt := (gt_ship_mst_tbl.COUNT + gt_pay_mst_tbl.COUNT);
--
    -- ===============================
    -- CSV�t�@�C���o�� (F-2)
    -- ===============================
    output_csv(
      gv_csv_file,       -- CSV�t�@�C��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_normal_cnt := (gt_ship_mst_tbl.COUNT + gt_pay_mst_tbl.COUNT);
--
    -- ===============================
    -- �ŏI�X�V�����t�@�C���X�V (F-3)
    -- ===============================
    upd_last_update(
      iv_wf_ope_div,     -- �����敪
      iv_wf_class,       -- �Ώ�
      iv_wf_notification,-- ����
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- Workflow�ʒm (F-4)
    -- ===============================
    wf_notif(
      iv_wf_ope_div,     -- �����敪
      iv_wf_class,       -- �Ώ�
      iv_wf_notification,-- ����
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
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
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div       IN  VARCHAR2,            -- �����敪
    iv_wf_class         IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,            -- ����
    iv_last_update      IN  VARCHAR2,            -- �ŏI�X�V����
    iv_ship_type        IN  VARCHAR2             -- �o��/�L��
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
      iv_wf_ope_div,         -- �����敪
      iv_wf_class,           -- �Ώ�
      iv_wf_notification,    -- ����
      iv_last_update,        -- �ŏI�X�V����
      iv_ship_type,          -- �o��/�L��
      lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
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
END xxcmn800006c;
/
