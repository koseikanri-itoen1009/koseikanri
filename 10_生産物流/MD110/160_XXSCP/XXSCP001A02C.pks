CREATE OR REPLACE PACKAGE APPS.XXSCP001A02C
AS
/*****************************************************************************************
 *Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXSCP001A02C(spec)
 * Description      : 転送オーダーメジャー生産計画FBDI連携
 *                    移動予定数量をCSV出力する。
 * Version          : 1.0
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
 *  2024/12/13    1.0   SCSK M.Sato      [E_本稼動_20298]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2     --   リターン・コード             --# 固定 #
  );
END XXSCP001A02C;
/
