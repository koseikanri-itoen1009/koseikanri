CREATE OR REPLACE PACKAGE APPS.xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : �����̔��@�ݒu�_����o�^�X�V_���ʊ֐�
 * MD.050/070       : 
 * Version          : 1.14
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  decode_bm_info            F    V      ��������_�R�[�h�擾�֐�
 *  get_base_leader_name      F    V      ���s���������擾
 *  get_base_leader_pos_name  F    V      ���s���������E�ʖ��擾
 *  chk_double_byte_kana      F    V      �S�p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_tel_format            F    V      �d�b�ԍ��`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_duplicate_vendor_name F    V      ���t�於�d���`�F�b�N
 *  get_authority             F    V      ��������֐�
 *  chk_bfa_single_byte_kana  F    V      ���p�J�i�`�F�b�N�iBFA�֐����b�s���O�j
 *  decode_cont_manage_info   F    V      �_��Ǘ���񕪊�擾
 *  get_sales_charge          F    V      �̔��萔�������۔���
 *  chk_double_byte           F    V      �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_single_byte_kana      F    V      ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  chk_cooperate_wait        F    V      �}�X�^�A�g�҂��`�F�b�N
 *  reflect_contract_status   P    -      �_�񏑊m���񔽉f����
 *  chk_validate_db           P    -      �c�a�X�V����`�F�b�N
 *  chk_cash_payment          F    V      �����x���`�F�b�N
 *  chk_install_code          F    V      �����R�[�h�`�F�b�N
 *  chk_stop_account          F    V      ���~�ڋq�`�F�b�N
 *  chk_account_install_code  F    V      �ڋq�����`�F�b�N
 *  chk_bank_branch           F    V      ��s�x�X�}�X�^�`�F�b�N
 *  chk_supplier              F    V      �d����}�X�^�`�F�b�N
 *  chk_bank_account          F    V      ��s�����}�X�^�`�F�b�N
 *  chk_bank_account_change   F    V      ��s�����}�X�^�ύX�`�F�b�N
 *  chk_owner_change_use      F    V      �I�[�i�ύX�����g�p�`�F�b�N
 *  chk_supp_info_change      F    V      ���t��ύX�`�F�b�N
 *  chk_email_address         F    V      ���[���A�h���X�`�F�b�N�i���ʊ֐����b�s���O�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   H.Ogawa          �V�K�쐬
 *  2009/02/16    1.0   N.Yanagitaira    [UT��C��]chk_bfa_single_byte_kana�ǉ�
 *  2009/02/17    1.1   N.Yanagitaira    [CT1-012]decode_cont_manage_info�ǉ�
 *  2009/02/23    1.1   N.Yanagitaira    [������Q-028]�S�p�J�i�`�F�b�N�����s���C��
 *  2009/03/12    1.1   N.Yanagitaira    [CT2-058]get_sales_charge�ǉ�
 *  2009/04/08    1.2   N.Yanagitaira    [ST��QT1_0364]chk_duplicate_vendor_name�C��
 *  2009/04/27    1.3   N.Yanagitaira    [ST��QT1_0708]���͍��ڃ`�F�b�N��������C��
 *                                                      chk_double_byte
 *                                                      chk_single_byte_kana
 *  2009-05-01    1.4   Tomoko.Mori      T1_0897�Ή�
 *  2010/02/10    1.5   D.Abe            E_�{�ғ�_01538�Ή�
 *  2010/03/01    1.6   D.Abe            E_�{�ғ�_01678,E_�{�ғ�_01868�Ή�
 *  2011/01/06    1.7   K.Kiriu          E_�{�ғ�_02498�Ή�
 *  2011/06/06    1.8   K.Kiriu          E_�{�ғ�_01963�Ή�
 *  2013/04/01    1.9   K.Kiriu          E_�{�ғ�_10413�Ή�
 *  2015/12/03    1.10  S.Yamashita      E_�{�ғ�_13345�Ή�
 *  2016/01/06    1.11  K.Kiriu          E_�{�ғ�_13456�Ή�
 *  2019/02/19    1.12  Y.Sasaki         E_�{�ғ�_15349�Ή�
 *  2020/10/28    1.13  Y.Sasaki         E_�{�ғ�_16410,E_�{�ғ�_16293�Ή�
 *  2020/12/14    1.14  Y.Sasaki         E_�{�ғ�_16642�Ή�
 *****************************************************************************************/
--
  -- BM��񕪊�擾
  FUNCTION decode_bm_info(
    in_customer_id              NUMBER
   ,iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���s���������擾
  FUNCTION get_base_leader_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���s���������E�ʖ��擾
  FUNCTION get_base_leader_pos_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �S�p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �d�b�ԍ��`�F�b�N�i���ʊ֐����b�s���O�j
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���t�於�d���`�F�b�N
-- 20090408_N.Yanagitaira T1_0364 Mod START
--  FUNCTION chk_duplicate_vendor_name(
--    iv_dm1_vendor_name             IN  VARCHAR2
--   ,iv_dm2_vendor_name             IN  VARCHAR2
--   ,iv_dm3_vendor_name             IN  VARCHAR2
--   ,in_contract_management_id      IN  NUMBER
--   ,in_dm1_supplier_id             IN  NUMBER
--   ,in_dm2_supplier_id             IN  NUMBER
--   ,in_dm3_supplier_id             IN  NUMBER
--  ) RETURN VARCHAR2;
  PROCEDURE chk_duplicate_vendor_name(
    iv_bm1_vendor_name             IN  VARCHAR2
   ,iv_bm2_vendor_name             IN  VARCHAR2
   ,iv_bm3_vendor_name             IN  VARCHAR2
   ,in_bm1_supplier_id             IN  NUMBER
   ,in_bm2_supplier_id             IN  NUMBER
   ,in_bm3_supplier_id             IN  NUMBER
   ,iv_operation_mode              IN  VARCHAR2
   ,on_bm1_dup_count               OUT NUMBER
   ,on_bm2_dup_count               OUT NUMBER
   ,on_bm3_dup_count               OUT NUMBER
   ,ov_bm1_contract_number         OUT VARCHAR2
   ,ov_bm2_contract_number         OUT VARCHAR2
   ,ov_bm3_contract_number         OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
-- 20090408_N.Yanagitaira T1_0364 Mod END
--
   -- ��������֐�
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER
  )
  RETURN VARCHAR2;
--
  -- ���p�J�i�`�F�b�N�iBFA�֐����b�s���O�j
  FUNCTION chk_bfa_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �_��Ǘ�����擾
  FUNCTION decode_cont_manage_info(
    iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �̔��萔�������۔���
  FUNCTION get_sales_charge(
    in_sp_decision_header_id    NUMBER
  ) RETURN VARCHAR2;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  -- �S�p�����`�F�b�N�i���ʊ֐����b�s���O�j
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ���p�J�i�����`�F�b�N�i���ʊ֐����b�s���O�j
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
-- 20090427_N.Yanagitaira T1_0708 Add END
--
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� START */
  -- �}�X�^�A�g�҂��`�F�b�N
  FUNCTION chk_cooperate_wait(
    iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
  ) RETURN VARCHAR2;
--
  -- �_�񏑊m���񔽉f����
  PROCEDURE reflect_contract_status(
    iv_contract_management_id     IN  VARCHAR2         -- �_��ID
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_status                     IN  VARCHAR2         -- �X�e�[�^�X
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
  -- �c�a�X�V����`�F�b�N
  PROCEDURE chk_validate_db(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� END */
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� START */
  -- �����x���`�F�b�N
  FUNCTION chk_payment_type_cash(
     in_sp_decision_header_id     IN  NUMBER           -- SP�ꌈ�w�b�_ID
    ,in_supplier_id               IN  NUMBER           -- ���t��ID
    ,iv_delivery_div              IN  VARCHAR2         -- ���t�敪
  ) RETURN VARCHAR2;
--
/* 2010.03.01 D.Abe E_�{�ғ�_01678�Ή� END */
/* 2010.03.01 D.Abe E_�{�ғ�_01868�Ή� START */
  -- �����R�[�h�`�F�b�N
  FUNCTION chk_install_code(
     iv_install_code              IN  VARCHAR2         -- �����R�[�h
  ) RETURN VARCHAR2;
--
/* 2015.12.03 S.Yamashita E_�{�ғ�_13345�Ή� START */
  -- ���~�ڋq�`�F�b�N
  FUNCTION chk_stop_account(
    in_install_account_id         IN  NUMBER           -- �ڋqID
  ) RETURN VARCHAR2;
--
  -- �ڋq�����`�F�b�N
  FUNCTION chk_account_install_code(
    in_install_account_id         IN  NUMBER           -- �ڋqID
  ) RETURN VARCHAR2;
--
/* 2015.12.03 S.Yamashita E_�{�ғ�_13345�Ή� END */
/* 2010.03.01 D.Abe E_�{�ғ�_01868�Ή� END */
/* 2011/01/06 Ver1.7 K.kiriu E_�{�ғ�_02498�Ή� START */
  -- ��s�x�X�}�X�^�`�F�b�N
  FUNCTION chk_bank_branch(
    iv_bank_number  IN  VARCHAR2                       -- ��s�ԍ�
   ,iv_bank_num     IN  VARCHAR2                       -- �x�X�ԍ�
  ) RETURN VARCHAR2;
/* 2011/01/06 Ver1.7 K.kiriu E_�{�ғ�_02498�Ή� END */
/* 2011/06/06 Ver1.8 K.kiriu E_�{�ғ�_01963�Ή� START */
  -- �d����}�X�^�`�F�b�N
  FUNCTION chk_supplier(
    iv_customer_code              IN  VARCHAR2         -- �ڋq�R�[�h
   ,in_supplier_id                IN  NUMBER           -- �d����ID
   ,iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,iv_delivery_div               IN  VARCHAR2         -- ���t�敪
  ) RETURN VARCHAR2;
  -- ��s�����}�X�^�`�F�b�N
  FUNCTION chk_bank_account(
    iv_bank_number                IN  VARCHAR2         -- ��s�ԍ�
   ,iv_bank_num                   IN  VARCHAR2         -- �x�X�ԍ�
   ,iv_bank_account_num           IN  VARCHAR2         -- �����ԍ�
  ) RETURN VARCHAR2;
/* 2011/06/06 Ver1.8 K.kiriu E_�{�ғ�_01963�Ή� END */
/* 2013/04/01 Ver1.9 K.kiriu E_�{�ғ�_10413�Ή� START */
  -- ��s�����}�X�^�ύX�`�F�b�N
  FUNCTION chk_bank_account_change(
    iv_bank_number                IN  VARCHAR2         -- ��s�ԍ�
   ,iv_bank_num                   IN  VARCHAR2         -- �x�X�ԍ�
   ,iv_bank_account_num           IN  VARCHAR2         -- �����ԍ�
   ,iv_bank_account_type          IN  VARCHAR2         -- �������(��ʓ��͒l)
   ,iv_account_holder_name_alt    IN  VARCHAR2         -- �������`�J�i(��ʓ��͒l)
   ,iv_account_holder_name        IN  VARCHAR2         -- �������`����(��ʓ��͒l)
   ,ov_bank_account_type          OUT VARCHAR2         -- �������(�}�X�^)
   ,ov_account_holder_name_alt    OUT VARCHAR2         -- �������`�J�i(�}�X�^)
   ,ov_account_holder_name        OUT VARCHAR2         -- �������`����(�}�X�^)
  ) RETURN VARCHAR2;
/* 2013/04/01 Ver1.9 K.kiriu E_�{�ғ�_10413�Ή� END */
/* 2016/01/06 Ver1.11 K.kiriu E_�{�ғ�_13456�Ή� START */
  -- �I�[�i�ύX�����g�p�`�F�b�N
  FUNCTION chk_owner_change_use(
    iv_install_code               IN  VARCHAR2         -- �����R�[�h
   ,in_install_account_id         IN  NUMBER           -- �ڋqID
  ) RETURN VARCHAR2;
/* 2016/01/06 Ver1.11 K.kiriu E_�{�ғ�_13456�Ή� END */
/* V1.12 Y.Sasaki Added START */
  -- ���t����ύX�`�F�b�N
  FUNCTION chk_supp_info_change(
     iv_vendor_code                  IN  VARCHAR2         -- ���t��R�[�h
    ,ov_bm_transfer_commission_type  OUT VARCHAR2         -- �U���萔�����S
    ,ov_bm_payment_type              OUT VARCHAR2         -- �x�����@�A���׏�
    ,ov_inquiry_base_code            OUT VARCHAR2         -- �⍇���S�����_
    ,ov_inquiry_base_name            OUT VARCHAR2         -- �⍇���S�����_��
    ,ov_vendor_name                  OUT VARCHAR2         -- ���t�於
    ,ov_vendor_name_alt              OUT VARCHAR2         -- ���t�於�J�i
    ,ov_zip                          OUT VARCHAR2         -- �X�֔ԍ�
    ,ov_address_line1                OUT VARCHAR2         -- �Z���P
    ,ov_address_line2                OUT VARCHAR2         -- �Z���Q
    ,ov_phone_number                 OUT VARCHAR2         -- �d�b�ԍ�
    ,ov_bank_number                  OUT VARCHAR2         -- ���Z�@�փR�[�h
    ,ov_bank_name                    OUT VARCHAR2         -- ���Z�@�֖�
    ,ov_bank_branch_number           OUT VARCHAR2         -- �x�X�R�[�h
    ,ov_bank_branch_name             OUT VARCHAR2         -- �x�X��
    ,ov_bank_account_type            OUT VARCHAR2         -- �������
    ,ov_bank_account_num             OUT VARCHAR2         -- �����ԍ�
    ,ov_bank_account_holder_nm_alt   OUT VARCHAR2         -- �������`�J�i
    ,ov_bank_account_holder_nm       OUT VARCHAR2         -- �������`����
  ) RETURN VARCHAR2;
/* V1.12 Y.Sasaki Added END   */
/* E_�{�ғ�_16410 Add START */
  -- BM��s�����ύX�`�F�b�N
  FUNCTION chk_bm_bank_chg(
      iv_vendor_code                IN  VARCHAR2          -- ���t��R�[�h
    , iv_bank_number                IN  VARCHAR2          -- ��s�R�[�h
    , iv_bank_num                   IN  VARCHAR2          -- �x�X�R�[�h
    , iv_bank_account_num           IN  VARCHAR2          -- �����ԍ�
    , iv_bank_account_type          IN  VARCHAR2          -- �������
    , iv_bank_account_holder_nm_alt IN  VARCHAR2          -- �������`�J�i
    , iv_bank_account_holder_nm     IN  VARCHAR2          -- �������`����
    , ov_bank_vendor_code           OUT VARCHAR2          -- �����d����R�[�h
  ) RETURN VARCHAR2;
/* E_�{�ғ�_16410 Add End */
/* E_�{�ғ�_16293 Add START */
  -- �d���斳�����`�F�b�N
  FUNCTION chk_vendor_inbalid(
    iv_vendor_code                  IN  VARCHAR2          -- ���t��R�[�h
  ) RETURN VARCHAR2;
/* E_�{�ғ�_16293 Add END   */
/* E_�{�ғ�_16293 Add START */
  -- ���[���A�h���X�`�F�b�N
  FUNCTION chk_email_address(
    iv_email_address                IN  VARCHAR2          -- E���[���A�h���X
  ) RETURN VARCHAR2;
/* E_�{�ғ�_16293 Add END   */
--
END xxcso_010003j_pkg;
/
