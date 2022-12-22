CREATE OR REPLACE PACKAGE BODY XXCMM_CUST_STS_CHG_CHK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM_CUST_STS_CHK_PKG(body)
 * Description      : �ڋq�X�e�[�^�X���u���~�v�ɕύX����ہA�X�e�[�^�X�ύX���\��������s���܂��B
 * MD.050           : MD050_CMM_003_A11_�ڋq�X�e�[�^�X�ύX�`�F�b�N
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  item_ins               ������񑶍݃`�F�b�N(A-2)
 *  cust_base_chk          ��݌ɐ��E�ޑK��z�`�F�b�N����(A-3)
 *  cust_balance_chk       ���|�c���`�F�b�N����(A-4)
 *  cust_tran_chk          ����������݃`�F�b�N����(A-5)
 *  bm_contract_err_chk    �̎�����G���[�`�F�b�N(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   ���s�t�@�C���o�^�v���V�[�W��(A-5 �I������)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   Takuya.Kaihara   �V�K�쐬
 *  2009/02/19    1.1   Takuya.Kaihara   �����}�X�^.�폜�t���O�̏C��
 *  2009/09/11    1.2   Yutaka.Kuboshima ��Q0001350 �Ƒ�(������)�̕K�{�`�F�b�N�̍폜
 *  2010/02/15    1.3   Yutaka.Kuboshima ��QE_�{�ғ�_01528 PT�Ή��F�c�����`�F�b�NSQL
 *  2010/08/04    1.4   Shigeto.Niki     ��QE_�{�ғ�_04245 �ƑԊ֌W�Ȃ����|�c���`�F�b�N
 *  2011/03/07    1.5   Masato.Hirose    ��QE_�{�ғ�_02443 ��������̑��݃`�F�b�N�ǉ�
 *  2015/11/17    1.6   Shigeto.Niki     ��QE_�{�ғ�_13403 PT�Ή��F�c�����`�F�b�NSQL
 *  2020/03/24    1.7   Nobuo.Koyama     ��QE_�{�ғ�_16273 BM�c���`�F�b�N�ǉ��Ή�
 *  2022/12/15    1.8   Manabu.Akachi    ��QE_�{�ғ�_18902 �̎�����G���[�`�F�b�N�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
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
  init_err_expt             EXCEPTION;     -- ���������G���[
  ins_err_expt              EXCEPTION;     -- �L���������~�`�F�b�N�G���[
  stop_err_expt             EXCEPTION;     -- ���~�`�F�b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCMM_CUST_STS_CHG_CHK_PKG';    -- �p�b�P�[�W��
--
  cv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCMM';                         -- �A�h�I���F���ʁE�}�X�^
--
  --�G���[���b�Z�[�W
  cv_msg_xxcmm_10312   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10312';              -- ���~�`�F�b�N�G���[
  cv_msg_xxcmm_10313   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10313';              -- �L���������~�`�F�b�N�G���[
  cv_msg_xxcmm_10314   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10314';              -- ���~�`�F�b�N�N���G���[
  cv_msg_xxcmm_10315   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10315';              -- �c�����~�`�F�b�N�N���G���[
-- 2020/03/24 Ver1.7 add start
  cv_msg_xxcmm_10500   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10500';              -- BM�x���\��z�`�F�b�N�G���[
-- 2020/03/24 Ver1.7 add end
-- Ver1.8 add Start
  cv_msg_xxcmm_10506   CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10506';              -- �̎�����G���[�`�F�b�N�G���[
-- Ver1.8 add End
-- 2011/03/07 Ver1.5 add start
  cv_msg_xxcmm_00018   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';              -- �Ɩ����t�擾�G���[
  cv_msg_xxcmm_00356   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00356';              -- ����������݃`�F�b�N�G���[
-- 2011/03/07 Ver1.5 add end
  --�g�[�N��
  cv_cnst_tkn_citem    CONSTANT VARCHAR2(15)  := 'CHECK_ITEM';                    -- �g�[�N��(�`�F�b�N���ږ�)
  cv_cnst_tkn_tnum     CONSTANT VARCHAR2(15)  := 'TOTAL_NUM';                     -- �g�[�N��(�T�}���[����)
  cv_cnst_tkn_cid      CONSTANT VARCHAR2(15)  := 'CUST_ID';                       -- �g�[�N��(�ڋqID)
  cv_cnst_tkn_gsyo     CONSTANT VARCHAR2(15)  := 'GTAI_SYO';                      -- �g�[�N��(�Ƒԕ��ށi�����ށj)
-- 2011/03/07 Ver1.5 add start
  cv_cnst_tkn_ccd      CONSTANT VARCHAR2(15)  := 'CUST_CODE';                     -- �ڋq�R�[�h�g�[�N��
-- 2011/03/07 Ver1.5 add end
--
  cv_sts_check_ok      CONSTANT VARCHAR2(1)   := '1';                             -- �`�F�b�N�X�e�[�^�X(OK)
  cv_sts_check_ng      CONSTANT VARCHAR2(1)   := '0';                             -- �`�F�b�N�X�e�[�^�X(NG)
  cv_cust_cls_cd_cu    CONSTANT VARCHAR2(2)   := '10';                            --�ڋq�敪(�ڋq)
  cv_cust_cls_cd_uc    CONSTANT VARCHAR2(2)   := '12';                            --�ڋq�敪(��l�ڋq)
  cv_cust_cls_cd_uk    CONSTANT VARCHAR2(2)   := '14';                            --�ڋq�敪(���|���Ǘ���ڋq)
  cv_site_use_cd_bt    CONSTANT VARCHAR2(20)  := 'BILL_TO';                       --�g�p�ړI(������)
  cv_site_use_cd_st    CONSTANT VARCHAR2(20)  := 'SHIP_TO';                       --�g�p�ړI(�o�א�)
  cv_gtal_syo_24       CONSTANT VARCHAR2(2)   := '24';                            --�Ƒԕ���(������)(�t���T�[�r�X(����)VD)
  cv_gtal_syo_25       CONSTANT VARCHAR2(2)   := '25';                            --�Ƒԕ���(������)(�t���T�[�r�XVD)
  cv_gtal_syo_27       CONSTANT VARCHAR2(2)   := '27';                            --�Ƒԕ���(������)(����VD)
  cv_status_op         CONSTANT VARCHAR2(2)   := 'OP';                            --�X�e�[�^�X(�I�[�v��)
  cv_status_cl         CONSTANT VARCHAR2(2)   := 'CL';                            --�X�e�[�^�X(�N���[�Y)
--  cn_ins_sts_cd        CONSTANT NUMBER        := 6;                               --�C���X�^���X�X�e�[�^�XID(�����폜��)
  cv_ins_sts_cd        CONSTANT VARCHAR2(20)  := '�����폜��';                    --�C���X�^���X�X�e�[�^�XID(�����폜��)
-- 2011/03/07 Ver1.5 add start
  cv_gtal_dai_vd       CONSTANT VARCHAR2(2)   := '05';                            --�Ƒԕ���(�啪��)(VD)
  cv_date_mm           CONSTANT VARCHAR2(2)   := 'MM';                            --�t�H�[�}�b�g('MM')
-- 2011/03/07 Ver1.5 add end
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- 2011/03/07 Ver1.5 add start
  gd_process_date      DATE;                                                      -- �Ɩ����t
-- 2011/03/07 Ver1.5 add end
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --�ڋqID�E�Ƒԕ���(������)NULL�`�F�b�N
-- 2009/09/11 Ver1.2 modify start by Y.Kuboshima
--    IF ( in_cust_id IS NULL OR iv_gtai_syo IS NULL ) THEN
    IF ( in_cust_id IS NULL ) THEN
-- 2009/09/11 Ver1.2 modify end by Y.Kuboshima
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10314,
                                            cv_cnst_tkn_cid,
                                            in_cust_id,
                                            cv_cnst_tkn_gsyo,
                                            iv_gtai_syo);
      RAISE init_err_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 add start
    -- �Ɩ����t�擾
    gd_process_date  := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t���擾�ł��Ȃ�������G���[
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cnst_msg_kbn
                    ,iv_name         => cv_msg_xxcmm_00018);
      RAISE init_err_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 add end
  EXCEPTION
    --*** ���������G���[ ***
    WHEN init_err_expt THEN
      ov_check_status := cv_sts_check_ng;             --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                   --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : item_ins
   * Description      : ������񑶍݃`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE item_ins(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_ins'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_errmsg      VARCHAR2(5000);                      -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_item_count  NUMBER;                              --�Ώی���
--
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    ln_item_count := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ������񑶍݃`�F�b�N
--    SELECT COUNT( cii.instance_id )
--    INTO   ln_item_count
--    FROM   csi_item_instances cii,
--           hz_cust_accounts hca
--    WHERE  hca.cust_account_id = in_cust_id
--    AND    cii.owner_party_account_id = hca.cust_account_id
--    AND    cii.instance_status_id <> cn_ins_sts_cd
--    AND    ROWNUM = 1;
--
    -- ������񑶍݃`�F�b�N
    SELECT COUNT( cii.instance_id )
    INTO   ln_item_count
    FROM   csi_item_instances cii,
           hz_cust_accounts   hca
    WHERE  hca.cust_account_id = in_cust_id
    AND    cii.owner_party_account_id = hca.cust_account_id
    AND    (NOT EXISTS (SELECT 1 
                       FROM    csi_instance_statuses  cis
                       WHERE   cis.name = cv_ins_sts_cd
                       AND     cii.instance_status_id = cis.instance_status_id ))
    AND    ROWNUM = 1;
--
    --������񑶍݂����݂��邩
    IF ( ln_item_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10313);
      RAISE ins_err_expt;
    END IF;
--
  EXCEPTION
    --*** �L���������~�`�F�b�N�G���[ ***
    WHEN ins_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END item_ins;
--
  /**********************************************************************************
   * Procedure Name   : cust_base_chk
   * Description      : ��݌ɐ��E�ޑK��z�`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE cust_base_chk(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_base_chk'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_tkn_inv    CONSTANT VARCHAR2(50) := '��݌ɐ�';             --��݌ɐ�
    cv_tkn_chg    CONSTANT VARCHAR2(50) := '�ޑK��z';             --�ޑK��z
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg    VARCHAR2(5000);                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_inv_total NUMBER;                                  --��݌ɐ����v
    ln_chg_chk   NUMBER;                                  --�ޑK��z���v
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    ln_inv_total := 0;
    ln_chg_chk := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --��݌ɐ��`�F�b�N
    SELECT NVL( SUM( NVL( xmvc.inventory_quantity,0 ) ), 0 )
    INTO   ln_inv_total
    FROM   xxcoi_mst_vd_column xmvc
    WHERE  xmvc.customer_id = in_cust_id;
--
    IF ( ln_inv_total <> 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10312,
                                            cv_cnst_tkn_citem,
                                            cv_tkn_inv,
                                            cv_cnst_tkn_tnum,
                                            ln_inv_total);
      RAISE stop_err_expt;
    END IF;
--
    BEGIN
      --�ޑK��z�`�F�b�N
      SELECT NVL( xca.change_amount,0 )
      INTO   ln_chg_chk
      FROM   xxcmm_cust_accounts xca
      WHERE  xca.customer_id = in_cust_id;
    EXCEPTION
      --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
      WHEN NO_DATA_FOUND THEN
        ln_chg_chk := 0;
      WHEN OTHERS THEN
        RAISE;
    END;
--
    IF ( ln_chg_chk <> 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10312,
                                            cv_cnst_tkn_citem,
                                            cv_tkn_chg,
                                            cv_cnst_tkn_tnum,
                                            ln_chg_chk);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** ���~�`�F�b�N�G���[ ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_base_chk;
--
  /**********************************************************************************
   * Procedure Name   : cust_balance_chk
   * Description      : ���|�c���`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE cust_balance_chk(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_balance_chk'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
-- Ver1.6 add start
    -- *** ���[�J���萔 ***
    cv_inv       CONSTANT VARCHAR2(3)    := 'INV';              -- ������
-- Ver1.6 add end
    -- *** ���[�J���ϐ� ***
    lv_errmsg    VARCHAR2(5000);                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_bal_count NUMBER;                                        --�Ώی���
--
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    ln_bal_count := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�c�����`�F�b�N
-- 2010/02/15 Ver1.3 E_�{�ғ�_XXXXX modify start by Yutaka.Kuboshima
--    SELECT COUNT( hca.cust_account_id )
--    INTO   ln_bal_count
--    FROM   hz_cust_accounts hca,
--           hz_cust_site_uses_all hcsu,
--           hz_cust_acct_sites_all hcas,
--           ra_customer_trx_all rct,
--           ar_payment_schedules_all aps
--    WHERE  (hca.customer_class_code IN ( cv_cust_cls_cd_cu, cv_cust_cls_cd_uc )
--    AND    hca.cust_account_id      = in_cust_id
--    AND    hcas.cust_account_id     = hca.cust_account_id
--    AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
--    AND    hcsu.site_use_code       = cv_site_use_cd_st
--    AND    aps.status               = cv_status_op
--    AND    hcsu.bill_to_site_use_id = rct.bill_to_site_use_id
--    AND    rct.customer_trx_id      = aps.customer_trx_id)
--    OR
--           (hca.customer_class_code = cv_cust_cls_cd_uk
--    AND    hca.cust_account_id      = in_cust_id
--    AND    hcas.cust_account_id     = hca.cust_account_id
--    AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
--    AND    hcsu.site_use_code       = cv_site_use_cd_bt
--    AND    aps.status               = cv_status_op
--    AND    hcsu.site_use_id         = rct.bill_to_site_use_id
--    AND    rct.customer_trx_id      = aps.customer_trx_id);
-- Ver1.6 mod start
--    SELECT COUNT( cust_bal.cust_account_id )
--    INTO   ln_bal_count
--    FROM  ( SELECT hca_bill.cust_account_id cust_account_id
--            FROM   hz_cust_accounts         hca_ship
--                  ,hz_cust_site_uses        hcsu_ship  -- �c��OU�̂�
--                  ,hz_cust_acct_sites       hcas_ship  -- �c��OU�̂�
--                  ,hz_cust_accounts         hca_bill
--                  ,hz_cust_site_uses        hcsu_bill  -- �c��OU�̂�
--                  ,hz_cust_acct_sites       hcas_bill  -- �c��OU�̂�
--                  ,ra_customer_trx_all      rct
--                  ,ar_payment_schedules_all aps
--            WHERE  hca_ship.customer_class_code IN ( cv_cust_cls_cd_cu, cv_cust_cls_cd_uc )
--            AND    hca_ship.cust_account_id      = in_cust_id
--            AND    hcas_ship.cust_account_id     = hca_ship.cust_account_id
--            AND    hcsu_ship.cust_acct_site_id   = hcas_ship.cust_acct_site_id
--            AND    hcsu_ship.site_use_code       = cv_site_use_cd_st
--            AND    hcas_bill.cust_account_id     = hca_bill.cust_account_id
--            AND    hcsu_bill.cust_acct_site_id   = hcas_bill.cust_acct_site_id
--            AND    hcsu_bill.site_use_code       = cv_site_use_cd_bt
--            AND    aps.status                    = cv_status_op
--            AND    hcsu_ship.bill_to_site_use_id = hcsu_bill.site_use_id
--            AND    hca_bill.cust_account_id      = rct.bill_to_customer_id
--            AND    rct.customer_trx_id           = aps.customer_trx_id
--            AND    ROWNUM                        = 1
--            UNION ALL
--            SELECT hca.cust_account_id cust_account_id
--            FROM   hz_cust_accounts         hca
--                  ,hz_cust_site_uses        hcsu  -- �c��OU�̂�
--                  ,hz_cust_acct_sites       hcas  -- �c��OU�̂�
--                  ,ra_customer_trx_all      rct
--                  ,ar_payment_schedules_all aps
--            WHERE  hca.customer_class_code  = cv_cust_cls_cd_uk
--            AND    hca.cust_account_id      = in_cust_id
--            AND    hcas.cust_account_id     = hca.cust_account_id
--            AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
--            AND    hcsu.site_use_code       = cv_site_use_cd_bt
--            AND    aps.status               = cv_status_op
--            AND    hca.cust_account_id      = rct.bill_to_customer_id
--            AND    rct.customer_trx_id      = aps.customer_trx_id
--            AND    ROWNUM                   = 1
--          ) cust_bal
--    WHERE  ROWNUM = 1
--    ;
---- 2010/02/15 Ver1.3 E_�{�ғ�_XXXXX modify end by Yutaka.Kuboshima
   BEGIN
     SELECT 1 AS dummy
     INTO   ln_bal_count
     FROM  ( SELECT /*+ LEADING(hca_ship hcas_ship hcsu_ship) */
                    hca_bill.cust_account_id AS cust_account_id
             FROM   hz_cust_accounts         hca_ship
                   ,hz_cust_site_uses        hcsu_ship
                   ,hz_cust_acct_sites       hcas_ship
                   ,hz_cust_accounts         hca_bill
                   ,hz_cust_site_uses        hcsu_bill
                   ,hz_cust_acct_sites       hcas_bill
             WHERE  hca_ship.customer_class_code IN ( cv_cust_cls_cd_cu, cv_cust_cls_cd_uc )
             AND    hca_ship.cust_account_id      = in_cust_id
             AND    hcas_ship.cust_account_id     = hca_ship.cust_account_id
             AND    hcsu_ship.cust_acct_site_id   = hcas_ship.cust_acct_site_id
             AND    hcsu_ship.site_use_code       = cv_site_use_cd_st
             AND    hcas_bill.cust_account_id     = hca_bill.cust_account_id
             AND    hcsu_bill.cust_acct_site_id   = hcas_bill.cust_acct_site_id
             AND    hcsu_bill.site_use_code       = cv_site_use_cd_bt
             AND    hcsu_ship.bill_to_site_use_id = hcsu_bill.site_use_id
             AND    EXISTS ( SELECT /*+ INDEX(aps AR_PAYMENT_SCHEDULES_N6) */
                                    1
                             FROM   ar_payment_schedules_all aps
                             WHERE  aps.customer_id = hca_bill.cust_account_id
                             AND    aps.status      = cv_status_op  --�I�[�v��
                             AND    aps.class       = cv_inv        --������
                             AND    ROWNUM          = 1
                    )
             UNION ALL
             SELECT /*+ LEADING(hca hcas hcsu)
                        INDEX(hcsu HZ_CUST_SITE_USES_N1)
                        INDEX(hcas HZ_CUST_ACCT_SITES_N2)
                    */
                    hca.cust_account_id AS cust_account_id
             FROM   hz_cust_accounts         hca
                   ,hz_cust_site_uses        hcsu
                   ,hz_cust_acct_sites       hcas
             WHERE  hca.customer_class_code  = cv_cust_cls_cd_uk
             AND    hca.cust_account_id      = in_cust_id
             AND    hcas.cust_account_id     = hca.cust_account_id
             AND    hcsu.cust_acct_site_id   = hcas.cust_acct_site_id
             AND    hcsu.site_use_code       = cv_site_use_cd_bt
             AND    EXISTS ( SELECT /*+ INDEX(aps2 AR_PAYMENT_SCHEDULES_N6) */
                                    1
                             FROM   ar_payment_schedules_all aps2
                             WHERE  aps2.customer_id = hca.cust_account_id
                             AND    aps2.status      = cv_status_op  --�I�[�v��
                             AND    aps2.class       = cv_inv        --������
                             AND    ROWNUM           = 1
                    )
           ) cust_bal
     WHERE  ROWNUM = 1
     ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_bal_count := 0;
    END;
-- Ver1.6 mod end
    IF ( ln_bal_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10315);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** �c�����~�`�F�b�N�G���[ ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_balance_chk;
--
-- 2011/03/07 Ver1.5 add start
  /**********************************************************************************
   * Procedure Name   : cust_tran_chk
   * Description      : ����������݃`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE cust_tran_chk(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_tran_chk'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_add_date_vd     CONSTANT NUMBER := -1;  -- �ΏۂƂ��������iVD�j
    cn_add_date_not_vd CONSTANT NUMBER := -2;  -- �ΏۂƂ��������iVD�ȊO�j
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg     VARCHAR2(5000);                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_cust_code  hz_cust_accounts.account_number%TYPE;      -- ���[�J���ϐ��E�ڋq�R�[�h
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    lv_cust_code := NULL;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      -- ����������݃`�F�b�N
      --  �Ƒԕ���(�啪��)  = VD  �� �ŏI����� >= 1�����O�̌�����
      --  �Ƒԕ���(�啪��) <> VD  �� �ŏI����� >= 2�����O�̌�����
      SELECT xca.customer_code AS customer_code  -- �ڋq�R�[�h
      INTO   lv_cust_code
      FROM   xxcmm_cust_accounts         xca   -- �ڋq�ǉ����
            ,xxcos_business_conditions_v xbcv  -- �Ƒԕ��ރr���[
      WHERE  xca.customer_id        = in_cust_id          -- ����ID
      AND    xca.business_low_type  = xbcv.s_lookup_code  -- �Ƒԕ���(������)
      AND    xca.final_tran_date   >= TRUNC(
                                        ADD_MONTHS( gd_process_date  -- �Ɩ����t
                                                  , DECODE( xbcv.d_lookup_code  -- �Ƒԕ���(�啪��)
                                                          , cv_gtal_dai_vd      -- VD('05')
                                                          , cn_add_date_vd      -- VD�́A1�����O�̌����ȓ�(-1)
                                                          , cn_add_date_not_vd  -- VD�ȊO�́A2�����O�̌����ȓ�(-2)
                                                    )
                                        )
                                      , cv_date_mm  -- ���������擾('MM')
                                      )
      ;
    EXCEPTION
      --*** �Ώۃ��R�[�h�Ȃ��G���[ ***
      WHEN NO_DATA_FOUND THEN
        lv_cust_code := NULL;
    END;
--
    -- ������������݂���Β��~NG
    IF ( lv_cust_code IS NOT NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_00356,
                                            cv_cnst_tkn_ccd,
                                            lv_cust_code);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** ���~�`�F�b�N�G���[ ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END cust_tran_chk;
--
-- 2011/03/07 Ver1.5 add end
-- 2020/03/24 Ver1.7 add start
  /**********************************************************************************
   * Procedure Name   : bm_expect_payment_chk
   * Description      : BM�x���\��z�`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE bm_expect_payment_chk(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bm_expect_payment_chk'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg     VARCHAR2(5000);                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_count      NUMBER;
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    ln_count := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- BM�x���\��z�`�F�b�N
    SELECT COUNT(1)  -- ����
     INTO  ln_count
    FROM   xxcok_backmargin_balance    xbb   -- BM�c�����
          ,xxcmm_cust_accounts         xca   -- �ڋq�ǉ����
    WHERE  xca.customer_id             = in_cust_id          -- ����ID
      AND  xca.customer_code           = xbb.cust_code
      AND  xbb.expect_payment_amt_tax <> 0
    ;
--
    --BM�x���\��z���c���Ă���Β��~
    IF ( ln_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10500);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** ���~�`�F�b�N�G���[ ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END bm_expect_payment_chk;
--
-- 2020/03/24 Ver1.7 add end
-- Ver1.8 add Start
  /**********************************************************************************
   * Procedure Name   : bm_contract_err_chk
   * Description      : �̎�����G���[�`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE bm_contract_err_chk(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bm_contract_err_chk'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg     VARCHAR2(5000);                            -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_count      NUMBER;
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    ov_check_status := cv_sts_check_ok;
    --���[�J���ϐ���������
    ln_count := 0;
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �̎�����G���[�`�F�b�N
    SELECT COUNT(1) AS cnt -- ����
     INTO  ln_count
    FROM   xxcok_bm_contract_err       xbce  -- �̎�����G���[�e�[�u��
          ,xxcmm_cust_accounts         xca   -- �ڋq�ǉ����
    WHERE  xca.customer_id             = in_cust_id          -- ����ID
      AND  xca.customer_code           = xbce.cust_code
      AND  xbce.err_kbn  IS NOT NULL                         -- �G���[�敪
    ;
--
    --�̎�����G���[����̏ꍇ���~
    IF ( ln_count > 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                            cv_msg_xxcmm_10506);
      RAISE stop_err_expt;
    END IF;
--
  EXCEPTION
    --*** ���~�`�F�b�N�G���[ ***
    WHEN stop_err_expt THEN
      ov_check_status := cv_sts_check_ng;            --�`�F�b�N�X�e�[�^�X
      ov_err_message  := lv_errmsg;                  --�G���[���b�Z�[�W
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END bm_contract_err_chk;
--
-- Ver1.8 add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_err_message    VARCHAR2(5000);                     --�G���[���b�Z�[�W
    lv_check_status   VARCHAR2(1);                        --�`�F�b�N�X�e�[�^�X
--
  BEGIN
--
    --�`�F�b�N�X�e�[�^�X��������
    lv_check_status := cv_sts_check_ok;
    ov_check_status := cv_sts_check_ok;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <��������>
    -- ===============================
    init(
      in_cust_id      =>  in_cust_id,        -- �ڋqID
      iv_gtai_syo     =>  iv_gtai_syo,       -- �Ƒԕ��ށi�����ށj
      ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
      ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <������񑶍݃`�F�b�N>
    -- ===============================
    item_ins(
      in_cust_id      =>  in_cust_id,        -- �ڋqID
      iv_gtai_syo     =>  iv_gtai_syo,       -- �Ƒԕ��ށi�����ށj
      ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
      ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --�Ƒԕ��ށi�����ށj�`�F�b�N
    IF ( iv_gtai_syo IN ( cv_gtal_syo_24, cv_gtal_syo_25, cv_gtal_syo_27 ) ) THEN
      -- =====================================
      -- <��݌ɐ��E�ޑK��z�`�F�b�N����>
      -- =====================================
      cust_base_chk(
        in_cust_id      =>  in_cust_id,        -- �ڋqID
        iv_gtai_syo     =>  iv_gtai_syo,       -- �Ƒԕ��ށi�����ށj
        ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
        ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
        );
-- 2010/08/04 Ver1.4 modify start by Shigeto.Niki
--    ELSE
--
      IF ( lv_check_status = cv_sts_check_ng ) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- 2010/08/04 Ver1.4 modify end by Shigeto.Niki
      -- ===============================
      -- <���|�c���`�F�b�N����>
      -- ===============================
      cust_balance_chk(
        in_cust_id      =>  in_cust_id,        -- �ڋqID
        iv_gtai_syo     =>  iv_gtai_syo,       -- �Ƒԕ��ށi�����ށj
        ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
        ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
        );
-- 2010/08/04 Ver1.4 delete start by Shigeto.Niki
--    END IF;
-- 2010/08/04 Ver1.4 delete end by Shigeto.Niki
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 insert start
    -- ===============================
    -- <����������݃`�F�b�N>
    -- ===============================
    cust_tran_chk(
      in_cust_id      =>  in_cust_id,        -- �ڋqID
      ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
      ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
-- 2011/03/07 Ver1.5 insert end
-- 2020/03/24 Ver1.7 insert start
--
    -- ===============================
    -- <BM�x���\��z�`�F�b�N>
    -- ===============================
    bm_expect_payment_chk(
      in_cust_id      =>  in_cust_id,        -- �ڋqID
      ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
      ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
-- 2020/03/24 Ver1.7 insert End
-- Ver1.8 Add Start
--
    -- ===============================
    -- <�̎�����G���[�`�F�b�N>
    -- ===============================
    bm_contract_err_chk(
      in_cust_id      =>  in_cust_id,        -- �ڋqID
      ov_check_status =>  lv_check_status,   -- �`�F�b�N�X�e�[�^�X
      ov_err_message  =>  lv_err_message     -- �G���[���b�Z�[�W
      );
--
    IF ( lv_check_status = cv_sts_check_ng ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
-- Ver1.8 Add End
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_err_message  := lv_err_message;
      ov_check_status := lv_check_status;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
--
--
  BEGIN
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      in_cust_id,      -- �ڋqID
      iv_gtai_syo,     -- �Ƒԕ��ށi�����ށj
      ov_check_status, -- �`�F�b�N�X�e�[�^�X
      ov_err_message   -- �G���[���b�Z�[�W
    );
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_err_message  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_check_status := cv_sts_check_ng;
      ROLLBACK;
  END main;
--
END XXCMM_CUST_STS_CHG_CHK_PKG;
/
