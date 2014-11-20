CREATE OR REPLACE PACKAGE XXCSO014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A08C(spec)
 * Description      : 日別売上計画ファイルをHHTへ連携するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_IPO_CSO_014_A08_HHT-EBSインターフェース：(OUT)日別売上計画
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
 *  create_csv_rec              CSVファイル出力 (A-7)
 *  close_csv_file              CSVファイルクローズ (A-8)
 *  submain                     メイン処理プロシージャ
 *                                顧客別日別売上計画データ抽出 (A-6)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-25    1.0   Syoei.Kin        新規作成
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
END XXCSO014A08C;
/
