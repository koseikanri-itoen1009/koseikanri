CREATE OR REPLACE PACKAGE XXCOK015A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A02R(spec)
 * Description      : 手数料を現金支払する際の支払案内書（領収書付き）を
 *                    各売上計上拠点で印刷します。
 * MD.050           : 支払案内書印刷（領収書付き） MD050_COK_015_A02
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   K.Yamaguchi      新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_base_code                   IN  VARCHAR2        -- 売上計上拠点
  , iv_fix_flag                    IN  VARCHAR2        -- 支払確定
  , iv_vendor_code                 IN  VARCHAR2        -- 支払先
  );
END XXCOK015A02R;
/
