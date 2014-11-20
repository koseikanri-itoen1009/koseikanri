/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_BASE_V
 * Description : ���_�r���[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_base_v
  ( base_code                                -- ���_�R�[�h
  , base_name                                -- ���_����
  )
AS
  SELECT hca.account_number   base_code         -- �ڋq�R�[�h
       , hp.party_name        base_name         -- �ڋq����
  FROM   hz_cust_accounts      hca              -- �ڋq�}�X�^
       , hz_parties            hp               -- �p�[�e�B�}�X�^
  WHERE  hca.party_id            = hp.party_id
  AND    hca.customer_class_code = '1'          -- ���_
  AND    hp.duns_number_c       <> '90'
/
COMMENT ON TABLE  apps.xxcok_base_v                       IS '���_�r���['
/
COMMENT ON COLUMN apps.xxcok_base_v.base_code             IS '���_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_base_v.base_name             IS '���_����'
/
