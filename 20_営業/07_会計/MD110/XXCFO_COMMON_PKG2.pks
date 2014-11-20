create or replace PACKAGE XXCFO_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg2(spec)
 * Description      : ���ʊ֐��i��v�j
 * MD.070           : MD070_IPO_CFO_001_���ʊ֐���`��
 * Version          : 1.00
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  chk_electric_book_item    P           �d�q���덀�ڃ`�F�b�N�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-08-31   1.00   SCSK T.Osawa     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�d�q���덀�ڃ`�F�b�N�֐�
  PROCEDURE chk_electric_book_item(
      iv_item_name    IN  VARCHAR2 -- ���ږ���
    , iv_item_value   IN  VARCHAR2 -- ���ڂ̒l
    , in_item_len     IN  NUMBER   -- ���ڂ̒���
    , in_item_decimal IN  NUMBER   -- ���ڂ̒���(�����_�ȉ�)
    , iv_item_nullflg IN  VARCHAR2 -- �K�{�t���O
    , iv_item_attr    IN  VARCHAR2 -- ���ڑ���
    , iv_item_cutflg  IN  VARCHAR2 -- �؎̂ăt���O
    , ov_item_value   OUT VARCHAR2 -- ���ڂ̒l
    , ov_errbuf       OUT VARCHAR2 -- �G���[���b�Z�[�W
    , ov_retcode      OUT VARCHAR2 -- ���^�[���R�[�h
    , ov_errmsg       OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  );
END XXCFO_COMMON_PKG2;
/
