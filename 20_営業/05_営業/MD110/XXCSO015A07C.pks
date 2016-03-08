CREATE OR REPLACE PACKAGE APPS.XXCSO015A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCSO015A07C(spec)
 * Description      : 契約にてオーナー変更が発生した時、自販機管理システムに
 *                    顧客と物件を連携するために、CSVファイルを作成します。
 * MD.050           : MD050_自販機-EBSインタフェース：（OUT））EBS自販機変更
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                       (A-1)
 *  open_csv_file               CSVファイルオープン            (A-2)
 *  upd_cont_manage             契約管理テーブル更新処理       (A-5)
 *  create_csv_rec              EBS自販機変更データCSV出力     (A-6)
 *  close_csv_file              CSVファイルクローズ処理        (A-7)
 *  submain                     メイン処理プロシージャ
 *                                EBS自販機変更データ抽出処理  (A-3)
 *                                セーブポイント発行           (A-4)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                終了処理                     (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016-01-06    1.0   Y.Shoji          新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,         -- エラーメッセージ #固定#
    retcode       OUT  NOCOPY  VARCHAR2,         -- エラーコード     #固定#
    iv_proc_date  IN VARCHAR2,                   -- 対象日
    iv_proc_time  IN VARCHAR2                    -- 対象時間
  );
END XXCSO015A07C;
/
