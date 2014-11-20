CREATE OR REPLACE PACKAGE XXCOI009A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A05R(body)
 * Description      : 消化ＶＤ商品別チェックリスト
 * MD.050           : 消化ＶＤ商品別チェックリスト <MD050_XXCOI_009_A05>
 * Version          : V1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/02    1.0   H.Sasaki         初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf            OUT VARCHAR2        --   エラーメッセージ #固定#
    , retcode           OUT VARCHAR2        --   エラーコード     #固定#
    , iv_base_code      IN  VARCHAR2        --  拠点コード
    , iv_date_from      IN  VARCHAR2        --  出力期間(FROM)
    , iv_date_to        IN  VARCHAR2        --  出力期間(TO)
    , iv_conclusion_day IN  VARCHAR2        --  締め日
    , iv_customer_code  IN  VARCHAR2        --  顧客コード
  );
END XXCOI009A05R;
/
