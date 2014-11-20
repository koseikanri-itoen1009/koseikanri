CREATE OR REPLACE PACKAGE xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : �����̔��@�ݒu�_����o�^�X�V_���ʊ֐�
 * MD.050/070       : 
 * Version          : 1.0
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
 *  chk_single_byte_kana      F    V      ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
 *  decode_cont_manage_info   F    V      �_��Ǘ���񕪊�擾
 *  get_sales_charge          F    V      �̔��萔�������۔���
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   H.Ogawa          �V�K�쐬
 *  2009/02/16    1.0   N.Yanagitaira    [UT��C��]chk_single_byte_kana�ǉ�
 *  2009/02/17    1.1   N.Yanagitaira    [CT1-012]decode_cont_manage_info�ǉ�
 *  2009/02/23    1.1   N.Yanagitaira    [������Q-028]�S�p�J�i�`�F�b�N�����s���C��
 *  2009/03/12    1.1   N.Yanagitaira    [CT2-058]get_sales_charge�ǉ�
 *  2009/04/08    1.2   N.Yanagitaira    [��QT1_0364]chk_duplicate_vendor_name�C��
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
  -- ���p�J�i�`�F�b�N�i���ʊ֐����b�s���O�j
  FUNCTION chk_single_byte_kana(
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
END xxcso_010003j_pkg;
/
