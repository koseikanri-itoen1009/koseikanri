CREATE OR REPLACE PACKAGE APPS.XXCSO015A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A04C(spec)
 * Description      : 拠点分割等により顧客マスタの拠点コードが変更になった物件を物件マスタから抽出し、
 *                        自販機管理システムに連携します。
 *                    
 * MD.050           : MD050_CSO_015_A04_自販機-EBSインタフェース：（OUT）物件マスタ情報
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  get_profile_info            プロファイル値取得 (A-2)
 *  open_csv_file               CSVファイルオープン (A-3)
 *  chk_str                     禁則文字チェック (A-6,A-10)
 *  create_csv_rec              CSVファイル出力 (A-8,A-13)
 *  update_wk_reqst_tbl         作業依頼／発注情報処理結果テーブル更新(A-12)
 *  close_csv_file              CSVファイルクローズ処理 (A-14)
 *  submain                     メイン処理プロシージャ
 *                                セーブポイント(ファイルクローズ失敗用)発行(A-4)
 *                                拠点変更物件マスタ情報抽出 (A-5)
 *                                廃棄作業依頼情報データ抽出(A-9)
 *                                セーブポイント(廃棄作業依頼情報連携失敗)発行(A-11)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-28    1.0   kyo              新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- エラーメッセージ #固定#
   ,retcode             OUT NOCOPY VARCHAR2         -- エラーコード     #固定#
   ,iv_csv_process_kbn  IN VARCHAR2                 -- 拠点変更・廃棄情報CSV出力処理区分
   ,iv_date_value       IN VARCHAR2                 -- 処理日付
  );
END XXCSO015A04C;
/
