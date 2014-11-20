CREATE OR REPLACE PACKAGE XXCFO019A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A09C(spec)
 * Description      : 電子帳簿在庫管理の情報系システム連携
 * MD.050           : MD050_CFO_019_A09_電子帳簿在庫管理の情報系システム連携
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
 *  2012-08-31    1.0   K.Nakamura       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf           OUT VARCHAR2         -- エラーメッセージ #固定#
    , retcode          OUT VARCHAR2         -- エラーコード     #固定#
    , iv_ins_upd_kbn   IN  VARCHAR2         -- 追加更新区分
    , iv_file_name     IN  VARCHAR2         -- ファイル名
    , iv_tran_id_from  IN  VARCHAR2         -- 資材取引ID（From）
    , iv_tran_id_to    IN  VARCHAR2         -- 資材取引TO（To）
    , iv_batch_id_from IN  VARCHAR2         -- GLバッチID（From）
    , iv_batch_id_to   IN  VARCHAR2         -- GLバッチID（To）
    , iv_exec_kbn      IN  VARCHAR2         -- 定期手動区分
  );
END XXCFO019A09C;
/
