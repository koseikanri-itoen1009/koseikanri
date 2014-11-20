CREATE OR REPLACE PACKAGE XXCSM002A03C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A03C(spec)
 * Description      : 商品計画参考資料出力(商品別2ヵ年実績)
 * MD.050           : 商品計画参考資料出力(商品別2ヵ年実績) MD050_CSM_002_A03
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                【初期処理】A-1
 *
 *  do_check            【チェック処理】A-2
 *
 *  deal_result_data    【実績データの詳細処理】A-3,A-4,A-5,A-6,A-7
 *
 *  deal_plan_data      【計画データの詳細処理】A-3,A-4,A-8,A-9,A-10
 *
 *  write_line_info     【商品単位でのデータ出力】A-11
 *
 *  write_csv_file      【商品計画参考資料データをCSVファイルへ出力】A-11
 *
 *  submain             【実装処理】A-1～A-11
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】A-1～A-12
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/04    1.0   ohshikyo        新規作成
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
END XXCSM002A03C;
/
