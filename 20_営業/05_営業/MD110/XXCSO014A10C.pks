CREATE OR REPLACE PACKAGE APPS.XXCSO014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A10C(spec)
 * Description      : )訪問予定ファイルをHHTへ連携するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_IPO_CSO_014_A10_HHT-EBSインターフェース：(OUT)訪問予定ファイル
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  chk_parm_date               パラメータチェック (A-2)
 *  get_profile_info            プロファイル値取得 (A-3)
 *  open_csv_file               CSVファイルオープン (A-4)
 *  get_csv_data                CSVファイルに出力する関連情報取得 (A-6)
 *  create_csv_rec              訪問予定データCSV出力 (A-7)
 *  close_csv_file              CSVファイルクローズ処理 (A-8)
 *  submain                     メイン処理プロシージャ
 *                                訪問予定データ抽出処理 (A-5)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Syoei.Kin        新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         --   エラーメッセージ #固定#
   ,retcode             OUT NOCOPY VARCHAR2         --   エラーコード     #固定#
   ,iv_value            IN VARCHAR2                 --   処理実行日(YYYYMMDD)
  );
END XXCSO014A10C;
/
