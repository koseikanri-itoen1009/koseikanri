CREATE OR REPLACE PACKAGE xxwsh600004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600004C(spec)
 * Description      : ＨＨＴ入出庫配車確定情報抽出処理
 * MD.050           : T_MD050_BPO_601_配車配送計画
 * MD.070           : T_MD070_BPO_60F_ＨＨＴ入出庫配車確定情報抽出処理
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
 *  2008/05/02    1.0   M.Ikeda          新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf              OUT NOCOPY  VARCHAR2    -- エラーメッセージ #固定#
     ,retcode             OUT NOCOPY  VARCHAR2    -- エラーコード     #固定#
     ,iv_dept_code        IN  VARCHAR2            -- 01 : 部署
     ,iv_date_fix         IN  VARCHAR2            -- 02 : 確定通知実施日
     ,iv_fix_from         IN  VARCHAR2            -- 03 : 確定通知実施時間From
     ,iv_fix_to           IN  VARCHAR2            -- 04 : 確定通知実施時間To
    ) ;
--
END xxwsh600004c ;
/
