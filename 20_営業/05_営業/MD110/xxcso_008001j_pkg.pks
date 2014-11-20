CREATE OR REPLACE PACKAGE APPS.xxcso_008001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_008001j_pkg(SPEC)
 * Description      : �T�������󋵏Ɖ�ʊ֐�
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_baseline_base_code   F    V      ��������_�R�[�h�擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   N.Yanagitaira    �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ��������_�R�[�h���_�R�[�h�擾�֐�
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2;
--
END xxcso_008001j_pkg;
/
