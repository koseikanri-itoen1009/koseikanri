CREATE OR REPLACE PACKAGE APPS.xxcso_005001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_005001j_pkg(spec)
 * Description      : ���\�[�X�Z�L�����e�B�p�b�P�[�W
 * MD.050           :  MD050_CSO_005_A01_�c�ƈ����\�[�X�֘A���̃Z�L�����e�B
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 * get_predicate          �Z�L�����e�B�|���V�[�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-05-08    1.0   Hiroshi.Ogawa    �V�K�쐬(T1_0593�Ή�)
 *****************************************************************************************/
  -- �Z�L�����e�B�|���V�[�擾
  FUNCTION  get_predicate(
    iv_schema            IN   VARCHAR2
   ,iv_object            IN   VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_005001j_pkg;
/
