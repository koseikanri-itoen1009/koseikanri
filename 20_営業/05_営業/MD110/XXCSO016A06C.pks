CREATE OR REPLACE PACKAGE XXCSO016A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A05C(spec)
 * Description      : 物件(自販機)の移動履歴情報を情報系システムに送信するためのCSVファイルを作成します。
 *                    
 * MD.050           : MD050_CSO_016_A06_情報系-EBSインターフェース：(OUT)什器移動明細
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
 *  get_profile_info            プロファイル値取得 (A-4)
 *  open_csv_file               CSVファイルオープン (A-5)
 *  get_csv_data                CSVファイルに出力する関連情報取得 (A-7)
 *  create_csv_rec              CSVファイル出力 (A-8)
 *  close_csv_file              CSVファイルクローズ処理 (A-9)
 *  submain                     メイン処理プロシージャ
 *                                什器移動明細データ抽出 (A-6)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Syoei.Kin        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- エラーメッセージ #固定#
   ,retcode             OUT NOCOPY VARCHAR2         -- エラーコード     #固定#
   ,iv_from_value       IN VARCHAR2                 -- 更新日FROM(YYYYMMDD)
   ,iv_to_value         IN VARCHAR2                 -- 更新日TO(YYYYMMDD)
  );
END XXCSO016A06C;
/
