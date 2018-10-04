CREATE OR REPLACE PACKAGE XXCFF020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCFF020A01C(spec)
 * Description      : 登録済み支払計画の支払料金、支払回数の変更
 * MD.050           : MD050_CFF_020_A01_リース料変更プログラム
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
 *  2018/10/02    1.0   H.Sasaki         新規作成(E_本稼動_14830)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf            OUT VARCHAR2          --  エラーメッセージ #固定#
    , retcode           OUT VARCHAR2          --  エラーコード     #固定#
    , iv_object_code    IN  VARCHAR2          --  物件コード
    , iv_new_frequency  IN  VARCHAR2          --  変更後支払回数
    , iv_new_charge     IN  VARCHAR2          --  変更後リース料
    , iv_new_tax_charge IN  VARCHAR2          --  変更後税額
    , iv_new_tax_code   IN  VARCHAR2          --  変更後税コード
  );
END XXCFF020A01C;
/
