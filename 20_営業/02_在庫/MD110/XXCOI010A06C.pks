CREATE OR REPLACE PACKAGE XXCOI010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOI010A06C(spec)
 * Description      : 工場入庫情報HHT連携
 * MD.050           : 工場入庫情報HHT連携 <MD050_COI_010_A06>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/01/12    1.0   SCSK佐々木       新規作成(E_本稼動_14486対応)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf          OUT VARCHAR2        --  エラー・メッセージ  --# 固定 #
    , retcode         OUT VARCHAR2        --  リターン・コード    --# 固定 #
    , iv_target_date  VARCHAR2            --  処理対象日
  );
END XXCOI010A06C;
/
