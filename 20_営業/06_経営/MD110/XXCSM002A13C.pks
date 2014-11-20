CREATE OR REPLACE PACKAGE XXCSM002A13C AS

/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A13C(spec)
 * Description      : 商品計画リスト(時系列_本数単位)出力
 * MD.050           : 商品計画リスト(時系列_本数単位)出力 MD050_CSM_002_A13
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                【初期処理】A-1
 *
 *  do_check            【チェック処理】A-2~A-3
 *
 *  deal_item_data      【商品単位の処理】A-4~A-6
 *
 *  deal_group4_data    【商品群単位の処理】A-7~A-9
 *
 *  deal_group1_data    【商品区分単位の処理】A-10~A-12
 *
 *  deal_sum_data       【商品合計単位の処理】A-13~A-15
 *
 *  deal_down_data      【商品値引単位の処理】A-16~A-17
 *
 *  deal_kyoten_data    【拠点単位の処理】A-18~A-20
 *
 *  deal_all_data       【拠点リスト単位の処理】A-2~A-20
 *
 *  get_col_data        【各項目データの取得】A-21
 *     
 *  deal_csv_data        【出力ボディ情報の取得】A-21
 *  
 *  write_csv_file      【出力処理】A-22
 *  
 *  submain             【実装処理】A-1~A-23
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】A-1~A-23
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ohshikyo        新規作成
 *  2012/12/19    1.1   SCSK K.Taniguchi [E_本稼動_09949] 新旧原価選択可能対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf           OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
      retcode          OUT    NOCOPY VARCHAR2,         --   エラーコード
      iv_taisyo_ym     IN     VARCHAR2,                --   対象年度
      iv_kyoten_cd     IN     VARCHAR2,                --   拠点コード
      iv_cost_kind     IN     VARCHAR2,                --   原価種別
--//+UPD START E_本稼動_09949 K.Taniguchi
--      iv_kyoten_kaisou IN     VARCHAR2                 --   階層
      iv_kyoten_kaisou IN     VARCHAR2,                --   階層
      iv_new_old_cost_class
                       IN     VARCHAR2                 --   新旧原価区分
--//+UPD END E_本稼動_09949 K.Taniguchi
  );
END XXCSM002A13C;
/
