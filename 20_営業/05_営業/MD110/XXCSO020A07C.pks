CREATE OR REPLACE PACKAGE APPS.XXCSO020A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO020A07C (spec)
 * Description      : SP専決書情報CSV出力
 * MD.050           : SP専決書情報CSV出力 (MD050_CSO_020A07)
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
 *  2015/02/10    1.0   S.Yamashita      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT    VARCHAR2     -- エラーメッセージ #固定#
   ,retcode          OUT    VARCHAR2     -- エラーコード     #固定#
   ,iv_base_code     IN     VARCHAR2     -- 申請(売上)拠点
   ,iv_app_date_from IN     VARCHAR2     -- 申請日(FROM)
   ,iv_app_date_to   IN     VARCHAR2     -- 申請日(TO)
   ,iv_status        IN     VARCHAR2     -- ステータス
   ,iv_customer_cd   IN     VARCHAR2     -- 顧客コード
   ,iv_kbn           IN     VARCHAR2     -- 判定区分
  );
END XXCSO020A07C;
/
