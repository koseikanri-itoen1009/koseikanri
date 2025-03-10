CREATE OR REPLACE PACKAGE XXCSO016A09C
AS
/*****************************************************************************************
 * Copyright(c)2022,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO016A09C(spec)
 * Description      : 自販機顧客別支払管理を情報系システムへ連携するための
 *                    ＣＳＶファイルを作成します。
 * MD.050           : MD050_CSO_016_A09_情報系-EBSインターフェース：
 *                    (OUT)自販機顧客別支払管理
 *                    
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
 *  2022-07-21    1.0   K.Tomie         新規作成 E_本稼働_18060
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode               OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,iv_target_yyyymm_from IN         VARCHAR2          -- 対象年月(From)
   ,iv_target_yyyymm_to   IN         VARCHAR2          -- 対象年月(To)
  );
END XXCSO016A09C;
/
