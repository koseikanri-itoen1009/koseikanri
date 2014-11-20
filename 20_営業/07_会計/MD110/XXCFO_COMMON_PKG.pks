create or replace PACKAGE XXCFO_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg(spec)
 * Description      : ���ʊ֐��i��v�j
 * MD.050           : �Ȃ�
 * Version          : 1.00
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_special_info_item     F    VAR    �Y�t��񍀖ڒl�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-05   1.00   SCS �R���D       �V�K�쐬
 *  2008-03-25   1.01   SCS Kayahara      �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
  --�Y�t��񍀖ڒl�����擾
  FUNCTION get_special_info_item(
    il_long_text              IN          LONG,           -- ��������
    iv_serach_char            IN          VARCHAR2        -- ����������
  )
  RETURN VARCHAR2;
END XXCFO_COMMON_PKG;
/