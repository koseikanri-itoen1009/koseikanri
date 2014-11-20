CREATE OR REPLACE PACKAGE BODY APPS.xxcso_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_common_pkg(BODY)
 * Description      : 共通関数(営業・営業領域）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  raise_api_others_expt     P    -     OTHERS例外生成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          新規作成
 *  2008/12/24    1.0   M.maruyama       ヘッダ修正(Oracle版からSCS版へ)
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_msg_part          CONSTANT VARCHAR2(3)    := ' : ';
  gv_msg_cont          CONSTANT VARCHAR2(1)    := '.';
--
--################################  固定部 END   ##################################
--
  -- OTHERS例外生成
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
