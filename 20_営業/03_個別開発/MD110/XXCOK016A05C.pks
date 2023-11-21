CREATE OR REPLACE PACKAGE XXCOK016A05C
AS
/*****************************************************************************************
 * Copyright(c) SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCOK016A05C(spec)
 * Description      : FBデータファイル作成処理で作成されたFBデータを基に、
 *                    仕向銀行の振り分け処理を行います。
 *
 * MD.050           : FBデータファイル振り分け処理 MD050_COK_016_A05
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
 *  2023/11/08    1.0   T.Okuyama        [E_本稼動_19540対応] 新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT VARCHAR2     -- エラーメッセージ
  , retcode            OUT VARCHAR2     -- エラーコード
  , in_request_id      IN  NUMBER       -- パラメータ：FBデータファイル作成時の要求ID
  , iv_internal_bank1  IN  VARCHAR2     -- パラメータ：他行分仕向銀行1
  , in_bank_cnt1       IN  NUMBER       -- パラメータ：仕向銀行1への按分件数
  , iv_internal_bank2  IN  VARCHAR2     -- パラメータ：他行分仕向銀行2
  , in_bank_cnt2       IN  NUMBER       -- パラメータ：仕向銀行2への按分件数
  , iv_internal_bank3  IN  VARCHAR2     -- パラメータ：他行分仕向銀行3
  , in_bank_cnt3       IN  NUMBER       -- パラメータ：仕向銀行3への按分件数
  , iv_internal_bank4  IN  VARCHAR2     -- パラメータ：他行分仕向銀行4
  , in_bank_cnt4       IN  NUMBER       -- パラメータ：仕向銀行4への按分件数
  , iv_internal_bank5  IN  VARCHAR2     -- パラメータ：他行分仕向銀行5
  , in_bank_cnt5       IN  NUMBER       -- パラメータ：仕向銀行5への按分件数
  , iv_internal_bank6  IN  VARCHAR2     -- パラメータ：他行分仕向銀行6
  , in_bank_cnt6       IN  NUMBER       -- パラメータ：仕向銀行6への按分件数
  );
END XXCOK016A05C;
/
