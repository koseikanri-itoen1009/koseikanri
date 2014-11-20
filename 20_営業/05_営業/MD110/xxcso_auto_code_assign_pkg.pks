CREATE OR REPLACE PACKAGE xxcso_auto_code_assign_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_AUTO_CODE_ASSIGN_PKG(SPEC)
 * Description      : 共通関数(XXCSO採番）
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  auto_code_assign          F    -     自動採番関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/21    1.0   T.maruyama       新規作成
 *
 *****************************************************************************************/
--
  -- 自動採番関数
  FUNCTION auto_code_assign(
    iv_cl_assign             IN  VARCHAR2,               -- 採番種別
    iv_base_code             IN  VARCHAR2,               -- 拠点コード
    id_base_date             IN  DATE                    -- 処理日付（YYYMMDD）
  ) RETURN VARCHAR2;
--
END XXCSO_AUTO_CODE_ASSIGN_PKG;
/
