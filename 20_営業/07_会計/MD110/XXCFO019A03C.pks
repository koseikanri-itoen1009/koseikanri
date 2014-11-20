CREATE OR REPLACE PACKAGE XXCFO019A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A03C(spec)
 * Description      : 電子帳簿販売実績の情報系システム連携
 * MD.050           : 電子帳簿販売実績の情報系システム連携 <MD050_CFO_019_A03>
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
 *  2012/08/27    1.0   T.Osawa          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT        VARCHAR2          -- エラーメッセージ #固定#
   ,retcode              OUT        VARCHAR2          -- エラーコード     #固定#
   ,iv_ins_upd_kbn       IN         VARCHAR2          -- 追加更新区分
   ,iv_file_name         IN         VARCHAR2          -- ファイル名
   ,iv_id_from           IN         VARCHAR2          -- 販売実績ヘッダID（From）
   ,iv_id_to             IN         VARCHAR2          -- 販売実績ヘッダID（To）
  );
END XXCFO019A03C;
/
