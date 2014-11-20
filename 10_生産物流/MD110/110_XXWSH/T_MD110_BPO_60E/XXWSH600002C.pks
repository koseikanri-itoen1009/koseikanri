CREATE OR REPLACE PACKAGE xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(spec)
 * Description      : 入出庫配送計画情報抽出処理
 * MD.050           : T_MD050_BPO_601_配車配送計画
 * MD.070           : T_MD070_BPO_60E_入出庫配送計画情報抽出処理
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
 *  2008/04/01    1.0   M.Ikeda          新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- エラーメッセージ #固定#
     ,retcode             OUT NOCOPY  VARCHAR2    -- エラーコード     #固定#
     ,iv_dept_code        IN  VARCHAR2            -- 01 : 部署
     ,iv_fix_class        IN  VARCHAR2            -- 02 : 予定確定区分
     ,iv_date_cutoff      IN  VARCHAR2            -- 03 : 締め実施日
     ,iv_cutoff_from      IN  VARCHAR2            -- 04 : 締め実施時間From
     ,iv_cutoff_to        IN  VARCHAR2            -- 05 : 締め実施時間To
     ,iv_date_fix         IN  VARCHAR2            -- 06 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2            -- 07 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2            -- 08 : 確定通知実施時間To
    ) ;
--
END xxwsh600002c ;
/
