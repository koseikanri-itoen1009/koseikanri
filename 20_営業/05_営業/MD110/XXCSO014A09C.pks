CREATE OR REPLACE PACKAGE APPS.XXCSO014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A09C(spec)
 * Description      : 月別売上計画ファイルをHHTへ連携するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_IPO_CSO_014_A09_HHT-EBSインターフェース：(OUT)月別売上計画
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  set_parm_def                パラメータデフォルトセット (A-2)
 *  chk_parm_date               パラメータチェック (A-3)
 *  get_profile_info            プロファイル値を取得 (A-4)
 *  open_csv_file               CSVファイルオープン (A-5) 
 *  create_csv_rec              CSVファイル出力 (A-8)
 *  close_csv_file              CSVファイルクローズ (A-9)
 *  submain                     メイン処理プロシージャ
 *                                顧客別月別売上計画データ抽出 (A-6)
 *                                CSVファイルに出力する関連情報取得 (A-7)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-10    1.0   Syoei.Kin        新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         --   エラーメッセージ #固定#
   ,retcode             OUT NOCOPY VARCHAR2         --   エラーコード     #固定#
   ,iv_from_value       IN VARCHAR2                 -- 更新日FROM(YYYYMMDD)
   ,iv_to_value         IN VARCHAR2                 -- 更新日TO(YYYYMMDD)
  );
END XXCSO014A09C;
/
