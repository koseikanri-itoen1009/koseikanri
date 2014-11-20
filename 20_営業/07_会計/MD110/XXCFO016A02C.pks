CREATE OR REPLACE PACKAGE XXCFO016A02C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A02C(spec)
 * Description     : 発注書データ出力処理
 * MD.050          : MD050_CFO_016_A02_発注書データ出力処理
 * MD.070          : MD050_CFO_016_A02_発注書データ出力処理
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
 *  2008-10-24    1.0  SCS 山口 優   初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                     OUT NOCOPY VARCHAR2,         --    エラーメッセージ #固定#
    retcode                    OUT NOCOPY VARCHAR2,         --    エラーコード     #固定#
    iv_po_dept_code            IN         VARCHAR2,         --    発注作成部署
    iv_po_agent_code           IN         VARCHAR2,         --    発注作成者
    iv_vender_code             IN         VARCHAR2,         --    仕入先
    iv_po_num                  IN         VARCHAR2,         --    発注番号
    iv_po_creation_date_from   IN         VARCHAR2,         --    発注作成日From
    iv_po_creation_date_to     IN         VARCHAR2,         --    発注作成日To
    iv_po_approved_date_from   IN         VARCHAR2,         --    発注承認日From
    iv_po_approved_date_to     IN         VARCHAR2,         --    発注承認日To
    iv_reissue_flag            IN         VARCHAR2          --    再発行フラグ
  );
END XXCFO016A02C;
/
