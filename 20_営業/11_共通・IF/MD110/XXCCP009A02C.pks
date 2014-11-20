CREATE OR REPLACE PACKAGE XXCCP009A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP009A02C(spec)
 * Description      : 対向システムジョブ状況テーブル(アドオン)の更新を行います。
 * MD.050           : MD050_CCP_009_A02_対向システムジョブ状況更新処理
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
 *  2009-01-05    1.0  Koji.Oomata       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                 OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_pk_request_id_val    IN     VARCHAR2,         --   処理順付要求ID
    iv_status_code          IN     VARCHAR2          --   ステータスコード
  );
END XXCCP009A02C;
/
