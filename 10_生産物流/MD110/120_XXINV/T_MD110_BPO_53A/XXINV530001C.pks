CREATE OR REPLACE PACKAGE xxinv530001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv5300001(spec)
 * Description      : 棚卸結果インターフェース
 * MD.050           : 棚卸Issue1.0(T_MD050_BPO_530)
 * MD.070           : 棚卸Issue1.0(T_MD070_BPO_53A)
 * Version          : 1.0
 *
 * Program List
 *  -------------------------------------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------------------------------------------------------------------
 *  main                  P          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * -----------------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * -----------------------------------------------------------------------------------
 *  2008/03/14    1.0   M.Inamine        新規作成
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT    VARCHAR2    -- エラーメッセージ
   ,retcode               OUT    VARCHAR2    -- リターン・コード  
   ,iv_report_post_code   IN     VARCHAR2    -- 報告部署
   ,iv_whse_code          IN     VARCHAR2    -- 倉庫コード
   ,iv_item_type          IN     VARCHAR2);  -- 品目区分
--
END xxinv530001c;
/