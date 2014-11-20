CREATE OR REPLACE PACKAGE xxwsh930007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930007c(spec)
 * Description      : 外部倉庫入出庫実績インタフェースラッピングプログラム
 * MD.050           : 出荷・移動インタフェース                             T_MD050_BPO_930
 * MD.070           : 外部倉庫入出庫実績インタフェースラッピングプログラム T_MD070_BPO_93G
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
 *  2008/10/09    1.0   Y.Suzuki         新規作成
 *
 *****************************************************************************************/
--
  -- コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT VARCHAR2          --   エラーメッセージ #固定#
   ,retcode                OUT VARCHAR2          --   エラーコード     #固定#
   ,iv_process_object_info IN  VARCHAR2          -- 処理対象情報
   ,iv_report_post         IN  VARCHAR2          -- 報告部署
   ,iv_object_warehouse    IN  VARCHAR2          -- 対象倉庫
  );
END xxwsh930007c;
/
