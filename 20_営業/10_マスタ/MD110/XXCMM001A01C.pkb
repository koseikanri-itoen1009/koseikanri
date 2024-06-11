CREATE OR REPLACE PACKAGE BODY XXCMM001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM001A01C(spec)
 * Description      : �d����}�X�^IF�o�́i���n�j
 * MD.050           : �d����}�X�^IF�o�́i���n�jMD050_CMM_001_A01
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             CSV�t�@�C���o�͏���(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   SCS �H�� �^��    ����쐬
 *  2009/03/09    1.1   SCS ��� �ϑ��Y  �d����̋�s�����o�^�`�F�b�N���R�����g�A�E�g
 *  2009/05/13    1.2   SCS �g�� ����    T1_0978�Ή�
 *  2009/12/04    1.3   SCS �m�� �d�l    E_�{�ғ�_00307�Ή�
 *  2010/03/08    1.4   SCS �v�ۓ� �L    E_�{�ғ�_01820�Ή�
 *                                       �E�a����ʖ��̂Ɂu���~�a��,�ʒi�a���v��ǉ�
 *  2024/05/15    1.5   SCSK �Ԓn �w     E_�{�ғ�_19529�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
--  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1(���g�p)
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
--  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����(���g�p)
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
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- �A�h�I���F�}�X�^
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F���ʁEIF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM001A01C';      -- �p�b�P�[�W��
--
  -- ���b�Z�[�W�ԍ�(�}�X�^)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- �Ώۃf�[�^�������b�Z�[�W
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- �t�@�C���p�X�s���G���[
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- �t�@�C���A�N�Z�X�����G���[
  cv_csv_data_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';  -- CSV�f�[�^�o�̓G���[
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';  -- CSV�t�@�C�����݃`�F�b�N
  cv_bank_account_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00100';  -- ��s�������Ȃ��G���[
  -- ���b�Z�[�W�ԍ�(���ʁEIF)
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';  -- �t�@�C�������b�Z�[�W
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
--
  -- �v���t�@�C��
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';   -- �d����}�X�^�A�g�pCSV�t�@�C���o�͐�
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_001A01_OUT_FILE'; -- �d����}�X�^�A�g�pCSV�t�@�C����
--
  -- �g�[�N��
  cv_tkn_ng_profile    CONSTANT VARCHAR2(30) := 'NG_PROFILE';        -- �G���[�v���t�@�C����
  cv_tkn_ng_word       CONSTANT VARCHAR2(30) := 'NG_WORD';           -- �G���[���ږ�
  cv_tkn_ng_data       CONSTANT VARCHAR2(30) := 'NG_DATA';           -- �G���[�f�[�^
  cv_tkn_ng_code       CONSTANT VARCHAR2(30) := 'NG_CODE';           -- �G���[�R�[�h
  cv_tkn_filename      CONSTANT VARCHAR2(30) := 'FILE_NAME';         -- �t�@�C����
  cv_prf_dir_nm        CONSTANT VARCHAR2(30) := 'CSV�t�@�C���o�͐�';
  cv_prf_fil_nm        CONSTANT VARCHAR2(30) := 'CSV�t�@�C����';
  cv_vender_num        CONSTANT VARCHAR2(30) := '�d����ԍ�';
--
  -- �b�r�u�p�Œ�l
  cc_itoen             CONSTANT CHAR(3)      := '001';               -- ��ЃR�[�h�i001:�Œ�j
  cd_sysdate           DATE                  := SYSDATE;             -- �����J�n����
  cc_output            CONSTANT CHAR(1)      := 'w';                 -- �o�̓X�e�[�^�X
  cc_payment_eft       CONSTANT CHAR(3)      := 'EFT';               -- �d�M�x��
--
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add start by Y.Kuboshima
  -- �Q�ƃ^�C�v
  cv_koza_type         CONSTANT VARCHAR2(30) := 'XXCSO1_KOZA_TYPE';  -- �Q�ƃ^�C�v(�������)
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add end by Y.Kuboshima
-- Ver1.5 Add Start
  cv_vendor_type        CONSTANT VARCHAR2(30) := 'VENDOR TYPE';                  -- �Q�ƃ^�C�v(�d����^�C�v)
  cv_bank_charge_bearer CONSTANT VARCHAR2(30) := 'BANK CHARGE BEARER';           -- �Q�ƃ^�C�v(�U���萔�����S��)
  cv_sp_tran_fee_type   CONSTANT VARCHAR2(30) := 'XXCSO1_SP_TRANSFER_FEE_TYPE';  -- �Q�ƃ^�C�v(�r�o�ꌈ�U���萔�����S�敪)
  cv_bm_payment_kbn     CONSTANT VARCHAR2(30) := 'XXCMM_BM_PAYMENT_KBN';         -- �Q�ƃ^�C�v(BM�x���敪)
  cv_bm_tax_kbn         CONSTANT VARCHAR2(30) := 'XXCSO1_BM_TAX_KBN';            -- �Q�ƃ^�C�v(BM�ŋ敪)
  cv_invoice_tax_div_bm CONSTANT VARCHAR2(30) := 'XXCMM_INVOICE_TAX_DIV_BM';     -- �Q�ƃ^�C�v(�Ōv�Z�敪)
-- Ver1.5 Add End
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �d����}�X�^�����i�[���郌�R�[�h
  TYPE  csv_out_rec IS RECORD(
        vender_num              VARCHAR2(9),    --�d����R�[�h
        vendor_site_code        VARCHAR2(9),    --�d����T�C�g�R�[�h
        vendor_nm               VARCHAR2(100),  --�d���於��
        zip                     VARCHAR2(7),    --���ݒn�F�X�֔ԍ�
        state                   VARCHAR2(100),  --���ݒn�F�s���{��
        city                    VARCHAR2(50),   --���ݒn�F�S�s��
        address1                VARCHAR2(100),  --���ݒn�F�Z���P
        pay_nm                  VARCHAR2(8),    --�x�������i�����E�����E�T�C�g�j
        bank_num                VARCHAR2(4),    --�U�����s�R�[�h
        bank_nm                 VARCHAR2(50),   --�U�����s����
        bank_nm_alt             VARCHAR2(30),   --�U�����s�J�i
        bank_branch_num         VARCHAR2(3),    --�U�����s�x�X�R�[�h
        bank_branch_nm          VARCHAR2(50),   --�U�����s�x�X����
        bank_branch_nm_alt      VARCHAR2(30),   --�U�����s�x�X�J�i
        bank_account_type       VARCHAR2(1),    --�U����a����ʌ������
        bank_account_type_nm    VARCHAR2(30),   --�U����a����ʖ���
        bank_account_num        VARCHAR2(30),   --��s�����ԍ�
        account_holder_nm_alt   VARCHAR2(50)    --�U����������`�l���J�i
-- Ver1.5 Add Start
       ,vendor_name_alt             VARCHAR2(320)  --�d���於��
       ,vendor_type_lookup_code     VARCHAR2(30)   --�d��������
       ,vendor_type_name            VARCHAR2(80)   --�d�������ߖ�
       ,pay_group_lookup_code       VARCHAR2(25)   --�x����ٰ��
       ,end_date_active             VARCHAR2(8)    --������(ͯ��)
       ,inactive_date               VARCHAR2(8)    --������(���)
       ,address_line2               VARCHAR2(100)  --���ݒn�Q
       ,address_line3               VARCHAR2(100)  --���ݒn�R
       ,area_code                   VARCHAR2(10)   --�s�O�ǔ�
       ,phone                       VARCHAR2(15)   --�d�b�ԍ�
       ,pay_description             VARCHAR2(80)   --�x��������
       ,bank_charge_bearer          VARCHAR2(1)    --�U���萔�����S��
       ,bank_charge_bearer_name     VARCHAR2(80)   --�U���萔�����S�Җ�(�W�����)
       ,bank_charge_bearer_name_bm  VARCHAR2(80)   --�U���萔�����S�Җ�(BM�p)
       ,vendor_formal_name          VARCHAR2(90)   --�d���搳������
       ,bm_payment_kbn              VARCHAR2(1)    --BM�x���敪
       ,bm_payment_kbn_name         VARCHAR2(80)   --BM�x���敪��
       ,inquiry_base_code           VARCHAR2(4)    --�⍇���S�����_�R�[�h
       ,bm_tax_kbn                  VARCHAR2(1)    --BM�ŋ敪
       ,bm_tax_kbn_name             VARCHAR2(80)   --BM�ŋ敪��
       ,vendor_site_e_mail          VARCHAR2(150)  --�d���滲�EҰٱ��ڽ
       ,invoice_t                   VARCHAR2(1)    --�K�i���������s���Ǝғo�^
       ,invoice_t_no                VARCHAR2(13)   --�ېŎ��ƎҔԍ�
       ,tax_calc_type               VARCHAR2(1)    --�Ōv�Z�敪
       ,tax_calc_type_name          VARCHAR2(80)   --�Ōv�Z�敪��
       ,creation_date               VARCHAR2(14)   --�쐬��
       ,created_by                  VARCHAR2(20)   --�쐬��
       ,last_update_date            VARCHAR2(14)   --�ŏI�X�V��
       ,last_updated_by             VARCHAR2(20)   --�ŏI�X�V��
-- Ver1.5 Add End
  );
--
  -- �d����}�X�^�����i�[����e�[�u���^�̒�`
  TYPE csv_out_tbl IS TABLE OF csv_out_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_directory      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C���p�X��
  gv_file_name      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C����
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gv_csv_file       VARCHAR2(5000);        -- �o�͏��
  gt_csv_out_tbl    csv_out_tbl;           -- �����z��̒�`
  gc_del_flg        CHAR(1) := ' ';        -- CSV�폜�t���O('1':�폜)
--
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
    lv_file_chk   BOOLEAN;   --���݃`�F�b�N����
    lv_file_size  NUMBER;    --�t�@�C���T�C�Y
    lv_block_size NUMBER;   --�u���b�N�T�C�Y
    -- *** ���[�J���ϐ� ***
    lc_vender_num  CHAR(9) := NULL; -- �G���[�d����ԍ�
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
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --���̓p�����[�^�Ȃ����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    -- �d����}�X�^�A�g�pCSV�t�@�C���o�͐�擾
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_directory IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_dir_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �d����}�X�^�A�g�pCSV�t�@�C�����擾
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_fil_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --IF�t�@�C�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_file_name
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_file_name
                );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- �t�@�C�����ݎ��G���[
    IF (lv_file_chk = TRUE) THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_csv_file_err
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �d����T�C�g�}�X�^�O���`�F�b�N
    -- ===============================
--
    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   po_vendor_sites_all pvs     --�d����T�C�g�}�X�^
      WHERE  ROWNUM = 1;
    EXCEPTION
      -- �f�[�^�Ȃ��̏ꍇ�G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--Ver1.1 2009/03/09 �d����̋�s�����o�^�`�F�b�N���폜
    -- ===============================
    -- �d����̋�s�����o�^�`�F�b�N
    -- ===============================
--
--    --�d�M�x���̎d����ɂ͕K����s������ݒ�
--    BEGIN
--      SELECT SUBSTRB(pv.segment1,1,9)
--      INTO   lc_vender_num
--      FROM   po_vendors pv,                  --�d����}�X�^
--             ap_bank_account_uses_all abau,  --��s�����g�p���}�X�^
--             po_vendor_sites_all pvs         --�d����T�C�g�}�X�^
--      WHERE  pvs.payment_method_lookup_code = cc_payment_eft
--      AND    pvs.vendor_id = abau.vendor_id(+)
--      AND    pvs.vendor_site_id = abau.vendor_site_id(+)
--      AND    (abau.vendor_site_id IS NULL OR abau.vendor_id IS NULL)
--      AND    pv.vendor_id = pvs.vendor_id
--      AND    ROWNUM = 1;
--
--    EXCEPTION
--      -- �f�[�^�Ȃ��̏ꍇ�p��
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--
--    -- �t�@�C�����ݎ��G���[
--    IF (lc_vender_num IS NOT NULL) then
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_short_name
--                  ,iv_name         => cv_bank_account_err
--                  ,iv_token_name1  => cv_tkn_ng_code
--                  ,iv_token_value1 => lc_vender_num
--                 );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--
--End1.1
    -- ===============================
    -- CSV�t�@�C���I�[�v������
    -- ===============================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                      gv_directory    -- �o�͐�
                     ,gv_file_name    -- CSV�t�@�C����
                     ,cc_output       -- �o�̓X�e�[�^�X
                     -- Ver1.5 Add Start
                     ,5000            -- max_linesize
                     -- Ver1.5 Add End
                    );
    EXCEPTION
      -- �t�@�C���p�X�s���G���[
      WHEN UTL_FILE.INVALID_PATH THEN
        gn_target_cnt := 0;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_pass_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Description      : CSV�t�@�C���o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================0
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
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
    lv_sep_com      CONSTANT VARCHAR2(1)  := ',';     -- �J���}
    lv_char_dq      CONSTANT VARCHAR2(1)  := '"';     -- �_�u���N�H�[�e�[�V����
--
    -- *** ���[�J���ϐ� ***
    lc_last_update   CHAR(14); -- �X�V���t(YYYYMMDDHH24MISS)
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
    lc_last_update := TO_CHAR(cd_sysdate, 'YYYYMMDDHH24MISS');
--
--
    <<gt_csv_out_tbl_loop>>
    FOR out_cnt IN gt_csv_out_tbl.FIRST .. gt_csv_out_tbl.LAST LOOP
--
      gv_csv_file   := lv_char_dq || cc_itoen || lv_char_dq        -- ��ЃR�[�h�i�Œ�l:001)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vender_num) || lv_char_dq  -- �d����ԍ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_site_code) || lv_char_dq  -- �d����T�C�g�R�[�h
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_nm) || lv_char_dq  -- �d���於��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).zip) || lv_char_dq  -- ���ݒn�F�X�֔ԍ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).state) || lv_char_dq  -- ���ݒn�F�s���{��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).city) || lv_char_dq  -- ���ݒn�F�S�s��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).address1) || lv_char_dq  -- ���ݒn�F�Z���P
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).pay_nm) || lv_char_dq  -- �x�������i�����E�����E�T�C�g�j
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_num) || lv_char_dq  -- �U�����s�R�[�h
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_nm) || lv_char_dq  -- �U�����s����
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_nm_alt) || lv_char_dq  -- �U�����s�J�i
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_num) || lv_char_dq  -- �U�����s�x�X�R�[�h
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_nm) || lv_char_dq  -- �U�����s�x�X����
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_nm_alt) || lv_char_dq  -- �U�����s�x�X�J�i
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_type) || lv_char_dq  -- �U����a����ʌ������
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_type_nm) || lv_char_dq  -- �U����a����ʖ���
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_num) || lv_char_dq  -- ��s�����ԍ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).account_holder_nm_alt) || lv_char_dq  -- �U����������`�l���J�i
-- Ver1.5 Add Start
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_name_alt) || lv_char_dq             --�d���於��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_type_lookup_code) || lv_char_dq     --�d��������
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_type_name) || lv_char_dq            --�d�������ߖ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).pay_group_lookup_code) || lv_char_dq       --�x����ٰ��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).end_date_active) || lv_char_dq             --������(ͯ��)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).inactive_date) || lv_char_dq               --������(���)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).address_line2) || lv_char_dq               --���ݒn�Q
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).address_line3) || lv_char_dq               --���ݒn�R
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).area_code) || lv_char_dq                   --�s�O�ǔ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).phone) || lv_char_dq                       --�d�b�ԍ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).pay_description) || lv_char_dq             --�x��������
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_charge_bearer) || lv_char_dq          --�U���萔�����S��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_charge_bearer_name) || lv_char_dq     --�U���萔�����S�Җ�(�W�����)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_charge_bearer_name_bm) || lv_char_dq  --�U���萔�����S�Җ�(BM�p)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_formal_name) || lv_char_dq          --�d���搳������
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bm_payment_kbn) || lv_char_dq              --BM�x���敪
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bm_payment_kbn_name) || lv_char_dq         --BM�x���敪��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).inquiry_base_code) || lv_char_dq           --�⍇���S�����_�R�[�h
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bm_tax_kbn) || lv_char_dq                  --BM�ŋ敪
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bm_tax_kbn_name) || lv_char_dq             --BM�ŋ敪��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_site_e_mail) || lv_char_dq          --�d���滲�EҰٱ��ڽ
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).invoice_t) || lv_char_dq                   --�K�i���������s���Ǝғo�^
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).invoice_t_no) || lv_char_dq                --�ېŎ��ƎҔԍ�
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).tax_calc_type) || lv_char_dq               --�Ōv�Z�敪
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).tax_calc_type_name) || lv_char_dq          --�Ōv�Z�敪��
        || lv_sep_com || gt_csv_out_tbl(out_cnt).creation_date                                                  --�쐬��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).created_by) || lv_char_dq                  --�쐬��
        || lv_sep_com || gt_csv_out_tbl(out_cnt).last_update_date                                               --�ŏI�X�V��
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).last_updated_by) || lv_char_dq             --�ŏI�X�V��
-- Ver1.5 Add End
        || lv_sep_com || lc_last_update;                        -- �ŏI�X�V����
