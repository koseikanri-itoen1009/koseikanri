CREATE OR REPLACE PACKAGE APPS.XXCMM006A07C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCMM006A07C
 * Description     : 値リストの値IF抽出
 * MD.050          : T_MD050_CMM_006_A07_値リストの値IF抽出_EBSコンカレント
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  main                コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2022-12-07    1.0   T.Okuyama     初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2         -- エラーメッセージ # 固定 #
    , retcode                 OUT    VARCHAR2         -- エラーコード     # 固定 #
    , iv_flex_value_set_name  IN     VARCHAR2         -- 値セット名
  );
END XXCMM006A07C;
/
