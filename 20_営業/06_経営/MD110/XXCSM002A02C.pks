CREATE OR REPLACE PACKAGE XXCSM002A02C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A02C(spec)
 * Description      : 商品計画群別計画資料出力
 * MD.050           : 商品計画群別計画資料出力 MD050_CSM_002_A02
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 * init                 【初期処理】：A-1
 *
 * do_check             【チェック処理】：A-2
 * 
 * deal_group4_data     【商品群4桁データの詳細処理】A-3,A-4,A-5
 *
 * deal_group3_data     【商品群3桁データの詳細処理】A-6,A-7,A-8
 * 
 * write_line_info      【商品群4桁単位でデータの出力】A-9
 * 
 * write_csv_file       【商品計画群別計画資料出力データをCSVファイルへ出力】A-9
 *  
 * final                【終了処理】A-10
 *  
 * submain              【実装処理】
 *
 * main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   ohshikyo        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
    retcode          OUT    NOCOPY VARCHAR2,         --   エラーコード
    iv_taisyo_ym     IN     VARCHAR2,                --   対象年度
    iv_kyoten_cd     IN     VARCHAR2                 --   拠点コード
  );
END XXCSM002A02C;
/
