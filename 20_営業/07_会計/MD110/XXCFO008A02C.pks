CREATE OR REPLACE PACKAGE XXCFO008A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO008A02C(spec)
 * Description      : 回収入金銀行預け入れ照合データ作成
 * MD.050           : 回収入金銀行預け入れ照合データ作成 MD050_CFO_008_A02
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
 *  2013/02/12    1.0  SCSK 石渡 賢和    新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_period_name IN    VARCHAR2,         --   1.対象年月
    iv_base_code   IN    VARCHAR2          --   2.拠点コード
  );
END XXCFO008A02C;
/
