CREATE OR REPLACE PACKAGE XXCMN800014C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800014C(spec)
 * Description      : 生産バッチ情報をCSVファイル出力し、ワークフロー形式で連携します。
 * MD.050           : 生産バッチ情報インタフェース<T_MD050_BPO_801>
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
 *  2016/07/01    1.0   S.Yamashita      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_batch_no               IN  VARCHAR2        -- 1.バッチNO
   ,iv_whse_code              IN  VARCHAR2        -- 2.倉庫コード
   ,iv_production_date_from   IN  VARCHAR2        -- 3.完成品製造日(FROM)
   ,iv_production_date_to     IN  VARCHAR2        -- 4.完成品製造日(TO)
   ,iv_routing                IN  VARCHAR2        -- 5.ラインNo
  );
END XXCMN800014C;
/
