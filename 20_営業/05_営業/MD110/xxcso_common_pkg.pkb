CREATE OR REPLACE PACKAGE BODY APPS.xxcso_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_common_pkg(BODY)
 * Description      : ���ʊ֐�(�c�ƁE�c�Ɨ̈�j
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  raise_api_others_expt     P    -     OTHERS��O����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          �V�K�쐬
 *  2008/12/24    1.0   M.maruyama       �w�b�_�C��(Oracle�ł���SCS�ł�)
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_msg_part          CONSTANT VARCHAR2(3)    := ' : ';
  gv_msg_cont          CONSTANT VARCHAR2(1)    := '.';
--
--################################  �Œ蕔 END   ##################################
--
  -- OTHERS��O����
  PROCEDURE raise_api_others_expt(
    iv_pkg_name          IN  VARCHAR2,
    iv_prg_name          IN  VARCHAR2
  )
  IS
  BEGIN
--
    RAISE_APPLICATION_ERROR
      (-20000,SUBSTRB(iv_pkg_name||gv_msg_cont||iv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
  END raise_api_others_expt;
--
END xxcso_common_pkg;
/
