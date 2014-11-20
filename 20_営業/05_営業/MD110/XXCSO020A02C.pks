CREATE OR REPLACE PACKAGE APPS.XXCSO020A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A02C(spec)
 * Description      : フルベンダー用ＳＰ専決・登録画面から渡される情報をもとに指定された
 *                    回送先にワークフロー通知を送付します。
 * MD.050           : MD050_CSO_020_A02_通知・承認ワークフロー機能
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-22    1.0   Noriyuki.Yabuki  新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
  --
  --実行ファイル登録プロシージャ
  PROCEDURE main(
     iv_notify_type           IN         VARCHAR2    -- 通知区分
   , it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE  -- ＳＰ専決ヘッダＩＤ
   , iv_send_employee_number  IN         VARCHAR2    -- 回送元従業員番号
   , iv_dest_employee_number  IN         VARCHAR2    -- 回送先従業員番号
   , errbuf                   OUT NOCOPY VARCHAR2    -- エラーメッセージ #固定#
   , retcode                  OUT NOCOPY VARCHAR2    -- エラーコード     #固定#
  );
  --
END XXCSO020A02C;
/
