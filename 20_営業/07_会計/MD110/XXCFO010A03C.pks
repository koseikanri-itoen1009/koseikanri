CREATE OR REPLACE PACKAGE XXCFO010A03C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 * 
 * Package Name    : XXCFO010A03C
 * Description     : GLIFグループID更新
 * MD.050          : MD050_CFO_010_A03_GLIFグループID更新
 * MD.070          : MD050_CFO_010_A03_GLIFグループID更新
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2015-08-07    1.0  SCSK 小路恭弘  初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT   VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode             OUT   VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_je_source_name   IN    VARCHAR2,      -- 仕訳ソース名
    iv_group_id         IN    VARCHAR2       -- グループID
  );
END XXCFO010A03C;
/
