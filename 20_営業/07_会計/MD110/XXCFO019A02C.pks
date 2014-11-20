CREATE OR REPLACE PACKAGE APPS.XXCFO019A02C
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A02C(spec)
 * Description      : 電子帳簿仕訳の情報系システム連携
 * MD.050           : MD050_CFO_019_A02_電子帳簿仕訳の情報系システム連携
 *                    
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
 *  2012-08-29    1.0   K.Onotsuka      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode               OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,iv_ins_upd_kbn        IN         VARCHAR2          -- 追加更新区分
   ,iv_file_name          IN         VARCHAR2          -- ファイル名
   ,iv_period_name        IN         VARCHAR2          -- 会計期間
   ,iv_doc_seq_value_from IN         VARCHAR2          -- 仕訳文書番号（From）
   ,iv_doc_seq_value_to   IN         VARCHAR2          -- 仕訳文書番号（To）
   ,iv_exec_kbn           IN         VARCHAR2          -- 定期手動区分
  );
END XXCFO019A02C;
/
