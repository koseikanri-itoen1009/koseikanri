CREATE OR REPLACE PACKAGE XXCOS011A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A10C (spec)
 * Description      : 入庫予定データの抽出を行う
 * MD.050           : 入庫予定データ抽出 (MD050_COS_011_A10)
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
 *  2008/12/02    1.0   K.Kiriu         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode            OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_to_s_code       IN     VARCHAR2,         --   1.搬送先保管場所
    iv_edi_c_code      IN     VARCHAR2,         --   2.EDIチェーン店コード
    iv_request_number  IN     VARCHAR2          --   3.移動オーダー番号
  );
END XXCOS011A10C;
/
