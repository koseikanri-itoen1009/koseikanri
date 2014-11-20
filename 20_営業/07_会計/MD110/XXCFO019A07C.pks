CREATE OR REPLACE PACKAGE XXCFO019A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A07C(spec)
 * Description      : 電子帳簿AR入金の情報系システム連携
 * MD.050           : 電子帳簿AR入金の情報系システム連携<MD050_CFO_019_A07>
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
 *  2012-09-07    1.0   N.Sugiura      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                  OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_ins_upd_kbn           IN     VARCHAR2,         -- 1.追加更新区分
    iv_file_name             IN     VARCHAR2,         -- 2.ファイル名
    iv_id_from               IN     VARCHAR2,         -- 3.入金履歴ID（From）
    iv_id_to                 IN     VARCHAR2,         -- 4.入金履歴ID（To）
    iv_doc_seq_value         IN     VARCHAR2,         -- 5.入金文書番号
    iv_exec_kbn              IN     VARCHAR2          -- 6.定期手動区分
  );
END XXCFO019A07C;
/