--
      BEGIN
      -- CSV�t�@�C���֏o��
          UTL_FILE.PUT_LINE(gf_file_hand,gv_csv_file);
--
      EXCEPTION
        WHEN UTL_FILE.INVALID_OPERATION THEN       -- �t�@�C���A�N�Z�X�����G���[
          -- �G���[����
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_file_priv_err
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN UTL_FILE.WRITE_ERROR THEN   -- CSV�f�[�^�o�̓G���[
          -- �G���[����
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_csv_data_err
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_vender_num
                      ,iv_token_name2  => cv_tkn_ng_data
                      ,iv_token_value2 => gt_csv_out_tbl(out_cnt).vender_num
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- ���팏��
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP gt_csv_out_tblloop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
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
  END output_csv;
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
    -- �d����}�X�^�e�[�u���擾�J�[�\��
    CURSOR vendor_cur
    IS
      SELECT SUBSTRB(pv.segment1,1,9)           vender_num,         --�d����ԍ�
-- Ver1.2 Mod 2009/05/13 T1_0978�Ή� �d����T�C�g�R�[�h�͔��p�݂̂̂��ߎd����T�C�gID��A�g����悤�C��
--             SUBSTRB(pvs.vendor_site_code,1,9)  vendor_site_code,   --�d����T�C�g�R�[�h
             TO_CHAR( pvs.vendor_site_id )      vendor_site_code,   --�d����T�C�g�R�[�h(�d����T�C�gID)
-- End
-- Ver1.3 Mod 2009/12/04 E_�{�ғ�_00307�Ή�
--             SUBSTRB(pv.vendor_name,1,100)      vendor_nm,          --�d���於
             SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(pv.vendor_name),1,100)      vendor_nm,          --�d���於
-- End
             DECODE(SUBSTRB(pvs.zip,4,1), '-', SUBSTRB(pvs.zip,1,3)||SUBSTRB(pvs.zip,5,4), SUBSTRB(pvs.zip,1,7))
                                                zip,                --�X�֔ԍ�
             SUBSTRB(pvs.state,1,100)           state,              --�s���{��
             SUBSTRB(pvs.city,1,50)             city,               --�S�s��
             SUBSTRB(pvs.address_line1,1,100)   address1,           --���ݒn�P
             SUBSTRB(att.name,1,8)              pay_nm,             --�x������
             SUBSTRB(abb.bank_number,1,4)       bank_num,           --��s�ԍ�
             SUBSTRB(abb.bank_name,1,50)        bank_nm,            --��s��
             SUBSTRB(abb.bank_name_alt,1,30)    bank_nm_alt,        --��s���J�i
             SUBSTRB(abb.bank_num,1,3)          bank_branch_num,    --��s�x�X�ԍ�
             SUBSTRB(abb.bank_branch_name,1,50) bank_branch_nm,     --��s�x�X��
             SUBSTRB(abb.bank_branch_name_alt,1,30)
                                                bank_branch_nm_alt, --��s�x�X�J�i
             SUBSTRB(aba.bank_account_type,1,1) bank_account_type,  --�������
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 modify start by Y.Kuboshima
--             DECODE(aba.bank_account_type,'1','���ʗa��','2','�����a��',NULL)
             SUBSTRB(koza.meaning, 1, 30)
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 modify end by Y.Kuboshima
                                                bank_account_type_nm, --�a����ʖ���
             SUBSTRB(aba.bank_account_num,1,30) bank_account_num,   --��s�����ԍ�
             SUBSTRB(aba.account_holder_name_alt,1,50)
                                                account_holder_nm_alt --�������`�l���J�i
-- Ver1.5 Add Start
            ,pv.vendor_name_alt                 vendor_name_alt             --�d���於��
            ,pv.vendor_type_lookup_code         vendor_type_lookup_code     --�d��������
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_vendor_type
              AND    flvv.lookup_code = pv.vendor_type_lookup_code)
                                                vendor_type_name            --�d�������ߖ�
            ,pv.pay_group_lookup_code           pay_group_lookup_code       --�x����ٰ��
            ,TO_CHAR(pv.end_date_active,'YYYYMMDD') 
                                                end_date_active             --������(ͯ��)
            ,TO_CHAR(pvs.inactive_date,'YYYYMMDD') 
                                                inactive_date               --������(���)
            ,SUBSTRB(pvs.address_line2,1,100)   address_line2               --���ݒn�Q
            ,SUBSTRB(pvs.address_line3,1,100)   address_line3               --���ݒn�R
            ,pvs.area_code                      area_code                   --�s�O�ǔ�
            ,pvs.phone                          phone                       --�d�b�ԍ�
            ,SUBSTRB(att.description,1,80)      pay_description             --�x��������
            ,pvs.bank_charge_bearer             bank_charge_bearer          --�U���萔�����S��
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bank_charge_bearer
              AND    flvv.lookup_code = pvs.bank_charge_bearer)
                                                bank_charge_bearer_name     --�U���萔�����S�Җ�(�W�����)
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_sp_tran_fee_type
              AND    flvv.lookup_code = pvs.bank_charge_bearer)
                                                bank_charge_bearer_name_bm  --�U���萔�����S�Җ�(BM�p)
            ,SUBSTRB(pvs.ATTRIBUTE1,1,90)       vendor_formal_name          --�d���搳������
            ,SUBSTRB(pvs.attribute4,1,1)        bm_payment_kbn              --BM�x���敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bm_payment_kbn
              AND    flvv.lookup_code = pvs.attribute4)
                                                bm_payment_kbn_name         --BM�x���敪��
            ,SUBSTRB(pvs.attribute5,1,4)        inquiry_base_code           --�⍇���S�����_�R�[�h
            ,SUBSTRB(pvs.attribute6,1,1)        bm_tax_kbn                  --BM�ŋ敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bm_tax_kbn
              AND    flvv.lookup_code = pvs.attribute6)
                                                bm_tax_kbn_name             --BM�ŋ敪��
            ,pvs.attribute7                     vendor_site_e_mail          --�d���滲�EҰٱ��ڽ
            ,SUBSTRB(pvs.attribute8,1,1)        invoice_t                   --�K�i���������s���Ǝғo�^
            ,SUBSTRB(pvs.attribute9,1,13)       invoice_t_no                --�ېŎ��ƎҔԍ�
            ,SUBSTRB(pvs.attribute10,1,1)       tax_calc_type               --�Ōv�Z�敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_invoice_tax_div_bm
              AND    flvv.lookup_code = pvs.attribute10)
                                                tax_calc_type_name          --�Ōv�Z�敪��
            ,TO_CHAR(pv.creation_date, 'YYYYMMDDHH24MISS')
                                                creation_date               --�쐬��
            ,(SELECT SUBSTRB(fu.user_name,1,20)
              FROM   fnd_user fu
              WHERE  fu.user_id = pv.created_by)
                                                created_by                  --�쐬��
            ,TO_CHAR(pvs.last_update_date, 'YYYYMMDDHH24MISS')
                                                last_update_date            --�ŏI�X�V��
            ,(SELECT SUBSTRB(fu.user_name,1,20)
              FROM   fnd_user fu
              WHERE  fu.user_id = pvs.last_updated_by)
                                                last_updated_by             --�ŏI�X�V��
-- Ver1.5 Add End
      FROM   ap_bank_accounts_all aba,   --��s�����}�X�^
             ap_bank_branches abb,       --��s�x�X�}�X�^
             ap_terms att,               --�x�������}�X�^
             po_vendors pv,              --�d����}�X�^
-- Ver1.2 Mod 2009/05/13 T1_0978�Ή� �c��OU�̂ݑΏۂƂ���
--             po_vendor_sites_all pvs     --�d����T�C�g�}�X�^
             po_vendor_sites  pvs        --�d����T�C�g�}�X�^
-- End
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add start by Y.Kuboshima
            ,(SELECT ffvv.lookup_code
                    ,ffvv.meaning
              FROM   fnd_lookup_values_vl ffvv   --�Q�ƃ^�C�v�}�X�^
              WHERE  ffvv.lookup_type  = cv_koza_type
                AND  ffvv.enabled_flag = 'Y'
             ) koza                      --�������
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add end by Y.Kuboshima
      WHERE  pv.vendor_id = pvs.vendor_id
      AND    EXISTS
             (SELECT 'x'
              FROM   ap_bank_account_uses_all abau  --��s�����g�p���}�X�^
              WHERE  abau.vendor_id = pvs.vendor_id
              AND    abau.vendor_site_id = pvs.vendor_site_id
              AND    abau.primary_flag = 'Y'
              AND    abau.external_bank_account_id = aba.bank_account_id)
      AND    pvs.terms_id = att.term_id(+)
      AND    aba.bank_branch_id = abb.bank_branch_id(+)
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add start by Y.Kuboshima
      AND    aba.bank_account_type = koza.lookup_code(+)
-- 2010/03/08 Ver1.4 E_�{�ғ�_01820 add end by Y.Kuboshima
      UNION ALL
      SELECT SUBSTRB(pv.segment1,1,9)           vender_num,         --�d����ԍ�
-- Ver1.2 Mod 2009/05/13 T1_0978�Ή� �d����T�C�g�R�[�h�͔��p�݂̂̂��ߎd����T�C�gID��A�g����悤�C��
--             SUBSTRB(pvs.vendor_site_code,1,9)  vendor_site_code,   --�d����T�C�g�R�[�h
             TO_CHAR( pvs.vendor_site_id )      vendor_site_code,   --�d����T�C�g�R�[�h(�d����T�C�gID)
-- End
-- Ver1.3 Mod 2009/12/04 E_�{�ғ�_00307�Ή�
--             SUBSTRB(pv.vendor_name,1,100)      vendor_nm,          --�d���於
             SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(pv.vendor_name),1,100)      vendor_nm,          --�d���於
-- End
             DECODE(SUBSTRB(pvs.zip,4,1), '-', SUBSTRB(pvs.zip,1,3)||SUBSTRB(pvs.zip,5,4), SUBSTRB(pvs.zip,1,7))
                                                zip,                --�X�֔ԍ�
             SUBSTRB(pvs.state,1,100)           state,              --�s���{��
             SUBSTRB(pvs.city,1,50)             city,               --�S�s��
             SUBSTRB(pvs.address_line1,1,100)   address1,           --���ݒn�P
             SUBSTRB(att.name,1,8)              pay_nm,             --�x������
             NULL                               bank_num,           --��s�ԍ�
             NULL                               bank_nm,            --��s��
             NULL                               bank_nm_alt,        --��s���J�i
             NULL                               bank_branch_num,    --��s�x�X�ԍ�
             NULL                               bank_branch_nm,     --��s�x�X��
             NULL                               bank_branch_nm_alt, --��s�x�X�J�i
             NULL                               bank_account_type,  --�������
             NULL                               bank_account_type_nm, --�a����ʖ���
             NULL                               bank_account_num,   --��s�����ԍ�
             NULL                               account_holder_nm_alt --�������`�l���J�i
-- Ver1.5 Add Start
            ,pv.vendor_name_alt                 vendor_name_alt             --�d���於��
            ,pv.vendor_type_lookup_code         vendor_type_lookup_code     --�d��������
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_vendor_type
              AND    flvv.lookup_code = pv.vendor_type_lookup_code)
                                                vendor_type_name            --�d�������ߖ�
            ,pv.pay_group_lookup_code           pay_group_lookup_code       --�x����ٰ��
            ,TO_CHAR(pv.end_date_active,'YYYYMMDD') 
                                                end_date_active             --������(ͯ��)
            ,TO_CHAR(pvs.inactive_date,'YYYYMMDD') 
                                                inactive_date               --������(���)
            ,SUBSTRB(pvs.address_line2,1,100)   address_line2               --���ݒn�Q
            ,SUBSTRB(pvs.address_line3,1,100)   address_line3               --���ݒn�R
            ,pvs.area_code                      area_code                   --�s�O�ǔ�
            ,pvs.phone                          phone                       --�d�b�ԍ�
            ,SUBSTRB(att.description,1,80)      pay_description             --�x��������
            ,pvs.bank_charge_bearer             bank_charge_bearer          --�U���萔�����S��
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bank_charge_bearer
              AND    flvv.lookup_code = pvs.bank_charge_bearer)
                                                bank_charge_bearer_name     --�U���萔�����S�Җ�(�W�����)
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_sp_tran_fee_type
              AND    flvv.lookup_code = pvs.bank_charge_bearer)
                                                bank_charge_bearer_name_bm  --�U���萔�����S�Җ�(BM�p)
            ,SUBSTRB(pvs.ATTRIBUTE1,1,90)       vendor_formal_name          --�d���搳������
            ,SUBSTRB(pvs.attribute4,1,1)        bm_payment_kbn              --BM�x���敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bm_payment_kbn
              AND    flvv.lookup_code = pvs.attribute4)
                                                bm_payment_kbn_name         --BM�x���敪��
            ,SUBSTRB(pvs.attribute5,1,4)        inquiry_base_code           --�⍇���S�����_�R�[�h
            ,SUBSTRB(pvs.attribute6,1,1)        bm_tax_kbn                  --BM�ŋ敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_bm_tax_kbn
              AND    flvv.lookup_code = pvs.attribute6)
                                                bm_tax_kbn_name             --BM�ŋ敪��
            ,pvs.attribute7                     vendor_site_e_mail          --�d���滲�EҰٱ��ڽ
            ,SUBSTRB(pvs.attribute8,1,1)        invoice_t                   --�K�i���������s���Ǝғo�^
            ,SUBSTRB(pvs.attribute9,1,13)       invoice_t_no                --�ېŎ��ƎҔԍ�
            ,SUBSTRB(pvs.attribute10,1,1)       tax_calc_type               --�Ōv�Z�敪
            ,(SELECT flvv.meaning
              FROM   fnd_lookup_values_vl flvv
              WHERE  flvv.lookup_type = cv_invoice_tax_div_bm
              AND    flvv.lookup_code = pvs.attribute10)
                                                tax_calc_type_name          --�Ōv�Z�敪��
            ,TO_CHAR(pv.creation_date, 'YYYYMMDDHH24MISS')
                                                creation_date               --�쐬��
            ,(SELECT SUBSTRB(fu.user_name,1,20)
              FROM   fnd_user fu
              WHERE  fu.user_id = pv.created_by)
                                                created_by                  --�쐬��
            ,TO_CHAR(pvs.last_update_date, 'YYYYMMDDHH24MISS')
                                                last_update_date            --�ŏI�X�V��
            ,(SELECT SUBSTRB(fu.user_name,1,20)
              FROM   fnd_user fu
              WHERE  fu.user_id = pvs.last_updated_by)
                                                last_updated_by             --�ŏI�X�V��
-- Ver1.5 Add End
      FROM   ap_terms att,               --�x�������}�X�^
             po_vendors pv,              --�d����}�X�^
-- Ver1.2 Mod 2009/05/13 T1_0978�Ή� �c��OU�̂ݑΏۂƂ���
--             po_vendor_sites_all pvs     --�d����T�C�g�}�X�^
             po_vendor_sites pvs         --�d����T�C�g�}�X�^
-- End
      WHERE  pv.vendor_id = pvs.vendor_id
      AND    NOT EXISTS
             (SELECT 'x'
              FROM   ap_bank_account_uses_all abau  --��s�����g�p���}�X�^
              WHERE  abau.vendor_id = pvs.vendor_id
              AND    abau.vendor_site_id = pvs.vendor_site_id
              AND    abau.primary_flag = 'Y')
      AND    pvs.terms_id = att.term_id(+)
      ORDER  BY  vender_num;
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
    gc_del_flg    := ' ';
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
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- �d����}�X�^�e�[�u�����擾(A-2)
    -- ====================================
    OPEN vendor_cur;
--
    <<vendor_loop>>
    LOOP
      FETCH vendor_cur BULK COLLECT INTO gt_csv_out_tbl;
        EXIT WHEN vendor_cur%NOTFOUND;
    END LOOP vendor_loop;
--
    CLOSE vendor_cur;
--
    gn_target_cnt := gt_csv_out_tbl.COUNT;  -- ���������J�E���g�A�b�v
--
    -- ===============================
    -- CSV�t�@�C���o�͏���(A-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���������Ȃ��̏ꍇ
    IF (gn_normal_cnt = 0) THEN
      gc_del_flg    := '1';   --CSV�폜
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �I������(A-4)
    -- ===============================
--
    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ���b�Z�[�W�ԍ�(���ʁEIF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
--    cv_skip_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
--    cv_warn_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
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
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --�ُ�G���[���́A���������O���A�G���[�����P���ƌŒ�\��
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_target_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_success_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --�������ł͌x���I���Ȃ�
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --CSV�o�̓f�[�^���O���̏ꍇ�ACSV�t�@�C�����폜����
    IF (gc_del_flg = '1') THEN
       UTL_FILE.FREMOVE(gv_directory,   -- �o�͐�
                        gv_file_name    -- CSV�t�@�C����
      );
    END IF;
--
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
END XXCMM001A01C;
/
