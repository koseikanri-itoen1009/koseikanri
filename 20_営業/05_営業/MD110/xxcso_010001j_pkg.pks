CREATE OR REPLACE PACKAGE APPS.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010001j_pkg(SPEC)
 * Description      : ��������֐�(XXCSO���[�e�B���e�B�j
 * MD.050/070       : 
 * Version          : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     ��������֐�
 *  chk_latest_contract         F    V     �ŐV�_�񏑃`�F�b�N�֐�
 *  chk_cancel_contract         F    V     �_�񏑎���`�F�b�N�֐�
 *  chk_cooperate_wait          F    V     �}�X�^�A�g�҂��`�F�b�N�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa        �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori     T1_0897�Ή�
 *  2010/02/10    1.2   D.Abe           E_�{�ғ�_01538�Ή�
 *
 *****************************************************************************************/
--
   -- ��������֐�
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER           -- SP�ꌈ�w�b�_ID
  )
  RETURN VARCHAR2;
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� START */
--
   -- �ŐV�_�񏑃`�F�b�N�֐�
  FUNCTION chk_latest_contract(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
  )
  RETURN VARCHAR2;
--
   -- �_�񏑎���`�F�b�N�֐�
  FUNCTION chk_cancel_contract(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
   ,iv_account_number             IN  VARCHAR2         -- �ڋq�R�[�h
  )
  RETURN VARCHAR2;
--
  -- �}�X�^�A�g�҂��`�F�b�N�֐�
  FUNCTION chk_cooperate_wait(
    iv_contract_number            IN  VARCHAR2         -- �_�񏑔ԍ�
  ) RETURN VARCHAR2;
/* 2010.02.10 D.Abe E_�{�ғ�_01538�Ή� END */
--
END xxcso_010001j_pkg;
/
