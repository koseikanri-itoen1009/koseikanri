CREATE OR REPLACE PACKAGE APPS.xxcso_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_common_pkg(SPEC)
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
  gv_status_normal     CONSTANT VARCHAR2(1)    := '0';
  gv_status_warn       CONSTANT VARCHAR2(1)    := '1';
  gv_status_error      CONSTANT VARCHAR2(1)    := '2';
--
  gv_no_data_error_msg CONSTANT VARCHAR2(100)  := 'NO_DATA_FOUND';
--
--################################  固定部 END   ##################################
--
  -- OTHERS例外生成
  PROCEDURE raise_api_others_expt(
    iv_pkg_name          IN  VARCHAR2,
    iv_prg_name          IN  VARCHAR2
  );
--
END xxcso_common_pkg;
/
